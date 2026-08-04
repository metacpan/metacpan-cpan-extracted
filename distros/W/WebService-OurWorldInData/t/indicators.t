use Test2::V0;

BEGIN {
    $ENV{ LWP_UA_MOCK } ||= 'playback';
    $ENV{ LWP_UA_MOCK_FILE } ||= __FILE__.'-lwp-mock.out';
}

use WebService::OurWorldInData::Indicators;

use Test2::Require::Module 'LWP::UserAgent';
use Test2::Require::Module 'LWP::UserAgent::Mockable';
use Test2::Require::Module 'URI';

use Data::Dumper::Concise;

my $ua = LWP::UserAgent->new;
$ua->agent('WebService::OurWorldInData-test/0.5');
my $indicator = WebService::OurWorldInData::Indicators->new( ua => $ua );

subtest 'Indicator object ok' => sub {
    is $indicator, object {
        prop isa => 'WebService::OurWorldInData::Indicators';

        field base_url => 'https://search.owid.io';
        field ua       => check_isa 'LWP::UserAgent';

        end();
    }, 'Chart object correct';
};

subtest 'health check' => sub {
    my $health = $indicator->health();
    is $health, { status => 'ok' }, 'Health check successful';
};

my $result_check = hash {
    field title => D();
    field indicator_id => D();
    field snippet => D();
    field score => D();
    field metadata => D();
    etc();
};

my $response_check = hash {
    field results => array {
        etc();
    };
    field query         => D();
    field total_results => T();
    end();
};

subtest 'basic indicators query' => sub {
    my $response = $indicator->query('gdp');
    is $response, $response_check, 'Indicators Response correct';
    is $response->{results}[0], $result_check, 'Indicators Result correct';
    is scalar @{$response->{results}}, 10, 'Default limit number of Results';
};

subtest 'indicators parameter setting' => sub {
    my $new_limit = 5;
    ok $indicator->limit($new_limit), 'Limit attribute set';
    is $indicator->limit, $new_limit, 'Limit attribute correct';

    my $response = $indicator->query('gdp');
    is $response->{results}[0], $result_check, 'Indicators Result correct';
    is scalar @{$response->{results}}, $new_limit,
        'Correct number of Results';
    my $all_results = $response->{total_results};

    my $new_pop = 0.6; # median popularity is 0.59
    ok $indicator->min_popularity($new_pop), 'Popularity attribute set';
    is $indicator->min_popularity, $new_pop, 'Popularity attribute correct';

    $response = $indicator->query('gdp');
    my $filtered_results = $response->{total_results};
    ok $filtered_results < $all_results, 'Filtered results';
};

subtest 'query errors' => sub {
    like(
        warning { $indicator->query() },
        qr/^query method requires an argument/,
        'Query on empty string - expected warning'
    );
    like(
        warning { $indicator->query({key => 'value'}) },
        qr/^query missing .*parameter/,
        'Query missing "q" or "query" - expected warning'
    );

    my $r;
    like(
        warning { $r = $indicator->query({q => 'gdp', min_popularity => 5}) },
        qr/HTTP Error: 422 Unprocessable Entity/,
        'Server warning that popularity is out of range'
    );
    is $r->{detail}[0]{msg}, 'Input should be less than or equal to 1',
        'JSON error message';
};

done_testing();

END {
    # END block ensures cleanup if script dies early
    LWP::UserAgent::Mockable->finished;
}
