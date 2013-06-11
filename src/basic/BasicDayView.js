
fc.views.basicDay = BasicDayView;

//TODO: when calendar's date starts out on a weekend, shouldn't happen


function BasicDayView(element, calendar) {
	var t = this;
	
	
	// exports
	t.render = render;
	
	
	// imports
	BasicView.call(t, element, calendar, 'basicDay');
	var opt = t.opt;
	var renderBasic = t.renderBasic;
	//var formatDate = calendar.formatDate;
	
	
	
	function render(date, delta) {
		if (delta) {
            fc.dateUtil.addDays(date, delta);
			if (!opt('weekends')) {
                fc.dateUtil.skipWeekend(date, delta < 0 ? -1 : 1);
			}
		}
		t.title = fc.dateUtil.formatDate(date, opt('titleFormat'));
		t.start = t.visStart = fc.dateUtil.cloneDate(date, true);
		t.end = t.visEnd = fc.dateUtil.addDays(fc.dateUtil.cloneDate(t.start), 1);
		renderBasic(1, 1, false);
	}
	
	
}
