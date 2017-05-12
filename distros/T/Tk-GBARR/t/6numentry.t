use strict;
use vars '$loaded';

my $top;
BEGIN {
    if (!eval {
	require Tk;
	$top = MainWindow->new;
    }) {
	print "1..0 # skip cannot open DISPLAY\n";
	CORE::exit;
    }
}

BEGIN { $^W= 1; $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk::NumEntry;
$loaded = 1;
my $ok = 1;
print "ok " . $ok++ . "\n";

######################################################################
# This test script defines a new NumEntry class, consisting of new
# FireButton and NumEntryPlain classes.
#
# The MyFireButton class replaces the increment and decrement pictures
# with some predefined Tk bitmaps.
#
# The MyNumEntryPlain class adds new key events: Prior and Next for
# fast keyboard spinning and Home to reset to the default value.
#
######################################################################
# define own FireButton class
package Tk::MyFireButton;
use base qw(Tk::FireButton);
Construct Tk::Widget "MyFireButton";

sub INCBITMAP { "error" }
sub DECBITMAP { "gray75" }
sub HORIZINCBITMAP { "gray50" }
sub HORIZDECBITMAP { "gray25" }

######################################################################
# define own NumEntryPlain class
package Tk::MyNumEntryPlain;
use base qw(Tk::NumEntryPlain);
Construct Tk::Widget "MyNumEntryPlain";

sub ClassInit {
    my($class, $mw) = @_;
    $class->SUPER::ClassInit($mw);
    $mw->bind($class, '<Shift-Prior>', 'Up10');
    $mw->bind($class, '<Shift-Next>',  'Down10');
    $mw->bind($class, '<Shift-Home>',  'Set0');
}

sub Set0   { my $w = shift;
	     $w->_parent->value($w->cget(-defaultvalue));
	   }
sub Up10   { shift->_parent->incdec(10,'initial') }
sub Down10 { shift->_parent->incdec(-10,'initial') }


######################################################################
# define own NumEntry class
package Tk::MyNumEntry;
use base qw(Tk::NumEntry);
Construct Tk::Widget "MyNumEntry";

sub FireButtonWidget    { "MyFireButton" }
sub NumEntryPlainWidget { "MyNumEntryPlain"  }

######################################################################
# back to main again
package main;

my $ne;
eval {
    $ne = $top->MyNumEntry(-defaultvalue => 42,
			   -increment => '1.0')->pack;
};
if ($@) { print "not " } print "ok " . $ok++ . "\n";

eval {
    $top->MyNumEntry(-orient       => "horizontal",
		     -defaultvalue => 4711,
		     -minvalue => -10000,
		     -maxvalue => +10000,
		     -increment    => 0.1,
		     -bigincrement => 50)->pack;
};
if ($@) { print "not " } print "ok " . $ok++ . "\n";

$ne->configure(-value => 1);
if ($ne->cget(-value) != 1) { print "not " } print "ok " . $ok++ . "\n";

$ne->incdec(1);
if ($ne->cget(-value) != 2) { print "not " } print "ok " . $ok++ . "\n";

$ne->incdec(-1);
if ($ne->cget(-value) != 1) { print "not " } print "ok " . $ok++ . "\n";

$top->update;
#Tk::MainLoop;
