use Test::More tests => 2;


@INC = ('./blib/lib','./blib/arch');

BEGIN {
use_ok( 'Unix::SavedIDs' ) || BAIL_OUT("Unix::SavedIDs required for all other tests");
use_ok( 'Unix::SetUser' );
}

