package WordList;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-24'; # DATE
our $DIST = 'WordList'; # DIST
our $VERSION = '0.7.5'; # VERSION

use strict 'subs', 'vars';

use WordListBase ();
our @ISA = qw(WordListBase);

# IFUNBUILT
# use Role::Tiny::With;
# with 'WordListRole::WordList';
# END IFUNBUILT

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my $fh = \*{"$class\::DATA"};
    binmode $fh, "encoding(utf8)";
    my $fh_orig_pos = tell $fh;
    unless (defined ${"$class\::DATA_POS"}) {
        ${"$class\::DATA_POS"} = $fh_orig_pos;
    }

    $self->{fh} = $fh;
    $self->{fh_orig_pos} = $fh_orig_pos;
    $self->{fh_seekable} = 1;
    $self;
}

sub each_word {
    my ($self, $code) = @_;

    my $i = 0;
    while (1) {
        my $word = $i++ ? $self->next_word : $self->first_word;
        last unless defined $word;
        my $res = $code->($word);
        last if defined $res && $res == -2;
    }
}

sub next_word {
    my $self = shift;

    my $fh = $self->{fh};
    my $word = <$fh>;
    chomp $word if defined $word;
    $word;
}

sub reset_iterator {
    my $self = shift;

    die "Cannot reset iterator, filehandle not seekable"
        unless $self->{fh_seekable};
    my $fh = $self->{fh};
    seek $fh, $self->{fh_orig_pos}, 0;
}

sub first_word {
    my $self = shift;

    $self->reset_iterator;
    $self->next_word;
}

sub pick {
    my ($self, $n, $allow_duplicates) = @_; # but this implementaiton never produces duplicates

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

This document describes version 0.7.5 of WordList (from Perl distribution WordList), released on 2020-05-24.

=head1 SYNOPSIS

Use one of the C<WordList::*> modules.

=head1 DESCRIPTION

C<WordList::*> modules are modules that contain, well, list of words. This
module, C<WordList>, serves as a base class and establishes convention for such
modules.

C<WordList> is an alternative for L<Games::Word::Wordlist> and
C<Games::Word::Wordlist::*>. Its main difference is: C<WordList::*> wordlists
are read-only/immutable and the modules are designed to have low startup
overhead. This makes them more suitable for use in CLI scripts which often only
want to pick a word from one or several lists. See L</"DIFFERENCES WITH
GAMES::WORD::WORDLIST"> for more details.

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
relies on C<first_word()> + C<next_word()>, or C<each_word()>, or C<all_words()>
to get the list. A deterministic wordlist returns the same list everytime
C<each_word()> or C<all_words()> is called. A non-deterministic list can return
a different list for a different C<each_word()> or C<all_words()> call. See
L<WordListRole::Dynamic::FirstNextResetFromEach> and
L<WordListRole::Dynamic::EachFromFirstNextReset> if you want to write a dynamic
wordlist module. It is possible for a dynamic list to return unordered or
duplicate entries, but it is not encouraged.

B<Parameterized wordlist.> When instantiating a wordlist class instance, user
can pass a list of key-value pairs as parameters. Normally only a dynamic
wordlist would accept parameters. Parameters are defined in the C<%PARAMS>
package variable. It is a hash of parameter names as keys and parameter
specification as values. Parameter specification follows function argument
metadata specified in L<Rinci::function>.

=head1 DIFFERENCES WITH GAMES::WORD::WORDLIST

Since this is a non-compatible interface from Games::Word::Wordlist, I also make
some other changes:

=over

=item * Namespace is put outside C<Games::>

Because obviously word lists are not only useful for games.

=item * Namespace is more language-neutral and not English-centric

English wordlists are put under C<WordList::EN::*>. Other languages have their
own subnamespaces, e.g. C<WordList::FR::*> or C<WordList::ID::*>. Aside from
language subnamespaces, there are also other subnamespaces:
C<WordList::Phrase::$LANG::*>, C<WordList::Password::*>, C<WordList::Domain::*>,
C<WordList::HTTP::*>, etc.

=item * Interface is simpler

This is partly due to the list being read-only. The methods provided are just:

- C<pick> (pick one or several random entries, without duplicates or with)

- C<word_exists> (check whether a word is in the list)

- C<each_word> (run code for each entry)

- C<all_words> (return all the words in a list)

A couple of other functions might be added, with careful consideration.

=item * More extensions

Some roles, subclasses, or alternate implementations are provided. For example,
since most wordlist are alphabetically sorted, a binary search can be performed
in C<word_exists()>. There is a role, L<WordListRole::BinarySearch>, that does
that and can be mixed in. An even faster version of C<word_exists()> using bloom
filter is offered by L<WordListRole::Bloom>. A faster version of pick() that
does random seeking is offered by L<WordListRole::RandomSeekPick>.

=back

=head1 SUBCLASSING OR CREATING ROLES

If you want to get the word list from another filehandle source, e.g. a gzipped
file, you just need to override C<reset_iterator()>. Your C<reset_iterator()>
needs to set the 'fh' attribute to the filehandle. The default C<first_word()>
calls C<reset_iterator()> and reads a line from the filehandle. The default
C<next_word()> just reads another line from the filehandle. C<each_word()> is
implemented in terms of C<first_word()> and C<next_word()>, and
C<word_exists()>, C<pick()>, and C<all_words()> are implemented in terms of
C<each_word()>.

=head1 METHODS

=head2 new

Usage:

 $wl = WordList::Module->new([ %params ]);

Constructor.

=head2 each_word

Usage:

 $wl->each_word($code)

Call C<$code> for each word in the list. The code will receive the word as its
first argument.

If code return -2 will exit early.

=head2 first_word

Another way to iterate the word list is by calling L</first_word> to get the
first word, then L</next_word> repeatedly until you get C<undef>.

=head2 next_word

Get the next word. See L</first_word> for more details.

=head2 reset_iterator

Reset iterator. Basically L</first_word> is equivalent to C<reset_iterator> +
L</next_word>.

=head2 pick

Usage:

 @words = $wl->pick([ $num=1 [ , $allow_duplicates=0 ] ])

Examples:

 ($word) = $wl->pick;
 @words  = $wl->pick(3);

Pick C<$n> (default: 1) random word(s) from the list, without duplicates (unless
C<$allow_duplicates> is set to true). If there are less then C<$n> words in the
list and duplicates are not allowed, only that many will be returned.

The algorithm used is from perlfaq ("perldoc -q "random line""), which scans the
whole list once (a.k.a. each_word() once). The algorithm is for returning a
single entry and is modified to support returning multiple entries.

=head2 word_exists

Usage:

 $wl->word_exists($word) => bool

Check whether C<$word> is in the list.

Algorithm in this implementation is linear scan (O(n)). Check out
L<WordListRole::BinarySearch> for an O(log n) implementation, or
L<WordListRole::Bloom> for O(1) implementation.

=head2 all_words

Usage:

 $wl->all_words() => list

Return all the words in a list, in order. Note that if wordlist is very large
you might want to use L</"each_word"> instead to avoid slurping all words into
memory.

=head1 FAQ

=head2 Why does pick() return "1"?

You probably write this:

 $word = $wl->pick;

instead of this:

 ($word) = $wl->pick;

C<pick()> returns a list and in scalar context it returns the number of elements
in the list which is 1. This is a common context trap in Perl.

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

C<WordListRole::*> modules.

C<WordList::*> modules.

L<Rinci>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
