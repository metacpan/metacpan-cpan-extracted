use Test::More tests => 18;

BEGIN {
use_ok( 'Zymurgy' );
use_ok( 'Zymurgy::Brewer' );
use_ok( 'Zymurgy::Brewer::Grist' );
use_ok( 'Zymurgy::Brewer::Hops' );
use_ok( 'Zymurgy::Brewer::Recipe' );
use_ok( 'Zymurgy::Brewer::Batch' );
use_ok( 'Zymurgy::Brewer::Batch::BrewDay' );
use_ok( 'Zymurgy::Brewer::Batch::BrewLog' );
use_ok( 'Zymurgy::Vintner' );
use_ok( 'Zymurgy::Vintner::Must' );
use_ok( 'Zymurgy::Vintner::Recipe' );
use_ok( 'Zymurgy::Vintner::Batch' );
use_ok( 'Zymurgy::Vintner::Batch::MustDay' );
use_ok( 'Zymurgy::Vintner::Batch::WineLog' );
use_ok( 'Zymurgy::Data' );
use_ok( 'Zymurgy::Data::Grist' );
use_ok( 'Zymurgy::Data::Hops' );
use_ok( 'Zymurgy::Data::Yeast' );
}

diag( "Testing Zymurgy $Zymurgy::VERSION" );
diag( "Testing Zymurgy::Brewer $Zymurgy::Brewer::VERSION" );
diag( "Testing Zymurgy::Brewer::Grist $Zymurgy::Brewer::Grist::VERSION" );
diag( "Testing Zymurgy::Brewer::Hops $Zymurgy::Brewer::Hops::VERSION" );
diag( "Testing Zymurgy::Brewer::Recipe $Zymurgy::Brewer::Recipe::VERSION" );
diag( "Testing Zymurgy::Brewer::Batch $Zymurgy::Brewer::Batch::VERSION" );
diag( "Testing Zymurgy::Brewer::Batch::BrewDay $Zymurgy::Brewer::Batch::BrewDay::VERSION" );
diag( "Testing Zymurgy::Brewer::Batch::BrewLog $Zymurgy::Brewer::Batch::BrewLog::VERSION" );
diag( "Testing Zymurgy::Vintner $Zymurgy::Vintner::VERSION" );
diag( "Testing Zymurgy::Vintner::Must $Zymurgy::Vintner::Must::VERSION" );
diag( "Testing Zymurgy::Vintner::Recipe $Zymurgy::Vintner::Recipe::VERSION" );
diag( "Testing Zymurgy::Vintner::Batch $Zymurgy::Vintner::Batch::VERSION" );
diag( "Testing Zymurgy::Vintner::Batch::MustDay $Zymurgy::Vintner::Batch::MustDay::VERSION" );
diag( "Testing Zymurgy::Vintner::Batch::WineLog $Zymurgy::Vintner::Batch::WineLog::VERSION" );
diag( "Testing Zymurgy::Data $Zymurgy::Data::VERSION" );
diag( "Testing Zymurgy::Data::Grist $Zymurgy::Data::Grist::VERSION" );
diag( "Testing Zymurgy::Data::Hops $Zymurgy::Data::Hops::VERSION" );
diag( "Testing Zymurgy::Data::Yeast $Zymurgy::Data::Yeast::VERSION" );

