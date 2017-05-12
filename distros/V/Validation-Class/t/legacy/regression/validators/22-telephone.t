use Test::More;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(fields => {phone => {telephone => 1}});

# failures

$r->params->{phone} = '0000000';
ok !$r->validate(), '0000000 is invalid';
$r->params->{phone} = '1115551212';
ok !$r->validate(), '1115551212 is invalid';

# successes

$r->params->{phone} = '2155551212';
ok $r->validate(), '2155551212 is valid';
$r->params->{phone} = '12155551212';
ok $r->validate(), '12155551212 is valid';
$r->params->{phone} = '+12155551212';
ok $r->validate(), '+12155551212 is valid';
$r->params->{phone} = '+1 215 555-1212';
ok $r->validate(), '+1 215 555-1212 is valid';
$r->params->{phone} = '+1 (215) 555-1212';
ok $r->validate(), '+1 (215) 555-1212 is valid';
$r->params->{phone} = '(215) 555-1212';
ok $r->validate(), '(215) 555-1212 is valid';
$r->params->{phone} = '215 555 1212';
ok $r->validate(), '215 555 1212 is valid';

done_testing;
