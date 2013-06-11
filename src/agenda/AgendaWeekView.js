
fc.views.agendaWeek = AgendaWeekView;

function AgendaWeekView(element, calendar) {
	var t = this;
	
	
	// exports
	t.render = render;
	
	
	// imports
	AgendaView.call(t, element, calendar, 'agendaWeek');
	var opt = t.opt;
	var renderAgenda = t.renderAgenda;
	//var formatDates = calendar.formatDates;
	
	
	
	function render(date, delta) {
		if (delta) {
            fc.dateUtil.addDays(date, delta * 7);
		}
		var start = fc.dateUtil.addDays(fc.dateUtil.cloneDate(date), -((date.getDay() - opt('firstDay') + 7) % 7));
		var end = fc.dateUtil.addDays(fc.dateUtil.cloneDate(start), 7);
		var visStart = fc.dateUtil.cloneDate(start);
		var visEnd = fc.dateUtil.cloneDate(end);
		var weekends = opt('weekends');
		if (!weekends) {
            fc.dateUtil.skipWeekend(visStart);
            fc.dateUtil.skipWeekend(visEnd, -1, ['Sunday', 'Monday']);
		}
		t.title = fc.dateUtil.formatDates(
			visStart,
            fc.dateUtil.addDays(fc.dateUtil.cloneDate(visEnd), -1),
			opt('titleFormat')
		);
		t.start = start;
		t.end = end;
		t.visStart = visStart;
		t.visEnd = visEnd;
		renderAgenda(weekends ? 7 : 5);
	}
	

}
