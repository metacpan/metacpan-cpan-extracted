package WordListBase::MetaSyntactic;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-22'; # DATE
our $DIST = 'WordListBase-MetaSyntactic'; # DIST
our $VERSION = '0.005'; # VERSION

use strict 'subs', 'vars';

sub new {
    my $package = shift;
    die "Must be subclassed by WordList::MetaSyntactic::*, not '$package'"
        unless $package =~ /\AWordList::MetaSyntactic::(\w+)\z/;
    require Acme::MetaSyntactic;
    bless {
        # Acme::MetaSyntactic object
        _am => Acme::MetaSyntactic->new($1),

        _iterator_idx => 0,

         # the whole array of words, for when iterating
        _all_words => undef,
    }, $package;
}

sub each_word {
    my ($self, $code) = @_;

    for my $word (sort $self->{_am}->name(0)) {
        $code->($word);
    }
}

sub pick {
    my ($self, $n) = @_;

    $n ||= 1;
    $self->{_am}->name($n);
}

sub word_exists {
    my ($self, $word) = @_;

    for my $w ($self->{_am}->name(0)) {
        return 1 if $word eq $w;
    }
    0;
}

sub all_words {
    my ($self) = @_;

    # A:M doesn't provide a method to get a sorted list, so we sort it ourselves
    sort $self->{_am}->name(0);
}

sub reset_iterator {
    my $self = shift;
    $self->{_iterator_idx} = 0;
}

sub next_word {
    my $self = shift;
    unless (defined $self->{_all_words}) {
        $self->{_all_words} = [$self->all_words];
    }
    my $word = $self->{_all_words}[ $self->{_iterator_idx} ];
    $self->{_iterator_idx}++;
    $self->{_iterator_idx} = 0
        if $self->{_iterator_idx} > @{ $self->{_all_words} };
    $word;
}

sub first_word {
    my $self = shift;
    $self->reset_iterator;
    $self->next_word;
}

1;
# ABSTRACT: Base class for WordList::MetaSyntactic::*

__END__

=pod

=encoding UTF-8

=head1 NAME

WordListBase::MetaSyntactic - Base class for WordList::MetaSyntactic::*

=head1 VERSION

This document describes version 0.005 of WordListBase::MetaSyntactic (from Perl distribution WordListBase-MetaSyntactic), released on 2020-05-22.

=head1 SYNOPSIS

Use one of the C<WordList::MetaSyntactic::*> modules.

=head1 DESCRIPTION

Base class for C<WordList::MetaSyntactic::*> modules.
<WordList::MetaSyntactic::*> are wordlist modules that get their wordlist from
corresponding C<Acme::MetaSyntactic::*> modules.

=for Pod::Coverage ^(.+)$

=head1 METHODS

See L<WordList>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordListBase-MetaSyntactic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordListBase-MetaSyntactic>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordListBase-MetaSyntactic>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordList>

L<Acme::MetaSyntactic>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
