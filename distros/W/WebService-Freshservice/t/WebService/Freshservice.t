#!/usr/bin/env perl

use lib 't/lib/';

use WebService::Freshservice::Test;
use Test::Most;
use Test::Warnings;

my $tester = WebService::Freshservice::Test->new();

$tester->test_with_dancer(\&requester_testing, 8);

sub requester_testing {
  my ($api,$message) = @_;

  pass("Freshservice Testing: $message");  
  use_ok("WebService::Freshservice");
  

  my $freshservice = WebService::Freshservice->new(
    apikey  => $api->apikey,
    apiurl  => $api->apiurl,
  );
  
  subtest 'Instantiation' => sub {
    isa_ok($freshservice, "WebService::Freshservice");
    
    can_ok($freshservice, qw( create_requester requester requesters ));
  };

  subtest 'Create Requester - Minimal Options' => sub {
    my $requester = $freshservice->create_requester(
      name        => "Test",
      email       => 'test@example.com',
      address     => 'An Address',
      description => "I'm Testy McTestFace",
      job_title   => 'Tester of Things',
      language    => 'en',
      timezone    => 'Perth',
    );

    is( $requester->active, 1, "'active' returned true");
    is( $requester->address, "An Address", "'address' returned a value");
    is( $requester->created_at, '2016-07-11T16:02:28+08:00', "'created_at' returned a raw date");
    ok( $requester->custom_field, "'custom_field' exists");
    is( $requester->deleted, 0, "'deleted' returned false");
    is( $requester->department_names, '', "'department_names' returned empty");
    is( $requester->description, "I'm Testy McTestFace", "'description' returned a value");
    is( $requester->email, 'test@example.com', "'email' returned an email address");
    is( $requester->external_id, 123456, "'external_id' returned a value");
    is( $requester->helpdesk_agent, 0, "'helpdesk_agent' returned false");
    is( $requester->id, 1234567890, "'id' returned a value");
    is( $requester->job_title, "Tester of Things", "'job_title' returned a value");
    is( $requester->language, 'en', "'language' returned a value");
    is( $requester->location_name, "Testland", "'location_name' returned a value");
    is( $requester->mobile, "0406000000", "'mobile' returned a value");
    is( $requester->name, "Test", "'name' returned a value");
    is( $requester->phone, "0386521453", "'phone' returned a value");
    is( $requester->time_zone, 'Perth', "'time_zone' returned a value");
    is( $requester->updated_at, '2016-07-18T09:28:47+08:00', "'updated_at' returned a raw date");

    my $phone = $freshservice->create_requester(
      name  => "Test",
      phone => '0386521453',
    );
    is( $phone->phone, "0386521453", "Requester creation with phone" );

    my $mobile = $freshservice->create_requester(
      name   => "Test",
      mobile => '0406000000',
    );
    is( $mobile->mobile, "0406000000", "Requester creation with mobile" );

    throws_ok { $freshservice->create_requester( email => 'test@example.com' ) } 
      qr/Name must be definded to create a user/,
      "method 'create_requester' requires the name attribute";
    throws_ok { $freshservice->create_requester( name => 'Test', address => '111' ) } 
      qr/One of email, phone or mobile must be definded to create a user/,
      "method 'create_requester' requires one of 'email', 'phone' or 'mobile'  attributes";
  };
  
  subtest 'Retrieve Requester' => sub {
    my $requester = $freshservice->requester( id => '1234567890' );
    is( $requester->id, 1234567890, "'id' returned a value");
    is( $requester->email, 'test@example.com', "'email' returned an email address");

    my $email = $freshservice->requester( email => 'search@example.com' );
    is( $email->email, 'search@example.com', "Search via email returns correct result");
    
    my $invalid = $freshservice->requester( id => '9999999999' );
    dies_ok { $invalid->name } "'requester' method croaks on unknown requester id";
    dies_ok { $freshservice->requester( email => 'croak@example.com' ) } "'requester' dies if no valid email found";
  };

  subtest 'Search Requesters' => sub {
    my $blank = $freshservice->requesters();
    is( (@{$blank})[1]->name, "Test 2", "Multiple requesters returned" );

    my $email = $freshservice->requesters( email => 'query@example.com'); 
    is( (@{$email})[0]->email, 'query@example.com', "Requester search based on email" );

    my $mobile = $freshservice->requesters( mobile => '0400000001'); 
    is( (@{$mobile})[0]->mobile, "0400000001", "Requester search based on mobile" );

    my $phone = $freshservice->requesters( phone => '0386521453'); 
    is( (@{$phone})[0]->phone, "0386521453", "Requester search based on phone" );

    my $all = $freshservice->requesters( 
      email => 'query@example.com',
      mobile => '0400000001',
      phone => '0386521453',
    ); 
    is( (@{$all})[0]->email, 'query@example.com', "Email returned from requester multi query search" );
    is( (@{$all})[0]->mobile, "0400000001", "Mobile returned from requester multi query search" );
    is( (@{$all})[0]->phone, "0386521453", "Phone returned from requester multi query search" );
    
    my $deactivated = $freshservice->requesters( state => 'unverified' );
    is( (@{$deactivated})[0]->active, 0, "state 'unverified' returns inactive requesters" );
    
    my $deleted = $freshservice->requesters( state => 'deleted' );
    is( (@{$deleted})[0]->deleted, 1, "state 'deleted' returns deleted requesters" );
    
    my $paginated = $freshservice->requesters( page => 2 );
    is( (@{$paginated})[0]->name, "Page 2", "page returns second page of results" );
  };

  subtest 'Retrieve Agent' => sub {
    my $agent = $freshservice->agent( id => '1234567890' );
    is( $agent->id, 1234567890, "'id' returned a value");
    is( $agent->email, 'agent@example.com', "'email' returned an email address");
  };

  subtest 'Retrieve Agents' => sub {
    my $agents = $freshservice->agents( email => 'agent.smith@example.com' );
    is( @{$agents}[0]->id, 19, "'id' returned a value");
    is( @{$agents}[0]->email, 'agent.smith@example.com', "'email' returned an email address");
  };

  subtest 'Failures' => sub {
    dies_ok { $freshservice->_build__api('argurment') } "method '_build__api' doesn't accept arguments";
    dies_ok { $freshservice->requester( id => 'test', email => 'test', unknown => 'test') } "method 'requester' only takes 2 arguments";
    dies_ok { $freshservice->requester } "'requester' method requires an id at a minimum";
    dies_ok { $freshservice->create_requester } "'create_requester' method requires arguments";
    dies_ok { 
      $freshservice->requesters(
        email   => 'test',
        mobile  => 'test',
        phone   => 'test',
        state   => 'test',
        page    => 'test',
        page    => 'test',
      ) 
    } "method 'requesters' only takes 5 arguments";
    dies_ok { 
      $freshservice->requesters(
        email   => 'test',
        test    => 'test',
      ) 
    } "method 'requesters' only takes valid arguments";
    dies_ok { 
      $freshservice->create_requester(
        name        => 'test',
        email       => 'test',
        address     => 'test',
        description => 'test',
        job_title   => 'test',
        phone       => 'test',
        mobile      => 'test',
        language    => 'test',
        timezone    => 'test',
        name        => 'test',
      ) 
    } "method 'create_requester' only takes 10 arguments";
    dies_ok { 
      $freshservice->create_requester(
        name        => 'test',
        test        => 'test',
      ) 
    } "method 'create_requester' only takes valid arguments";
    dies_ok { 
      $freshservice->requester(
        id      => 'test',
        email   => 'test',
        email   => 'test',
      ) 
    } "method '_user' only takes 2 arguments";
    dies_ok { 
      $freshservice->requester(
        id      => 'test',
        test    => 'test',
      ) 
    } "method '_user' only takes valid arguments";
  };
}

done_testing();
__END__
