use strict;
use warnings;
use Future;
use Test::More;
use Log::Any::Test;
use Log::Any qw($log);
use Test::MockModule;
use Test::Fatal;
use Test::Deep;
use WebService::Async::SmartyStreets;
use Future::AsyncAwait;
use Future::Exception;
use JSON::MaybeUTF8 qw(:v1);

my $user_agent = Test::MockModule->new('Net::Async::HTTP');
$user_agent->mock(
    GET => sub {
        return Future->done();
    });

my $data = [{
        input_id     => 12345,
        organization => 'Beenary',
        metadata     => {
            latitude          => 101.2131,
            longitude         => 180.1223,
            geocode_precision => "Premise",
        },
        analysis => {
            verification_status => "Partial",
            address_precision   => "Premise",
        },
    }];
my $mock_ss = Test::MockModule->new('WebService::Async::SmartyStreets');
$mock_ss->mock(
    international_auth_id => sub {
        return 1;
    },

    international_token => sub {
        return 1;
    },

    get_decoded_data => sub {
        return Future->done($data);
    });

subtest "Call SmartyStreets" => sub {
    my $ss = WebService::Async::SmartyStreets->new(
        # this function is mocked, so the values are irrelevant
        international_auth_id => '...',
        international_token   => '...',
    );

    my %data = (
        api_choice          => 'international',
        address1            => 'Jalan 1223 Jamse Bndo 012',
        address2            => '03/03',
        locality            => 'Sukabumi',
        administrative_area => 'JB',
        postal_code         => '43145',
        country             => 'Indonesia',
        geocode             => 'true',
    );

    my $addr = $ss->verify(%data)->get();
    # Check if status check is correct
    is($addr->status_at_least('none'),     1,  "Verification score is correct");
    is($addr->status_at_least('verified'), '', "Verification score is correct");

    # Check if address accuracy level check is correct
    is($addr->accuracy_at_least('locality'),           1,  "Accuracy checking is correct");
    is($addr->accuracy_at_least('administrativearea'), 1,  "Accuracy checking is correct");
    is($addr->accuracy_at_least('deliverypoint'),      '', "Accuracy checking is correct");

    $data = [{
            input_id     => 12345,
            organization => 'Beenary',
            metadata     => {
                latitude          => 101.2131,
                longitude         => 180.1223,
                geocode_precision => "Premise",
            },
            analysis => {
                verification_status => "",
                address_precision   => "Premise",
            },
        }];

    $addr = $ss->verify(%data)->get();
    is($addr->status_at_least('partial'), '', "Verification score is correct for empty status");

    # empty response case, this means adddress is invalid
    # get_decoded_data returns the first element of the data, we wanted to test empty response [], so `undef` would be the result of that operation.

    $data = undef;
    $addr = $ss->verify(%data)->get();
    is($addr->status_at_least('partial'), '', "Verification score is correct for empty http response");
};

subtest 'HTTP Error' => sub {
    $mock_ss->unmock_all;

    $user_agent->mock(
        GET => sub {
            my $res = HTTP::Response->new(402);

            $res->content(
                encode_json_utf8({
                        errors => [{
                                id      => 1588026162,
                                message =>
                                    'Active subscription required (1588026162): The optional license value supplied (if any) was valid and understood, but the account does not have the necessary active subscription to allow this operation to continue.'
                            }]}));

            Future::Exception->throw('HTTP Failure', 'http', $res);
        });

    my $ss = WebService::Async::SmartyStreets->new(
        international_auth_id => '...',
        international_token   => '...',
    );

    my %data = (
        api_choice          => 'international',
        address1            => 'Jalan 1223 Jamse Bndo 012',
        address2            => '03/03',
        locality            => 'Sukabumi',
        administrative_area => 'JB',
        postal_code         => '43145',
        country             => 'Indonesia',
        geocode             => 'true',
    );

    $log->clear();

    my $e = exception { $ss->verify(%data)->get };

    cmp_deeply, $log->msgs,
        [{
            category => 'WebService::Async::SmartyStreets',
            message  =>
                'GET https://international-street.api.smartystreets.com/verify?administrative_area=JB&address2=03%2F03&locality=Sukabumi&address1=Jalan+1223+Jamse+Bndo+012&country=Indonesia&api_choice=international&postal_code=43145&geocode=true&auth-id=...&auth-token=...&input-id=AA00000001',
            level => 'trace'
        },
        {
            level   => 'warning',
            message =>
                'SmartyStreets HTTP status 402 error: Active subscription required (1588026162): The optional license value supplied (if any) was valid and understood, but the account does not have the necessary active subscription to allow this operation to continue.',
            category => 'WebService::Async::SmartyStreets'
        }];

    ok $e =~ /Unable to retrieve response/, 'Exception caught';
};

done_testing();
