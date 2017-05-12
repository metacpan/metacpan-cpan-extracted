package Test::Proto::Role::Value;
use 5.008;
use strict;
use warnings;
use Test::Proto::Common;
use Scalar::Util qw(weaken isweak);
use Moo::Role;

=head1 NAME

Test::Proto::Role::Value - Role containing test case methods for any perl value

=head1 SYNOPSIS

	package MyProtoClass;
	use Moo;
	with 'Test::Proto::Role::Value';

This Moo Role provides methods to L<Test::Proto::Base> for common test case methods like C<eq>, C<defined>, etc. which can potentially be used on any perl value/object.

=head1 METHODS

=head3 eq, ne, gt, lt, ge, le

	p->eq('green')->ok('green'); # passes
	p->lt('green')->ok('grape'); # passes

Performs the relevant string comparison on the subject, comparing against the text supplied. 

=cut

sub eq {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'eq', { expected => $expected }, $reason );
}

sub ne {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'ne', { expected => $expected }, $reason );
}

sub gt {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'gt', { expected => $expected }, $reason );
}

sub lt {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'lt', { expected => $expected }, $reason );
}

sub ge {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'ge', { expected => $expected }, $reason );
}

sub le {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'le', { expected => $expected }, $reason );
}

=head3 num_eq, num_ne, num_gt, num_lt, num_ge, num_le

	p->num_eq(0)->ok(0); # passes
	p->num_lt(256)->ok(255); # passes

Performs the relevant string comparison on the subject, comparing against the number supplied. 

=cut

sub num_eq {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'num_eq', { expected => $expected }, $reason );
}

sub num_ne {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'num_ne', { expected => $expected }, $reason );
}

sub num_gt {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'num_gt', { expected => $expected }, $reason );
}

sub num_lt {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'num_lt', { expected => $expected }, $reason );
}

sub num_ge {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'num_ge', { expected => $expected }, $reason );
}

sub num_le {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'num_le', { expected => $expected }, $reason );
}

=head3 true, false

	p->true->ok("Strings are true"); # passes
	p->false->ok($undefined); # fails

Tests if the subject returns true or false in boolean context.

=cut

sub true {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'true', { expected => 'true' }, $reason );
}

define_test 'true' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	if ( $self->subject ) {
		return $self->pass;
	}
	else {
		return $self->fail;
	}
};

sub false {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'false', { expected => 'false' }, $reason );
}

define_test 'false' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	if ( $self->subject ) {
		return $self->fail;
	}
	else {
		return $self->pass;
	}
};

=head3 defined, undefined

Tests if the subject is defined/undefined. 

	p->defined->ok("Pretty much anything"); # passes

Note that directly supplying undef into the protoype (as opposed to a variable containing undef, a function which returns undef, etc.) will exhibit different behaviour: it will attempt to use C<$_> instead. This is experimental behaviour.

	$_ = 3;
	$undef = undef;
	p->undefined->ok(undef); # fails
	p->undefined->ok($undef); # passes

=cut

sub defined {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'defined', { expected => 'defined' }, $reason );
}

define_test 'defined' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	if ( defined $self->subject ) {
		return $self->pass;
	}
	else {
		return $self->fail;
	}
};

sub undefined {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'undefined', { expected => 'undefined' }, $reason );
}

define_test 'undefined' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	if ( defined $self->subject ) {
		return $self->fail;
	}
	else {
		return $self->pass;
	}
};

=head3 like, unlike

	p->like(qr/^a$/)->ok('a');
	p->unlike(qr/^a$/)->ok('b');

The test subject is validated against the regular expression. Like tests for a match; unlike tests for nonmatching.

=cut

sub like {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'like', { expected => $expected }, $reason );
}

define_test 'like' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $re = $data->{expected};
	if ( $self->subject =~ m/$re/ ) {
		return $self->pass;
	}
	else {
		return $self->fail;
	}
};

sub unlike {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'unlike', { expected => $expected }, $reason );
}

define_test 'unlike' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $re = $data->{expected};
	if ( $self->subject !~ m/$re/ ) {
		return $self->pass;
	}
	else {
		return $self->fail;
	}
};

=head3 try

	p->try( sub { 'a' eq lc shift; } )->ok('A');

Used to execute arbitrary code. Passes if the return value is true.

=cut

sub try {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'try', { expected => $expected }, $reason );
}

define_test 'try' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	if ( $data->{expected}->( $self->subject ) ) {
		return $self->pass;
	}
	else {
		return $self->fail;
	}
};

=head3 ref

	p->ref(undef)->ok('b');
	p->ref('less')->ok(less);
	p->ref(qr/[a-z]+/)->ok(less);

Tests the result of the 'ref'. Any prototype will do here.

=cut

sub ref {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'ref', { expected => $expected }, $reason );
}

define_test 'ref' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	return upgrade( $data->{expected} )->validate( CORE::ref( $self->subject ), $self );
};

=head3 is_a

	p->is_a('')->ok('b');
	p->is_a('ARRAY')->ok([]);
	p->is_a('less')->ok(less);

A test which bundles C<isa> and C<ref> together. 

If the subject is not a reference, C<undef> or C<''> in the first argument passes.

If the subject is a reference to a builtin type like HASH, the C<ref> of that type passes.

If the subject is a blessed reference, then C<isa> is used.

=cut

sub is_a {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'is_a', { expected => $expected }, $reason );
}

define_test is_a => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	if ( ( CORE::ref $self->subject ) =~ /^(SCALAR|ARRAY|HASH|CODE|REF|GLOB|LVALUE|FORMAT|IO|VSTRING|Regexp)$/ ) {
		if ( $1 eq $data->{expected} ) {
			return $self->pass;
		}
	}
	elsif ( Scalar::Util::blessed $self->subject ) {
		if ( $self->subject->isa( $data->{expected} ) ) {
			return $self->pass;
		}
	}
	elsif ( ( !defined $data->{expected} ) or $data->{expected} eq '' ) {
		return $self->pass;
	}
	return $self->fail;
};

=head3 blessed 

	p->blessed->ok($object); # passes
	p->blessed('Correct::Class')->ok($object); # passes
	p->blessed->ok([]); # fails

Compares the prototype to the result of running C<blessed> from L<Scalar::Util> on the test subject. 

=cut

sub blessed {
	my ( $self, $expected, $reason ) = @_;
	$expected = Test::Proto::Base->new()->ne('') unless defined $expected;
	$self->add_test( 'blessed', { expected => $expected }, $reason );
}

define_test blessed => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	return upgrade( $data->{expected} )->validate( Scalar::Util::blessed( $self->subject ), $self );
};

=head3 array

	p->array->ok([1..10]); # passes
	p->array->ok($object); # fails, even if $object overloads @{}

Passes if the subject is an unblessed array.

=cut

sub array {
	my $self = shift;
	$self->ref( Test::Proto::Base->new->eq('ARRAY'), @_ );
}

=head3 hash

	p->hash->ok({a=>'1'}); # passes
	p->hash->ok($object); # fails, even if $object overloads @{}

Passes if the subject is an unblessed hash.

=cut

sub hash {
	my $self = shift;
	$self->ref( Test::Proto::Base->new->eq('HASH'), @_ );
}

=head3 scalar

	p->scalar->ok('a'); # passes
	p->scalar->ok(\''); # fails

Passes if the subject is an unblessed scalar.

=cut

sub scalar {
	my $self = shift;
	$self->ref( Test::Proto::Base->new->eq(''), @_ );
}

=head3 scalar_ref

	p->scalar_ref->ok(\'a'); # passes
	p->scalar_ref->ok('a'); # fails

Passes if the subject is an unblessed scalar ref.

=cut

sub scalar_ref {
	my $self = shift;
	$self->ref( Test::Proto::Base->new->eq('SCALAR'), @_ );
}

=head3 object

	p->scalar->ok('a'); # passes
	p->scalar->ok(\'');

Passes if the subject is a blessed object.

=cut

sub object {
	shift->blessed;
}

=head3 refaddr

	p->refaddr(undef)->ok('b');
	p->refaddr(p->gt(5))->ok($obj);

Tests the result of the 'refaddr' (from L<Scalar::Util>). Any prototype will do here.

=cut

sub refaddr {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'refaddr', { expected => $expected }, $reason );
}

define_test 'refaddr' => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	upgrade( $data->{expected} )->validate( Scalar::Util::refaddr( $self->subject ), $self );
};

=head3 refaddr_of

	$obj2 = $obj;
	p->refaddr_of($obj)->ok($obj2); # passes
	p->refaddr([])->ok([]); # fails

Tests the result of the 'refaddr' (from L<Scalar::Util>) is the same as the refaddr of the object passed. Do not supply prototypes.

Note: This always passes for strings.

=cut

sub refaddr_of {
	my ( $self, $expected, $reason ) = @_;
	my $refaddr = Scalar::Util::refaddr($expected);
	$refaddr = Test::Proto::Base->new->undefined unless defined $refaddr;
	$self->add_test( 'refaddr', { expected => $refaddr }, $reason );
}

{
	my %num_eqv = qw(eq == ne != gt > lt < ge >= le <=);
	foreach my $dir ( keys %num_eqv ) {

		define_test $dir => sub {
			my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
			my $result;
			eval "\$result = \$self->subject $dir \$data->{expected}";
			if ($result) {
				return $self->pass;
			}
			else {
				return $self->fail;
			}
		};

		my $num_dir = $num_eqv{$dir};

		define_test "num_$dir" => sub {
			my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
			my $result;
			eval "\$result = \$self->subject $num_dir \$data->{expected}";
			if ($result) {
				return $self->pass;
			}
			else {
				return $self->fail;
			}
		};
	}
}

=head3 also

	$positive = p->num_gt(0);
	$integer->also($positive);
	$integer->also(qr/[02468]$/);
	$integer->ok(42); # passes

Tests that the subject also matches the protoype given. If the argument given is not a prototype, the argument is upgraded to become one.

=cut

sub also {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'also', { expected => $expected }, $reason );
}

define_test also => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	return upgrade( $data->{expected} )->validate( $self->subject, $self );
};

=head3 any_of

	$positive = p->num_gt(0);
	$all = p->eq('all');
	$integer->any_of([$positive, $all]);
	$integer->ok(42); # passes
	$integer->ok('all'); # passes

Tests that the subject also matches one of the protoypes given in the arrayref. If a member of the arrayref given is not a prototype, the argument is upgraded to become one.

=cut

sub any_of {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'any_of', { expected => $expected }, $reason );
}

define_test any_of => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $i = 0;
	foreach my $candidate ( @{ $data->{expected} } ) {
		my $result = upgrade($candidate)->validate( $self->subject, $self->subtest );
		return $self->pass("Candidate $i was successful") if $result;
		$i++;
	}
	return $self->fail("None of the $i candidates were successful");
};

=head3 all_of

	$positive = p->num_gt(0);
	$under_a_hundred = p->num_lt(100);
	$integer->all_of([$positive, $under_a_hundred]);
	$integer->ok(42); # passes
	$integer->ok('101'); # fails

Tests that the subject also matches one of the protoypes given in the arrayref. If a member of the arrayref given is not a prototype, the argument is upgraded to become one.

=cut

sub all_of {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'all_of', { expected => $expected }, $reason );
}

define_test all_of => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $i = 0;
	foreach my $candidate ( @{ $data->{expected} } ) {
		my $result = upgrade($candidate)->validate( $self->subject, $self->subtest );
		return $self->fail("Candidate $i was unsuccessful") unless $result;
		$i++;
	}
	return $self->pass("All of the $i candidates were successful");
};

=head3 none_of

	$positive = p->num_gt(0);
	$all = p->like(qr/[02468]$/);
	$integer->none_of([$positive, $all]);
	$integer->ok(-1); # passes
	$integer->ok(-2); # fails
	$integer->ok(1); # fails

Tests that the subject does not match any of the protoypes given in the arrayref. If a member of the arrayref given is not a prototype, the argument is upgraded to become one.

=cut

sub none_of {
	my ( $self, $expected, $reason ) = @_;
	$self->add_test( 'none_of', { expected => $expected }, $reason );
}

define_test none_of => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $i = 0;
	foreach my $candidate ( @{ $data->{expected} } ) {
		my $result = upgrade($candidate)->validate( $self->subject, $self->subtest );
		return $self->fail("Candidate $i was successful") if $result;
		$i++;
	}
	return $self->pass("None of the $i candidates were successful");
};

=head3 some_of

	p->some_of([qr/cheap/, qr/fast/, qr/good/], 2, 'Pick two!');

Tests that the subject some, all, or none of the protoypes given in the arrayref; the number of successful matches is tested against the second argument. If a member of the arrayref given is not a prototype, the argument is upgraded to become one.

=cut

sub some_of {
	my ( $self, $expected, $count, $reason ) = @_;
	$count = p->gt(0) unless defined $count;
	$self->add_test(
		'some_of',
		{
			expected => $expected,
			count    => $count
		},
		$reason
	);
}

define_test some_of => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	my $i = 0;
	foreach my $candidate ( @{ $data->{expected} } ) {
		$i++ if upgrade($candidate)->validate( $self->subject, $self->subtest );
	}
	return $self->pass if upgrade( $data->{count} )->validate( $i, $self->subtest );
	return $self->fail;
};

=head3 looks_like_number

	p->looks_like_number->ok('3'); # passes
	p->looks_like_number->ok('a'); # fails

If the test subject looks like a number according to Perl's internal rules (specifically, using Scalar::Util::looks_like_number), then pass.

=cut

sub looks_like_number {
	my ( $self, $expected, $count, $reason ) = @_;
	$self->add_test( 'looks_like_number', $reason );
}

define_test looks_like_number => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	return $self->pass if Scalar::Util::looks_like_number( $self->subject );
	return $self->fail;
};

=head3 looks_unlike_number

	p->looks_unlike_number->ok('3'); # fails
	p->looks_unlike_number->ok('a'); # passes

If the test subject looks like a number according to Perl's internal rules (specifically, using Scalar::Util::looks_like_number), then fail.

=cut

sub looks_unlike_number {
	my ( $self, $expected, $count, $reason ) = @_;
	$self->add_test( 'looks_unlike_number', $reason );
}

define_test looks_unlike_number => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	return $self->fail if Scalar::Util::looks_like_number( $self->subject );
	return $self->pass;
};

=head3 is_weak_ref

DOES NOT WORK

Tests that the subject is a weak reference using is_weak from L<Scalar::Util>.

=cut

sub is_weak_ref {
	my ( $self, $reason ) = @_;
	$self->add_test( 'is_weak_ref', {}, $reason );
}

define_test is_weak_ref => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	return $self->fail("Not a reference") unless CORE::ref $self->subject;
	return $self->fail("Not weak") unless isweak $self->subject;
	return $self->pass("Weak reference");
};

=head3 is_strong_ref

DOES NOT WORK

Tests that the subject is not a weak reference using is_weak from L<Scalar::Util>.

=cut

sub is_strong_ref {
	my ( $self, $reason ) = @_;
	$self->add_test( 'is_strong_ref', {}, $reason );
}

define_test is_strong_ref => sub {
	my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
	return $self->fail("Not a reference") unless CORE::ref $self->subject;
	return $self->fail("Weak reference") if isweak $self->subject;
	return $self->pass("Not a weak reference");
};

=head2 Data::DPath

The following functions will load if you have Data::DPath installed.

=cut

eval {
	require Data::DPath;
	Data::DPath->import();
};
unless ($@) {

	#~ Data::DPath loaded ok

=head3 dpath_true

	p->dpath_true('//answer[ val == 42 ]')

Evaluates the dpath expression and passes if it finds a match.

=cut

	sub dpath_true {
		my ( $self, $path, $reason ) = @_;
		$self->add_test( 'dpath_true', { path => $path }, $reason );
	}

=head3 dpath_false

	p->dpath_false('//answer[ !val ]')

Evaluates the dpath expression and passes if it does not find a match.

=cut

	sub dpath_false {
		my ( $self, $path, $reason ) = @_;
		$self->add_test( 'dpath_false', { path => $path }, $reason );
	}

=head3 dpath_results

	p->dpath_false('//answer', pArray->array_any(42))

Evaluates the dpath expression and then uses the second argument (which should be upgradeable to a L<Test::Proto::ArrayRef>) to validate the list of matches.

=cut

	sub dpath_results {
		my ( $self, $path, $expected, $reason ) = @_;
		$self->add_test(
			'dpath_results',
			{
				path     => $path,
				expected => $expected
			},
			$reason
		);
	}

	define_test dpath_true => sub {
		my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
		my $dpath  = Data::DPath::build_dpath()->( $data->{path} );
		my $result = scalar( $dpath->match( $self->subject ) );
		return $self->pass if $result;
		return $self->fail;
	};
	define_test dpath_false => sub {
		my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
		my $dpath  = Data::DPath::build_dpath()->( $data->{path} );
		my $result = scalar( $dpath->match( $self->subject ) );
		return $self->fail if $result;
		return $self->pass;
	};
	define_test dpath_results => sub {
		my ( $self, $data, $reason ) = @_;    # self is the runner, NOT the prototype
		my $dpath  = Data::DPath::build_dpath()->( $data->{path} );
		my $result = [ $dpath->match( $self->subject ) ];
		return upgrade( $data->{expected} )->validate( $result, $self );
	};

}

=head1 OTHER INFORMATION

For author, version, bug reports, support, etc, please see L<Test::Proto>. 

=cut

1;
