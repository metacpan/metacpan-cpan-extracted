package Text::Minify::XS;

# ABSTRACT: Simple text minification

use v5.9.3;
use strict;
use warnings;

require Exporter;
require XSLoader;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(minify);

our $VERSION = 'v0.4.6';

XSLoader::load( "Text::Minify::XS", $VERSION );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Minify::XS - Simple text minification

=head1 VERSION

version v0.4.6

=head1 SYNOPSIS

  use Text::Minify::XS qw/ minify /;

  my $out = minify( $in );

=head1 EXPORTS

=head2 minify

  my $out = minify( $in );

This is a quick-and-dirty text minifier that removes whitespace in a
single pass.

It does the following:

=over

=item *

removes leading whitespace (indentation),

=item *

removes trailing whitespace,

=item *

removes multiple newlines,

=item *

and changes carriage returns to newlines.

=back

It does not recognise any form of markup, comments or text quoting.
Nor does it remove extra whitespace in the middle of the line.

=head1 KNOWN ISSUES

=head2 Support for older Perl versions

This module requires Perl v5.9.3 or newer.

Pull requests to support older versions of Perl are welcome. See
L</SOURCE>.

=head2 Malformed UTF-8

Malformed UTF-8 characters may be be mangled or omitted from the
output. You should ensure that the input string is properly encoded as
UTF-8.

=head1 SEE ALSO

There are many string trimming and specialised
whitespace/comment-removal modules on CPAN.  Some of them are:

=head2 CSS

=over

=item L<CSS::Minifier>

=item L<CSS::Minifier::XS>

=item L<CSS::Packer>

=back

=head2 HTML

=over

=item L<HTML::Packer>

=back

=head2 JavaScript

=over

=item L<JavaScript::Minifier>

=item L<JavaScript::Minifier::XS>

=item L<JavaScript::Packer>

=back

=head2 Plain Text

=over

=item L<String::Strip>

=item L<String::Trim>

=item String::Trim::Regex

=item L<String::Trim::NonRegex>

=item L<String::Util>

=item L<Text::Trim>

=back

This list does not include specialised template filters or plugins to
web frameworks.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Text-Minify-XS>
and may be cloned from L<git://github.com/robrwo/Text-Minify-XS.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Text-Minify-XS/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020-2021 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
