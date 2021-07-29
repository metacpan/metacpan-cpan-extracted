package WordList::EN::StopWords;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-23'; # DATE
our $DIST = 'WordList-EN-StopWords'; # DIST
our $VERSION = '0.001'; # VERSION

use WordList;
our @ISA = qw(WordList);

use Role::Tiny::With;
with 'WordListRole::FromArray';

our $DYNAMIC = 1;

sub _array {
    require Lingua::EN::StopWordList;
    [sort @{ Lingua::EN::StopWordList->new->words}];
}

our %STATS = ("shortest_word_len",1,"num_words_contains_unicode",0,"avg_word_len",5.40667678300455,"num_words_contains_nonword_chars",73,"num_words_contain_unicode",0,"num_words_contain_whitespace",0,"num_words_contain_nonword_chars",73,"num_words",659,"num_words_contains_whitespace",0,"longest_word_len",15); # STATS

1;
# ABSTRACT: English stop words

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::EN::StopWords - English stop words

=head1 VERSION

This document describes version 0.001 of WordList::EN::StopWords (from Perl distribution WordList-EN-StopWords), released on 2021-02-23.

=head1 SYNOPSIS

 use WordList::EN::StopWords;

 my $wl = WordList::EN::StopWords->new;

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

This wordlist contains English stopwords from L<Lingua::EN::StopWordList>. You
can also retrieve the list directly from that module.

=head1 WORDLIST STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 5.40667678300455 |
 | longest_word_len                 | 15               |
 | num_words                        | 659              |
 | num_words_contain_nonword_chars  | 73               |
 | num_words_contain_unicode        | 0                |
 | num_words_contain_whitespace     | 0                |
 | num_words_contains_nonword_chars | 73               |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 0                |
 | shortest_word_len                | 1                |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-EN-StopWords>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-EN-StopWords>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-WordList-EN-StopWords/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Lingua::EN::StopWordList>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
