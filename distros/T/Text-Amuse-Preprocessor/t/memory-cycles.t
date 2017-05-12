use strict;
use warnings;
use Test::More;

eval "use Test::Memory::Cycle";
if ($@) {
    plan skip_all => "Test::Memory::Cycle required for testing memory cycles";
    exit;
}
else {
    plan tests => 1;
}

use Text::Amuse::Preprocessor::Typography qw/get_typography_filter/;

my $sub = get_typography_filter(en => 1);

memory_cycle_ok($sub);

