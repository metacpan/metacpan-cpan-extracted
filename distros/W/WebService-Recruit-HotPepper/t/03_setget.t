# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 9;
# ----------------------------------------------------------------
{
    use_ok('WebService::Recruit::HotPepper');
    my $api = WebService::Recruit::HotPepper->new();
    ok( ref $api, 'WebService::Recruit::HotPepper->new()' );

    my $key = $ENV{HOTPEPPER_API_KEY} if exists $ENV{HOTPEPPER_API_KEY};
    $key ||= 'guest';

    $api->key( $key );
    is( $api->key(), $key, 'key' );

    my $pagesize = 2;
    $api->Start( $pagesize );
    is( $api->Start, $pagesize, 'Start' );

    my $count = 20;
    $api->Count( $count );
    is( $api->Count, $count, 'Count' );

    ok( $api->user_agent, 'user_agent (default)' );
    my $user_agent = $0;
    $api->user_agent( $user_agent );
    is( $api->user_agent, $user_agent, 'user_agent' );

    my $utf8_flag = 1;
    $api->utf8_flag( $utf8_flag );
    is( $api->utf8_flag, $utf8_flag, 'utf8_flag (true)' );

    $utf8_flag = 0;
    $api->utf8_flag( $utf8_flag );
    is( $api->utf8_flag, $utf8_flag, 'utf8_flag (false)' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
