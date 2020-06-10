package WordList::ID::Color::HTML_ID;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-07'; # DATE
our $DIST = 'WordList-ID-Color-HTML_ID'; # DIST
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words",17,"num_words_contain_whitespace",0,"num_words_contains_unicode",0,"avg_word_len",5.23529411764706,"num_words_contain_nonword_chars",0,"num_words_contain_unicode",0,"num_words_contains_nonword_chars",0,"shortest_word_len",3,"longest_word_len",10,"num_words_contains_whitespace",0); # STATS

1;
# ABSTRACT: List of color names from Graphics::ColorNames::HTML_ID

=pod

=encoding UTF-8

=head1 NAME

WordList::ID::Color::HTML_ID - List of color names from Graphics::ColorNames::HTML_ID

=head1 VERSION

This document describes version 0.001 of WordList::ID::Color::HTML_ID (from Perl distribution WordList-ID-Color-HTML_ID), released on 2020-06-07.

=head1 SYNOPSIS

 use WordList::ID::Color::HTML_ID;

 my $wl = WordList::ID::Color::HTML_ID->new;

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

=head1 STATISTICS

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

Please visit the project's homepage at L<https://metacpan.org/release/WordList-ID-Color-HTML_ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-ID-Color-HTML_ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-ID-Color-HTML_ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Graphics::ColorNames::HTML_ID

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
