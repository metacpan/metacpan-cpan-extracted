## no critic: Modules::ProhibitAutomaticExportation

package URI::Escape::Any;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-18'; # DATE
our $DIST = 'URI-Escape-Any'; # DIST
our $VERSION = '0.001'; # VERSION

# IFUNBUILT
# use strict 'subs', 'vars';
# #use warnings;
# END IFUNBUILT

use Exporter qw(import);

our @EXPORT = qw(uri_escape uri_escape_utf8 uri_unescape);
#our @EXPORT_OK = qw(%escapes);

if (eval { require URI::XSEscape; 1 }) {
    *uri_escape        = \&URI::XSEscape::uri_escape;
    *uri_escape_utf8   = \&URI::XSEscape::uri_escape_utf8;
    *uri_unescape      = \&URI::XSEscape::uri_unescape;
} elsif (eval { require URI::Escape::XS; 1 }) {
    *uri_escape        = \&URI::Escape::XS::uri_escape;
    *uri_escape_utf8   = \&URI::Escape::XS::uri_escape_utf8;
    *uri_unescape      = \&URI::Escape::XS::uri_unescape;
} else {
    require URI::Escape;
    *uri_escape        = \&URI::Escape::uri_escape;
    *uri_escape_utf8   = \&URI::Escape::uri_escape_utf8;
    *uri_unescape      = \&URI::Escape::uri_unescape;
}

1;
# ABSTRACT: Use XS-based URI escape module, fallback to URI::Escape

__END__

=pod

=encoding UTF-8

=head1 NAME

URI::Escape::Any - Use XS-based URI escape module, fallback to URI::Escape

=head1 VERSION

This document describes version 0.001 of URI::Escape::Any (from Perl distribution URI-Escape-Any), released on 2020-06-18.

=head1 SYNOPSIS

 use URI::Escape::Any;

 my $escaped = uri_escape('/foo');

=head1 DESCRIPTION

This module tries to load L<URI::XSEscape>, then L<URI::Escape::XS>, then falls
back to L<URI::Escape>.

The export '%escapes' from URI::Escape is currently not provided.

=head1 FUNCTIONS

=head2 uri_escape

=head2 uri_escape_utf8

=head2 uri_unescape

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/URI-Escape-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-URI-Escape-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=URI-Escape-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<URI::XSEscape>

L<URI::Escape::XS>

L<URI::Escape>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
