package Tree::SEMETrie::Iterator;

#Private Constants
my $EDGE = 0;
my $NODE = 1;

#Constructor

sub new {
	my $class = shift;
	$class = ref($class) || $class;
	my $self = bless {}, $class;

	my $current = shift;
	#Stack of children of edge-node pairs
	$self->{_ITERATOR_STACK} = [ [ ['', $current] ] ];
	$self->next unless $current->has_value;

	return $self;
}

#Iterator Inspectors

sub key {
	my $self = shift;

	return @{$self->{_ITERATOR_STACK}}
		? join '', map { $_->[0][$EDGE] } @{$self->{_ITERATOR_STACK}}
		: undef;
}

sub value {
	my $self = shift;

	return @{$self->{_ITERATOR_STACK}}
		? $self->{_ITERATOR_STACK}[-1][0][$NODE]->value(@_)
		: undef;
}

#Iterator Operators

sub is_done { ! @{$_[0]{_ITERATOR_STACK}} }

sub next {
	my $self = shift;
	my $iterator_stack_ref = $self->{_ITERATOR_STACK};

	#Return false if there's nothing left to see
	return 0 unless @$iterator_stack_ref;

	#There are only 2 options:

	#We stopped at an inner node so the next value is a descendant
	if ($iterator_stack_ref->[-1][0][$NODE]->has_childs) {
		while (my @childs = $iterator_stack_ref->[-1][0][$NODE]->childs) {
			push @$iterator_stack_ref, \@childs;
			last if $iterator_stack_ref->[-1][0][$NODE]->has_value;
		}

	#We stopped at a leaf node
	} else {

		#Try to go to the next sibling
		shift @{$iterator_stack_ref->[-1]};
		#Keep looking until some ancestor has a sibling
		until (@{$iterator_stack_ref->[-1]}) {
			#Go to the ancestor
			pop @$iterator_stack_ref;
			#We're done if there are no more ancestors
			return 0 unless @$iterator_stack_ref;
			#Go to the ancestor's sibling
			shift @{$iterator_stack_ref->[-1]};
		}

		#The sibling may not have a value, but one of its descendants must
		until ($iterator_stack_ref->[-1][0][$NODE]->has_value) {
			#Move to the children
			my @childs = $iterator_stack_ref->[-1][0][$NODE]->childs;
			push @$iterator_stack_ref, \@childs;
		}
	}

	#We succeeded if we didn't exhaust the stack
	return @$iterator_stack_ref > 0;
}

1;
