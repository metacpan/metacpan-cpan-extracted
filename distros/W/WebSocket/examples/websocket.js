/*
##----------------------------------------------------------------------------
## WebSocket JavaScript Client - ~/scripts/websocket.js
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/10
## Modified 2021/09/10
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
*/
"use strict";
/*jshint esversion: 6 */
$(document).ready(function() 
{
	/* Simple JavaScript Inheritance
	 * By John Resig https://johnresig.com/blog/simple-javascript-inheritance/
	 * MIT Licensed.
	 */
	// Inspired by base2 and Prototype
	// Modified by Jacques Deguest on 2021-04-06 to enable hash like init parameters and 
	// to allow class wide variables or functions using the special prefix "_"
	// This is inspired from SO <https://stackoverflow.com/questions/11172801/static-variables-with-john-resigs-simple-class-pattern>
	// Added special __class__ to set the class level and object level className property, inspired by:
	// <https://github.com/pointofpresence/js-inherit>
	// XXX Class
	(function()
	{
		var initializing = false, fnTest = /xyz/.test(function(){xyz;}) ? /\b_super\b/ : /.*/;
 
		// The base Class implementation (does nothing)
		this.Class = function(){};

        this.Class.prototype.isA = function(className)
        {
            if( !this.hasOwnProperty( 'className' ) )
            {
                return( false );
            }
            return( this.className === className );
        };
        
		// Create a new Class that inherits from this class
		Class.extend = function(prop) 
		{
			var _super = this.prototype;
	 
			// Instantiate a base class (but only create the instance,
			// don't run the init constructor)
			initializing = true;
			var prototype = new this();
			initializing = false;
			
			// Copy the properties over onto the new prototype
            for( var name in prop ) 
            {
                // Check if we're overwriting an existing function
                if( typeof prop[name] == "function" &&
                    typeof _super[name] == "function" &&
                    fnTest.test(prop[name]) )
                {
                    prototype[name] = (function(name, fn){
                        return function() 
                        {
                            var tmp = this._super;
         
                            // Add a new ._super() method that is the same method
                            // but on the super-class
                            this._super = _super[name];
         
                            // The method only need to be bound temporarily, so we
                            // remove it when we're done executing
                            var ret = fn.apply(this, arguments);        
                            this._super = tmp;
                            return ret;
                        };
                    })(name, prop[name]);
                }
                else if( name == '__class__' )
                {
                    prototype.className = prop[name];
                }
                else if( name.substr(0, 1) == '_' )
                {
                    Class[ name.substr( 1 ) ] = prop[name];
                }
                else
                {
                    prototype[name] = prop[name];
                }
            }
 
            // The dummy class constructor
            function Class() 
            {
                // All construction is actually done in the init method
                if( !initializing && this.init )
                    return( this.init.apply(this, arguments) );
            }
        
            // Copy static properties from base
            for( var name in this )
            {
                if( name.substr( 0, 1 ) == '_' )
                {
                    Class[ name.substr( 1 ) ] = this[name];
                }
            }

	 
			// Populate our constructed prototype object
			Class.prototype = prototype;
	 
			// Enforce the constructor to be what we expect
			Class.prototype.constructor = Class;
			
			// Add in the static members
			// See SO answer: <https://stackoverflow.com/a/23458861/4814971>
            for ( var name in this )
            {
                if( !Class[name] )
                {
                    Class[name] = this[name];
                }
            }
            
            if( typeof( prototype.className ) !== 'undefined' )
            {
                Class.prototype.className = prototype.className;
                Class.className = prototype.className;
            }
 
			// And make this class extendable
			Class.extend = arguments.callee;
	 
			return Class;
		};
		
        window.URI = Class.extend(
        {
            init: function(url = null)
            {
                var l = window.location;
                if( url === null )
                {
                    url = l.toString();
                }
                var u = new URL( url, l.toString() );
                return( u );
            }
        });
        
        URL.prototype.clone = function()
        {
            var newObject = new URL( this.toString() );
            return( newObject );
        };
	})();

    window.Perl = window.Perl || {};
    
	// XXX Generic class
	window.Perl.Generic = Class.extend(
	{
	    __class__: "Generic",
	    
	    init: function( opts )
	    {
	        var self = this;
		    if( typeof( opts ) === 'undefined' )
		    {
		        opts = {};
		    }
            if( opts.hasOwnProperty( 'debug' ) )
            {
                self.debug_level = parseInt( opts.debug );
                delete( opts.debug );
            }
	        else if( opts.hasOwnProperty( 'debug_level' ) )
	        {
                self.debug_level = parseInt( opts.debug_level );
                delete( opts.debug_level );
	        }
            else if( settings.hasOwnProperty( 'DEBUG' ) )
            {
                if( window.DEBUG == true )
                {
                    self.debug_level = 1;
                }
                else if( Number.isInteger( settings.DEBUG ) )
                {
                    self.debug_level = settings.DEBUG;
                }
            }
            self.debug = self.debug_level;
		    // this._super( opts );
            var tmpParams = opts || {};
            Object.keys(tmpParams).forEach(function(key)
            {
                self[key] = tmpParams[key];
            });
            
            // For local storage and setSitePrefs() and getSitePrefs()
            self.ai_data = 'ai_data';
            // this._super( opts );
	    },
	    
		debug: function()
		{
	        var self = this;
		    var args = Array.from(arguments);
		    args.unshift( "debug" );
		    this.log_console.apply( self, args );
		},
		
		eraseCookie: function(name) 
		{
			setCookie( name, '', -1 );
		},
		
		error: function()
		{
		    var self = this;
		    var args = Array.from(arguments);
		    args.unshift( "error" );
		    self.log.apply( self, args );
		},
		
        getCookie: function(cname, json_decode = false)
        {
            var self = this;
            if( typeof( json_decode ) === 'undefined' ) json_decode = false;
            var name = cname + "=";
            var ca = document.cookie.split( /\;\s*/ );
            var thisCookie = "";
            for(var i = 0; i < ca.length; i++)
            {
                var c = ca[i];
                while( c.charAt(0) == ' ' ) c = c.substring(1);
                // Make sure we found our cookie and it has some value, ie it is not just CookieName=
                if( c.indexOf(name) == 0 &&
                    name.length !== c.length ) 
                {
                    thisCookie = c.substring( name.length, c.length );
                    break;
                }
            }
            if( thisCookie.length )
            {
                try
                {
                    thisCookie = decodeURIComponent( thisCookie.replace( /\+/g,  " " ) );
                    return( json_decode ? $.parseJSON( thisCookie ) : thisCookie );
                }
                catch( e )
                {
                    self.error( "Error decoding cookie: \"cname\": " + e + "\n" + JSON.stringify( thisCookie ) );
                }
            }
            else
            {
                return( json_decode ? {} : "" );
            }
        },

		getKeyPressed: function(e) 
		{
		    var self = this;
			// Modern way
			if( e.key )
			{
				// self.log( "Return e.key: " + e.key );
				return( e.key );
			}
			// IE
			else if( window.event ) 
			{
				// self.log( "Return e.keyCode: " + e.keyCode );
				return( e.keyCode );
			}
			// Netscape/Firefox/Opera
			else if( e.which ) 
			{
				// self.log( "Return e.which: " + e.which );
				return( e.which );
			}
		},
		
        getLocalStorage: function( opts = {} )
        {
            var self = this;
            // name, session = false
            if( typeof( opts.name ) === 'undefined' )
            {
                self.log( "Local storage name provided is undefined." );
                // return( null );
                throw new Error( "Local storage name provided is undefined." );
            }
            var data = '';
            if( opts.session )
            {
                data = sessionStorage.getItem( opts.name );
            }
            else
            {
                data = localStorage.getItem( opts.name );
            }
            var json = {};
            if( !data ) return( json );
            if( data.length )
            {
                try
                {
                    json = $.parseJSON( data );
                }
                catch( error )
                {
                    self.log( error );
                }
            }
            self.log( "Found local storage data: " + data );
            return( json );
        },
        
        getLocalStorageItem: function( p = {} )
        {
            var self = this;
            if( typeof( p ) !== 'object' )
            {
                self.log( "Parameter hash provided (" + p + ") is not an object." );
                return;
            }
            if( typeof( p.name ) === 'undefined' )
            {
                self.log( "Parameter name provided (" + p.name + ") is undefined." );
                return;
            }
            if( !p.hasOwnProperty( 'dbname' ) || typeof( p.dbname ) === 'undefined' )
            {
                // Set in the page header after the css
                p.dbname = settings.DATA_NAME;
            }
            if( !p.hasOwnProperty( 'session' ) )
            {
                p.session = false;
            }
            var json = this.getLocalStorage({ name: p.dbname, session: p._session });
            self.log( "Getting value for key " + p.name + " from : " + JSON.stringify( json ) );
            if( typeof( json ) === 'object' )
            {
                self.log( "Returning value " + json[ p.name ] + " for name '" + p.name + "'" );
                // Because I do not want o have to check the return value when I expects an hash (object) in return, even if empty
                if( p.expectsHash && typeof( json[ p.name ] ) === 'undefined' )
                {
                    return( {} );
                }
                else
                {
                    return( json[ p.name ] );
                }
            }
            else
            {
                self.log( "Could parse json data stored in local storage, but did not get an object!" );
            }
        },

        // Credits: Kevin Leary <https://www.kevinleary.net/javascript-get-url-parameters/>
        // Slightly modified by Jacques Deguest for the way the return value is handled
        getUrlParams: function( prop ) 
        {
            var params = {};
            var search = decodeURIComponent( window.location.href.slice( window.location.href.indexOf( '?' ) + 1 ) );
            var definitions = search.split( '&' );

            definitions.forEach( function( val, key ) 
            {
                var parts = val.split( '=', 2 );
                params[ parts[ 0 ] ] = ( new String( parts[ 1 ] ) ).replace( /\+/g,  " " );
            } );
            // Remove the query string
            var uri = window.location.href.toString();
            if( uri.indexOf( "?" ) > 0 ) 
            {
                var clean_uri = uri.substring( 0, uri.indexOf( "?" ) );
                window.history.replaceState( {}, document.title, clean_uri );
            }
            if( prop )
            {
                return( prop in params ? params[ prop ] : null );
            }
            else
            {
                return( params );
            }
        },
    
		info: function()
		{
	        var self = this;
		    var args = Array.from(arguments);
		    args.unshift( "info" );
		    this.log_console.apply( self, args );
		},
		
		log: function()
		{
	        var self = this;
		    var args = Array.from(arguments);
		    args.unshift( "log" );
		    self.log_console.apply( self, args );
		},
		
		log_console: function()
		{
	        var self = this;
	        // console.log( "self.debug_level is " + self.debug_level + " and settings.DEBUG is " + settings.DEBUG  );
            if( !( self.debug_level > 0 ) && !settings.DEBUG ) return( false );
		    var logType = "log";
			var callerFuncName = '';
			if( arguments.callee.caller !== null )
			{
                var callerFunc = arguments.callee.caller.toString();
                callerFuncName = (callerFunc.substring( callerFunc.indexOf( 'function' ) + 8, callerFunc.indexOf( '(' ) ) || 'anoynmous');
			}
			var logData = {};
			var stackString = (new Error()).stack;
			stackString = stackString.replace( /[\n\r]+$/g, '' );
			logData.stackTrace = stackString;
			var stackLines = stackString.split( "\n" );
			var stackTrace = [];
			for( var i = 0; i < stackLines.length; i++ )
			{
				var def = {};
				var line = stackLines[i];
				// console.log( "Checking line '" + line + "'" );
				var chunk = line.split( "@" );
				var functionInfo = chunk[0];
				var locationInfo = chunk[1];
				var matches = [];
				// http://legal-server.test/js/jquery-1.11.2.min.js line 2 > eval:749:4
				if( ( matches = locationInfo.match( /^(\S+)\s+line\s\d+\s+>\s+eval\:(\d+):(\d+)$/ ) ) !== null )
				{
					def.url = matches[1];
					def.file = def.url.split( '/' ).slice(-1)[0];
					def.eval = true;
					def.line = matches[2];
					def.col = matches[3];
				}
				// http://legal-server.test/js/desktop.js:502:38
				else if( ( matches = locationInfo.match( /^(.*?):(\d+):(\d+)$/ ) ) !== null )
				{
					def.url = matches[1];
					def.file = def.url.split( '/' ).slice(-1)[0];
					def.line = matches[2];
					def.col = matches[3];
					// con.log( `Found url ${def.url} file ${def.file} line ${def.line} and col ${def.col}` );
				}
				else
				{
					console.info( "Location no match for: '" + locationInfo + "'" );
				}
				// LegalTech</ui.legalTechProgressBar
				// LegalTech/this.init/</<
				// window.Account</ui.log
				// send
				def.object = null;
				def.method = null;
				if( ( matches = functionInfo.match( /^([a-zA-Z0-9_\.]+)[\<\/]+([a-zA-Z0-9\._]+)/ ) ) !== null )
				{
					def.object = matches[1];
					def.method = matches[2];
				}
				// success/</<
				// $.fn.changeMenu
				else if( ( matches = functionInfo.match( /^(\$?[a-zA-Z0-9_\.]+)/ ) ) !== null )
				{
					def.method = matches[1];
				}
				else
				{
					// con.log( "Function no match for: '" + functionInfo + "'" );
				}
				stackTrace.push( def );
			}
			// console.info( "stackTrace result is: " + JSON.stringify( stackTrace, null, 4 ) );
			/*
			var index = caller_line.indexOf( 'at ' );
			var clean = caller_line.slice( index + 2, caller_line.length );
			*/
			// log.apply( null, arguments );
			// Credits: https://stackoverflow.com/a/19790505/4814971
			var toPrint = [];
			for( var i = 0; i < arguments.length; ++i ) 
			{
				toPrint.push( arguments[i] );
			}
			// console.log( "toPrint contains: " + JSON.stringify( toPrint, null, 4 ) );
			// If we have more than one argument and our first one is a keyword, we use it to know how to log
			if( arguments.length > 1 &&
			    typeof( toPrint[0] ) === "string" &&
			    toPrint[0].match( /^(debug|error|info|log|trace|warn)$/ ) )
			{
			    logType = toPrint.shift();
			}
			logData.message = toPrint.join( '' );
			var isSprintf = false;
			if( typeof( toPrint[0] ) !== 'undefined' )
			{
			    var testPrintf = new String( toPrint[0] );
                if( testPrintf.indexOf( '%o' ) != -1 ||
                    testPrintf.indexOf( '%O' ) != -1 ||
                    testPrintf.indexOf( '%d' ) != -1 ||
                    testPrintf.indexOf( '%i' ) != -1 ||
                    testPrintf.indexOf( '%.' ) != -1 ||
                    testPrintf.indexOf( '%f' ) != -1 ||
                    testPrintf.indexOf( '%.f' ) != -1 ||
                    testPrintf.indexOf( '%s' ) != -1 )
                {
                    isSprintf = true;
                }
			}
			
            // offset 0 is our own function ui.log, so we check for our caller at offset 1
            var j = 1;
            var ref = stackTrace[j];
            // console.log( "Checking method '" + ref.method + "'" );
            if( ( ref.method === 'debug' || ref.method === 'error' || ref.method === 'log' || ref.method === 'trace' || ref.method === 'warn' ) && ( j + 1 ) < stackTrace.length )
            {
                var def = stackTrace[j+1];
                if( def.object !== null && def.object.length > 0 )
                {
                    var thisObject = def.object;
                    if( thisObject.match( /^window\./ ) ) thisObject = def.object.split( "." )[1];
                    toPrint.unshift( sprintf( '{%s} %s -> %s%s[%d]: ', thisObject, def.method, def.file, (def.eval ? "(eval)" : ""), def.line ) );
                    logData.app = null;
                    if( thisObject.hasOwnProperty( 'resources' ) )
                    {
                        logData.app = thisObject.resources.name;
                    }
                }
                else
                {
                    toPrint.unshift( sprintf( '%s -> %s%s[%d]: ', def.method, def.file, (def.eval ? "(eval)" : ""), def.line ) );
                }
                // logData.location = sprintf( '%s -> %s%s', def.url, def.method, (def.eval ? "(eval)" : "") );
                logData.location = def.url;
                logData.line = def.line;
                logData.col = def.col;
                logData.method = def.method || '(eval)';
                // break;
            }
			toPrint.unshift( strftime( '%Y-%m-%d %H:%M:%S.%Q ', (new Date()).getTime() ) );
			var logFunction = console.log;
			if( typeof( logType ) === 'string' )
			{
			    logFunction = eval( "console." + logType );
			}
			logFunction.apply( null, toPrint );
		},
		
        removeLocalStorage: function( p = {} )
        {
            var self = this;
            if( typeof( p ) !== 'object' )
            {
                self.log( "Parameter hash provided (" + p + ") is not an object." );
                return;
            }
            if( typeof( p.name ) === 'undefined' )
            {
                self.log( "Parameter name provided (" + p.name + ") is undefined." );
                return;
            }
            if( !p.hasOwnProperty( 'dbname' ) || typeof( p.dbname ) === 'undefined' )
            {
                // Set in the page header after the css
                p.dbname = settings.DATA_NAME;
            }
            if( !p.hasOwnProperty( 'session' ) )
            {
                p.session = false;
            }
            var json = self.getLocalStorage({ name: p.dbname, session: p.session });
            self.log( "Removing local storage for '" + p.name + "'" );
            //localStorage.removeItem( p.name );
            delete( json[ p.name ] );
            self.setLocalStorage({ data: json, session: p.session });
        },
        
        resetLocalStorage: function( opts = {} )
        {
            var self = this;
            self.log( "Resetting local storage" );
            if( typeof( opts.session ) === 'undefined' ) opts.session = false;
            if( typeof( opts.name ) === 'undefined' ) opts.name = settings.DATA_NAME;
            var json = self.getLocalStorage({ name: opts.name, session: opts.session });
            self.setLocalStorage({ data: {}, session: opts.session });
            self.log( "Reset local storage is now: " + JSON.stringify( json ) );
            return( json );
        },

        setCookie: function(cname, cvalue, exdays)
        {
            // Set expiry to 1 month by default
            if( exdays === undefined ) exdays = 30;
            var d = new Date();
            d.setTime( d.getTime() + (exdays * 24 * 60 * 60 * 1000) );
            var expires = d.toUTCString();
            var d2 = new Date();
            d2.setTime( d2.getTime() + (-7 * 24 * 60 * 60 * 1000) );
            var expiresNow = d2.toUTCString();
            cvalue = encodeURIComponent( JSON.stringify( cvalue ) );
            // Remove garbage old cookies
            document.cookie = cname + '=; expires=' +  expiresNow + ';domain=' + window.location.hostname + ';secure';
            document.cookie = cname + '=; expires=' +  expiresNow + ';domain=' + window.location.hostname + '; path=' + location.pathname + ';secure';
            document.cookie = cname + '=' + cvalue + '; expires=' + expires + ';domain=' + window.location.hostname + '; path=/' + ';secure';
            document.cookie = cname + '=' + cvalue + '; expires=' + expires + ';domain=' + '.' + window.location.hostname + '; path=/' + ';secure';
        },
        
        setLocalStorage: function( opts = {} )
        {
            var self = this;
            // data, session = false
            if( typeof( opts.name ) === 'undefined' ) opts.name = settings.DATA_NAME;
            if( !opts.hasOwnProperty( 'session' ) ||
                typeof( opts.session ) === 'undefined' )
            {
                opts.session = false;
            }
            
            if( !opts.hasOwnProperty( 'data' ) )
            {
                throw new Error( "No data parameter provided to set local storage." );
            }
            if( typeof( opts.data ) !== 'object' )
            {
                throw new Error( "Data to be stored in local storage must be an hash (object)" );
            }
            var json = JSON.stringify( opts.data );
            self.log( "Storing to local storage '" + opts.name + "' the data: " + json );
            try
            {
                if( opts.session )
                {
                    sessionStorage.setItem( opts.name, json );
                }
                else
                {
                    localStorage.setItem( opts.name, json );
                }
            }
            catch( error )
            {
                self.error( "An error occurred while trying to stor data to local storage: " + error.message );
            }
        },
    
        setLocalStorageItem: function( p = {} )
        {
            var self = this;
            if( typeof( p ) !== 'object' )
            {
                throw new Error( "Parameter hash provided (" + p + ") is not an object." );
            }
            if( typeof( p.name ) === 'undefined' )
            {
                self.log( "Parameter name provided (" + p.name + ") is undefined." );
                throw new Error( "Parameter name provided (" + p.name + ") is undefined." );
            }
            else if( p.name === null )
            {
                throw new Error( "Parameter name provided (" + p.name + ") is null." );
            }
            if( !p.hasOwnProperty( 'dbname' ) || typeof( p.dbname ) === 'undefined' )
            {
                // constant set at the beginning of this script
                p.dbname = settings.DATA_NAME;
            }
            if( !p.hasOwnProperty( 'session' ) )
            {
                p.session = false;
            }
            self.log( "Set name '" + p.name + "' with value '" + p.value + "'" );
            var json = this.getLocalStorage({ name: p.dbname, session: p.session });
            if( typeof( json ) === 'undefined' || json === null ) json = {};
            json[ p.name ] = p.value;
            self.setLocalStorage({ data: json, session: p.session });
            return( json );
        },
        
		trace: function()
		{
	        var self = this;
		    var args = Array.from(arguments);
		    args.unshift( "trace" );
		    this.log_console.apply( self, args );
		},
		
		// To parse query string.
		// https://stackoverflow.com/questions/7731778/get-query-string-parameters-with-jquery
		urlParam: function( name ) 
		{
			var results = new RegExp( '[\?&]' + name + '=([^&#]*)' ).exec( window.location.href );
			if( results == null )
			{
				return( "" );
			}
			return( results[1] || 0 );
		},
		
		warn: function()
		{
	        var self = this;
		    var args = Array.from(arguments);
		    args.unshift( "warn" );
		    this.log_console.apply( self, args );
		},
	});

    // XXX WebSocket class
    window.Perl.WebSocket = window.Perl.Generic.extend(
    {
        __class__: "WebSocket",
        init: function(uri, opts )
        {
            opts = opts || {};
            this._super( opts );
            if( typeof( uri ) === 'undefined' )
            {
                throw new Error( "No WebSocket uri was provided." );
            }
            else if( typeof( uri ) === null )
            {
                throw new Error( "WebSocket URI provided is null" );
            }
            else
            {
                // <https://developer.mozilla.org/en-US/docs/Web/API/URL>
                this.uri = new URL(uri);
            }
            this.max       = opts.maxAttempts || Infinity;
            this.num       = 0;
            this.timer     = 1;
            // For reconnect
            this.timeout   = opts.timeout;
            this.opts      = opts.opts;
            this.onclose   = opts.onclose;
            this.onerror   = opts.onerror;
            this.onmessage = opts.onmessage;
            this.onopen    = opts.onopen;
            this.onmaximum = opts.onmaximum;
            this.onreconnect = opts.onreconnect;
            this.protocols = opts.protocols || [];
            
            this.ws;
            var self = this;
            
            // Make alias for convenience
            /*
            self.makePropertyReadWrite( 'onopen' );
            self.makePropertyReadWrite( 'onclose' );
            self.makePropertyReadWrite( 'onerror' );
            self.makePropertyReadWrite( 'onmessage' );
            */
            
            self.makePropertyReadWrite( 'binaryType' );
            self.makePropertyReadOnly( 'bufferedAmount ' );
            self.makePropertyReadOnly( 'extensions' );
            self.makePropertyReadOnly( 'protocol' );
            self.makePropertyReadOnly( 'readyState' );
            self.makePropertyReadOnly( 'url' );
            
            self.makePropertyReadOnly( 'CONNECTING' ); // 0
            self.makePropertyReadOnly( 'OPEN' ); // 1
            self.makePropertyReadOnly( 'CLOSING' ); // 2
            self.makePropertyReadOnly( 'CLOSED' ); // 3
            
            self.open();
            // Ref: <https://stackoverflow.com/questions/9385778/window-unload-is-not-firing>
            $(window).on('beforeunload', function()
            {
                self.ws.close();
                self.ws = 'undefined';
            });
            return( this );
        },
        
        addEventListener: function(type, func)
        {
            var self = this;
            return( self.ws.addEventListener(type, func) );
        },
        
        close: function(code, reason)
        {
            var self = this;
            self.timer = clearTimeout(self.timer);
            self.ws.close(code || 1e3, reason);
        },
        
        getCsrf: function()
        {
            var self = this;
            self.log( "Getting the csrf_token from local storage." );
            var csrfToken = self.getLocalStorageItem({ name: 'csrf_token', _session: false });
            self.log( "csrf_token found is '" + csrfToken + "'" );
            if( typeof( csrfToken ) !== 'undefined' && csrfToken !== null && csrfToken.length > 0 )
            {
                return( csrfToken );
            }
            return;
        },
        
        isClosed: function()
        {
            return( this.ws && this.ws.readyState === 3 );
        },
        
        isClosing: function()
        {
            return( this.ws && this.ws.readyState === 2 );
        },
        
        isConnecting: function()
        {
            return( this.ws && this.ws.readyState === 0 );
        },
        
        isConnected: function()
        {
            return( this.ws && this.ws.readyState === 1 );
        },
        
        json: function(data)
        {
            var self = this;
            var csrfToken = self.getCsrf();
            if( typeof( csrfToken ) !== 'undefined' )
            {
                data.csrf_token = csrfToken;
            }
            self.ws.send(JSON.stringify(data));
        },
        
        // <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty>
        makePropertyReadOnly: function(prop)
        {
            var self = this;
            Object.defineProperty(self, prop,
            {
                enumerable: true,
                configurable: true,
                // writable: false,
                get()
                {
                    return( self.ws[prop] );
                }
            });
        },
        
        makePropertyReadWrite: function(prop)
        {
            var self = this;
            Object.defineProperty(self, prop,
            {
                enumerable: true,
                configurable: true,
                // writable: false,
                get()
                {
                    return( self.ws[prop] );
                },
                set(value)
                {
                    self.ws[prop] = value;
                }
            });
        },
        
        noop: function() {},

        open: function()
        {
            var self = this;
            var connectUrl = self.uri.clone();
            var csrfToken = self.getCsrf();
            // Add the CSRF token as query string to the connect uri
            // The connection token is passed as a cookie automatically, and thus we get our double token authentication
            if( typeof( csrfToken ) !== 'undefined' )
            {
                self.log( "Adding csrf token to uri query string." );
                connectUrl.search = '?csrf=' + csrfToken;
            }
            else
            {
                self.log( "No csrf token found!" );
            }
            
            // WebSocket object already set
            if( self.ws )
            {
                // state is CLOSING or CLOSED
                if( self.ws.readyState === 2 || self.ws.readyState === 3 )
                {
                    self.ws.close();
                }
                // already connecting or connected
                else if( self.ws.readyState === 0 || self.ws.readyState === 1 )
                {
                    return( self );
                }
            }
            
            self.log( "Trying to connect to " + connectUrl );
            self.ws = new WebSocket(connectUrl, self.protocols || []);
            if( !self.ws )
            {
                throw new Error( "Unable to connect to " + self.uri );
            }

            // self.ws.onmessage = self.onmessage || self.noop;
            self.ws.onmessage = function(e)
            {
                try
                {
                    var json = JSON.parse(e.originalEvent.data);
                    // self.onmessage.call(this, json);
                    (self.onmessage || self.noop)(json, e);
                }
                catch( exception )
                {
                    (self.onerror || self.noop)(exception);
                }
            };

            self.ws.onopen = function(e)
            {
                (self.onopen || self.noop)(e);
                self.num = 0;
            };

            self.ws.onclose = function(e)
            {
                e.code === 1e3 || e.code === 1001 || e.code === 1005 || self.reconnect(e);
                (self.onclose || self.noop)(e);
            };

            self.ws.onerror = function(e)
            {
                (e && e.code === 'ECONNREFUSED') ? self.reconnect(e) : (self.onerror || self.noop)(e);
            };
        },

        reconnect: function(e)
        {
            var self = this;
            if( self.timer && self.num++ < self.max )
            {
                self.timer = setTimeout(function()
                {
                    (self.onreconnect || self.noop)(e);
                    self.open();
                }, self.timeout || 1e3);
            }
            else
            {
                (self.onmaximum || self.noop)(e);
            }
        },

        send: function(x)
        {
            var self = this;
            self.ws.send(x);
        },
        
        socket: function()
        {
            var self = this;
            return( self.ws );
        }
    });
});
