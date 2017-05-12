#!perl -T

use Test::More 'no_plan';
use Data::Dumper;
use lib 't/lib';

BEGIN {
    use_ok( 'WebService::FC2::SpamAPI' );
}

my $api = WebService::FC2::SpamAPI->new();
my $r = $api->check_url('http//example.com/');
isa_ok( $r, 'WebService::FC2::SpamAPI::Response' );
is( $r->is_spam, 0 );

$r = $api->check_url({ url => 'http//example.com/' });
isa_ok( $r, 'WebService::FC2::SpamAPI::Response' );
is( $r->is_spam, 0 );

my @r = $api->get_url_list();
ok( @r );
isa_ok( $r[0], 'WebService::FC2::SpamAPI::Response' );

@r = $api->get_domain_list({ dm => 'example.com' });
is( scalar @r, 0 );




