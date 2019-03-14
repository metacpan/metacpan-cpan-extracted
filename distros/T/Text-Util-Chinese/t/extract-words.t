use utf8;
use Text::Util::Chinese qw(extract_words);

use Test2::V0;

sub extract_from_these {
    my @input = @_;
    return extract_words(sub { shift @input });
}

my $words = extract_from_these(
    '一節禁煙的車廂',
    '無論在哪裡，都可以看見禁煙標語',
    '我每個月都禁煙一天',
    '禁煙之後容易餓',
    '不禁煙的生活沒有意義',
    '全席禁煙。這多殘酷',
    '我是身處於吸煙區的禁煙者',
);

is $words, ['禁煙'];

done_testing;
