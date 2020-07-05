## no critic: Modules::ProhibitAutomaticExportation

package URI::Escape::Path;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-18'; # DATE
our $DIST = 'URI-Escape-Path'; # DIST
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;

use Exporter qw(import);
use URI::Escape::Any ();

our @EXPORT = qw(uri_escape uri_escape_utf8 uri_unescape);

sub uri_escape      { URI::Escape::Any::uri_escape     ($_[0], $_[1] || "^A-Za-z0-9\-\._~/") }
sub uri_escape_utf8 { URI::Escape::Any::uri_escape_utf8($_[0], $_[1] || "^A-Za-z0-9\-\._~/") }
*uri_unescape = \&URI::Escape::Any::uri_unescape;

1;
# ABSTRACT: Like URI::Escape, but does not escape '/'

__END__

=pod

=encoding UTF-8

=head1 NAME

URI::Escape::Path - Like URI::Escape, but does not escape '/'

=head1 VERSION

This document describes version 0.001 of URI::Escape::Path (from Perl distribution URI-Escape-Path), released on 2020-06-18.

=head1 SYNOPSIS

 use URI::Escape::Path;
 # use like you would use URI::Escape
 my $escaped = uri_escape('/foo bar'); # => "/foo%20bar'

=head1 DESCRIPTION

This module's C<uri_escape()> and C<uri_escape_utf8()> functions use this
default unsafe character list:

 "^A-Za-z0-9\-\._~"

instead of L<URI::Escape>'s default of:

 "^A-Za-z0-9\-\._~"

=head1 FUNCTIONS

=head2 uri_escape

=head2 uri_escape_utf8

=head2 uri_unescape

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/URI-Escape-Path>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-URI-Escape-Path>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=URI-Escape-Path>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<URI::Escape>

L<URI::Escape::Any>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
