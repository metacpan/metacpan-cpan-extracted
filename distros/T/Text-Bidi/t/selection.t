use 5.10.0;
use strict;
use warnings;
use utf8;
use Test::More;
use Text::Bidi::Selection;
use Text::Bidi::Array::Long;

my $selection = Text::Bidi::Selection->new(
    text => 'abc אבגד xyz',
    visual_to_logical => [0, 1, 2, 3, 7, 6, 5, 4, 8, 9, 10, 11],
);
is_deeply $selection->logical_ranges(6, 10), [[4, 6], [8, 10]],
    'one visual interval can select two separate logical ranges';
is $selection->selected_text(6, 10), 'אב x',
    'unselected letters between logical ranges are omitted';
is $selection->selected_text(4, 6), 'גד', 'an RTL interval is copied in logical order';
is $selection->selected_text(0, 12), 'abc אבגד xyz', 'the full selection preserves original text';
is_deeply $selection->logical_ranges(0, 0), [], 'an empty selection has no ranges';
is $selection->selected_text(0, 0), '', 'an empty selection copies no text';
is_deeply $selection->logical_ranges(12, 12), [], 'an empty selection at the end is valid';
is $selection->selected_text('00', '02'), 'ab', 'integer strings use numeric visual offsets';

$selection = Text::Bidi::Selection->new(text => 'אב', visual_to_logical => [1, 0]);
is_deeply $selection->logical_ranges(0, 1), [[1, 2]], 'a minimal RTL selection maps the visible letter';
is $selection->selected_text(0, 1), 'ב', 'a minimal RTL selection copies the visible letter';

$selection = Text::Bidi::Selection->new(text => '漢A', visual_to_logical => [0, 0, 1]);
is $selection->selected_text(0, 1), '漢', 'the first cell selects a wide character';
is $selection->selected_text(1, 2), '漢', 'the continuation cell selects the same wide character';
is $selection->selected_text(0, 2), '漢', 'selecting both cells does not duplicate the character';
is_deeply $selection->logical_ranges(0, 3), [[0, 2]], 'adjacent logical characters form one range';

$selection = Text::Bidi::Selection->new(text => 'אְב', visual_to_logical => [2, [0, 1]]);
is $selection->selected_text(1, 2), 'אְ', 'a grapheme selects its base and combining mark';
is_deeply $selection->logical_ranges(1, 2), [[0, 2]], 'grapheme offsets count original code points';
is $selection->selected_text(0, 2), 'אְב', 'grapheme selection preserves the original normalization';

$selection = Text::Bidi::Selection->new(text => 'لا', visual_to_logical => [[1, 0, 1]]);
is $selection->selected_text(0, 1), 'لا', 'a ligature copies both original Arabic letters once';
is_deeply $selection->logical_ranges(0, 1), [[0, 2]], 'a grouped mapping is deduplicated and sorted';

$selection = Text::Bidi::Selection->new(text => 'א(', visual_to_logical => [1, 0]);
is $selection->selected_text(0, 1), '(', 'copying preserves original punctuation rather than mirroring it';

$selection = Text::Bidi::Selection->new(text => 'A😀א', visual_to_logical => [2, 1, 1, 0]);
is_deeply $selection->logical_ranges(1, 3), [[1, 2]], 'supplementary characters occupy one logical offset';
is $selection->selected_text(1, 3), '😀', 'supplementary characters are copied intact';
$selection = Text::Bidi::Selection->new(text => "A\0B", visual_to_logical => [2, 1, 0]);
is $selection->selected_text(0, 3), "A\0B", 'embedded NUL characters are preserved';

$selection = Text::Bidi::Selection->new(text => 'abc', visual_to_logical => [undef, [], 2, []]);
is_deeply $selection->logical_ranges(0, 2), [], 'padding and inserted characters have no logical ranges';
is $selection->selected_text(0, 2), '', 'selecting only unmapped positions copies nothing';
is $selection->selected_text(0, 4), 'c', 'unmapped positions around text are ignored';
$selection = Text::Bidi::Selection->new(text => '', visual_to_logical => [undef, []]);
is $selection->selected_text(0, 2), '', 'empty source text can have display padding';
$selection = Text::Bidi::Selection->new(text => '', visual_to_logical => []);
is_deeply $selection->logical_ranges(0, 0), [], 'empty text and map are supported';

$selection = Text::Bidi::Selection->new(text => 'abcdefg', visual_to_logical => [6, 1, 2, 4, 4, 0, 5, 3]);
is_deeply $selection->logical_ranges(0, 4), [[1, 3], [4, 5], [6, 7]],
    'separated logical ranges stay separate and are returned in reading order';
is $selection->selected_text(0, 4), 'bceg', 'separate ranges concatenate without adding characters';
is_deeply $selection->logical_ranges(4, 8), [[0, 1], [3, 6]],
    'adjacency is based on logical offsets rather than visual neighbors';

my $reported_line = 'משמר הבחירות האזרח│השיבוצים נפתחים בימים הקרובים - עוד לא הצטרפת לווט        │ ';
$selection = Text::Bidi::Selection->new(
    text => $reported_line,
    visual_to_logical => [(reverse 0..17), 18, (reverse 19..76), 77, 78, undef],
);
is_deeply $selection->logical_ranges(62, 68), [[28, 34]],
    'the reported visual Hebrew word maps to its original logical range';
is $selection->selected_text(62, 68), 'נפתחים',
    'the reported table selection copies the intended word';

my $source = 'abc';
my $map = [[1, 0], [2]];
$selection = Text::Bidi::Selection->new(text => $source, visual_to_logical => $map);
$source = 'xyz';
$map->[0][0] = 2;
push @{$map->[0]}, 2;
$map->[1] = [0];
push @$map, [1];
is $selection->selected_text(0, 2), 'abc', 'text and nested map entries are captured by value';
my $ranges = $selection->logical_ranges(0, 2);
$ranges->[0][0] = 99;
push @$ranges, [7, 8];
is_deeply $selection->logical_ranges(0, 2), [[0, 3]], 'returned ranges cannot mutate the selection snapshot';

my $array = Text::Bidi::Array::Long->new([2, 1, 0]);
$selection = Text::Bidi::Selection->new(text => 'abc', visual_to_logical => $array);
$array->[0] = 0;
is $selection->selected_text(0, 2), 'bc', 'dual-life arrays can supply an independent map snapshot';

sub rejects {
    my ($name, $call, $message) = @_;
    my $ok = eval { $call->(); 1 };
    ok !$ok, $name;
    like $@, $message, "$name reports its error";
}

for my $bad (3, -1, 0.5, 'letter', [undef], [[0]]) {
    rejects 'invalid logical map offset', sub {
        Text::Bidi::Selection->new(text => 'abc', visual_to_logical => [$bad]);
    }, qr/Map offsets/;
}
rejects 'missing logical text', sub {
    Text::Bidi::Selection->new(visual_to_logical => []);
}, qr/text must be a defined string/;
rejects 'reference instead of text', sub {
    Text::Bidi::Selection->new(text => [], visual_to_logical => []);
}, qr/text must be a defined string/;
for my $bad (undef, {}, 'map') {
    rejects 'invalid map container', sub {
        Text::Bidi::Selection->new(text => 'abc', visual_to_logical => $bad);
    }, qr/visual_to_logical must be an array reference/;
}
rejects 'unknown constructor argument', sub {
    Text::Bidi::Selection->new(text => '', visual_to_logical => [], typo => 1);
}, qr/Unknown argument: typo/;
rejects 'unpaired constructor arguments', sub {
    Text::Bidi::Selection->new('text');
}, qr/Expected named arguments/;

$selection = Text::Bidi::Selection->new(text => 'abc', visual_to_logical => [2, 1, 0]);
for my $bounds ([2, 1], [0, 4], [3, 4]) {
    rejects 'out-of-bounds visual selection', sub {
        $selection->selected_text(@$bounds);
    }, qr/Visual range/;
}
for my $bounds ([-1, 2], [0, 1.5], [undef, 2], [0, 'end']) {
    rejects 'invalid visual offset', sub {
        $selection->logical_ranges(@$bounds);
    }, qr/Visual offsets must be non-negative integers/;
}
rejects 'missing end offset', sub {
    $selection->logical_ranges(0);
}, qr/Expected visual start and end offsets/;
rejects 'extra selection argument', sub {
    $selection->selected_text(0, 1, 2);
}, qr/Expected visual start and end offsets/;

done_testing;
