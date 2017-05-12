package Text::ANSITable::ColorTheme::Extra;

our $DATE = '2014-12-11'; # DATE
our $VERSION = '0.14'; # VERSION

use 5.010001;
use strict;
use warnings;

use Color::RGB::Util qw(rgb2grayscale rgb2sepia reverse_rgb_color);
use Color::Theme::Util qw(create_color_theme_transform);
require Text::ANSITable;

my $defct = Text::ANSITable->get_color_theme("Default::default_gradation");

our %color_themes = ();

{
    my $ct = create_color_theme_transform($defct, sub { rgb2grayscale(shift) });
    $ct->{v} = 1.1;
    $ct->{summary} = 'Grayscale';
    $color_themes{grayscale} = $ct;
}

{
    my $ct = create_color_theme_transform($defct, sub { rgb2sepia(shift) });
    $ct->{v} = 1.1;
    $ct->{summary} = 'Sepia tone';
    $color_themes{sepia} = $ct;
}

{
    my $ct = create_color_theme_transform($defct, sub { reverse_rgb_color(shift) });
    $ct->{v} = 1.1;
    $ct->{summary} = 'Reverse';
    $color_themes{reverse} = $ct;
}

1;
# ABSTRACT: More color themes

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::ANSITable::ColorTheme::Extra - More color themes

=head1 VERSION

This document describes version 0.14 of Text::ANSITable::ColorTheme::Extra (from Perl distribution Text-ANSITable-ColorTheme-Extra), released on 2014-12-11.

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

=item * grayscale (Grayscale)

=item * reverse (Reverse)

=item * sepia (Sepia tone)

=back

=cut
