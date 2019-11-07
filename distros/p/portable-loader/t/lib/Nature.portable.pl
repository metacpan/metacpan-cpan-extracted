{
	role  => [
		'LeafGrower' => {
			has => [ '@leafs' => sub { [] } ],
			can => {
				'grow_leaf' => sub {
					my $self = shift;
					my $leaf = $self->FACTORY->new_leaf;
					push @{ $self->leafs }, $leaf;
					return $leaf;
				},
			},
		},
	],
	class => [
		'Leaf',
		'Tree'  => { with => ['LeafGrower'] },
	],
};
