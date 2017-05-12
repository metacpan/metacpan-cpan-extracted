package WordList::Test::Unicode::Currency;

our $DATE = '2016-01-13'; # DATE
our $VERSION = '0.03'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("shortest_word_len",5,"num_words",5,"longest_word_len",6,"num_words_contains_nonword_chars",5,"num_words_contains_unicode",3,"avg_word_len",5.2,"num_words_contains_whitespace",5); # STATS

1;
# ABSTRACT: Currency symbols



=pod

=encoding UTF-8

=head1 NAME

WordList::Test::Unicode::Currency - Currency symbols

=head1 VERSION

This document describes version 0.03 of WordList::Test::Unicode::Currency (from Perl distribution WordList-Test-Unicode-Currency), released on 2016-01-13.

=head1 SYNOPSIS

 use WordList::Test::Unicode::Currency;

 my $wl = WordList::Test::Unicode::Currency->new;

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
 | avg_word_len                     | 5.2   |
 | longest_word_len                 | 6     |
 | num_words                        | 5     |
 | num_words_contains_nonword_chars | 5     |
 | num_words_contains_unicode       | 3     |
 | num_words_contains_whitespace    | 5     |
 | shortest_word_len                | 5     |
 +----------------------------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Test-Unicode-Currency>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Test-Unicode-Currency>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Test-Unicode-Currency>

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
IDR Rp
USD $
GBP £
EUR €
JPY ¥
