package Text::ANSITable::StyleSet::AltRow;

use 5.010001;
use Moo;
use namespace::clean;

has odd_bgcolor  => (is => 'rw');
has even_bgcolor => (is => 'rw');
has odd_fgcolor  => (is => 'rw');
has even_fgcolor => (is => 'rw');

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-14'; # DATE
our $DIST = 'Text-ANSITable'; # DIST
our $VERSION = '0.608'; # VERSION

sub summary {
    "Set different foreground and/or background color for odd/even rows";
}

sub apply {
    my ($self, $table) = @_;

    $table->add_cond_row_style(
        sub {
            my ($t, %args) = @_;
            my %styles;
            # because we count from 0
            if ($_ % 2 == 0) {
                $styles{bgcolor} = $self->odd_bgcolor
                    if defined $self->odd_bgcolor;
                $styles{fgcolor}=$self->odd_fgcolor
                    if defined $self->odd_fgcolor;
            } else {
                $styles{bgcolor} = $self->even_bgcolor
                    if defined $self->even_bgcolor;
                $styles{fgcolor} = $self->even_fgcolor
                    if defined $self->even_fgcolor;
            }
            \%styles;
        },
    );
}

1;

# ABSTRACT: Set different foreground and/or background color for odd/even rows";

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::ANSITable::StyleSet::AltRow - Set different foreground and/or background color for odd/even rows";

=head1 VERSION

This document describes version 0.608 of Text::ANSITable::StyleSet::AltRow (from Perl distribution Text-ANSITable), released on 2022-02-14.

=for Pod::Coverage ^(summary|apply)$

=head1 ATTRIBUTES

=head2 odd_bgcolor

=head2 odd_fgcolor

=head2 even_bgcolor

=head2 even_fgcolor

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-ANSITable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-ANSITable>.

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

This software is copyright (c) 2022, 2021, 2020, 2018, 2017, 2016, 2015, 2014, 2013 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-ANSITable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
