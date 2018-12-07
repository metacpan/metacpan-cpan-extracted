package Test::WWW::eNom::Service;

use strict;
use warnings;

use Test::More;
use Test::MockModule;
use MooseX::Params::Validate;

use Test::WWW::eNom qw( mock_response );

use Exporter 'import';
our @EXPORT_OK = qw(
    mock_pe_getproductprice
    mock_purchase_services
    mock_renew_services
    mock_enable_services
    mock_disable_services
    mock_get_wpps_info
);

sub mock_pe_getproductprice {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api => { isa => 'Test::MockModule', optional => 1 },
        price      => { isa => 'Num' },
    );

    return mock_response(
        $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'PE_GetProductPrice',
        response => {
            ErrCount     => 0,
            productprice => {
                price          => $args{price},
                productenabled => 'True',
            }
        }
    );
}

sub mock_purchase_services {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api => { isa => 'Test::MockModule', optional => 1 },
    );

    return mock_response(
        $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'PurchaseServices',
        response => {
            ErrCount => 0,
            OrderID  => 42,
        }
    );
}

sub mock_renew_services {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api => { isa => 'Test::MockModule', optional => 1 },
    );

    return mock_response(
        $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'RenewServices',
        response => {
            ErrCount => 0,
            OrderID  => 42,
        }
    );
}

sub mock_enable_services {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api => { isa => 'Test::MockModule', optional => 1 },
    );

    return mock_response(
        $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'EnableServices',
        response => {
            ErrCount => 0,
            OrderID  => 42,
        }
    );
}

sub mock_disable_services {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api => { isa => 'Test::MockModule', optional => 1 },
    );

    return mock_response(
        $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'DisableServices',
        response => {
            ErrCount => 0,
        }
    );
}

sub mock_get_wpps_info {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api      => { isa => 'Test::MockModule', optional => 1 },
        is_auto_renew   => { isa => 'Bool' },
        expiration_date => { isa => 'DateTime' },
    );

    return mock_response(
        $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'GetWPPSInfo',
        response => {
            ErrCount => 0,
            GetWPPSInfo => {
                WPPSExists    => 1,
                WPPSAutoRenew => $args{is_auto_renew} ? 'Yes' : 'No',
                WPPSExpDate   => $args{expiration_date}->strftime('%b %d, %Y'),
            }
        }
    );
}

1;
