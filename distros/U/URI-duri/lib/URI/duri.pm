package URI::duri;

use 5.010;
use strict;

BEGIN {
	$URI::duri::AUTHORITY = 'cpan:TOBYINK';
	$URI::duri::VERSION   = '0.003';
}

use base 'URI::_duri_tdb';
use constant _preferred_scheme => 'duri';

__PACKAGE__
__END__

=head1 NAME

URI::duri - the duri URI scheme

=head1 SYNOPSIS

 my $uri = URI->new('duri:2012:http://tobyinkster.co.uk/');
 say $uri->embedded_uri;

=head1 DESCRIPTION

The dated URI scheme is defined in an Internet Draft
L<http://tools.ietf.org/html/draft-masinter-dated-uri-10>. Dated URIs
include a date and an embedded URI. They identify the same resource that
was identified by the embedded URI at the given date.

This module brings support for the duri URI scheme to the L<URI>
framework.

=head2 Constructor

The constructor can be called in two forms:

=over

=item C<< new($string) >>

=item C<< new(\%hash) >>

=back

When called with a string argument, B<must> be a URI string conforming
to the dated URI Internet Draft.

If called with a hashref argument, the hash B<must> have a key
C<embedded_uri> which is a string or URI object. It B<may> have a key
C<datetime_string> which is a string representing a datetime in the
format required by the dated URI specification; alternatively it
B<may> have a key C<datetime> which is a L<DateTime> or (better)
L<DateTime::Incomplete> object; if neither are present, then the
current time is used instead.

=head2 Methods

The following accessors are provided:

=over

=item C<< datetime >>

=item C<< datetime($object) >>

Get/set the URI's datetime as a DateTime::Incomplete object.

=item C<< datetime_string >>

=item C<< datetime_string($string) >>

Get/set the URI's datetime as a literal string.

=item C<< embedded_uri >>

=item C<< embedded_uri($uri) >>

Get/set the embedded URI as a URI object. (The setter may also be called
with a plain string.)

=back

The following methods are inherited from L<URI> and make sense to use:

=over

=item C<< scheme >>

=item C<< scheme($string) >>

Get/set the URI scheme.

=item C<< as_string >>

Get the URI as a string.

=item C<< as_iri >>

Get the URI as a Unicode string.

=item C<< canonical >>

Get the URI as a canonical string.

=item C<< secure >>

Returns false, though the method doesn't make much sense. One URI is no
more secure than another; it is B<protocols> that can be secure or 
insecure.

=item C<< eq($uri) >>

Tests if this URI is equal to another.

=back

The following methods are also inherited from URI, but don't make much
sense to use: C<opaque>, C<path>, C<fragment>. It generally makes more
sense to inspect the embedded URI:

 say $duri->embedded_uri->fragment;

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=URI-duri>.

=head1 SEE ALSO

L<URI>, L<URI::tdb>.

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

