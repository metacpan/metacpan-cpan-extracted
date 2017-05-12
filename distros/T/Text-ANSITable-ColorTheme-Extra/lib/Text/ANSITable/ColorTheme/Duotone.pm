package Text::ANSITable::ColorTheme::Duotone;

our $DATE = '2014-12-11'; # DATE
our $VERSION = '0.14'; # VERSION

use 5.010001;
use strict;
use warnings;

use Color::Theme::Util qw(create_color_theme_transform);
require Text::ANSITable;

my $defct = Text::ANSITable->get_color_theme("Default::default_gradation");

our %color_themes = ();

sub _modify_rgb_weights {

    my ($rgb, $fr1, $fg1, $fb1, $fr2, $fg2, $fb2, $fr3, $fg3, $fb3) = @_;

    $rgb =~ /^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/o
        or die "Invalid rgb color, must be in 'ffffff' form";
    my $r = hex($1);
    my $g = hex($2);
    my $b = hex($3);

    # reference:
    # http://www.techrepublic.com/blog/howdoi/how-do-i-convert-images-to-grayscale-and-sepia-tone-using-c/120
    # with modified numbers. currently only by trial-and-error.
    my $or = ($r*$fr1) + ($g*$fg1) + ($b*$fb1);
    my $og = ($r*$fr2) + ($g*$fg2) + ($b*$fb2);
    my $ob = ($r*$fr3) + ($g*$fg3) + ($b*$fb3);
    for ($or, $og, $ob) { $_ = 255 if $_ > 255 }
    return sprintf("%02x%02x%02x", $or, $og, $ob);
}

# original sepia weights:
#0.393, 0.769, 0.189,
#0.349, 0.686, 0.168,
#0.272, 0.534, 0.131


{
    my $ct = create_color_theme_transform(
        $defct, sub {
            _modify_rgb_weights(
                shift,
                0.4, 0.3, 0.2,
                0.3, 0.8, 0.4,
                0.3, 0.5, 0.1,
            )});
    $ct->{v} = 1.1;
    $ct->{summary} = 'Duotone green 1';
    $color_themes{duotone_green1} = $ct;
}

{
    my $ct = create_color_theme_transform(
        $defct, sub {
            _modify_rgb_weights(
                shift,
                0.1, 0.3, 0.1,
                0.2, 0.5, 0.3,
                0.4, 0.7, 0.3,
            )});
    $ct->{v} = 1.1;
    $ct->{summary} = 'Duotone cyan 1';
    $color_themes{duotone_cyan1} = $ct;
}

{
    # this can be run several times to see which ones produce some nice output,
    # and be used to create new color themes

    my $ct = create_color_theme_transform(
        $defct, sub {
            state $fr1 = rand();
            state $fg1 = rand();
            state $fb1 = rand();
            state $fr2 = rand();
            state $fg2 = rand();
            state $fb2 = rand();
            state $fr3 = rand();
            state $fg3 = rand();
            state $fb3 = rand();
            _modify_rgb_weights(
                shift,
                $fr1, $fg1, $fb1,
                $fr2, $fg2, $fb2,
                $fr3, $fg3, $fb3,
            )});
    $ct->{v} = 1.1;
    $ct->{summary} = 'Random duotone on every run';
    $color_themes{duotone_random} = $ct;
}

1;
# ABSTRACT: Several duotone color themes

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::ANSITable::ColorTheme::Duotone - Several duotone color themes

=head1 VERSION

This document describes version 0.14 of Text::ANSITable::ColorTheme::Duotone (from Perl distribution Text-ANSITable-ColorTheme-Extra), released on 2014-12-11.

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

=item * duotone_cyan1 (Duotone cyan 1)

=item * duotone_green1 (Duotone green 1)

=item * duotone_random (Random duotone on every run)

=back

=cut
