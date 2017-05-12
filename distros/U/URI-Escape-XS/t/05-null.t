#!perl -w
#
# $Id: 05-null.t,v 1.1 2009/10/07 11:40:30 dankogai Exp $
#
# https://rt.cpan.org/Ticket/Display.html?id=45855

use URI::Escape::XS;
use Test::More tests => 6;

{
    no warnings 'uninitialized';
    my $d;
    is encodeURIComponent($d) => '', 'encodeURIComponent(null)';
    is decodeURIComponent($d) => '', 'decodeURIComponent(null)';
}

$d = '';
is length(encodeURIComponent($d)) => 0, 'length encodeURIComponent(\'\')';
is defined(encodeURIComponent($d)) => 1, 'defined encodeURIComponent(\'\')';
is length(decodeURIComponent($d)) => 0, 'length decodeURIComponent(\'\')';
is defined(decodeURIComponent($d)) => 1, 'defined decodeURIComponent(\'\')';
