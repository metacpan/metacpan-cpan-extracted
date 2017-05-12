use Test::Modern;
use t::lib::Harness qw(ss);
use DateTime;
plan skip_all => 'SIFT_SCIENCE_API_KEY not in ENV' unless defined ss();

my $id = 1;
my %garbage = ('$garbage' => 'asdf12345');

subtest 'General Event Method Testing' => sub {
    my @events = qw/
        add_item_to_cart
        create_account
        create_order
        login
        remove_item_from_cart
        send_message
        submit_review
        update_account
    /;
    for my $test (
        [ {}                                        , '"%s" w/ empty hash'   ],
        [ {'$user_email' => 'email@live.com'       }, '"%s" w/ param'        ],
        [ { custom_date  => DateTime->now->iso8601 }, '"%s" w/ custom field' ],
    ) {
        my ($data, $message) = @$test;
        for my $event (@events) {
            my $res = ss->$event($id, $data);
            is $res->{error_message} => 'OK',
                sprintf $message, $event or diag explain $res;
        }
    }

    my $res = ss->logout($id);
    is $res->{error_message} => 'OK', '"logout"' or diag explain $res;

    for my $event (@events) {
        ok exception { ss->$event($id, \%garbage ) },
            "\"$event\" failed with garbage data";
    }
};

subtest 'Transaction' => sub {
    ok exception { ss->transaction($id) },
        '"transaction" failed with missing required params';

    my %data = (
        '$amount'        => 506790000,
        '$currency_code' => 'USD',
    );

    my $res = ss->create_order($id, \%data);
    is $res->{error_message} => 'OK',
        '"transaction" with required params' or diag explain $res;

    $data{'$order_id'} = 555;
    $res = ss->create_order($id, \%data);
    is $res->{error_message} => 'OK',
        '"transaction" with required and optional params'
        or diag explain $res;

    ok exception { ss->transaction($id, %garbage) },
        '"transaction" failed with garbage data';
};

subtest 'Link Session to User' => sub {
    ok exception { ss->link_session_to_user($id) },
        '"link_session_to_user" failed with missing required param';

    my %data = ( session_id => 'ABC12345' );

    my $res = ss->link_session_to_user($id, \%data);
    is $res->{error_message} => 'OK',
        '"link_session_to_user" with required param' or diag explain $res;

    ok exception { ss->link_session_to_user($id, %garbage) },
        '"link_session_to_user" failed with garbage data';
};

subtest 'Custom Event' => sub {
    ok exception { ss->custom_event($id) },
        '"custom_event" failed with missing required params';

    for my $event (
        [ 'make_call',       { call_duration   => 448                    }],
        [ 'create_campaign', { campaign_status => 'expired'              }],
        [ 'empty_trash',     { last_emptied    => DateTime->now->iso8601 }],
    ) {
        my ($type, $data) = @$event;
        my $res = ss->custom_event($id, $type, $data);
        is $res->{error_message} => 'OK',
            "\"custom_event\" of \"$type\" with data" or diag explain $res;
    }
};

done_testing;
