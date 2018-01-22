#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: base.t,v 1.13 2009/02/01 14:24:41 eserte Exp $
# Author: Slaven Rezic
#

use strict;

use Tk;
use Tk::PathEntry;

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "1..0 # skip not Test module\n";
	exit;
    }
}

my $top = eval { new MainWindow };
if (!$top) {
    print "1..0 # skip cannot create main window: $@\n";
    exit;
}
$top->geometry('+10+10'); # for twm

plan tests => 3;

if (!defined $ENV{BATCH}) { $ENV{BATCH} = 1 }
defined $ENV{HOME}  or  $ENV{HOME} = '.';

my $file; # = "$ENV{HOME}";
my $pe = $top->PathEntry(-textvariable => \$file,
			 -selectcmd => sub { warn "selected...\n" },
			 -cancelcmd => sub { warn "cancelled...\n" },
			 -initialfile => $ENV{HOME})->pack;
$pe->focus;
ok(!!Tk::Exists($pe), 1);
$top->Label(-textvariable => \$file)->pack;

if (!defined $ENV{HOME} || !-e $ENV{HOME}) {
    skip(1, 1) for 1..2;
} else {
    my $file2 = "$ENV{HOME}";
    my $pe2 = $top->PathEntry(-textvariable => \$file2)->pack;
    ok(!!Tk::Exists($pe2), 1);
    $top->Label(-textvariable => \$file2)->pack;
    $pe2->update;
    ok($file2, "$ENV{HOME}");
}

$top->Button(-text => "Set -textvariable 1",
	     -command => sub {
		 use FindBin;
		 $file = "$FindBin::RealBin/$FindBin::RealScript";
	     })->pack;
$top->Button(-text => "OK",
	     -command => sub { $top->destroy })->pack;

if ($ENV{BATCH}) { $top->after(1000, sub { $top->destroy }) }

MainLoop;

__END__
