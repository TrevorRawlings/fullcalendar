
fc.views.agendaDay = AgendaDayView;

function AgendaDayView(element, calendar) {
	var t = this;
	
	
	// exports
	t.render = render;
	
	
	// imports
	AgendaView.call(t, element, calendar, 'agendaDay');
	var opt = t.opt;
	var renderAgenda = t.renderAgenda;
	//var formatDate = calendar.formatDate;
	
	
	
	function render(date, delta) {
		if (delta) {
            fc.dateUtil.addDays(date, delta);
			if (!opt('weekends')) {
                fc.dateUtil.skipWeekend(date, delta < 0 ? -1 : 1);
			}
		}
		var start = fc.dateUtil.cloneDate(date, true);
		var end = fc.dateUtil.addDays(fc.dateUtil.cloneDate(start), 1);
		t.title = fc.dateUtil.formatDate(date, opt('titleFormat'));
		t.start = t.visStart = start;
		t.end = t.visEnd = end;
		renderAgenda(1);
	}
	

}
