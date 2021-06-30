use strict;
use warnings;

use Test::More;

use Scalar::Util qw( blessed );
use Test::Fatal;
use WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST ();

use lib 't/lib';
use Util;

## no critic (RequireExplicitInclusion)
my $ppa = Util::mocked_ppa;

subtest 'bad params' => sub {

    # What happens if the params contain only garbage?
    like(
        exception {
            Util::mocked_ppa->get_response_from_silent_post(
                { params => { foo => 'bar' } } )
        },
        qr{Bad params supplied from silent POST},
        'generic exception on bad params'
    );
};

subtest 'RESULT=161 with no transtime' => sub {
    my $txn
        = WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST->new(
        nonfatal_result_codes => [161],
        params                => {
            RESULT  => 161,
            RESPMSG =>
                'Transaction using secure token is already in progress',
        }
        );

    is( $txn->transaction_time, undef, 'no exception on missing transtime' );
};

done_testing();
