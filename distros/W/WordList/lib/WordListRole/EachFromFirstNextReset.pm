package WordListRole::EachFromFirstNextReset;

use Role::Tiny;

requires 'first_word';
requires 'next_word';
requires 'reset_iterator';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-26'; # DATE
our $DIST = 'WordList'; # DIST
our $VERSION = '0.7.11'; # VERSION

sub each_word {
    no warnings 'numeric';

    my ($self, $code) = @_;

    $self->reset_iterator;
    my $word = $self->first_word;
    return undef unless defined $word; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    my $ret = $code->($word);
    return undef if defined $ret && $ret == -2; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    while (1) {
        $word = $self->next_word;
        return undef unless defined $word; ## no critic: Subroutines::ProhibitExplicitReturnUndef
        $ret = $code->($word);
        return undef if defined $ret && $ret == -2; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    }
}

1;
# ABSTRACT: Provide each_word(); relies on first_word(), next_word(), reset_iterator()

__END__

=pod

=encoding UTF-8

=head1 NAME

WordListRole::EachFromFirstNextReset - Provide each_word(); relies on first_word(), next_word(), reset_iterator()

=head1 VERSION

This document describes version 0.7.11 of WordListRole::EachFromFirstNextReset (from Perl distribution WordList), released on 2021-09-26.

=head1 DESCRIPTION

This role can be used if you want to construct a dynamic wordlist module by
providing providing C<first_word()>, C<next_word()>, C<reset_iterator()>. This
role will add an C<each_word()> method that uses the former three methods.

=for Pod::Coverage .+

=head1 REQUIRED METHODS

=head2 first_word

=head2 next_word

=head2 reset_iterator

=head1 PROVIDED METHODS

=head2 each_word

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList>.

=head1 SEE ALSO

L<WordListRole::FirstNextResetFromEach>

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

This software is copyright (c) 2021, 2020, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
