package WordList::Special::Stdin;

use strict;
use parent qw(WordList);

use Role::Tiny::With;
with 'WordListRole::EachFromFirstNextReset';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-12-01'; # DATE
our $DIST = 'WordList-Special-Stdin'; # DIST
our $VERSION = '0.002'; # VERSION

our $DYNAMIC = 1;

our %PARAMS = (
    cache => {
        summary => 'Whether to cache the words the first time until EOF, then reuse them later',
        schema => 'bool*',
    },
);

sub reset_iterator {
    my $self = shift;
    if ($self->{params}{cache}) {
        $self->{_iterator_idx} = 0;
    } else {
        warn "Warning: resetting a non-resettable wordlist (Special::Stdin)";
    }
}

sub first_word {
    my $self = shift;
    $self->reset_iterator if defined $self->{_iterator_idx};
    $self->next_word;
}

sub next_word {
    my $self = shift;

    $self->{_iterator_idx} = 0 unless defined $self->{_iterator_idx};
    if ($self->{_eof}) {
        if ($self->{_cache}) {
            return undef if $self->{_iterator_idx}++ >= @{ $self->{_words} }; ## no critic: Subroutines::ProhibitExplicitReturnUndef
            return $self->{_words}[ $self->{_iterator_idx} ];
        } else {
            return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
        }
    }

    my $word = <STDIN>;
    if (defined $word) {
        chomp $word;
    } else {
        $self->{_eof}++;
    }
    if ($self->{params}{cache}) {
        $self->{_words} = [] unless defined $self->{_words};
        push @{ $self->{_words} }, $word if defined $word;
    }
    $self->{_iterator_idx}++;
    return $word;
}

1;
# ABSTRACT: Wordlist from STDIN

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::Special::Stdin - Wordlist from STDIN

=head1 VERSION

This document describes version 0.002 of WordList::Special::Stdin (from Perl distribution WordList-Special-Stdin), released on 2021-12-01.

=head1 SYNOPSIS

From Perl:

 use WordList::Special::Stdin;

 my $wl = WordList::Special::Stdin->new();
 $wl->each_word(sub { ... });

From the command-line:

 % some-prog-that-produces-words | wordlist -w Special::Stdin

Typical use-case is to filter some words, either some L<wordlist> or other
programs:

 % wordlist ... | wordlist -w Special::Stdin --len 5 '/foo/'

=head1 DESCRIPTION

This is a special wordlist to get list of words from standard input.

=head1 WORDLIST PARAMETERS


This is a parameterized wordlist module. When loading in Perl, you can specify
the parameters to the constructor, for example:

 use WordList::Special::Stdin;
 my $wl = WordList::Special::Stdin->(bar => 2, foo => 1);


When loading on the command-line, you can specify parameters using the
C<WORDLISTNAME=ARGNAME1,ARGVAL1,ARGNAME2,ARGVAL2> syntax, like in L<perl>'s
C<-M> option, for example:

 % wordlist -w Special::Stdin=foo,1,bar,2 ...

Known parameters:

=head2 cache

Whether to cache the words the first time until EOF, then reuse them later.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Special-Stdin>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Special-Stdin>.

=head1 SEE ALSO

L<WordList>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Special-Stdin>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
