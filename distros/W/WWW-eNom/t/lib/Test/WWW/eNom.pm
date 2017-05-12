package Test::WWW::eNom;

use strict;
use warnings;

use Test::More;
use Test::Exception;

use WWW::eNom;

use Readonly;
Readonly our $ENOM_USERNAME => $ENV{PERL_WWW_ENOM_USERNAME};
Readonly our $ENOM_PASSWORD => $ENV{PERL_WWW_ENOM_PASSWORD};
Readonly my $SKIP_MESSAGE   => 'PERL_WWW_ENOM_USERNAME and PERL_WWW_ENOM_PASSWORD must be defined in order to run integration tests.';

use Exporter 'import';
our @EXPORT_OK = qw(
    create_api check_for_credentials
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

1;
