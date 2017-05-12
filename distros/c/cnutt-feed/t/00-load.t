#!perl -T

use Test::More tests => 5;

BEGIN {
    use_ok( 'Cnutt::Feed' );
    use_ok( 'Cnutt::Feed::Mailbox' );
    use_ok( 'Cnutt::Feed::Actions::Fetch' );
    use_ok( 'Cnutt::Feed::Actions::Get' );
    use_ok( 'Cnutt::Feed::Actions::List' );
}

