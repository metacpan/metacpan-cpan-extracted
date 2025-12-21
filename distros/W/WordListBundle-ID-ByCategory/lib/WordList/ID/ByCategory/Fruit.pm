package WordList::ID::ByCategory::Fruit;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-01-14'; # DATE
our $DIST = 'WordListBundle-ID-ByCategory'; # DIST
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words",76,"num_words_contains_whitespace",4,"num_words_contain_whitespace",4,"avg_word_len",6.01315789473684,"num_words_contain_nonword_chars",4,"longest_word_len",14,"num_words_contains_nonword_chars",4,"num_words_contain_unicode",0,"shortest_word_len",3,"num_words_contains_unicode",0); # STATS

1;
# ABSTRACT: List of fruits in Indonesian

=pod

=encoding UTF-8

=head1 NAME

WordList::ID::ByCategory::Fruit - List of fruits in Indonesian

=head1 VERSION

This document describes version 0.001 of WordList::ID::ByCategory::Fruit (from Perl distribution WordListBundle-ID-ByCategory), released on 2025-01-14.

=head1 SYNOPSIS

 use WordList::ID::ByCategory::Fruit;

 my $wl = WordList::ID::ByCategory::Fruit->new;

 # Pick a (or several) random word(s) from the list
 my ($word) = $wl->pick;
 my ($word) = $wl->pick(1);  # ditto
 my @words  = $wl->pick(3);  # no duplicates

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }  # case-sensitive

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Iterate
 my $first_word = $wl->first_word;
 while (defined(my $word = $wl->next_word)) { ... }

 # Get all the words (beware, some wordlists are *huge*)
 my @all_words = $wl->all_words;

=head1 DESCRIPTION

=head1 WORDLIST STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 6.01315789473684 |
 | longest_word_len                 | 14               |
 | num_words                        | 76               |
 | num_words_contain_nonword_chars  | 4                |
 | num_words_contain_unicode        | 0                |
 | num_words_contain_whitespace     | 4                |
 | num_words_contains_nonword_chars | 4                |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 4                |
 | shortest_word_len                | 3                |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordListBundle-ID-ByCategory>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordListBundle-ID-ByCategory>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordListBundle-ID-ByCategory>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
alpukat
anggur
apel
aprikot
ara
arbei
asam
belimbing
beri
blewah
bluberi
cempedak
ceremai
ceri
delima
duku
durian
duwet
frambosa
gandaria
guava
jamblang
jambu
jambu air
jambu batu
jambu biji
jeruk
kecapi
kedondong
kelapa
kelor
kesemek
kiwi
kurma
labu
leci
lemon
lengkeng
limau
longan
maja
mangga
manggala
manggis
markisa
matoa
melinjo
melon
mengkudu
naga
nanas
nangka
nektarin
noni
okra
pala
palem
pepaya
pir
pisang
plum
prem
rambutan
salak
sawo
semangka
sirsak
srikaya
stroberi
sukun
terong belanda
tomat
vanila
ximenia
yuzu
zaitun
