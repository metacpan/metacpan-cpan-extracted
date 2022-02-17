# no code
## no critic: TestingAndDebugging::RequireUseStrict
package BorderStyle::Text::ANSITable::OldCompat::Default::single_ascii;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-14'; # DATE
our $DIST = 'Text-ANSITable'; # DIST
our $VERSION = '0.608'; # VERSION

use alias::module 'BorderStyle::ASCII::SingleLine';

1;
# ABSTRACT: ASCII::SingleLine border style (with old name)

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle::Text::ANSITable::OldCompat::Default::single_ascii - ASCII::SingleLine border style (with old name)

=head1 VERSION

This document describes version 0.608 of BorderStyle::Text::ANSITable::OldCompat::Default::single_ascii (from Perl distribution Text-ANSITable), released on 2022-02-14.

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
