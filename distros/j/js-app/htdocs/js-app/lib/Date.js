
function DateWidget () {
    this.init = init;
    function init () {
        var n = this.serviceName;
        var value = context.getValue(n);
        if (value == null && this["default"] != null) {
            value = this["default"];
            context.setValue(this.serviceName, null, value);
            
        }
        if (value) {
            this.year  = value.substring(0, 4);  // YYYY
            this.month = value.substring(5, 7);  // MM
            this.day   = value.substring(8, 10); // DD
        }
        else {
            // initialize with current date
            var d = new Date();
            // initialize year
            if (d.getFullYear) {
               this.year = d.getFullYear();
            }
            else {
               this.year = d.getYear();
               if (this.year < 1000) this.year += 1900;
            }
            // initialize month
            var m = d.getMonth() + 1;
            if (m < 10) m = "0" + m;
            else        m = "" + m;
            this.month = m;
            // initialize day
            var d = d.getDate();
            if (d < 10) d = "0" + d;
            else        d = "" + d;
            this.day = d;

            value = this.year + "-" + this.month + "-" + this.day;
            context.setValue(this.serviceName, null, value);
        }

        var dayConf = {
            serviceClass : "SelectWidget",
            domain : "date-day",
            onChange : 1
        };
        var monthConf = {
            serviceClass : "SelectWidget",
            domain : "date-month",
            onChange : 1
        };
        var yearConf = {
            serviceClass : "TextFieldWidget",
            size : 4,
            maxlength : 4,
            onChange : 1
        };
        context.widget(n + "-day",   dayConf);
        context.widget(n + "-month", monthConf);
        context.widget(n + "-year",  yearConf);
    }
    this.html = html;
    function html () {
        var n = this.serviceName;
        var html = '<table border="0" cellspacing="0" cellpadding="0"' + this.stdAttribs() + '><tr><td>\n' +
            context.widget(n + "-day").html() + '</td><td>\n' +
            context.widget(n + "-month").html() + '</td><td>\n' +
            context.widget(n + "-year").html() + 
            (this.submittable ? this.hiddenValue() : "") +
            '</td></tr></table>\n';
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        var handled = 0;
        var changed = 0;
        if (eventName == "change") {
            var s = context.service("SessionObject", thisServiceName);
            var valid = 1;
            var day   = context.getDOMValue(thisServiceName + "-day");
            var month = context.getDOMValue(thisServiceName + "-month");
            var year  = context.getDOMValue(thisServiceName + "-year");
            var yearnum = Number(year);
            var date;
            // alert("so.handleEvent(" + thisServiceName + "," + eventServiceName + "," + eventName + ")\n" +
            //     "year=" + year + " : s.year=" + s.year + "\n" +
            //     "month=" + month + " : s.month=" + s.month + "\n" +
            //     "day=" + day + " : s.day=" + s.day);
            if (year.length != 4 || yearnum + "" != year) {
                valid = 0;
                context.setDOMValue(thisServiceName + "-year",  s.year);
            }
            else {
                if (month == "02") {
                    var isLeap = (yearnum % 4 == 0 && (yearnum % 100 != 0 || yearnum % 400 == 0));
                    if (isLeap) {
                        if (day == "31" || day == "30") {
                            day = "29";
                            context.setDOMValue(thisServiceName + "-day",  day);
                        }
                    }
                    else {
                        if (day == "31" || day == "30" || day == "29") {
                            day = "28";
                            context.setDOMValue(thisServiceName + "-day",  day);
                        }
                    }
                }
                else if (month == "04" || month == "06" || month == "09" || month == "11") {
                    if (day == "31") {
                        day = "30";
                        context.setDOMValue(thisServiceName + "-day",  day);
                    }
                }
            }
            if (valid) {
                s.day   = day;
                s.month = month;
                s.year  = year;
                date = year + "-" + month + "-" + day;
                s.setCurrentValue(date);
                if (s.submittable) {
                    context.setDOMValue(thisServiceName, date);
                }
                DateWidget.prototype.handleEvent(s.container(thisServiceName), thisServiceName, "change");
            }
            handled = 1;
        }
        else {
            handled = DateWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs);
        }
        return(handled);
    }
}
DateWidget.prototype = new Widget();

