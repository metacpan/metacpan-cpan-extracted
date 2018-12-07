package Test::WWW::eNom;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockModule;
use MooseX::Params::Validate;

use WWW::eNom;

use Readonly;
Readonly our $ENOM_USERNAME => $ENV{PERL_WWW_ENOM_USERNAME};
Readonly our $ENOM_PASSWORD => $ENV{PERL_WWW_ENOM_PASSWORD};
Readonly my $SKIP_MESSAGE   => 'PERL_WWW_ENOM_USERNAME and PERL_WWW_ENOM_PASSWORD must be defined in order to run integration tests.';

use Exporter 'import';
our @EXPORT_OK = qw(
    create_api check_for_credentials mock_response
    $ENOM_USERNAME $ENOM_PASSWORD
);

sub create_api {
    check_for_credentials();

    my $api;
    lives_ok {
        $api = WWW::eNom->new({
            username      => $ENOM_USERNAME,
            password      => $ENOM_PASSWORD,
            response_type => 'xml_simple',
            test          => 1,
        });
    } 'Lives through WWW::eNom object creation';

    return $api;
}

sub check_for_credentials {
    if( !defined $ENOM_USERNAME || !defined $ENOM_PASSWORD ) {
        plan( skip_all => $SKIP_MESSAGE );
    }

    return;
}

sub mock_response {
    my ( %args ) = validated_hash(
        \@_,
        force_mock => { isa => 'Bool', default => 0 },
        method     => { isa => 'Str' },
        response   => { isa => 'Str | HashRef' },
        mocked_api => { isa => 'Test::MockModule', optional => 1 }
    );

    my $mocked_api = defined $args{mocked_api} ? $args{mocked_api} : Test::MockModule->new('WWW::eNom');

    if( $ENV{USE_MOCK} || $args{force_mock} ) {
        $mocked_api->mock( $args{method}, sub {
            my $self = shift;

            note( 'Mocked WWW::eNom->' . $args{method} );

            return $args{response};
        });
    }

    return $mocked_api;
}

1;
