_ = require 'underscore'

DOMUtils =
  removeElements: (elements=[]) ->
    for el in elements
      try
        if el.parentNode then el.parentNode.removeChild(el)
      catch
        # This can happen if we've already removed ourselves from the node
        # or it no longer exists
        continue
    return elements

  # Checks to see if a particular node is visible and any of its parents
  # are visible.
  #
  # WARNING. This is a fairly expensive operation and should be used
  # sparingly.
  nodeIsVisible: (node) ->
    while node and node isnt window.document
      style = window.getComputedStyle(node)
      node = node.parentNode
      continue unless style?
      # NOTE: opacity must be soft ==
      if style.opacity is 0 or style.opacity is "0" or style.visibility is "hidden" or style.display is "none"
        return false
    return true

  # Finds all of the non blank node in a {Document} object or HTML string.
  #
  # - `elementOrHTML` a dom element or an HTML string. If passed a
  # string, it will use `DOMParser` to convert it into a DOM object.
  #
  # "Non blank" is defined as any node whose `textContent` returns a
  # whitespace string.
  #
  # It will also reject nodes we see are invisible due to basic CSS
  # properties.
  #
  # Returns an array of DOM Nodes
  nodesWithContent: (elementOrHTML) ->
    nodes = []
    if _.isString(elementOrHTML)
      domParser = new DOMParser()
      doc = domParser.parseFromString(elementOrHTML, "text/html")
      allNodes = doc.body.childNodes
    else if elementOrHTML?.childNodes
      allNodes = elementOrHTML.childNodes
    else return nodes

    # We need to check `childNodes` instead of `children` to look for
    # plain Text nodes.
    for node in allNodes by -1
      if node.nodeName is "IMG"
        nodes.unshift node

      # It's important to use `textContent` and NOT `innerText`.
      # `innerText` causes a full reflow on every call because it
      # calcaultes CSS styles to determine if the text is truly visible or
      # not. This utility method must NOT cause a reflow. We instead will
      # check for basic cases ourselves.
      if (node.textContent ? "").trim().length is 0
        continue

      if node.style?.opacity is 0 or node.style?.opacity is "0" or node.style?.visibility is "hidden" or node.style?.display is "none"
        continue

      nodes.unshift node

    # No nodes with content found!
    return nodes

  parents: (node) ->
    nodes = []
    nodes.unshift(node) while node = node.parentNode
    return nodes

  commonAncestor: (nodes=[]) ->
    nodes = Array::slice.call(nodes)

    minDepth = Number.MAX_VALUE
    # Sometimes we can potentially have tons of REALLY deeply nested
    # nodes. Since we're looking for a common ancestor we can really speed
    # this up by keeping track of the min depth reached. We know that we
    # won't need to check past that.
    parents = ->
      nodes = []
      depth = 0
      while node = node.parentNode
        nodes.unshift(node)
        depth += 1
        if depth > minDepth then break
      minDepth = Math.min(minDepth, depth)
      return nodes

    # _.intersection will preserve the ordering of the parent node arrays.
    # parents are ordered top to bottom, so the last node is the most
    # specific common ancenstor
    _.last(_.intersection.apply(null, nodes.map(DOMUtils.parents)))

  scrollAdjustmentToMakeNodeVisibleInContainer: (node, container) ->
    return unless node

    nodeRect = node.getBoundingClientRect()
    containerRect = container.getBoundingClientRect()

    distanceBelowBottom = (nodeRect.top + nodeRect.height) - (containerRect.top + containerRect.height)
    if distanceBelowBottom > 0
      return distanceBelowBottom

    distanceAboveTop = containerRect.top - nodeRect.top
    if distanceAboveTop > 0
      return -distanceAboveTop

    return 0

module.exports = DOMUtils
