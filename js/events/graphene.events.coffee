toggleHighlight = (classVal, toggleVal) ->
  replaceAll = (find, replace, str) ->
    return str.replace(new RegExp(find, 'g'), replace)

  if classVal.indexOf(toggleVal) != -1
    return replaceAll("highlight", "", classVal)
  else
    return classVal + " " + toggleVal


postRenderTimeSeriesView = (element) ->
  svg = element;
  svg.selectAll('a.l').forEach( (g) ->
    g.forEach( (a) ->
      aid = a.getAttribute('id')
      a.addEventListener('mouseenter', () ->
        svg.selectAll('path#l-' + aid).forEach ((graph) ->
          graph.forEach( (path) ->
            path.setAttribute('class', toggleHighlight(path.getAttribute('class'), "line-highlight"));
          )
        )
        svg.selectAll('path#a-' + aid).forEach ( (graph) ->
          graph.forEach( (path) ->
            path.setAttribute('class', toggleHighlight(path.getAttribute('class'), "area-highlight"));
          )
        )
      )
      a.addEventListener('mouseleave', () ->
        svg.selectAll('path#l-' + aid).forEach ((graph) ->
          graph.forEach( (path) ->
            path.setAttribute('class', toggleHighlight(path.getAttribute('class'), "line-highlight"));
          )
        )
        svg.selectAll('path#a-' + aid).forEach ( (graph) ->
          graph.forEach( (path) ->
            path.setAttribute('class', toggleHighlight(path.getAttribute('class'), "area-highlight"));
          )
        )
      )
    )
  )
