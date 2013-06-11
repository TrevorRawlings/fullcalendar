
function BasicEventRenderer() {
	var t = this;
	
	
	// exports
	t.renderEvents = renderEvents;
	t.compileDaySegs = compileSegs; // for DayEventRenderer
	t.clearEvents = clearEvents;
	t.bindDaySeg = bindDaySeg;
	
	
	// imports
	DayEventRenderer.call(t);
	//var opt = t.opt;
	//var trigger = t.trigger;
	//var setOverflowHidden = t.setOverflowHidden;
	//var isEventDraggable = t.isEventDraggable;
	//var isEventResizable = t.isEventResizable;
	//var reportEvents = t.reportEvents;
	//var reportEventClear = t.reportEventClear;
	//var eventElementHandlers = t.eventElementHandlers;
	//var showEvents = t.showEvents;
	//var hideEvents = t.hideEvents;
	//var t.eventDrop = t.eventDrop;
	//var getDaySegmentContainer = t.getDaySegmentContainer;
	//var getHoverListener = t.getHoverListener;
	//var renderDayOverlay = t.renderDayOverlay;
	//var clearOverlays = t.clearOverlays;
	//var getRowCnt = t.getRowCnt;
	//var getColCnt = t.getColCnt;
	//var renderDaySegs = t.renderDaySegs;
	//var resizableDayEvent = t.resizableDayEvent;
	
	
	
	/* Rendering
	--------------------------------------------------------------------*/
	
	
	function renderEvents(events, modifiedEventId) {
		t.reportEvents(events);
		t.renderDaySegs(compileSegs(events), modifiedEventId);
		t.trigger('eventAfterAllRender');
	}
	
	
	function clearEvents() {
		t.reportEventClear();
		t.getDaySegmentContainer().empty();
	}
	
	
	function compileSegs(events) {
		var rowCnt = t.getRowCnt(),
			colCnt =t.getColCnt(),
			d1 = fc.dateUtil.cloneDate(t.visStart),
			d2 = fc.dateUtil.addDays(fc.dateUtil.cloneDate(d1), colCnt),
			visEventsEnds = $.map(events, fc.util.exclEndDay),
			i, row,
			j, level,
			k, seg,
			segs=[];
		for (i=0; i<rowCnt; i++) {
			row = fc.util.stackSegs(fc.util.sliceSegs(events, visEventsEnds, d1, d2));
			for (j=0; j<row.length; j++) {
				level = row[j];
				for (k=0; k<level.length; k++) {
					seg = level[k];
					seg.row = i;
					seg.level = j; // not needed anymore
					segs.push(seg);
				}
			}
            fc.dateUtil.addDays(d1, 7);
            fc.dateUtil.addDays(d2, 7);
		}
		return segs;
	}
	
	
	function bindDaySeg(event, eventElement, seg) {
		if (t.isEventDraggable(event)) {
			draggableDayEvent(event, eventElement);
		}
		if (seg.isEnd && t.isEventResizable(event)) {
			t.resizableDayEvent(event, eventElement, seg);
		}
		t.eventElementHandlers(event, eventElement);
			// needs to be after, because t.resizableDayEvent might stopImmediatePropagation on click
	}
	
	
	
	/* Dragging
	----------------------------------------------------------------------------*/
	
	
	function draggableDayEvent(event, eventElement) {
		var hoverListener = t.getHoverListener();
		var dayDelta;
		eventElement.draggable({
			zIndex: 9,
			delay: 50,
			opacity: t.opt('dragOpacity'),
			revertDuration: t.opt('dragRevertDuration'),
			start: function(ev, ui) {
				t.trigger('eventDragStart', eventElement, event, ev, ui);
				t.hideEvents(event, eventElement);
				hoverListener.start(function(cell, origCell, rowDelta, colDelta) {
					eventElement.draggable('option', 'revert', !cell || !rowDelta && !colDelta);
					t.clearOverlays();
					if (cell) {
						//setOverflowHidden(true);
						dayDelta = rowDelta*7 + colDelta * (t.opt('isRTL') ? -1 : 1);
						t.renderDayOverlay(
                            fc.dateUtil.addDays(fc.dateUtil.cloneDate(event.start), dayDelta),
                            fc.dateUtil.addDays(fc.util.exclEndDay(event), dayDelta)
						);
					}else{
						//setOverflowHidden(false);
						dayDelta = 0;
					}
				}, ev, 'drag');
			},
			stop: function(ev, ui) {
				hoverListener.stop();
				t.clearOverlays();
				t.trigger('eventDragStop', eventElement, event, ev, ui);
				if (dayDelta) {
					t.eventDrop(this, event, dayDelta, 0, event.allDay, ev, ui);
				}else{
					eventElement.css('filter', ''); // clear IE opacity side-effects
					t.showEvents(event, eventElement);
				}
				//setOverflowHidden(false);
			}
		});
	}


}
