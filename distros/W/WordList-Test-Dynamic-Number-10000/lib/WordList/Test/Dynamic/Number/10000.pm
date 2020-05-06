package WordList::Test::Dynamic::Number::10000;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-04'; # DATE
our $DIST = 'WordList-Test-Dynamic-Number-10000'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;

use WordList;
our @ISA = qw(WordList);

use Role::Tiny::With;
with 'WordListRole::FirstNextResetFromEach';

our $DYNAMIC = 1;

sub each_word {
    my ($self, $code) = @_;

    for my $i (1..10_000) {
        my $word = sprintf "%05d", $i;
        my $res = $code->($word);
        last if defined $res && $res == -2;
    }
}

our %STATS = ("longest_word_len",5,"avg_word_len",5,"num_words_contain_nonword_chars",0,"num_words",10000,"num_words_contain_whitespace",0,"num_words_contain_unicode",0,"num_words_contains_unicode",0,"shortest_word_len",5,"num_words_contains_nonword_chars",0,"num_words_contains_whitespace",0); # STATS

1;
# ABSTRACT: 10 million numbers from "00001" to "10000"

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::Test::Dynamic::Number::10000 - 10 million numbers from "00001" to "10000"

=head1 VERSION

This document describes version 0.003 of WordList::Test::Dynamic::Number::10000 (from Perl distribution WordList-Test-Dynamic-Number-10000), released on 2020-05-04.

=head1 SYNOPSIS

 use WordList::Test::Dynamic::Number::10000;

 my $wl = WordList::Test::Dynamic::Number::10000->new;

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
 | avg_word_len                     | 5     |
 | longest_word_len                 | 5     |
 | num_words                        | 10000 |
 | num_words_contain_nonword_chars  | 0     |
 | num_words_contain_unicode        | 0     |
 | num_words_contain_whitespace     | 0     |
 | num_words_contains_nonword_chars | 0     |
 | num_words_contains_unicode       | 0     |
 | num_words_contains_whitespace    | 0     |
 | shortest_word_len                | 5     |
 +----------------------------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Test-Dynamic-Number-10000>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Test-Dynamic-Number-10000>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Test-Dynamic-Number-10000>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
