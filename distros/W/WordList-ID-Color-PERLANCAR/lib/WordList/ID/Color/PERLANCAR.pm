package WordList::ID::Color::PERLANCAR;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-07'; # DATE
our $DIST = 'WordList-ID-Color-PERLANCAR'; # DIST
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contain_whitespace",4,"shortest_word_len",3,"num_words_contains_whitespace",4,"num_words_contains_nonword_chars",5,"num_words_contain_unicode",0,"num_words_contains_unicode",0,"num_words",28,"num_words_contain_nonword_chars",5,"longest_word_len",12,"avg_word_len",6.25); # STATS

1;
# ABSTRACT: List of color names in Indonesian

=pod

=encoding UTF-8

=head1 NAME

WordList::ID::Color::PERLANCAR - List of color names in Indonesian

=head1 VERSION

This document describes version 0.001 of WordList::ID::Color::PERLANCAR (from Perl distribution WordList-ID-Color-PERLANCAR), released on 2020-06-07.

=head1 SYNOPSIS

 use WordList::ID::Color::PERLANCAR;

 my $wl = WordList::ID::Color::PERLANCAR->new;

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

Some variations included, e.g. coklat & cokelat, abu & abu-abu, merah marun &
marun, orange & jingga.

Not all "WARNA muda/tua/gelap/terang" included, e.g. "kuning tua" or "ungu muda"
are not included. But "merah muda" is included.

=head1 STATISTICS

 +----------------------------------+-------+
 | key                              | value |
 +----------------------------------+-------+
 | avg_word_len                     | 6.25  |
 | longest_word_len                 | 12    |
 | num_words                        | 28    |
 | num_words_contain_nonword_chars  | 5     |
 | num_words_contain_unicode        | 0     |
 | num_words_contain_whitespace     | 4     |
 | num_words_contains_nonword_chars | 5     |
 | num_words_contains_unicode       | 0     |
 | num_words_contains_whitespace    | 4     |
 | shortest_word_len                | 3     |
 +----------------------------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 INTERNAL NOTES

krem - beige

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-ID-Color-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-ID-Color-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-ID-Color-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
abu
abu-abu
biru
biru dongker
cokelas
coklat
emas
gading
hijau
hitam
jingga
krem
lembayung
magenta
marun
merah
merah jambu
merah marun
merah muda
nila
oranye
perak
perunggu
putih
sian
ungu
violet
zaitun
