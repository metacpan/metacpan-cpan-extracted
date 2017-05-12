use Test::Most 0.25;

use WebService::Lymbix;
use JSON;

plan( skip_all => "Required to have LYMBIX_AUTH_KEY env variable set" )
  unless $ENV{LYMBIX_AUTH_KEY};

my $lymbix = WebService::Lymbix->new(
    auth_key    => $ENV{LYMBIX_AUTH_KEY},
    api_version => $ENV{LYMBIX_API_VER},
);

bail_on_fail;

subtest 'tonalize tests' => sub {

    can_ok $lymbix, 'tonalize';

    my $res;
    my $article = 'I like Perl';

    eval { $res = decode_json $lymbix->tonalize($article); };
    fail "Invalid response to decode. ERROR:[$@]" if $@;

    is $res->{article}, $article, 'Got expected value of article in response';

    eval { $res = decode_json $lymbix->tonalize( $article, undef, 12345 ); };
    fail "Invalid response to decode. ERROR:[$@]" if $@;

    is $res->{reference_id}, 12345,
      'Got expected value of reference_id in response';

    explain 'A tonalize complete response: ', $res;
};

subtest 'tonalize_detailed tests' => sub {

    can_ok $lymbix, 'tonalize_detailed';

    my $res;
    my $article = 'I am a hacker. I like Perl';

    eval { $res = decode_json $lymbix->tonalize_detailed($article); };
    fail "Invalid response to decode. ERROR:[$@]" if $@;

    is $res->{article}, $article, 'Got expected value of article in response';

    explain 'A tonalize_detailed complete response: ', $res;
};

subtest 'tonalize_multiple tests' => sub {

    can_ok $lymbix, 'tonalize_multiple';

    my $res;
    my $articles = '"I am a hacker","I like Perl"';

    eval {
        $res = decode_json $lymbix->tonalize_multiple( $articles, undef,
            '12345,54321' );
    };

    fail "Invalid response to decode. ERROR:[$@]" if $@;

    explain 'A tonalize_multiple complete response: ', $res;
    is ref $res, 'ARRAY', 'Return ARRAYREF of results';

};

subtest 'flag_response tests' => sub {

    can_ok $lymbix, 'flag_response';

    my $res;
    my $phrase =
      "He was happy and surprised instead of being angry. Although he wasn't too happy about it he said yes anyways! What do you think of this decision?";

    dies_ok { $lymbix->flag_response( 1234, $phrase, 'invalid_request' ) }
    'Expecting to die on invalid api_method_request';

    eval {
        $res = $lymbix->flag_response( 'AD1234', $phrase, 'tonalize_detailed' );
    };
    fail "Invalid response. ERROR:[$@]" if $@;

    is $res, 'Thank you for your submission', 'Successfully ran flag_response';
};

done_testing();
