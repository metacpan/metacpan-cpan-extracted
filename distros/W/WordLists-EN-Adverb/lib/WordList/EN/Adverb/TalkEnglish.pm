package WordList::EN::Adverb::TalkEnglish;

use strict;
use warnings;
use WordList;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-26'; # DATE
our $DIST = 'WordLists-EN-Adverb'; # DIST
our $VERSION = '0.003'; # VERSION

our @ISA = qw(WordList);

use Role::Tiny::With;
with 'WordListRole::FromArray';

sub _array {
    require TableData::Lingua::Word::EN::Adverb::TalkEnglish;

    my $t = TableData::Lingua::Word::EN::Adverb::TalkEnglish->new;
    my $ary = [];
    $t->each_row_arrayref(
        sub {
            my $row = shift;
            push @$ary, $row->[0];
            1;
        }
    );
    $ary;
}

our $DYNAMIC = 1;
our $SORT = 'custom';

our %STATS = ("num_words_contains_unicode",0,"num_words_contain_nonword_chars",0,"avg_word_len",7.7280701754386,"shortest_word_len",3,"num_words_contains_whitespace",0,"longest_word_len",13,"num_words_contain_whitespace",0,"num_words_contains_nonword_chars",0,"num_words",114,"num_words_contain_unicode",0); # STATS

1;
# ABSTRACT: Words that are used as adverbs only, from talkenglish.com

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::EN::Adverb::TalkEnglish - Words that are used as adverbs only, from talkenglish.com

=head1 VERSION

This document describes version 0.003 of WordList::EN::Adverb::TalkEnglish (from Perl distribution WordLists-EN-Adverb), released on 2021-09-26.

=head1 SYNOPSIS

 use WordList::EN::Adverb::TalkEnglish;

 my $wl = WordList::EN::Adverb::TalkEnglish->new;

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

Source: L<https://www.talkenglish.com/vocabulary/top-250-adverbs.aspx>

=head1 WORDLIST STATISTICS

 +----------------------------------+-----------------+
 | key                              | value           |
 +----------------------------------+-----------------+
 | avg_word_len                     | 7.7280701754386 |
 | longest_word_len                 | 13              |
 | num_words                        | 114             |
 | num_words_contain_nonword_chars  | 0               |
 | num_words_contain_unicode        | 0               |
 | num_words_contain_whitespace     | 0               |
 | num_words_contains_nonword_chars | 0               |
 | num_words_contains_unicode       | 0               |
 | num_words_contains_whitespace    | 0               |
 | shortest_word_len                | 3               |
 +----------------------------------+-----------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordLists-EN-Adverb>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordLists-EN-Adverb>.

=head1 SEE ALSO

L<WordList::EN::Noun::TalkEnglish>, L<WordList::EN::Adjective::TalkEnglish>.

Other C<WordList::EN::Adverb::*> modules.

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

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordLists-EN-Adverb>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
