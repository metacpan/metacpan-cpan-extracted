#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More tests => 14;
use Test::Fatal;
use Test::Builder::Tester;

use ok 'Test::Mocha';

my $e;

isa_ok( class_mock('Some::Class'), 'Test::Mocha::Mock' );

ok(
    exception { class_mock 'Test::Builder::Tester' },
    'class_mock() throws if real module is already loaded'
);

ok(
    exception { class_mock('Some::Class') },
    'class_mock() throws if module is already mocked'
);

TODO: {
    local $TODO = 'Give better feedback when trying to stub a non-mock';
    like(
        exception {
            stub { Test::Builder::Test->dummy } returns 1;
        },
        qr/better error message/,
    );
}

# Class method - stubs
test_out('ok 1');
stub { Some::Class->class_method(1) } returns "foo";
is( Some::Class->class_method(1), "foo" );
test_test("class_mock stubs class method");

# Class method - called_ok
test_out('ok 1 - Some::Class->class_method(1) was called 1 time(s)');
called_ok { Some::Class->class_method(1) };
test_test('called_ok with class method');

# Module function - stubs
test_out('ok 1');
stub { Some::Class::module_function(1) } returns "foo";
is( Some::Class::module_function(1), "foo" );
test_test("class_mock stubs module function");

# Module function - called_ok
test_out('ok 1 - Some::Class::module_function(1) was called 1 time(s)');
called_ok { Some::Class::module_function(1) };
test_test('called_ok with module function');

# Executes - class method
test_out('ok 1');
stub { Some::Class->class_method( 2, 3 ) }
executes { my $self = shift; return join( ",", @_ ) };
is( Some::Class->class_method( 2, 3 ), "2,3" );
test_test("class method executes alternate method");

# stub Class->new
stub { Some::Class->new } returns mock;
new_ok('Some::Class');

# Executes - module function method
test_out('ok 1');
stub { Some::Class::module_function( 2, 3 ) }
executes { my $self = shift; return join( ",", @_ ) };
is( Some::Class::module_function( 2, 3 ), "2,3" );
test_test("module function executes alternate method");

# Throws - class method
test_out('ok 1');
stub { Some::Class->class_method(4) } throws 'My::Exception';
$e = exception { Some::Class->class_method(4) };
like( $e, qr/My::Exception/ );
test_test("class method throws exception");

# Throws - module function
test_out('ok 1');
stub { Some::Class::module_function(4) } throws 'My::Exception';
$e = exception { Some::Class::module_function(4) };
like( $e, qr/My::Exception/ );
test_test("module function throws exception");
