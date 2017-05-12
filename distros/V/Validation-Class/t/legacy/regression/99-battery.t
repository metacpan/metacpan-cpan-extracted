use Test::More tests => 17;

package MyVal;

use Validation::Class;

# declare validation rules
mixin 'basic' => {
    required   => 1,
    min_length => 1,
    max_length => 255,
    filters    => ['lowercase', 'alphanumeric']
};

mixin 'validation' => {};

field 'login' => {
    mixin      => 'basic',
    label      => 'user login',
    error      => 'login invalid',
    validation => sub {
        my ($self, $this, $fields) = @_;
        return $this->{value} eq 'admin' ? 1 : 0;
      }
};

field 'password' => {
    mixin      => 'basic',
    label      => 'user password',
    error      => 'password invalid',
    validation => sub {
        my ($self, $this, $fields) = @_;
        return $this->{value} eq 'pass' ? 1 : 0;
      }
};

field 'something' => {mixin => ['basic', 'validation']};

package main;

# create instance
my $v = MyVal->new;
ok $v, 'instance created';

# verify fields received mixins
ok defined $v->fields->{login}->{required}
  && defined $v->fields->{login}->{min_length}
  && defined $v->fields->{login}->{max_length},
  'login field received mixin';
ok defined $v->fields->{password}->{required}
  && defined $v->fields->{password}->{min_length}
  && defined $v->fields->{password}->{max_length},
  'password field received mixin';

# check attributes
ok $v->params, 'params attr ok';
ok $v->fields, 'fields attr ok';

# ok $v->mixins,  'mixins attr ok'; - DEPRECATED
ok $v->proto->mixins, 'mixins attr ok';

# ok $v->filters, 'filters attr ok'; - DEPRECATED
ok $v->proto->filters, 'filters attr ok';

# ok $v->types,   'types attr ok'; - DEPRECATED
# ok $v->proto->types,   'types attr ok';

# process field with multiple mixins
ok defined $v->fields->{something}->{required}
  && defined $v->fields->{something}->{min_length}
  && defined $v->fields->{something}->{max_length},
  'something field generated from multiple mixins';

# define grouped fields
$v->fields->{'auth.login'} = {
    mixin      => 'basic',
    label      => 'user login',
    error      => 'login invalid',
    validation => sub {
        my ($self, $this, $fields) = @_;
        return $this->{value} eq 'admin' ? 1 : 0;
      }
};

$v->fields->{'auth.password'} = {
    mixin      => 'basic',
    label      => 'user password',
    error      => 'password invalid',
    validation => sub {
        my ($self, $this, $fields) = @_;
        return $this->{value} eq 'pass' ? 1 : 0;
      }
};

$v->fields->{'user.name'} = {
    mixin      => 'basic',
    label      => 'user name',
    error      => 'invalid name',
    validation => sub {
        my ($self, $this, $fields) = @_;
        return 1;
      }
};

$v->fields->{'user.phone'} = {
    mixin      => 'basic',
    label      => 'user phone',
    error      => 'phone invalid',
    validation => sub {
        my ($self, $this, $fields) = @_;
        return 0;
      }
};

$v->fields->{'user.email'} = {
    mixin      => 'basic',
    label      => 'user email',
    error      => 'email invalid',
    validation => sub {
        my ($self, $this, $fields) = @_;
        return 1;
      }
};

package main;

my $params = {
    login    => 'admin1%^&%&^%^%&',
    password => 'pass@@@#$#%$^',
    name     => 'al newkirk',
    phone    => '2155551212',
    email    => 'awncorp2cpan.org'
};

$v = MyVal->new(params => $params, fields => $v->fields->hash);

# params set at new function
ok scalar(keys %{$v->params}), 'params have been set at instantiation';

# error class exists
ok !$v->error_count, 'error count reporting';

# validate login only
ok !$v->validate({login => 'auth.login'}), 'login field failed as expected';
ok $v->error_count == 1, 'error count accurate';
ok $v->errors_to_string eq 'login invalid',
  'error messages and error class to_string method works';

# check formatting
ok $v->params->{login}    eq 'admin1', 'login formatting worked';
ok $v->params->{password} eq 'pass',   'password formatting worked';

# process common password confirmation
$v->fields->{'password_cfm'} = {
    mixin_field => 'password',
    default     => 'pass',
    validation  => sub {
        my ($self, $this, $params) = @_;
        return $this->{value} eq $params->{password} ? 1 : 0;
      }
};

$v = MyVal->new(params => $v->params->hash, fields => $v->fields->hash);

ok $v->validate('password'), 'password field validates';
ok $v->validate('password', 'password_cfm'), 'password confirmation validates';
