package WordListRole::FirstNextResetFromEach;

use Role::Tiny;

requires 'each_word';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-26'; # DATE
our $DIST = 'WordList'; # DIST
our $VERSION = '0.7.11'; # VERSION

sub first_word {
    my $self = shift;

    $self->reset_iterator;
    $self->next_word;
}

sub next_word {
    my $self = shift;

    unless ($self->{_all_words}) {
        my @wordlist;
        $self->each_word(sub { push @wordlist, $_[0] });
        $self->{_all_words} = \@wordlist;
    }
    $self->{_iterator_idx} = 0 unless defined $self->{_iterator_idx};

    return undef if $self->{_iterator_idx} > $#{ $self->{_all_words} }; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    $self->{_all_words}[ $self->{_iterator_idx}++ ];
}

sub reset_iterator {
    my $self = shift;

    $self->{_iterator_idx} = 0;
}

1;
# ABSTRACT: Provide first_word(), next_word(), reset_iterator(); relies on each_word()

__END__

=pod

=encoding UTF-8

=head1 NAME

WordListRole::FirstNextResetFromEach - Provide first_word(), next_word(), reset_iterator(); relies on each_word()

=head1 VERSION

This document describes version 0.7.11 of WordListRole::FirstNextResetFromEach (from Perl distribution WordList), released on 2021-09-26.

=head1 DESCRIPTION

This role can be used if you want to construct a dynamic wordlist module by
providing C<each_word()>. This role will provide the C<first_word()>,
C<next_word()>, C<reset_iterator()> that uses C<each_word()>.

=for Pod::Coverage .+

=head1 REQUIRED METHODS

=head2 each_word

=head1 PROVIDED METHODS

=head2 first_word

=head2 next_word

=head2 reset_iterator

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList>.

=head1 SEE ALSO

L<WordListRole::EachFromFirstNextReset>

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
