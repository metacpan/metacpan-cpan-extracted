use Test::More tests => 3;

# load module
package MyVal;
use Validation::Class;

my $passer = sub {1};

field 'id',
  { label      => 'ID',
    error      => 'id error',
    min_length => 24,
    max_length => 24
  };

field 'id2', {
    label      => 'ID',
    required   => 1,
    error      => 'id error',
    min_length => 24,
    max_length => 24

};

field 'login',
  { label      => 'user login',
    error      => 'login invalid',
    validation => $passer
  };

field 'password',
  { label      => 'user password',
    error      => 'password invalid',
    validation => $passer
  };

field 'name',
  { label      => 'user name',
    error      => 'invalid name',
    validation => $passer
  };

field 'phone',
  { label      => 'user phone',
    error      => 'phone invalid',
    validation => $passer
  };

field 'email',
  { label      => 'user email',
    error      => 'email invalid',
    validation => $passer
  };

package main;

my $v = MyVal->new(
    params => {
        id2      => '',
        login    => 'admin',
        password => 'pass'
    }
);

ok $v, 'validation-class initialized';

ok !$v->validate(qw/id2 login password/),
  'validation works and found id error';
ok $v->errors_to_string eq 'id error', 'id error found with correct value';
