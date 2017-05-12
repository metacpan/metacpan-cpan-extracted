use strict;

use Test::More tests => 1;
my $treport = 'scripts/treport';

my $data = qq|
foo=bar
baz=0
|;

my $output = `echo "$data" | $treport`;
print $output;
ok ( $?==0, "Verifying processing of treport script") or
    diag("'$treport' failed to generate correct output: $output");



