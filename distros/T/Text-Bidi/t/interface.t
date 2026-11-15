use 5.10.0;
use strict;
use warnings;
use Test::More;
use Text::Bidi qw(log2vis);
use Text::Bidi::Constants;
use Text::Bidi::Selection;

my $bd = Text::Bidi->new;
my $text = "a(\x{5d0})\x{5d1}";
my $internal = $bd->utf8_to_internal($text);
my $types = $bd->get_bidi_types($internal);
my $brackets = $bd->get_bracket_types($internal, $types);

is_deeply [@$brackets], [@{$bd->get_bracket_types($internal)}],
    'bracket types can compute bidi types automatically';
is $brackets->[0], 0, 'a letter is not a bracket';
ok $brackets->[1] & $Text::Bidi::private::FRIBIDI_BRACKET_OPEN_MASK,
    'opening bracket has the opening bit';
is $brackets->[1] & $Text::Bidi::private::FRIBIDI_BRACKET_ID_MASK,
    $brackets->[3], 'paired brackets have the same ID';
is Text::Bidi::private::get_bracket(ord '('), $brackets->[1],
    'single-character bracket lookup returns a number';

my ($dir, $levels) = $bd->get_par_embedding_levels($types, undef, $brackets);
is $dir, $Text::Bidi::Par::LTR, 'paragraph direction is resolved';
is_deeply [@$levels], [0, 0, 1, 0, 1], 'N0 resolves paired brackets together';
my (undef, $legacy) = $bd->get_par_embedding_levels($types);
is_deeply [@$legacy], [0, 0, 1, 1, 1],
    'embedding levels without bracket properties preserve the old interface';

my ($paragraph, $visual) = log2vis($text);
is $visual, $text, 'log2vis uses bracket-aware resolution';
is_deeply [@{$paragraph->levels}], [0, 0, 1, 0, 1],
    'Paragraph passes bracket properties to FriBidi';
is_deeply $paragraph->map, [0, 1, 2, 3, 4], 'bracket-aware visual map';

($paragraph, $visual) = log2vis("a\x{2067}\x{5d0}()\x{2069}b");
is $visual, "a\x{2067}()\x{5d0}\x{2069}b", 'isolates preserve bracket pairs';
is_deeply [@{$paragraph->levels}], [0, 0, 1, 1, 1, 0, 0],
    'embedding levels inside an RTL isolate';

my @mirrored = Text::Bidi::private::get_mirror_char(ord '(');
is_deeply \@mirrored, [1, ord ')'], 'mirror lookup returns a boolean and code point';
is_deeply [Text::Bidi::private::get_mirror_char(ord 'a')], [0, ord 'a'],
    'a non-mirrored character returns false';

for my $string ('', "a\0b", "\x{5d0}\x{1f600}\x{10ffff}") {
    my $packed = $bd->utf8_to_internal($string);
    is scalar(@$packed), length($string), 'UTF-8 conversion counts code points';
    is $bd->internal_to_utf8($packed), $string, 'UTF-8 conversion round trip';
}
($paragraph, $visual) = log2vis('');
is $visual, '', 'empty paragraphs remain empty';
is_deeply [@{$paragraph->levels}], [], 'empty embedding levels';

my $packed = $bd->utf8_to_internal('(');
my $snapshot = $$packed;
my $mirrored = $bd->mirrored($bd->tie_byte([1]), $packed);
is $bd->internal_to_utf8($mirrored), ')', 'mirroring returns modified text';
is $$packed, $snapshot, 'mirroring leaves its input unchanged';
is $bd->internal_to_utf8($packed), '(', 'shared Perl buffers remain unchanged';

my $packed_levels = $$levels;
my $map = $bd->tie_long([0..4]);
my $packed_map = $$map;
my ($out_levels, $out_map) = $bd->reorder_map(
    $types, 0, 5, $dir, $map, $levels);
is $$levels, $packed_levels, 'reordering leaves input levels unchanged';
is $$map, $packed_map, 'reordering leaves input map unchanged';
is_deeply $out_map, [0..4], 'reordering returns the resulting map';

my $rtl = $bd->utf8_to_internal("\x{5d0}\x{5d1}\x{5d2}");
my $rtl_types = $bd->get_bidi_types($rtl);
my ($rtl_dir, $rtl_levels) = $bd->get_par_embedding_levels($rtl_types);
my $rtl_map = $bd->tie_long([0..2]);
my (undef, $line_map) = $bd->reorder_map(
    $rtl_types, 1, 2, $rtl_dir, $rtl_map, $rtl_levels);
is_deeply $line_map, [0, 2, 1], 'a nonzero line offset reorders only that line';
is_deeply [@$rtl_map], [0, 1, 2], 'reordering a line preserves the original map';

my $space_types = $bd->get_bidi_types($bd->utf8_to_internal("\x{5d0} \x{5d1}"));
my ($space_dir, $space_levels) = $bd->get_par_embedding_levels(
    $space_types, $Text::Bidi::Par::LTR);
my ($line_levels) = $bd->reorder_map(
    $space_types, 0, 2, $space_dir, undef, $space_levels);
is_deeply $line_levels, [1, 0, 1], 'line reordering resets trailing whitespace levels';
is_deeply [@$space_levels], [1, 1, 1], 'line reordering preserves paragraph levels';

my $arabic = $bd->utf8_to_internal("\x{644}\x{62d}");
my $arabic_types = $bd->get_bidi_types($arabic);
my (undef, $arabic_levels) = $bd->get_par_embedding_levels($arabic_types);
my $joining = $bd->get_joining_types($arabic);
my $original_joining = $$joining;
my $props = $bd->join_arabic($arabic_types, $arabic_levels, $joining);
is $$joining, $original_joining, 'Arabic joining leaves input properties unchanged';
my $original_props = $$props;
my $original_arabic = $$arabic;
my ($shaped_props, $shaped) = Text::Bidi::private::shape(
    $Text::Bidi::private::FRIBIDI_FLAGS_ARABIC,
    $$arabic_levels, $$props, $$arabic);
is $bd->internal_to_utf8($shaped), "\x{fedf}\x{fea2}",
    'the combined shaping API accepts packed properties';
is $$props, $original_props, 'Arabic shaping leaves input properties unchanged';
is $$arabic, $original_arabic, 'Arabic shaping leaves input characters unchanged';
is Text::Bidi::private::get_joining_type(ord "\x{644}"), $joining->[0],
    'single-character joining lookup returns a number';

for my $class ('Text::Bidi::Array::Byte', 'Text::Bidi::Array::Long') {
    my $empty = $class->new;
    is scalar(@$empty), 0, "$class starts empty";
    $empty->[0] = 1;
    @$empty = ();
    is $$empty, '', "$class clears to an empty packed string";
}

sub rejects {
    my ($name, $call, $message) = @_;
    my $ok = eval { $call->(); 1 };
    ok !$ok, $name;
    like $@, $message, "$name reports the error";
}

rejects 'incomplete packed code point', sub {
    Text::Bidi::private::get_bidi_types('x');
}, qr/Invalid packed array length/;
rejects 'mismatched bracket types', sub {
    Text::Bidi::private::get_par_embedding_levels_ex($$types, '', $dir);
}, qr/equal lengths/;
rejects 'mismatched bidi types in bracket lookup', sub {
    Text::Bidi::private::get_bracket_types($$internal, '');
}, qr/equal lengths/;
rejects 'mismatched levels in mirroring', sub {
    Text::Bidi::private::shape_mirroring('', $$internal);
}, qr/equal lengths/;
rejects 'mismatched levels in joining', sub {
    Text::Bidi::private::join_arabic($$arabic_types, '', $$joining);
}, qr/equal lengths/;
rejects 'mismatched properties in shaping', sub {
    Text::Bidi::private::shape_arabic(0, $$arabic_levels, '', $$arabic);
}, qr/equal lengths/;
rejects 'short map in reordering', sub {
    Text::Bidi::private::reorder_map(0, $$types, 0, 5, $dir, $$levels, '');
}, qr/equal lengths/;
rejects 'negative line offset', sub {
    $bd->reorder_map($types, -1, 1, $dir, $map, $levels);
}, qr/outside the paragraph/;
rejects 'line past the paragraph', sub {
    $bd->reorder_map($types, 4, 2, $dir, $map, $levels);
}, qr/outside the paragraph/;
rejects 'negative line length', sub {
    $bd->reorder_map($types, 0, -1, $dir, $map, $levels);
}, qr/outside the paragraph/;

my $selection_text = "abc \x{5d0}\x{5d1}\x{5d2}\x{5d3} xyz";
my ($selection_paragraph) = log2vis($selection_text);
my $selection = Text::Bidi::Selection->new(
    text => $selection_text, visual_to_logical => $selection_paragraph->map,
);
is_deeply $selection->logical_ranges(6, 10), [[4, 6], [8, 10]],
    'Selection accepts the public Paragraph map';
is $selection->selected_text(6, 10), "\x{5d0}\x{5d1} x",
    'Selection extracts logical text from a Paragraph visual interval';
$selection_paragraph->visual(4, 4);
is $selection->selected_text(6, 10), "\x{5d0}\x{5d1} x",
    'reordering a Paragraph again leaves the Selection snapshot intact';

done_testing;
