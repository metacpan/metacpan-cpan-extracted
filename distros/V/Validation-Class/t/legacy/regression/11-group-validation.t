use Test::More tests => 21;

package MyVal;
use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {
        'user.login'    => {error => 'login error'},
        'user.password' => {
            error      => 'password error',
            min_length => 3,
            max_length => 9,
            pattern    => 'XXX######'
        }
    },
    params => {
        'user.login'    => 'member',
        'user.password' => 'abc123456'
    }
);

ok $v, 'class initialized';
ok defined $v->fields->{'user.login'}, 'login field exists';
ok defined $v->params->{'user.login'}, 'login param exists';

# check min_length directive
$v->fields->{'user.login'}->{min_length} = 10;
ok !$v->validate('user.login'), 'error found as expected';
ok !$v->validate, 'alternate use of validation found error also';
ok $v->error_count == 1, 'error count is correct';
ok $v->errors_to_string eq 'login error', 'error message specified captured';

$v->fields->{'user.login'}->{min_length} = 5;
ok $v->validate('user.login'), 'user.login rule validates';
ok $v->validate, 'alternate use of validation validates';
ok $v->error_count == 0, 'error count is zero';
ok $v->errors_to_string eq '', 'no error messages found';

# check max_length directive
$v->fields->{'user.login'}->{max_length} = 5;
ok !$v->validate('user.login'), 'error found as expected';
ok !$v->validate, 'alternate use of validation found error also';
ok $v->error_count == 1, 'error count is correct';
ok $v->errors_to_string eq 'login error', 'error message specified captured';

$v->fields->{'user.login'}->{max_length} = 9;
ok $v->validate('user.login'), 'user.login rule validates';
ok $v->validate, 'alternate use of validation validates';
ok $v->error_count == 0, 'error count is zero';
ok $v->errors_to_string eq '', 'no error messages found';

# grouped fields perform like normal fields, now testing validation and
# extraction routines

# my $obj = $v->unflatten_params(); - DEPRECATED
my $obj = $v->proto->unflatten_params($v->proto->params->hash);
ok defined $obj->{user}->{login} && $obj->{user}->{login},
  'unflatten_params has user hash with login key';
ok defined $obj->{user}->{password} && $obj->{user}->{password},
  'unflatten_params has user hash with password key';
