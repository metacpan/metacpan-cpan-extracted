#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;

use Tk;
use Tk::More;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip tests only work with installed Test::More module\n";
	CORE::exit(0);
    }
}

my $mw = eval { tkinit };
if (!$mw) {
    print "1..0 # cannot create MainWindow\n";
    CORE::exit(0);
}
$mw->geometry("+1+1"); # for twm

plan tests => 4;

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $more = $mw->Scrolled("More",
			     -font => "Courier 10",
			     -scrollbars => "osoe",
			    )->pack(-fill => "both", -expand => 1);
    $more->focus;
    $more->Load($INC{"Tk/More.pm"});
    $more->update;
    ok(Tk::Exists($more));
    ok(!@warnings, "No warnings while loading")
	or diag($warnings[0] . "...");
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $more = $mw->More
	(# -font: use default
	 -width => 20,
	 -height => 3,
	)->pack;
    $more->Load($0);
    $more->update;
    ok(Tk::Exists($more));
    ok(!@warnings, "No warnings while loading")
	or diag($warnings[0] . "...");
}

if (!$ENV{PERL_INTERACTIVE_TEST}) {
    $mw->after(1*1000, sub { $mw->destroy });
}
MainLoop;

