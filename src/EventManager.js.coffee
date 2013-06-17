fc = $.fullCalendar

class fc.EventManager

  constructor: (calendar, options, sources) ->
    @calendar = calendar

    # exports
    for name in ['isFetchNeeded', 'fetchEvents','addEventSource',
                 'removeEventSource', 'updateEvent', 'renderEvent',
                 'removeEvents', 'clientEvents','normalizeEvent']
      @[name] = _.bind(@[name], this)
      @calendar[name] = this[name]

    # locals
    @sources = []
    @rangeStart = null
    @rangeEnd = null
    @cache = []

    @_addEventSource(source) for source in sources


  # /* Fetching
  # -----------------------------------------------------------------------------*/

  isFetchNeeded: (start, end) ->
    return true

  fetchEvents: (start, end) ->
    @rangeStart = start
    @rangeEnd = end
    #@calendar.trigger('loading', null, true)

    new_cache = []
    for source in @sources
      events = source.fetch_events(@rangeStart, @rangeEnd, @calendar)
      for event in events
        event.source = source
        @normalizeEvent(event);
      new_cache = new_cache.concat(events)

    #@calendar.trigger('loading', null, false)

    @cache = new_cache
    @calendar.reportEvents(@cache)






  #* Sources
  #-----------------------------------------------------------------------------*/


  addEventSource: (source) ->
    @_addEventSource(source);



  _addEventSource: (source) ->
    throw "expected a object" if !_.isObject(source) or !_.isFunction(source.fetch_events)

    @normalizeSource(source)
    @sources.push(source)
    return @source




  removeEventSource: (source) ->
    #
    new_sources = (src for src in sources when !(src == source) )
    @sources = new_sources

    new_events = (e for e in @cache when !(e.source == source))
    @cache = new_events
    @calendar.reportEvents(@cache)




  #* Manipulation
  #-----------------------------------------------------------------------------*/

  # update an existing event
  updateEvent: (event) ->
    @normalizeEvent(event)
    @calendar.reportEvents(cache)



  renderEvent: (event, source) ->
    throw "unknown source" if !_.contains(@sources, source)

    @normalizeEvent(event, source);
    @cache.push(event)
    @calendar.reportEvents(cache);



  removeEvents: (filter)  ->
    if (!filter)   # // remove all
      @cache = []  #  clear all array sources
    else if _.isArray(filter)
      @cache = _.difference(@cache, filter)
    else
      throw "unsupported argument"
    @calendar.reportEvents(@cache);


  clientEvents: () ->
    return @cache;



  # /* Event Normalization
  # -----------------------------------------------------------------------------*/


  normalizeEvent: (event, source) ->

    if !event.source
      event.source = source

    if !event._id
      event._id = if _.isUndefined(event.id) then _.uniqueId('_fc') else "#{event.id}"

    if event.date
      if !event.start
        event.start = event.date;

      delete event.date;

    event._start = fc.dateUtil.cloneDate(event.start = fc.dateUtil.parseDate(event.start));
    if event.end
      event.end = fc.dateUtil.parseDate(event.end);
      event.end = null if event.end <= event.start


    event._end = if event.end then fc.dateUtil.cloneDate(event.end) else null
    if _.isUndefined(event.allDay)
      event.allDay = fc.util.firstDefined(source.allDayDefault, options.allDayDefault);

    if event.className
      if _.isString(event.className)
        event.className = event.className.split(/\s+/)

    else
      event.className = []

    # TODO: if there is no start date, return false to indicate an invalid event




  # /* Utils
  #------------------------------------------------------------------------------*/


  normalizeSource: (source) ->
    if source.className
      # TODO: repeat code, same code for event classNames
      if _.isString(source.className)
        source.className = source.className.split(/\s+/)
    else
      source.className = []




