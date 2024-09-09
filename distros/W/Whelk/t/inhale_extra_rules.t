use Kelp::Base -strict;
use Test::More;
use Whelk::Schema;
use JSON::PP;

use utf8;

################################################################################
# This tests extra validation rules
################################################################################

subtest 'should inhale an integer with an extra rule' => sub {
	my $schema = Whelk::Schema->build(
		{
			type => 'integer',
			rules => [
				{
					hint => 'even',
					code => sub { shift() % 2 == 0 },
				},
			],
		}
	);

	is $schema->inhale(0), undef, 'inhaled 0 ok';
	is $schema->inhale(0.5), 'integer', 'inhaled 0.5 ok';
	is $schema->inhale(1), 'even', 'inhaled 1 ok';
	is $schema->inhale(2), undef, 'inhaled 2 ok';
};

subtest 'should inhale a number with an extra rule' => sub {
	my $schema = Whelk::Schema->build(
		{
			type => 'number',
			rules => [
				{
					hint => 'positive',
					code => sub { shift() > 0 },
				},
			],
		}
	);

	is $schema->inhale(0), 'positive', 'inhaled 0 ok';
	is $schema->inhale(0.001), undef, 'inhaled 0.001 ok';
	is $schema->inhale(-0.001), 'positive', 'inhaled -0.001 ok';
};

subtest 'should inhale a string with an extra rule' => sub {
	my $schema = Whelk::Schema->build(
		{
			type => 'string',
			rules => [
				{
					hint => 'empty',
					code => sub { length shift() > 0 },
				},
			],
		}
	);

	is $schema->inhale(''), 'empty', 'inhaled empty string ok';
	is $schema->inhale('aa'), undef, 'inhaled string ok';
};

subtest 'should inhale an array with an extra rule' => sub {
	my $schema = Whelk::Schema->build(
		{
			type => 'array',
			items => {
				type => 'string',
			},
			rules => [
				{
					hint => 'count',
					code => sub { @{shift()} == 2 },
				},
			],
		}
	);

	is $schema->inhale('??'), 'array', 'inhaled string ok';
	is $schema->inhale([{}]), 'array[0]->string', 'inhaled not a string in array ok';
	is $schema->inhale(['1']), 'count', 'inhaled one string in array ok';
	is $schema->inhale(['1', '2']), undef, 'inhaled two strings in array ok';
};

subtest 'should inhale an object with a rule and two nested rules' => sub {
	my $schema = Whelk::Schema->build(
		{
			type => 'object',
			properties => {
				test => {
					type => 'string',
					rules => [
						{
							hint => 'empty',
							code => sub { length shift() > 0 },
						},
						{
							hint => 'one',
							code => sub { shift() ne '1' },
						},
					],
				},
				one => {
					type => 'string',
					required => !!0,
				},
				two => {
					type => 'string',
					required => !!0,
				},
			},
			rules => [
				{
					hint => 'count',
					code => sub { keys %{shift()} == 2 },
				},
			],
		}
	);

	is $schema->inhale({test => ''}), 'object[test]->empty', 'inhaled nested empty string ok';
	is $schema->inhale({test => '1'}), 'object[test]->one', 'inhaled nested string with 1 ok';
	is $schema->inhale({test => '2'}), 'count', 'inhaled nested string ok';
	is $schema->inhale({test => '2', one => 'one'}), undef, 'inhaled two nested strings ok';
	is $schema->inhale({test => '2', two => 'two'}), undef, 'inhaled two nested strings ok';
	is $schema->inhale({test => '2', one => 'one', two => 'two'}), 'count', 'inhaled three nested strings ok';
};

done_testing;

