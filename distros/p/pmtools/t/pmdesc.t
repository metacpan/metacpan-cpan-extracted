# pmdesc testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 2;

# ------ define variable
my $output_split   = undef;
my $output_unified = undef;

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

my $split;
my $unified;

eval {
    $output_unified = `bin/pmdesc Carp 2>&1`;
};
$unified = $?;

eval {
    $output_split = `bin/pmdesc --splitpod Carp 2>&1`;
};
$split = $?;

if ($unified == 0 || $split == 0) {
    is($?, 0, "pmdesc runs");
} else {
    fail('pmdesc fails to run');
}
if ($output_unified =~ m/Carp\D+\(\d+\.\d+\)\s-\s\w/msx
 || $output_split   =~ m/Carp\D+\(\d+\.\d+\)\s-\s\w/msx) {
    pass('described a module');
} else {
    fail('no description found by pmdesc');
}
