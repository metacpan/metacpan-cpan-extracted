package ColorTheme::Text::ANSITable::Standard::NoGradationWhiteBG;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-09'; # DATE
our $DIST = 'Text-ANSITable'; # DIST
our $VERSION = '0.604'; # VERSION

use parent 'ColorThemeBase::Static::FromStructColors';

use ColorTheme::Text::ANSITable::Standard::GradationWhiteBG;
use Function::Fallback::CoreOrPP qw(clone);

our %THEME = %{ clone(\%ColorTheme::Text::ANSITable::Standard::GradationWhiteBG::THEME) };
$THEME{summary} = 'Default (no gradation, for white background)';

delete $THEME{description};

delete $THEME{args}{border1};
delete $THEME{args}{border2};

$THEME{items}{border} = '666666';

1;
# ABSTRACT: Default (no gradation, for white background)

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Text::ANSITable::Standard::NoGradationWhiteBG - Default (no gradation, for white background)

=head1 VERSION

This document describes version 0.604 of ColorTheme::Text::ANSITable::Standard::NoGradationWhiteBG (from Perl distribution Text-ANSITable), released on 2021-08-09.

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
