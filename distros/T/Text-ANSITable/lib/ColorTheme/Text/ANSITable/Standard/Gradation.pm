# no code
## no critic: TestingAndDebugging::RequireUseStrict
package ColorTheme::Text::ANSITable::Standard::Gradation;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-02-24'; # DATE
our $DIST = 'Text-ANSITable'; # DIST
our $VERSION = '0.610'; # VERSION

use parent 'ColorThemeBase::Static::FromStructColors';

use Color::RGB::Util qw(mix_2_rgb_colors);

our %THEME = (
    v => 2,
    summary => 'Gradation border (for terminal with black background)',
    args => {
        border1_fg => {
            schema => 'color::rgb24*',
            default => 'ffffff',
        },
        border2_fg => {
            schema => 'color::rgb24*',
            default => '444444',
        },
        border1_bg => {
            schema => 'color::rgb24*',
            default => undef,
        },
        border2_bg => {
            schema => 'color::rgb24*',
            default => undef,
        },
    },
    description => <<'_',

Border color has gradation from top to bottom. Accept arguments `border1_fg` and
`border2_fg` to set first (top) and second (bottom) foreground RGB colors.
Colors will fade from the top color to bottom color. Also accept `border1_bg`
and `border2_bg` to set background RGB colors.

_
    items => {
        border      => sub {
            my ($self, $name, $args) = @_;

            my $t = $args->{table};

            my $pct = ($t->{_draw}{y}+1) / $t->{_draw}{table_height};

            my $rgbf1 = $self->{args}{border1_fg};
            my $rgbf2 = $self->{args}{border2_fg};
            my $rgbf  = mix_2_rgb_colors($rgbf1, $rgbf2, $pct);

            my $rgbb1 = $self->{args}{border1_bg};
            my $rgbb2 = $self->{args}{border2_bg};
            my $rgbb;
            if ($rgbb1 && $rgbb2) {
                $rgbb = mix_2_rgb_colors($rgbb1, $rgbb2, $pct);
            }

            #say "D:$rgbf, $rgbb";
            {fg=>$rgbf, bg=>$rgbb};
        },

        header      => '808080',
        header_bg   => undef,
        cell        => undef,
        cell_bg     => undef,

        num_data    => '66ffff',
        str_data    => undef,
        date_data   => 'aaaa00',
        bool_data   => sub {
            my ($self, $name, $args) = @_;

            $args->{orig_data} ? '00ff00' : 'ff0000';
        },
    },
);

1;
# ABSTRACT: Gradation border (for terminal with black background)

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Text::ANSITable::Standard::Gradation - Gradation border (for terminal with black background)

=head1 VERSION

This document describes version 0.610 of ColorTheme::Text::ANSITable::Standard::Gradation (from Perl distribution Text-ANSITable), released on 2025-02-24.

=head1 DESCRIPTION

Border color has gradation from top to bottom. Accept arguments C<border1_fg> and
C<border2_fg> to set first (top) and second (bottom) foreground RGB colors.
Colors will fade from the top color to bottom color. Also accept C<border1_bg>
and C<border2_bg> to set background RGB colors.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-ANSITable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
