use Test::More tests => 19;

BEGIN {
    use_ok( 'WWW::BigDoor' );
    use_ok( 'WWW::BigDoor::Attribute' );
    use_ok( 'WWW::BigDoor::Award' );
    use_ok( 'WWW::BigDoor::Currency' );
    use_ok( 'WWW::BigDoor::CurrencyBalance' );
    use_ok( 'WWW::BigDoor::CurrencyType' );
    use_ok( 'WWW::BigDoor::EndUser' );
    use_ok( 'WWW::BigDoor::Good' );
    use_ok( 'WWW::BigDoor::Leaderboard' );
    use_ok( 'WWW::BigDoor::Level' );
    use_ok( 'WWW::BigDoor::NamedAwardCollection' );
    use_ok( 'WWW::BigDoor::NamedAward' );
    use_ok( 'WWW::BigDoor::NamedGoodCollection' );
    use_ok( 'WWW::BigDoor::NamedGood' );
    use_ok( 'WWW::BigDoor::NamedLevelCollection' );
    use_ok( 'WWW::BigDoor::NamedLevel' );
    use_ok( 'WWW::BigDoor::Profile' );
    use_ok( 'WWW::BigDoor::Resource' );
    use_ok( 'WWW::BigDoor::URL' );
}

diag( "Testing WWW::BigDoor $WWW::BigDoor::VERSION" );
