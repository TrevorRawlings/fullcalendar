
class fc.Navigate

  constructor: (calendar)  ->
    @calendar = calendar

  prev: ->
    fc.dateUtil.addMonths(@calendar.date, -1, false)
    @calendar.renderView(-1)

  next: ->
    fc.dateUtil.addMonths(@calendar.date, 1, false)
    @calendar.renderView(1)

  prevYear: ->
    fc.dateUtil.addYears(@calendar.date, -1)
    @calendar.renderView(1)

  nextYear: ->
    fc.dateUtil.addYears(@calendar.date, 1)
    @calendar.renderView(1)

  _before_MoveBy_Month: ->
    currentMonth = fc.dateUtil.center_date(@calendar.currentView.visStart, @calendar.currentView.visEnd)
    @calendar.date = moment(currentMonth).startOf('month').toDate();

  prevMonth: ->
    @_before_MoveBy_Month()
    fc.dateUtil.addMonths(@calendar.date, -1)
    @calendar.renderView(1)

  nextMonth: ->
    @_before_MoveBy_Month()
    fc.dateUtil.addMonths(@calendar.date, 1)
    @calendar.renderView(1)

  prevWeek: ->
    fc.dateUtil.addDays(@calendar.date, -7)
    @calendar.renderView(1)

  nextWeek: ->
    fc.dateUtil.addDays(@calendar.date, 7)
    @calendar.renderView(1)

  today: ->
    @calendar.date = new Date()
    @calendar.renderView(1)

  gotoDate: (year, month, dateOfMonth) ->
    if (year instanceof Date)
      @calendar.date = fc.dateUtil.cloneDate(year); # provided 1 argument, a Date
    else
      fc.dateUtil.setYMD(@calendar.date, year, month, dateOfMonth);
    @calendar.renderView(1);

  incrementDate: (years, months, days) ->
    fc.dateUtil.addYears(@calendar.date, years) if !_.isUndefined(years)
    fc.dateUtil.addMonths(@calendar.date, months) if !_.isUndefined(months)
    fc.dateUtil.addDays(@calendar.date, days) if !_.isUndefined(days)
    @calendar.renderView(1)

  getDate: ->
    return fc.dateUtil.cloneDate(@calendar.date)
