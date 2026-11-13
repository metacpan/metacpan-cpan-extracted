use 5.016;
use warnings;

use lib 't/lib';

use Test::More;

use Local::Resources;
use Twilio::InstanceContext;

my (undef, $version) = Local::Resources::build();

subtest 'an instance keeps the record' => sub {
  my $instance = Local::Instance->new($version, { sid => 'SM1' }, { account_sid => 'ACxx' });

  is($instance->sid, 'SM1', 'accessor');
  is_deeply($instance->{solution}, { account_sid => 'ACxx' }, 'solution');
  is($instance->{version}, $version, 'version');
};

subtest 'fields newer than the library are kept' => sub {
  my $instance = Local::Instance->new($version, { sid => 'SM1', new_field => 'value' });
  is($instance->to_hash->{new_field}, 'value', 'reachable through to_hash');
};

subtest 'to_hash is a copy' => sub {
  my $payload  = { sid => 'SM1' };
  my $instance = Local::Instance->new($version, $payload);

  $payload->{sid} = 'changed';
  $instance->to_hash->{sid} = 'changed too';

  is($instance->sid, 'SM1', 'neither the payload nor the result reach the instance');
};

subtest 'an unusable payload is an empty record' => sub {
  for my $payload (undef, 'text', [1]) {
    my $instance = Local::Instance->new($version, $payload);
    is_deeply($instance->to_hash, {}, 'no fields');
    is($instance->sid, undef, 'accessor is undef');
  }
};

subtest 'lists and contexts start with their version' => sub {
  for my $class (qw(Twilio::ListResource Twilio::InstanceContext)) {
    my $object = $class->new($version);
    is($object->{version}, $version, "$class version");
    is_deeply($object->{solution}, {}, "$class solution");
  }
};

subtest 'a list without read does not respond to it' => sub {
  my $list = Twilio::ListResource->new($version);
  ok(!$list->can('read'),   'no read');
  ok(!$list->can('stream'), 'no stream');
  ok(!$list->can('page'),   'no page');
};

done_testing;
