# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 8;
# ----------------------------------------------------------------
{
    use_ok('WebService::Recruit::Dokoiku');
    my $doko = WebService::Recruit::Dokoiku->new();
    ok( ref $doko, 'WebService::Recruit::Dokoiku->new()' );

    my $key = $ENV{DOKOIKU_API_KEY} if exists $ENV{DOKOIKU_API_KEY};
    $key ||= 'guest';   # is not allowed however.

    $doko->key( $key );
    is( $doko->key(), $key, 'key' );

    my $pagesize = 10;
    $doko->pagesize( $pagesize );
    is( $doko->pagesize, $pagesize, 'pagesize' );

    ok( $doko->user_agent, 'user_agent (default)' );
    my $user_agent = $0;
    $doko->user_agent( $user_agent );
    is( $doko->user_agent, $user_agent, 'user_agent' );

    my $utf8_flag = 1;
    $doko->utf8_flag( $utf8_flag );
    is( $doko->utf8_flag, $utf8_flag, 'utf8_flag (true)' );

    $utf8_flag = 0;
    $doko->utf8_flag( $utf8_flag );
    is( $doko->utf8_flag, $utf8_flag, 'utf8_flag (false)' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
