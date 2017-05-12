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
  

  my $user = WebService::Freshservice::User->new(
    api  => $api,
    id   => '1234567890',
  );
  
  subtest 'Instantiation' => sub {
    isa_ok($user, "WebService::Freshservice::User");
    
    can_ok($user, qw( delete_requester ) );
  };
  
  subtest 'Retrieved Values' => sub {
    is( $user->active, 1, "'active' returned true");
    is( $user->address, "An Address", "'address' returned a value");
    is( $user->created_at, '2016-07-11T16:02:28+08:00', "'created_at' returned a raw date");
    cmp_deeply( 
      $user->get_custom_field('cf_field_name'),  
      all(
        isa("WebService::Freshservice::User::CustomField"),
        methods( 
          value => 'field value',
          field => 'cf_field_name',
          api   =>  ignore(),
        ),
      ), "'custom_field' returns a object"
    );
    is( $user->deleted, 0, "'deleted' returned false");
    is( $user->department_names, '', "'department_names' returned empty");
    is( $user->description, "I'm Testy McTestFace", "'description' returned a value");
    is( $user->email, 'test@example.com', "'email' returned an email address");
    is( $user->external_id, 123456, "'external_id' returned a value");
    is( $user->helpdesk_agent, 0, "'helpdesk_agent' returned false");
    is( $user->id, 1234567890, "'id' returned a value");
    is( $user->job_title, "Tester of Things", "'job_title' returned a value");
    is( $user->language, 'en', "'language' returned a value");
    is( $user->location_name, "Testland", "'location_name' returned a value");
    is( $user->mobile, "0406000000", "'mobile' returned a value");
    is( $user->name, "Test", "'name' returned a value");
    is( $user->phone, "0386521453", "'phone' returned a value");
    is( $user->time_zone, 'Perth', "'time_zone' returned a value");
    is( $user->updated_at, '2016-07-18T09:28:47+08:00', "'updated_at' returned a raw date");
  };

  subtest 'Actions' => sub {
    is( $user->delete_requester, 1, "Requester deletes work correctly" );
  };
  
  subtest 'Attribute Clearing' => sub {
    $user->_clear_all;
    my @attributes = qw( 
      active created_at custom_field deleted department_names 
      helpdesk_agent updated_at address description email external_id 
      language location_name job_title mobile name phone time_zone _raw
    );
    foreach my $attr (@attributes) {
      is( $user->{$attr}, undef, "Attribute '$attr' was cleared" );
    }
  };
   
  subtest 'Attribute Updating' => sub {
    my $update = WebService::Freshservice::User->new(
      api  => $api,
      id   => '1337',
    );
   
    # Simple Attributes
    is( $update->name, "Test", "Name correct on initial population" );
    $update->name('Elite');
    $update->update_requester;
    is( $update->name, "Elite", "Name correct post object update" );
    $update->update_requester( attr => 'name', value => 'Dangerous' );
    is( $update->name, "Dangerous", "Individual attribute update completed" );

    ## Custom Fields
    cmp_deeply( 
      $update->get_custom_field('cf_field_name'),  
      all(
        isa("WebService::Freshservice::User::CustomField"),
        methods( 
          field => 'cf_field_name',
          value => 'field value',
          api   =>  ignore(),
        ),
      ), "'custom_field' returns a object without a value"
    );
    $update->set_custom_field( 
      field => 'cf_field_name',
      value => 'strawberry fields'
    );
    
    my $confirm = WebService::Freshservice::User->new(
      api  => $api,
      id   => '1337',
    );
    cmp_deeply( 
      $confirm->get_custom_field('cf_field_name'),  
      all(
        isa("WebService::Freshservice::User::CustomField"),
        methods( 
          field => 'cf_field_name',
          value => 'strawberry fields',
          api   =>  ignore(),
        ),
      ), "'custom_field' value immediately"
    );

    $update->set_custom_field( 
      field   => 'cf_field_name',
      value   => 'forever',
      update  => 0,
    );
    
    my $noupdate = WebService::Freshservice::User->new(
      api  => $api,
      id   => '1337',
    );
    cmp_deeply( 
      $noupdate->get_custom_field('cf_field_name'),  
      all(
        isa("WebService::Freshservice::User::CustomField"),
        methods( 
          field => 'cf_field_name',
          value => 'strawberry fields',
          api   =>  ignore(),
        ),
      ), "'custom_field' value not updated immediately"
    );

    $update->update_requester;

    my $updated = WebService::Freshservice::User->new(
      api  => $api,
      id   => '1337',
    );
    cmp_deeply( 
      $updated->get_custom_field('cf_field_name'),  
      all(
        isa("WebService::Freshservice::User::CustomField"),
        methods( 
          field => 'cf_field_name',
          value => 'forever',
          api   =>  ignore(),
        ),
      ), "'custom_field' value not updated after requester update"
    );

    is($updated->get_custom_field('cf_field_name')->value, "forever", "Custom field values can be called inline");
  
    my $no_cf = WebService::Freshservice::User->new(
      api  => $api,
      id   => '1338',
    );
    cmp_deeply( 
      $no_cf->custom_field,
      noclass( { } ),
      "'custom_field' is an empty object if no custom fields exist",
    );
    throws_ok
      { $no_cf->get_custom_field('no field') }
      qr/Custom field must exist in Freshservice/,
      "'get_custom_field' dies if retrieval of a field isn't present"
    ;

    # Non modifiable fields
    my @attributes = qw( 
      active custom_field created_at deleted department_names
      helpdesk_agent updated_at
    );
    foreach my $attr (@attributes) {
      dies_ok { $user->update_requester( attr => $attr, value => "update" ) } "'$attr' is non writeable, croaks accordingly";
    }
  };

  subtest 'Failures' => sub {
    dies_ok { $user->_build_user('argument') } "method '_build_user' doesn't accept arguments";
    dies_ok { $user->_build__raw('argurment') } "method '_build__raw' doesn't accept arguments";
    dies_ok { $user->_build__attributes('argurment') } "method '_build__attributes' doesn't accept arguments";
    dies_ok { $user->_build__attributes_rw('argurment') } "method '_build__attributes_rw' doesn't accept arguments";
    dies_ok { $user->_build_custom_field('argurment') } "method '_build_custom_field' doesn't accept arguments";
    dies_ok { $user->_clear_all('argument') } "method '_clear_all' doesn't accept arguments";
    dies_ok { $user->delete_requester('argurment') } "method 'delete_reqester' doesn't accept arguments";
    dies_ok { $user->update_requester(attr => 1, value => 1, attr => 1) } "method 'update_requester' only takes 4 arguments";
    dies_ok { $user->update_requester(attr => 1, cow => 1) } "method 'update_requester' requires valid arguments";
    dies_ok { $user->set_custom_field(field => 1, value => 1, update => 1, update => 1) } "method 'set_custom_field' only takes 6 arguments";
    dies_ok { $user->set_custom_field() } "method 'set_custom_field' requires arguments";
    dies_ok { $user->get_custom_field() } "method 'get_custom_field' requires arguments";
    dies_ok { $user->set_custom_field('arg1', 'value') } "method 'set_custom_field' only accepts valid arguments";
    dies_ok { $user->get_custom_field('arg1','arg2') } "method 'get_custom_field' only takes 1 argument";
    dies_ok { $user->TO_JSON('argument') } "method 'TO_JSON' doesn't accept arguments";
    throws_ok { $user->update_requester( attr => 'mobile' ) } qr/'value' required if providing an 'attr'/, "method 'update_requester' requires a 'value' if a 'attr' is provided";
  };
}

done_testing();
__END__
