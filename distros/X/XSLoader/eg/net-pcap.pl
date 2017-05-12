# This example was extracted from the Net::Pcap module.
# As a version is specified in the XSLoader::load() and in the bootstrap()
# calls, this example will only load the object module if its version 
# matches the given version.

package Net::Pcap;
use strict;

BEGIN {
    no strict;
    $VERSION = '0.13';

    eval {
        require XSLoader;
        XSLoader::load('Net::Pcap', $VERSION);
        1
    } or do {
        require DynaLoader;
        push @ISA, 'DynaLoader';
        bootstrap Net::Pcap $VERSION;
    };
}
