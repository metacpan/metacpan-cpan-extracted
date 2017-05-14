use Test::More tests => 15;

use YAML::Accessor;

my $ya = YAML::Accessor->new(
	file => qw{ testdata/testdata.yaml },
	autocommit => 0,
	readonly => 1,
	damian => 1,
);

ok($ya);

ok($ya->get_ordered_mapping());
ok(scalar @{ $ya->get_ordered_mapping() } == 2);
ok(scalar ( keys %{ $ya->get_ordered_mapping()->[0] } ) == 4);
ok(scalar ( keys %{ $ya->get_ordered_mapping()->[1] } ) == 4);


ok($ya->get_mapping());
ok($ya->get_mapping()->{key1} eq 'value1');
ok($ya->get_mapping()->{key2} eq 'value2');
ok($ya->get_mapping()->{key3} eq 'value3');

ok($ya->get_nested());
ok($ya->get_nested()->get_parent());
ok($ya->get_nested()->get_parent()->get_child1());
ok($ya->get_nested()->get_parent()->get_child2());
ok($ya->get_nested()->get_parent()->get_child1()->get_childkey1() eq 'childvalue1' );
ok($ya->get_nested()->get_parent()->get_child2()->get_childkey2() eq 'childvalue2' );

