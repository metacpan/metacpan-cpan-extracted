package WordList::EN::Color::CSS;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-07'; # DATE
our $DIST = 'WordList-EN-Color-CSS'; # DIST
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contains_nonword_chars",0,"avg_word_len",8.88513513513514,"num_words_contain_whitespace",0,"longest_word_len",20,"num_words",148,"num_words_contain_unicode",0,"num_words_contain_nonword_chars",0,"shortest_word_len",3,"num_words_contains_whitespace",0,"num_words_contains_unicode",0); # STATS

1;
# ABSTRACT: Color names from Graphics::ColorNames::CSS

=pod

=encoding UTF-8

=head1 NAME

WordList::EN::Color::CSS - Color names from Graphics::ColorNames::CSS

=head1 VERSION

This document describes version 0.001 of WordList::EN::Color::CSS (from Perl distribution WordList-EN-Color-CSS), released on 2020-06-07.

=head1 SYNOPSIS

 use WordList::EN::Color::CSS;

 my $wl = WordList::EN::Color::CSS->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Iterate
 my $first_word = $wl->first_word;
 while (defined(my $word = $wl->next_word)) { ... }

 # Get all the words
 my @all_words = $wl->all_words;

=head1 STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 8.88513513513514 |
 | longest_word_len                 | 20               |
 | num_words                        | 148              |
 | num_words_contain_nonword_chars  | 0                |
 | num_words_contain_unicode        | 0                |
 | num_words_contain_whitespace     | 0                |
 | num_words_contains_nonword_chars | 0                |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 0                |
 | shortest_word_len                | 3                |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-EN-Color-CSS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-EN-Color-CSS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-EN-Color-CSS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Graphics::ColorNames::CSS>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
aliceblue
antiquewhite
aqua
aquamarine
azure
beige
bisque
black
blanchedalmond
blue
blueviolet
brown
burlywood
cadetblue
chartreuse
chocolate
coral
cornflowerblue
cornsilk
crimson
cyan
darkblue
darkcyan
darkgoldenrod
darkgray
darkgreen
darkgrey
darkkhaki
darkmagenta
darkolivegreen
darkorange
darkorchid
darkred
darksalmon
darkseagreen
darkslateblue
darkslategray
darkslategrey
darkturquoise
darkviolet
deeppink
deepskyblue
dimgray
dimgrey
dodgerblue
firebrick
floralwhite
forestgreen
fuchsia
fuscia
gainsboro
ghostwhite
gold
goldenrod
gray
green
greenyellow
grey
honeydew
hotpink
indianred
indigo
ivory
khaki
lavender
lavenderblush
lawngreen
lemonchiffon
lightblue
lightcoral
lightcyan
lightgoldenrodyellow
lightgray
lightgreen
lightgrey
lightpink
lightsalmon
lightseagreen
lightskyblue
lightslategray
lightslategrey
lightsteelblue
lightyellow
lime
limegreen
linen
magenta
maroon
mediumaquamarine
mediumblue
mediumorchid
mediumpurple
mediumseagreen
mediumslateblue
mediumspringgreen
mediumturquoise
mediumvioletred
midnightblue
mintcream
mistyrose
moccasin
navajowhite
navy
oldlace
olive
olivedrab
orange
orangered
orchid
palegoldenrod
palegreen
paleturquoise
palevioletred
papayawhip
peachpuff
peru
pink
plum
powderblue
purple
red
rosybrown
royalblue
saddlebrown
salmon
sandybrown
seagreen
seashell
sienna
silver
skyblue
slateblue
slategray
slategrey
snow
springgreen
steelblue
tan
teal
thistle
tomato
turquoise
violet
wheat
white
whitesmoke
yellow
yellowgreen
