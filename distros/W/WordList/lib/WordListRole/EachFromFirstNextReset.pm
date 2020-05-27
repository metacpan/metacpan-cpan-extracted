package WordListRole::EachFromFirstNextReset;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-24'; # DATE
our $DIST = 'WordList'; # DIST
our $VERSION = '0.7.5'; # VERSION

use Role::Tiny;

requires 'first_word';
requires 'next_word';
requires 'reset_iterator';

sub each_word {
    no warnings 'numeric';

    my ($self, $code) = @_;

    $self->reset_iterator;
    my $word = $self->first_word;
    return undef unless defined $word;
    my $ret = $code->($word);
    return undef if defined $ret && $ret == -2;
    while (1) {
        $word = $self->next_word;
        return undef unless defined $word;
        $ret = $code->($word);
        return undef if defined $ret && $ret == -2;
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

This document describes version 0.7.5 of WordListRole::EachFromFirstNextReset (from Perl distribution WordList), released on 2020-05-24.

=head1 DESCRIPTION

This role can be used if you want to construct a dynamic wordlist module by
providing providing C<first_word()>, C<next_word()>, C<reset_iterator()>. This
role will add an C<each_word()> method that uses the former three methods.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
