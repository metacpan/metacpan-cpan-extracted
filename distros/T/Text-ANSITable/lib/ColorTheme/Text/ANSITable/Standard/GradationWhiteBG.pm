package ColorTheme::Text::ANSITable::Standard::GradationWhiteBG;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-19'; # DATE
our $DIST = 'Text-ANSITable'; # DIST
our $VERSION = '0.602'; # VERSION

use parent 'ColorThemeBase::Static::FromStructColors';

use ColorTheme::Text::ANSITable::Standard::Gradation;
use Function::Fallback::CoreOrPP qw(clone);

our %THEME = %{ clone(\%ColorTheme::Text::ANSITable::Standard::Gradation::THEME) };
$THEME{summary} = 'Gradation (for terminal with white background)';

$THEME{args}{border1_fg}{default} = '000000';
$THEME{args}{border2_fg}{default} = 'cccccc';

$THEME{items}{header_bg} = 'cccccc';
$THEME{items}{num_data}  = '006666';
$THEME{items}{date_data} = '666600';
$THEME{items}{bool_data} = sub {
    my ($self, $name, $args) = @_;
    $args->{orig_data} ? '00cc00' : 'cc0000';
};

1;
# ABSTRACT: Gradation (for terminal with white background)

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Text::ANSITable::Standard::GradationWhiteBG - Gradation (for terminal with white background)

=head1 VERSION

This document describes version 0.602 of ColorTheme::Text::ANSITable::Standard::GradationWhiteBG (from Perl distribution Text-ANSITable), released on 2021-02-19.

=head1 DESCRIPTION

Border color has gradation from top to bottom. Accept arguments C<border1_fg> and
C<border2_fg> to set first (top) and second (bottom) foreground RGB colors.
Colors will fade from the top color to bottom color. Also accept C<border1_bg>
and C<border2_bg> to set background RGB colors.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-ANSITable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-ANSITable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Text-ANSITable/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018, 2017, 2016, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
