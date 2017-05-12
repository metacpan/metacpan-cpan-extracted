use Test::More 'no_plan';

use strict;
use warnings;
use utf8;
use Validator::Custom;

# create new validation object
{
  my $vc = Validator::Custom->new;
  my $validation1 = $vc->validation;
  my $validation2 = $vc->validation;
  is(ref $validation1, 'Validator::Custom::Validation');
  is(ref $validation2, 'Validator::Custom::Validation');
  isnt($validation1, $validation2);
}

# check
{
  # check - int
  {
    my $vc = Validator::Custom->new;
    my $k1 = '19';
    my $k2 = '-10';
    my $k3 = 'a';
    my $k4 =  '10.0';
    my $k5 ='２';
    my $k6;
      
    my $validation = $vc->validation;
    if (!$vc->check($k1, 'int')) {
        $validation->add_failed('k1');
    }
    if (!$vc->check($k2, 'int')) {
      $validation->add_failed('k2');
    }
    if (!$vc->check($k3, 'int')) {
      $validation->add_failed('k3');
    }
    if (!$vc->check($k4, 'int')) {
      $validation->add_failed('k4');
    }
    if (!$vc->check($k5, 'int')) {
      $validation->add_failed('k5');
    }
    if (!$vc->check($k6, 'int')) {
      $validation->add_failed('k6');
    }
    
    is_deeply($validation->failed, ['k3', 'k4', 'k5', 'k6']);
  }
  
  # check - ascii_graphic
  {
    my $vc = Validator::Custom->new;
    my $k1 = '!~';
    my $k2 = ' ';
    my $k3 = "\0x7f";
    my $k4;
      
    my $validation = $vc->validation;
    if (!$vc->check($k1, 'ascii_graphic')) {
      $validation->add_failed('k1');
    }
    if (!$vc->check($k2, 'ascii_graphic')) {
      $validation->add_failed('k2');
    }
    if (!$vc->check($k3, 'ascii_graphic')) {
      $validation->add_failed('k3');
    }
    if (!$vc->check($k4, 'ascii_graphic')) {
      $validation->add_failed('k4');
    }
    
    is_deeply($validation->failed, ['k2', 'k3', 'k4']);
  }

  # check - number
  {
    my $vc = Validator::Custom->new;
    my $k1 = '1';
    my $k2 = '123';
    my $k3 = '456.123';
    my $k4 = '-1';
    my $k5 = '-789';
    my $k6 = '-100.456';
    my $k7 = '-100.789';
    
    my $k8 = 'a';
    my $k9 = '1.a';
    my $k10 = 'a.1';
    my $k11 = '';
    my $k12;
    
    my $validation = $vc->validation;
    if (!$vc->check($k1, 'number')) {
      $validation->add_failed('k1');
    }
    if (!$vc->check($k2, 'number')) {
      $validation->add_failed('k2');
    }
    if (!$vc->check($k3, 'number')) {
      $validation->add_failed('k3');
    }
    if (!$vc->check($k4, 'number')) {
      $validation->add_failed('k4');
    }
    if (!$vc->check($k5, 'number')) {
      $validation->add_failed('k5');
    }
    if (!$vc->check($k6, 'number')) {
      $validation->add_failed('k6');
    }
    if (!$vc->check($k7, 'number')) {
      $validation->add_failed('k7');
    }
    if (!$vc->check($k8, 'number')) {
      $validation->add_failed('k8');
    }
    if (!$vc->check($k9, 'number')) {
      $validation->add_failed('k9');
    }
    if (!$vc->check($k10, 'number')) {
      $validation->add_failed('k10');
    }
    if (!$vc->check($k11, 'number')) {
      $validation->add_failed('k11');
    }
    if (!$vc->check($k12, 'number')) {
      $validation->add_failed('k12');
    }
    is_deeply($validation->failed, [qw/k8 k9 k10 k11 k12/]);
  }

  # check - number, decimal_part_max
  {
    my $vc = Validator::Custom->new;
    my $k1 = '1';
    my $k2 = '123';
    my $k3 = '456.123';
    my $k4 = '-1';
    my $k5 = '-789';
    my $k6 = '-100.456';
    my $k7 = '-100.789';
    
    my $k8 = 'a';
    my $k9 = '1.a';
    my $k10 = 'a.1';
    my $k11 = '';
    my $k12;
    
    my $k13 = '456.1234';
    my $k14 = '-100.7894';
    
    my $validation = $vc->validation;
    if (!$vc->check($k1, 'number', {decimal_part_max => 3})) {
      $validation->add_failed('k1');
    }
    if (!$vc->check($k2, 'number', {decimal_part_max => 3})) {
      $validation->add_failed('k2');
    }
    if (!$vc->check($k3, 'number', {decimal_part_max => 3})) {
      $validation->add_failed('k3');
    }
    if (!$vc->check($k4, 'number', {decimal_part_max => 3})) {
      $validation->add_failed('k4');
    }
    if (!$vc->check($k5, 'number', {decimal_part_max => 3})) {
      $validation->add_failed('k5');
    }
    if (!$vc->check($k6, 'number', {decimal_part_max => 3})) {
      $validation->add_failed('k6');
    }
    if (!$vc->check($k7, 'number', {decimal_part_max => 3})) {
      $validation->add_failed('k7');
    }
    if (!$vc->check($k8, 'number', {decimal_part_max => 3})) {
      $validation->add_failed('k8');
    }
    if (!$vc->check($k9, 'number', {decimal_part_max => 3})) {
      $validation->add_failed('k9');
    }
    if (!$vc->check($k10, 'number', {decimal_part_max => 3})) {
      $validation->add_failed('k10');
    }
    if (!$vc->check($k11, 'number', {decimal_part_max => 3})) {
      $validation->add_failed('k11');
    }
    if (!$vc->check($k12, 'number', {decimal_part_max => 3})) {
      $validation->add_failed('k12');
    }
    if (!$vc->check($k13, 'number', {decimal_part_max => 3})) {
      $validation->add_failed('k13');
    }
    if (!$vc->check($k14, 'number', {decimal_part_max => 3})) {
      $validation->add_failed('k14');
    }

    is_deeply($validation->failed, [qw/k8 k9 k10 k11 k12 k13 k14/]);
  }
  
  # check - in
  {
    my $vc = Validator::Custom->new;
    my $k1 = 'a';
    my $k2 = 'a';
    my $k3;
    
    my $validation = $vc->validation;
    if (!($vc->check($k1, 'in', ['a', 'b']))) {
      $validation->add_failed('k1');
    }
    if (!($vc->check($k2, 'in', ['b', 'c']))) {
      $validation->add_failed('k2');
    }
    if (!($vc->check($k3, 'in', ['b', 'c']))) {
      $validation->add_failed('k3');
    }
    
    is_deeply($validation->failed, ['k2', 'k3']);
  }

  # check - exception, few arguments
  {
    my $vc = Validator::Custom->new;
    eval { $vc->check() };
    like($@, qr/value and the name of a checking function must be passed/);
    
    eval { $vc->check(3) };
    like($@, qr/value and the name of a checking function must be passed/);
  }

  # check - exception, checking function not found
  {
    my $vc = Validator::Custom->new;
    eval { $vc->check(1, 'foo') };
    like($@, qr/Can't call "foo" checking function/);
  }
}

# filter
{
  # remove_blank filter
  {
    my $vc = Validator::Custom->new;
    my $k1 =[1, 2];
    my $k2 = [1, 3, '', '', undef];
    my $k3 = [];
    
    $k1 = $vc->filter($k1, 'remove_blank');
    $k2 = $vc->filter($k2, 'remove_blank');
    $k3 = $vc->filter($k3, 'remove_blank');
    
    is_deeply($k1, [1, 2]);
    is_deeply($k2, [1, 3]);
    is_deeply($k3, []);
  }
  
  # filter - remove_blank, exception
  {
    my $vc = Validator::Custom->new;
    my $k1 = 1;
    eval {$k1 = $vc->filter($k1, 'remove_blank')};
    like($@, qr/must be array reference/);
  }

  # filter - trim
  {
    my $vc = Validator::Custom->new;
    my $k1 = ' 　　123　　 ';
    my $k2;
    
    $k1 = $vc->filter($k1, 'trim');
    $k2 = $vc->filter($k2, 'trim');
    
    is($k1, '123');
    ok(!defined $k2);
  }

  # filter - exception, few arguments
  {
    my $vc = Validator::Custom->new;
    eval { $vc->filter() };
    like($@, qr/value and the name of a filtering function must be passed/);
    
    eval { $vc->filter(3) };
    like($@, qr/value and the name of a filtering function must be passed/);
  }

  # filter - exception, filtering function not found
  {
    my $vc = Validator::Custom->new;
    eval { $vc->filter(1, 'foo') };
    like($@, qr/Can't call "foo" filtering function/);
  }
}

# add_check
{
  my $vc = Validator::Custom->new;
  my $is_first_arg_object;
  $vc->add_check('equal' => sub {
    my ($vc2, $value, $arg) = @_;
    
    if ($vc eq $vc2) {
      $is_first_arg_object = 1;
    }
    
    if ($value eq $arg) {
      return 1;
    }
    else {
      return 0;
    }
  });
  
  my $k1 = 'a';
  my $k2 = 'a';
  
  my $validation = $vc->validation;
  
  if (!($vc->check($k1, 'equal', 'a'))) {
    $validation->add_failed('k1');
  }
  
  if (!($vc->check($k1, 'equal', 'b'))) {
    $validation->add_failed('k2');
  }
  
  is_deeply($validation->failed, ['k2']);
  ok($is_first_arg_object);
}

# add_filter
{
  my $vc = Validator::Custom->new;
  my $is_first_arg_object;
  $vc->add_filter('cat' => sub {
    my ($vc2, $value, $arg) = @_;
    
    if ($vc eq $vc2) {
      $is_first_arg_object = 1;
    }
    
    return "$value$arg";
  });
  
  my $k1 = 'a';
  
  my $validation = $vc->validation;
  
  $k1 = $vc->filter($k1, 'cat', 'b');
  
  is($k1, 'ab');
  ok($is_first_arg_object);
}

# check_each
{
  # check_each - int
  {
    my $vc = Validator::Custom->new;
    my $k1 = ['19', '20'];
    my $k2 = ['a', '19'];
      
    my $validation = $vc->validation;
    if (!$vc->check_each($k1, 'int')) {
      $validation->add_failed('k1');
    }
    if (!$vc->check_each($k2, 'int')) {
      $validation->add_failed('k2');
    }
    is_deeply($validation->failed, ['k2']);
  }
  
  # check_each - arguments
  {
    my $vc = Validator::Custom->new;
    my $is_first_arg_object;
    my $validation = $vc->validation;
    $vc->add_check('equal' => sub {
      my ($vc2, $value, $arg) = @_;
      
      if ($vc eq $vc2) {
        $is_first_arg_object = 1;
      }
      
      if ($value eq $arg) {
        return 1;
      }
      else {
        return 0;
      }
    });
    
    my $k1 = ['a', 'a'];
    my $k2 = ['a', 'b'];
    
    if (!$vc->check_each($k1, 'equal', 'a')) {
      $validation->add_failed('k1');
    }

    if (!$vc->check_each($k2, 'equal', 'a')) {
      $validation->add_failed('k2');
    }
    
    is_deeply($validation->failed, ['k2']);
    ok($is_first_arg_object);
  }

  # check_each - exception, few arguments
  {
    my $vc = Validator::Custom->new;
    eval { $vc->check_each() };
    like($@, qr/values and the name of a checking function must be passed/);
    
    eval { $vc->check_each([]) };
    like($@, qr/values and the name of a checking function must be passed/);
  }

  # check_each - exception, checking function not found
  {
    my $vc = Validator::Custom->new;
    eval { $vc->check_each([1], 'foo') };
    like($@, qr/Can't call "foo" checking function/);
  }

  # check - exception, values is not array reference
  {
    my $vc = Validator::Custom->new;
    eval { $vc->check_each(1, 'int') };
    like($@, qr/values must be array reference/);
  }
}

# filter_each
{
  # filter_each - int
  {
    my $vc = Validator::Custom->new;
    my $k1 = [' a ', ' b '];
      
    my $validation = $vc->validation;
    $k1 = $vc->filter_each($k1, 'trim');

    is_deeply($k1, ['a', 'b']);
  }
  
  # filter_each - arguments
  {
    my $vc = Validator::Custom->new;
    my $is_first_arg_object;
    $vc->add_filter('cat' => sub {
      my ($vc2, $value, $arg) = @_;
      
      if ($vc eq $vc2) {
        $is_first_arg_object = 1;
      }
      
      return "$value$arg";
    });
    
    my $k1 = ['a', 'c'];
    
    my $validation = $vc->validation;
    
    $k1 = $vc->filter_each($k1, 'cat', 'b');
    
    is_deeply($k1, ['ab', 'cb']);
    ok($is_first_arg_object);
  }
  
  # filter_each - exception, few arguments
  {
    my $vc = Validator::Custom->new;
    eval { $vc->filter_each() };
    like($@, qr/values and the name of a filtering function must be passed/);
    
    eval { $vc->filter_each([]) };
    like($@, qr/values and the name of a filtering function must be passed/);
  }

  # filter_each - exception, filtering function not found
  {
    my $vc = Validator::Custom->new;
    eval { $vc->filter_each([1], 'foo') };
    like($@, qr/Can't call "foo" filtering function/);
  }

  # filter - exception, values is not array reference
  {
    my $vc = Validator::Custom->new;
    eval { $vc->filter_each(1, 'trim') };
    like($@, qr/values must be array reference/);
  }
}
