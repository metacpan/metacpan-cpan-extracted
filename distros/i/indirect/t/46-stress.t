#!perl -T

use strict;
use warnings;

my $count;
BEGIN { $count = 1_000 }

use lib 't/lib';
use Test::Leaner tests => 2 * $count;

BEGIN { delete $ENV{PERL_INDIRECT_PM_DISABLE} }

for (1 .. $count) {
 my @errs;
 {
  local $SIG{__WARN__} = sub { die @_ };
  eval q(
   return;
   no indirect hook => sub { push @errs, [ @_[0, 1, 3] ] };
   my $x = new Wut;
  );
 }
 is        $@,     '',                      "didn't croak at run $_";
 is_deeply \@errs, [ [ 'Wut', 'new', 4 ] ], "got the right data at run $_";
}
