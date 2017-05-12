importScripts( '/__/js/yote.js' );
yote.init();
var root = yote.fetch_root(); // <--- got to here, but init is not fully complete


onmessage = function(e) {
    console.log( "Worker got messsage from main page", e );
    var res = root.test( e.data );
    console.log( [ 'test results', res ] );
}
