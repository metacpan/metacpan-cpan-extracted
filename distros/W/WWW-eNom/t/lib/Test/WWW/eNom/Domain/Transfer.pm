package Test::WWW::eNom::Domain::Transfer;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockModule;
use String::Random qw( random_string );
use MooseX::Params::Validate;

use Test::WWW::eNom qw( mock_response create_api );
use Test::WWW::eNom::Contact qw( create_contact );
use Test::WWW::eNom::Service qw( mock_pe_getproductprice );

use WWW::eNom::Types qw( DomainName TransferVerificationMethod Bool Str Contact );

use WWW::eNom::DomainRequest::Transfer;

use Exporter 'import';
our @EXPORT_OK = qw(
    create_transfer
    mock_domain_transfer
    mock_tp_get_order_detail
);

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

        my $mocked_api = mock_domain_transfer( request => $request );

        lives_ok {
            $transfer = $api->transfer_domain( request => $request );
        } 'Lives through domain transfer';

        $mocked_api->unmock_all;

        note( 'Transfer Order ID: ' . $transfer->order_id );
        note( 'Transfer Domain Name: ' . $transfer->name );
    };

    return $transfer;
}

sub mock_domain_transfer {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api => { isa => 'Test::MockModule', optional => 1 },
        request    => { isa => 'WWW::eNom::DomainRequest::Transfer', optional => 1 },
    );

    my $mocked_api = mock_response(
        defined $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'TP_CreateOrder',
        response => {
            ErrCount      => 0,
            transferorder => {
                transferorderdetail => {
                    transferorderdetailid => 42,
                },
            },
        }
    );

    mock_pe_getproductprice(
        mocked_api => $mocked_api,
        price      => 6,
    );

    mock_tp_get_order_detail(
        mocked_api    => $mocked_api,
        order_id      => 42,
        sld           => $args{request}->sld,
        tld           => $args{request}->tld,
        status_id     => 13,
        status        => 'Domain awaiting transfer initiation',
        is_locked     => $args{request}->is_locked,
        is_auto_renew => $args{request}->is_auto_renew,
        use_existing_contacts => $args{request}->use_existing_contacts,
        $args{request}->has_registrant_contact ? ( registrant_contact => $args{request}->registrant_contact ) : ( ),
        $args{request}->has_admin_contact      ? ( admin_contact      => $args{request}->admin_contact      ) : ( ),
        $args{request}->has_technical_contact  ? ( technical_contact  => $args{request}->technical_contact  ) : ( ),
        $args{request}->has_billing_contact    ? ( billing_contact    => $args{request}->billing_contact    ) : ( ),
    );

    return $mocked_api;
}

sub mock_tp_get_order_detail {
    my ( %args ) = validated_hash(
        \@_,
        force_mock            => { isa => 'Bool',               default  => 0 },
        mocked_api            => { isa => 'Test::MockModule',   optional => 1 },
        order_id              => { isa => 'Int',                optional => 1 },
        sld                   => { isa => 'Str' },
        tld                   => { isa => 'Str' },
        status_id             => { isa => 'Int',                optional => 1 },
        status                => { isa => 'Str',                optional => 1 },
        is_locked             => { isa => 'Bool',               optional => 1 },
        is_auto_renew         => { isa => 'Bool',               optional => 1 },
        use_existing_contacts => { isa => 'Bool',               optional => 1 },
        registrant_contact    => { isa => 'WWW::eNom::Contact', optional => 1 },
        admin_contact         => { isa => 'WWW::eNom::Contact', optional => 1 },
        technical_contact     => { isa => 'WWW::eNom::Contact', optional => 1 },
        billing_contact       => { isa => 'WWW::eNom::Contact', optional => 1 },
    );

    my %contacts;
    if( $args{use_existing_contacts} ) {
        %contacts = (
            Registrant     => 'None',
            Administrative => 'None',
            Technical      => 'None',
            AuxBilling     => 'None',
        );
    }
    else {
        %contacts = (
            Registrant     => $args{registrant_contact}
                ? ( $args{registrant_contact}->construct_creation_request('Registrant') ) : ( ),
            Administrative => $args{admin_contact}
                ? ( $args{admin_contact}->construct_creation_request('Administrative') ) : ( ),
            Technical      => $args{technical_contact}
                ? ( $args{technical_contact}->construct_creation_request('Technical') ) : ( ),
            AuxBilling     => $args{billing_contact}
                ? ( $args{billing_contact}->construct_creation_request('AuxBilling') ) : ( ),
        );
    }

    return mock_response(
        $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        force_mock => $args{force_mock},
        method     => 'TP_GetOrderDetail',
        response   => {
            ErrCount => 0,
            transferorderdetail => {
                'transferorderdetailid' => $args{order_id} // 42,
                'sld'         => lc $args{sld},
                'tld'         => lc $args{tld},
                'statusdesc'  => $args{status}        // 'Domain awaiting transfer initiation',
                'statusid'    => $args{status_id}     // 13,
                'lock'        => $args{is_locked}     // 1 ? 'True' : 'False',
                'renew'       => $args{is_auto_renew} // 0 ? 'True' : 'False',
                'usecontacts' => $args{use_existing_contacts} // 0 ? '1' : '0',
                'contacts'    => \%contacts,
            },
        },
    );
}

1;
