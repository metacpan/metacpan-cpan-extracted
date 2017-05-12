use Test::Modern;
use t::lib::Harness qw(ss);
use DateTime;
plan skip_all => 'SIFT_SCIENCE_API_KEY not in ENV' unless defined ss();

my $id = 2;

subtest 'Score' => sub {
    ss->login($id);
    my $res = ss->get_score($id);
    cmp_deeply $res => {
            error_message => 'OK',
            score         => TD->re('\d*\.\d*'),
            status        => TD->re('\d+'),
            user_id       => $id,
        }, 'Correctly retrieved user\'s score'
        or diag explain $res;
};

done_testing;
