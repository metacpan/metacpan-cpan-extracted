use utf8;
use strict;
use Test::More tests => 2;
use Text::Autoformat;

my $str = <<'END';
1. Analyze problem
0. Design algorithm
3. Code solution
END

my $after = autoformat $str, { lists => 'number', all => 1 }; 

is(
  $after,
  "1. Analyze problem\n2. Design algorithm\n3. Code solution\n",
  "do not lose 0 in list"
);

$str = <<'END';
4.0 Analyze problem
END

$after = autoformat $str, { lists => 'number', all => 1 }; 

is(
  $after,
  "4.0 Analyze problem\n",
  "do not lose 0 at end of list"
);

