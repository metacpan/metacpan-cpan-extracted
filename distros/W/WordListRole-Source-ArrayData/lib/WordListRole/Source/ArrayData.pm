package WordListRole::Source::ArrayData;

use Role::Tiny;
use Role::Tiny::With;
with 'WordListRole::EachFromFirstNextReset';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-06'; # DATE
our $DIST = 'WordListRole-Source-ArrayData'; # DIST
our $VERSION = '0.001'; # VERSION

requires '_arraydata';

sub reset_iterator {
    my $self = shift;
    $self->{_arraydata} ||= $self->_arraydata;

    $self->{_arraydata}->reset_iterator;
}

sub first_word {
    my $self = shift;
    $self->{_arraydata} ||= $self->_arraydata;

    if ($self->{_arraydata}->has_next_item) {
        $self->{_arraydata}->get_next_item;
    } else {
        return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    }
}

sub next_word {
    my $self = shift;
    $self->{_arraydata} ||= $self->_arraydata;

    if ($self->{_arraydata}->has_next_item) {
        $self->{_arraydata}->get_next_item;
    } else {
        return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    }
}

1;
# ABSTRACT: Role to use an ArrayData::* module as wordlist source

__END__

=pod

=encoding UTF-8

=head1 NAME

WordListRole::Source::ArrayData - Role to use an ArrayData::* module as wordlist source

=head1 VERSION

This document describes version 0.001 of WordListRole::Source::ArrayData (from Perl distribution WordListRole-Source-ArrayData), released on 2022-03-06.

=head1 DESCRIPTION

You return the C<ArrayData::*> class instance in C<_arraydata> method that you
provide.

=for Pod::Coverage .+

=head1 REQUIRED METHODS

=head2 _arraydata

This is where you return an instance of an C<ArrayData::*> class.

=head1 PROVIDED METHODS

=head2 reset_iterator

=head2 first_word

=head2 next_word

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordListRole-Source-ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordListRole-Source-ArrayData>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordListRole-Source-ArrayData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
