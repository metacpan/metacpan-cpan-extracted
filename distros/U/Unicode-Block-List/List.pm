package Unicode::Block::List;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Unicode::Block;
use Unicode::UCD qw(charblock charblocks);

# Version.
our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	# Object.
	return $self;
}

# Get block.
sub block {
	my ($self, $block) = @_;
	my $charblock_ar = charblock($block);
	if (ref $charblock_ar ne 'ARRAY' || ! @{$charblock_ar}) {
		return;
	}
	my $char_from = sprintf '%04x', $charblock_ar->[0]->[0];
	my $char_to = sprintf '%04x', $charblock_ar->[0]->[1];
	return Unicode::Block->new(
		'title' => $charblock_ar->[0]->[2],
		'char_from' => $char_from,
		'char_to' => $char_to,
	);
}

# Get list of blocks.
sub list {
	my $self = shift;
	my $charblocks_hr = charblocks();
	return sort keys %{$charblocks_hr};
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Unicode::Block::List - List of unicode blocks.

=head1 SYNOPSIS

 use Unicode::Block::List;
 my $obj = Unicode::Block->new(%parameters);
 my $block = $obj->block($block);
 my @list = $obj->list; 

=head1 METHODS

=over 8

=item C<new(%parameters)>

Constructor.

=item C<block($block)>

 Get Unicode::Block object for defined Unicode block.
 Returns Unicode::Block object.

=item C<list()>

 Get list of blocks.
 Returns array of Unicode block names.

=back

=head1 ERRORS

 new():
         From Class::Utils::set_params_pub():
                 Unknown parameter '%s'.

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Encode qw(encode_utf8);
 use Unicode::Block::Ascii;
 use Unicode::Block::List;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 block_name\n";
         exit 1;
 }
 my $block_name = $ARGV[0];

 # Object.
 my $obj = Unicode::Block::List->new;

 # Get Unicode::Block for block name.
 my $block = $obj->block($block_name);
 if (! $block) {
         print "Block '$block_name' doesn't exist.\n";
         exit 1;
 }

 # Get ASCII object.
 my $block_ascii = Unicode::Block::Ascii->new(%{$block});

 # Print to output.
 print encode_utf8($block_ascii->get)."\n";

 # Output:
 # Usage: /tmp/o1NG0vm_Wf block_name

 # Output with 'Block Elements' argument:
 # ┌────────────────────────────────────────┐
 # │             Block Elements             │
 # ├────────┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┤
 # │        │0│1│2│3│4│5│6│7│8│9│A│B│C│D│E│F│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+258x │▀│▁│▂│▃│▄│▅│▆│▇│█│▉│▊│▋│▌│▍│▎│▏│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+259x │▐│░│▒│▓│▔│▕│▖│▗│▘│▙│▚│▛│▜│▝│▞│▟│
 # └────────┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘

 # Output with 'foo' argument:
 # Block 'foo' doesn't exist.

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Data::Printer;
 use Unicode::Block::List;

 # Object.
 my $obj = Unicode::Block::List->new;

 # Get list.
 my @list = $obj->list;

 # Print out.
 p @list;

 # Output.
 # [
 #     [0]   "Aegean Numbers",
 #     [1]   "Alchemical Symbols",
 #     [2]   "Alphabetic Presentation Forms",
 #     [3]   "Ancient Greek Musical Notation",
 #     [4]   "Ancient Greek Numbers",
 #     [5]   "Ancient Symbols",
 #     [6]   "Arabic",
 #     [7]   "Arabic Presentation Forms-A",
 #     [8]   "Arabic Presentation Forms-B",
 #     [9]   "Arabic Supplement",
 #     [10]  "Armenian",
 #     [11]  "Arrows",
 #     [12]  "Avestan",
 #     [13]  "Balinese",
 #     [14]  "Bamum",
 #     [15]  "Bamum Supplement",
 #     [16]  "Basic Latin",
 #     [17]  "Batak",
 #     [18]  "Bengali",
 #     [19]  "Block Elements",
 #     [20]  "Bopomofo",
 #     [21]  "Bopomofo Extended",
 #     [22]  "Box Drawing",
 #     [23]  "Brahmi",
 #     [24]  "Braille Patterns",
 #     [25]  "Buginese",
 #     [26]  "Buhid",
 #     [27]  "Byzantine Musical Symbols",
 #     [28]  "CJK Compatibility",
 #     [29]  "CJK Compatibility Forms",
 #     [30]  "CJK Compatibility Ideographs",
 #     [31]  "CJK Compatibility Ideographs Supplement",
 #     [32]  "CJK Radicals Supplement",
 #     [33]  "CJK Strokes",
 #     [34]  "CJK Symbols and Punctuation",
 #     [35]  "CJK Unified Ideographs",
 #     [36]  "CJK Unified Ideographs Extension A",
 #     [37]  "CJK Unified Ideographs Extension B",
 #     [38]  "CJK Unified Ideographs Extension C",
 #     [39]  "CJK Unified Ideographs Extension D",
 #     [40]  "Carian",
 #     [41]  "Cham",
 #     [42]  "Cherokee",
 #     [43]  "Combining Diacritical Marks",
 #     [44]  "Combining Diacritical Marks Supplement",
 #     [45]  "Combining Diacritical Marks for Symbols",
 #     [46]  "Combining Half Marks",
 #     [47]  "Common Indic Number Forms",
 #     [48]  "Control Pictures",
 #     [49]  "Coptic",
 #     [50]  "Counting Rod Numerals",
 #     [51]  "Cuneiform",
 #     [52]  "Cuneiform Numbers and Punctuation",
 #     [53]  "Currency Symbols",
 #     [54]  "Cypriot Syllabary",
 #     [55]  "Cyrillic",
 #     [56]  "Cyrillic Extended-A",
 #     [57]  "Cyrillic Extended-B",
 #     [58]  "Cyrillic Supplement",
 #     [59]  "Deseret",
 #     [60]  "Devanagari",
 #     [61]  "Devanagari Extended",
 #     [62]  "Dingbats",
 #     [63]  "Domino Tiles",
 #     [64]  "Egyptian Hieroglyphs",
 #     [65]  "Emoticons",
 #     [66]  "Enclosed Alphanumeric Supplement",
 #     [67]  "Enclosed Alphanumerics",
 #     [68]  "Enclosed CJK Letters and Months",
 #     [69]  "Enclosed Ideographic Supplement",
 #     [70]  "Ethiopic",
 #     [71]  "Ethiopic Extended",
 #     [72]  "Ethiopic Extended-A",
 #     [73]  "Ethiopic Supplement",
 #     [74]  "General Punctuation",
 #     [75]  "Geometric Shapes",
 #     [76]  "Georgian",
 #     [77]  "Georgian Supplement",
 #     [78]  "Glagolitic",
 #     [79]  "Gothic",
 #     [80]  "Greek Extended",
 #     [81]  "Greek and Coptic",
 #     [82]  "Gujarati",
 #     [83]  "Gurmukhi",
 #     [84]  "Halfwidth and Fullwidth Forms",
 #     [85]  "Hangul Compatibility Jamo",
 #     [86]  "Hangul Jamo",
 #     [87]  "Hangul Jamo Extended-A",
 #     [88]  "Hangul Jamo Extended-B",
 #     [89]  "Hangul Syllables",
 #     [90]  "Hanunoo",
 #     [91]  "Hebrew",
 #     [92]  "High Private Use Surrogates",
 #     [93]  "High Surrogates",
 #     [94]  "Hiragana",
 #     [95]  "IPA Extensions",
 #     [96]  "Ideographic Description Characters",
 #     [97]  "Imperial Aramaic",
 #     [98]  "Inscriptional Pahlavi",
 #     [99]  "Inscriptional Parthian",
 #     [100] "Javanese",
 #     [101] "Kaithi",
 #     [102] "Kana Supplement",
 #     [103] "Kanbun",
 #     [104] "Kangxi Radicals",
 #     [105] "Kannada",
 #     [106] "Katakana",
 #     [107] "Katakana Phonetic Extensions",
 #     [108] "Kayah Li",
 #     [109] "Kharoshthi",
 #     [110] "Khmer",
 #     [111] "Khmer Symbols",
 #     [112] "Lao",
 #     [113] "Latin Extended Additional",
 #     [114] "Latin Extended-A",
 #     [115] "Latin Extended-B",
 #     [116] "Latin Extended-C",
 #     [117] "Latin Extended-D",
 #     [118] "Latin-1 Supplement",
 #     [119] "Lepcha",
 #     [120] "Letterlike Symbols",
 #     [121] "Limbu",
 #     [122] "Linear B Ideograms",
 #     [123] "Linear B Syllabary",
 #     [124] "Lisu",
 #     [125] "Low Surrogates",
 #     [126] "Lycian",
 #     [127] "Lydian",
 #     [128] "Mahjong Tiles",
 #     [129] "Malayalam",
 #     [130] "Mandaic",
 #     [131] "Mathematical Alphanumeric Symbols",
 #     [132] "Mathematical Operators",
 #     [133] "Meetei Mayek",
 #     [134] "Miscellaneous Mathematical Symbols-A",
 #     [135] "Miscellaneous Mathematical Symbols-B",
 #     [136] "Miscellaneous Symbols",
 #     [137] "Miscellaneous Symbols And Pictographs",
 #     [138] "Miscellaneous Symbols and Arrows",
 #     [139] "Miscellaneous Technical",
 #     [140] "Modifier Tone Letters",
 #     [141] "Mongolian",
 #     [142] "Musical Symbols",
 #     [143] "Myanmar",
 #     [144] "Myanmar Extended-A",
 #     [145] "NKo",
 #     [146] "New Tai Lue",
 #     [147] "Number Forms",
 #     [148] "Ogham",
 #     [149] "Ol Chiki",
 #     [150] "Old Italic",
 #     [151] "Old Persian",
 #     [152] "Old South Arabian",
 #     [153] "Old Turkic",
 #     [154] "Optical Character Recognition",
 #     [155] "Oriya",
 #     [156] "Osmanya",
 #     [157] "Phags-pa",
 #     [158] "Phaistos Disc",
 #     [159] "Phoenician",
 #     [160] "Phonetic Extensions",
 #     [161] "Phonetic Extensions Supplement",
 #     [162] "Playing Cards",
 #     [163] "Private Use Area",
 #     [164] "Rejang",
 #     [165] "Rumi Numeral Symbols",
 #     [166] "Runic",
 #     [167] "Samaritan",
 #     [168] "Saurashtra",
 #     [169] "Shavian",
 #     [170] "Sinhala",
 #     [171] "Small Form Variants",
 #     [172] "Spacing Modifier Letters",
 #     [173] "Specials",
 #     [174] "Sundanese",
 #     [175] "Superscripts and Subscripts",
 #     [176] "Supplemental Arrows-A",
 #     [177] "Supplemental Arrows-B",
 #     [178] "Supplemental Mathematical Operators",
 #     [179] "Supplemental Punctuation",
 #     [180] "Supplementary Private Use Area-A",
 #     [181] "Supplementary Private Use Area-B",
 #     [182] "Syloti Nagri",
 #     [183] "Syriac",
 #     [184] "Tagalog",
 #     [185] "Tagbanwa",
 #     [186] "Tags",
 #     [187] "Tai Le",
 #     [188] "Tai Tham",
 #     [189] "Tai Viet",
 #     [190] "Tai Xuan Jing Symbols",
 #     [191] "Tamil",
 #     [192] "Telugu",
 #     [193] "Thaana",
 #     [194] "Thai",
 #     [195] "Tibetan",
 #     [196] "Tifinagh",
 #     [197] "Transport And Map Symbols",
 #     [198] "Ugaritic",
 #     [199] "Unified Canadian Aboriginal Syllabics",
 #     [200] "Unified Canadian Aboriginal Syllabics Extended",
 #     [201] "Vai",
 #     [202] "Variation Selectors",
 #     [203] "Variation Selectors Supplement",
 #     [204] "Vedic Extensions",
 #     [205] "Vertical Forms",
 #     [206] "Yi Radicals",
 #     [207] "Yi Syllables",
 #     [208] "Yijing Hexagram Symbols"
 # ]

=head1 DEPENDENCIES

L<Class::Utils>,
L<Unicode::Block>,
L<Unicode::UCD>.

=head1 REPOSITORY

L<https://github.com/tupinek/Unicode-Block-List>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

BSD license.

=head1 VERSION

0.02

=cut
