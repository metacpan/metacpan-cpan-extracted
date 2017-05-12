use Test::More tests => 15;

package MyVal;

use Validation::Class;

field email => {required => 1, min_length => 1, max_length => 255};

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

# $v->clone_field - DEPRECATED
$v->proto->clone_field('email', 'email3',
    {label => 'Third Email', required => 0});
$v->proto->clone_field('email', 'email2');
$v->proto->clone_field('email', 'email1');

ok $v->fields->{email1}->{required}, 'email1 cloned of email, has req';
ok 1 == $v->fields->{email1}->{min_length}, 'email1 cloned of email, has min';
ok 255 == $v->fields->{email1}->{max_length},
  'email1 cloned of email, has max';
ok !$v->fields->{email1}->{label}, 'email1 cloned of email, no label';

ok $v->fields->{email2}->{required}, 'email2 cloned of email, has req';
ok 1 == $v->fields->{email2}->{min_length}, 'email2 cloned of email, has min';
ok 255 == $v->fields->{email2}->{max_length},
  'email2 cloned of email, has max';
ok !$v->fields->{email2}->{label}, 'email2 cloned of email, no label';

ok !$v->fields->{email3}->{required}, 'email3 cloned of email, has no req';
ok 1 == $v->fields->{email3}->{min_length}, 'email3 cloned of email, has min';
ok 255 == $v->fields->{email3}->{max_length},
  'email3 cloned of email, has max';
ok $v->fields->{email3}->{label}, 'email3 cloned of email, has label';

ok $v->validate(qr/email(\d+)?/), 'validation passed';
ok $v->error_count == 0, 'validation ok';
