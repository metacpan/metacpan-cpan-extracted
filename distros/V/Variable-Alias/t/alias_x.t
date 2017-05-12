use Test::More tests => 4;

use blib;
use Variable::Alias qw(alias_s alias_a);

my $src;
my $a;
our $b;
my @c;
our @d;

alias_s $src => $a;
alias_s $a => $b;
alias_s $b => $c[0];
alias_a @c => @d;

$src='src';

is($a, $src);
is($b, $src);
is($c[0], $src);
is($d[0], $src);