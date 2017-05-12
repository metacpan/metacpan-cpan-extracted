package Text::ANSITable::ColorTheme::Monotone;

our $DATE = '2014-12-11'; # DATE
our $VERSION = '0.14'; # VERSION

use 5.010001;
use strict;
use warnings;

use Convert::Color;
use Color::Theme::Util qw(create_color_theme_transform);
require Text::ANSITable;

sub _make_monotone_theme {
    my ($basect, $hue) = @_;
    my $ct = create_color_theme_transform(
        $basect, sub {
            $_[0] =~ /#?(..)(..)(..)/;
            my $r = hex($1);
            my $g = hex($2);
            my $b = hex($3);
            my $c = Convert::Color->new("rgb8:$r,$g,$b");
            my ($h, $s, $v) = $c->as_hsv->hsv;
            $c = Convert::Color->new("hsv:$hue,$s,$v");
            $c->as_rgb8->hex;
        });
    $ct->{v} = 1.1;
    $ct;
}

my $defct = Text::ANSITable->get_color_theme("Default::default_gradation");

our %color_themes = ();

{
    my $ct = _make_monotone_theme($defct, 0);
    $ct->{v} = 1.1;
    $ct->{summary} = 'Monotone red';
    $color_themes{monotone_red} = $ct;
}

{
    my $ct = _make_monotone_theme($defct, 60);
    $ct->{v} = 1.1;
    $ct->{summary} = 'Monotone yellow';
    $color_themes{monotone_yellow} = $ct;
}

{
    my $ct = _make_monotone_theme($defct, 120);
    $ct->{v} = 1.1;
    $ct->{summary} = 'Monotone green';
    $color_themes{monotone_green} = $ct;
}

{
    my $ct = _make_monotone_theme($defct, 180);
    $ct->{v} = 1.1;
    $ct->{summary} = 'Monotone cyan';
    $color_themes{monotone_cyan} = $ct;
}

{
    my $ct = _make_monotone_theme($defct, 240);
    $ct->{v} = 1.1;
    $ct->{summary} = 'Monotone blue';
    $color_themes{monotone_blue} = $ct;
}

{
    my $ct = _make_monotone_theme($defct, 300);
    $ct->{v} = 1.1;
    $ct->{summary} = 'Monotone purple';
    $color_themes{monotone_purple} = $ct;
}

1;
# ABSTRACT: Monotone color themes

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::ANSITable::ColorTheme::Monotone - Monotone color themes

=head1 VERSION

This document describes version 0.14 of Text::ANSITable::ColorTheme::Monotone (from Perl distribution Text-ANSITable-ColorTheme-Extra), released on 2014-12-11.

=head1 DESCRIPTION

Monotone themes uses single-hue colors, differing only in saturation and
lightness/value.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-ANSITable-ColorTheme-Extra>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-ANSITable-ColorTheme-Extra>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-ANSITable-ColorTheme-Extra>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 INCLUDED COLOR THEMES

=over

=item * monotone_blue (Monotone blue)

=item * monotone_cyan (Monotone cyan)

=item * monotone_green (Monotone green)

=item * monotone_purple (Monotone purple)

=item * monotone_red (Monotone red)

=item * monotone_yellow (Monotone yellow)

=back

=cut
