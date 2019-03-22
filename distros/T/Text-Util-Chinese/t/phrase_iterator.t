use strict;
use utf8;
use FindBin '$Bin';

use Text::Util::Chinese qw(phrase_iterator);
use Test2::V0;

open my $fh, '<:utf8', "$Bin/data/rand0m.txt";

my $iter = phrase_iterator(sub { <$fh> });

my $phrases = 0;
while (my $phrase = $iter->()) {
    ok $phrase =~ /\p{Han}/, $phrase;
    $phrases++;
}

ok $phrases > 685, 'phrases muts be more than the number of lines in t/data/rand0m.txt';

done_testing;
