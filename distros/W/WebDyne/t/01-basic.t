#!perl


#  Load
#
use Test::More qw(no_plan);
BEGIN { use_ok( 'WebDyne::Request::Fake' ); }
require_ok( 'WebDyne::Request::Fake' );


#  Initiate Fake Request
#
my $r=WebDyne::Request::Fake->new();
ok (defined $r);
ok ($r->isa('WebDyne::Request::Fake'));


