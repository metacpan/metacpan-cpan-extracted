use strict;
use warnings;
use Test::More;

use_ok('Trickster::Exception');

# Test basic exception
my $e = Trickster::Exception->new(
    message => 'Test error',
    status => 500,
);

is($e->message, 'Test error', 'Exception message');
is($e->status, 500, 'Exception status');
ok($e->stack_trace, 'Has stack trace');

# Test string overload
is("$e", 'Test error', 'String overload works');

# Test as_hash
my $hash = $e->as_hash;
is($hash->{error}, 'Test error', 'Hash representation');
is($hash->{status}, 500, 'Hash status');

# Test predefined exceptions
eval {
    Trickster::Exception::NotFound->throw(message => 'User not found');
};
my $not_found = $@;
ok($not_found->isa('Trickster::Exception::NotFound'), 'NotFound exception');
is($not_found->status, 404, 'NotFound status is 404');

eval {
    Trickster::Exception::BadRequest->throw(
        message => 'Invalid input',
        details => { field => 'email' }
    );
};
my $bad_request = $@;
ok($bad_request->isa('Trickster::Exception::BadRequest'), 'BadRequest exception');
is($bad_request->status, 400, 'BadRequest status is 400');
is($bad_request->message, 'Invalid input', 'Exception message');
is_deeply($bad_request->details, { field => 'email' }, 'Exception details');

done_testing;
