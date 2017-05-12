package WordList::MetaSyntactic;

our $DATE = '2016-06-08'; # DATE
our $VERSION = '0.002'; # VERSION

use strict 'subs', 'vars';

sub new {
    my $package = shift;
    die "Must be subclassed by WordList::MetaSyntactic::*, not '$package'"
        unless $package =~ /\AWordList::MetaSyntactic::(\w+)\z/;
    require Acme::MetaSyntactic;
    bless [Acme::MetaSyntactic->new($1)], $package;
}

sub each_word {
    my ($self, $code) = @_;

    for my $word (sort $self->[0]->name(0)) {
        $code->($word);
    }
}

sub pick {
    my ($self, $n) = @_;

    $n ||= 1;
    $self->[0]->name($n);
}

sub word_exists {
    my ($self, $word) = @_;

    for my $w ($self->[0]->name(0)) {
        return 1 if $word eq $w;
    }
    0;
}

sub all_words {
    my ($self) = @_;

    # A:M doesn't provide a method to get a sorted list, so we sort it ourselves
    sort $self->[0]->name(0);
}

1;
# ABSTRACT: Base class for WordList::MetaSyntactic::*

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::MetaSyntactic - Base class for WordList::MetaSyntactic::*

=head1 VERSION

This document describes version 0.002 of WordList::MetaSyntactic (from Perl distribution WordList-MetaSyntactic), released on 2016-06-08.

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

Please visit the project's homepage at L<https://metacpan.org/release/WordList-MetaSyntactic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Base-MetaSyntactic>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-MetaSyntactic>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordList>

L<Acme::MetaSyntactic>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
