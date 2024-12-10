package WordList::HTTP::UserAgentString::PERLANCAR;

use strict;

use WordList;
our @ISA = qw(WordList);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-10'; # DATE
our $DIST = 'WordList-HTTP-UserAgentString-PERLANCAR'; # DIST
our $VERSION = '0.004'; # VERSION

our %STATS = ("num_words_contains_whitespace",4,"num_words_contain_whitespace",4,"num_words_contains_nonword_chars",4,"num_words",4,"shortest_word_len",70,"num_words_contain_nonword_chars",4,"longest_word_len",111,"num_words_contain_unicode",0,"num_words_contains_unicode",0,"avg_word_len",90.25); # STATS

1;
# ABSTRACT: A selection of some HTTP User-Agent strings

=pod

=encoding UTF-8

=head1 NAME

WordList::HTTP::UserAgentString::PERLANCAR - A selection of some HTTP User-Agent strings

=head1 VERSION

This document describes version 0.004 of WordList::HTTP::UserAgentString::PERLANCAR (from Perl distribution WordList-HTTP-UserAgentString-PERLANCAR), released on 2024-12-10.

=head1 SYNOPSIS

 use WordList::HTTP::UserAgentString::PERLANCAR;

 my $wl = WordList::HTTP::UserAgentString::PERLANCAR->new;

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

My selection: recent Firefox (Linux & Windows), recent Chrome (Linux & Windows).

NOTE: My Windows version is still at 7

=head1 WORDLIST STATISTICS

 +----------------------------------+-------+
 | key                              | value |
 +----------------------------------+-------+
 | avg_word_len                     | 90.25 |
 | longest_word_len                 | 111   |
 | num_words                        | 4     |
 | num_words_contain_nonword_chars  | 4     |
 | num_words_contain_unicode        | 0     |
 | num_words_contain_whitespace     | 4     |
 | num_words_contains_nonword_chars | 4     |
 | num_words_contains_unicode       | 0     |
 | num_words_contains_whitespace    | 4     |
 | shortest_word_len                | 70    |
 +----------------------------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-HTTP-UserAgentString-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-HTTP-UserAgentString-PERLANCAR>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-HTTP-UserAgentString-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36
Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0
Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36
Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0
