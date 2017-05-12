#!perl -wT
# Win32::GUI test suite.
# $Id: 02_window.t,v 1.5 2008/02/08 14:44:57 robertemay Exp $
#
# Win32::GUI::Window tests:
# - check that we can create and manipulate Windows

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 17;

use Win32::GUI();

# check that the methods we want to use are available
can_ok('Win32::GUI::Window', qw(new Left Top Width Height Move Resize Text) );

my $W = new Win32::GUI::Window(
    -name => "TestWindow",
    -pos  => [  0,   0],
    -size => [210, 200],
    -text => "TestWindow",
);

isa_ok($W, "Win32::GUI::Window");

is($W->Left,0, "Window LEFT correct");
is($W->Top, 0, "Window TOP correct");
is($W->Width,210, "Window WIDTH correct");
is($W->Height, 200, "Window HEIGHT correct");
is($W->Text, "TestWindow", "Window TITLE correct");

$W->Left(100);
is($W->Left, 100, "Change window LEFT");

$W->Top(100);
is($W->Top, 100, "Change window TOP");

$W->Width(310);
is($W->Width, 310, "Change window WIDTH");

$W->Height(300);
is($W->Height, 300, "Change window HEIGHT");

$W->Move(0, 0);
is($W->Left, 0, "Move window, LEFT");
is($W->Top, 0, "Move winodw TOP");

$W->Resize(210, 200);
is($W->Width, 210, "Resize winodw WIDTH");
is($W->Height, 200, "Resize winodw HEIGHT");

$W->Text("TestChanged");
is($W->Text ,"TestChanged", "Change winodw TITLE");

# Adding style WS_POPUP causes a change in message ordering during
# CreateWindowEx(), esp. it adds a WM_SIZE, which we will try to
# dispatch.  Prior to 1.05_90 we didn't have $win->{-handle}
# set before the callback, resuting in 'use of uninitialised
# value in subroutine entry' when calling handleFrom() in XS.
{
    use warnings;
    use Win32::GUI::Constants();

    my $warning;
    local $SIG{__WARN__} = sub {
        $warning = $_[0];
    };

    $warning = '';
    my $win = Win32::GUI::Window->new(-addstyle => Win32::GUI::Constants::WS_POPUP());
    undef $win;
    is($warning, '', "Don't want warnings from constructors");
}
