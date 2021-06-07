package WordList::ID::FruitName::PERLANCAR;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-02'; # DATE
our $DIST = 'WordList-ID-FruitName-PERLANCAR'; # DIST
our $VERSION = '0.002'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("longest_word_len",15,"num_words_contains_unicode",0,"num_words_contains_whitespace",14,"num_words_contains_nonword_chars",14,"num_words_contain_unicode",0,"num_words",137,"num_words_contain_nonword_chars",14,"num_words_contain_whitespace",14,"shortest_word_len",3,"avg_word_len",6.46715328467153); # STATS

1;
# ABSTRACT: List of fruit names in Indonesian

=pod

=encoding UTF-8

=head1 NAME

WordList::ID::FruitName::PERLANCAR - List of fruit names in Indonesian

=head1 VERSION

This document describes version 0.002 of WordList::ID::FruitName::PERLANCAR (from Perl distribution WordList-ID-FruitName-PERLANCAR), released on 2021-02-02.

=head1 SYNOPSIS

 use WordList::ID::FruitName::PERLANCAR;

 my $wl = WordList::ID::FruitName::PERLANCAR->new;

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

=head1 DESCRIPTION

Suitable for playing hangman.

Some spelling variations included (e.g. C<ceremai> and C<cermai>, C<nenas> and
C<nanas>, C<mentimun> and C<timun>). Multiple popular names for the same fruit
included (e.g. C<jeruk bali> and C<pomelo>, C<frambozen> and C<raspberry>).

=head1 WORDLIST STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 6.46715328467153 |
 | longest_word_len                 | 15               |
 | num_words                        | 137              |
 | num_words_contain_nonword_chars  | 14               |
 | num_words_contain_unicode        | 0                |
 | num_words_contain_whitespace     | 14               |
 | num_words_contains_nonword_chars | 14               |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 14               |
 | shortest_word_len                | 3                |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-ID-FruitName-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-ID-FruitName-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-WordList-ID-FruitName-PERLANCAR/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<hangman> from L<Games::Hangman>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
almond
alpukat
anggur
apel
aprikot
ara
arbei
aren
asam
atap
bacang
badam
belimbing
belimbing sayur
benda
bengkuang
beri
binjai
bisbul
bit
blackberry
blackcurrant
blewah
bluberi
buni
cempaka
cempedak
ceremai
ceri
cermai
coklat
cranberry
delima
duku
duren
durian
duwet
enau
erbis
fragaria
frambozen
gandaria
gowok
guava
jagung
jamblang
jambu
jambu air
jambu batu
jambu biji
jambu bol
jambu mete
jambu monyet
jeruk
jeruk bali
jeruk limau
jeruk mandarin
jeruk nipis
jujuba
jujube
kakao
kapulasan
kawista
kecapi
kedondong
kelapa
kelapa kopyor
kelengkeng
kemang
kemiri
kenari
kepa
kepel
kersen
kesemek
kiwi
kopyor
kumkuat
kupa
kurma
kweni
leci
lemon
lengkeng
limau
maja
malaka
mandarin
mangga
manggis
markisa
matoa
melon
mengkudu
mentawa
menteng
mentimun
mentimun suri
murbai
naga
namnam
nanas
nangka
nenas
nona
pepaya
persik
pinang
pir
pisang
plum
pomelo
prem
rambai
rambusa
rambutan
raspberry
rukam
salak
sawit
sawo
semangka
simpur
sirsak
srikaya
stroberi
sukun
terong
timun
timun suri
tin
tomat
ubi
vanili
waluh
widuri
zaitun
