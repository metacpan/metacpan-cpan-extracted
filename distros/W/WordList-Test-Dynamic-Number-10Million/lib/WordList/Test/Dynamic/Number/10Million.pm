package WordList::Test::Dynamic::Number::10Million;

use strict;
use WordList;
our @ISA = qw(WordList);

use Role::Tiny::With;
with 'WordListRole::EachFromFirstNextReset';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-12-01'; # DATE
our $DIST = 'WordList-Test-Dynamic-Number-10Million'; # DIST
our $VERSION = '0.005'; # VERSION

our $DYNAMIC = 1;

sub reset_iterator {
    my $self = shift;
    $self->{_iterator_idx} = 0;
}

sub first_word {
    my $self = shift;
    $self->reset_iterator;
    $self->next_word;
}

sub next_word {
    my $self = shift;

    $self->{_iterator_idx} = 0 unless defined $self->{_iterator_idx};
    return undef if $self->{_iterator_idx}++ >= 10_000_000; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    sprintf "%08d", $self->{_iterator_idx};
}

our %STATS = ("num_words_contains_unicode",0,"num_words",10000000,"longest_word_len",8,"num_words_contains_nonword_chars",0,"num_words_contains_whitespace",0,"num_words_contain_whitespace",0,"shortest_word_len",8,"num_words_contain_unicode",0,"num_words_contain_nonword_chars",0,"avg_word_len",8); # STATS

1;
# ABSTRACT: 10 million numbers from "00000001" to "10000000"

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::Test::Dynamic::Number::10Million - 10 million numbers from "00000001" to "10000000"

=head1 VERSION

This document describes version 0.005 of WordList::Test::Dynamic::Number::10Million (from Perl distribution WordList-Test-Dynamic-Number-10Million), released on 2021-12-01.

=head1 SYNOPSIS

 use WordList::Test::Dynamic::Number::10Million;

 my $wl = WordList::Test::Dynamic::Number::10Million->new;

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

 +----------------------------------+----------+
 | key                              | value    |
 +----------------------------------+----------+
 | avg_word_len                     | 8        |
 | longest_word_len                 | 8        |
 | num_words                        | 10000000 |
 | num_words_contain_nonword_chars  | 0        |
 | num_words_contain_unicode        | 0        |
 | num_words_contain_whitespace     | 0        |
 | num_words_contains_nonword_chars | 0        |
 | num_words_contains_unicode       | 0        |
 | num_words_contains_whitespace    | 0        |
 | shortest_word_len                | 8        |
 +----------------------------------+----------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Test-Dynamic-Number-10Million>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Test-Dynamic-Number-10Million>.

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

This software is copyright (c) 2021, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Test-Dynamic-Number-10Million>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
