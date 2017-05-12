package Test::Proto::Base;
use 5.008;
use strict;
use warnings;
use Test::Proto::Common;
use Test::Proto::TestRunner;
use Test::Proto::Formatter::TestBuilder;
use Test::Proto::TestCase;
use Moo;
use overload
	'&' => \&_overload_AND,
	'|' => \&_overload_OR,
	'^' => \&_overload_XOR,
	'!' => \&_overload_NOT,
	;
with('Test::Proto::Role::Value');
with('Test::Proto::Role::Tagged');
our $VERSION = '0.027';

=pod

=head1 NAME

Test::Proto::Base - Base Class for Test Prototypes

=head1 SYNOPSIS

	my $p = Test::Proto::Base->new->is_eq(-5);
	$p->ok ($temperature) # will fail unless $temperature is -5
	$p->ok ($score) # you can use the same test multple times
	ok($p->validate($score)) # If you like your "ok"s first

This is a base class for test prototypes. 

Throughout this documentation, C<p> will be used as a shorthand for C<< Test::Proto::Base->new >>.

=cut

=head1 METHODS

=head2 PUBLIC METHODS

These are the methods intended for use when execcuting tests. All the methods for writing tests can be found at L<Test::Proto::Role::Value>.

=cut

=head3 validate

	my $result = $p->validate($subject);
	warn $result unless $result;

Runs through the tests in the prototype and checks that they all pass. It returns a TestRunner which evaluates true or false accordingly. 

If you have an existing TestRunner, you can pass it that as well;

	my $result = $p->validate($subject, $context);

EXPERIMENTAL: If no argument is passed, $_ will be used.

=cut

sub validate {
	my ( $self, $subject, $context ) = @_;
	$subject = $_ unless exists $_[1];
	if ( !defined $context or !CORE::ref($context) ) {    # if context is not a TestRunner
		my $reason = $context;
		$context = Test::Proto::TestRunner->new( subject => $subject );
		if ( defined $reason ) {
			$context->subtest->diag($reason);
		}
	}
	else {
		$context->subject($subject);
	}
	$self->run_tests($context);
	$context->done;
	return $context;
}

=head3 ok

	$p->ok($subject, $context)

Works like validate, only produces a Test::Builder-compatible TAP output. 

=cut

sub ok {
	my ( $self, $subject, $context ) = @_;
	my $reason = $context;
	$context = Test::Proto::TestRunner->new( formatter => Test::Proto::Formatter::TestBuilder->new() ) unless ( ( defined $context ) and ( CORE::ref $context ) );
	if ( defined $reason ) {
		$context->subtest->diag($reason);
	}
	$self->validate( $subject, $context );
}

=head3 clone

This method returns a copy of the current object. The new object can have tests added without affecting the existing test. However, existing tests are not cloned, so if you want to tag them, you will need to clone them too.

=cut

sub clone {
	my $self = shift;
	my $pkg  = CORE::ref $self;
	my %args = ( map { $_ => [ @{ $self->$_ } ] } qw(natural_script user_script tags) );
	return $pkg->new(%args);
}

=head2 OPERATOR OVERLOADING

Prototypes can be combined with the operators C<&>, C<|>, C<^>, and negated: C<!>. In all cases, a new prototype is returned.

	$x & $y => p->all_of([$x, $y])
	$x | $y => p->any_of([$x, $y])
	$x ^ $y => p->some_of([$x, $y], 1)
	!$x     => p->none_of([$x])

Remember that this only works with prototypes. C<'A' & 'B'> still returns C<'@'>.

=cut

=head2 PROTOTYPER METHODS

These are for documentation purposes only.

=cut

=head3 natural_type

This roughly corresponds to C<ref>. Useful for indicating what sort of element you're expecting.

This is documented for information purposes only and is not intended to be used except in the maintainance of C<Test::Proto> itself.

=cut

has natural_type => (
	is      => 'rw',
	default => sub { '' },
	,
);    # roughly corresponds to ref.

=head3 natural_script

These are tests common to the whole prototype which need not be repeated if two similar scripts are joined together. Normally, this should only be modified by the prototype class.

This is documented for information purposes only and is not intended to be used except in the maintainance of C<Test::Proto> itself.

=cut

has natural_script => (
	is      => 'rw',
	default => sub { [] },
);

=head3 user_script

These are the tests which the user (specifically, the test script author) has added by a method call. Normally, these should empty in a class but may be present in an instance of an object.

This is documented for information purposes only and is not intended to be used except in the maintainance of C<Test::Proto> itself.

=cut

has user_script => (
	is      => 'rw',
	default => sub { [] },
);

=head3 script

This method returns an arrayref containing the contents of the C<natural_script> and the C<user_script>, i.e. all the tests in the object that are due to be run when C<< ->ok() >> is called.

=cut

sub script {
	my $self = shift;
	return [ @{ $self->natural_script }, @{ $self->user_script }, ];
}

=head3 add_test

This method adds a test to the current object, specifically to the C<user_script>, and returns the prototype object.

This is documented for information purposes only and is not intended to be used except in the maintainance of C<Test::Proto> itself.

=cut

sub add_test {
	my ( $self, $name, $data, $reason ) = @_;
	my $package = CORE::ref($self);

	my $testMethodName = $package . '::' . ${Test::Proto::Common::TEST_PREFIX} . $name;
	my $code           = sub {
		my $runner  = shift;
		my $subject = $runner->subject;
		{
			no strict 'refs';
			eval { &{$testMethodName}( $runner, $data, $reason ); };
			$runner->exception( "Failed during $name\n" . $@ ) if $@;
		}
	};
	push @{ $self->user_script },
		Test::Proto::TestCase->new(
		name   => $name,
		code   => $code,
		data   => $data,
		reason => $reason,
		);
	return $self;
}

=head3 run_tests

	$self->run_tests($subject, $context);

This method runs all the tests in the prototype object's script (simply calling the C<< ->run_test >> method on each), and returns the prototype object. 

This is documented for information purposes only and is not intended to be used except in the maintainance of C<Test::Proto> itself.

=cut

sub run_tests {
	my ( $self, $context ) = @_;
	my $runner = $context->subtest( test_case => $self );
	foreach my $test ( @{ $self->script } ) {

		# $self->run_test($test, $runner);
		$runner->run_test( $test, $self );
		return $self if $runner->is_exception;
	}
	$runner->done( "A " . ( ref $self ) . " must pass all its subtests." );
	return $self;
}

=head1 OTHER INFORMATION

For author, version, bug reports, support, etc, please see L<Test::Proto>. 

=cut

sub _overload_AND {
	my ( $left, $right ) = @_;
	return __PACKAGE__->new->all_of( [ $left, $right ] );
}

sub _overload_OR {
	my ( $left, $right ) = @_;
	return __PACKAGE__->new->any_of( [ $left, $right ] );
}

sub _overload_XOR {
	my ( $left, $right ) = @_;
	return __PACKAGE__->new->some_of( [ $left, $right ], 1 );
}

sub _overload_NOT {
	my ($left) = @_;
	return __PACKAGE__->new->none_of( [$left], 1 );
}

1;
