package WWW::eNom::Role::Command::Service;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( Bool Domain DomainName PositiveInt );

use DateTime::Format::DateParse;
use Math::Currency;
use POSIX qw( ceil );

use Try::Tiny;
use Carp;

requires 'submit', '_set_domain_auto_renew', 'get_domain_by_name';

our $VERSION = 'v2.6.0'; # VERSION
# ABSTRACT: Addon Services That Can Be Purchased

sub get_domain_privacy_wholesale_price {
    my $self = shift;

    return try {
        my $response = $self->submit({
            method => 'PE_GetProductPrice',
            params => {
                ProductType => 72,
            },
        });

        if( $response->{ErrCount} > 0 ) {
            croak 'Unknown error';
        }

        if( !exists $response->{productprice}{price} ) {
            croak 'Response did not contain price info';
        }

        return Math::Currency->new( $response->{productprice}{price} );
    }
    catch {
        croak $_;
    };
}

sub purchase_domain_privacy_for_domain {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_name   => { isa => DomainName },
        years         => { isa => PositiveInt, default => 1 },
        is_auto_renew => { isa => Bool,        default => 0 },
    );

    return try {
        my $response = $self->submit({
            method => 'PurchaseServices',
            params => {
                Service   => 'WPPS',
                Domain    => $args{domain_name},
                NumYears  => $args{years},
                RenewName => ( $args{is_auto_renew} ? 1 : 0 ),
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            if( grep { $_ eq 'ID Protection is already active for this domain' } @{ $response->{errors} } ) {
                croak 'Domain privacy is already purchased for this domain';
            }

            croak 'Unknown error';
        }

        return $response->{OrderID};
    }
    catch {
        croak $_;
    };
}

sub get_is_privacy_purchased_by_name {
    my $self            = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetWPPSInfo',
            params => {
                Domain => $domain_name
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }
        }

        return !!( $response->{GetWPPSInfo}{WPPSExists} == 1 );
    }
    catch {
        croak $_;
    };
}

sub enable_privacy_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    if( !$self->get_is_privacy_purchased_by_name( $domain_name ) ) {
        my $domain = $self->get_domain_by_name( $domain_name );
        my $years  = $domain->expiration_date->year - DateTime->now->year;
        $years == 0 and $years = 1;

        $self->purchase_domain_privacy_for_domain(
            domain_name   => $domain_name,
            years         => $years,
            is_auto_renew => $domain->is_auto_renew,
        );
    }
    else {
        try {
            my $response = $self->submit({
                method => 'EnableServices',
                params => {
                    Domain  => $domain_name,
                    Service => 'WPPS',
                }
            });

            if( $response->{ErrCount} > 0 ) {
                if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                    croak 'Domain not found in your account';
                }

                if( grep { $_ eq 'Unable to activate service for this domain' } @{ $response->{errors} } ) {
                    # NO OP
                    return;
                }

                croak 'Unknown error';
            }
        }
        catch {
            croak $_;
        };
    }

    return $self->get_domain_by_name( $domain_name );
}

sub disable_privacy_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    try {
        my $response = $self->submit({
            method => 'DisableServices',
            params => {
                Domain  => $domain_name,
                Service => 'WPPS',
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            if(    ( grep { $_ eq 'ID Protect is not purchased for this domain' } @{ $response->{errors} } )
                || ( grep { $_ eq 'Unable to disable service for this domain' } @{ $response->{errors} } ) ) {
                # NO OP
                return;
            }

            croak 'Unknown error';
        }
    }
    catch {
        croak $_;
    };

    return $self->get_domain_by_name( $domain_name );
}

sub get_is_privacy_auto_renew_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetWPPSInfo',
            params => {
                Domain => $domain_name
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }
        }

        if( $response->{GetWPPSInfo}{WPPSExists} == 0 ) {
            croak 'Domain does not have privacy';
        }

        if( !$response->{GetWPPSInfo}{WPPSAutoRenew} ) {
            croak 'Response did not contain privacy renewal data';
        }

        return !!( $response->{GetWPPSInfo}{WPPSAutoRenew} eq 'Yes' );
    }
    catch {
        croak $_;
    };
}

sub get_privacy_expiration_date_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetWPPSInfo',
            params => {
                Domain => $domain_name
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }
        }

        if( $response->{GetWPPSInfo}{WPPSExists} == 0 ) {
            croak 'Domain does not have privacy';
        }

        if( !$response->{GetWPPSInfo}{WPPSExpDate} ) {
            croak 'Response did not contain privacy expiration data';
        }

        return DateTime::Format::DateParse->parse_datetime( $response->{GetWPPSInfo}{WPPSExpDate} );
    }
    catch {
        croak $_;
    };
}

sub enable_privacy_auto_renew_for_domain {
    my $self       = shift;
    my ( $domain ) = pos_validated_list( \@_, { isa => Domain } );

    my $current_is_privacy_auto_renew  = $self->get_is_privacy_auto_renew_by_name( $domain->name );
    if( $current_is_privacy_auto_renew ) {
        return $domain;
    }

    return $self->_set_domain_auto_renew({
        domain_name           => $domain->name,
        is_auto_renew         => $domain->is_auto_renew,
        privacy_is_auto_renew => 1,
    });
}

sub disable_privacy_auto_renew_for_domain {
    my $self       = shift;
    my ( $domain ) = pos_validated_list( \@_, { isa => Domain } );

    my $current_is_privacy_auto_renew  = $self->get_is_privacy_auto_renew_by_name( $domain->name );
    if( !$current_is_privacy_auto_renew ) {
        return $domain;
    }

    return $self->_set_domain_auto_renew({
        domain_name           => $domain->name,
        is_auto_renew         => $domain->is_auto_renew,
        privacy_is_auto_renew => 0,
    });
}

sub renew_privacy {
    my $self     = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_name => { isa => DomainName },
        years       => { isa => PositiveInt },
    );

    return try {
        my $response = $self->submit({
            method => 'RenewServices',
            params => {
                Service   => 'WPPS',
                Domain    => $args{domain_name},
                NumYears  => $args{years},
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            if( grep { $_ eq 'Unable to renew ID Protect for this domain.' } @{ $response->{errors} } ) {
                croak 'Domain does not have privacy';
            }

            if( grep { $_ =~ qr/The number of years cannot/ } @{ $response->{errors} } ) {
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

1;

__END__

=pod

=head1 NAME

WWW::eNom::Role::Command::Service - Addon Services That Can Be Purchased

=head1 SYNOPSIS

    use WWW::eNom;

    my $api = WWW::eNom->new( ... );

    # Get wholesale price for Domain privacy
    my $domain_privacy_wholesale_price = $api->get_domain_privacy_wholesale_price();

    # Purchase Domain Privacy
    my $order_id = $api->purchase_domain_privacy_for_domain( 'drzigman.com' );

    # Get If Privacy Has Been Purchased
    my $is_privacy_purchased = $api->get_is_privacy_purchased_by_name( 'drzigman.com' );

    # Enable Domain Privacy
    my $updated_domain = $api->enable_privacy_by_name( 'drzigman.com' );

    # Disable Domain Privacy
    my $updated_domain = $api->disable_privacy_by_name( 'drzigman.com' );

    # Get Privacy Expiration Date
    my $privacy_expiration_date = $api->get_privacy_expiration_date_by_name( 'drzigman.com' );

    # Get is Privacy Auto Renew
    my $is_privacy_auto_renew = $api->get_is_privacy_auto_renew_by_name( 'drzigman.com' );

    my $domain = WWW::eNom::Domain->new( ... );

    # Enable Auto Renew for Domain Privacy
    my $updated_domain = $api->enable_privacy_auto_renew_for_domain( $domain );

    # Disable Auto Renew for Domain Privacy
    my $updated_domain = $api->disable_privacy_auto_renew_for_domain( $domain );

    # Renew Domain privacy
    my $order_id = $api->renew_privacy({
        domain_name => 'drzigman.com',
        years       => 1,
    });

=head1 REQUIRES

=over 4

=item submit

=back

=head1 DESCRIPTION

Implements addon service related API calls (such as L<WPPS Service|https://www.enom.com/api/Value%20Added%20Topics/ID%20Protect.htm>, what eNom calls Privacy Protection).

=head1 METHODS

=head2 get_domain_privacy_wholesale_price

    use Math::Currency;

    my $domain_privacy_wholesale_price = $api->get_domain_privacy_wholesale_price();

Returns the wholesale price per year (the price you as the reseller pay, not what you want to charge your customers) for domain privacy as a Math::Currency object.

=head2 purchase_domain_privacy_for_domain

    # Be sure to wrap this in a try/catch block, presented here for clarity
    my $order_id = $api->purchase_domain_privacy_for_domain( 'drzigman.com' );

Abstraction of the L<PurchaseServices for ID Protect|https://www.enom.com/api/API%20topics/api_PurchaseServices.htm#input> eNom API Call.  Given a FQDN, attempts to purchase Domain Privacy for the specified domain.  On success, the OrderID of this purchase is returned.

There are several reason this method could fail and croak.

=over 4

=item Domain not found in account

=item Domain privacy is already purchased for this domain

=item Unknown error

This is almost always caused by attempting to add privacy protection to a public suffix that does not support it.

=back

Noting this, consumers should take care to ensure safe handling of these potential errors.

=head2 get_is_privacy_purchased_by_name

    my $is_privacy_purchased = $api->get_is_privacy_purchased_by_name( 'drzigman.com' );

Abstraction of the L<GetWPPSInfo|https://www.enom.com/api/API%20topics/api_GetWPPSInfo.htm> eNom API Call.  Given a FQDN, returns a truthy value if privacy has been purchased B<regardless of if it is active or not> and a falsey value if privacy has not been purchased B<regardless of it is active or not>.

If the domain is not registered or is registered to someone else this method will croak.


=head2 enable_privacy_by_name

    my $updated_domain = $api->enable_privacy_by_name( 'drzigman.com' );

Abstraction of the L<EnableServices|https://www.enom.com/api/API%20topics/api_EnableServices.htm> eNom API Call.  Given a FQDN, enables Domain Privacy for it.  If privacy is already active this method is effectively a NO OP.  B<If domain privacy has not been purchased for this domain, this method will buy and activate it automatically.  In this case the auto renew will match that of the domain and enough Domain Privacy will be purchased to cover the registration length remaining>.  Domain privacy is not free, so you may wish to check L<get_is_privacy_purchased_by_name> before making this call if you do not wish to purchase privacy.

If the domain is not registered or is registered to someone else this method will croak.

=head2 disable_privacy_by_name

    my $updated_domain = $api->disable_privacy_by_name( 'drzigman.com' );

Abstraction of the L<DisableServices|https://www.enom.com/api/API%20topics/api_DisableServices.htm> eNom API Call.  Given a FQDN, disables Domain Privacy for it.  If privacy is not currently active (or if it has never been purchased for this domain) this method is effective a NO OP.

If the domain is not registered or is registered to someone else this method will croak.

=head2 get_is_privacy_auto_renew_by_name

    my $is_privacy_auto_renew = $api->get_is_privacy_auto_renew_by_name( 'drzigman.com' );

Abstraction of the L<GetWPPSInfo|https://www.enom.com/api/API%20topics/api_GetWPPSInfo.htm> eNom API Call.  Given a FQDN, returns a truthy value if auto renew is enabled for domain privacy and a falsey value if auto renew is disabled for domain privacy.

If the domain is not registered or is registered to someone else this method will croak.

B<NOTE> If the specified domain does not have domain privacy this method will croak with the message 'Domain does not have privacy'.

=head2 get_privacy_expiration_date_by_name

    my $privacy_expiration_date = $api->get_privacy_expiration_date_by_name( 'drzigman.com' );

Abstraction of the L<GetWPPSInfo|https://www.enom.com/api/API%20topics/api_GetWPPSInfo.htm> eNom API Call.  Given a FQDN, returns a DateTime object representing when domain privacy will expire.

If the domain is not registered or is registered to someone else this method will croak.

B<NOTE> If the specified domain does not have domain privacy this method will croak with the message 'Domain does not have privacy'.

=head2 enable_privacy_auto_renew_for_domain

    my $domain         = WWW::eNom::Domain->new( ... );
    my $updated_domain = $api->enable_privacy_auto_renew_for_domain( $domain );

Abstraction of the L<SetRenew|https://www.enom.com/api/API%20topics/api_SetRenew.htm> eNom API Call.  Given an instance of L<WWW::eNom::Domain> enables auto renew of domain privacy.  If the domain privacy is already set to auto renew this method is effectively a NO OP.

B<NOTE> If the specified domain does not have domain privacy this method will croak with the message 'Domain does not have privacy'.

=head2 disable_privacy_auto_renew_for_domain

    my $domain         = WWW::eNom::Domain->new( ... );
    my $updated_domain = $api->disable_privacy_auto_renew_for_domain( $domain );

Abstraction of the L<SetRenew|https://www.enom.com/api/API%20topics/api_SetRenew.htm> eNom API Call.  Given an instance of L<WWW::eNom::Domain> disables auto renew of domain privacy.  If the domain privacy is already set not to auto renew this method is effectively a NO OP.

If the domain is not registered or is registered to someone else this method will croak.

B<NOTE> If the specified domain does not have domain privacy this method will croak with the message 'Domain does not have privacy'.

=head2 renew_privacy

    my $order_id = $api->renew_privacy({
        domain_name => 'drzigman.com',
        years       => 1,
    });

Abstraction of the L<RenewServices|https://www.enom.com/api/API%20topics/api_RenewServices.htm> eNom API Call.  Given a FQDN and a number of years, renews domain privacy.  Returned is the order id.

There are several reasons this method could croak:

=over 4

=item Requested renewal too long

If you request a renewal longer than 10 years.

=item Domain does not have privacy

If the domain does not have privacy

=back

If the domain is not registered or is registered to someone else this method will croak.

=cut
