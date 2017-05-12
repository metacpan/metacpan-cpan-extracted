#!perl -w
#
# $Id: 06-nonstr.t,v 0.1 2014/04/16 10:48:20 dankogai Exp $
#
# https://rt.cpan.org/Ticket/Display.html?id=45855

use URI::Escape::XS;
use Test::More tests => 4;

my $d = 42;
is encodeURIComponent($d) => '42', "encodeURIComponent($d)";
is decodeURIComponent($d) => '42', "decodeURIComponent($d)";
my $rd = \$d;
my $rx = qr/^SCALAR\(0x[0-9a-fA-F]+\)$/ms;
like encodeURIComponent($rd) => $rx, "encodeURIComponent($rd)";
like decodeURIComponent($rd) => $rx, "decodeURIComponent($rd)";
