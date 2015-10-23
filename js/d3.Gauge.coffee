#
# this example is based on Tomer Doron's Google Gauge,
# https://github.com/tomerd
#

Gauge = (placeholderName, configuration) ->
  @placeholderName = placeholderName
  self = this
  # some internal d3 functions do not "like" the "this" keyword, hence setting a local variable

  @configure = (configuration) ->
    @config = configuration
    @config.size = @config.size * 0.9
    @config.raduis = @config.size * 0.97 / 2
    @config.cx = @config.size / 2
    @config.cy = @config.size / 2
    @config.min = configuration.min or 0
    @config.max = configuration.max or 100
    @config.range = @config.max - (@config.min)
    @config.majorTicks = configuration.majorTicks or 5
    @config.minorTicks = configuration.minorTicks or 2
    @config.greenColor = configuration.greenColor or '#109618'
    @config.yellowColor = configuration.yellowColor or '#FF9900'
    @config.redColor = configuration.redColor or '#DC3912'
    return

  @render = ->
    `var point2`
    `var point1`
    `var fontSize`
    `var index`
    `var index`
    @body = d3.select('#' + @placeholderName).append('svg:svg').attr('class', 'gauge').attr('width',
      @config.size).attr('height', @config.size)
    @body.append('svg:circle').attr('class', 'outer').attr('cx', @config.cx).attr('cy',
      @config.cy).attr 'r', @config.raduis
    @body.append('svg:circle').attr('class', 'inner').attr('cx', @config.cx).attr('cy',
      @config.cy).attr 'r', 0.9 * @config.raduis
    for index of @config.greenZones
      @drawBand @config.greenZones[index].from, @config.greenZones[index].to, self.config.greenColor
    for index of @config.yellowZones
      @drawBand @config.yellowZones[index].from, @config.yellowZones[index].to, self.config.yellowColor
    for index of @config.redZones
      @drawBand @config.redZones[index].from, @config.redZones[index].to, self.config.redColor
    if undefined != @config.label
      fontSize = Math.round(@config.size / 9)
      @body.append('svg:text').attr('class', 'label').attr('x', @config.cx).attr('y',
        @config.cy / 2 + fontSize / 2).attr('dy', fontSize / 2).attr('text-anchor',
        'middle').text(@config.label).style 'font-size', fontSize + 'px'
    fontSize = Math.round(@config.size / 16)
    majorDelta = @config.range / (@config.majorTicks - 1)

    major = this.config.min
    while major <= @config.max
      minorDelta = majorDelta / @config.minorTicks
      minor = major + minorDelta
      while minor < Math.min(major + majorDelta, @config.max)
        point1 = @valueToPoint(minor, 0.75)
        point2 = @valueToPoint(minor, 0.85)
        @body.append('svg:line').attr('class', 'small-tick').attr('x1', point1.x).attr('y1', point1.y).attr('x2',
          point2.x).attr 'y2', point2.y
        minor += minorDelta
      point1 = @valueToPoint(major, 0.7)
      point2 = @valueToPoint(major, 0.85)
      @body.append('svg:line').attr('class', 'big-tick').attr('x1', point1.x).attr('y1', point1.y).attr('x2',
        point2.x).attr 'y2', point2.y
      if major == @config.min or major == @config.max
        point = @valueToPoint(major, 0.63)
        @body.append('svg:text').attr('class', 'limit').attr('x', point.x).attr('y', point.y).attr('dy',
          fontSize / 3).attr('text-anchor',
          if major == @config.min then 'start' else 'end').text(major).style 'font-size', fontSize + 'px'
      major += majorDelta
    pointerContainer = @body.append('svg:g').attr('class', 'pointerContainer')
    @drawPointer 0
    pointerContainer.append('svg:circle').attr('class', 'pointer-circle').attr('cx', @config.cx).attr('cy',
      @config.cy).attr 'r', 0.12 * @config.raduis
    return

  @redraw = (value, value_format) ->
    @drawPointer value, value_format
    return

  @drawBand = (start, end, color) ->
    return if 0 >= end - start

    @body.append('svg:path')
    .style('fill', color)
    .attr('class', 'band')
    .attr('d',d3.svg.arc().startAngle(@valueToRadians(start)).endAngle(@valueToRadians(end)).innerRadius(0.80 * @config.raduis).outerRadius(0.85 * @config.raduis))
    .attr 'transform', ->
      'translate(' + self.config.cx + ', ' + self.config.cy + ') rotate(270)'

    return

  @drawPointer = (value, value_format) ->
    delta = @config.range / 13
    head = @valueToPoint(value, 0.85)
    head1 = @valueToPoint(value - delta, 0.12)
    head2 = @valueToPoint(value + delta, 0.12)
    tailValue = value - (@config.range * 1 / (270 / 360) / 2)
    tail = @valueToPoint(tailValue, 0.28)
    tail1 = @valueToPoint(tailValue - delta, 0.12)
    tail2 = @valueToPoint(tailValue + delta, 0.12)
    data = [
      head
      head1
      tail2
      tail
      tail1
      head2
      head
    ]
    line = d3.svg.line().x((d) ->
      d.x
    ).y((d) ->
      d.y
    ).interpolate('basis')
    pointerContainer = @body.select('.pointerContainer')
    pointer = pointerContainer.selectAll('path').data([data])
    pointer.enter().append('svg:path').attr('class', 'pointer').attr 'd', line
    pointer.transition().attr 'd', line
    #.ease("linear")
    #.duration(5000);
    fontSize = Math.round(@config.size / 10)
    pointerContainer.selectAll('text').data([value]).text(d3.format(value_format)(value)).enter().append('svg:text').attr('class',
      'value').attr('x', @config.cx).attr('y', @config.size - (@config.cy / 4) - fontSize).attr('dy',
      fontSize / 2).attr('text-anchor',
      'middle').text(d3.format(value_format)(value)).style 'font-size', fontSize + 'px'
    return

  @valueToDegrees = (value) ->
    value / @config.range * 270 - 45

  @valueToRadians = (value) ->
    @valueToDegrees(value) * Math.PI / 180

  @valueToPoint = (value, factor) ->
    point =
      x: @config.cx - (@config.raduis * factor * Math.cos(@valueToRadians(value)))
      y: @config.cy - (@config.raduis * factor * Math.sin(@valueToRadians(value)))
    point

  # initialization
  @configure configuration
  return

# ---
# generated by js2coffee 2.1.0
