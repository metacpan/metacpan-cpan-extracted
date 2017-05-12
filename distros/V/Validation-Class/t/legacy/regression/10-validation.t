use Test::More tests => 27;

package MyVal;

use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {foobar => {error => 'foobar error'}},
    params => {foobar => 'abc123456'}
);

ok $v, 'class initialized';
ok defined $v->fields->{foobar}, 'foobar field exists';
ok defined $v->params->{foobar}, 'foobar param exists';

# check min_length directive
$v->fields->{foobar}->{min_length} = 10;
ok !$v->validate('foobar'), 'error found as expected';
ok !$v->validate, 'alternate use of validation found error also';
ok $v->error_count == 1, 'error count is correct';
ok $v->errors_to_string eq 'foobar error', 'error message specified captured';

$v->fields->{foobar}->{min_length} = 5;
ok $v->validate('foobar'), 'foobar rule validates';
ok $v->validate, 'alternate use of validation validates';
ok $v->error_count == 0, 'error count is zero';
ok $v->errors_to_string eq '', 'no error messages found';

# check max_length directive
$v->fields->{foobar}->{max_length} = 8;
ok !$v->validate('foobar'), 'error found as expected';
ok !$v->validate, 'alternate use of validation found error also';
ok $v->error_count == 1, 'error count is correct';
ok $v->errors_to_string eq 'foobar error', 'error message specified captured';

$v->fields->{foobar}->{max_length} = 9;
ok $v->validate('foobar'), 'foobar rule validates';
ok $v->validate, 'alternate use of validation validates';
ok $v->error_count == 0, 'error count is zero';
ok $v->errors_to_string eq '', 'no error messages found';

# check pattern directive
$v->fields->{foobar}->{pattern} = 'XXX######';
ok $v->validate('foobar'), 'foobar rule validates';
ok $v->validate, 'alternate use of validation validates';
ok $v->error_count == 0, 'error count is zero';
ok $v->errors_to_string eq '', 'no error messages found';

# check pattern (telephone example) directive
delete $v->fields->{foobar}->{error};
$v->fields->{foobar}->{pattern} = '(###) ###-####';
$v->params->{foobar} = '111-1111';
ok !$v->validate('foobar'), 'foobar rule doesnt validate';
ok !$v->validate, 'alternate use of validation doesnt validate';
ok $v->error_count == 1, 'error count is correct';
ok $v->errors_to_string =~ 'not formatted', 'pattern error message found';
