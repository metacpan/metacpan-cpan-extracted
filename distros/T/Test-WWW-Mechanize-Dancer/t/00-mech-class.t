use Test::WWW::Mechanize::Dancer;
use Test::More tests => 1;
use lib 't/lib';

# Load
ok( Test::WWW::Mechanize::Dancer->new( mech_class => 'TestPsgi' )->mech );

