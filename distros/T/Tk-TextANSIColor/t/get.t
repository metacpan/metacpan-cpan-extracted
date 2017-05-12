#!/usr/local/bin/perl -w

# Test the getansi function
use strict;
use Test::More tests => 5;

use Term::ANSIColor;
use Tk;

require_ok( "Tk::TextANSIColor" );

# Create new Tk

SKIP: {

my $MW = eval { MainWindow->new() };

# If we have not managed to get a MainWindow that probably
# means we are running headless so skip all remaining tests
skip("Unable to launch Tk MainWindow. Is there a display attached?", 4)
  unless defined $MW;

ok( defined $MW, "Mainwindow" );

# Create a simple text wiget

my $text = $MW->TextANSIColor->pack;
isa_ok($text, "Tk::TextANSIColor" );

# We don't care if the window never appears. We are
# just checking the contents

# Create a string using all the known codes
my $string = "nocolor ";
# And one without them
my $nocode = $string;
for (qw/ red green blue magenta yellow cyan bold underline /) {
  $string .= colored(" $_ ", "$_");
  $nocode .= " $_ ";
}
$string .= " finish";
$nocode .= " finish";

# Now insert it
$text->insert('1.0', $string);

# And get it back
my $res = $text->getansi('1.0','end');
chomp($res); # remove additional newline

# Compare the two - should be identical
is($res,$string, "Compare strings");

# A simple get should give the same as a stripped input string
$res = $text->get('1.0','end');
chomp($res);
is($res,$nocode, "Compare stripped");

}
