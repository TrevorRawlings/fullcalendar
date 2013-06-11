
#setDefaults({
#	weekMode: 'fixed'
#});

class fc.BasicViewCoordinateGrid extends fc.CoordinateGrid

  build: (headCells, bodyRows, rowCnt) ->
    @rows = []
    @cols = []

    e = null
    n = null
    p = null
    for _e, i in headCells
      e = $(_e);
      n = e.offset().left;
      if (i)
        p[1] = n;
      p = [n];
      @cols[i] = p;
    p[1] = n + e.outerWidth();

    for _e, i in bodyRows
      if (i < rowCnt)
        e = $(_e);
        n = e.offset().top;
        if (i)
          p[1] = n;
        p = [n];
        @rows[i] = p;
    p[1] = n + e.outerHeight();


class fc.BasicView extends fc.View

  events:
    'click .fc-day'          : 'dayClick'
    'click .fc-cell-overlay' : 'dayClick'
    'mousedown .fc-day'          : 'daySelectionMousedown'
    'mousedown .fc-cell-overlay' : 'daySelectionMousedown'
    'click .fc-event' :       'eventClick'


  initialize: (options = {}) ->
    super
    OverlayManager.call(this);
    SelectionManager.call(this);
    BasicEventRenderer.call(this);

    @coordinateGrid = new fc.BasicViewCoordinateGrid()
    @hoverListener = new HoverListener(@coordinateGrid);

    self = this
    getElement = (col) ->
      return self.$tableEl.bodyCellTopInners.eq(col);
    @colContentPositions = new HorizontalPositionCache(getElement);

  getHoverListener: ->
    return @hoverListener

  cellIsAllDay: ->
    return true

  getRowCnt: ->
    return @rowCnt

  getColCnt: ->
    return @colCnt

  getColWidth: ->
    return @colWidth

  getDaySegmentContainer: ->
    return @daySegmentContainer

  updateOptions: ->
    @rtl = @opt('isRTL');
    if (@rtl)
      @dis = -1;
      @dit = @colCnt - 1;
    else
      @dis = 1;
      @dit = 0;

    @firstDay = @opt('firstDay');
    @nwe = if @opt('weekends') then 0 else 1;  #// no weekends? a 0 or 1 for easy computations
    @tm = if @opt('theme') then 'ui' else 'fc';
    @colFormat = @opt('columnFormat');

    # week # options. (TODO: bad, logic also in other views)
    @showWeekNumbers = @opt('weekNumbers');
    @weekNumberTitle = @opt('weekNumberTitle');
    if (@opt('weekNumberCalculation') != 'iso')
      @weekNumberFormat = "w";
    else
      @weekNumberFormat = "W";


  buildEventContainer: ->
    @daySegmentContainer =
      $("<div style='position:absolute;z-index:8;top:0;left:0'/>")
        .appendTo(@$el);

  center_date: (visStart, visEnd) ->
    visStart = moment(visStart);
    visEnd = moment(visEnd);
    days = visEnd.diff(visStart, 'days');
    return visStart.clone().add('days', (days / 2)).toDate();


  center_month: ->
    return @center_date(@visStart, @visEnd).getMonth();

  buildTable: (showNumbers) ->
    html = '';
    headerClass = @tm + "-widget-header";
    contentClass = @tm + "-widget-content";
    month = @center_month();
    today = fc.dateUtil.clearTime(new Date());
    cellDate = null; # not to be confused with local function. TODO: better names

    cell = null;


    html += "<table class='fc-table fc-border-separate' style='width:100%' cellspacing='0'>" +
            "<thead>" +
            "<tr>";

    if (@showWeekNumbers)
      html += "<th class='fc-week-number " + headerClass + "'/>";


    for i in [0...@colCnt] by 1
      cellDate = @_cellDate(0, i); # a little confusing. cellDate is local variable. @_cellDate is private function
      html += "<th class='fc-day-header fc-" + fc.dateUtil.dayIDs[cellDate.getDay()] + " " + headerClass + "'/>";

    html += "</tr></thead><tbody>";

    for i in [0...@rowCnt] by 1
      html += "<tr class='fc-week'>";

      if (@showWeekNumbers)
        html += "<td class='fc-week-number " + contentClass + "'><div/></td>";

      for j in [0...@colCnt] by 1
        cellDate = @_cellDate(i, j); # a little confusing. cellDate is local variable. @_cellDate is private function
        isToday = (+cellDate == +today);

        cellClasses = ['fc-day', 'fc-' + fc.dateUtil.dayIDs[cellDate.getDay()], contentClass];
        cellClasses.push('fc-other-month') if (cellDate.getMonth() != month)

        if (isToday)
          cellClasses.push('fc-today');
          cellClasses.push(@tm + '-state-highlight')

        html += "<td class='" + cellClasses.join(' ') + "' data-date='" + @calendar.options.dateConverter.fromDateToString(cellDate) + "'><div>";
        if (showNumbers)
          day_number = cellDate.getDate()
          html += "<div class='fc-day-number'>" + cellDate.getDate()
          html += fc.dateUtil.formatDate(cellDate, " MMM") if ((day_number == 1) or ( i == 0 and j == 0))
          html += " - today" if (isToday)
          html += "</div>";
        html += "<div class='fc-day-content'><div style='position:relative'>&nbsp;</div></div></div></td>";
      html += "</tr>"
    html += "</tbody></table>";

    @lockHeight(); # the unlock happens later, in setHeight()...
    if @$tableEl
      @$tableEl.table.remove();
    @$tableEl = {}
    @$tableEl.table = $(html).appendTo(@$el);
    @$tableEl.head = @$tableEl.table.find('thead');
    @$tableEl.headCells = @$tableEl.head.find('.fc-day-header');
    @$tableEl.body = @$tableEl.table.find('tbody');
    @$tableEl.bodyRows = @$tableEl.body.find('tr');
    @$tableEl.bodyCells = @$tableEl.body.find('.fc-day');
    @$tableEl.bodyFirstCells = @$tableEl.bodyRows.find('td:first-child');
    @$tableEl.bodyCellTopInners = @$tableEl.bodyRows.eq(0).find('.fc-day-content > div');

    fc.util.markFirstLast(@$tableEl.head.add(@$tableEl.head.find('tr'))); # marks first+last tr/th's
    fc.util.markFirstLast(@$tableEl.bodyRows); # marks first+last td's
    @$tableEl.bodyRows.eq(0).addClass('fc-first');
    @$tableEl.bodyRows.filter(':last').addClass('fc-last');

    if (@showWeekNumbers)
      @$tableEl.head.find('.fc-week-number').text(@weekNumberTitle);

    for _cell, i in @$tableEl.headCells
      date = @indexDate(i)
      $(_cell).text(fc.dateUtil.formatDate(date, @colFormat));


    if (@showWeekNumbers)
      for _cell, i in @$tableEl.body.find('.fc-week-number > div')
        weekStart = @_cellDate(i, 0)
        $(_cell).text(fc.dateUtil.formatDate(weekStart, @weekNumberFormat))



  setHeight: (height) ->
    @viewHeight = height;

    bodyHeight = @viewHeight - @$tableEl.head.height();
    #
    #    var rowHeightLast;
    #    var cell;

    if (@opt('weekMode') == 'variable')
      rowHeight = rowHeightLast = Math.floor(bodyHeight / (@rowCnt==1 ? 2 : 6));
    else
      rowHeight = Math.floor(bodyHeight / @rowCnt);
      rowHeightLast = bodyHeight - rowHeight * (@rowCnt-1);


    for _cell, i in @$tableEl.bodyFirstCells
      if (i < @rowCnt)
        cell = $(_cell);
        height = (if i == @rowCnt-1 then rowHeightLast else rowHeight) - fc.util.vsides(cell)
        fc.util.setMinHeight( cell.find('> div'), height );

    @unlockHeight();



  setWidth: (width) ->
    @viewWidth = width;
    @colContentPositions.clear();

    @weekNumberWidth = 0;
    if (@showWeekNumbers)
      @weekNumberWidth = @$tableEl.head.find('th.fc-week-number').outerWidth();


    @colWidth = Math.floor((@viewWidth - @weekNumberWidth) / @colCnt);
    fc.util.setOuterWidth(@$tableEl.headCells.slice(0, -1), @colWidth);



  #  /* Day clicking and binding
  #  -----------------------------------------------------------*/


  dayClick: (ev) ->
    if !@opt('selectable')  # if selectable, SelectionManager will worry about dayClick
      $element = $(ev.currentTarget)
      date = $element.data('date')
      date = @calendar.options.dateConverter.fromStringToDate(date)
      @calendar.trigger('dayClick', $element, date, ev);

  eventElementHandlers: (event, eventElement) ->
    # do nothing

  eventClick: (ev) ->
    $eventElement = $(ev.currentTarget)
    if !$eventElement.hasClass('ui-draggable-dragging') and !$eventElement.hasClass('ui-resizable-resizing')
      event = $eventElement.data('fc-event')
      @calendar.trigger('eventClick', $eventElement, event, ev);



  #  /* Semi-transparent Overlay Helpers
  #  ------------------------------------------------------*/


  renderDayOverlay: (overlayStart, overlayEnd, refreshCoordinateGrid) -> # overlayEnd is exclusive
    if refreshCoordinateGrid
      @coordinateGrid.build(@$tableEl.headCells, @$tableEl.bodyRows, @rowCnt);


    rowStart = fc.dateUtil.cloneDate(@visStart);
    rowEnd = fc.dateUtil.addDays(fc.dateUtil.cloneDate(rowStart), @colCnt)

    for i in [0...@rowCnt] by 1
      stretchStart = new Date(Math.max(rowStart, overlayStart));
      stretchEnd = new Date(Math.min(rowEnd, overlayEnd));
      if (stretchStart < stretchEnd)
        if (@rtl)
          colStart = fc.dateUtil.dayDiff(stretchEnd, rowStart) * @dis + @dit + 1;
          colEnd = fc.dateUtil.dayDiff(stretchStart, rowStart) * @dis + @dit + 1;
        else
          colStart = fc.dateUtil.dayDiff(stretchStart, rowStart);
          colEnd = fc.dateUtil.dayDiff(stretchEnd, rowStart);

        @renderCellOverlay(i, colStart, i, colEnd-1)

      fc.dateUtil.addDays(rowStart, 7);
      fc.dateUtil.addDays(rowEnd, 7);


  renderCellOverlay: (row0, col0, row1, col1) -> # row1,col1 is inclusive
    rect = @coordinateGrid.rect(row0, col0, row1, col1, element);
    return @overlayManager.renderOverlay(rect, @$el);



  #  /* Selection
  #  -----------------------------------------------------------------------*/


  defaultSelectionEnd: (startDate, allDay)  ->
    return fc.dateUtil.cloneDate(startDate);

  renderSelection: (startDate, endDate, allDay) ->
    @renderDayOverlay(startDate, fc.dateUtil.addDays(fc.dateUtil.cloneDate(endDate), 1), true); # rebuild every time???

  clearSelection: ->
    @overlayManager.clearOverlays();


  reportDayClick: (date, allDay, ev) ->
    cell = dateCell(date);
    _element = @$tableEl.bodyCells[cell.row * @colCnt + cell.col];
    @calendar.trigger('dayClick', _element, date, allDay, ev);


  #  /* External Dragging
  #  -----------------------------------------------------------------------*/


  dragStart: (_dragElement, ev, ui) ->
    f = (cell) ->
      @overlayManager.clearOverlays();
      if (cell)
        renderCellOverlay(cell.row, cell.col, cell.row, cell.col);
    @hoverListener.start(f, ev);


  dragStop: (_dragElement, ev, ui) ->
    cell = @hoverListener.stop();
    @overlayManager.clearOverlays();
    if (cell)
      d = @cellDate(cell);
      @calendar.trigger('drop', _dragElement, d, true, ev, ui);


  #  /* Utilities
  #  --------------------------------------------------------*/

  defaultEventEnd: (event) ->
    return fc.dateUtil.cloneDate(event.start)

  colContentLeft: (col) ->
    return @colContentPositions.left(col);

  colContentRight: (col) ->
    return @colContentPositions.right(col);

  dateCell: (date) ->
    rtn =
      row: Math.floor(fc.dateUtil.dayDiff(date, @visStart) / 7)
      col: dayOfWeekCol(date.getDay())
    return rtn

  cellDate: (cell) ->
    return @_cellDate(cell.row, cell.col);


  _cellDate: (row, col) ->
    return fc.dateUtil.addDays(fc.dateUtil.cloneDate(@visStart), row*7 + col * @dis + @dit);
    # what about weekends in middle of week?

  indexDate: (index) ->
    return @_cellDate(Math.floor(index / @colCnt), index % @colCnt);

  dayOfWeekCol: (dayOfWeek) ->
    return ((dayOfWeek - Math.max(@firstDay, @nwe) + @colCnt) % @colCnt) * @dis + @dit;

  allDayRow: (i) ->
    return @$tableEl.bodyRows.eq(i);

  allDayBounds: (i) ->
    left = 0;
    if @showWeekNumbers
      left += @weekNumberWidth;
    return { left: left,  right: @viewWidth };

  # makes sure height doesn't collapse while we destroy/render new cells
  # (this causes a bad end-user scrollbar jump)
  # TODO: generalize this for all view rendering. (also in Calendar.js)

  lockHeight: ->
    fc.util.setMinHeight(@$el, @$el.height());

  unlockHeight: ->
    fc.util.setMinHeight(@$el, 1);

  #/* Rendering
  #------------------------------------------------------------*/

  render: ->
    fc.util.disableTextSelection(@$el.addClass('fc-grid'));

  renderBasic: (r, c, showNumbers) ->
    @rowCnt = r;
    @colCnt = c;
    @updateOptions();
    if firstTime = !@$tableEl
      @buildEventContainer();
    else
      @clearEvents();
    @buildTable(showNumbers);
