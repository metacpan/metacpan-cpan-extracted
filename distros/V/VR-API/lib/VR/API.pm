package VR::API;
use strict;

use SOAP::Lite;

our $VERSION = '1.06';

sub _uri {
    'VR/API/1_0'
}

sub _methods {
    qw(
        addListMember
        appendFileToList
        appendFileToListBackground
        appendTemplateCampaignModule
        calculateCampaignAudience
        canCallMethod
        checkFreeformContent
        compileCampaignRecipientResults
        compileCampaignRecipientResultsBackground
        createEmailCampaign
        createList
        createOptinForm
        deleteCampaign
        deleteList
        deleteListMember
        deleteTemplateCampaignModule
        downloadCampaignRecipientResults
        downloadCampaignRecipientResultsBackground
        downloadCompanyUnsubscribesAndBounces
        downloadList
        downloadListBackground
        editCompany
        editListAttribute
        editListMember
        editUser
        enumerateEmailCampaigns
        enumerateLists
        enumeratePostcardCampaigns
        eraseListMembers
        getCampaignDomainCount
        getCompany
        getEmailCampaignDeclineHistory
        getEmailCampaignResponseHistograms
        getEmailCampaignStats
        getEmailCreditBalance
        getListDomainCount
        getListMemberByAddressHash
        getListMemberByEmailAddress
        getListMemberByEmailAddress
        getListMemberByHash
        getListMembers
        getUser
        getUserByEmailAddress
        launchEmailCampaign
        login
        refresh
        renderCampaignContent
        searchListMembers
        sendEmailCampaignTest
        setCampaignLists
        setCustomListFields
        setDisplayedListFields
        setEmailCampaignAttribute
        setEmailCampaignContent
        setIndexedListFields
        setTemplateCampaignModule
        transferEmailCredits
        undeleteCampaign
        undeleteList
        unlaunchEmailCampaign
        validateStreetAddress
    );
}

sub _on_fault {
    my($soap, $res) = @_;
    if( ref( $res ) ) {
        my $error_string = "";
        if( $soap->endpoint ) {
            $error_string .= "Error while communicating with " . $soap->endpoint . " - ";
        }
        if( $res->faultcode ) {
            $error_string .= "SOAP Fault Code: " . $res->faultcode . ": ";
        }
        if( $res->faultstring ) {
            $error_string .= "SOAP Fault String: " . $res->faultstring . " - ";
        }
        die $error_string;
    } else {
        die $soap->transport->status;
    }
}

sub _on_debug {
    foreach( @_ ) {
        print $_, "\n";
    }
}

sub _getAction {
    my $self = shift;
    my $method = shift;
    $self->_uri . "#" . $method;
}

sub _getArgsType {
    my $self = shift;
    my $method = shift;
    if( $method =~ /^(.+)Background$/ ) {
        return 'vrtypens:' . $1 . 'Args';
    } else {
        return 'vrtypens:' . $method . "Args";
    }
}

sub _call {
    my $self = shift;
    my $method = shift;
    my $args = shift;

    my $qualified_args = SOAP::Data->name( 'args' )
                                   ->value( $args )
                                   ->type( $self->_getArgsType( $method ) )
                                   ->attr( {'xmlns:vrtypens' =>  'http://api.verticalresponse.com/1.0/VRAPI' } );

    my $som = $self->client
                   ->proxy( $self->endpoint )
                   ->endpoint( $self->endpoint )
                   ->uri( $self->_uri )
                   ->on_action( sub { __PACKAGE__->_getAction( $method ) } )
                   ->call( $method => $qualified_args );

    if( $som && ref( $som ) && $som->isa( 'SOAP::SOM') ) {
        # Remember the session_id from login() calls
        $self->session_id( $som->result ) if( 'login' eq $method );
        return wantarray ? $som->paramsall : $som->result;
    } else {
        return $som;
    }
}

sub new {
    my $self = shift;
    my $client = SOAP::Lite->new->on_fault( \&VR::API::_on_fault );
    # For debugging, uncomment the line below
    # $client->on_debug( \&VR::API::_on_debug );
    my $object = bless { 
        _client => $client,
        _endpoint => ($ENV{VR_API_SOAP_ENDPOINT} || 'https://api.verticalresponse.com/1.0/VRAPI'),
        _session_id => undef,
    }, $self;
    return $object;
}

sub logout {
    my $self = shift;
    delete $self->{_session_id};
}

sub client {
    my $self = shift;
    if( @_ ) {
        my $old = $self->{_client};
        $self->{_client} = shift @_;
        return $old;
    } else {
        return $self->{_client};
    }
}

sub endpoint {
    my $self = shift;
    if( @_ ) {
        my $old = $self->{_endpoint};
        $self->{_endpoint} = shift @_;
        return $old;
    } else {
        return $self->{_endpoint};
    }
}

sub session_id {
    my $self = shift;
    if( @_ ) {
        my $old = $self->{_session_id};
        $self->{_session_id} = shift @_;
        return $old;
    } else {
        return $self->{_session_id};
    }
}

sub _manufacture_methods {
    my $package_name = shift;

    foreach my $method ( $package_name->_methods ) {
        next if( $package_name->can( $method ) );
        my $code = qq{
package $package_name;
sub $method {
    my \$self = shift;
    my \$args = shift || { };
    die __PACKAGE__ . "::$method: requires a single hashref argument" unless( 'HASH' eq ref(\$args) );

    if( 'login' eq "$method" ) {
        return \$self->_call( "login" => \$args );
    } else {
        die __PACKAGE__ . "::$method: Not logged in" unless( defined( \$self->session_id ) );
        return \$self->_call( "$method" => { session_id => \$self->session_id, %\$args } );
    }

}
        };

        eval( $code );
    }

}

sub BEGIN {
    VR::API::_manufacture_methods( __PACKAGE__ );
}

1;

__END__

=head1 NAME

VR::API - Communicate with VerticalResponse's API services

=head1 SYNOPSIS

VR::API provides simplified access to the VerticalResponse API services server. It is
based on the SOAP::Lite package, a widely-used SOAP toolkit for Perl.

=head2 Example
 
    #!/usr/bin/perl -w
    use strict;
    use VR::API;

    my $vrapi = new VR::API;
    $vrapi->login( { username => 'nick@verticalresponse.com', password => 'super_secret' } );

    $vrapi->createList( {
        name => "A new list",
        type => "email",
    } );

=head2 Available functions

See VR::API::_methods() for a list of available functions. These functions
correspond to the functions listed in the VR API Enterprise WSDL file.

Note that it is not necessary to send the 'session_id' parameter with each
method call; the VR::API infrastructure does that automatically after a
successful call to login().

=head2 References

Enterprise API:

L<https://api.verticalresponse.com/wsdl/1.0/VRAPI.wsdl>
L<https://api.verticalresponse.com/wsdl/1.0/documentation.html>

=head1 SEE ALSO

L<VR::API::Partner>, the VR Partner API Perl module

=head1 BUGS

No known bugs. Please report bugs to api-support@verticalresponse.com

=head1 CREDITS

Paul Kulchenko and Bryce Harrington, for writing a fantastic SOAP toolkit in Perl.
Wes Bailey for help with CPAN and packaging.

=head1 MAINTAINER

Nick Marden <nick@verticalresponse.com>

=head1 COPYRIGHT

Copyright (C) 2007, Nick Marden, VerticalResponse Inc.

VR::API is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

VR::API.pm is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=cut
