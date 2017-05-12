#!/usr/local/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2001,2004,2007,2012 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: srezic@cpan.org
# WWW:  http://www.rezic.de/eserte/
#

use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	use Tk;
	1;
    }) {
	print "1..0 # skip: no Test::More and/or Tk modules\n";
	exit;
    }
}

if (!defined $ENV{BATCH}) { $ENV{BATCH} = 1 }

my $mw = eval { tkinit };
if (!$mw) {
    print "1..0 # skip: cannot create MainWindow\n";
    CORE::exit(0);
}

plan tests => 9;

use_ok("Tk::FlatRadiobutton");

my $top = tkinit;
$top->geometry("+10+10");
$top->Label(-text => "Tk::FlatRadiobutton")->pack;
#$top->optionAdd("*FlatRadiobutton*background" => "green", "userDefault");
my $p = $top->Photo(-file => Tk->findINC("icon.gif"));
my $on = 0;
my $cb = $top->FlatRadiobutton(-image => $p,
			       -variable => \$on,
			       -value => "eins",
			       -command => sub { print "# Current value is: $on\n" },
			       -borderwidth => 20,
			      )->pack;
isa_ok($cb, "Tk::FlatRadiobutton");
my $cb2 = $top->FlatRadiobutton(-image => $p,
				-variable => \$on,
				-value => "zwei",
				-command => sub { print "# Current value is: $on\n" },
				-raiseonenter => 1,
			       )->pack;
isa_ok($cb2, "Tk::FlatRadiobutton");
my $cb3 = $top->FlatRadiobutton(-text => "Text",
				-variable => \$on,
				-value => "drei",
				-command => sub { print "# Current value is: $on\n" },
			       )->pack;
isa_ok($cb3, "Tk::FlatRadiobutton");
my $cb4 = $top->FlatRadiobutton(-text => "Text",
				-variable => \$on,
				-value => "vier",
				-command => sub { print "# Current value is: $on\n" },
				-raiseonenter => 1,
			       )->pack;
isa_ok($cb4, "Tk::FlatRadiobutton");


my $sb = $top->Radiobutton(-text => "Shared",
			   -variable => \$on,
			   -value => "fünf",
			  )->pack;

if (!$ENV{BATCH}) {
    MainLoop;
    for (1..3) { pass("skipping automatic tests") }
} else {
    is($on, 0, "Initial variable value");
    $cb->invoke;
    $cb->update;
    select undef, undef, undef, 0.3;
    is($on, "eins", "After invoke");
    $cb2->invoke;
    $cb2->update;
    is($on, "zwei", "Second invoke");
}

pass("Tk::FlatRadiobutton tests");

__END__
