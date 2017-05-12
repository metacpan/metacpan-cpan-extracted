#!perl -T

package main;

use strict;
use warnings;

use Test::More 'no_plan';

sub with::Mock::right { pass $_[1] }
sub with::Mock::wrong { fail $_[1] }
sub with::Mock::test  { is $_[1], $_[2], $_[3] }

use with \bless {}, 'with::Mock';

right 'normal';
my $s = q{wrong 'string'};
test $s, q{wrong 'string'}, 'string is preserved';
# no with;
right
  'after string';
# wrong('comments');
right 'after comment';
=pod
wrong('POD');
=cut
right q/after POD/;
my $x = "heredoc"; right "before $x";
my $y = <<HEREDOC;
wrong('heredoc');
HEREDOC
right qq[after heredoc];
test $y, "wrong('heredoc');\n", 'heredoc is preserved';
my $d = <DATA>;
test $d, "wrong '__DATA__';\n", 'data is preserved';
__DATA__
wrong '__DATA__';
