// insure jslib base is loaded
if (typeof(JS_LIB_LOADED)=='boolean') 
{
  // these two consts below are specifically used for jslib 
  const JS_DATE_LOADED      = true;
  const JS_FILE_DATE        = "date.js";

  const DEFAULT_DATE_FORMAT = "d.m.Y - H:i:s";
  
  /**
   * The month- and weekdayname is to be stored
   * in a dtd language dependent file.
   */
  var month = new Array(
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  );
  
  var weekday = new Array(
    "Sunday",
    "Monday",
    "Tuesday",
    "Wedensday",
    "Thursday",
    "Friday",
    "Saturday"
  );
  
  
  /**
   * Returns a string formatted according to the given 
   * format string using the given date object
   */
  function jslibDate(aDateString, aDate) 
  {
    if (arguments.length<1)
      aDateString = DEFAULT_DATE_FORMAT;
  
    var date = aDate;
    if (arguments.length<2)
      date = (new Date);
  
    var datePatterns = new Array(
      // Lowercase Ante meridiem and Post meridiem
      new Array(new RegExp(/([^\\])a|^a()/g), addSlashes(getMeridiem(getHours(aDate)))),

      //  Uppercase Ante meridiem and Post meridiem
      new Array(new RegExp(/([^\\])A|^A()/g), 
                addSlashes(getMeridiem(getHours(aDate)).toUpperCase())),

      // Swatch internet time
      new Array(new RegExp(/([^\\])B|^B()/g), getSwatchInternetTime(date)),

      // Day of the month, 2 digits with leading zeros
      new Array(new RegExp(/([^\\])d|^d()/g), insertLeadingZero(date.getDate())),

      // A textual representation of a week, three letters
      new Array(new RegExp(/([^\\])D|^D()/g), addSlashes(weekday[date.getDay()].substr(0,3))),

      // A full textual representation of a month
      new Array(new RegExp(/([^\\])F|^F()/g), addSlashes(month[date.getMonth()])),

      // 12-hour format of an hour without leading zeros
      new Array(new RegExp(/([^\\])g|^g()/g), twelveHour(aDate)),

      // 24-hour format of an hour without leading zeros
      new Array(new RegExp(/([^\\])G|^G()/g), getHours(aDate)),

      // 12-hour format of an hour with leading zeros
      new Array(new RegExp(/([^\\])h|^h()/g), insertLeadingZero(twelveHour(aDate))),

      // 24-hour format of an hour with leading zeros
      new Array(new RegExp(/([^\\])H|^H()/g), insertLeadingZero(getHours(aDate))),

      // Minutes with leading zeros
      new Array(new RegExp(/([^\\])i|^i()/g), insertLeadingZero(date.getMinutes())),

      // Whether or not the date is in daylights savings time
      new Array(new RegExp(/([^\\])I|^I()/g), ""),

      // Day of the month without leading zeros
      new Array(new RegExp(/([^\\])j|^j()/g), date.getDate()),

      // A full textual representation of the day of the week
      new Array(new RegExp(/([^\\])l|^l()/g), addSlashes(weekday[date.getDay()])),

      // Whether it's a leap year
      new Array(new RegExp(/([^\\])L|^L()/g), leapYear(date.getFullYear())),

      // Numeric representation of a month, with leading zeros
      new Array(new RegExp(/([^\\])m|^m()/g), insertLeadingZero(date.getMonth()+1)),

      // A short textual representation of a month, three letters
      new Array(new RegExp(/([^\\])M|^M()/g), addSlashes(month[date.getMonth()].substr(0,3))),

      // Numeric representation of a month, without leading zeros
      new Array(new RegExp(/([^\\])n|^n()/g), date.getMonth()+1),

      // Difference to Greenwich time (GMT) in hours
      new Array(new RegExp(/([^\\])O|^O()/g), getGTMDifference(date)),

      // RFC 822 formatted date
      new Array(new RegExp(/([^\\])r|^r()/g), getRFCDate(date)),

      // Seconds, with leading zeros
      new Array(new RegExp(/([^\\])s|^s()/g), insertLeadingZero(date.getSeconds())),

      // English ordinal suffix for the day of the month, 2 characters
      new Array(new RegExp(/([^\\])S|^S()/g), addSlashes(getDateSuffix(date.getDate()))),

      // Number of days in the given month
      new Array(new RegExp(/([^\\])t|^t()/g), getDaysInMonth(date)),

      // Timezone setting of this machine
      new Array(new RegExp(/([^\\])T|^T()/g), ""),

      // Miliseconds since the Unix Epoch (January 1 1970 00:00:00 GMT)
      new Array(new RegExp(/([^\\])U|^U()/g), date.getTime()),

      // Numeric representation of the day of the week
      new Array(new RegExp(/([^\\])w|^w()/g), date.getDay()),

      // ISO-8601 week number of year, weeks starting on Monday
      new Array(new RegExp(/([^\\])W|^W()/g), getWeekNumber(date)),

      // A two digit representation of a year
      new Array(new RegExp(/([^\\])y|^y()/g), (""+date.getFullYear()).substr(2,2)),

      // A full numeric representation of a year, 4 digits
      new Array(new RegExp(/([^\\])Y|^Y()/g), date.getFullYear()),

      // The day of the year
      new Array(new RegExp(/([^\\])z|^z()/g), getNumberOfDays(date)),

      // Timezone offset in seconds. The offset for timezones west of 
      // UTC is always negative, and for those east of UTC is always positive.
      new Array(new RegExp(/([^\\])Z|^Z()/g), getTimezoneOffset(date)),
  
      // Replace all backslashes followed by a letter with the letter
      new Array(new RegExp(/\\([A-Za-z])/g), "")
    );
  
    var datePattern;
    while ((datePattern = datePatterns.shift()))
      aDateString = aDateString.replace(datePattern[0], "$1" + datePattern[1]);
  
    return aDateString;
  }
  // deprecated
  var date = jslibDate;
  
  /**
   * Returns the hour in a 12-hour format
   */
  function twelveHour(aDate) 
  {
    var hour;
    if (aDate)
      hour = aDate.getHours();
    else
      hour = (new Date()).getHours();
    if ( getMeridiem(hour)=="pm" )
      hour -= 12;
    if ( hour==0 )
      hour = 12;

    return hour;
  }
  
  
  /**
   * Returns lowercase am or pm based on the given 24-hour
   */
  function getMeridiem(hour) 
  {
    if ( hour>11 )
      return "pm";
    else
      return "am";
  }
  
  
  /**
   * Return true if year is a leap year otherwise false
   */
  function leapYear(year) 
  {
    //The Date object automatic corrigates if values is out of limit
    //29 isn't out of limit if it is leap year!
    var date = new Date(year, 1, 29);
    if ( date.getMonth()==1 )
      return 1;
    else
      return 0;
  }
  
  
  /**
   * Returns the number of days from new year to current date (incl current day)
   */
  function getNumberOfDays(date) 
  {
    var currentDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    var startOfYear = new Date(date.getFullYear(), 0, 1);

    return ( currentDate.getTime()-startOfYear.getTime() )/86400000 +1;
  }
  
  
  /**
   * Returns the number of days in the current month of the date object
   */
  function getDaysInMonth(date) 
  {
    var currentDate = new Date(date.getFullYear(), date.getMonth()+1, 0);
    var startOfYear = new Date(date.getFullYear(), date.getMonth(), 1);

    return ( currentDate.getTime()-startOfYear.getTime() )/86400000 +1;
  }


  /**
   * Returns the english ordinal suffix for the day of the month, 2 characters
   */
  function getDateSuffix(dayOfMonth) 
  {
    var rv = null;
    if ( dayOfMonth>3 && dayOfMonth<21 ) {
      rv = "th";
    } else {
      switch( dayOfMonth%10 ) {
        case 1:
          rv = "st";
          break;
        case 2:
          rv = "nd";
          break;
        case 3:
          rv = "rd";
          break;
        default:
          rv = "th";
          break;
      }
    }
    return rv;
  }  


  function daylightSavingsTime(date) 
  {
    return 0;
  }

  /**
   * Timezone offset in seconds
   * -43200 through 43200
   */
  function getTimezoneOffset(date) 
  {
    return date.getTimezoneOffset()*(-60);
  }


  /**
   * This function isn't implemented yet, but here is an idea of how it might look
   * Before thins function can be made the function daylightSavingsTime() have 
   * to be written
   * http://www.timeanddate.com/time/abbreviations.html
   * http://setiathome.ssl.berkeley.edu/utc.html
   */
  function getTimezone(date) 
  {
    if ( daylightSavingsTime(date)==1 ) {
      switch(getTimezoneOffset(date)/3600) {
        case -11:
          return "";
          break;
//..........
        case 0:
          return "";
          break;
        case 1:
          return "WEST";
          break;
        case 2:
          return "CEST";
          break;
        case 3:
          return "EEST";
          break;
//............
        case 12:
          return "";
          break;
        default:
          return "";
          break;
      }
    }
    else {
      switch(getTimezoneOffset(date)/3600) {
        case -11:
          return "";
          break;
//..........
        case 0:
          return "";
          break;
        case 1:
          return "WET";
          break;
        case 2:
          return "CET";
          break;
        case 3:
          return "EET";
          break;
//............
        case 12:
          return "";
          break;
        default:
          return "";
          break;
      }
    }
    return "";
  }


  /**
   * Difference to Greenwich time (GMT) in hours
   */
  function getGTMDifference(date) 
  {
    var offset = getTimezoneOffset(date)/3600;
    if (offset>0) //adding leading zeros and gives the offset a positive prefix
      return "+" + insertLeadingZero(offset)      + "00";
    else  //if negative, make the offset positive before adding leading zeros and give the number a negative prefix
      return "-" + insertLeadingZero(offset*(-1)) + "00";
  }
  

  /**
   * In [ISO8601], the week number is defined by:
   * - weeks start on a monday
   * - week 1 of a given year is the one that includes the first 
   *   Thursday of that year.
   *   (or, equivalently, week 1 is the week that includes 4 January.)
   * Weeknumbers can be a number between 1 - 53 (53 is not common)
   */
  function getWeekNumber(date) 
  {
    var weekday = date.getDay();
    if (weekday==0)
      weekday = 7;

    //currentDate is on the fist monday in the same week of date (could be the same date)
    var currentDate = new Date(date.getFullYear(), date.getMonth(), date.getDate()-(weekday-1));
    var startOfYear = new Date(currentDate.getFullYear(), 0, 1);

    var firstWeekday = startOfYear.getDay();

    var extraDays;
    if ( 5>firstWeekday )
      extraDays = firstWeekday-1;
    else
      extraDays = firstWeekday-8;

    //var numberOfDays = ( ( currentDate.getTime()-startOfYear.getTime() )/86400000 ) + extraDays;
    //var weekNumber = numberOfDays/7 +1; 

    return ( ( ( currentDate.getTime()-startOfYear.getTime() )/86400000 ) + extraDays )/7 +1;
  }


  /**
   * RFC 822 formatted
   * http://www.freesoft.org/CIE/RFC/822/39.htm
   */
  function getRFCDate(aDate) 
  {
    var dayRFC  = addSlashes(weekday[aDate.getDay()].substr(0,3));
    var dateRFC = aDate.getDate() + " " + addSlashes(month[aDate.getMonth()].substr(0,3)) 
                + " " + (""+aDate.getFullYear()).substr(2,2);
    var timeRFC = insertLeadingZero(aDate.getHours()) + ":" 
                + insertLeadingZero(aDate.getMinutes()) + ":" 
                + insertLeadingZero(aDate.getSeconds()) + " " + getGTMDifference(aDate);
    return dayRFC + ", " + dateRFC + " " + timeRFC;
  }  
  

  /**
   * 1min 26.4sek = 1 Swatch beat
   * (60sek + 26.4sek)*1000milliseconds/second = 86400miliseconds = 1 Swatch beat
   */
  function getSwatchInternetTime(aDate) 
  {
    // A day in Internet Time begins at midnight BMT (@000 Swatch Beats) 
    // (Central European Wintertime) (+0100 from GTM)
    // This line makes the Date object corrigate if the hour is 23 then it 
    // will be set to 0 and the date will be incremented

    var h = aDate.getUTCHours();
    var nDate = new Date(aDate); 
    nDate.setUTCHours(h+1);

    var milliseconds = Date.UTC(1970, 0, 1, 
                                nDate.getUTCHours(), 
                                nDate.getUTCMinutes(), 
                                nDate.getUTCSeconds());

    return "@" + ( milliseconds-( milliseconds%86400 ) )/86400;
  }


  /**
   * Some of the numbers needs leading zeros
   * and this function returns the number with a leading zero
   * if the number is smaller than 10
   */
  function insertLeadingZero(number) 
  {
   if (number < 10)
      number = "0" + number;
    return number;
  }


  /**
   * This function is used to make every second character a backslash
   * so the insterted charaters isn't converted to hours, dates and so on.
   */
  function addSlashes(string) 
  {
    var stringTemp = "";
    for(var x=0; x<string.length; x++) {
      stringTemp += "\\";
      stringTemp += string.substr(x, 1);
    }
    return stringTemp;
  }
  
  function getHours (aDate)
  {
    var rv;
    if (aDate)
      rv = aDate.getHours();
    else
      rv = (new Date()).getHours();

    return rv;
  }

  jslibLoadMsg(JS_FILE_DATE);

} else { dump("Load Failure: date.js\n"); }
