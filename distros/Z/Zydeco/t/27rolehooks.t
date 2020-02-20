use strict;
use warnings;
use Test::More;

my %xxx;

package Local {
	use Zydeco (
		prefix          => 'Local',
		factory_package => 'Local',
	);
	
	role Role1 {
		before_apply {
			push @{ $xxx{'Local::Role1'}||=[] }, [ before_apply => $role, $package, $kind ];
		}
		after_apply {
			if ($kind eq 'class') {
				has bleh;
				constant MY_CONSTANT = 42;
			}
			push @{ $xxx{'Local::Role1'}||=[] }, [ after_apply  => $role, $package, $kind ];
		}
	}
	
	role Role2 {
		with Role1;
		before_apply {
			push @{ $xxx{'Local::Role2'}||=[] }, [ before_apply => $role, $package, $kind ];
		}
		after_apply {
			push @{ $xxx{'Local::Role2'}||=[] }, [ after_apply  => $role, $package, $kind ];
		}
	}
	
	class Class1 with Role2;
}

is_deeply(\%xxx, {
	'Local::Role1' => [
		[
			'before_apply',
			'Local::Role1',
			'Local::Role2',
			'role',
		],
		[
			'after_apply',
			'Local::Role1',
			'Local::Role2',
			'role',
		],
		[
			'before_apply',
			'Local::Role2',
			'Local::Class1',
			'class',
		],
		[
			'after_apply',
			'Local::Role2',
			'Local::Class1',
			'class',
		]
	],
	'Local::Role2' => [
		[
			'before_apply',
			'Local::Role2',
			'Local::Class1',
			'class',
		],
		[
			'after_apply',
			'Local::Role2',
			'Local::Class1',
			'class',
		]
	]
}) or diag explain(\%xxx);

ok(!Local::Role1->can('MY_CONSTANT'));
ok(!Local::Role2->can('MY_CONSTANT'));
is(Local::Class1::MY_CONSTANT, 42);

ok(!Local::Role1->can('bleh'));
ok(!Local::Role2->can('bleh'));
ok(Local::Class1->can('bleh'));

done_testing;
