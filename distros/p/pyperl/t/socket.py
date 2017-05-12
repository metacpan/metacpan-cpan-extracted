# This test that the embedded perl can load XS modules that happen
# to be (usually) separate dynamic libraries.

print "1..2"

import perl

addr = perl.eval("""
require Socket;
Socket::pack_sockaddr_in(80, Socket::inet_aton('127.0.0.1'));
""");

#print repr(addr);

if not addr: print "not ",
print "ok 1";

addr = perl.call_tuple("Socket::unpack_sockaddr_in", addr)
#print addr

if addr[0] != 80 or len(addr[1]) != 4: print "not ",
print "ok 2"

