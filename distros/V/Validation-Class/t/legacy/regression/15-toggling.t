use Test::More tests => 7;

package MyVal;

use Validation::Class;

field name    => {required => 1};
field email   => {required => 1};
field phone   => {required => 1};
field address => {required => 1};
field company => {};
field fax     => {};
field country => {
    validation => sub {0}
};

package main;

my $v = MyVal->new(params => {});

ok $v, 'initialization successful';
ok $v->validate('country'), 'country validation passed, not required';
ok !$v->validate('+country'), 'country validation failed, requirement toggled';
ok $v->validate('country'), 'country validation passed, not required';
ok !$v->validate('name'), 'name validation failed, required';
ok $v->validate('-name'), 'name validation passed, requirement toggled';
ok !$v->validate('name'), 'name validation failed, required';
