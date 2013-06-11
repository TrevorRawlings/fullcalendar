class fc.Mixin

fc.Mixin.add_to = (object) ->
  for key, value of this.prototype when key not in ["constructor"]
    object.prototype[key] = value  # Assign properties to the prototype


# Searches the tree of html nodes below the view item. An error is raised if the number found is not equal to 1
# http://api.jquery.com/find/
class fc.FindElementMixin extends fc.Mixin
  findElement: (search) ->
    elements = @$(search)
    if elements.length != 1
      throw "element #{search} found #{elements.length} times (expected 1 instance)"
    else
      return $(elements[0])



class fc.Calendar extends Backbone.Marionette.Layout
  fc.FindElementMixin.add_to(this)

  regions:
    contentRegion: "#fc-content"

  initialize: (options) ->

    # check date & dateTime converters have been supplied
    throw "converters missing" if !options.dateConverter or !options.dateTimerConverter

    rtlDefaults = if options.isRTL or (_.isUndefined(options.isRTL) and fc.defaults.isRTL) then fc.rtlDefaults else {}
    @options = options = $.extend(true, {}, fc.defaults, rtlDefaults, options)

    eventSources = options.eventSources || [];
    delete options.eventSources;

    @eventManager = new fc.EventManager(this, options, eventSources)
    @navigate = new fc.Navigate(this)

    # locals
    @tm= null; # for making theme classes
    @currentView= null;
    @elementOuterWidth= null;
    @suggestedViewHeight= null;
    @resizeUID = 0;
    @ignoreWindowResize = 0;
    @date = new Date();
    @events = [];
    @_dragElement= null;

    fc.dateUtil.setYMD(@date, options.year, options.month, options.date);


  elementVisible: ->
    return @isActive



  #	/* View Rendering
  #	-----------------------------------------------------------------------------*/
  #
  #	// TODO: improve view switching (still weird transition in IE, and FF has whiteout problem)
  #
  changeView: (newViewName) ->
    if (!@currentView || newViewName != @currentView.name)
      try
        @ignoreWindowResize++; # because setMinHeight might change the height before render (and subsequently setSize) is reached

        @unselect();

        oldView = @currentView;
        newViewElement = null;

        if @contentRegion.hasView()
          fc.util.setMinHeight(@content, @content.height())
        else
          fc.util.setMinHeight(@content, 1); # needs to be 1 (not 0) for IE7, or else view dimensions miscalculated
        @content.css('overflow', 'hidden');

        @currentView = new fc.views[newViewName]({calendar: this}) # the calendar object
        @$absoluteViewElement = @currentView.$el
        @$absoluteViewElement.css('position', 'absolute')
        @contentRegion.set( @currentView )

        if @header
          @header.deactivateButton(oldView.name) if (oldView)
          @header.activateButton(newViewName);

        @renderView(); # after height has been set, will make absoluteViewElement's position=relative, then set to null

        @content.css('overflow', '');
        fc.util.setMinHeight(@content, 1);


      finally
        @ignoreWindowResize--;


  renderView: (inc) ->
    if @elementVisible()
      try
        @ignoreWindowResize++ # because renderEvents might temporarily change the height before setSize is reached
        @unselect();
        @calcSize() if _.isUndefined(@suggestedViewHeight)

        forceEventRender = false;
        if !@currentView.start or inc or @date < @currentView.start or @date >= @currentView.end
          # view must render an entire new date range (and refetch/render events)
          @currentView.render(@date, inc || 0); # responsible for clearing events
          @setSize(true)
          forceEventRender = true

        else if @currentView.sizeDirty
          # view must resize (and rerender events)
          @currentView.clearEvents();
          @setSize();
          forceEventRender = true

        else if @currentView.eventsDirty
          currentView.clearEvents();
          forceEventRender = true;

        @currentView.sizeDirty = false;
        @currentView.eventsDirty = false;
        @updateEvents(forceEventRender);

        @elementOuterWidth = @$el.outerWidth()

        if @header
          @header.updateTitle(@currentView.title);
          today = new Date();
          if (today >= @currentView.start and today < @currentView.end)
            @header.disableButton('today');
          else
            @header.enableButton('today');

      finally
        @ignoreWindowResize--
      @trigger('viewDisplay')



  #	/* Resizing
  #	-----------------------------------------------------------------------------*/


  updateSize: ->
    @markSizesDirty();
    if @elementVisible()
      @calcSize()
      @setSize();
      @unselect();
      @currentView.clearEvents();
      @currentView.renderEvents(@events);
      @currentView.sizeDirty = false;


  markSizesDirty: ->
    if @currentView
      @currentView.sizeDirty = true;

  calcSize: ->
    if (@options.contentHeight)
      @suggestedViewHeight = @options.contentHeight;
    else if @options.height
      headerElementHeight = if @headerElement then headerElement.height() else 0
      @suggestedViewHeight = @options.height - headerElementHeight - vsides(@content)
    else
      @suggestedViewHeight = Math.round(@content.width() / Math.max(@options.aspectRatio, 0.5))


  setSize: (dateChanged) -> # todo: dateChanged?
    try
      @ignoreWindowResize++;
      @currentView.setHeight(@suggestedViewHeight, dateChanged);
      if (@$absoluteViewElement)
        @$absoluteViewElement.css('position', 'relative');
        @$absoluteViewElement = null;

      @currentView.setWidth(@content.width(), dateChanged);

    finally
      @ignoreWindowResize--;




  #	/* Event Fetching/Rendering
  #	-----------------------------------------------------------------------------*/
  #
  #
  #	// fetches events if necessary, rerenders events if necessary (or if forced)
  updateEvents: (forceRender) ->
    if (!@options.lazyFetching or @eventManager.isFetchNeeded(@currentView.visStart, @currentView.visEnd))
      @refetchEvents();

    else if (forceRender)
      @rerenderEvents()

  # public method
  refetchEvents: ->
    @eventManager.fetchEvents(@currentView.visStart, @currentView.visEnd); # will call reportEvents


  # called when event data arrives
  reportEvents: (_events) ->
    @events = _events;
    @rerenderEvents();

  # called when a single event's data has been changed
  reportEventChange: (eventID) ->
    @rerenderEvents(eventID);


  # attempts to rerenderEvents
  rerenderEvents: (modifiedEventID) ->
    @markEventsDirty();
    if @elementVisible()
      @currentView.clearEvents();
      @currentView.renderEvents(@events, modifiedEventID);
      @currentView.eventsDirty = false

  markEventsDirty: ->
    if @currentView
      @currentView.eventsDirty = true;


  #  /* Selection
  #  -----------------------------------------------------------------------------*/

  select: (start, end, allDay = true) ->
    @currentView.select(start, end, allDay);


  unselect: () -> # safe to be called before renderView
    @currentView.unselect() if @currentView


  #  * Misc
  #  -----------------------------------------------------------------------------*/
  #

  getView: ->
    return @currentView

  option: (name, value) ->
    return @options[name] if _.isUndefined(value)

    if (name == 'height' || name == 'contentHeight' || name == 'aspectRatio')
      @options[name] = value;
      @updateSize();


  trigger_callback: (name, thisObj) ->
    if @options[name]
      event_context = @options.event_context || thisObj
      return @options[name].apply(event_context, Array.prototype.slice.call(arguments, 1));
    return null


  onShow: (wasAlreadyActive) ->
    super
    if !wasAlreadyActive
      @render()

  onDeactivate: ->
    super
    if @header
      @header.destroy();

    if @content
      @content.remove();
      @$el.removeClass('fc fc-rtl ui-widget');
      @content = null


  #  destroy: ->
  #    #$(window).unbind('resize', windowResize);
  #    #header.destroy();
  #    @content.remove();
  #    @$el.removeClass('fc fc-rtl ui-widget');

  initialRender: ->
    @tm = if @options.theme then 'ui' else 'fc'
    @$el.addClass('fc')
    if (@options.isRTL)
      @$el.addClass('fc-rtl');
    else
      @$el.addClass('fc-ltr');
    @$el.addClass('ui-widget') if (@options.theme)

    @$el.html("<div id='fc-content' class='fc-content' style='position:relative'/>")
    @initializeRegions()
    @content = @findElement('#fc-content')

  render: (inc) ->
    if (!@content)
      @initialRender()
    else
      @calcSize()
      @markSizesDirty();
      @markEventsDirty();
      @renderView(inc);





    #		header = new Header(t, options);
    #		headerElement = header.render();
    #		if (headerElement)
    #			@element.prepend(headerElement);
    #		}
    @changeView(@options.defaultView);
    #		$(window).resize(windowResize);
    #		// needed for IE in a 0x0 iframe, b/c when it is resized, never triggers a windowResize
    #		if (!bodyVisible()) {
    #			lateRender();
    #		}
    #	}



  #  /* External Dragging
  #  ------------------------------------------------------------------------*/

  #  if (options.droppable) {
  #    $(document)
  #      .bind('dragstart', function(ev, ui) {
  #        var _e = ev.target;
  #        var e = $(_e);
  #        if (!e.parents('.fc').length) { // not already inside a calendar
  #          var accept = options.dropAccept;
  #          if ($.isFunction(accept) ? accept.call(_e, e) : e.is(accept)) {
  #            _dragElement = _e;
  #            currentView.dragStart(_dragElement, ev, ui);
  #          }
  #        }
  #      })
  #      .bind('dragstop', function(ev, ui) {
  #        if (_dragElement) {
  #          currentView.dragStop(_dragElement, ev, ui);
  #          _dragElement = null;
  #        }
  #      });
  #  }
  #


#	windowResize() {
#		if (!ignoreWindowResize) {
#			if (currentView.start) { // view has already been rendered
#				var uid = ++resizeUID;
#				setTimeout(function() { // add a delay
#					if (uid == resizeUID && !ignoreWindowResize && elementVisible()) {
#						if (elementOuterWidth != (elementOuterWidth = element.outerWidth())) {
#							ignoreWindowResize++; // in case the windowResize callback changes the height
#							c();
#							currentView.trigger('windowResize', _element);
#							ignoreWindowResize--;
#						}
#					}
#				}, 200);
#			}else{
#				// calendar must have been initialized in a 0x0 iframe that has just been resized
#				lateRender();
#			}
#		}
#	}
