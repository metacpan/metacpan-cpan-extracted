importScripts( '/__/js/yote.js' );

yote.initWorker();

console.log( "login.js : LOADED WORKER LOGIN" );
var root = yote.fetch_root();
var app  = root.fetch_app( 'Yote::App' );
console.log( ["login.js : LOADED APP",app ] );
onmessage = function(e) {    
    var data = e.data;
    console.log( [ "login.js GOT MESSAGE", data ] );
    var name = data[0], pw = data[1];
    var rawResp = app.login( [ name, pw ], true );
    console.log( [ "login.js GOT MESSAGE RESPONSE", rawResp ] );
    postMessage( rawResp );
} //onMessage
