#!perl

use Test::More skip_all => 'new date handling not working yet';
use Test::More tests => 8;

my @expected_burndown = split "\n", <<'EOT';
YYYY/MM/DD\tTotal\tTodo
2005/07/11\t8    \t6
2005/07/13\t8    \t4
2005/07/14\t8    \t2
2005/07/15\t10   \t4
2005/07/16\t12   \t6
2005/07/17\t12   \t5
2005/07/18\t12   \t3
EOT

my @output = `$^X -Mblib bin/hwd --burndown < t/simple.hwd`;
chomp @output;
# make tabs easier to see
s/\t/\\t/g for @output;

is(scalar(@output), scalar(@expected_burndown));
for (my $i=0; $i<$#output; $i++) {
    is($output[$i], $expected_burndown[$i]);
}
