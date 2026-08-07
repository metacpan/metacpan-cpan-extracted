use Test2::V0;

BEGIN {
    $ENV{ LWP_UA_MOCK } ||= 'playback';
    $ENV{ LWP_UA_MOCK_FILE } ||= __FILE__.'-lwp-mock.out';
}

use WebService::OurWorldInData::Search;

use Test2::Require::Module 'LWP::UserAgent';
use Test2::Require::Module 'LWP::UserAgent::Mockable';
use Test2::Require::Module 'URI';

my $ua    = LWP::UserAgent->new;
$ua->agent('WebService::OurWorldInData-test/0.1');
my $search = WebService::OurWorldInData::Search->new( ua => $ua );

subtest 'invalid parameters' => sub {
    my $response;
    ok $search->hitsPerPage(200), 'Set hits_per_page';

    like(
        warning { $response = $search->query('gdp') },
        qr/HTTP Error: 400 Bad Request/,
        'HTTP 400 raised on bad parameters'
    );

    my $error_check = hash {
            field error   => match qr/Invalid \w+ parameter/;
            field details => 'hitsPerPage must be between 1 and 100';
            end();
    };
    is $response, $error_check, 'Bad Request error returned';
};

done_testing();

END {
    # END block ensures cleanup if script dies early
    LWP::UserAgent::Mockable->finished;
}
