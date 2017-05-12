package Test::Proto::Common;
use 5.008;
use strict;
use warnings;
use Sub::Name;
use Exporter 'import';
use Scalar::Util qw(blessed looks_like_number);
our @EXPORT = qw(define_test define_simple_test simple_test upgrade upgrade_comparison);

our $TEST_PREFIX = '_TEST_';    #~ this is used when creating internal methods.

=head1 NAME

Test::Proto::Common - Provides common functions for Test::Proto development

=head1 SYNOPSIS

	use Test::Proto::Common; # exports all functions automatically

Provides functions used to build a Prototype class.

=cut

=head1 FUNCTIONS

All these functions are for use in prototype classes, not in scripts.

=head3 define_test

	define_test 'is_uppercase', sub {
		my ($self, $data, $reason) = @_; # self is the runner, NOT the prototype
		if ($self->subject =~ !/[a-z]/){ 
			return $self->pass;
		}
		return $self->fail;
	};

Adds a test definition to the class. This allows you to create user-facing test methods which interact with the test definition. The name you provide is the name of the test definition, which usually matches the test method (but is not required to).

Optionally, you can set the package to which this method is to be added as a third argument.

=cut

sub define_test {
	my ( $testName, $testSub,  $customPackage ) = @_;
	my ( $package,  $filename, $line )          = caller;
	$package = $customPackage if defined $customPackage;
	{
		no strict 'refs';
		my $fullName = $package . '::' . $TEST_PREFIX . $testName;
		*$fullName = subname( $TEST_PREFIX . $testName, $testSub );    #~ Consider Sub::Install here, per Khisanth on irc.freenode.net#perl
	}

	#~ return value of this not specified
}

=head3 define_simple_test

Adds a test definition to the class. In this case, the subroutine passed evaluates the subject against the expected data.

=cut

sub define_simple_test {
	my ( $testName, $testSub,  $customPackage ) = @_;
	my ( $package,  $filename, $line )          = caller;
	$package = $customPackage if defined $customPackage;
	define_test(
		$testName,
		sub {
			my ( $self, $data, $reason ) = ( shift, shift, shift );    # self is the runner, NOT the prototype
			if ( $testSub->( $self->subject, $data->{expected} ) ) {
				return $self->pass;
			}
			else {
				return $self->fail;
			}
		},
		$package
	);
}

=head3 simple_test

	simple_test 'lc_eq', sub {
		return lc ($_[0]) eq $_[1];
	};
	
	...
	
	p->lc_eq('yes')->ok('Yes');

Adds a test method to the class. The first argument is the name of that method, the second argument is the code to be executed - however, the code should return only a true or false value, and is passed only the test subject and the expected value, not the runner or full data. 

The test method itself takes one argument, the expected value.

=cut

sub simple_test {
	my ( $testName, $testSub ) = @_;
	my ( $package, $filename, $line ) = caller;
	{
		no strict 'refs';
		{
			#package $package;
			define_simple_test( $testName, $testSub, $package );
		}
		my $fullName = $package . '::' . $testName;
		*$fullName = subname(
			$testName,
			sub {
				my ( $self, $expected, $reason ) = ( shift, shift, shift );
				$self->add_test( $testName, { expected => $expected }, $reason );
			}
		);    # Consider Sub::Install here, per Khisanth on irc.freenode.net#perl
	}
}

=head3 upgrade

	upgrade('NONE'); # returns Test::Proto::Base->new()->eq('NONE')
	upgrade(1); # returns Test::Proto::Base->new()->num_eq(1)
	upgrade(['foo']); # returns Test::Proto::ArrayRef->new()->array_eq(['foo'])
	upgrade({'foo'=>'bar'}); # returns Test::Proto::HashRef->new()->hash_of({'foo'=>'bar'})
	upgrade(sub {return $_ * 2 == 4}); Test::Proto::Base->new()->try(...)

Returns a Prototype which corresponds to the data in the first argument. 

If the first argument is already a prototype, this does nothing.

Use this when you have a parameter and want to validate data against it, but you do not know if it is a prototype or 'natural data'.

=cut

sub upgrade {
	my ( $expected, $noref ) = @_;
	{
		require Test::Proto::Base;
		require Test::Proto::HashRef;
		require Test::Proto::ArrayRef;

		if ( defined ref $expected ) {
			if ( blessed $expected) {
				return Test::Proto::ArrayRef->new()->array->contains_only($expected)
					if $expected->isa('Test::Proto::Series')
					or $expected->isa('Test::Proto::Repeatable')
					or $expected->isa('Test::Proto::Alternation');
				return $expected if $expected->isa('Test::Proto::Base');
			}
			return Test::Proto::ArrayRef->new()->array->array_eq($expected)   if ref $expected eq 'ARRAY';
			return Test::Proto::HashRef->new()->hash->superhash_of($expected) if ref $expected eq 'HASH';
			return Test::Proto::Base->new()->like($expected)                  if ref $expected eq 'Regexp';
			return Test::Proto::Base->new()->try($expected)                   if ref $expected eq 'CODE';
		}
		return Test::Proto::Base->new()->scalar->num_eq($expected) if Scalar::Util::looks_like_number($expected);

		#return Test::Proto::Base->new()->eq($expected) if $noref;
		return Test::Proto::Base->new()->scalar->eq($expected);
	}
}

=head3 upgrade_comparison

	upgrade_comparison(sub {lc shift cmp lc shift}, 'Lowercase Comparison');

This creates a Test::Proto::Compare object using the code provided in the first argument. The second argument, if present, is used as the summary.

If the first argument is either of the strings 'cmp' or '<=>', it will return the appropriate string or numeric comparison, as these are special-cased.

=cut

sub upgrade_comparison {
	require Test::Proto::Compare;
	require Test::Proto::Compare::Numeric;
	my ( $comparison, $summary ) = @_;
	$summary = 'Unknown comparison' unless defined $summary;    #:5.8
	if ( ref $comparison eq 'CODE' ) {
		return Test::Proto::Compare->new($comparison)->summary($summary);
	}
	elsif ( blessed $comparison and $comparison->isa('Test::Proto::Compare') ) {
		return $comparison;
	}
	elsif ( defined $comparison and !ref $comparison ) {
		return Test::Proto::Compare->new          if $comparison eq 'cmp';
		return Test::Proto::Compare::Numeric->new if $comparison eq '<=>';
	}
	return Test::Proto::Compare->new;
}

=head3 chainable

	around 'attr', 'other_attr', \&Test::Proto::Common::chainable;

	...

	$object->attr(2)->some_method;

Use this to make a Moo attribute chainable.
	
=cut

sub chainable {
	my $orig = shift;
	my $self = shift;
	if ( exists $_[0] ) {

		#~ when setting, return self
		$orig->( $self, @_ );
		return $self;
	}
	else {
		#~ when getting, return value
		return $orig->( $self, @_ );
	}
}

1;
