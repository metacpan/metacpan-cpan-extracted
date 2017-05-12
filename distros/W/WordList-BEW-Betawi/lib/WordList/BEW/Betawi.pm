package WordList::BEW::Betawi;

our $DATE = '2016-06-21'; # DATE
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("longest_word_len",9,"shortest_word_len",2,"num_words_contains_unicode",0,"num_words_contains_nonword_chars",0,"num_words_contains_whitespace",0,"num_words",82,"avg_word_len",5.04878048780488); # STATS

1;
# ABSTRACT: Betawi words from several sources

=pod

=encoding UTF-8

=head1 NAME

WordList::BEW::Betawi - Betawi words from several sources

=head1 VERSION

This document describes version 0.001 of WordList::BEW::Betawi (from Perl distribution WordList-BEW-Betawi), released on 2016-06-21.

=head1 SYNOPSIS

 use WordList::BEW::Betawi;

 my $wl = WordList::BEW::Betawi->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Get all the words
 my @all_words = $wl->all_words;

=head1 STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 5.04878048780488 |
 | longest_word_len                 | 9                |
 | num_words                        | 82               |
 | num_words_contains_nonword_chars | 0                |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 0                |
 | shortest_word_len                | 2                |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-BEW-Betawi>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-BEW-Betawi>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-BEW-Betawi>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Sources:

L<https://id.wikipedia.org/wiki/Bahasa_Betawi>

L<http://kamusmania.com/categories/Kamus-Bahasa-Betawi-12/>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
abang
abreg
ade
adul
agan
ajag
aje
ame
amprog
antep
ape
atu
aye
babe
bale
bawe
bego
beken
berabe
berape
belepotan
bontot
bupet
bujubune
butut
cawan
centeng
centong
danta
demplon
doang
dongo
elo
emang
empok
encang
encing
engkong
entong
enyak
ganjen
gaplok
gimane
gua
gue
gulem
ijig
iye
jibun
jubel
kagak
kayak
kempek
kepret
kite
langgar
lo
loe
lu
mendusin
napa
nenggak
ngacir
ngendon
norak
nyai
nyang
nyelonong
nyok
ogah
pangkeng
ponten
ribet
saban
sape
siape
songong
syahi
tampol
tauke
tisi
tong
