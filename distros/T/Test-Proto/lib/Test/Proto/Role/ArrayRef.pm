package Test::Proto::Role::ArrayRef;
use 5.008;
use strict;
use warnings;
use Test::Proto::Common;
use Scalar::Util qw'blessed weaken';
use Moo::Role;

=head1 NAME

Test::Proto::Role::ArrayRef - Role containing test case methods for array refs.

=head1 SYNOPSIS

	package MyProtoClass;
	use Moo;
	with 'Test::Proto::Role::ArrayRef';

This Moo Role provides methods to Test::Proto::ArrayRef for test case methods that apply to arrayrefs such as C<map>. It can also be used for objects which use overload or otherwise respond to arrayref syntax.

=head1 METHODS

=head3 map

	pArray->map(sub { uc shift }, ['A','B'])->ok(['a','b']);

Applies the first argument (a coderef) onto each member of the array. The resulting array is compared to the second argument.

=cut

sub map {
	my ( $self, $code, $expected, $reason ) = @_;
	$self->add_test(
		'map',
		{
			code     => $code,
			expected => $expected
		},
		$reason
	);
}

define_test 'map' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $subject = [ map { $data->{code}->($_) } @{ $self->subject } ];
	return upgrade( $data->{expected} )->validate( $subject, $self );
};

=head3 grep

	pArray->grep(sub { $_[0] eq uc $_[0] }, ['A'])->ok(['A','b']); # passes
	pArray->grep(sub { $_[0] eq uc $_[0] }, [])->ok(['a','b']); # passes
	pArray->grep(sub { $_[0] eq uc $_[0] })->ok(['a','b']); # fails - 'boolean' grep behaves like array_any

Applies the first argument (a prototype) onto each member of the array; if it returns true, the member is added to the resulting array. The resulting array is compared to the second argument.

=cut

sub grep {
	my ( $self, $code, $expected, $reason ) = @_;
	if ( defined $expected and CORE::ref $expected ) {    #~ CORE::ref used because boolean grep might have a reason
		$self->add_test(
			'grep',
			{
				match    => $code,
				expected => $expected
			},
			$reason
		);
	}
	else {
		$reason = $expected;
		$self->add_test( 'array_any', { match => $code }, $reason );
	}
}

define_test 'grep' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $subject = [ grep { upgrade( $data->{match} )->validate($_) } @{ $self->subject } ];
	return upgrade( $data->{expected} )->validate( $subject, $self );
};

=head3 array_any

	pArray->array_any(sub { $_[0] eq uc $_[0] })->ok(['A','b']); # passes
	pArray->array_any(sub { $_[0] eq uc $_[0] })->ok(['a','b']); # fails

Applies the first argument (a prototype) onto each member of the array; if any member returns true, the test case succeeds.

=cut

sub array_any {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'array_any', { match => $expected }, $reason );
}

define_test 'array_any' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $i = 0;
	foreach my $single_subject ( @{ $self->subject } ) {
		return $self->pass("Item $i matched") if upgrade( $data->{match} )->validate($single_subject);
		$i++;
	}
	return $self->fail('None matched');
};

=head3 array_none

	pArray->array_none(sub { $_[0] eq uc $_[0] })->ok(['a','b']); # passes
	pArray->array_none(sub { $_[0] eq uc $_[0] })->ok(['A','b']); # fails

Applies the first argument (a prototype) onto each member of the array; if any member returns true, the test case fails.

=cut

sub array_none {
	my ( $self, $code, $reason ) = @_;
	$self->add_test( 'array_none', { code => $code }, $reason );
}

define_test 'array_none' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $i = 0;
	foreach my $single_subject ( @{ $self->subject } ) {
		return $self->fail("Item $i matched") if upgrade( $data->{code} )->validate($single_subject);
		$i++;
	}
	return $self->pass('None matched');
};

=head3 array_all

	pArray->array_all(sub { $_[0] eq uc $_[0] })->ok(['A','B']); # passes
	pArray->array_all(sub { $_[0] eq uc $_[0] })->ok(['A','b']); # fails

Applies the first argument (a prototype) onto each member of the array; if any member returns false, the test case fails.

=cut

sub array_all {
	my ( $self, $code, $reason ) = @_;
	$self->add_test( 'array_all', { code => $code }, $reason );
}

define_test 'array_all' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $i = 0;
	foreach my $single_subject ( @{ $self->subject } ) {
		return $self->fail("Item $i did not match") unless upgrade( $data->{code} )->validate($single_subject);
		$i++;
	}
	return $self->pass('All matched');
};

=head3 reduce

	pArray->reduce(sub { $_[0] + $_[1] }, 6 )->ok([1,2,3]);

Applies the first argument (a coderef) onto the first two elements of the array, and thereafter the next element and the return value of the previous calculation. Similar to List::Util::reduce.

=cut

sub reduce {
	my ( $self, $code, $expected, $reason ) = @_;
	$self->add_test(
		'reduce',
		{
			code     => $code,
			expected => $expected
		},
		$reason
	);
}

define_test 'reduce' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $length = $#{ $self->subject };
	return $self->exception( 'Cannot use reduce unless the subject has at least two elements; only ' . ( $length + 1 ) . ' found' ) unless $length;
	my $left = ${ $self->subject }[0];
	my $right;
	my $i = 1;
	while ( $i <= $length ) {
		$right = ${ $self->subject }[$i];
		$left = $data->{code}->( $left, $right );
		$i++;
	}
	return upgrade( $data->{expected} )->validate( $left, $self );
};

=head3 nth

	pArray->nth(1,'b')->ok(['a','b']);

Finds the nth item (where n is the first argument) and compares the result to the prototype provided in the second argument.

=cut

sub nth {
	my ( $self, $index, $expected, $reason ) = @_;
	$self->add_test(
		'nth',
		{
			'index'  => $index,
			expected => $expected
		},
		$reason
	);
}

define_test nth => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	if ( exists $self->subject->[ $data->{'index'} ] ) {
		my $subject = $self->subject->[ $data->{'index'} ];
		return upgrade( $data->{expected} )->validate( $subject, $self );
	}
	else {
		return $self->fail( 'The index ' . $data->{'index'} . ' does not exist.' );
	}
};

=head3 count_items

	pArray->count_items(2)->ok(['a','b']);

Finds the length of the array (i.e. the number of items) and compares the result to the prototype provided in the argument.

=cut

sub count_items {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'count_items', { expected => $expected }, $reason );
}

define_test count_items => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $subject = scalar @{ $self->subject };
	return upgrade( $data->{expected} )->validate( $subject, $self );
};

=head3 enumerated

	pArray->enumerated($tests_enumerated)->ok(['a','b']);

Produces the indices and values of the subject as an array reference, and tests them against the prototype provided in the argument.

In the above example, the prototype C<$tests_enumerated> should return a pass for C<[[0,'a'],[1,'b']]>.

=cut

sub enumerated {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'enumerated', { expected => $expected }, $reason );
}

define_test 'enumerated' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $subject = [];
	push @$subject, [ $_, $self->subject->[$_] ] foreach ( 0 .. $#{ $self->subject } );
	return upgrade( $data->{expected} )->validate( $subject, $self );
};

=head3 in_groups

	pArray->in_groups(2,[['a','b'],['c','d'],['e']])->ok(['a','b','c','d','e']);

Bundles the contents in groups of n (where n is the first argument), puts each group in an arrayref, and compares the resulting arrayref to the prototype provided in the second argument.

=cut

sub in_groups {
	my ( $self, $groups, $expected, $reason ) = @_;
	$self->add_test(
		'in_groups',
		{
			'groups' => $groups,
			expected => $expected
		},
		$reason
	);
}

define_test in_groups => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	return $self->exception('in_groups needs groups of 1 or more') if $data->{'groups'} < 1;
	my $newArray     = [];
	my $i            = 0;
	my $currentGroup = [];
	foreach my $item ( @{ $self->subject } ) {
		if ( 0 == ( $i % $data->{'groups'} ) ) {
			push @$newArray, $currentGroup if @$currentGroup;
			$currentGroup = [];
		}
		push @$currentGroup, $item;
		$i++;
	}
	push @$newArray, $currentGroup if @$currentGroup;
	return upgrade( $data->{expected} )->validate( $newArray, $self );
};

=head3 group_when

	pArray->group_when(sub {$_[eq uc $_[0]}, [['A'],['B','c','d'],['E']])->ok(['A','B','c','d','E']);
	pArray->group_when(sub {$_[0] eq $_[0]}, [['a','b','c','d','e']])->ok(['a','b','c','d','e']);

Bundles the contents of the test subject in groups; a new group is created when the member matches the first argument (a prototype). The resulting arrayref is compared to the second argument.

=cut

sub group_when {
	my ( $self, $condition, $expected, $reason ) = @_;
	$self->add_test(
		'group_when',
		{
			'condition' => $condition,
			expected    => $expected,
			must_match  => 'value'
		},
		$reason
	);
}

=head3 group_when_index

	pArray->group_when_index(p(0)|p(1)|p(4), [['A'],['B','c','d'],['E']])->ok(['A','B','c','d','E']);
	pArray->group_when_index(p->num_gt(2), [['a','b','c','d','e']])->ok(['a','b','c','d','e']);

Bundles the contents of the test subject in groups; a new group is created when the index matches the first argument (a prototype). The resulting arrayref is compared to the second argument.

=cut

sub group_when_index {
	my ( $self, $condition, $expected, $reason ) = @_;
	$self->add_test(
		'group_when',
		{
			'condition' => $condition,
			expected    => $expected,
			must_match  => 'index'
		},
		$reason
	);
}

define_test group_when => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $newArray     = [];
	my $currentGroup = [];
	my $condition    = upgrade( $data->{condition} );
	my $i            = 0;
	foreach my $item ( @{ $self->subject } ) {
		my $got = $item;
		$got = $i if $data->{must_match} =~ /index/;
		if ( $condition->validate($got) ) {
			push @$newArray, $currentGroup if defined $currentGroup and @$currentGroup;
			$currentGroup = [];
		}
		push @$currentGroup, $item;
		$i++;
	}
	push @$newArray, $currentGroup if defined $currentGroup and @$currentGroup;
	return upgrade( $data->{expected} )->validate( $newArray, $self );
};

=head3 indexes_of

	pArray->indexes_of('a', [0,2])->ok(['a','b','a']);

Finds the indexes which match the first argument, and compares that list as an arrayref with the second list.

=cut

sub indexes_of {
	my ( $self, $match, $expected, $reason ) = @_;
	$self->add_test(
		'indexes_of',
		{
			match    => $match,
			expected => $expected
		},
		$reason
	);
}

define_test indexes_of => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $indexes = [];
	for my $i ( 0 .. $#{ $self->subject } ) {
		push @$indexes, $i if upgrade( $data->{match} )->validate( $self->subject->[$i], $self->subtest( status_message => "Testing index $i" ) );
	}
	my $result = upgrade( $data->{expected} )->validate( $indexes, $self->subtest( status_message => 'Checking indexes against expected list' ) );
	return $self->pass if $result;
	return $self->fail;
};

=head3 array_eq

	pArray->array_eq(['a','b'])->ok(['a','b']);

Compares the elements of the test subject with the elements of the first argument, using the C<upgrade> feature.

=cut

sub array_eq {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'array_eq', { expected => $expected }, $reason );
}

define_test array_eq => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $length = scalar @{ $data->{expected} };
	my $length_result = Test::Proto::ArrayRef->new()->count_items($length)->validate( $self->subject, $self->subtest );
	if ($length_result) {
		foreach my $i ( 0 .. ( $length - 1 ) ) {

			#upgrade($data->{expected}->[$i])->validate($self->subject->[$i], $self);
			Test::Proto::ArrayRef->new()->nth( $i, $data->{expected}->[$i] )->validate( $self->subject, $self->subtest );
		}
	}
	$self->done;
};

=head3 range

	pArray->range('1,3..4',[9,7,6,5])->ok([10..1]);

Finds the range specified in the first element, and compares them to the second element.

=cut

sub range {
	my ( $self, $range, $expected, $reason ) = @_;
	$self->add_test(
		'range',
		{
			range    => $range,
			expected => $expected
		},
		$reason
	);
}

define_test range => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $range  = $data->{range};
	my $result = [];
	my $length = scalar @{ $self->subject };
	$range =~ s/-(\d+)/$length - $1/ge;
	$range =~ s/\.\.$/'..' . ($length - 1)/e;
	$range =~ s/^\.\./0../;
	return $self->exception('Invalid range specified') unless $range =~ m/^(?:\d+|\d+..\d+)(?:,(\d+|\d+..\d+))*$/;
	my @range = eval("($range)");         # surely there is a better way?

	foreach my $i (@range) {
		return $self->fail("Element $i does not exist") unless exists $self->subject->[$i];
		push( @$result, $self->subject->[$i] );
	}
	return upgrade( $data->{expected} )->validate( $result, $self );
};

=head3 reverse

	pArray->reverse([10..1])->ok([1..10]);

Reverses the order of elements and compares the result to the prototype given.

=cut

sub reverse {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'reverse', { expected => $expected }, $reason );
}

define_test reverse => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $reversed = [ CORE::reverse @{ $self->subject } ];
	return upgrade( $data->{expected} )->validate( $reversed, $self );
};

=head3 array_before

	pArray->array_before('b',['a'])->ok(['a','b']); # passes

Applies the first argument (a prototype) onto each member of the array; if any member returns true, the second argument is validated against a new arrayref containing all the preceding members of the array.

=cut

sub array_before {
	my ( $self, $match, $expected, $reason ) = @_;
	$self->add_test(
		'array_before',
		{
			match    => $match,
			expected => $expected
		},
		$reason
	);
}

=head3 array_before_inclusive

	pArray->array_before_inclusive('b',['a', 'b'])->ok(['a','b', 'c']); # passes

Applies the first argument (a prototype) onto each member of the array; if any member returns true, the second argument is validated against a new arrayref containing all the preceding members of the array, plus the element matched.

=cut

sub array_before_inclusive {
	my ( $self, $match, $expected, $reason ) = @_;
	$self->add_test(
		'array_before',
		{
			match        => $match,
			expected     => $expected,
			include_self => 1
		},
		$reason
	);
}

define_test 'array_before' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $i = 0;
	foreach my $single_subject ( @{ $self->subject } ) {
		if ( upgrade( $data->{match} )->validate($single_subject) ) {

			# $self->add_info("Item $i matched")
			my $before = [ @{ $self->subject }[ 0 .. $i ] ];
			pop @$before unless $data->{include_self};
			return upgrade( $data->{expected} )->validate( $before, $self );
		}
		$i++;
	}
	return $self->fail('None matched');
};

=head3 array_after

	pArray->array_after('a',['b'])->ok(['a','b']); # passes

Applies the first argument (a prototype) onto each member of the array; if any member returns true, the second argument is validated against a new arrayref containing all the following members of the array.

=cut

sub array_after {
	my ( $self, $match, $expected, $reason ) = @_;
	$self->add_test(
		'array_after',
		{
			match    => $match,
			expected => $expected
		},
		$reason
	);
}

=head3 array_after_inclusive

	pArray->array_after_inclusive('b',['b','c'])->ok(['a','b','c']); # passes

Applies the first argument (a prototype) onto each member of the array; if any member returns true, the second argument is validated against a new arrayref containing the element matched, plus all the following members of the array.

=cut

sub array_after_inclusive {
	my ( $self, $match, $expected, $reason ) = @_;
	$self->add_test(
		'array_after',
		{
			match        => $match,
			expected     => $expected,
			include_self => 1
		},
		$reason
	);
}

define_test 'array_after' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $i = 0;
	foreach my $single_subject ( @{ $self->subject } ) {
		if ( upgrade( $data->{match} )->validate($single_subject) ) {

			# $self->add_info("Item $i matched")
			my $last_index = $#{ $self->subject };
			my $after      = [ @{ $self->subject }[ $i .. $last_index ] ];
			shift @$after unless $data->{include_self};
			return upgrade( $data->{expected} )->validate( $after, $self );
		}
		$i++;
	}
	return $self->fail('None matched');
};

=head3 sorted

	pArray->sorted(['a','c','e'])->ok(['a','e','c']); # passes
	pArray->sorted([2,10,11], cNumeric)->ok([11,2,10]); # passes

This will sort the subject and compare the result against the protoype.

=cut

sub sorted {
	my ( $self, $expected, $compare, $reason ) = @_;
	$self->add_test(
		'sorted',
		{
			compare  => $compare,
			expected => $expected
		},
		$reason
	);
}

define_test 'sorted' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $compare = upgrade_comparison( $data->{compare} );

	#my $got = [sort { $compare->($a, $b) } @{$self->subject}];
	my $got = [ sort { $compare->compare( $a, $b ) } @{ $self->subject } ];

	return upgrade( $data->{expected} )->validate( $got, $self );
};

=head3 ascending

	pArray->ascending->ok(['a','c','e']); # passes
	pArray->ascending->ok(['a','c','c','e']); # passes
	pArray->ascending(cNumeric)->ok([2,10,11]); # passes

This will return true if the elements are already in ascending order. Elements which compare as equal as the previous element are permitted.

=cut

sub ascending {
	my ( $self, $compare, $reason ) = @_;
	$self->add_test(
		'in_order',
		{
			compare => $compare,
			dir     => 'ascending'
		},
		$reason
	);
}

=head3 descending

	pArray->descending->ok(['e','c','a']); # passes
	pArray->descending->ok(['e','c','c','a']); # passes
	pArray->descending(cNumeric)->ok([11,10,2]); # passes

This will return true if the elements are already in descending order. Elements which compare as equal as the previous element are permitted.

=cut

sub descending {
	my ( $self, $compare, $reason ) = @_;
	$self->add_test(
		'in_order',
		{
			compare => $compare,
			dir     => 'descending'
		},
		$reason
	);
}

define_test 'in_order' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	return $self->pass('Empty array is ascending by definition')       if $#{ $self->subject } == -1;
	return $self->pass('Single-item array is ascending by definition') if $#{ $self->subject } == 0;
	my $dir     = defined $data->{dir} ? $data->{dir} : 'ascending';
	my $compare = upgrade_comparison( $data->{compare} );
	my @range   = 0 .. $#{ $self->subject };
	@range = CORE::reverse(@range) if $dir eq 'descending';
	my $prev = shift @range;

	for my $i (@range) {
		$self->subtest->diag("Comparing items $prev and $i");
		my $result = $compare->le( $self->subject->[$prev], $self->subject->[$i] );
		return $self->fail("Item $prev > item $i") unless $result;
		$prev = $i;
	}
	return $self->pass;
};

=head3 array_max

	pArray->array_max('e')->ok(['a','e','c']); # passes
	pArray->array_max(p->num_gt(10), cNumeric)->ok(['2','11','10']); # passes

This will find the maximum value using the optional comparator in the second argument, and check it against the first argument.

=cut

sub array_max {
	my ( $self, $expected, $compare, $reason ) = @_;
	$self->add_test(
		'array_best',
		{
			expected   => $expected,
			must_match => 'any',
			compare    => $compare,
			dir        => 'max'
		},
		$reason
	);
}

=head3 array_min

	pArray->array_min('a')->ok(['a','e','c']); # passes
	pArray->array_min(p->num_lt(10), cNumeric)->ok(['2','11','10']); # passes

This will find the minimum value using the optional comparator in the second argument, and check it against the first argument.

=cut

sub array_min {
	my ( $self, $expected, $compare, $reason ) = @_;
	$self->add_test(
		'array_best',
		{
			expected   => $expected,
			must_match => 'any',
			compare    => $compare,
			dir        => 'min'
		},
		$reason
	);
}

=head3 array_index_of_max

	pArray->array_index_of_max(1)->ok(['a','e','c']); # passes
	pArray->array_index_of_max(1, cNumeric)->ok(['2','11','10']); # passes

This will find the index of the maximum value using the optional comparator in the second argument, and check it against the first argument.

=cut

sub array_index_of_max {
	my ( $self, $expected, $compare, $reason ) = @_;
	$self->add_test(
		'array_best',
		{
			expected   => $expected,
			must_match => 'any index',
			compare    => $compare,
			dir        => 'max'
		},
		$reason
	);
}

=head3 array_index_of_min

	pArray->array_index_of_min(0)->ok(['a','e','c']); # passes
	pArray->array_index_of_min(0, cNumeric)->ok(['2','11','10']); # passes

This will find the index of the minimum value using the optional comparator in the second argument, and check it against the first argument.

=cut

sub array_index_of_min {
	my ( $self, $expected, $compare, $reason ) = @_;
	$self->add_test(
		'array_best',
		{
			expected   => $expected,
			must_match => 'any index',
			compare    => $compare,
			dir        => 'min'
		},
		$reason
	);
}

define_test 'array_best' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $i = 0;
	return $self->fail('Empty array has no max by definition') if $#{ $self->subject } == -1;
	my $compare  = upgrade_comparison( $data->{compare} );
	my $better   = ( defined $data->{dir} and $data->{dir} eq 'min' ? sub { shift() > 0 } : sub { shift() < 0 } );
	my $best     = [ $self->subject->[0] ];
	my $best_idx = [0];
	foreach my $single_subject ( @{ $self->subject } ) {

		if ( $i != 0 ) {
			my $cmp_result = $compare->compare( $best->[0], $single_subject );
			if ( $better->($cmp_result) ) {
				$best     = [$single_subject];
				$best_idx = [$i];
			}
			elsif ( $cmp_result == 0 ) {
				push @$best,     $single_subject;
				push @$best_idx, $i;
			}
		}
		$i++;
	}
	my $got = $best;
	$got = $best_idx if $data->{must_match} =~ 'index';
	if ( $data->{must_match} =~ 'any' ) {
		return Test::Proto::ArrayRef->new()->array_any( $data->{expected} )->validate( $got, $self );
	}
	else {
		return upgrade( $data->{expected} )->validate( $got, $self );
	}
};

=head3 array_all_unique

	pArray->array_all_unique->ok(['a','b','c']); # passes
	pArray->array_all_unique(cNumeric)->ok(['0','0e0','0.0']); # fails

This will pass if all of the members of the array are unique, using the comparison provided (or cmp).

=cut

sub array_all_unique {
	my ( $self, $compare, $reason ) = @_;
	$self->add_test( 'array_all_unique', { compare => $compare }, $reason );
}

define_test 'array_all_unique' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $i       = 0;
	my $compare = upgrade_comparison( $data->{compare} );
	return $self->pass('Empty array unique by definition')            if $#{ $self->subject } == -1;
	return $self->pass('Array with one element unique by definition') if $#{ $self->subject } == 0;
	foreach my $single_subject ( @{ $self->subject } ) {
		if ( $i != 0 ) {
			return $self->fail("Item $i matches item 0") if $compare->eq( $self->subject->[0], $single_subject );
		}
		$i++;
	}
	return $self->pass('All unique');
};

=head3 array_all_same

	pArray->array_all_same->ok(['a','a']); # passes
	pArray->array_all_same(cNumeric)->ok(['0','0e0','0.0']); # passes
	pArray->array_all_same->ok(['0','0e0','0.0']); # fails

This will pass if all of the members of the array are the same, using the comparison provided (or cmp).

=cut

sub array_all_same {
	my ( $self, $compare, $reason ) = @_;
	$self->add_test( 'array_all_same', { compare => $compare }, $reason );
}

define_test 'array_all_same' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $i       = 0;
	my $compare = upgrade_comparison( $data->{compare} );
	return $self->pass('Empty array all same by definition')            if $#{ $self->subject } == -1;
	return $self->pass('Array with one element all same by definition') if $#{ $self->subject } == 0;
	foreach my $single_subject ( @{ $self->subject } ) {
		if ( $i != 0 ) {
			return $self->fail("Item $i does not match item 0") if $compare->ne( $self->subject->[0], $single_subject );
		}
		$i++;
	}
	return $self->pass('All the same');
};

=head2 Unordered Comparisons

These methods are useful for when you know what the array should contain but do not know what order the elements are in, for example when testing the keys of a hash. 

The principle is similar to the C<set> and C<bag> tests documented L<List::Util>, but does not use the same implementation and does not suffer from the known bug documented there.

=cut

=head3 set_of

	pArray->set_of(['a','b','c'])->ok(['a','c','a','b']); # passes

Checks that all of the elements in the test subject match at least one element in the first argument, and vice versa. Members of the test subject may be 'reused'.

=cut

sub set_of {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test(
		'unordered_comparison',
		{
			expected => $expected,
			method   => 'set'
		},
		$reason
	);
}

=head3 bag_of

	pArray->bag_of(['a','b','c'])->ok(['c','a','b']); # passes

Checks that all of the elements in the test subject match at least one element in the first argument, and vice versa. Members may B<not> be 'reused'.

=cut

sub bag_of {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test(
		'unordered_comparison',
		{
			expected => $expected,
			method   => 'bag'
		},
		$reason
	);
}

=head3 subset_of

	pArray->subset_of(['a','b','c'])->ok(['a','a','b']); # passes

Checks that all of the elements in the test subject match at least one element in the first argument. Members of the test subject may be 'reused'.

=cut

sub subset_of {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test(
		'unordered_comparison',
		{
			expected => $expected,
			method   => 'subset'
		},
		$reason
	);
}

=head3 superset_of

	pArray->superset_of(['a','b','a'])->ok(['a','b','c']); # passes

Checks that all of the elements in the first argument can validate at least one element in the test subject. Members of the test subject may be 'reused'.

=cut

sub superset_of {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test(
		'unordered_comparison',
		{
			expected => $expected,
			method   => 'superset'
		},
		$reason
	);
}

=head3 subbag_of

	pArray->subbag_of(['a','b','c'])->ok(['a','b']); # passes

Checks that all of the elements in the test subject match at least one element in the first argument. Members of the test subject may B<not> be 'reused'.

=cut

sub subbag_of {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test(
		'unordered_comparison',
		{
			expected => $expected,
			method   => 'subbag'
		},
		$reason
	);
}

=head3 superbag_of

	pArray->superbag_of(['a','b'])->ok(['a','b','c']); # passes

Checks that all of the elements in the first argument can validate at least one element in the test subject. Members of the test subject may B<not> be 'reused'.

=cut

sub superbag_of {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test(
		'unordered_comparison',
		{
			expected => $expected,
			method   => 'superbag'
		},
		$reason
	);
}

my $machine;
define_test 'unordered_comparison' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	return $machine->( $self, $data->{method}, $self->subject, $data->{expected} );
};

my ( $allocate_l, $allocate_r );
$allocate_l = sub {
	my ( $matrix, $pairs, $bag ) = @_;
	my $best = $pairs;
	LEFT: foreach my $l ( 0 .. $#{$matrix} ) {
		next LEFT if grep { $_->[0] == $l } @$pairs;    # skip if already allocated
		RIGHT: foreach my $r ( 0 .. $#{ $matrix->[$l] } ) {
			next RIGHT if $bag and grep { $_->[1] == $r } @$pairs;    # skip if already allocated and bag logic
			if ( $matrix->[$l]->[$r] ) {
				my $result = $allocate_l->( $matrix, [ @$pairs, [ $l, $r ] ], $bag );
				$best = $result if ( @$result > @$best );

				# short circuit if length of Best == length of matrix ?
			}
		}
	}
	return $best;
};
$allocate_r = sub {
	my ( $matrix, $pairs, $bag ) = @_;
	my $best = $pairs;
	RIGHT: foreach my $r ( 0 .. $#{ $matrix->[0] } ) {
		next RIGHT if grep { $_->[1] == $r } @$pairs;    # skip if already allocated
		LEFT: foreach my $l ( 0 .. $#{$matrix} ) {
			next LEFT if $bag and grep { $_->[0] == $l } @$pairs;    # skip if already allocated and bag logic
			if ( $matrix->[$l]->[$r] ) {
				my $result = $allocate_r->( $matrix, [ @$pairs, [ $l, $r ] ], $bag );
				$best = $result if ( @$result > @$best );
			}
		}
	}
	return $best;
};
$machine = sub {
	my ( $runner, $method, $left, $right ) = @_;
	my $bag    = ( $method =~ /bag$/ );
	my $matrix = [];
	my $super  = ( $method =~ m/^super/ );

	# prepare the results matrix
	LEFT: foreach my $l ( 0 .. $#{$left} ) {
		RIGHT: foreach my $r ( 0 .. $#{$right} ) {
			my $result = upgrade( $right->[$r] )->validate( $left->[$l], );    #$runner->subtest("Comparing subject->[$l] and expected->[$r]"));
			$matrix->[$l]->[$r] = $result;
		}
	}
	my $pairs = [];

	my $allocation_l = $allocate_l->( $matrix, $pairs, $bag );
	my $allocation_r = $allocate_r->( $matrix, $pairs, $bag );

	if ( $method =~ m/^(sub|)(bag|set)$/ ) {
		foreach my $l ( 0 .. $#{$left} ) {
			unless ( grep { $_->[0] == $l } @$allocation_l ) {
				return $runner->fail('Not a superbag') if $bag;
				return $runner->fail('Not a superset');
			}

		}
	}
	if ( $method =~ m/^(super|)(bag|set)$/ ) {
		foreach my $r ( 0 .. $#{$right} ) {
			unless ( grep { $_->[1] == $r } @$allocation_r ) {
				return $runner->fail('Not a superbag') if $bag;
				return $runner->fail('Not a superset');
			}
		}
	}
	return $runner->pass("Successful");
};

=head2 Series Validation

Sometimes you need to check an array matches a certain complex 'pattern' including multiple units of variable length, like in a regular expression or an XML DTD or Schema. Using L<Test::Proto::Series>, L<Test::Proto::Repeatable>, and L<Test::Proto::Alternation>, you can describe these units, and the methods below can be used to iterate over such a structure. 

=cut

#~ Series handling

=head3 contains_only

	pArray->contains_only(pSeries(pRepeatable(pAlternation('a', 'b'))->max(5)))->ok(['a','a','a']); # passes

This passes if the series expected matches exactly the test subject, i.e. the series can legally stop at the point where the subject ends. 

=cut

my ( $bt_core, $bt_advance, $bt_eval_step, $bt_backtrack, $bt_backtrack_to );

sub contains_only {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'contains_only', { expected => $expected }, $reason );
}

define_test 'contains_only' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	return $bt_core->( $self, $self->subject, $data->{expected} );
};

=head3 begins_with

	pArray->begins_with(pSeries('a','a',pRepeatable('a')->max(2)))->ok(['a','a','a']); # passes

This passes if the full value of the series expected matches the test subject with some elements of the test subject optionally left over at the end.  

=cut

sub begins_with {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'begins_with', { expected => $expected }, $reason );
}

define_test 'begins_with' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	for my $i ( 0 .. $#{ $self->subject } ) {
		my $subset = [ @{ $self->subject }[ 0 .. $i ] ];
		return $self->pass("Succeeded with 0..$i") if $bt_core->( $self->subtest( subject => $subset ), $subset, $data->{expected} );
	}
	return $self->fail("No subsets passed");
};

=head3 ends_with

	pArray->ends_with(pSeries('b','c')->ok(['a','b','c']); # passes

This passes if the full value of the series expected matches the final items of the test subject with some elements of the test subject optionally preceding. 

=cut

sub ends_with {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'ends_with', { expected => $expected }, $reason );
}

define_test 'ends_with' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	for my $i ( CORE::reverse( 0 .. $#{ $self->subject } ) ) {
		my $subset = [ @{ $self->subject }[ $i .. $#{ $self->subject } ] ];
		return $self->pass( "Succeeded with " . $i . ".." . $#{ $self->subject } ) if $bt_core->( $self->subtest( subject => $subset ), $subset, $data->{expected} );
	}
	return $self->fail("No subsets passed");
};

#~ How the backtracker works
#~
#~ 1. To advance a step
#~
#~ Find the most recent incomplete SERIES
#~
#~ Get its next element.
#~
#~ 2. To get the next alternative (backreack)
#~
#~ Find the most recent VARIABLE_UNIT
#~
#~ If a repeatable, decrease it (they begin greedy)
#~
#~ If an alternation, try the next alternative,
#~
#~ If either of those cannot legally be done, it's no longer a variable unit so keep looking
#~
#~ When you run out of history, fail
#~
#~
#~ So the backtracker should do the following:
#~
#~
#~ 	backtracker (runner r, subject s, expected e, history h)
#~ 		loop
#~ 			next_step = advance (r, s, e, h)
#~ 			if no next_step
#~ 				return r->pass if index of last h is length of s
#~ 			push next step onto history
#~ 			result = evaluate
#~ 			if result is not ok
#~ 				next_solution = backtrack (r, s, e, h) # modifies h
#~ 				if no next_solution
#~ 					return r->fail
#~ 				# implicit else continue and redo the loop
#~
#~
$bt_core = sub {
	my ( $runner, $subject, $expected, $history, $options ) = @_;
	$history = [] unless defined $history;    #:5.8
	while (1) {                               #~ yeah, scary, I know, but better than diving headlong into recursion

		#~ Advance
		my $next_step = $bt_advance->( $runner, $subject, $expected, $history );

		#~ If we cannot advance, then pass if what we've matched so far meets the criteria
		unless ( defined $next_step ) {
			return $runner->pass
				if (
				( !@{$history} and !@{$subject} )    # this oughtn't to happen
				or ( $history->[-1]->{index} == $#$subject )
				);

			#return $runner->fail('No next step; index reached: '.$history->[-1]->{index});
			$runner->subtest()->diag('No next step');
		}

		#~ Add the next step to the history
		push @$history, $next_step if defined $next_step;

		#~ Determine if the next step can be executed
		my $evaluation_result =
			defined $next_step
			? $bt_eval_step->( $runner, $subject, $expected, $history )
			: undef;
		unless ($evaluation_result) {
			my $next_solution = $bt_backtrack->( $runner, $subject, $expected, $history );
			unless ( defined $next_solution ) {
				return $runner->fail('No more alternatve solutions');
			}
		}
	}
};

$bt_advance = sub {

	#~ the purpose of this to find the latest series or repeatble which has not been exhausted.
	#~ This method adds items to the end of the history stack, and never removes them.
	my ( $runner, $subject, $expected, $history ) = @_;
	my $l = $#$history;
	$runner->subtest( test_case => $history )->diag( 'Advance ' . $l . '!' );
	my $next_step;

	#~ todo: check if l == -1
	if ( $l == -1 ) {
		return {
			self   => $expected,
			parent => undef,
			index  => -1,
		};
	}
	for my $i ( CORE::reverse( 0 .. $l ) ) {
		my $step = $history->[$i];
		my $children;
		if ( ( blessed $step->{self} ) and $step->{self}->isa('Test::Proto::Series') ) {
			$children = $step->{children};
			$children = [] unless defined $children;    #:5.8
			my $contents = $step->{self}->contents;
			if ( $#$children < $#$contents ) {

				#~ we conclude the series is not complete. Add a new step.
				$next_step = {
					self    => $contents->[ $#$children + 1 ],
					parent  => $step,
					element => $#$children + 1
				};
				weaken $next_step->{parent};
				push @{ $step->{children} }, ($next_step);
			}
		}
		elsif ( ( blessed $step->{self} ) and $step->{self}->isa('Test::Proto::Repeatable') ) {
			$children = $step->{children};
			$children = [] unless defined $children;    #:5.8
			my $max = $step->{max};    #~ the maximum set by a backtrack action
			$max = $step->{self}->max unless defined $max;    # the maximum allowed by the repeatable
			                                                  #~ NB: Repeatables are greedy, so go as far as they can unless a backtrack has caused them to try being less greedy.
			unless ( ( defined $max ) and ( $#$children + 1 >= $max ) ) {

				#~ we conclude the repeatable is not exhausted. Add a new step.
				$next_step = {
					self    => $step->{self}->contents,
					parent  => $step,
					element => $#$children + 1
				};
				weaken $next_step->{parent};
				push @{ $step->{children} }, $next_step;
				$step->{max_tried} = $#{ $step->{children} } + 1;
			}
		}
		elsif ( ( blessed $step->{self} ) and $step->{self}->isa('Test::Proto::Alternation') ) {

			#~ Pick first alternative
			unless ( ( defined $step->{children} ) and @{ $step->{children} } ) {
				my $alt = 0;
				$alt = $step->{alt} if defined $step->{alt};
				$next_step = {
					self    => $step->{self}->alternatives->[$alt],
					parent  => $step,
					element => 0
				};
				weaken $next_step->{parent};
				$step->{alt} = $alt;
				push @{ $step->{children} }, $next_step;
			}
		}
		if ( defined $next_step ) {
			return $next_step;
		}

		#~ Otherwise, next $i.
	}
	return undef;
};

$bt_eval_step = sub {

	#~ The purpose of this function is to determine if the current solution can continue at this point.
	#~ Specifically, if the current step (i.e. the last in the history) validates against the next item in the subject.
	#~ However, if the current step is a series/repeatable/altenration, then this is not an issue.
	my ( $runner, $subject, $expected, $history ) = @_;
	my $current_step = $history->[-1];
	my $current_index = ( ( exists $history->[1] ) ? ( defined $history->[-2]->{index} ? $history->[-2]->{index} : -1 ) : -1 );    # current_index is what has been completed
	$current_step->{index} = $current_index;    #:jic
	if ( exists $subject->[ $current_index + 1 ] ) {

		#~ if a series, repeatable, or alternation, we're always ok, we just need to update the index
		#~ if a prototype, evaluate it.
		if ( ( ref $current_step->{self} ) and ref( $current_step->{self} ) =~ /^Test::Proto::(?:Series|Repeatable|Alternation)$/ ) {
			$runner->subtest( test_case => $history )->diag( 'Starting a ' . ( ref $current_step->{self} ) );
			$current_step->{index} = $current_index;
			return 1;    #~ always ok
		}
		else {
			my $p = upgrade( $current_step->{self} );
			$runner->subtest( test_case => $history )->diag( 'Validating index ' . ( $current_index + 1 ) );
			my $result = $p->validate( $subject->[ $current_index + 1 ], $runner->subtest() );
			if ($result) {
				$current_step->{index} = $current_index + 1;
			}
			else {
				$current_step->{index} = $current_index;    # shouldn't read this
			}
			return $result;
		}
	}
	else {
		#~...
		#~ We are allowed only:
		#~ - repeatables with zero minimum
		#~ - alternations
		#~ i.e. no prototypes or series
		#~ Todo: check if we're repeating interminably by seeing if any object is its own ancestor
		$runner->subtest()->diag('Reached end of subject, allowing only potentially empty patterns');
		if ( ref( $current_step->{self} ) eq 'Test::Proto::Alternation' ) {
			$current_step->{index} = $current_index;
			return 1;
		}
		elsif ( ( ( ref $current_step->{self} ) eq 'Test::Proto::Repeatable' ) and ( $current_step->{self}->min <= ( $#{ $current_step->{children} } + 1 ) ) ) {
			$current_step->{max} = $#{ $current_step->{children} } + 1
				unless defined( $current_step->{max} )
				and $current_step->{max} < ( $#{ $current_step->{children} } + 1 );    #~ we need to consider it complete so we don't end up in a loop of adding and removing these.
			$current_step->{index} = $current_index;
			return 1;
		}
		else {
			$current_step->{index} = $current_index;
			return 0;                                                                  #~ cause a backtrack
		}

	}
};

$bt_backtrack = sub {
	my ( $runner, $subject, $expected, $history ) = @_;

	#~ The purpose of this to find the latest repeatable and alternation which has not had all its options exhausted.
	#~ This method then removes all items from the history stack after that point and increments a counter on that history item.
	#~ No extra steps are added.
	#~ Consider taking the removed slice and keeping it in a 'failed branches' slot of the repeatable/alternation.
	my $l = $#$history;
	$runner->subtest()->diag( 'Backtracking... (last history item: ' . $l . ')' );

	#~ todo: check if l == -1 ?
	for my $i ( CORE::reverse( 0 .. $l ) ) {
		my $step = $history->[$i];
		if ( ( blessed $step->{self} ) and $step->{self}->isa('Test::Proto::Repeatable') ) {
			my $children = $step->{children};
			$children = [] unless defined $children;    #:5.8
			my $max = $step->{max};                     #~ the maximum set by a backtrack action
			$max = $step->{self}->max unless defined $max;    # the maximum allowed by the repeatable
			$max = $step->{max_tried} unless defined $max;
			my $new_max = $max - 1;
			unless ( $new_max < $step->{self}->min ) {
				$runner->subtest( test_case => ($step) )->diag("Selected a new max of $new_max at Repeatable at step $i");
				$step->{max} = $new_max;
				if ( defined $step->{children}->[0] ) {       # then the advance worked
					$bt_backtrack_to->( $runner, $history, $step->{children}->[0] );
					$#{ $step->{children} } = -1;
					return 1;
				}
			}
		}
		elsif ( ( blessed $step->{self} ) and $step->{self}->isa('Test::Proto::Alternation') ) {
			if ( $step->{alt} < $#{ $step->{self}->{alternatives} } ) {
				$runner->subtest( test_case => ($step) )->diag( "Selected branch " . ( $step->{alt} + 1 ) . " at Alternation at step $i" );
				$step->{alt}++;
				if ( defined $step->{children}->[0] ) {       # then the advance worked
					$bt_backtrack_to->( $runner, $history, $step->{children}->[0] );
					$#{ $step->{children} } = -1;
					return 1;
				}
			}
		}
	}
	return undef;

};

$bt_backtrack_to = sub {

	#~ Backtracks to the target step (inclsively, i.e. deletes the step).
	my ( $runner, $history, $target_step ) = @_;
	for my $i ( CORE::reverse( 1 .. $#$history ) ) {
		if ( $history->[$i] == $target_step ) {
			$runner->subtest( test_case => ( $history->[$i] ) )->diag("Backtracked to step $i");

			#~ If step $i or any step after it is a child of a parent earlier in the history, it should no longer be a child, because it will shortly no longer exist.
			my @delenda = $i .. $#$history;
			foreach my $j ( 0 .. ( $i - 1 ) ) {
				if ( defined $history->[$j]->{children} ) {
					foreach my $childIndex ( 0 .. $#{ $history->[$j]->{children} } ) {
						if ( grep { $history->[$j]->{children}->[$childIndex] == $history->[$_] } @delenda ) {
							$#{ $history->[$j]->{children} } = $childIndex - 1;
							last;
						}
					}
				}
			}
			$#$history = $i - 1;
			return;
		}
	}
	die;    #~ we should never reach this point
};
1;

