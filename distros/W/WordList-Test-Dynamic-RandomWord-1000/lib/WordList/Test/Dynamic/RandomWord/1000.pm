package WordList::Test::Dynamic::RandomWord::1000;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-23'; # DATE
our $DIST = 'WordList-Test-Dynamic-RandomWord-1000'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;

use WordList;
our @ISA = qw(WordList);

use Role::Tiny::With;
with 'WordListRole::EachFromFirstNextReset';

our $DYNAMIC = 2;
our $SORT = 'random';

our %PARAMS = (
    min_len => {
        schema => 'uint*',
        default => 5,
    },
    max_len => {
        schema => 'uint*',
        default => 8,
    },
);

our @EXAMPLES = (
    {
        summary => '1000 random words, each 5-8 characters long (the default length range)',
        args => {},
    },
    {
        summary => '1000 random words, each 10-15 characters long',
        args => {min_len=>10, max_len=>15},
    },
);

sub reset_iterator {
    my $self = shift;
    $self->{_iterator_idx} = 0;
}

sub first_word {
    my $self = shift;
    $self->reset_iterator;
    $self->next_word;
}

my @letters = "a".."z";
sub next_word {
    my $self = shift;
    my $min_len = $self->{params}{min_len} // 5;
    my $max_len = $self->{params}{max_len} // 8;
    return undef if $self->{_iterator_idx}++ >= 1000;
    join("", map { $letters[rand @letters] }
             1..int(($max_len-$min_len+1)*rand)+$min_len);
}

# STATS

1;
# ABSTRACT: 1000 random words

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::Test::Dynamic::RandomWord::1000 - 1000 random words

=head1 VERSION

This document describes version 0.003 of WordList::Test::Dynamic::RandomWord::1000 (from Perl distribution WordList-Test-Dynamic-RandomWord-1000), released on 2020-08-23.

=head1 SYNOPSIS

 use WordList::Test::Dynamic::RandomWord::1000;

 my $wl = WordList::Test::Dynamic::RandomWord::1000->new;

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

This wordlist demoes a dynamic, non-deterministic wordlist.

=head1 WORDLIST PARAMETERS


This is a parameterized wordlist module. When loading in Perl, you can specify
the parameters to the constructor, for example:

 use WordList::Test::Dynamic::RandomWord::1000;
 # 1000 random words, each 10-15 characters long
 my $wl = WordList::Test::Dynamic::RandomWord::1000->(max_len => 15, min_len => 10);


When loading on the command-line, you can specify parameters using the
C<WORDLISTNAME=ARGNAME1,ARGVAL1,ARGNAME2,ARGVAL2> syntax, like in L<perl>'s
C<-M> option, for example:

 % wordlist -w Test::Dynamic::RandomWord::1000=max_len=15,min_len=10

Known parameters:

=head2 max_len

=head2 min_len

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Test-Dynamic-RandomWord-1000>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Test-Dynamic-RandomWord-1000>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Test-Dynamic-RandomWord-1000>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
