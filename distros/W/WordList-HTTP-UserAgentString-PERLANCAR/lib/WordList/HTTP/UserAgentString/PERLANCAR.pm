package WordList::HTTP::UserAgentString::PERLANCAR;

our $DATE = '2019-06-17'; # DATE
our $VERSION = '0.003'; # VERSION

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contains_unicode",0,"avg_word_len",95.6666666666667,"num_words",6,"longest_word_len",113,"shortest_word_len",68,"num_words_contains_whitespace",6,"num_words_contains_nonword_chars",6); # STATS

1;
# ABSTRACT: A selection of some HTTP User-Agent strings

=pod

=encoding UTF-8

=head1 NAME

WordList::HTTP::UserAgentString::PERLANCAR - A selection of some HTTP User-Agent strings

=head1 VERSION

This document describes version 0.003 of WordList::HTTP::UserAgentString::PERLANCAR (from Perl distribution WordList-HTTP-UserAgentString-PERLANCAR), released on 2019-06-17.

=head1 SYNOPSIS

 use WordList::HTTP::UserAgentString::PERLANCAR;

 my $wl = WordList::HTTP::UserAgentString::PERLANCAR->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Get all the words
 my @all_words = $wl->all_words;

=head1 DESCRIPTION

My selection: recent Firefox (Linux & Windows), recent Chrome (Linux & Windows).

=head1 STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 95.6666666666667 |
 | longest_word_len                 | 113              |
 | num_words                        | 6                |
 | num_words_contains_nonword_chars | 6                |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 6                |
 | shortest_word_len                | 68               |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-HTTP-UserAgentString-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-HTTP-UserAgentString-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-HTTP-UserAgentString-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
Mozilla/5.0 (Windows NT 6.1; WOW64; rv:67.0) Gecko/20100101 Firefox/67.0
Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36
Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.90 Safari/537.36
Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36
Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.90 Safari/537.36
Mozilla/5.0 (X11; Linux x86_64; rv:67.0) Gecko/20100101 Firefox/67.0
