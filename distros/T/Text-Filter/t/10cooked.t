#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;

-d 't' && chdir 't';

BEGIN {
    use_ok qw(Text::Filter::Cooked);
    use_ok qw(File::Compare);
}

my ($new, $f, $id, $inp);

my $dat = <<EOD;
# This is comment, and ignored.
This is data in ASCII
This is data in ASCII

This \\
  will \\
    be     glued   \\
           together \\
as one line
EOD

my $ref = <<EOD;
  2	This is data in ASCII
  3	This is data in ASCII
  5	This will be glued together as one line
EOD

my $ref2 = <<EOD;
This is data in ASCII
This is data in ASCII
This will be glued together as one line
EOD

$id = "basic";		################
$inp = $dat; $new = "";
$f = Text::Filter::Cooked->new
  (input => \$inp,
   output => \$new,
   comment => "#",
   join_lines => "\\");

while ( my $line = $f->readline ) {
    $f->writeline(sprintf("%3d\t%s", $f->lineno, $line));
}

is($new, $ref, $id);

$id = "run";		################
$inp = $dat; $new = "";
$f = Text::Filter::Cooked->new
  (input => \$inp,
   output => \$new,
   comment => "#",
   join_lines => "\\");

$f->run;

is($new, $ref2, $id);

$id = "quick";		################
$inp = $dat; $new = "";
Text::Filter::Cooked->run
  (input => \$inp,
   output => \$new,
   comment => "#",
   join_lines => "\\");

is($new, $ref2, $id);

