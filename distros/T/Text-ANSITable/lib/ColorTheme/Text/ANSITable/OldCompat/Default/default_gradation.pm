package ColorTheme::Text::ANSITable::OldCompat::Default::default_gradation;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-09'; # DATE
our $DIST = 'Text-ANSITable'; # DIST
our $VERSION = '0.604'; # VERSION

use alias::module 'ColorTheme::Text::ANSITable::Standard::Gradation';

1;
# ABSTRACT: Text::ANSITable::Standard::Gradation color theme (with old name)

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Text::ANSITable::OldCompat::Default::default_gradation - Text::ANSITable::Standard::Gradation color theme (with old name)

=head1 VERSION

This document describes version 0.604 of ColorTheme::Text::ANSITable::OldCompat::Default::default_gradation (from Perl distribution Text-ANSITable), released on 2021-08-09.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-ANSITable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018, 2017, 2016, 2015, 2014, 2013 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
