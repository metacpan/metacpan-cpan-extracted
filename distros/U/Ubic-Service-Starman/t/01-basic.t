use Test::More tests => 2;

use Ubic::Service::Starman;

# Test Hashref
ok my $s = Ubic::Service::Starman->new({ app => "t/app.psgi", app_name => '2' });

# Test List
ok my $s2 = Ubic::Service::Starman->new( app => "t/app.psgi", app_name=> '2' );
