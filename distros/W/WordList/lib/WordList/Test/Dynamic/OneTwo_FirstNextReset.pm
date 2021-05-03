package WordList::Test::Dynamic::OneTwo_FirstNextReset;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-28'; # DATE
our $DIST = 'WordList'; # DIST
our $VERSION = '0.7.7'; # VERSION

use strict;

use WordList;
our @ISA = qw(WordList);

use Role::Tiny::With;
with 'WordListRole::EachFromFirstNextReset';

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

    $self->{_iterator_idx}++;
    if    ($self->{_iterator_idx} == 1) { return "one" }
    elsif ($self->{_iterator_idx} == 2) { return "two" }
    else { return undef }
}

our %STATS = ("shortest_word_len",3,"num_words",2,"num_words_contains_nonword_chars",0,"num_words_contain_nonword_chars",0,"num_words_contains_whitespace",0,"avg_word_len",3,"longest_word_len",3,"num_words_contain_unicode",0,"num_words_contains_unicode",0,"num_words_contain_whitespace",0); # STATS

1;
# ABSTRACT: Wordlist that returns one, two (via implementing first_word(), next_word(), and reset_iterator())

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::Test::Dynamic::OneTwo_FirstNextReset - Wordlist that returns one, two (via implementing first_word(), next_word(), and reset_iterator())

=head1 VERSION

This document describes version 0.7.7 of WordList::Test::Dynamic::OneTwo_FirstNextReset (from Perl distribution WordList), released on 2021-01-28.

=head1 SYNOPSIS

 use WordList::Test::Dynamic::OneTwo_FirstNextReset;

 my $wl = WordList::Test::Dynamic::OneTwo_FirstNextReset->new;

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-WordList/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
