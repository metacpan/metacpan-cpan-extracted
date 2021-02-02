package WordList::ID::ColorName::HTML_ID;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-12-27'; # DATE
our $DIST = 'WordList-ID-ColorName-HTML_ID'; # DIST
our $VERSION = '0.002'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("avg_word_len",5.23529411764706,"num_words_contains_nonword_chars",0,"num_words_contain_nonword_chars",0,"num_words_contain_whitespace",0,"longest_word_len",10,"num_words",17,"num_words_contains_unicode",0,"num_words_contains_whitespace",0,"num_words_contain_unicode",0,"shortest_word_len",3); # STATS

1;
# ABSTRACT: List of color names from Graphics::ColorNames::HTML_ID

=pod

=encoding UTF-8

=head1 NAME

WordList::ID::ColorName::HTML_ID - List of color names from Graphics::ColorNames::HTML_ID

=head1 VERSION

This document describes version 0.002 of WordList::ID::ColorName::HTML_ID (from Perl distribution WordList-ID-ColorName-HTML_ID), released on 2020-12-27.

=head1 SYNOPSIS

 use WordList::ID::ColorName::HTML_ID;

 my $wl = WordList::ID::ColorName::HTML_ID->new;

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

=head1 WORDLIST STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 5.23529411764706 |
 | longest_word_len                 | 10               |
 | num_words                        | 17               |
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

Please visit the project's homepage at L<https://metacpan.org/release/WordList-ID-ColorName-HTML_ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-ID-ColorName-HTML_ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-WordList-ID-ColorName-HTML_ID/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Graphics::ColorNames::HTML_ID>

Other WordList::ID::ColorName::*, e.g. L<,WordList::ID::ColorName::PERLANCAR>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
abu
akua
aqua
biru
birutua
fuchsia
hijau
hitam
kapur
kuning
merah
merahmarun
perak
putih
teal
ungu
zaitun
