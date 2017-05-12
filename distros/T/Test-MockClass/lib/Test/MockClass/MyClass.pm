package Test::MockClass::MyClass;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
				foo => '1',
				bar => '2',
				bas => '3',
			   };
	bless($self, $class);
}

sub foo {
	my $self = shift;
	return $self->{foo};
}

sub bar {
	my $self = shift;
	return $self->{bar};
}

sub bas {
	my $self = shift;
	return $self->{bas};
}

1;
