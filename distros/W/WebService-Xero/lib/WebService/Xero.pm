package WebService::Xero;

use 5.006;
use strict;
use warnings;

=head1 NAME

WebService::Xero - Access Xero Accounting Package Public and Private Application API

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';


=head1 SYNOPSIS


The Xero API is a RESTful web service and uses the OAuth (v1.0a) L<https://oauth.net/core/1.0a/> protocol to authenticate 3rd party applications.

WebService::Xero aims primarily to simplify the authenticated access to Xero API service end-point by encapuslating the OAuth requirements.

To enable API access see the Xero Getting started guide

L<https://developer.xero.com/documentation/getting-started/getting-started-guide/>

and with the Configured Application Authentication Credentials from L<https://api.xero.com/Application> 

this module will allow to to access the API Services.

Xero provides Private, Public and Partner Applications. This module currently supports the Private and Public Application types.

The simplest implementation uses a Private Application as follows:

    use WebService::Xero::Agent::PrivateApplication;
    use Data::Dumper;

    my $xero = WebService::Xero::Agent::PrivateApplication->new( CONSUMER_KEY    => 'YOUR_OAUTH_CONSUMER_KEY', 
                                                          CONSUMER_SECRET => 'YOUR_OAUTH_CONSUMER_SECRET', 
                                                          PRIVATE_KEY         => "-----BEGIN RSA PRIVATE KEY-----.........." 
                                                          );
    ## AND THEN ACCESS THE API POINTS

    my $contact_struct = $xero->do_xero_api_call( 'https://api.xero.com/api.xro/2.0/Contacts' );

    print Dumper $contact_struct; ## should contain an array of hashes containing contact data.


=head2 Limits

Xero API call limits are 1,000/day and 60/minute request per organisation limit as described at L<https://developer.xero.com/documentation/getting-started/xero-api-limits/>.

I have started to work at encpsulating the Xero data objects (Contact, Item, Invoice etc ) and will refine for the next release.

=head1 AUTHOR

Peter Scott, C<< <peter at computerpros.com.au> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-WebService-Xero at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Xero>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.




You can also look for information at:

=over 4

=item * Xero Developer Documentation 

L<https://developer.xero.com/documentation/api/api-overview/>

=item * Xero API DTD Schemas

L<https://github.com/XeroAPI/XeroAPI-Schemas>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Xero>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Xero>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Xero>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Xero/>

=back


=head1 ACKNOWLEDGEMENTS

=over 4

=item * Net::Xero for the OAUTH Code 

L<https://metacpan.org/pod/Net::Xero>


=item * Steve Bertrand for advice on Perlmonks 

L<https://metacpan.org/author/STEVEB>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Peter Scott.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WebService::Xero
