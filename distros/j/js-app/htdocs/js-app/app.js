// ******************************************************************
// * js-app/app.js
// ******************************************************************
// * A primary design goal of JS-App is to support maximum browser
// * compatibility.  At the same time, we want our core software to
// * be riding the wave of the latest standard functionality.
// * 
// * To do this, we start by loading the init.js file.
// * This file must always be compatible (in syntax) with the very
// * oldest Javascript versions ever implemented.  Its job is to
// * decide which other Javascript files must be loaded in order
// * to provide the full functionality.
// ******************************************************************

var context = new Context();
if (!window.appConf) {
    var appConf = new Object();
}
if (!appConf.global) {
    appConf.global = new Object();
}
context.importJavascript();
context.importCss();
context.importAppFiles();  // latest-defined CSS rules take precedence

function Context () {
    this.session = new Object();
    this.cache   = new Object();

    this.onLoadEvents = [];

    // onLoad() starts the program running.
    // If there is content in the HTML <body>, the program is
    // already "running".
    this.onLoad = onLoad;
    function onLoad () {
        var e;
        for (e = 0; e < this.onLoadEvents.length; e++) {
            this.sendEvent(this.onLoadEvents[e]);
        }
    }

    this.callOnLoad = callOnLoad;
    function callOnLoad (evt) {
        this.sendEvent.push(evt);
    }

    this.service = service;
    function service (serviceType, serviceName, codedConf) {
        // alert("context.service(" + serviceType + "," + serviceName + "," + codedConf + ")");
        var s;
        if (this.cache[serviceType] != null &&
            this.cache[serviceType][serviceName] != null) {
            s = this.cache[serviceType][serviceName];
        }
        else {
            // get the serviceConf
            var serviceConf;
            if (appConf[serviceType]) {
                if (appConf[serviceType][serviceName] != null) {
                    serviceConf = appConf[serviceType][serviceName];
                }
            }
            // alert("service(" + serviceType + "," + serviceName + "," + codedConf + ") : conf=" + serviceConf);
            if (!serviceConf && codedConf) {
                serviceConf = codedConf;
            }

            // get the serviceTypeConf
            var serviceTypeName, serviceTypeType, serviceTypeConf;
            if (serviceConf != null) {
                serviceTypeName = serviceConf.serviceType;
            }
            if (serviceTypeName == null) {
                serviceTypeName = "default";
            }
            serviceTypeType = serviceType + "Type";
            if (appConf[serviceTypeType] != null) {
                if (appConf[serviceTypeType][serviceTypeName] != null) {
                    serviceTypeConf = appConf[serviceTypeType][serviceTypeName];
                }
            }

            // get serviceClass
            var serviceClass;
            if (serviceConf != null && serviceConf.serviceClass != null) {
                serviceClass = serviceConf.serviceClass;
            }
            else if (serviceTypeConf != null && serviceTypeConf.serviceClass != null) {
                serviceClass = serviceTypeConf.serviceClass;
            }
            else {
                serviceClass = serviceType;
            }

            // construct an instance of the class
            var serviceConstructor = 'var s = new ' + serviceClass + '();';
            // alert(serviceConstructor);
            eval(serviceConstructor);

            // initialize some standard attributes
            this.copyObject(serviceConf, s);
            this.copyObject(serviceTypeConf, s);
            s.serviceName  = serviceName;
            s.serviceType  = serviceType;
            s.serviceClass = serviceClass;
            if (this.cache[serviceType] == null) {
                this.cache[serviceType] = new Object();
            }
            this.cache[serviceType][serviceName] = s;

            s.init();
        }
        return(s);
    }

    this.repository = repository;
    function repository (serviceName,conf) {
        return(this.service("Repository",serviceName,conf));
    }

    this.sessionObject = sessionObject;
    function sessionObject (serviceName,conf) {
        return(this.service("SessionObject",serviceName,conf));
    }

    this.dictionary = dictionary;
    function dictionary (serviceName,conf) {
        return(this.service("Dictionary",serviceName,conf));
    }

    this.defaultWidget = defaultWidget;
    function defaultWidget (conf) {
        var serviceName = appOptions.defaultWidgetName;
        if (serviceName == null) {
            serviceName = "default";
        }
        return(this.service("SessionObject",serviceName,conf));
    }

    this.widget = widget;
    function widget (serviceName,conf) {
        return(this.service("SessionObject",serviceName,conf));
    }

    this.sendEvent = sendEvent;
    function sendEvent (serviceName, eventName, eventArgs) {
        var serviceType, event;
        serviceType = "SessionObject";  // make the assumption
        if (typeof serviceName == "object") {
            event = serviceName;
            serviceType = event.serviceType || "SessionObject";
            serviceName = event.serviceName;
            eventName   = event.eventName;
            eventArgs   = event.eventArgs;
        }
        // alert("context.sendEvent(" + serviceName + "," + eventName + ", ...)");
        var s = this.service(serviceType,serviceName);
        // if (s[eventName] && typeof s[eventName] == "function") {
        // }
        // else {
            s.handleEvent(serviceType, serviceName, eventName, eventArgs);
        // }
        // return(false) causes <input onClick="..."> handlers not to continue with form submission
        return(false);
    }

    this.getValue = getValue;
    function getValue (serviceName, attrib, valueDefault, setDefault) {
        var s, container, value, pos;
        if (serviceName) {
            if (typeof serviceName == "string") {
                if (!attrib) {
                    pos = serviceName.lastIndexOf("-");
                    if (pos >= 0) {
                        attrib = serviceName.substring(pos+1,serviceName.length);
                        serviceName = serviceName.substring(0,pos);
                    }
                    else {
                        attrib = serviceName;
                        serviceName = "default";
                    }
                }
                s = this.service("SessionObject", serviceName);
                if (!s) return(null);
            }
            else {
                s = serviceName;
            }
            value = s[attrib];
        }
        if (value == null && valueDefault != null) {
            value = valueDefault;
            if (setDefault) s[attrib] = value;
        }
        return(value);
    }

    this.setValue = setValue;
    function setValue (serviceName, attrib, value) {
        if (!serviceName) return(null);
        var s, container, value, pos;
        if (typeof serviceName == "string") {
            if (!attrib) {
                pos = serviceName.lastIndexOf("-");
                if (pos >= 0) {
                    attrib = serviceName.substring(pos+1,serviceName.length);
                    serviceName = serviceName.substring(0,pos);
                }
                else {
                    attrib = serviceName;
                    serviceName = "default";
                }
            }
            s = this.service("SessionObject", serviceName);
            if (!s) return(null);
        }
        else {
            s = serviceName;
        }
        s[attrib] = value;
    }

    this.getValues = getValues;
    function getValues (serviceName, attrib, valueDefault, setDefault) {
        return(this.getValue(serviceName, attrib, valueDefault, setDefault).split(","));
    }

    this.setValues = setValues;
    function setValues (serviceName, attrib, values) {
        return(this.setValue(serviceName, attrib, values.join(",")));
    }

    // copies attributes from SRC to DST without overwriting anything
    this.copyObject = copyObject;
    function copyObject (src, dst) {
        var attrib;
        for (attrib in src) {
            if (dst[attrib] == null) {
                dst[attrib] = src[attrib];
            }
        }
    }

    this.dumpValue = dumpValue;
    function dumpValue (val, varName, op, indent, maxDepth) {
        var dump, attrib, i, indentSpaces, first, attribType;
        indentSpaces = "";
        for (i = 0; i < indent; i++) {
            indentSpaces += "   ";
        }
        // alert("context.dumpValue(" + val + "," + varName + "," + op + "," + indent + "," + maxDepth + ") = " + typeof(val));
        switch (typeof(val)) {
            case "number":
                dump = indentSpaces + varName + " " + op + " " + val;
                break;
            case "string":
                dump = indentSpaces + varName + " " + op + ' "' + val + '"';
                break;
            case "boolean":
                if (val) {
                    dump = indentSpaces + varName + " " + op + " true";
                }
                else {
                    dump = indentSpaces + varName + " " + op + " false";
                }
                break;
            case "function":
                dump = indentSpaces + "// " + varName + " " + op + " function";
                break;
            case "object":
                dump = indentSpaces + varName + " " + op + " {\n";
                first = true;
                for (attrib in val) {
                    if (! first) {
                        dump += ",\n";
                    }
                    if ((maxDepth != null && indent+1 >= maxDepth) || val.parentNode != null) {
                        attribType = typeof(val[attrib]);
                        if (attribType == "string" || attribType == "number" || attribType == "boolean") {
                            dump += indentSpaces + "   " + attrib + " : " + val[attrib];
                        }
                        else {
                            dump += indentSpaces + "   " + attrib + " : " + attribType;
                        }
                    }
                    else {
                        dump += this.dumpValue(val[attrib], attrib, ":", indent+1, maxDepth);
                    }
                    first = false;
                }
                dump += "\n" + indentSpaces + "}";
                break;
            default:
                dump = indentSpaces + "// " + varName + " " + op + " " + typeof(val) + " (unexpected)";
                break;
        }
        return(dump);
    }

    this.dump = dump;
    function dump (obj, varName, maxDepth) {
        if (obj == null) {
            obj = this;
            if (varName == null) {
                varName = "context";
            }
        }
        else {
            if (varName == null) {
                varName = "v";
            }
        }
        var dump = this.dumpValue(obj, varName, "=", 0, maxDepth);
        dump += ";";
        return(dump);
    }

    this.show = show;
    function show (obj, name) {
        var msg = name;
        if (name == null) {
            msg = "null = \n";
        }
        else {
            msg += " = \n";
        }
        if (obj != null) {
            msg += this.dump(obj);
        }
        else {
            msg += "null";
        }
        alert(msg);
    }

    this.write = write;
    function write () {
        document.write(this.dump());
    }

    this.importJavascript = importJavascript;
    function importJavascript () {
        document.writeln('<script type="text/javascript" src="' +
            appOptions.urlDocRoot + '/js-app/utils.js" language="JavaScript"></script>');
        document.writeln('<script type="text/javascript" src="' +
            appOptions.urlDocRoot + '/js-app/app-widget.js" language="JavaScript"></script>');
        document.writeln('<script type="text/javascript" src="' +
            appOptions.urlDocRoot + '/js-app/debug.js" language="JavaScript"></script>');
    }

    this.importCss = importCss;
    function importCss () {
        document.writeln('<link type="text/css" href="' +
            appOptions.urlDocRoot + '/js-app/app.css" rel="stylesheet">');
        document.writeln('<link type="text/css" href="' +
            appOptions.urlDocRoot + '/theme/' +
            appOptions.theme + '/theme.css" rel="stylesheet">');
    }

    this.importAppFiles = importAppFiles;
    function importAppFiles () {
        var files, i, file;
        if (appConf.global.js != null) {
            // import additional application-specific JavaScript
            files = appConf.global.js;
            for (i = 0; i < files.length; i++) {
                file = files[i];
                if (file.indexOf("http") == 0 || file.indexOf("/") == 0) {
                    document.writeln('<script type="text/javascript" src="' + file + '" language="JavaScript"></script>');
                }
                else {
                    document.writeln('<script type="text/javascript" src="' + appOptions.urlDocDir +
                        "/" + file + '" language="JavaScript"></script>');
                }
            }
        }
        else {
            // import the default application-specific JavaScript
            if (appOptions.appName != null) {
                html = '<script type="text/javascript" src="' + appOptions.urlDocDir + "/" +
                    appOptions.appName + '.js" language="JavaScript"></script>';
                document.writeln(html);
            }
        }

        if (appConf.global.css != null) {
            // import additional application-specific CSS
            files = appConf.global.css;
            for (i = 0; i < files.length; i++) {
                file = files[i];
                if (file.indexOf("http") == 0 || file.indexOf("/") == 0) {
                    document.writeln('<link type="text/css" href="' + file + '" rel="stylesheet">');
                }
                else {
                    document.writeln('<link type="text/css" href="' + appOptions.urlDocDir +
                        "/" + file + '" rel="stylesheet">');
                }
            }
        }
        else {
            // import the default application-specific CSS
            if (appOptions.appName != null) {
                html = '<link type="text/css" href="' + appOptions.urlDocDir + "/" +
                    appOptions.appName + '.css" rel="stylesheet">';
                document.writeln(html);
            }
        }

        // import theme-driven application-specific CSS
        if (appOptions.appName != null) {
            document.writeln('<link type="text/css" href="' +
                appOptions.urlDocRoot + '/theme/' +
                appOptions.theme + '/' + appOptions.appName + '.css" rel="stylesheet">');
        }
    }

    this.initStandardServices = initStandardServices;
    function initStandardServices () {
        this.service("ValueDomain", "date-day", {
            values : [ "01", "02", "03", "04", "05", "06", "07", "08", "09", "10",
                       "11", "12", "13", "14", "15", "16", "17", "18", "19", "20",
                       "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31" ]
        });
        this.service("ValueDomain", "date-month", {
            values : [ "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12" ],
            labels : { "01" : "Jan", "02" : "Feb", "03" : "Mar", "04" : "Apr", "05" : "May", "06" : "Jun",
                       "07" : "Jul", "08" : "Aug", "09" : "Sep", "10" : "Oct", "11" : "Nov", "12" : "Dec" }
        });
        this.service("ValueDomain", "date-dow", {
            values : [ "1", "2", "3", "4", "5", "6", "7" ],
            labels : { "1" : "Sun", "2" : "Mon", "3" : "Tue", "4" : "Wed", "5" : "Thu", "6" : "Fri", "7" : "Sat" }
        });
    }

    this.getElementById = getElementById;
    function getElementById (elemId, required) {
        var e;
        if (document.getElementById) { e = document.getElementById(elemId); }
        else if (document.all)       { e = document.all[elemId]; }
        else if (document.layers)    { e = document.layers[elemId]; }
        if (required) {
            if (e == null) {
                this.log("elem(" + elemId + "): Not Found");
            }
            else if (e.id == null) {
                this.log("elem(" + elemId + "): Doesn't have ID");
            }
        }
        return(e);
    }

    // TODO: re-evaluate this method
    // I pulled this in from some old code which works on old browsers.
    // I think it still has value, but we'll have to see.
    this.getElementByName = getElementByName;
    function getElementByName (name, type) {
        var f, form, e, elem;
        elem = document[name];  // is this supposed to work? (it doesn't seem to)
        if (!elem) {
            for (f = 0; f < document.forms.length; f++) {
                form = document.forms[f];
                for (e = 0; e < form.elements.length; e++) {
                    elem = form.elements[e];
                    if (elem.name == name && (arguments.length == 1 || elem.type == type)) {
                        return(elem);
                    }
                }
            }
        }
        return(null);
    }

    this.getDOMValue = getDOMValue;
    function getDOMValue (name) {
        var value;
        var elem = this.getElementByName(name);
        if (elem) {
            var i;
            if (elem.value != null) {
                value = elem.value;
            }
            else if (elem.type == "select-one") {
                value = elem.options[elem.selectedIndex].value;
            }
            else if (elem.type == "select-multiple") {
                for (i = 0; i < elem.options.length; i++) {
                    if (elem.options[i].selected) {
                        if (value == null) { value = elem.options[i].value;   }
                        else               { value += "," + elem.options[i].value; }
                    }
                }
            }
        }
        return(value);
    }

    this.setDOMValue = setDOMValue;
    function setDOMValue (name, value) {
        var elem = this.getElementByName(name);
        if (elem) {
            var i;
            var type = elem.type;
            if (type == null) {
                // do nothing
            }
            else if (type == "select-one") {
                // It seems that IE and DOM1 allow elem.value = value
                // for a "select-one" element, but NS4+ and even Firefox
                // don't seem to allow this.
                if (elem.options[elem.selectedIndex].value != value) {
                    elem.options[elem.selectedIndex].selected = false;
                    for (i = 0; i < elem.options.length; i++) {
                        if (elem.options[i].value == value) {
                            elem.options[i].selected = true;
                            break;
                        }
                    }
                }
            }
            else if (type == "select-multiple") {
                var values;
                if (value == null) {
                    values = [];
                }
                else {
                    values = value.split(",");
                }
                // set up a hash of the values to be set (comma-sep in "value")
                var valuesToBeSet = new Object();
                for (i = 0; i < values.length; i++) {
                    valuesToBeSet[values[i]] = 1;
                }
                for (i = 0; i < elem.options.length; i++) {
                    if (elem.options[i].selected) {
                        if (! valuesToBeSet[elem.options[i].value]) {
                            elem.options[i].selected = false;
                        }
                    }
                    else {
                        if (valuesToBeSet[elem.options[i].value]) {
                            elem.options[i].selected = true;
                        }
                    }
                }
            }
            else if (type == "hidden" ||
                     type == "text" ||
                     type == "textarea" ||
                     type == "radio" ||
                     type == "checkbox" ||
                     type == "file" ||
                     type == "image" ||
                     type == "password" ||
                     type == "reset" ||
                     type == "submit" ||
                     type == "button") {
                elem.value = value;
            }
        }
    }

    this.translate = translate;
    function translate (str, lang) {
        // TODO
        return(str);
    }

    this.log = log;
    function log (str) {
        alert(str);
    }
}

// *******************************************************************
// CLASS: Service
// *******************************************************************
function Service () {
    this.html = html;
    function html () {
        var html = '[' + this.serviceType + '(' + this.serviceName + ') : ' + this.serviceClass + ']';
        return(html);
    }
    this.write = write;
    function write () {
        document.write(this.html());
    }
    this.init = init;
    function init () {
        // do nothing (available for overriding in a subclass)
    }
}

// *******************************************************************
// CLASS: SessionObject
// *******************************************************************
function SessionObject () {

    this.init = init;
    function init () {
        var n = this.serviceName;
        var value = context.getValue(n);
        if (value == null && this["default"] != null) {
            context.setValue(this.serviceName, null, this["default"]);
        }
    }

    this.container   = container;
    function container (serviceName) {
        if (serviceName == null) {
            serviceName = this.serviceName;
        }
        var containerServiceName;
        if (serviceName != "default") {
            var pos = serviceName.lastIndexOf("-");
            if (pos <= 0) {
                containerServiceName = "default";
            }
            else {
                containerServiceName = serviceName.substring(0, pos);
            }
        }
        return(containerServiceName);
    }

    // not sure if anyone needs this. it is provided in parallel to the container() function
    this.containerAttrib   = containerAttrib;
    function containerAttrib (serviceName) {
        if (serviceName == null) {
            serviceName = this.serviceName;
        }
        var containerAttribName;
        if (serviceName != "default") {
            var pos = serviceName.lastIndexOf("-");
            if (pos <= 0) {
                containerAttribName = "serviceName";
            }
            else {
                containerAttribName = serviceName.substring(pos+1, serviceName.length);
            }
        }
        return(containerAttribName);
    }

    this.getCurrentValue = getCurrentValue;
    function getCurrentValue () {
        return(context.getValue(this.serviceName));
    }

    this.setCurrentValue = setCurrentValue;
    function setCurrentValue (value) {
        context.setValue(this.serviceName, null, value);
        // should this really go here?
        // (I think it should go in each subclass for which it is appropriate)
        // context.setDOMValue(this.serviceName, value);
    }

    this.getCurrentValues = getCurrentValues;
    function getCurrentValues () {
        var value = this.getCurrentValue();
        if (value == null || value == "") {
            return(new Array());
        }
        else {
            return(value.split(","));
        }
    }

    this.setCurrentValues = setCurrentValues;
    function setCurrentValues (values) {
        if (values && values.length > 0) {
            return(this.setCurrentValue(values.join(",")));
        }
        else {
            return(this.setCurrentValue(""));
        }
    }

    this.getValues = getValues;
    function getValues () {
        var values = this.values;
        if (values == null && this.domain) {
            var domain = context.service("ValueDomain", this.domain);
            values = domain.getValues();
        }
        if (values == null) {
            values = new Array();
        }
        return(values);
    }

    this.getLabels = getLabels;
    function getLabels () {
        var labels = this.labels;
        if (labels == null && this.domain) {
            var domain = context.service("ValueDomain", this.domain);
            labels = domain.getLabels();
        }
        if (labels == null) {
            labels = new Object();
        }
        return(labels);
    }

    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        // alert("so.handleEvent(" + thisServiceName + "," + eventServiceName + "," + eventName + ")");
        var containerServiceName = this.container(thisServiceName);
        var argString;
        if (eventArgs == null) {
            argString = "null";
        }
        else {
            var i;
            argString = "";
            for (i = 0; i < eventArgs.length; i++) {
                argString += (i == 0) ? "[" : ",";
                argString += eventArgs[i];
            }
            argString += "]";
        }
        var handled;
        if (containerServiceName) {
            var s = context.service("SessionObject", containerServiceName);
            handled = s.handleEvent(containerServiceName, eventServiceName, eventName, eventArgs);
        }
        else if (eventName == "change") {  // ignore change events that are not otherwise handled
            handled = 1;
        }
        else {
            context.log("handleEvent(" + thisServiceName + "," + eventServiceName + "," +
                eventName + "," + argString + ") : Event not handled");
            handled = 0;
        }
        return(handled);
    }

    this.getId = getId;
    function getId (withAttrib) {
        var id = this.serviceName;
        // id.replace(/\./g,"-");
        if (withAttrib != null && withAttrib) {
            id = ' id="' + id + '"';
        }
        return(id);
    }
}
SessionObject.prototype = new Service();

// *******************************************************************
// CLASS: ValueDomain
// *******************************************************************
function ValueDomain () {

    this.getLabels = getLabels;
    function getLabels () {
        var labels = this.labels;
        if (labels == null) {
            labels = new Object();
        }
        return(labels);
    }

    this.getValues = getValues;
    function getValues () {
        var values = this.values;
        if (values == null) {
            values = new Array();
        }
        return(values);
    }
}
ValueDomain.prototype = new Service();

// *******************************************************************
// CLASS: Dictionary
// *******************************************************************
function Dictionary () {

    this.loadKeysValues = loadKeysValues;
    function loadKeysValues (keys) {
        // for overriding in a subclass
        if (keys == null) {
            // load the full set of keys/values
            this.currKeys = "";  // signifies "ALL"
        }
        else {
            if (typeof(keys) == "Array") {
                this.currKeys = keys.join(",");
            }
            else {
                this.currKeys = keys;
                keys = keys.split(",");
            }
            // load only the values for the given keys
            // ...
        }
        this.labels = null;  // rebuild if needed
    }

    this.getKeys = getKeys;
    function getKeys () {
        var keys = this.keys;
        if (keys == null && !this.loaded) {
            this.loadKeysValues();
        }
        return(keys);
    }

    this.getValues = getValues;
    function getValues (keys) {
        var values = this.values;
        if (values == null && !this.loaded) {
            values = new Array();
        }
        return(values);
    }

    this.getLabels = getLabels;
    function getLabels (keys, lang) {
        var labels = this.labels;
        if (labels == null && !this.loaded) {
            labels = new Object();
        }
        return(labels);
    }
}
Dictionary.prototype = new Service();

// This has to run after the Dictionary.prototype(s) have been assigned
context.initStandardServices();

