package WordList::EN::Noun::TalkEnglish;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-03-05'; # DATE
our $DIST = 'WordLists-EN-Noun'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;
use WordList;
our @ISA = qw(WordList);

use Role::Tiny::With;
with 'WordListRole::FromArray';

sub _array {
    require Tables::Words::EN::Nouns::TalkEnglish;

    my $t = Tables::Words::EN::Nouns::TalkEnglish->new;
    my $ary = [];
    while (my $row = $t->get_row_arrayref) { push @$ary, $row->[0] }
    $ary;
}

our $DYNAMIC = 1;
our $SORT = 'custom';

our %STATS = ("shortest_word_len",2,"num_words_contains_whitespace",0,"num_words_contains_nonword_chars",0,"num_words",484,"num_words_contain_whitespace",0,"num_words_contain_nonword_chars",0,"num_words_contain_unicode",0,"avg_word_len",7.37809917355372,"num_words_contains_unicode",0,"longest_word_len",14); # STATS

1;
# ABSTRACT: Words that are used as nouns only, from talkenglish.com

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::EN::Noun::TalkEnglish - Words that are used as nouns only, from talkenglish.com

=head1 VERSION

This document describes version 0.003 of WordList::EN::Noun::TalkEnglish (from Perl distribution WordLists-EN-Noun), released on 2021-03-05.

=head1 SYNOPSIS

 use WordList::EN::Noun::TalkEnglish;

 my $wl = WordList::EN::Noun::TalkEnglish->new;

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

Source: L<https://www.talkenglish.com/vocabulary/top-1500-nouns.aspx>

=head1 WORDLIST STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 7.37809917355372 |
 | longest_word_len                 | 14               |
 | num_words                        | 484              |
 | num_words_contain_nonword_chars  | 0                |
 | num_words_contain_unicode        | 0                |
 | num_words_contain_whitespace     | 0                |
 | num_words_contains_nonword_chars | 0                |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 0                |
 | shortest_word_len                | 2                |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordLists-EN-Noun>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordLists-EN-Noun>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-WordLists-EN-Noun/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordList::EN::Adjective::TalkEnglish>, L<WordList::EN::Adverb::TalkEnglish>.

Other C<WordList::EN::Noun::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
