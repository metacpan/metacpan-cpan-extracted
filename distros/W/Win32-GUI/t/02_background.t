##!perl -wT
# Win32::GUI test suite.
# $Id: 02_background.t,v 1.1 2011/07/16 14:51:03 acalpini Exp $
#
# Win32::GUI::Window tests:
# - check background brush GDI object leak (cfr. bug #2864551)

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 8;

use Win32::GUI();

# we need those to stay in scope
my $hbrush;
my $hbrush1;
my $hbrush2;

{
	my $W = new Win32::GUI::Window(
		-name => "TestWindow",
		-pos  => [  0,   0],
		-size => [210, 200],
		-text => "TestWindow",
	);

	my $L = $W->AddLabel(
		-background => 0xff00ff,
		-name       => "label",
	);

	$hbrush = $L->{"-backgroundbrush"};

	my @brushinfo = Win32::GUI::Brush::Info($hbrush);
	ok(@brushinfo > 0, "got -backgroundbrush info");
}

# $W/$L go out of scope, $hbrush should now be invalid

my $brushinfo = Win32::GUI::Brush::Info($hbrush);
ok(!defined($brushinfo), "-backgroundbrush gone out of scope");

# create a Win32::GUI::Brush object
	
my $brush = Win32::GUI::Brush->new(
	-style => 0, # BS_SOLID
	-color => 0xff00ff,
);

$hbrush = $brush->{"-handle"};

# create 2 windows with the same -backgroundbrush

{
	my $W = new Win32::GUI::Window(
		-name => "TestWindow",
		-pos  => [  0,   0],
		-size => [210, 200],
		-text => "TestWindow",
	);

	my $L1 = $W->AddLabel(
		-backgroundbrush => $brush,
		-name            => "label1",
	);

	my $L2 = $W->AddLabel(
		-backgroundbrush => $brush,
		-name            => "label2",
	);

	my $hbrush1 = $L1->{"-backgroundbrush"};
	my $hbrush2 = $L2->{"-backgroundbrush"};
	# check if we used the Win32::GUI::Object
	ok($hbrush == $hbrush1, "-backgroundbrush works");
	# check if we used the same for the two windows
	ok($hbrush1 == $hbrush2, "same -backgroundbrush used");
	
}

# destroying the windows does not destroy the brush
my @brushinfo = Win32::GUI::Brush::Info($hbrush1);
ok(@brushinfo > 0, "-backgroundbrush still in scope");


# test the Change() method

{
	my $W = new Win32::GUI::Window(
		-name => "TestWindow",
		-pos  => [  0,   0],
		-size => [210, 200],
		-text => "TestWindow",
	);

	my $L = $W->AddLabel(
		-background => 0xff00ff,
		-name       => "label",
	);

	$hbrush1 = $L->{"-backgroundbrush"};

	$L->Change(
		-background => 0x00ff00,
	);

	my $brushinfo = Win32::GUI::Brush::Info($hbrush1);
	ok(!defined($brushinfo), "-backgroundbrush destroyed after Change");


}

# test Change() with a Win32::GUI::Brush object

{
	my $W = new Win32::GUI::Window(
		-name => "TestWindow",
		-pos  => [  0,   0],
		-size => [210, 200],
		-text => "TestWindow",
	);

	my $L = $W->AddLabel(
		-backgroundbrush => $brush,
		-name   => "label",
	);

	$hbrush1 = $L->{"-backgroundbrush"};

	$L->Change(
		-background => 0x00ff00,
	);

	$hbrush2 = $L->{"-backgroundbrush"};

	my $brushinfo = Win32::GUI::Brush::Info($hbrush1);
	ok(@brushinfo > 0, "Win32::GUI::Brush object still in scope");
	
	ok($hbrush1 != $hbrush2, "-backgroundbrush changed after Change");
}
