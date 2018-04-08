package WordList;

our $DATE = '2018-04-03'; # DATE
our $VERSION = '0.4.1'; # VERSION

use strict 'subs', 'vars';

sub new {
    my $class = shift;
    my $fh = \*{"$class\::DATA"};
    binmode $fh, "encoding(utf8)";
    unless (defined ${"$class\::DATA_POS"}) {
        ${"$class\::DATA_POS"} = tell $fh;
    }
    bless [], $class;
}

sub each_word {
    my ($self, $code) = @_;

    my $class = ref($self);

    my $fh = \*{"$class\::DATA"};

    seek $fh, ${"$class\::DATA_POS"}, 0;
    while (defined(my $word = <$fh>)) {
        chomp $word;
        my $res = $code->($word);
        last if defined $res && $res == -2;
    }
}

sub pick {
    my ($self, $n) = @_;

    $n = 1 if !defined $n;
    die "Please specify a positive number of words to pick" if $n < 1;

    if ($n == 1) {
        my $i = 0;
        my $word;
        # algorithm from Learning Perl
        $self->each_word(
            sub {
                $i++;
                $word = $_[0] if rand($i) < 1;
            }
        );
        return $word;
    }

    my $i = 0;
    my @words;
    $self->each_word(
        sub {
            $i++;
            if (@words < $n) {
                # we haven't reached $n, put word to result in a random position
                splice @words, rand(@words+1), 0, $_[0];
            } else {
                # we have reached $n, just replace a word randomly, using
                # algorithm from Learning Perl, slightly modified
                rand($i) < @words and splice @words, rand(@words), 1, $_[0];
            }
        }
    );
    @words;
}

sub word_exists {
    my ($self, $word) = @_;

    my $found = 0;
    $self->each_word(
        sub {
            if ($word eq $_[0]) {
                $found = 1;
                return -2;
            }
        }
    );
    $found;
}

sub all_words {
    my ($self) = @_;

    my @words;
    $self->each_word(
        sub {
            push @words, $_[0];
        }
    );
    @words;
}

1;
# ABSTRACT: Word lists

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList - Word lists

=head1 VERSION

This document describes version 0.4.1 of WordList (from Perl distribution WordList), released on 2018-04-03.

=head1 SYNOPSIS

Use one of the C<WordList::*> modules.

=head1 DESCRIPTION

C<WordList::*> modules are modules that contain, well, list of words. This
module, C<WordList>, serves as a base class and establishes convention for such
modules.

C<WordList> is an alternative interface for L<Games::Word::Wordlist> and
C<Games::Word::Wordlist::*>. Its main difference is: C<WordList::*> wordlists
are read-only/immutable and the modules are designed to have low startup
overhead. This makes them more suitable for use in CLI scripts which often only
want to pick a word from one or several lists.

Unless you are defining a dynamic wordlist (see below), words (or phrases) must
be put in C<__DATA__> section, one per line. Putting the wordlist in the
C<__DATA__> section relieves perl from having to parse the list during the
loading of the module. To search for words or picking some random words from the
list, the module also need not slurp the whole list into memory (and will not do
so unless explicitly instructed).

You must sort your words ascibetically (or by Unicode code point). Sorting makes
it more convenient to diff different versions of the module, as well as
performing binary search. If you have a different sort order other than
ascibetical, you must set package variable C<$SORT> with some true value (say,
C<frequency>).

There must not be any duplicate entry in the word list.

B<Dynamic and non-deterministic wordlist.> A dynamic wordlist must set package
variable C<$DYNAMIC> to either 1 (deterministic) or 2 (non-deterministic). A
dynamic wordlist does not put the wordlist in the DATA section; instead, user
relies on C<each_word()> or C<all_words()> to get the list. A deterministic
wordlist returns the same list everytime C<each_word()> or C<all_words()> is
called. A non-deterministic list can return a different list for a different
C<each_word()> or C<all_words()> call.

=head1 DIFFERENCES WITH GAMES::WORD::WORDLIST

Since this is a new and non-backward compatible interface from
Games::Word::Wordlist, I also make some other changes:

=over

=item * Namespace is put outside C<Games::>

Because obviously word lists are not only useful for games.

=item * Interface is simpler

This is partly due to the list being read-only. The methods provided are just:

- C<pick> (pick one or several random entries)

- C<word_exists> (check whether a word is in the list)

- C<each_word> (run code for each entry)

- C<all_words> (return all the words in a list)

A couple of other functions might be added, with careful consideration.

=item * Namespace is more language-neutral and not English-centric

=back

=head1 METHODS

=head2 new

Usage:

 $wl = WordList::Module->new => obj

Constructor.

=head2 each_word

Usage:

 $wl->each_word($code)

Call C<$code> for each word in the list. The code will receive the word as its
first argument.

If code return -2 will exit early.

=head2 pick

Usage:

 $wl->pick($n = 1) => list

Pick C<$n> (default: 1) random word(s) from the list. If there are less then
C<$n> words in the list, only that many will be returned.

The algorithm used is from perlfaq ("perldoc -q "random line""), which scans the
whole list once (a.k.a. each_word() once). The algorithm is for returning a
single entry and is modified to support returning multiple entries.

=head2 word_exists

Usage:

 $wl->word_exists($word) => bool

Check whether C<$word> is in the list.

Algorithm in this implementation is linear scan (O(n)). Check out
L<WordList::Role::BinarySearch> for an O(log n) implementation, or
L<WordList::Role::Bloom> for O(1) implementation.

=head2 all_words

Usage:

 $wl->all_words() => list

Return all the words in a list, in order. Note that if wordlist is very large
you might want to use L</"each_word"> instead to avoid slurping all words into
memory.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

C<WordList::Role::*> modules.

Other C<WordList::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
