#!/usr/local/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 1998,2004,2007,2012 Slaven Rezic. All rights reserved.
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

plan tests => 10;

use_ok("Tk::FlatCheckbox");

my $top = tkinit;
$top->geometry("+10+10");
$top->Label(-text => "Tk::FlatCheckbox")->pack;
#$top->optionAdd("*FlatCheckbox*background" => "green", "userDefault");
my $p = $top->Photo(-file => Tk->findINC("icon.gif"));
my $on = 0;
my $on2;
my $cb = $top->FlatCheckbox(-image => $p,
			    -variable => \$on,
			    -command => sub { print "# Current value is: $on\n" },
			    -borderwidth => 20,
			   )->pack;
isa_ok($cb, "Tk::FlatCheckbox");
my $cb2 = $top->FlatCheckbox(-image => $p,
			     -variable => \$on,
			     -command => sub { print "# Current value is: $on\n" },
			     -raiseonenter => 1,
			    )->pack;
isa_ok($cb2, "Tk::FlatCheckbox");
my $cb3 = $top->FlatCheckbox(-text => "Text",
			     -variable => \$on,
			     -command => sub { print "# Current value is: $on\n" },
			    )->pack;
isa_ok($cb3, "Tk::FlatCheckbox");
my $cb4 = $top->FlatCheckbox(-text => "Text",
			     -variable => \$on,
			     -command => sub { print "# Current value is: $on\n" },
			     -raiseonenter => 1,
			    )->pack;
isa_ok($cb4, "Tk::FlatCheckbox");
my $cb5 = $top->FlatCheckbox(-text => "Other value",
			     -variable => \$on2,
			     -command => sub { print "# Current value is: $on2\n" },
			     -raiseonenter => 1,
			     -onvalue => "on",
			     -offvalue => "off",
			    )->pack;
isa_ok($cb5, "Tk::FlatCheckbox");

my $sb = $top->Checkbutton(-text => "Shared",
			   -variable => \$on,
			  )->pack;
if (!$ENV{BATCH}) {
    MainLoop;
    for (1..3) { pass("skipping automatic tests") }
} else {
    $top->update;
    is($on, 0, "Initial variable value");
    $cb->invoke;
    $top->update;
    select undef, undef, undef, 0.3;
    is($on, 1, "After invoke");
    $cb->invoke;
    $top->update;
    is($on, 0, "Again after invoke");
}

pass("FlatCheckbox demo");

__END__
