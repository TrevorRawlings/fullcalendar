

class fc.View extends Backbone.Marionette.View

  # (element, calendar, viewName) {
  initialize: (options = {}) ->

    throw "missing #{key}" for key in ["calendar", "viewName"] when _.isUndefined(options[key])

    @calendar = options.calendar
    @name = @viewName = options.viewName


    # locals
    @eventsByID = {};
    @eventElements = [];
    @eventElementsByID = {};




  opt: (name, viewNameOverride) ->
    v = @calendar.options[name];
    if _.isObject(v)
      return fc.util.smartProperty(v, viewNameOverride || @viewName);
    return v

  trigger: ->
    return @calendar.trigger_callback.apply(@calendar, arguments)


  isEventDraggable: (event) ->
    return @isEventEditable(event) && !@opt('disableDragging');

  isEventResizable: (event) -> # but also need to make sure the seg.isEnd == true
    return @isEventEditable(event) && !@opt('disableResizing')

  isEventEditable: (event) ->
    return fc.util.firstDefined(event.editable, (event.source || {}).editable, @opt('editable'));


  #	/* Event Data
  #	------------------------------------------------------------------------------*/

  # report when view receives new events
  reportEvents: (events) -> # events are already normalized at this point
    @eventsByID = {}
    for event in events
      if (@eventsByID[event._id])
        @eventsByID[event._id].push(event);
      else
        @eventsByID[event._id] = [event];

  # returns a Date object for an event's end
  eventEnd: (event) ->
    return if event.end then fc.dateUtil.cloneDate(event.end) else @defaultEventEnd(event);

  #  /* Event Elements
  #  ------------------------------------------------------------------------------*/

  # report when view creates an element for an event
  reportEventElement: (event, element) ->
    @eventElements.push(element);
    if (@eventElementsByID[event._id])
      @eventElementsByID[event._id].push(element);
    else
      @eventElementsByID[event._id] = [element];


  reportEventClear: ->
    @eventElements = [];
    @eventElementsByID = {};

  # attaches eventClick, eventMouseover, eventMouseout
  #  eventElementHandlers: (event, eventElement) ->
  #      eventElement
  #        .click(function(ev) {
  #          if (!eventElement.hasClass('ui-draggable-dragging') &&
  #            !eventElement.hasClass('ui-resizable-resizing')) {
  #              return trigger('eventClick', this, event, ev);
  #            }
  #        })

  #    // TODO: don't fire eventMouseover/eventMouseout *while* dragging is occuring (on subject element)
  #    // TODO: same for resizing
  #  }
  #

  showEvents: (event, exceptElement) ->
    @eachEventElement(event, exceptElement, 'show');

  hideEvents: (event, exceptElement) ->
    @eachEventElement(event, exceptElement, 'hide')

  eachEventElement: (event, exceptElement, funcName) ->
    elements = @eventElementsByID[event._id]
    for element, i in elements
      if (!exceptElement or element[0] != exceptElement[0])
        elements[i][funcName]();


  #  /* Event Modification Reporting
  #  ---------------------------------------------------------------------------------*/


    #  function eventDrop(e, event, dayDelta, minuteDelta, allDay, ev, ui) {
    #    var oldAllDay = event.allDay;
    #    var eventId = event._id;
    #    moveEvents(eventsByID[eventId], dayDelta, minuteDelta, allDay);
    #    trigger(
    #      'eventDrop',
    #      e,
    #      event,
    #      dayDelta,
    #      minuteDelta,
    #      allDay,
    #      function() {
    #        // TODO: investigate cases where this inverse technique might not work
    #        moveEvents(eventsByID[eventId], -dayDelta, -minuteDelta, oldAllDay);
    #        @calendar.reportEventChange(eventId);
    #      },
    #      ev,
    #      ui
    #    );
    #    @calendar.reportEventChange(eventId);
    #  }
    #
    #
    #  function eventResize(e, event, dayDelta, minuteDelta, ev, ui) {
    #    var eventId = event._id;
    #    elongateEvents(eventsByID[eventId], dayDelta, minuteDelta);
    #    trigger(
    #      'eventResize',
    #      e,
    #      event,
    #      dayDelta,
    #      minuteDelta,
    #      function() {
    #        // TODO: investigate cases where this inverse technique might not work
    #        elongateEvents(eventsByID[eventId], -dayDelta, -minuteDelta);
    #        @calendar.reportEventChange(eventId);
    #      },
    #      ev,
    #      ui
    #    );
    #    @calendar.reportEventChange(eventId);
    #  }
    #
    #
    #
    #  #	/* Event Modification Math
    #  #	---------------------------------------------------------------------------------*/
    #
    #
    #  function moveEvents(events, dayDelta, minuteDelta, allDay) {
    #    minuteDelta = minuteDelta || 0;
    #    for (var e, len=events.length, i=0; i<len; i++) {
    #      e = events[i];
    #      if (allDay !== undefined) {
    #        e.allDay = allDay;
    #      }
    #      addMinutes(fc.dateUtil.addDays(e.start, dayDelta, true), minuteDelta);
    #      if (e.end) {
    #        e.end = addMinutes(fc.dateUtil.addDays(e.end, dayDelta, true), minuteDelta);
    #      }
    #      @calendar.normalizeEvent(e, @calendar.options);
    #    }
    #  }
    #
    #
    #  function elongateEvents(events, dayDelta, minuteDelta) {
    #    minuteDelta = minuteDelta || 0;
    #    for (var e, len=events.length, i=0; i<len; i++) {
    #      e = events[i];
    #      e.end = addMinutes(fc.dateUtil.addDays(eventEnd(e), dayDelta, true), minuteDelta);
    #      @calendar.normalizeEvent(e, @calendar.options);
    #    }
    #  }

