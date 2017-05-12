/* This helps verify nav packets against the Nodecopter implementation.  
 * To run, you will need Node.js installed, and then clone the Nodecopter 
 * git repository from:
 *
 * https://github.com/felixge/node-ar-drone
 *
 * Put the packet data in the packet var as a hex string.  Then execute with:
 *
 * NODE_PATH=/path/to/nodecopter/lib/navdata node nav_data_dump.js
 *
 */
var packet = "88776655d004800f346f000001000000000094000000020059000000bf4ccccd00209ec400941a47000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030000000e4f453fe9fb22bfe7ffcdbcd111233f3455453f70f5003cc67a6b3c9feab4bc3ee97f3f0000000000000000000000001000480100000000000000000000000000000000000000000000000000000000000000000000ffff0800201b0000";

var packet_buf = new Buffer( packet, "hex" );

var parseNavData = require( "parseNavdata" );
var navdata = parseNavData( packet_buf );

console.log( navdata );
