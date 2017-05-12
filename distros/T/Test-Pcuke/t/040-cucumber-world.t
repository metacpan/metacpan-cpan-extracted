use Test::Most;

BEGIN: {
	use_ok('Test::Pcuke::World');
}

my $world = Test::Pcuke::World->new;
isa_ok($world, 'Test::Pcuke::World', 'world');

$world->set('property','value');
is($world->get('property'), 'value', 'set and get variable');
is($world->property,'value','getter named after the name of the variable is also available');

throws_ok {
	$world->property_that_was_not_set;
} qr{method is not defined}, 'world throws on call of the accessor to non-existing variable';

throws_ok {
	$world->set('ok',111);
} qr'reserved', 'Throws on setting reserved name';


done_testing();