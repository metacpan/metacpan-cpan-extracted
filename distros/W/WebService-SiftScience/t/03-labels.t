use Test::Modern;
use t::lib::Harness qw(ss);
use DateTime;
plan skip_all => 'SIFT_SCIENCE_API_KEY not in ENV' unless defined ss();

my $id = 3;

subtest 'Labels' => sub {
    my $res = ss->label_user($id, { '$is_bad' => 1 });
    is $res->{error_message} => 'OK',
        '"label_user" with required params' or diag explain $res;

    $res = ss->unlabel_user($id);
    is $res => 1,
        '"unlabel_user" with required params';
};

done_testing;
