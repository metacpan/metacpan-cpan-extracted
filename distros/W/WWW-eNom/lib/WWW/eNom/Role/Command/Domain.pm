package WWW::eNom::Role::Command::Domain;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( Bool DomainName DomainNames PositiveInt );

use WWW::eNom::Domain;

use Data::Util qw( is_array_ref );
use DateTime::Format::DateParse;
use Mozilla::PublicSuffix qw( public_suffix );
use Try::Tiny;
use Carp;

requires 'submit', 'get_contacts_by_domain_name', 'delete_private_nameserver';

our $VERSION = 'v2.6.0'; # VERSION
# ABSTRACT: Domain Related Operations

sub get_domain_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetDomainInfo',
            params => {
                Domain => $domain_name,
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            croak 'Unknown error';
        }

        if( !exists $response->{GetDomainInfo} ) {
            croak 'Response did not contain domain info';
        }

        # There is no way to ask eNom what the private nameservers are so we use
        # the fact that they must have the same root domain in order to differentiate
        # between private and "regular" nameservers
        my $nameservers = $self->get_domain_name_servers_by_name( $domain_name );
        my @private_nameservers = map {
            $self->retrieve_private_nameserver_by_name( $_ )
        } grep { $_ =~ m/\Q$domain_name/ } @{ $nameservers };

        return WWW::eNom::Domain->construct_from_response(
            domain_info   => $response->{GetDomainInfo},
            is_auto_renew => $self->get_is_domain_auto_renew_by_name( $domain_name ),
            is_locked     => $self->get_is_domain_locked_by_name( $domain_name ),
            name_servers  => $nameservers,
            scalar @private_nameservers ? ( private_nameservers => \@private_nameservers ) : ( ),
            contacts      => $self->get_contacts_by_domain_name( $domain_name ),
            created_date  => $self->get_domain_created_date_by_name( $domain_name ),
        );
    }
    catch {
        croak $_;
    };
}

sub get_is_domain_locked_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetRegLock',
            params => {
                Domain => $domain_name,
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( $response->{RRPText} =~ m/Command blocked/ ) {
                croak 'Domain owned by someone else';
            }

            if( $response->{RRPText} =~ m/Object does not exist/ ) {
                croak 'Domain is not registered';
            }

            croak $response->{RRPText};
        }

        if( !exists $response->{'reg-lock'} ) {
            croak 'Response did not contain lock data';
        }

        return !!$response->{'reg-lock'};
    }
    catch {
        croak $_;
    };
}

sub enable_domain_lock_by_name {
    my $self            = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return $self->_set_domain_locking(
        domain_name => $domain_name,
        is_locked   => 1,
    );
}

sub disable_domain_lock_by_name {
    my $self            = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return $self->_set_domain_locking(
        domain_name => $domain_name,
        is_locked   => 0,
    );
}

sub _set_domain_locking {
    my $self     = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_name => { isa => DomainName },
        is_locked   => { isa => Bool },
    );

    return try {
        my $response = $self->submit({
            method => 'SetRegLock',
            params => {
                Domain          => $args{domain_name},
                UnlockRegistrar => ( !$args{is_locked} ? 1 : 0 ),
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            if( grep { $_ =~ m/domain is already/ } @{ $response->{errors} } ) {
                # NO OP, what I asked for is already done
            }
        }

        return $self->get_domain_by_name( $args{domain_name} );
    }
    catch {
        croak "$_";
    };
}

sub get_domain_name_servers_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetDNS',
            params => {
                Domain => $domain_name,
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            elsif( grep { $_ eq 'This domain name is expired and cannot be updated' } @{ $response->{errors} } ) {
                return [ ];
            }

            croak 'Unknown error';
        }

        if( !exists $response->{dns} ) {
            croak 'Response did not contain nameserver data';
        }

        # If there is only one NS convert the scalar to an arrayref
        return is_array_ref( $response->{dns} ) ? $response->{dns} : [ $response->{dns} ];
    }
    catch {
        croak $_;
    };
}

sub update_nameservers_for_domain_name {
    my $self     = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_name => { isa => DomainName },
        ns          => { isa => DomainNames },
    );

    try {
        my @initial_private_nameserver_names = grep {
            $_ =~ m/\Q$args{domain_name}/
        } @{ $self->get_domain_name_servers_by_name( $args{domain_name} ) };

        my $response = $self->submit({
            method => 'ModifyNS',
            params => {
                Domain => $args{domain_name},
                map { 'NS' . ( $_ + 1 ) => $args{ns}->[ $_ ] } 0 .. ( scalar (@{ $args{ns} }) - 1)
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            if( grep { $_ =~ m/could not be registered/ } @{ $response->{errors} } ) {
                croak 'Invalid Nameserver provided';
            }

            croak 'Unknown error';
        }

        # Delete private nameservers that are no longer being used as authoritative
        for my $private_nameserver_name ( @initial_private_nameserver_names ) {
            if( grep { $_ eq $private_nameserver_name } @{ $args{ns} } ) {
                next;
            }

            $self->delete_private_nameserver(
                domain_name             => $args{domain_name},
                private_nameserver_name => $private_nameserver_name,
            );
        }
    }
    catch {
        croak $_;
    };


    return $self->get_domain_by_name( $args{domain_name} );
}

sub get_is_domain_auto_renew_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetRenew',
            params => {
                Domain => $domain_name,
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }
            elsif( grep { $_ eq 'This domain name is expired and cannot be updated' } @{ $response->{errors} } ) {
                return !!0;
            }

            croak 'Unknown error';
        }

        if( !exists $response->{'auto-renew'} ) {
            croak 'Response did not contain renewal data';
        }

        return !!$response->{'auto-renew'};
    }
    catch {
        croak $_;
    };
}

sub enable_domain_auto_renew_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return $self->_set_domain_auto_renew({
        domain_name   => $domain_name,
        is_auto_renew => 1,
    });
}

sub disable_domain_auto_renew_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return $self->_set_domain_auto_renew({
        domain_name   => $domain_name,
        is_auto_renew => 0,
    });
}

sub _set_domain_auto_renew {
    my $self     = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_name           => { isa => DomainName },
        is_auto_renew         => { isa => Bool },
        privacy_is_auto_renew => { isa => Bool, optional => 1 },
    );

    return try {
        my $response = $self->submit({
            method => 'SetRenew',
            params => {
                Domain    => $args{domain_name},
                RenewFlag => ( $args{is_auto_renew} ? 1 : 0 ),
                defined $args{privacy_is_auto_renew} ? ( WPPSRenew => ( $args{privacy_is_auto_renew} ? 1 : 0 ) ) : ( ),
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }
        }

        return $self->get_domain_by_name( $args{domain_name} );
    }
    catch {
        croak "$_";
    };

}

sub get_domain_created_date_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetWhoisContact',
            params => {
                Domain => $domain_name,
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'No results found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            croak 'Unknown error';
        }

        if( !exists $response->{GetWhoisContacts}{'rrp-info'}{'created-date'} ) {
            croak 'Response did not contain creation data';
        }

        return DateTime::Format::DateParse->parse_datetime( $response->{GetWhoisContacts}{'rrp-info'}{'created-date'}, 'UTC' );

    }
    catch {
        croak $_;
    };

}

sub renew_domain {
    my $self     = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_name => { isa => DomainName },
        years       => { isa => PositiveInt },
    );

    return try {
        my $response = $self->submit({
            method => 'Extend',
            params => {
                Domain    => $args{domain_name},
                NumYears  => $args{years},
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            if(    ( grep { $_ =~ qr/The number of years cannot/ } @{ $response->{errors} } )
                || ( grep { $_ =~ qr/cannot be extended/ } @{ $response->{errors} } ) ) {
                croak 'Requested renewal too long';
            }

            croak 'Unknown error';
        }

        return $response->{OrderID};
    }
    catch {
        croak $_;
    };
}

sub email_epp_key_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetSubAccountPassword',
            params => {
                Domain => $domain_name,
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain is not available to get password' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            croak 'Unknown error';
        }

        # If there are no errors, assume success
        return;
    }
    catch {
        croak $_;
    };
}

1;

__END__

=pod

=head1 NAME

WWW::eNom::Role::Command::Domain - Domain Related Operations

=head1 SYNOPSIS

    use WWW::eNom;
    use WWW::eNom::Domain;

    my $api = WWW::eNom->new( ... );

    # Get a fully formed WWW::eNom::Domain object for a domain
    my $domain = $api->get_domain_by_name( 'drzigman.com' );


    # Check if a domain is locked
    if( $api->get_is_domain_locked_by_name( 'drzigman.com' ) ) {
        print "Domain is Locked!\n";
    }
    else {
        print "Domain is NOT Locked!\n";
    }

    # Lock Domain
    my $updated_domain = $api->enable_domain_lock_by_name( 'drzigman.com' );

    # Unlock Domain
    my $updated_domain = $api->disable_domain_lock_by_name( 'drzigman.com' );


    # Get domain authoritative nameservers
    for my $ns ( $api->get_domain_name_servers_by_name( 'drzigman.com' ) ) {
        print "Nameserver: $ns\n";
    }

    # Update Domain Nameservers
    my $updated_domain = $api->update_nameservers_for_domain_name({
        domain_name => 'drzigman.com',
        ns          => [ 'ns1.enom.org', 'ns2.enom.org' ],
    });


    # Get auto renew status
    if( $api->get_is_domain_auto_renew_by_name( 'drzigman.com' ) ) {
        print "Domain will be auto renewed!\n";
    }
    else {
        print "Domain will NOT be renewed automatically!\n";
    }

    # Enable domain auto renew
    my $updated_domain = $api->enable_domain_auto_renew_by_name( 'drzigman.com' );

    # Disable domain auto renew
    my $updated_domain = $api->disable_domain_auto_renew_by_name( 'drzigman.com' );

    # Renew Domain
    my $order_id = $api->renew_domain({
        domain_name => 'drzigman.com',
        years       => 1,
    });

    # Get Created Date
    my $created_date = $api->get_domain_created_date_by_name( 'drzigman.com' );
    print "This domain was created on: " . $created_date->ymd . "\n";

    # Email EPP Key to Registrant Contact
    try { $api->email_epp_key_by_name( 'drzigman.com' ) }
    catch {
        ...;
    };

=head1 REQUIRES

=over 4

=item submit

=item get_contacts_by_domain_name

Needed in order to construct a full L<WWW::eNom::Domain> object.

=item delete_private_nameserver

Needed in order to keep private nameservers and authoritative nameservers in sync.

=back

=head1 DESCRIPTION

Implements domain related operations with the L<eNom|https://www.enom.com> API.

=head2 See Also

=over 4

=item For Domain Registration please see L<WWW::eNom::Role::Command::Domain::Registration>

=item For Domain Availability please see L<WWW::eNom::Role::Command::Domain::Availability>

=back

=head1 METHODS

=head2 get_domain_by_name

    my $domain = $api->get_domain_by_name( 'drzigman.com' );

At it's core, this is an Abstraction of the L<GetDomainInfo|https://www.enom.com/api/API%20topics/api_GetDomainInfo.htm> eNom API Call.  However, because this API Call does not return enough information to fully populate a L<WWW::eNom::Domain> object, internally the following additional methods are called:

=over 4

=item L<WWW::eNom::Role::Command::Domain/get_is_domain_auto_renew_by_name>

=item L<WWW::eNom::Role::Command::Domain/get_is_domain_locked_by_name>

=item L<WWW::eNom::Role::Command::Domain/get_domain_name_servers_by_name>

=item L<WWW::eNom::Role::Command::Domain/get_domain_created_date_by_name>

=item L<WWW::eNom::Role::Command::Contact/get_contacts_by_domain_name>

=back

Because of all of these API calls this method can be fairly slow (usually about a second or two).

Given a FQDN, this method returns a fully formed L<WWW::eNom::Domain> object.  If the domain does not exist in your account (either because it's registered by someone else or it's available) this method will croak.

=head2 get_is_domain_locked_by_name

    if( $api->get_is_domain_locked_by_name( 'drzigman.com' ) ) {
        print "Domain is Locked!\n";
    }
    else {
        print "Domain is NOT Locked!\n";
    }

Abstraction of the L<GetRegLock|https://www.enom.com/api/API%20topics/api_GetRegLock.htm> eNom API Call.  Given a FQDN, returns a truthy value if the domain is locked and falsey if it is not.

This method will croak if the domain is owned by someone else or if it is not registered.

=head2 enable_domain_lock_by_name

    my $updated_domain = $api->enable_domain_lock_by_name( 'drzigman.com' );

Abstraction of the L<SetRegLock|https://www.enom.com/api/API%20topics/api_SetRegLock.htm> eNom API Call.  Given a FQDN, enables the registrar lock for the provided domain.  If the domain is already locked this is effectively a NO OP.

This method will croak if the domain is owned by someone else or if it is not registered.

=head2 disable_domain_lock_by_name

    my $updated_domain = $api->disable_domain_lock_by_name( 'drzigman.com' );

Abstraction of the L<SetRegLock|https://www.enom.com/api/API%20topics/api_SetRegLock.htm> eNom API Call.  Given a FQDN, disabled the registrar lock for the provided domain.  If the domain is already unlocked this is effectively a NO OP.

This method will croak if the domain is owned by someone else or if it is not registered.

=head2 get_domain_name_servers_by_name

    for my $ns ( $api->get_domain_name_servers_by_name( 'drzigman.com' ) ) {
        print "Nameserver: $ns\n";
    }

Abstraction of the L<GetDNS|https://www.enom.com/api/API%20topics/api_GetDNS.htm> eNom API Call.  Given a FQDN, returns an ArrayRef of FQDNs that are the authoritative name servers for the specified FQDN.

This method will croak if the domain is owned by someone else or if it is not registered.

=head2 update_nameservers_for_domain_name

    my $updated_domain = $api->update_nameservers_for_domain_name({
        domain_name => 'drzigman.com',
        ns          => [ 'ns1.enom.org', 'ns2.enom.org' ],
    });

Abstraction of the L<ModifyNS|https://www.enom.com/api/API%20topics/api_ModifyNS.htm> eNom API Call.  Given a FQDN and an ArrayRef of FQDNs to use as nameservers, updates the nameservers and returns an updated version L<WWW::eNom::Domain>.

This method will croak if the domain is owned by someone else or if it is not registered.  It will also croak if you provide an invalid nameserver (such as ns1.some-domain-that-does-not-really-exist.com).

B<NOTE> If, during the update, you remove a private nameserver (by not including it in the ns ArrayRef) that private nameserver will be B<deleted>.  This is a limitation of L<eNom|https://www.enom.com>'s API.

=head2 get_is_domain_auto_renew_by_name

    if( $api->get_is_domain_auto_renew_by_name( 'drzigman.com' ) ) {
        print "Domain will be auto renewed!\n";
    }
    else {
        print "Domain will NOT be renewed automatically!\n";
    }

Abstraction of the L<GetRenew|https://www.enom.com/api/API%20topics/api_GetRenew.htm> eNom API Call.  Given a FQDN, returns a truthy value if auto renew is enabled for this domain (you want eNom to automatically renew this) or a falsey value if auto renew is not enabled for this domain.

This method will croak if the domain is owned by someone else or if it is not registered.

=head2 enable_domain_auto_renew_by_name

    my $updated_domain = $api->enable_domain_auto_renew_by_name( 'drzigman.com' );

Abstraction of the L<SetRenew|https://www.enom.com/api/API%20topics/api_SetRenew.htm> eNom API Call.  Given a FQDN, enables auto renew for the provided domain.  If the domain is already set to auto renew this is effectively a NO OP.

This method will croak if the domain is owned by someone else or if it is not registered.

=head2 disable_domain_auto_renew_by_name

    my $updated_domain = $api->disable_domain_auto_renew_by_name( 'drzigman.com' );

Abstraction of the L<SetRenew|https://www.enom.com/api/API%20topics/api_SetRenew.htm> eNom API Call.  Given a FQDN, disables auto renew for the provided domain.  If the domain is already set not to auto renew this is effectively a NO OP.

This method will croak if the domain is owned by someone else or if it is not registered.

=head2 get_domain_created_date_by_name

    my $created_date = $api->get_domain_created_date_by_name( 'drzigman.com' );

    print "This domain was created on: " . $created_date->ymd . "\n";

Abstraction of the L<GetWhoisContact|https://www.enom.com/api/API%20topics/api_GetWhoisContact.htm> eNom API Call.  Given a FQDN, returns a L<DateTime> object representing when this domain registration was created.

This method will croak if the domain is owned by someone else or if it is not registered.

=head2 renew_domain

    my $order_id = $api->renew_domain({
        domain_name => 'drzigman.com',
        years       => 1,
    });

Abstraction of the L<Extend|https://www.enom.com/api/API%20topics/api_Extend.htm> eNom API Call.  Given a FQDN and the number of years, renews the domain for the requested number of years returning the order_id.

B<NOTE> There is a limit as to how far into the future you can renew a domain (usually it's 10 years but that can vary based on the public suffix and the registry).  In the event you try to renew too far into the future this method will croak with 'Requested renewal too long'

This method will croak if the domain is owned by someone else or if it is not registered.

=head2 email_epp_key_by_name

    try { $api->email_epp_key_by_name( 'drzigman.com' ) }
    catch {
        ...;
    };

Abstraction of the L<GetSubAccountPassword|http://www.enom.com/api/API%20topics/api_GetSubAccountPassword.htm> eNom API Call.  Given a FQDN, emails the EPP Key to the email address listed for the registrant contact.

B<NOTE> Unfortunately, eNom provides no API method to get the actual EPP Key.  Instead, you must use this method to ask eNom to email the EPP Key to the registrant for you.

=cut
