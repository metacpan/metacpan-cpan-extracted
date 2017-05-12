# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 1997,1998,2007,2008,2016 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip: no Test::More module\n";
	exit;
    }
}

use Tk;

my $top;
BEGIN {
    if (!eval { $top = new MainWindow }) {
	print "1..0 # skip cannot open DISPLAY\n";
	CORE::exit;
    }
    $top->geometry('+10+10');
}

use Tk::HistEntry;
use strict;

plan tests => 4;

$top->geometry($top->screenwidth . "x" .$top->screenheight . "+0+0");

my $he = $top->HistEntry(-match => 1,
			)->pack;
isa_ok($he, "Tk::HistEntry");

$he->addhistory('Foo');
$he->addhistory('Bar');
my $e = $he->_entry;
isa_ok($e, "Tk::LabEntry");
my $focus_e = $e->Subwidget("entry");
$e->focus;
$e->update;

eval {
    $e->event('generate', '<KeyPress>', -keysym => 'F');
    $e->event('generate', '<KeyPress>', -keysym => 'o');
    $e->update;
};
SKIP: {
    skip("Focus lost? $@", 1) if $@;
    skip("Focus lost!", 1) if ($top->focusCurrent||"") ne $focus_e;
    is($e->get, 'Foo', "Expected first entry");
}

{
    local $TODO = "Rethink BackSpace behavior...";

    eval {
	$e->event('generate', '<KeyPress>', -keysym => 'BackSpace');
	$e->update;
    };
 SKIP: {
	skip("Focus lost? $@", 1) if $@;
	skip("Focus lost!", 1) if ($top->focusCurrent||"") ne $focus_e;
	is($e->get, 'F', 'Only one character entered');
    }
}

#MainLoop;
