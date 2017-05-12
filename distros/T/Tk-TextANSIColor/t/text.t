#!/usr/local/bin/perl -w

# Test of Tk::TextANSIColor
#  This test requires that Tk widgets can be opened
#  This test will launch a Tk widget and write to it using
#  ANSI color codes. Unfortunately, it can not check that the
#  codes were displayed correctly......

# Also tests the tied version

#  In order to do this it simply keeps the window up for a few seconds
#  in case anyone needs to look at it

# Copyright (C) 2010 Tim Jenness
# Copyright (C) 2000 Tim Jenness and the Particle Physics and Astronomy
# Research Council. All Rights Reserved.

use strict;
use Test::More tests => 13;

use Term::ANSIColor;
use Tk;

require_ok( "Tk::TextANSIColor" );

# Create new Tk

SKIP: {

my $MW = eval { MainWindow->new() };

# If we have not managed to get a MainWindow that probably
# means we are running headless so skip all remaining tests
skip("Unable to launch Tk MainWindow. Is there a display attached?", 12)
  unless defined $MW;

ok( defined $MW, "MainWindow" );

# Create a simple text wiget

my $text = $MW->TextANSIColor->pack;

isa_ok( $text, "Tk::TextANSIColor" );

# We dont want to run an event loop - just do an update
$MW->update;

# Some normal text
doprint($text, "Normal text, no ANSI codes\n");
ok(1, "print text without crashing" );

# Some colored text

foreach (qw/ red green blue magenta yellow cyan bold underline /) {
  doprint( $text, colored("This is a test of $_\n", "$_") );
  ok(1, "colored text");
}

# Now try a tie
use vars qw/ *HDL /;
my $tie = tie(*HDL, ref($text), $text);

ok(defined $tie, "Got Tie");

# Cant yet test the return status of a print from a tied text widget
# since it always returns undef (as of v800.021).

print HDL "Some normal text from a tied handle.\n";
print HDL colored("Some tied text in red\n", 'red');

$tie->update;

sleep 3;

}

exit;


# Sub to print a string to the widget and update the display
# could do it with a tied filehandle instead

sub doprint {
  my $text = shift;
  my $str = shift;
  my $ret = $text->insert('end', $str);
  $text->update;
}



