use strict;
use warnings;
use Test::More;

use_ok('Trickster::Validator');

# Test required validation
my $validator = Trickster::Validator->new({
    name => ['required'],
    email => ['required', 'email'],
});

ok(!$validator->validate({}), 'Validation fails for empty data');
ok(exists $validator->errors->{name}, 'Name error exists');
ok(exists $validator->errors->{email}, 'Email error exists');

ok($validator->validate({ name => 'Alice', email => 'alice@example.com' }), 
   'Validation passes for valid data');

# Test min/max validation
$validator = Trickster::Validator->new({
    age => ['numeric', ['min', 18], ['max', 100]],
    username => [['min', 3], ['max', 20]],
});

ok(!$validator->validate({ age => 15 }), 'Age too low');
ok(!$validator->validate({ age => 150 }), 'Age too high');
ok($validator->validate({ age => 25 }), 'Age valid');

ok(!$validator->validate({ username => 'ab' }), 'Username too short');
ok($validator->validate({ username => 'alice' }), 'Username valid');

# Test email validation
$validator = Trickster::Validator->new({
    email => ['email'],
});

ok($validator->validate({ email => 'test@example.com' }), 'Valid email');
ok(!$validator->validate({ email => 'invalid' }), 'Invalid email');

# Test in validation
$validator = Trickster::Validator->new({
    role => [['in', 'admin', 'user', 'guest']],
});

ok($validator->validate({ role => 'admin' }), 'Valid role');
ok(!$validator->validate({ role => 'superuser' }), 'Invalid role');

# Test custom validation
$validator = Trickster::Validator->new({
    password => [['custom', sub {
        my $val = shift;
        return 'Password too weak' if length($val) < 8;
        return 'Password must contain a number' unless $val =~ /\d/;
        return undef;
    }]],
});

ok(!$validator->validate({ password => 'short' }), 'Password too short');
ok(!$validator->validate({ password => 'nodigits' }), 'Password needs digit');
ok($validator->validate({ password => 'secure123' }), 'Valid password');

done_testing;
