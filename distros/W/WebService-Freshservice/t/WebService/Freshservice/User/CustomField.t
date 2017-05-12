#!/usr/bin/env perl

use lib 't/lib/';

use WebService::Freshservice::Test;
use WebService::Freshservice::User;
use Test::Most;
use Test::Warnings;

my $tester = WebService::Freshservice::Test->new();

$tester->test_with_dancer(\&user_testing, 9);

sub user_testing {
  my ($api,$message) = @_;

  pass("User Testing: $message");  
  use_ok("WebService::Freshservice::User::CustomField");
  

  my $custom_field = WebService::Freshservice::User::CustomField->new(
    api   => $api,
    id    => '1337',
    field => 'cf_field_name',
    value => 'field value',
  );
  
  subtest 'Instantiation' => sub {
    isa_ok($custom_field, "WebService::Freshservice::User::CustomField");
    can_ok($custom_field, qw( update_custom_field ) );
  };


  subtest 'Updates' => sub {
    is($custom_field->value, 'field value', "Custom field value correct");
    is($custom_field->field, 'cf_field_name', "Custom field name correct");
    $custom_field->value("strawberry fields forever");
    $custom_field->update_custom_field;
    my $user = WebService::Freshservice::User->new(
      api   => $api,
      id    => '1337',
    );
    is($user->get_custom_field('cf_field_name')->value, "strawberry fields forever", "custom field updates correctly");
  };
  
  subtest 'Failures' => sub {
    dies_ok { $custom_field->update_custom_field('argument') } "method 'update_custom_field' doesn't accept arguments";
    dies_ok { $custom_field->TO_JSON('argument') } "method 'TO_JSON' doesn't accept arguments";
  };
}

done_testing();
__END__
