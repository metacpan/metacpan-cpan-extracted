use Test::More tests => 7;

BEGIN {
use_ok( 'WWW::Comix' );
use_ok( 'WWW::Comix::Plugin' );
use_ok( 'WWW::Comix::Plugin::GoComics' );
use_ok( 'WWW::Comix::Plugin::ComicsDotCom' );
use_ok( 'WWW::Comix::Plugin::ArcaMax' );
use_ok( 'WWW::Comix::Plugin::KingFeatures' );
use_ok( 'WWW::Comix::Plugin::Creators' );
}

diag( "Testing WWW::Comix $WWW::Comix::VERSION" );
