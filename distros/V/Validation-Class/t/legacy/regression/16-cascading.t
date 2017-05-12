use Test::More tests => 5;

package MyVal;

use Validation::Class;

field password      => {required    => 1};
field password_conf => {mixin_field => 'password', matches => 'password'};
field chng_password => {depends_on  => ['password_conf']};

package main;

my $v = MyVal->new(params => {chng_password => 1});

ok $v, 'initialization successful';
ok !$v->validate(qw/chng_password password_conf/), 'validation failed';
ok $v->error_count == 1, 'validation failed because password_conf is requried';

$v->params->add(password_conf => 1);

ok !$v->validate(qw/chng_password password_conf/), 'validation failed';
ok $v->error_count == 1,
  'validation failed because password_conf does not match password';
