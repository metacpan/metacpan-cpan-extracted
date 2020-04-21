use strict;
use utf8;

use Text::Util::Chinese qw(extract_presuf presuf_iterator);

use Test2::V0;

my @input = (
    '禁煙的車廂',
    '禁煙標語隨處可見',
    '我每個月都有一天禁煙',
    '禁煙之後容易餓',
    '禁煙的生活很有意義',
    '全席禁煙',
    '只有部分禁煙',
);

subtest 'extract_presuf' => sub {
    my @copy = @input;
    my $extracted = extract_presuf(
        sub { shift @copy },
        { threshold => 2 },
    );

    is $extracted, ['禁煙'];
};

subtest 'presuf_iterator' => sub {
    my @params = (
        [ { threshold => 2 }, ['禁煙'] ],
        [ { threshold => 8 }, [] ],
    );

    for my $param (@params) {
        my @copy = @input;
        my ($opts, $expected) = @$param;

        subtest "Threshold: $opts->{threshold}" => sub {
            my $iter = presuf_iterator(
                sub { shift @copy },
                $opts,
            );

            my @extracted;
            while (defined(my $it = $iter->())) {
                push @extracted, $it;
            }

            is \@extracted, $expected;
        };
    }
};

done_testing;
