class Graphene
  constructor: ->
    @models = {}
    @is_silent = false
    @is_demo = false

  demo: ->
    @is_demo = true

  silent: ->
    @is_silent = true

  build: (json) =>
    _.each _.keys(json), (k)=>
      console.log "building [#{k}]" if not @is_silent

      # init backbone model
      model = if @is_demo then Graphene.DemoTimeSeries else Graphene.TimeSeries
      model_opts = {source: json[k].source}
      model_opts.silent = @is_silent
      delete json[k].source
      if json[k].refresh_interval
        model_opts.refresh_interval = json[k].refresh_interval
        delete json[k].refresh_interval
      ts = new model(model_opts)
      @models[k] = ts

      _.each json[k], (opts, view) =>
        # init backbone view
        view = eval("Graphene.#{view}View")
        params = _.extend({
          model: ts,
          silent: @is_silent,
          ymin: @getUrlParam(model_opts.source, "yMin"),
          ymax: @getUrlParam(model_opts.source, "yMax")
        }, opts)
        new view(params)
        ts.start()

  stop: () =>
    _.each @models, (chart) =>
      console.log('stop polling') if not @is_silent
      chart.stop()

  discover: (url, dash, parent_specifier, cb)->
    $.getJSON "#{url}/dashboard/load/#{dash}", (data)->
      i = 0
      desc = {}
      _.each data['state']['graphs'], (graph)->
        path = graph[2]
        conf = graph[1]
        title = if conf.title then conf.title else "n/a"
        desc["Graph #{i}"] =
          source: "#{url}#{path}&format=json"
          TimeSeries:
            title: title
            ymin: conf.yMin
            parent: parent_specifier(i, url)
        i++
      cb(desc)

  getUrlParam: (url, variable)->
    value = ''
    query = url.split('?')[1]
    return value unless query

    vars = query.split('&')
    return value unless vars && vars.length > 0

    _.each vars, (v)->
      pair = v.split('=')
      if decodeURIComponent(pair[0]) == variable
        value = decodeURIComponent(pair[1])
    value


@Graphene = Graphene

class Graphene.GraphiteModel extends Backbone.Model
  defaults:
    source: ''
    data: null
    ymin: 0
    ymax: 0
    refresh_interval: 10000
    silent: false

  debug: () ->
    console.log("#{@get('refresh_interval')}") if nor @get('silent')

  start: () =>
    @refresh()
    console.log("Starting to poll at #{@get('refresh_interval')}") if nor @get('silent')
    @t_index = setInterval(@refresh, @get('refresh_interval'))

  stop: ()=>
    clearInterval(@t_index)

  refresh: ()=>
    url = @get('source')
    #jQuery expects to see 'jsonp=?' in the url in order to perform JSONP-style requests
    if -1 == url.indexOf('&jsonp=?')
      url = url + '&jsonp=?'

    options =
      url: url
      dataType: 'json'
      jsonp: 'jsonp'
      success: (js) =>
        console.log("got data.") if nor @get('silent')
        @process_data(js)
    $.ajax options

  process_data: ()=>
    return null

