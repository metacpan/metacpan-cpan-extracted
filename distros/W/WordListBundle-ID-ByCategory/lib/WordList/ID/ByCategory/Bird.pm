package WordList::ID::ByCategory::Bird;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-01-14'; # DATE
our $DIST = 'WordListBundle-ID-ByCategory'; # DIST
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("shortest_word_len",3,"num_words_contains_unicode",0,"longest_word_len",12,"num_words_contain_nonword_chars",4,"num_words_contain_unicode",0,"num_words_contains_nonword_chars",4,"num_words_contains_whitespace",1,"num_words_contain_whitespace",1,"num_words",87,"avg_word_len",6.24137931034483); # STATS

1;
# ABSTRACT: List of birds in Indonesian

=pod

=encoding UTF-8

=head1 NAME

WordList::ID::ByCategory::Bird - List of birds in Indonesian

=head1 VERSION

This document describes version 0.001 of WordList::ID::ByCategory::Bird (from Perl distribution WordListBundle-ID-ByCategory), released on 2025-01-14.

=head1 SYNOPSIS

 use WordList::ID::ByCategory::Bird;

 my $wl = WordList::ID::ByCategory::Bird->new;

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
 | avg_word_len                     | 6.24137931034483 |
 | longest_word_len                 | 12               |
 | num_words                        | 87               |
 | num_words_contain_nonword_chars  | 4                |
 | num_words_contain_unicode        | 0                |
 | num_words_contain_whitespace     | 1                |
 | num_words_contains_nonword_chars | 4                |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 1                |
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
alap-alap
albatros
angsa
anis
ardea
ayam
bangau
bebek
belibis
beo
betet
blekok
bulbul
burung hantu
celepuk
cendrawasih
cucakrawa
dadali
dara
dodo
elang
enggang
entog
falkon
flamingo
fregat
fulmar
gagak
gajahan
garuda
gelatik
hantu
hering
ibis
itik
jalak
kakaktua
kalkun
kasturi
kasuari
kenari
kepodang
kiwi
kolibri
kondor
kuau
kukabura
kuntul
kutilang
luntur
maleo
manyar
merak
merpati
murai
nuri
onta
osprey
otus
parkit
pelikan
penguin
perkutut
pipit
poksai
pramuka
punai
punggok
pungguk
puyuh
quetzal
rajawali
rama-rama
rangkong
sambar
sempur
serindit
srigunting
tekukur
tukan
tukik
undan
upih-upih
wader
walet
xenoglaux
xenops
