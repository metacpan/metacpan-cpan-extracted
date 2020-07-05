use Test2::V0;
use Text::Util::Chinese qw(looks_like_simplified_chinese);

my @cases = (
    ['禁煙的車廂', F()],
    ['禁烟标语随处可见', T()],
);

for(@cases) {
    my ($txt, $expected) = @$_;
    is looks_like_simplified_chinese($txt), $expected, "Case: $txt";
}

done_testing;
