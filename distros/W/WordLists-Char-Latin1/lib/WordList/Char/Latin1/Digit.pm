package WordList::Char::Latin1::Digit;

our $DATE = '2018-03-22'; # DATE
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contains_nonword_chars",0,"avg_word_len",1,"num_words",10,"num_words_contains_whitespace",0,"longest_word_len",1,"shortest_word_len",1,"num_words_contains_unicode",0); # STATS

1;
# ABSTRACT: Latin1 digits

=pod

=encoding UTF-8

=head1 NAME

WordList::Char::Latin1::Digit - Latin1 digits

=head1 VERSION

This document describes version 0.001 of WordList::Char::Latin1::Digit (from Perl distribution WordLists-Char-Latin1), released on 2018-03-22.

=head1 SYNOPSIS

 use WordList::Char::Latin1::Digit;

 my $wl = WordList::Char::Latin1::Digit->new;

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

 +----------------------------------+-------+
 | key                              | value |
 +----------------------------------+-------+
 | avg_word_len                     | 1     |
 | longest_word_len                 | 1     |
 | num_words                        | 10    |
 | num_words_contains_nonword_chars | 0     |
 | num_words_contains_unicode       | 0     |
 | num_words_contains_whitespace    | 0     |
 | shortest_word_len                | 1     |
 +----------------------------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordLists-Char-Latin1>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordLists-Char-Latin1>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordLists-Char-Latin1>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
0
1
2
3
4
5
6
7
8
9
