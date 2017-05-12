use Test::More();

BEGIN {
    if($^V lt 5.8.0) {
        import Test::More skip_all => "alias() doesn't work before 5.8";
    }
    else {
        import Test::More tests    => 4;
    }
}

use blib;
use Variable::Alias 'alias';

my $src;
my $a;
our $b;
my @c;
our @d;

alias $src => $a;
alias $a => $b;
alias $b => $c[0];
alias @c => @d;

$src='src';

is($a, $src);
is($b, $src);
is($c[0], $src);
is($d[0], $src);