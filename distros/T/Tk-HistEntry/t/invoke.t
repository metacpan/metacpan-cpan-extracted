# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 1997,1998,2008,2016 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use Tk;
my $top;
BEGIN {
    if (!eval { $top = new MainWindow }) {
	print "1..0 # skip cannot open DISPLAY\n";
	CORE::exit;
    }
    $top->geometry('+10+10'); # for twm
}

BEGIN { $^W = 1; $| = 1; $loaded = 0; $last = 3; print "1..$last\n"; }
END {print "not ok 1\n" unless $loaded;}

use Tk::HistEntry;
use strict;
use vars qw($loaded $last);

package main;

$loaded = 1;

my $ok = 1;
print "ok " . $ok++ . "\n";

use Tk;

my $he = $top->HistEntry(-command => sub { },
			 -limit => 1)->pack;
$he->invoke("aaa");
my(@h) = $he->history;
if (join(",", @h) ne "aaa") {
    print "not ";
}
print "ok " . $ok++ . "\n";

$he->invoke("bbb");
@h = $he->history;
if (join(",", @h) ne "bbb") {
    print "not ";
}
print "ok " . $ok++ . "\n";
