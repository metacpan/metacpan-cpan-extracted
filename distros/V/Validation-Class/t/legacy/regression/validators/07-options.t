use Test::More tests => 5;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(
    fields => {status => {options => 'Active, Inactive'}},
    params => {status => 'Active'}
);

ok $r->validate(), 'status is valid';
$r->params->{status} = 'active';

ok !$r->validate(), 'status case doesnt match';
ok 'status must be either Active or Inactive' eq $r->errors_to_string(),
  'displays proper error message';

$r->params->{status} = 'inactive';

ok !$r->validate(), 'status case doesnt match alt';

$r->params->{status} = 'Inactive';

ok $r->validate(), 'alternate status value validates';

#warn $r->errors_to_string();
