var yote = {}; // yote var

/*
   yote.init - sets up contact with the yote server and runs a handler provided, passing it
               the server root object and optionally an app object.

   usage :

      yote.init( {

         yoteServerUrl : 'optional. include only if yote server is different than the server that served this js doc',
 
         appName : 'optional. If given, then an app object is also passed to the handler.',

         handler : function( root, app ) { // app is only passed in if appName is an argument
            // do stuff
         },

         errHandler : function(err) { } //optional
      } );

    The app and root objects are yote objects.


    A note on yote methods :
      yote methods are called with an array of parameters, a success handler and a fail handler
      all are optional, but the first function encounted is going to be the success handler. The
      next the fail handler. Passing in a single argument is also allowed :
      So the method signatures are as follows :

    yoteobj.doSomething( [arg1,arg2,..], successHandler, failHandler );
    yoteobj.doSomething( [arg1,arg2,..], successHandler );
    yoteobj.doSomething( singlearg, successHandler, failHandler );
    yoteobj.doSomething( singlearg, successHandler );
    yoteobj.doSomething( successHandler, failHandler );
    yoteobj.doSomething( successHandler );


*/
yote._readyFuns = [];

// when the yote initialization is completed, run this function, passing it
// root, app, acct, and session ( if avail )
yote.onReady = function( fun ) {
    yote._readyFuns.push( fun );
}

yote.init = function( args ) {

    var yoteServerURL = args.yoteServerURL || '';

    var token, root, app, appname, acct, globalErrHandler;


    token = args.token;
    
    // cache storing objects and their meta-data
    var class2meths = {};

    var id2obj = {};
    

    var _register = function( id, obj ) {
        id2obj[ id ] = obj;
    }


    // creates a proxy method that contacts the server and
    // returns data
    function makeMethod( mName ) {
        var nm = '' + mName;
        return function( data, handler, failhandler ) {
            var that = this;
            var id = this.id;

            if( ! Array.isArray( data ) ) {
                var err = "Error, call without paramers (even empty ones), so not doing this";
                console.warn( err );
                if( failhandler ) {
                    failhandler( err );
                }
            }

            var res = contact( id, nm, data, handler, failhandler );
        };
    };

    var makeObjSkell = function( cls, objrecord ) {
        var obj = {
            _cls  : cls,
            _data : objrecord ? objrecord._data : {},
            listeners : {},
            
            // takes a function that takes this object as a
            // parameter
            addUpdateListener : function( listener, key ) {
                key = key || '_';
                if( key === '_' ) {
                    var defs = this.listeners[ key ];
                    if( ! defs ) {
                        defs = [];
                        this.listeners[ key ] = defs;
                    }
                    defs.push( listener );
                } else {
                    this.listeners[ key ] = listener;
                }
                return this;
            },
            removeUpdateListeners : function( key ) {
                if( key ) {
                    delete this.listeners[ key ];
                } else {
                    this.listeners = {};
                }
                return this;
            },
            get : function( key ) {
                var val = this._data[key];
                if( typeof val === 'undefined' || val === null ) {
                    return undefined;
                }
                if( typeof val === 'string' && val.startsWith( 'v' ) ) {
                    return val.substring( 1 );
                } 
                return yote.fetch( val );
            }
        };

        if( cls === 'ARRAY' ) {
            obj.toArray = function() {
                var a = [];
                for( var k in obj._data ) {
                    a[k] = obj.get( k );
                }
                return a;
            };
            obj.each = function( fun ) {
                for( var k in obj._data ) {
                    fun( obj.get( k ), k );
                }
            };
            obj.length = function() {
                return Object.keys( obj._data ).length;
            };
        }
        var mnames = class2meths[ cls ] ? class2meths[ cls ] : objrecord ? objrecord._meths : [];
        obj._meths = mnames;
        mnames.forEach( function( mname ) {
            obj[ mname ] = makeMethod( mname );
        } );
        return obj;
    }; //makeObjSkell
    
    // returns an object, either the cache or server
    var _fetch = function( id ) {
        return id2obj[id];
    }; //_fetch

    yote.fetch = _fetch;
    
    // method for translating and storing the objects
    // NOTE : returns a function used for updating
    function makeObj( datastructure ) {
        /* method that returns the value of the given field on the yote obj */
        var obj = _fetch( datastructure.id );
        var isUpdate = obj !== null && typeof obj === 'object';
        // TODO : maybe include what was updated and pass that to the action listener?
        if( ! isUpdate ) {
            obj = makeObjSkell( datastructure.cls );
            obj.id = datastructure.id;
            obj._data = datastructure.data;
        }
        obj._data = datastructure.data;
        _register( datastructure.id, obj );
        
        // fire off an event for any update listeners
        return function() {
            if( isUpdate ) {
                for( var key in obj.listeners ) {
                    if( key === '_' ) {
                        obj.listeners[key].forEach( function( l ) {
                            l( obj );
                        } );
                    } else {
                        obj.listeners[key]( obj );
                    }
                };
            }
        }
    } //makeObj
    
    function processReturn( returnData ) {
        if( Array.isArray( returnData ) ) {
            var ret = returnData.map( function( x ) {
                return processReturn( x );
            } );
            return ret;
        } 
        else if( typeof returnData === 'object' ) {
            var ret = {};
            for( var k in returnData ) {
                ret[k] = processReturn( returnData[k] );
            }
            return ret;
        } 
        else if( typeof returnData === 'string' && returnData.startsWith('v') ) {
            return returnData.substring(1);
        }
        else if( returnData ) {    
            return yote.fetch( returnData );
        }
    } //processReturn

    function processRaw(rawResponse,succHandle,failHandle) {
        var res = JSON.parse( rawResponse );

        // check for errors
        if( res.err ) {
            if( res.needs_resync && resyncHander ) {
                resyncHander();
                return;
            }
            if( failHandle ) {
                failHandle( res.err );
            }
            return;
        }
        
        // ** 3 parts : methods, updates and result
        
        // methods
        if( res.methods ) {
            for( var cls in res.methods ) {
                class2meths[cls] = res.methods[ cls ];
            }
        }
        
        // updates
        if( res.updates ) {
            var makeOrUpdateFuns = [];
            console.log( ["GOT UPDATES", res.updates ] );
            res.updates.forEach( function( upd ) {
                if( typeof upd !== 'object' || ! upd.id ) {
                    console.warn( "Update error, was expecting object, not : '" + upd + "'" );
                } else {
                    // good place for an update listener
                    makeOrUpdateFuns.push( makeObj( upd ) );
                }
            } ); //updates section
            makeOrUpdateFuns.map( function( fun ) {
                fun();
            } );
        }
        
        // results
        if( res.result && succHandle ) {
            var resses = processReturn( res.result );
            succHandle.apply( succHandle, resses );
        }
    }; //processRaw

    // yote objects can be stored here, and interpreting
    // etc can be done here, the get & stuff
    function reqListener( succHandl, failHandl ) { 
        return function() {
            console.log( "GOT FROM SERVER : " + this.response );
            if( typeof this === 'object' ) {
                processRaw( this.response, succHandl, failHandl );
            } else if( failHandl ) {
                failHandl( 'failed' );
            }
        };
    };

    function readyObjForContact( obj, files ) {
        if( typeof obj !== 'object' ) {
            return typeof obj === 'undefined' || obj === null ? undefined : 'v' + obj;
        }
        if( _fetch( obj.id ) === obj ) {
            return obj.id;
        }

        for( var idx in obj ) {
            var v = obj[idx];
            if( typeof v === 'object' ) {
                if( _fetch( v.id ) === v ) {
                    v = v.id;
                } else {
                    v = readyObjForContact( v, files );
                }
            } else if( typeof v === 'function' ) {
                var morefiles = v();
                if( morefiles.length > 0 ) {
                    var start = files.length;
                    files.push.apply( files, morefiles ); //unroll files
                    // f0_1 would be the first group of files 
                    v = 'f' + start + '_' + (start + morefiles.length);
                }
            } else if( v !== undefined ) {
                v = 'v' + v;
            } else {
                v = undefined;
            }
            obj[idx] = v;
        }
        return obj;
    }

    function contact(id,action,data,handl,errhandl) { 
        var oReq = new XMLHttpRequest();
        errhandl = errhandl || globalErrHandler;
        oReq.addEventListener("loadend", reqListener( handl, errhandl ) );
        oReq.addEventListener("error", function(e) { console.warn('error : ' + e) } );
        oReq.addEventListener("abort", function(e) { console.warn('abort : ' + e) } );

        console.log( "CONTACTING SERVER ASYNC via url : " + yoteServerURL + 
                     '/' + id +
                     '/' + ( token ? token : '_' ) + 
                     '/' + action )
        

        var readiedData = undefined;
        var files = [];
        var readiedData = typeof data === 'undefined' || data === null ? undefined : readyObjForContact( data, files );

        // for a single parameter, wrap into a parameter list

// *** TRY [var sendData = new FormData()] here and append the file uploads
/*        
        var sendData = 'p=' + JSON.stringify( { pl    : readiedData, //payload
                                                i     : id,                 
                                                t     : token ? token : '_',
                                                a     : action
                                              } );
*/
        var sendData = new FormData();
        var payload = JSON.stringify( { pl : readiedData, //payload
                                        i  : id,                 
                                        t  : token ? token : '_',
                                        a  : action
                                      } );
        sendData.set( 'p', payload );
        sendData.set( 'f', files.length ); // number of files
        for( var i=0; i<files.length; i++ ) {
            sendData.set( 'f' + i, files[i], files[i].name );
        }

        console.log( "About to send to server : " + payload );

        // data must always be an array, though that array may have different data structures inside of it
        // as vehicles for data
        oReq.open("POST", yoteServerURL, true );
//        oReq.setRequestHeader("Content-type", "application/x-www-form-urlencoded" );
        oReq.send( sendData );

    }; // contact
   // translates text to objects
    function xform_in( item ) {
        if( typeof item === 'object' ) {
            if( item === null ) {
                return undefined;
            }
            if( Array.isArray( item ) ) {
                return item.map( function( x ) { return xform_in(x); } );
            } else {
                var ret = {};
                for( var k in item ) {
                    ret[ k ] = xform_in( item[k] );
                }
                return ret;
            }
        } else {
            if( typeof item === 'undefined' || item === null ) return undefined;
            if( typeof item === 'string' && item.startsWith('v') ) {
                return item.substring( 1 );
            } else {
                return _fetch( item );
            }
        }
    }
    

    // transform from objects to text
    function xform_out( res ) {
        if( typeof res === 'object' ) {
            if( Array.isArray( res ) ) {
                return res.map( function( x ) { return xform_out( x ) } );
            }
            var obj = _fetch( res.id );
            if( obj ) { return res.id }
            var ret = {};
            for( var key in res ) {
                ret[key] = xform_out( res[key] );
            }
            return ret;
            
        }
        if( typeof res === 'undefined' ) return undefined;
        return 'v' + res;
    }//xform_out

    appname = args.appName;
    var handler = args.handler;
    var errhandler = args.errHandler;
    var resyncHander = args.resyncHander;

    globalErrHandler = args.globalErrHandler;

    if( ! handler ) {
        console.warn( "Warning : yote.init called without handler" );
    }
    contact( '_', 'init_root', [], function(newroot,newtoken) {
        token = newtoken;
        root = newroot;
        if( appname ) {
            root.fetch_app( [appname], function( newapp, newacct, session ) {
                app = newapp;
                acct = newacct;
                if( handler ) {
                    handler( root, app, acct, session );
                }
                yote.readyFuns(root, app, acct, session );
            } );
        } else {
            if( handler ) {
                handler( root );
            }
            yote.readyFuns(root );
        }
    }, errhandler );

    yote.logout = function( handler ) {
        if( app ) {
            app.logout([],function() {
                localStorage.clear();

                acct = undefined;
                token = undefined;
                app = undefined;

                contact( '_', 'init_root', [], function(newerroot,newertoken) {
                    token = newertoken;
                    root = newerroot;

                    if( appname ) {
                        root.fetch_app( [appname], function( app ) {
                            if( handler ) {
                                handler( root, app );
                            }
                        } );
                    } else if( handler ) {
                        handler( root );
                    }
                }, errhandler );

            }, function(err) { localStorage.clear(); } );
        } else {
            acct = undefined;
            token = undefined;
            
            localStorage.clear();
            contact( '_', 'init_root', [], function(newerroot,newertoken) {
                root = newerroot;
                token = newertoken;
                if( appname ) {
                    root.fetch_app( [appname], function( app ) {
                        if( handler ) {
                            handler( root, app );
                        }
                    } );
                } else if( handler ) {
                    handler( root );
                }
            }, function( err ) { if( handler ) handler(); } );
        }
    } //yote.logout
    
}; //yote.init

// invoked when yote is ready and runs all the on ready functions
// that were defined prior to yote being finished with its initialized.
yote.readyFuns = function(root,app,acct,session) {
    
    yote.onReady = function( fun ) {
        fun(root,app,acct,session);
    };

    while( yote._readyFuns.length > 0 ) {
        var fun = yote._readyFuns.shift();
        if( fun ) {
            fun(root,app,acct,session);
        }
    }

}

yote.prepUpload = function( files ) {
    return function() {
        return files;
    }
}

yote.sameyoteobjects = function( a, b ) {
    return typeof a === 'object' && typeof b === 'object' && a.id === b.id;
};
