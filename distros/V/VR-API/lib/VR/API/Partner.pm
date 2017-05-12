package VR::API::Partner;
use strict;

use VR::API;
use base qw( VR::API );

our $VERSION = $VR::API::VERSION;

sub _methods {
    my @enterprise_methods = VR::API::_methods( );
    return @enterprise_methods, qw(
        createCompany
        createUser
        enumerateCompanies
    );
}

BEGIN {
    VR::API::_manufacture_methods( __PACKAGE__ );
}

=head1 NAME

VR::API - Communicate with VerticalResponse's API services as a partner (privileged) user

=head1 SYNOPSIS

VR::API::Partner extends VR::API with certain methods that are only available when the
user communicates with the VR API servers using a signed SSL certificate, which securely
identifies the user as VerticalResponse partner.

Contact api-support@verticalresponse.com for information on becoming a VR API Partner.

=head2 Example
 
    #!/usr/bin/perl -w
    use strict;
    use VR::API::Partner;

    # SOAP::Lite uses Crypt::SSLeay for client-side certificate management.
    # perldoc Crypt::SSLeay for more documentation on how these environment
    # variables are used.
    $ENV{HTTPS_PKCS12_FILE} = "nickverticalresponsecom.p12";
    $ENV{HTTPS_PKCS12_PASSWORD} = "a_secret"; # Not needed for passphraseless PKCS#12 keystores

    # Log in to the main partner account
    my $vrapi = new VR::API::Partner;
    $vrapi->login( {
        username => 'nick@verticalresponse.com',
        password => 'another_secret',
    } );

    # Bring a sub-account's balance up to 100 email credits
    my $balance = $vrapi->getEmailCreditBalance( {
        company_id => 5678 # A sub-account managed by this partner
    } );

    if( $balance < 100 ) {
        $vrapi->transferEmailCredits( {
            from_company_id => 1234, # The partner's main account
            to_company_id => 5678, # The sub-account that needs email credits
            credits_to_transfer => 100 - $balance,
        } );
    }


=head2 Available functions

See VR::API::Partner::_methods() for a list of available functions. These 
functions correspond to the functions listed in the VR API Partner WSDL file.

Note that it is not necessary to send the 'session_id' parameter with each
method call; the VR::API infrastructure does that automatically after a
successful call to login().

=head2 References

Partner API (requires a valid partner certificate):

L<https://api.verticalresponse.com/partner-wsdl/1.0/VRAPI.wsdl>
L<https://api.verticalresponse.com/partner-wsdl/1.0/documentation.html>

=head1 SEE ALSO

L<VR::API>, the VR Enterprise API Perl module

=head1 COPYRIGHT

Copyright (C) 2007, Nick Marden, VerticalResponse Inc.

VR::API::Partner.pm is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

VR::API::Partner.pm is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=cut

1;
