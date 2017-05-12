package WordList::Test::Empty;

our $DATE = '2016-01-17'; # DATE
our $VERSION = '0.01'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words",0,"num_words_contains_whitespace",0,"longest_word_len",undef,"num_words_contains_nonword_chars",0,"shortest_word_len",undef,"num_words_contains_unicode",0); # STATS

1;
# ABSTRACT: An empty list

=pod

=encoding UTF-8

=head1 NAME

WordList::Test::Empty - An empty list

=head1 VERSION

This document describes version 0.01 of WordList::Test::Empty (from Perl distribution WordList-Test-Empty), released on 2016-01-17.

=head1 SYNOPSIS

 use WordList::Test::Empty;

 my $wl = WordList::Test::Empty->new;

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
 | longest_word_len                 |       |
 | num_words                        | 0     |
 | num_words_contains_nonword_chars | 0     |
 | num_words_contains_unicode       | 0     |
 | num_words_contains_whitespace    | 0     |
 | shortest_word_len                |       |
 +----------------------------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Test-Empty>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Test-Empty>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Test-Empty>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__