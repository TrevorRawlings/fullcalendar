


class MonthView extends fc.BasicView
  className: "fc-view fc-view-month fc-grid"


  initialize: (options = {}) ->
    options.viewName = 'month'
    super



  render: (date, delta) ->

    start = fc.dateUtil.cloneDate(date, true);
    end = fc.dateUtil.addMonths(fc.dateUtil.cloneDate(start), 1);
    visStart = fc.dateUtil.cloneDate(start);
    visEnd = fc.dateUtil.cloneDate(end);
    firstDay = @opt('firstDay');
    not_weekends = !@opt('weekends');
    if (not_weekends)
      fc.dateUtil.skipWeekend(visStart);
      fc.dateUtil.skipWeekend(visEnd, -1, ['Sunday', 'Monday']);

    fc.dateUtil.addDays(visStart, -((visStart.getDay() - Math.max(firstDay, not_weekends) + 7) % 7));
    fc.dateUtil.addDays(visEnd, (7 - visEnd.getDay() + Math.max(firstDay, not_weekends)) % 7);

    rowCnt = fc.dateUtil.dayDiff(visEnd, visStart) / 7;
    if @opt('weekMode') == 'fixed'
      fc.dateUtil.addDays(visEnd, (6 - rowCnt) * 7);
      rowCnt = 6;
    columnCnt = if not_weekends then 5 else 7

    @title = fc.dateUtil.formatDate(@center_date(visStart, visEnd), @opt('titleFormat'));
    @start = start;
    @end = end;
    @visStart = visStart;
    @visEnd = visEnd;
    @renderBasic(rowCnt, columnCnt, true);

fc.views.month = MonthView;
