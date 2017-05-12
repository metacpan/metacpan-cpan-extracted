#!/usr/bin/env perl

use lib 't/lib/';

use WebService::Freshservice::Test;
use Test::Most;
use Test::Warnings;

my $tester = WebService::Freshservice::Test->new();

$tester->test_with_dancer(\&agent_testing, 8);

sub agent_testing {
  my ($api,$message) = @_;

  pass("Agent Testing: $message");  
  use_ok("WebService::Freshservice::Agent");
  

  my $agent = WebService::Freshservice::Agent->new(
    api  => $api,
    id   => '1234567890',
  );
  
  subtest 'Instantiation' => sub {
    isa_ok($agent, "WebService::Freshservice::Agent");
    
    #can_ok($agent, qw(retrieve create update update_attr activate
    #  deactivate delete));
  };
  
  subtest 'Retrieved Values' => sub {
    is( $agent->active, 1, "'active' returned true");
    is( $agent->address, "An Address", "'address' returned a value");
    is( $agent->created_at, '2015-01-02T22:56:39-10:00', "'created_at' returned a raw date");
    cmp_deeply( 
      $agent->get_custom_field('cf_field_name'),  
      all(
        isa("WebService::Freshservice::User::CustomField"),
        methods( 
          value => 'field value',
          field => 'cf_field_name',
          api   =>  ignore(),
        ),
      ), "'custom_field' returns a object"
    );
    is( $agent->deleted, 0, "'deleted' returned false");
    is( $agent->department_names, '', "'department_names' returned empty");
    is( $agent->description, "I'm Testy McTestFace", "'description' returned a value");
    is( $agent->email, 'agent@example.com', "'email' returned an email address");
    is( $agent->external_id, 123456, "'external_id' returned a value");
    is( $agent->helpdesk_agent, 0, "'helpdesk_agent' returned false");
    is( $agent->id, 1234567890, "'id' returned a value");
    is( $agent->job_title, "Tester of Things", "'job_title' returned a value");
    is( $agent->language, 'en', "'language' returned a value");
    is( $agent->location_name, "Testland", "'location_name' returned a value");
    is( $agent->mobile, "0406000000", "'mobile' returned a value");
    is( $agent->name, "Test", "'name' returned a value");
    is( $agent->phone, "0386521453", "'phone' returned a value");
    is( $agent->time_zone, 'Perth', "'time_zone' returned a value");
    is( $agent->updated_at, '2015-01-04T23:09:52-10:00', "'updated_at' returned a raw date");
    is( $agent->active_since, "2016-07-18T09:28:47+08:00", "'active_since' returned a value" );
    is( $agent->available, 1, "'available' returns true" );
    is( $agent->occasional, 0, "'occasional' returns false" );
    is( $agent->signature, "I can haz signature??", "'signature' returns a value" );
    is( $agent->signature_html, "<p><br></p>\r\n", "'signature_html' returns a value" );
    is( $agent->points, "2500", "'points' returns a value" );
    is( $agent->scoreboard_level_id, "5", "'scoreboard_level_id' returns a value" );
    is( $agent->ticket_permission, "1", "'ticket_permission' returns a value" );
    is( $agent->user_id, '1234567890', "'user_id' returned a value" );
    is( $agent->user_created_at, '2016-07-11T16:02:28+08:00', "'user_created_at' returned a raw date");
    is( $agent->user_updated_at, '2016-07-18T09:28:47+08:00', "'user_updated_at' returned a raw date");
    throws_ok
      { $agent->get_custom_field('no field') }
      qr/Custom field must exist in freshservice/,
      "'get_custom_field' dies if retrieval of a field isn't present"
    ;
  };
   
  subtest 'Failures' => sub {
    dies_ok { $agent->_build_user('argument') } "method '_build_user' doesn't accept arguments";
    dies_ok { $agent->_build_user_override('argument') } "method '_build_user_override' doesn't accept arguments";
    dies_ok { $agent->_build_agent('argument') } "method '_build_agent' doesn't accept arguments";
    dies_ok { $agent->_build__raw('argurment') } "method '_build__raw' doesn't accept arguments";
    dies_ok { $agent->_build_custom_field('argurment') } "method '_build__custom_field' doesn't accept arguments";
    dies_ok { $agent->get_custom_field() } "method 'get_custom_field' requires an argument";
    dies_ok { $agent->get_custom_field('arg1', 'arg2') } "method 'get_custom_field' only accepts a single argument";
    dies_ok { $agent->delete_requester('argument') } "method 'delete_requester' doesn't accept arguments";
    dies_ok { $agent->update_requester('argument') } "method 'update_requester' doesn't accept arguments";
    dies_ok { $agent->set_custom_field('argument') } "method 'set_custom_field' doesn't accept arguments";
    throws_ok { $agent->delete_requester } qr/This method is not available to Agents/, "method 'delete_requester' not available for agents";
    throws_ok { $agent->update_requester } qr/This method is not available to Agents/, "method 'update_requester' not available for agents";
    throws_ok { $agent->set_custom_field } qr/This method is not available to Agents/, "method 'update_requester' not available for agents";
  };
}

done_testing();
__END__
