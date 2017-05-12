use Test::More tests => 3;

package MyVal;

use Validation::Class;

field email  => {required => 1};
field email1 => {required => 1};
field email2 => {required => 1};
field email3 => {required => 1};

package main;

my $v = MyVal->new(
    params => {
        email  => 1,
        email1 => 1,
        email2 => 1,
        email3 => 1
    }
);

ok $v, 'initialization successful';
ok $v->validate(qr/email(\d+)?/), 'validation passed';
ok $v->error_count == 0, 'validation ok';
