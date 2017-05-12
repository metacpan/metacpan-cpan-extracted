
function getHTTPObject() {
    var xmlhttp;
    /*@cc_on
    @if (@_jscript_version >= 5)
        try {
            xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
        } catch (e) {
            try {
                xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
            } catch (E) {
                xmlhttp = false;
            }
        }
    @else
        xmlhttp = null;
    @end @*/
    if (!xmlhttp && typeof XMLHttpRequest != 'undefined') {
        try {
            xmlhttp = new XMLHttpRequest();
        } catch (e) {
            xmlhttp = null;
        }
    }
    return(xmlhttp);
}

// These functions are from http://www.crockford.com/javascript/remedial.html
// They are intended to make more things work on IE 5.0 because IE 5.0 is
// missing some stuff.  There are other functions on Crockford's page that
// go farther, and I may want to get those too.

function isAlien(a) {
   return isObject(a) && typeof a.constructor != 'function';
}

function isArray(a) {
    return isObject(a) && a.constructor == Array;
}

function isBoolean(a) {
    return typeof a == 'boolean';
}

function isEmpty(o) {
    var i, v;
    if (isObject(o)) {
        for (i in o) {
            v = o[i];
            if (isUndefined(v) && isFunction(v)) {
                return false;
            }
        }
    }
    return true;
}

function isFunction(a) {
    return typeof a == 'function';
}

function isNull(a) {
    return typeof a == 'object' && !a;
}

function isNumber(a) {
    return typeof a == 'number' && isFinite(a);
}

function isObject(a) {
    return (a && typeof a == 'object') || isFunction(a);
}

function isString(a) {
    return typeof a == 'string';
}

function isUndefined(a) {
    return typeof a == 'undefined';
} 

// from http://www.crockford.com/JSON/js.html
// which is in turn from json.org
function stringify(arg) {
    var c, i, l, o, u, v;

    switch (typeof arg) {
    case 'object':
        if (arg) {
            if (arg.constructor == Array) {
                o = '';
                for (i = 0; i < arg.length; ++i) {
                    v = stringify(arg[i]);
                    if (o) {
                        o += ',';
                    }
                    if (v !== u) {
                        o += v;
                    } else {
                        o += 'null,';
                    }
                }
                return '[' + o + ']';
            } else if (typeof arg.toString != 'undefined') {
                o = '';
                for (i in arg) {
                    v = stringify(arg[i]);
                    if (v !== u) {
                        if (o) {
                            o += ',';
                        }
                        o += stringify(i) + ':' + v;
                    }
                }
                return '{' + o + '}';
            } else {
                return;
            }
        }
        return 'null';
    case 'unknown':
    case 'undefined':
    case 'function':
        return u;
    case 'string':
        l = arg.length;
        o = '"';
        for (i = 0; i < l; i += 1) {
            c = arg.charAt(i);
            if (c >= ' ') {
                if (c == '\\' || c == '"') {
                    o += '\\';
                }
                o += c;
            } else {
                switch (c) {
                case '\b':
                    o += '\\b';
                    break;
                case '\f':
                    o += '\\f';
                    break;
                case '\n':
                    o += '\\n';
                    break;
                case '\r':
                    o += '\\r';
                    break;
                case '\t':
                    o += '\\t';
                    break;
                default:
                    c = c.charCodeAt();
                    o += '\\u00' + Math.floor(c / 16).toString(16) +
                        (c % 16).toString(16);
                }
            }
        }
        return o + '"';
    default:
        return String(arg);
    }
}

