#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: noprereq.t,v 1.4 2008/09/23 19:34:28 eserte Exp $
# Author: Slaven Rezic
#

use strict;

use Tk;
use Tk::Date;

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "1..0 # skip tests only work with installed Test module\n";
	CORE::exit;
    }
}

my $top;
BEGIN {
    if (!eval { $top = tkinit }) {
	print "1..0 # skip cannot open DISPLAY\n";
	CORE::exit;
    }
}

BEGIN { plan tests => 12 }

# simulate not having some prereq widgets
$Tk::Date::has_numentryplain = 0;
$Tk::Date::has_numentry      = 0;

$^W = 0;

my $d1 = $top->Date->pack;
ok(ref $d1, "Tk::Date");
my $d2 = $top->Date(-allarrows => 1)->pack;
ok(ref $d2, "Tk::Date");
ok($d2->cget(-allarrows), undef);
my $d3 = $top->Date(-monthmenu => 1)->pack;
ok(ref $d3, "Tk::Date");
ok(!!$d3->cget(-monthmenu), !!$Tk::VERSION >= 800.023);
my $d4 = $top->Date(-readonly => 1)->pack;
ok(ref $d4, "Tk::Date");

{
    # test -state
    my $d = $top->Date(-state => "disabled");
    ok($d->isa('Tk::Date'), 1);
    ok($d->cget(-state), 'disabled');
    $d->configure(-state => "normal");
    ok($d->cget(-state), 'normal');
}

{
    # test -state together with -editable
    my $d = $top->Date(-editable => 0);
    ok($d->isa('Tk::Date'), 1);
    $d->configure(-state => 'disabled');
    ok($d->cget(-state), 'disabled');
    $d->configure(-state => "normal");
    ok($d->cget(-state), 'normal');
}

#MainLoop;

__END__
