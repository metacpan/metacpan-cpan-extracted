package WordList::EN::Medical::Glutanimate;

use strict;
use parent 'WordList';

use Role::Tiny::With;
with 'WordListRole::Source::ArrayData';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-27'; # DATE
our $DIST = 'WordList-EN-Medical-Glutanimate'; # DIST
our $VERSION = '20220727.0.0'; # VERSION

our %STATS = ("num_words_contain_unicode",377,"num_words_contain_whitespace",5,"num_words_contains_unicode",377,"longest_word_len",61,"num_words_contain_nonword_chars",4351,"num_words_contains_nonword_chars",4351,"shortest_word_len",3,"num_words",98119,"avg_word_len",9.97994272261234,"num_words_contains_whitespace",5); # STATS

our $SORT = 'custom';

sub _arraydata {
    require ArrayData::Lingua::Word::EN::Medical::Glutanimate;
    ArrayData::Lingua::Word::EN::Medical::Glutanimate->new;
}

1;
# ABSTRACT: Medical word list (English)

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::EN::Medical::Glutanimate - Medical word list (English)

=head1 VERSION

This document describes version 20220727.0.0 of WordList::EN::Medical::Glutanimate (from Perl distribution WordList-EN-Medical-Glutanimate), released on 2022-07-27.

=head1 SYNOPSIS

 use WordList::EN::Medical::Glutanimate;

 my $wl = WordList::EN::Medical::Glutanimate->new;

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

=head1 WORDLIST STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 9.97994272261234 |
 | longest_word_len                 | 61               |
 | num_words                        | 98119            |
 | num_words_contain_nonword_chars  | 4351             |
 | num_words_contain_unicode        | 377              |
 | num_words_contain_whitespace     | 5                |
 | num_words_contains_nonword_chars | 4351             |
 | num_words_contains_unicode       | 377              |
 | num_words_contains_whitespace    | 5                |
 | shortest_word_len                | 3                |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-EN-Medical-Glutanimate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-EN-Medical-Glutanimate>.

=head1 SEE ALSO

This wordlist gets its source of words from
L<ArrayData::Lingua::Word::EN::Medical::Glutanimate>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-EN-Medical-Glutanimate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
