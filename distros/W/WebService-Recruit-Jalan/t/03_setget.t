# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 7;
# ----------------------------------------------------------------
{
    use_ok('WebService::Recruit::Jalan');
    my $jalan = WebService::Recruit::Jalan->new();
    ok( ref $jalan, 'WebService::Recruit::Jalan->new()' );

    my $key = $ENV{JALAN_API_KEY} if exists $ENV{JALAN_API_KEY};
    $key ||= 'guest';   # is not allowed however.

    $jalan->key( $key );
    is( $jalan->key(), $key, 'key' );

    ok( $jalan->user_agent, 'user_agent (default)' );
    my $user_agent = $0;
    $jalan->user_agent( $user_agent );
    is( $jalan->user_agent, $user_agent, 'user_agent' );

    my $utf8_flag = 1;
    $jalan->utf8_flag( $utf8_flag );
    is( $jalan->utf8_flag, $utf8_flag, 'utf8_flag (true)' );

    $utf8_flag = 0;
    $jalan->utf8_flag( $utf8_flag );
    is( $jalan->utf8_flag, $utf8_flag, 'utf8_flag (false)' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
