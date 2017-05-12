#! /usr/bin/perl
#---------------------------------------------------------------------
# 20-unicode.t
#---------------------------------------------------------------------

use 5.008;
use strict;
use warnings;
use utf8;

use Test::More;

# Load Test::Differences, if available:
BEGIN {
  # SUGGEST PREREQ: Test::Differences
  if (eval "use Test::Differences; 1") {
    # Not all versions of Test::Differences support changing the style:
    eval { Test::Differences::unified_diff() }
  } else {
    *eq_or_diff = \&is;         # Just use "is" instead
  }
} # end BEGIN

use Text::Wrapper;

my $generate = (@ARGV and $ARGV[0] eq 'print');

if ($generate) {
  open(OUT, '>:utf8', '/tmp/20-unicode.t') or die;

  print OUT "\n__DATA__\n";
} else {
  plan tests => 4;
}

#---------------------------------------------------------------------
# Now try each set of parameters and compare it to the expected result:
#   (Or, if invoked as '20-unicode.t print', print out the actual
#   results and parameters in the required format.)

my ($name, $text, @args);

while (<DATA>) {
  print OUT $_ if $generate;

  if (/^\* (.+)/) {
    $name = $1;
    defined($_ = <DATA>) or die;
    print OUT $_ if $generate;
    @args = eval $_;
    $text = '';
  } elsif ($_ eq "===\n") {
    # Read the expected results:
    my $expected = '';
    while (<DATA>) {
      last if $_ eq "---\n";
      $expected .= $_;
    }

    # Remove single line breaks, and condense double line breaks into one:
    $text =~ s/\n(?=\S)/ /g;
    $text =~ s/\n /\n/g;

    my $w = Text::Wrapper->new(@args);
    my $result = $w->wrap($text);
    if ($generate) { print OUT "$result---\n" }
    else {
      # Make Unicode characters visible in output:
      for ($result, $expected) {
        s/([\xA0\x{100}-\x{feff}])/ sprintf '{%X}', ord $1 /eg;
      }
      eq_or_diff($result, $expected, $name)
    }

    undef $name;
    @args = ();
  } elsif (/^#/) {
    # comment
  } else {
    $text .= $_;
  }
} # end forever

#---------------------------------------------------------------------
# Here are test cases.
# Don't forget to change the count in the "plan tests" line.

__DATA__
* unusual spaces
(columns => 40)
Fourscore and seven years ago our fathers brought forth on this continent a new nation, conceived in liberty and dedicated to the proposition that all men are created equal.
===
Fourscore and seven years ago our
fathers brought forth on this continent
a new nation, conceived in liberty and
dedicated to the proposition that all
men are created equal.
---


* break after dashes
(columns => 40, wrap_after => "-\x{2013}\x{2014}")
Fourscore and seven years ago our-fathers brought forth on this
continent—a new nation, conceived in liberty and–dedicated to the
proposition that all men are created equal.
===
Fourscore and seven years ago our-
fathers brought forth on this continent—
a new nation, conceived in liberty and–
dedicated to the proposition that all
men are created equal.
---


* do not break after dashes
(columns => 40)
Fourscore and seven years ago our-fathers brought forth on this
continent—a new nation, conceived in liberty and–dedicated to the
proposition that all men are created equal.
===
Fourscore and seven years ago our-
fathers brought forth on this
continent—a new nation, conceived in
liberty and–dedicated to the proposition
that all men are created equal.
---

* "zero-width" spaces
(columns => 40)
Fourscore​and​seven​years​ago​our​fathers​brought​forth​on​this​continent​a​new​nation,​conceived​in​liberty​and​dedicated​to​the​proposition​that​all​men​are​created​equal.
===
Fourscore​and​seven​years​ago​our
fathers​brought​forth​on​this​continent
a​new​nation,​conceived​in​liberty​and
dedicated​to​the​proposition​that​all
men​are​created​equal.
---

# Local Variables:
#  compile-command: "perl 20-unicode.t print"
# End:
