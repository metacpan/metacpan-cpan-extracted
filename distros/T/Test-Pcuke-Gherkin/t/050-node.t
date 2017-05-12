use Test::Most;

BEGIN: {
	use_ok('Test::Pcuke::Gherkin::Node');
}

my $CLASS = 'Test::Pcuke::Gherkin::Node';

new_ok($CLASS=>[], 'node instance');

can_ok($CLASS, qw{new _get_property _set_property _get_immutable _set_immutable _add_property});

{
	
	my ($name, $value) = ('x',"xxx");
	my $node = $CLASS->new();
	
	$node->_set_property($name, $value);
	is($node->_get_property($name), $value, 'can set and get the value of an object');
	
	my $node2 = $CLASS->new();
	ok( !defined $node2->_get_property($name), 'different objects have the different properties');

	lives_ok {
		$node->_set_property($name, "new $value");
	} 'can change values';
	
	is($node->_get_property($name), "new $value", 'property is changed');

}

{
	my ($name, $value) = ('x',"xxx");
	my $node = $CLASS->new();
	
	$node->_set_property($name, $value);
	
	$node->_set_immutable($name, "immutable $value");
	is($node->_get_immutable($name), "immutable $value", 'sets and gets immutable properties');

	isnt($node->_get_property($name), $node->_get_immutable($name), "immutables are not mutables!");
	
	throws_ok {
		$node->_set_immutable($name, "new $value");
	} qr{is an immutable property}i, 'immutable properties are immutable';	
}

{
	my $immutable_name = 'immutable_name';
	my $immutable_value = 'immutable value';
	my $mutable_name = 'a_mutable_name';
	my $mutable_value = 'a mutable value';

	my $node = $CLASS->new(
		properties	=> [$mutable_name],
		immutables	=> [$immutable_name],
		args		=> {
			$mutable_name	=> $mutable_value,
			$immutable_name	=> $immutable_value,
		}, 
	);

	is($node->_get_property($mutable_name), $mutable_value, 'mutable properties may be defined in the constructor');
	is($node->_get_immutable($immutable_name), $immutable_value, 'immutable properties may be defined in the constructor');
	
}

{
	my $node = $CLASS->new(
		properties	=> ['property'],
		immutables	=> ['immutable'],
		args		=> {
			property	=> 0,
			immutable	=> q{},
		}
	);

	is($node->_get_property('property'), 0, 'zeroes are stored fine');
	is($node->_get_immutable('immutable'), q{}, 'empty strings are stored fine');	
}

{
	my $name = 'ARRAY REFERENCE';
	my @values = qw{one two three};
	
	my $node = $CLASS->new();
	
	ok( !defined $node->_get_property($name), 'given array property is not defined' );
	
	$node->_add_property($name, $_) for (@values); 
	is(ref $node->_get_property($name), 'ARRAY', "when we add to property, then array is initialized");
	is_deeply($node->_get_property($name), [@values], 'and it keeps all the values in order of adding');
	
	throws_ok {
		$node->_add_property($name);
	} qr{must be defined}, '_add_property dies when value is undefined';
	
}
done_testing();