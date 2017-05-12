use strict;
use warnings;
use utf8;
use Test::Base::Less;

run {
    my $block = shift;
    is($block->input, 'MMM');
};

done_testing;
__END__

===
--- input: YYY

===
--- ONLY
--- input: MMM

===
--- input: ZZZ
