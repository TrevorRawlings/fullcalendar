

#fc.addDays = addDays;
#fc.cloneDate = cloneDate;
#fc.parseDate = parseDate;
#fc.parseISO8601 = parseISO8601;
#fc.parseTime = parseTime;
#fc.formatDate = formatDate;
#fc.formatDates = formatDates;



#/* Date Math
#-----------------------------------------------------------------------------*/


class fc.DateUtil

  dayIDs: ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'],
  DAY_MS: 86400000,
  HOUR_MS: 3600000,
  MINUTE_MS: 60000;


  addYears: (d, n, keepTime) ->
    m = moment(d).add('years', n)
    m.startOf('day') if !keepTime
    return m.toDate()

  addMonths: (d, n, keepTime) -> # prevents day overflow/underflow
    m = moment(d).add('months', n)
    m.startOf('day') if !keepTime
    return m.toDate()

  addDays: (d, n, keepTime) -> # deals with daylight savings
    m = moment(d).add('days', n)
    m.startOf('day') if !keepTime
    return m.toDate()

  #function fixDate(d, check) { // force d to be on check's YMD, for daylight savings purposes
  #	if (+d) { // prevent infinite looping on invalid dates
  #		while (d.getDate() != check.getDate()) {
  #			d.setTime(+d + (d < check ? 1 : -1) * HOUR_MS);
  #		}
  #	}
  #}

  addMinutes: (d, n) ->
    m = moment(d).add('minutes', n)
    return m.toDate()

  clearTime: (d) ->
    return moment(d).startOf('day').toDate()

  cloneDate: (d, dontKeepTime) ->
    m = moment(d).clone()
    m.startOf('day') if dontKeepTime
    return m.toDate()



  #  zeroDate() { // returns a Date with time 00:00:00 and dateOfMonth=1
  #	var i=0, d;
  #	do {
  #		d = new Date(1970, i++, 1);
  #	} while (d.getHours()); // != 0
  #	return d;
  #}

  days_numbers:
   "sunday": 0
   "monday": 1
   "tuesday": 2
   "wednesday": 3
   "thursday": 4
   "friday": 5
   "saturday": 6

  # skipWeekend
  # -----------
  #
  # increment: direction of skip (1 = up, -1 = down)
  # exclude:   days to exclude
  #
  # weekday[0]="Sunday";
  # weekday[1]="Monday";
  # weekday[2]="Tuesday";
  # weekday[3]="Wednesday";
  # weekday[4]="Thursday";
  # weekday[5]="Friday";
  # weekday[6]="Saturday";
  #
  skipWeekend: (date, increment = 1, exclude = [0, 6])  ->
    throw "skipWeekend: expected -1 or 1" if increment != 1 and increment != -1
    m = moment(d)

    for day, i in exclude when _.isString(day)
      number = @days_numbers[day.downcase()]
      throw "day #{day} is invalid" if !_.isNumber(number)
      exclude[i] = number

    while _.contains(exclude, m.toDate().getDay())
      m.add('days', increment)
    return m.toDate()

  dayDiff: (d1, d2) -> # d1 - d2
    return moment(d1).diff(d2, 'days')


  setYMD: (date, year, month, day)  ->
    m = moment(date)

    if !_.isUndefined(year) and year != m.toDate().getFullYear()
      m.year(year).startOf('year')

    if !_.isUndefined(month) and month != m.toDate().getMonth()
      m.month(month).startOf('month')

    if !_.isUndefined(day)
      m.date(day)

    return m.toDate()

  center_date:  (visStart, visEnd) ->
    visStart = moment(visStart);
    visEnd = moment(visEnd);
    days = visEnd.diff(visStart, 'days');
    return visStart.clone().add('days', (days / 2)).toDate();


  #/* Date Parsing
  #-----------------------------------------------------------------------------*/
  #
  parseDate: (s, ignoreTimezone) ->
    throw "expected a date object" if !_.isDate(s)
    return s


  parseTime: (s) -> # returns minutes since start of day
    if _.isNumber(s) # an hour
      return s * 60;

    if _.isDate(s) # a Date object
      return s.getHours() * 60 + s.getMinutes()

    m = s.match(/(\d+)(?::(\d+))?\s*(\w+)?/);
    if (m)
      h = parseInt(m[1], 10);
      if m[3]
        h %= 12
        if m[3].toLowerCase().charAt(0) == 'p'
          h += 12;

      m = if m[2] then parseInt(m[2], 10) else 0
      return h * 60 + m
    return null



  #/* Date Formatting
  #-----------------------------------------------------------------------------*/
  #// TODO: use same function formatDate(date, [date2], format, [options])


  formatDate: (date, format, options) ->
    @formatDates(date, null, format, options)

  formatDates: (date1, date2, format, options) ->
    return moment(date1).format(format)


  #/* thanks jQuery UI (https://github.com/jquery/jquery-ui/blob/master/ui/jquery.ui.datepicker.js)
  # *
  # * Set as calculateWeek to determine the week of the year based on the ISO 8601 definition.
  # * @param  date  Date - the date to get the week for
  # * @return  number - the number of the week within the year that contains this date
  # */
  # moment.isoWeek()
  iso8601Week: (date) ->
    return moment(date).isoWeek()

fc.dateUtil = new fc.DateUtil()