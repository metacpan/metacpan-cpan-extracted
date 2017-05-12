package URI::tdb;

use 5.010;
use strict;

BEGIN {
	$URI::tdb::AUTHORITY = 'cpan:TOBYINK';
	$URI::tdb::VERSION   = '0.003';
}

use base 'URI::_duri_tdb';
use constant _preferred_scheme => 'tdb';

__PACKAGE__
__END__

=head1 NAME

URI::tdb - the tdb URI scheme

=head1 SYNOPSIS

 my $uri = URI->new('tdb:2012:http://tobyinkster.co.uk/');
 say $uri->embedded_uri;

=head1 DESCRIPTION

The dated URI scheme is defined in an Internet Draft
L<http://tools.ietf.org/html/draft-masinter-dated-uri-10>. Dated URIs
include a date and an embedded URI. They identify the same resource that
was identified by the embedded URI at the given date.

tdb URIs take a slightly different approach, identifying the "thing
described by" the resource. In the example given in the SYNOPSIS, the tdb
URI doesn't identify a web page; it identifies a person.

This module brings support for the tdb URI scheme to the L<URI> framework.

This module provides an exactly identical interface to L<URI::duri> with
the exception of differences described in the "Differences from URI::duri"
section below.

=head2 Differences from URI::duri

None.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=URI-duri>.

=head1 SEE ALSO

L<URI>, L<URI::duri>.

L<http://tools.ietf.org/html/draft-masinter-dated-uri-10>.

L<http://www.perlrdf.org/>.

L<DateTime::Incomplete>.

=head1 AUTHOR

Toby Inkster E<lt>tdb:2012:http://metacpan.org/author/TOBYINKE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

