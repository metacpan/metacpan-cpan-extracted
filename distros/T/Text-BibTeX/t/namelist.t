# -*- cperl -*-
use strict;
use warnings;

use IO::Handle;
use Test::More tests => 13;

use vars qw($DEBUG);
use Cwd;
BEGIN {
    use_ok('Text::BibTeX');
    my $common = getcwd()."/t/common.pl";
    require $common;
}

$DEBUG = 0;

# ----------------------------------------------------------------------
# make sure we can split up lists of names

my (@names);

@names =
   ('J. Smith and N. D. Andrews' => ['J. Smith', 'N. D. Andrews'],
    'J. Smith and A. Jones' => ['J. Smith', 'A. Jones'],
    'J. Smith and A. Jones and J. Random' => ['J. Smith', 'A. Jones', 'J. Random'],
    'A. Smith and J. Jones' => ['A. Smith', 'J. Jones'],
    'A. Smith and A. Jones' => ['A. Smith', 'A. Jones'],
    'Amy Smith and Andrew Jones' => ['Amy Smith', 'Andrew Jones'],
    'Amy Smith and And y Jones' => ['Amy Smith', undef, 'y Jones'],
    'K. Herterich and S. Determann and B. Grieger and I. Hansen and P. Helbig and S. Lorenz and A. Manschke' => ['K. Herterich', 'S. Determann', 'B. Grieger', 'I. Hansen', 'P. Helbig', 'S. Lorenz', 'A. Manschke'],
    'A. Manschke and M. Matthies and A. Paul and R. Schlotte and U. Wyputta' => ['A. Manschke', 'M. Matthies', 'A. Paul', 'R. Schlotte', 'U. Wyputta'],
    'S. Lorenz and A. Manschke and M. Matthies' => ['S. Lorenz', 'A. Manschke', 'M. Matthies'],
    'K. Herterich and S. Determann and B. Grieger and I. Hansen and P. Helbig and S. Lorenz and A. Manschke and M. Matthies and A. Paul and R. Schlotte and U. Wyputta' => ['K. Herterich', 'S. Determann', 'B. Grieger', 'I. Hansen', 'P. Helbig', 'S. Lorenz', 'A. Manschke', 'M. Matthies', 'A. Paul', 'R. Schlotte', 'U. Wyputta'],
   );

while (@names) {
  my ($name, $should_split) = (shift @names, shift @names);

  my $actual_split;
  if (!$should_split->[1]) {
    # these should issue a warning
    err_like sub { $actual_split = [Text::BibTeX::split_list ($name, 'and')] },
      qr!empty substring!;
  } else {
    $actual_split = [Text::BibTeX::split_list ($name, 'and')];
  }

  if ($DEBUG) {
    printf "name = >%s<\n", $name;
    print "should split to:\n  ";
    print join ("\n  ", @$should_split) . "\n";
    print "actually split to:\n  ";
    print join ("\n  ", @$actual_split) . "\n";
  }

  ok(slist_equal ($should_split, $actual_split));
}
