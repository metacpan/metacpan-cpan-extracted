
//console = {
//    log   : function () {},
//    info  : function () {},
//    error : function () {}
//};

function Throw(a, b) {
	var message       = b? (a.message || a.description) + "\n" + b: a;
	var exception     = b? a: new Error;
	exception.message = message;
	throw exception;
}

var JSAN = function () { JSAN.addRepository(arguments) }

JSAN.VERSION = 0.10;

/*

*/

JSAN.globalScope   = self;
JSAN.includePath   = ['.', 'lib'];
JSAN.errorLevel    = "die";
JSAN.errorMessage  = "";
JSAN.loaded        = {};

/*

*/

JSAN.use = function () {
    var classdef = JSAN.require(arguments[0]);
    if (!classdef) return null;

    var importList = JSAN._parseUseArgs.apply(JSAN, arguments).importList;
    JSAN.exporter(classdef, importList);

    return classdef;
}

JSAN.useInc = function () {
    this.includePath = [arguments[0]];
    for (var i = 1, len = arguments.length; i < len; i++)
        { JSAN.use(arguments[i]) }
}

JSAN.package = function (name) {
    if( JSAN._package_exists(name) ) return;
    var parts = name.split(".");
    var path = "";
    for (i in parts) {
        var part = parts[i];
        path = path + (path == ""? "": ".") + part;
        JSAN._package_set(path);
    }
}

JSAN._package_set = function (name) {
    if( JSAN._package_exists(name) ) return;
    eval(name + " = {}");
}

JSAN._package_exists = function (name)
    { try { var v = eval(name); return v } catch (e) { return 0 } }

/*

*/

JSAN.require = function (pkg) {
    var path = JSAN._convertPackageToPath(pkg);
    if (JSAN.loaded[path]) {
        return JSAN.loaded[path];
    }

    try {
        var classdef = eval(pkg);
        if (typeof classdef != 'undefined') return classdef;
    } catch (e) { /* nice try, eh? */ }

    for (var i = 0; i < JSAN.includePath.length; i++) {
        var js;
        try{
            var url = JSAN._convertPathToUrl(path, JSAN.includePath[i]);
                js  = JSAN._loadJSFromUrl(url);
        } catch (e) {
            if (i == JSAN.includePath.length - 1) throw e;
        }
        if (js != null) {
            var classdef = JSAN._createScript(js, pkg);
            JSAN.loaded[path] = classdef;
            return classdef;
        }
    }
    return false;

}

/*

*/

JSAN.exporter = function () {
    JSAN._exportItems.apply(JSAN, arguments);
}

/*

*/

JSAN.addRepository = function () {
    var temp = JSAN._flatten( arguments );
    // Need to go in reverse to do something as simple as unshift( @foo, @_ );
    for ( var i = temp.length - 1; i >= 0; i-- )
        JSAN.includePath.unshift(temp[i]);
    return JSAN;
}

JSAN._flatten = function( list1 ) {
    var list2 = new Array();
    for ( var i = 0; i < list1.length; i++ ) {
        if ( typeof list1[i] == 'object' ) {
            list2 = JSAN._flatten( list1[i], list2 );
        }
        else {
            list2.push( list1[i] );
        }
    }
    return list2;
};

JSAN._findMyPath = function () {
    if (document) {
        var scripts = document.getElementsByTagName('script');
        for ( var i = 0; i < scripts.length; i++ ) {
            var src = scripts[i].getAttribute('src');
            if (src) {
                var inc = src.match(/^(.*?)\/?JSAN.js/);
                if (inc && inc[1]) {
                    var repo = inc[1];
                    for (var j = 0; j < JSAN.includePath.length; j++) {
                        if (JSAN.includePath[j] == repo) {
                            return;
                        }
                    }
                    JSAN.addRepository(repo);
                }
            }
        }
    }
}
JSAN._findMyPath();

JSAN._convertPathToUrl = function (path, repository) {
    return repository.concat('/' + path);
};
    

JSAN._convertPackageToPath = function (pkg) {
    var path = pkg.replace(/\./g, '/');
        path = path.concat('.js');
    return path;
}

JSAN._parseUseArgs = function () {
    var pkg        = arguments[0];
    var importList = [];

    for (var i = 1; i < arguments.length; i++)
        importList.push(arguments[i]);

    return {
        pkg:        pkg,
        importList: importList
    }
}

JSAN._loadJSFromUrl = function (url) {
    return new JSAN.Request().getText(url);
}

JSAN._findExportInList = function (list, request) {
    if (list == null) return false;
    for (var i = 0; i < list.length; i++)
        if (list[i] == request)
            return true;
    return false;
}

JSAN._findExportInTag = function (tags, request) {
    if (tags == null) return [];
    for (var i in tags)
        if (i == request)
            return tags[i];
    return [];
}

JSAN._exportItems = function (classdef, importList) {
    var exportList  = new Array();
    var EXPORT      = classdef.EXPORT;
    var EXPORT_OK   = classdef.EXPORT_OK;
    var EXPORT_TAGS = classdef.EXPORT_TAGS;
    
    if (importList.length > 0) {
       importList = JSAN._flatten( importList );

       for (var i = 0; i < importList.length; i++) {
            var request = importList[i];
            if (   JSAN._findExportInList(EXPORT,    request)
                || JSAN._findExportInList(EXPORT_OK, request)) {
                exportList.push(request);
                continue;
            }
            var list = JSAN._findExportInTag(EXPORT_TAGS, request);
            for (var i = 0; i < list.length; i++) {
                exportList.push(list[i]);
            }
        }
    } else {
        exportList = EXPORT;
    }
    JSAN._exportList(classdef, exportList);
}

JSAN._exportList = function (classdef, exportList) {
    if (typeof(exportList) != 'object') return null;
    for (var i = 0; i < exportList.length; i++) {
        var name = exportList[i];

        if (JSAN.globalScope[name] == null)
            JSAN.globalScope[name] = classdef[name];
    }
}

JSAN._makeNamespace = function(js, pkg) {
    var spaces = pkg.split('.');
    var parent = JSAN.globalScope;
//    js = "JSAN.use('mootools');" + js;
    eval(js);
    var classdef = eval(pkg);
    for (var i = 0; i < spaces.length; i++) {
        var name = spaces[i];
        if (i == spaces.length - 1) {
            if (typeof parent[name] == 'undefined') {
                parent[name] = classdef;
                if ( typeof classdef['prototype'] != 'undefined' ) {
                    parent[name].prototype = classdef.prototype;
                }
            }
        } else {
            if (parent[name] == undefined) {
                parent[name] = {};
            }
        }

        parent = parent[name];
    }
    return classdef;
}

JSAN._handleError = function (msg, level) {
    if (!level) level = JSAN.errorLevel;
    JSAN.errorMessage = msg;

    switch (level) {
        case "none":
            break;
        case "warn":
            alert(msg);
            break;
        case "die":
        default:
            throw new Error(msg);
            break;
    }
}

JSAN._createScript = function (js, pkg) {
    try {
        return JSAN._makeNamespace(js, pkg);
    } catch (e) {
        JSAN._handleError("Could not create namespace [" + pkg + "]: " + e);
    }
    return null;
}


JSAN.prototype = {
    use: function () { JSAN.use.apply(JSAN, arguments) }
};


// Low-Level HTTP Request
JSAN.Request = function (jsan) {
    if (JSAN.globalScope.XMLHttpRequest) {
        this._req = new XMLHttpRequest();
    } else {
        this._req = new ActiveXObject("Microsoft.XMLHTTP");
    }
}

JSAN.Request.prototype = {
    _req:  null,
    
    getText: function (url) {
        this._req.open("GET", url, false);
        try {
            this._req.send(null);
            if (this._req.status == 200 || this._req.status == 0)
                return this._req.responseText;
        } catch (e) {
            JSAN._handleError("File not found: " + url);
            return null;
        };

        JSAN._handleError("File not found: " + url);
        return null;
    }
};

/*

*/

// MooTools -------------------------------------------------------------------

// for benefit for JSAN. Also removed "var" from top level vars
mootools = function () {};

/*
Script: Moo.js
	My Object Oriented javascript.

Author:
	Valerio Proietti, <http://mad4milk.net>

License:
	MIT-style license.

Mootools Credits:
	- Class is slightly based on Base.js <http://dean.edwards.name/weblog/2006/03/base/> (c) 2006 Dean Edwards, License <http://creativecommons.org/licenses/LGPL/2.1/>
	- Some functions are based on those found in prototype.js <http://prototype.conio.net/> (c) 2005 Sam Stephenson sam [at] conio [dot] net, MIT-style license
	- Documentation by Aaron Newton (aaron.newton [at] cnet [dot] com) and Valerio Proietti.
*/

/*
Class: Class
	The base class object of the <http://mootools.net> framework.

Arguments:
	properties - the collection of properties that apply to the class. Creates a new class, its initialize method will fire upon class instantiation.

Example:
	(start code)
	var Cat = new Class({
		initialize: function(name){
			this.name = name;
		}
	});
	var myCat = new Cat('Micia');
	alert myCat.name; //alerts 'Micia'
	(end)
*/

Class = function(){
    var properties, name;
    var has_name = arguments.length == 2;
    if (has_name) {
        name       = arguments[0];
        properties = arguments[1];
    } else {
        name       = "Unknown";
        properties = arguments[0];
    }
    properties.$className = name;

    var klass = function(){
        if (this.initialize && arguments[0] != 'noinit')
            return this.initialize.apply(this, arguments);
        else return this;
    };
    for (var property in this) klass[property] = this[property];
    klass.prototype = properties;
    if (has_name) eval(name + " = klass");
    return klass;
};

/*
Property: empty
	Returns an empty function
*/

Class.empty = function(){};

Class.prototype = {

	/*
	Property: extend
		Returns the copy of the Class extended with the passed in properties.

	Arguments:
		properties - the properties to add to the base class in this new Class.

	Example:
		(start code)
		var Animal = new Class({
			initialize: function(age){
				this.age = age;
			}
		});
		var Cat = Animal.extend({
			initialize: function(name, age){
				this.parent(age); //will call the previous initialize;
				this.name = name;
			}
		});
		var myCat = new Cat('Micia', 20);
		alert myCat.name; //alerts 'Micia'
		alert myCat.age; //alerts 20
		(end)
	*/

	extend: function(){
        var properties, name;
        var has_name = arguments.length == 2;
        if (has_name) {
            name       = arguments[0];
            properties = arguments[1];
        } else {
            name       = "Unknown";
            properties = arguments[0];
        }

		var pr0t0typ3 = new this('noinit');

		var parentize = function(previous, current){
			if (!previous.apply || !current.apply) return false;
			return function(){
				this.parent = previous;
				return current.apply(this, arguments);
			};
		};

		for (var property in properties){
			var previous = pr0t0typ3[property];
			var current = properties[property];
			if (previous && previous != current) current = parentize(previous, current) || current;
			pr0t0typ3[property] = current;
		}
		return new Class(name, pr0t0typ3);
	},

	/*
	Property: implement
		Implements the passed in properties to the base Class prototypes, altering the base class, unlike <Class.extend>.

	Arguments:
		properties - the properties to add to the base class.

	Example:
		(start code)
		var Animal = new Class({
			initialize: function(age){
				this.age = age;
			}
		});
		Animal.implement({
			setName: function(name){
				this.name = name
			}
		});
		var myAnimal = new Animal(20);
		myAnimal.setName('Micia');
		alert(myAnimal.name); //alerts 'Micia'
		(end)
	*/

	implement: function(properties){
		for (var property in properties) this.prototype[property] = properties[property];
	}

};

/* Section: Object related Functions */

/*
Function: Object.extend
	Copies all the properties from the second passed object to the first passed Object.
	If you do myWhatever.extend = Object.extend the first parameter will become myWhatever, and your extend function will only need one parameter.

Example:
	(start code)
	var firstOb = {
		'name': 'John',
		'lastName': 'Doe'
	};
	var secondOb = {
		'age': '20',
		'sex': 'male',
		'lastName': 'Dorian'
	};
	Object.extend(firstOb, secondOb);
	//firstOb will become: 
	{
		'name': 'John',
		'lastName': 'Dorian',
		'age': '20',
		'sex': 'male'
	};
	(end)

Returns:
	The first object, extended.
*/

Object.extend = function(){
	var args = arguments;
	args = (args[1]) ? [args[0], args[1]] : [this, args[0]];
	for (var property in args[1]) args[0][property] = args[1][property];
	return args[0];
};

/*
Function: Object.Native
	Will add a .extend method to the objects passed as a parameter, equivalent to <Class.implement>

Arguments:
	a number of classes/native javascript objects

*/

Object.Native = function(){
	for (var i = 0; i < arguments.length; i++) arguments[i].extend = Class.prototype.implement;
};

new Object.Native(Function, Array, String, Number, Class);

/*
Script: Utility.js
	Contains Utility functions

Author:
	Valerio Proietti, <http://mad4milk.net>

License:
	MIT-style license.
*/

//htmlelement

if (typeof HTMLElement == 'undefined'){
	var HTMLElement = Class.empty;
	HTMLElement.prototype = {};
} else {
	HTMLElement.prototype.htmlElement = true;
}

//window, document

window.extend = document.extend = Object.extend;
Window = window;

/*
Function: $type
	Returns the type of object that matches the element passed in.

Arguments:
	obj - the object to inspect.

Example:
	>var myString = 'hello';
	>$type(myString); //returns "string"

Returns:
	'element' - if obj is a DOM element node
	'textnode' - if obj is a DOM text node
	'whitespace' - if obj is a DOM whitespace node
	'array' - if obj is an array
	'object' - if obj is an object
	'string' - if obj is a string
	'number' - if obj is a number
	'boolean' - if obj is a boolean
	'function' - if obj is a function
	false - (boolean) if the object is not defined or none of the above.
*/

function $type(obj){
	if (obj === null || obj === undefined) return false;
	var type = typeof obj;
	if (type == 'object'){
		if (obj.htmlElement) return 'element';
		if (obj.push) return 'array';
		if (obj.nodeName){
			switch (obj.nodeType){
				case 1: return 'element';
				case 3: return obj.nodeValue.test(/\S/) ? 'textnode' : 'whitespace';
			}
		}
	}
	return type;
};

/*
Function: $chk
	Returns true if the passed in value/object exists or is 0, otherwise returns false.
	Useful to accept zeroes.
*/

function $chk(obj){
	return !!(obj || obj === 0);
};

/*
Function: $pick
	Returns the first object if defined, otherwise returns the second.
*/

function $pick(obj, picked){
	return ($type(obj)) ? obj : picked;
};

/*
Function: $random
	Returns a random integer number between the two passed in values.

Arguments:
	min - integer, the minimum value (inclusive).
	max - integer, the maximum value (inclusive).

Returns:
	a random integer between min and max.
*/

function $random(min, max){
	return Math.floor(Math.random() * (max - min + 1) + min);
};

/*
Function: $clear
	clears a timeout or an Interval.

Returns:
	null

Arguments:
	timer - the setInterval or setTimeout to clear.

Example:
	>var myTimer = myFunction.delay(5000); //wait 5 seconds and execute my function.
	>myTimer = $clear(myTimer); //nevermind

See also:
	<Function.delay>, <Function.periodical>
*/

function $clear(timer){
	clearTimeout(timer);
	clearInterval(timer);
	return null;
};

/*
Class: window
	Some properties are attached to the window object by the browser detection.

Properties:
	window.ie - will be set to true if the current browser is internet explorer (any).
	window.ie6 - will be set to true if the current browser is internet explorer 6.
	window.ie7 - will be set to true if the current browser is internet explorer 7.
	window.khtml - will be set to true if the current browser is Safari/Konqueror.
	window.gecko - will be set to true if the current browser is Mozilla/Gecko.
*/

if (window.ActiveXObject) window.ie = window[window.XMLHttpRequest ? 'ie7' : 'ie6'] = true;
else if (document.childNodes && !document.all && !navigator.taintEnabled) window.khtml = true;
else if (document.getBoxObjectFor != null) window.gecko = true;

//enables background image cache for internet explorer 6

if (window.ie6) try {document.execCommand("BackgroundImageCache", false, true);} catch (e){};

/*
Script: Json.js
	Simple Json parser and Stringyfier, See: <http://www.json.org/>

Authors:
	- Christophe Beyls, <http://www.digitalia.be>
	- Valerio Proietti, <http://mad4milk.net>

License:
	MIT-style license.
*/

/*
Class: Json
	Simple Json parser and Stringyfier, See: <http://www.json.org/>
*/

Json = {

	/*
	Property: toString
		Converts an object to a string, to be passed in server-side scripts as a parameter. Although its not normal usage for this class, this method can also be used to convert functions and arrays to strings.

	Arguments:
		obj - the object to convert to string

	Returns:
		A json string

	Example:
		(start code)
		Json.toString({apple: 'red', lemon: 'yellow'}); "{"apple":"red","lemon":"yellow"}" //don't get hung up on the quotes; it's just a string.
		(end)
	*/

	toString: function(obj){
		switch ($type(obj)){
			case 'string':
				return '"'+obj.replace(new RegExp('(["\\\\])', 'g'), '\\$1')+'"';
			case 'array':
				return '['+ obj.map(function(ar){
					return Json.toString(ar);
				}).join(',') +']';
			case 'object':
				var string = [];
				for (var property in obj) string.push('"'+property+'":'+Json.toString(obj[property]));
				return '{'+string.join(',')+'}';
		}
		return String(obj);
	},

	/*
	Property: evaluate
		converts a json string to an javascript Object.

	Arguments:
		str - the string to evaluate.

	Example:
		>var myObject = Json.evaluate('{"apple":"red","lemon":"yellow"}');
		>//myObject will become {apple: 'red', lemon: 'yellow'}
	*/

	evaluate: function(str){
		return eval('(' + str + ')');
	}

};

