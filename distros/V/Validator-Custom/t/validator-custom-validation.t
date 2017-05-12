use Test::More 'no_plan';

use strict;
use warnings;
use utf8;
use Validator::Custom;

my $vc = Validator::Custom->new;

# add failed
# contains tests of is_valid, message, messages, messages_to_hash 
{
  # add failed - add none
  {
    my $validation = $vc->validation;
    ok($validation->is_valid);
    ok($validation->is_valid('k1'));
    is_deeply($validation->messages, []);
    is_deeply($validation->messages_to_hash, {});
  }
  
  # add failed - add one failed name
  {
    my $validation = $vc->validation;
    $validation->add_failed('k1');
    ok(!$validation->is_valid);
    ok(!$validation->is_valid('k1'));
    is_deeply($validation->messages, ['k1 is invalid']);
    is($validation->message('k1'), 'k1 is invalid');
    is_deeply($validation->failed, ['k1']);
    is_deeply($validation->messages_to_hash, {k1 => 'k1 is invalid'});
  }

  # add failed - add one failed name with message
  {
    my $validation = $vc->validation;
    $validation->add_failed('k1' => 'k1 is wrong value');
    ok(!$validation->is_valid);
    ok(!$validation->is_valid('k1'));
    is_deeply($validation->messages, ['k1 is wrong value']);
    is($validation->message('k1'), 'k1 is wrong value');
    is_deeply($validation->failed, ['k1']);
    is_deeply($validation->messages_to_hash, {k1 => 'k1 is wrong value'});
  }

  # add failed - add three failed name
  {
    my $validation = $vc->validation;
    $validation->add_failed('k1');
    $validation->add_failed('k2');
    $validation->add_failed('k3');
    ok(!$validation->is_valid);
    ok(!$validation->is_valid('k1'));
    ok(!$validation->is_valid('k2'));
    ok(!$validation->is_valid('k3'));
    is_deeply($validation->messages, ['k1 is invalid', 'k2 is invalid', 'k3 is invalid']);
    is($validation->message('k1'), 'k1 is invalid');
    is($validation->message('k2'), 'k2 is invalid');
    is($validation->message('k3'), 'k3 is invalid');
    is_deeply($validation->failed, ['k1', 'k2', 'k3']);
    is_deeply(
      $validation->messages_to_hash,
      {
        k1 => 'k1 is invalid',
        k2 => 'k2 is invalid',
        k3 => 'k3 is invalid'
      }
    );
  }

  # add failed - add three failed name with message
  {
    my $validation = $vc->validation;
    $validation->add_failed('k1' => 'k1 is wrong value');
    $validation->add_failed('k2' => 'k2 is wrong value');
    $validation->add_failed('k3' => 'k3 is wrong value');
    ok(!$validation->is_valid);
    ok(!$validation->is_valid('k1'));
    ok(!$validation->is_valid('k2'));
    ok(!$validation->is_valid('k3'));
    is_deeply($validation->messages, ['k1 is wrong value', 'k2 is wrong value', 'k3 is wrong value']);
    is($validation->message('k1'), 'k1 is wrong value');
    is($validation->message('k2'), 'k2 is wrong value');
    is($validation->message('k3'), 'k3 is wrong value');
    is_deeply($validation->failed, ['k1', 'k2', 'k3']);
    is_deeply(
      $validation->messages_to_hash,
      {
        k1 => 'k1 is wrong value',
        k2 => 'k2 is wrong value',
        k3 => 'k3 is wrong value'
      }
    );
  }
}
