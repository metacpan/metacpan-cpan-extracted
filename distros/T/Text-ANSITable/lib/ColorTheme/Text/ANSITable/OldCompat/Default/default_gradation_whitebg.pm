# no code
## no critic: TestingAndDebugging::RequireUseStrict
package ColorTheme::Text::ANSITable::OldCompat::Default::default_gradation_whitebg;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-27'; # DATE
our $DIST = 'Text-ANSITable'; # DIST
our $VERSION = '0.606'; # VERSION

use alias::module 'ColorTheme::Text::ANSITable::Standard::GradationWhiteBG';

1;
# ABSTRACT: Text::ANSITable::Standard::GradationWhiteBG color theme (with old name)

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Text::ANSITable::OldCompat::Default::default_gradation_whitebg - Text::ANSITable::Standard::GradationWhiteBG color theme (with old name)

=head1 VERSION

This document describes version 0.606 of ColorTheme::Text::ANSITable::OldCompat::Default::default_gradation_whitebg (from Perl distribution Text-ANSITable), released on 2021-08-27.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018, 2017, 2016, 2015, 2014, 2013 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-ANSITable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
