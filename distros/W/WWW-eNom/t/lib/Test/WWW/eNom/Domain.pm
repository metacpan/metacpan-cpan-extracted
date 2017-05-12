package Test::WWW::eNom::Domain;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MooseX::Params::Validate;
use String::Random qw( random_string );

use WWW::eNom::Types qw( Bool Contact DomainName DomainNames PositiveInt Str TransferVerificationMethod );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Contact qw( create_contact $DEFAULT_CONTACT );

use WWW::eNom::Domain;
use WWW::eNom::DomainTransfer;
use WWW::eNom::DomainRequest::Registration;
use WWW::eNom::DomainRequest::Transfer;

use DateTime;

use Readonly;
Readonly our $UNREGISTERED_DOMAIN => WWW::eNom::Domain->new(
    id                  => 42,
    name                => 'NOT-REGISTERED-' . random_string('ccnnccnnccnnccnnccnnccnnccnn') . '.com',
    status              => 'Paid',
    verification_status => 'Pending Suspension',
    is_auto_renew       => 0,
    is_locked           => 1,
    is_private          => 0,
    created_date        => DateTime->now,
    expiration_date     => DateTime->now->add( years => 1 ),
    ns                  => [ 'ns1.enom.com', 'ns2.enom.com' ],
    registrant_contact  => $DEFAULT_CONTACT,
    admin_contact       => $DEFAULT_CONTACT,
    technical_contact   => $DEFAULT_CONTACT,
    billing_contact     => $DEFAULT_CONTACT,
);

Readonly our $NOT_MY_DOMAIN => WWW::eNom::Domain->new(
    id                  => 42,
    name                => 'enom.com',
    status              => 'Paid',
    verification_status => 'Pending Suspension',
    is_auto_renew       => 0,
    is_locked           => 1,
    is_private          => 0,
    created_date        => DateTime->now,
    expiration_date     => DateTime->now->add( years => 1 ),
    ns                  => [ 'ns1.enom.com', 'ns2.enom.com' ],
    registrant_contact  => $DEFAULT_CONTACT,
    admin_contact       => $DEFAULT_CONTACT,
    technical_contact   => $DEFAULT_CONTACT,
    billing_contact     => $DEFAULT_CONTACT,
);

use Exporter 'import';
our @EXPORT_OK = qw(
    create_domain create_transfer
    retrieve_domain_with_cron_delay
    $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN
);

sub create_domain {
    my ( %args ) = validated_hash(
        \@_,
        name                => { isa => DomainName,         optional => 1 },
        ns                  => { isa => DomainNames,        optional => 1 },
        is_locked           => { isa => Bool,               optional => 1 },
        is_private          => { isa => Bool,               optional => 1 },
        is_auto_renew       => { isa => Bool,               optional => 1 },
        years               => { isa => PositiveInt,        optional => 1 },
        registrant_contact  => { isa => Contact,            optional => 1 },
        admin_contact       => { isa => Contact,            optional => 1 },
        technical_contact   => { isa => Contact,            optional => 1 },
        billing_contact     => { isa => Contact,            optional => 1 },
    );

    $args{name}               //= 'test-' . random_string('nnccnnccnnccnnccnnccnncc') . '.com';
    $args{ns}                 //= [ 'ns1.enom.com', 'ns2.enom.com' ];
    $args{is_locked}          //= 1;
    $args{years}              //= 1;
    $args{registrant_contact} //= create_contact( first_name => 'Before', last_name => 'Change' );
    $args{admin_contact}      //= create_contact();
    $args{technical_contact}  //= create_contact();
    $args{billing_contact}    //= create_contact();

    my $api = create_api();

    my $domain;
    subtest 'Create Domain' => sub {
        my $request;
        lives_ok {
            $request = WWW::eNom::DomainRequest::Registration->new( %args );
        } 'Lives through creating request object';

        lives_ok {
            $domain = $api->register_domain( request => $request );
        } 'Lives through domain registration';

        note( 'Domain ID: ' . $domain->id );
        note( 'Domain Name: ' . $domain->name );
    };

    return $domain;

}

sub create_transfer {
    my ( %args ) = validated_hash(
        \@_,
        name                  => { isa => DomainName,  optional => 1 },
        verification_method   => { isa => TransferVerificationMethod, optional => 1 },
        is_private            => { isa => Bool,        optional => 1 },
        is_locked             => { isa => Bool,        optional => 1 },
        is_auto_renew         => { isa => Bool,        optional => 1 },
        epp_key               => { isa => Str,         optional => 1 },
        use_existing_contacts => { isa => Bool,        optional => 1 },
        registrant_contact    => { isa => Contact,     optional => 1 },
        admin_contact         => { isa => Contact,     optional => 1 },
        technical_contact     => { isa => Contact,     optional => 1 },
        billing_contact       => { isa => Contact,     optional => 1 },
    );


    $args{name}    //= 'test-' . random_string('nnccnnccnnccnnccnnccnncc') . '.com';
    $args{epp_key} //= '12345';

    if( !exists $args{use_existing_contacts} ) {
        $args{registrant_contact} //= create_contact();
        $args{admin_contact}      //= create_contact();
        $args{technical_contact}  //= create_contact();
        $args{billing_contact}    //= create_contact();
    }

    my $api = create_api();

    my $transfer;
    subtest 'Create Transfer' => sub {
        my $request;
        lives_ok {
            $request = WWW::eNom::DomainRequest::Transfer->new( %args );
        } 'Lives through creating request object';

        lives_ok {
            $transfer = $api->transfer_domain( request => $request );
        } 'Lives through domain transfer';

        note( 'Transfer Order ID: ' . $transfer->order_id );
        note( 'Transfer Domain Name: ' . $transfer->name );
    };

    return $transfer;
}

sub retrieve_domain_with_cron_delay {
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    my $api = create_api();

    note('Waiting for eNom to Process Contact Change...');

    sleep 10;

    for my $seconds_waited ( 1 .. 60 ) {
        if( DateTime->now->second > 5 && DateTime->now->second < 10 ) {
            return $api->get_domain_by_name( $domain_name );
        }
        else {
            if( $seconds_waited % 5 == 0 ) {
                note("Waited $seconds_waited seconds - " . DateTime->now->datetime );
            }

            sleep 1;
        }
    }
}

1;
