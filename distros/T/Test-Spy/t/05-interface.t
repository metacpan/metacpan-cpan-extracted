use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Spy;

subtest 'testing strict value' => sub {
	my $spy = Test::Spy->new;
	is $spy->interface, 'strict', 'interface ok';

	my $return = eval {
		local $SIG{__WARN__} = sub { die '###WARNING ' . shift };
		$spy->object->no_method;
		1;
	};

	ok !$return, 'non-existent method call ok';
};

subtest 'testing lax value' => sub {
	my $spy = Test::Spy->new(interface => 'lax');
	is $spy->interface, 'lax', 'interface ok';

	$spy->add_method('test', 11);

	my $return = eval {
		local $SIG{__WARN__} = sub { die '###WARNING ' . shift };
		$spy->object->no_method;
		1;
	};

	ok $return, 'non-existent method call ok';

	$spy->object->test;
	ok $spy->method('test')->was_called_once, 'test method called ok';
};

subtest 'testing warn value' => sub {
	my $spy = Test::Spy->new(interface => 'warn');
	is $spy->interface, 'warn', 'interface ok';

	my $return = eval {
		local $SIG{__WARN__} = sub { die '###WARNING ' . shift };
		$spy->object->no_method;
		1;
	};

	ok !$return, 'non-existent method call ok';
	like $@, qr/###WARNING/, 'warning raised';
};

done_testing;

