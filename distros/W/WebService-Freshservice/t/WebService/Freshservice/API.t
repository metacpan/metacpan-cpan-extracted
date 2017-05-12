#!/usr/bin/env perl

use lib 't/lib/';

use WebService::Freshservice::Test;
use Test::Most;
use Test::Warnings;

my $tester = WebService::Freshservice::Test->new();

$tester->test_with_dancer(\&user_testing, 9);

sub user_testing {
  my ($api,$message) = @_;

  pass("User Testing: $message");  
  use_ok("WebService::Freshservice::User");
  

  subtest 'Instantiation' => sub {
    isa_ok($api, "WebService::Freshservice::API");
    can_ok($api, qw( get_api post_api ) );
  };
  
  subtest 'Get Method' => sub {
    my $get = $api->get_api( "/itil/requesters/1234.json" );
    is( $get->{user}{name}, "Test", "'get_api' returns data" );
    dies_ok { $api->get_api("invalid") } "'get_api' dies when JSON not received";
    dies_ok { $api->get_api("unknown") } "'get_api' dies when success is not received";
  };
   
  subtest 'Post Method' => sub {
    my $user->{user}{name} = "Test";
    my $post = $api->post_api( "/itil/requesters.json", $user );
    is( $post->{user}{name}, "Test", "'post_api' returns data" );
    throws_ok { $api->post_api("invalid", { content => "test" } ) } qr/Failed to parse json/,"'post_api' dies when JSON not received";
    throws_ok { $api->post_api("unknown", { content => "test" }) } qr/API failed - error: /, "'post_api' dies when success is not received";
  };
   
  subtest 'Put Method' => sub {
    my $user->{user}{name} = "Elite";
    is( $api->put_api( "/itil/requesters/1337.json", $user ), 1, "'put_api' returns 1 on success" );
    my $get = $api->get_api( "/itil/requesters/1337.json" );
    is( $get->{user}{name}, "Elite", "'put_api' updates data" );
    throws_ok { $api->put_api("error", { content => "test" }) } qr/API failed - error: /, "'put_api' dies when success is not received";
  };

  subtest 'Delete Method' => sub {
    is( $api->delete_api( "/itil/requesters/1337.json" ), 1, "'delete_api' returns 1 on success" );
    throws_ok { $api->delete_api("error") } qr/API failed - error: /, "'delete_api' dies when success is not received";
  };

  subtest 'Failures' => sub {
    dies_ok { $api->_build__ua('argurment') } "method '_build__ua' doesn't accept arguments";
    dies_ok { $api->get_api() } "method 'get_api' requires an argument";
    dies_ok { $api->get_api('arg1', 'arg2' ) } "method 'get_api' only takes a singular argument";
    dies_ok { $api->post_api() } "method 'post_api' requires arguments";
    dies_ok { $api->post_api('arg') } "method 'post_api' requires 2 arguments";
    dies_ok { $api->post_api('arg1', 'arg2', 'arg3') } "method 'post_api' only takes 2 arguments";
    dies_ok { $api->put_api() } "method 'put_api' requires arguments";
    dies_ok { $api->put_api('arg') } "method 'put_api' requires 2 arguments";
    dies_ok { $api->put_api('arg1', 'arg2', 'arg3') } "method 'put_api' only takes 2 arguments";
    dies_ok { $api->delete_api() } "method 'delete_api' requires arguments";
    dies_ok { $api->delete_api('arg1', 'arg2' ) } "method 'delete_api' only takes a singular argument";
  };
}

done_testing();
__END__
