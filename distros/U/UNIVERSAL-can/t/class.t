#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 16;
use Test::SmallWarn;

# must happen here to register warnings category
BEGIN { use_ok( 'UNIVERSAL::can' ) };

{
	package Logger;

	use Scalar::Util 'blessed';

	use vars '$AUTOLOAD';

	sub new
	{
		my ($class, $object) = @_;
		bless { object => $object, calls => [] }, $class;
	}

	sub object
	{
		my $self = shift;
		return $self->{object} if blessed( $self );
		return $self;
	}

	sub calls
	{
		my $self = shift;
		return $self->{calls};
	}

	sub can
	{
		my ($self, $name)  = @_;
		my $object         = $self->object();
		return $self->SUPER::can( $name ) if $object->isa( __PACKAGE__ );
		my $wrapped_method = $self->object->can( $name );
	}

	sub DESTROY {}

	sub AUTOLOAD
	{
		my $self     = shift;
		my ($method) = $AUTOLOAD =~ /::(\w+)$/;
		return unless my $coderef = $self->object->can( $method );

		push @{ $self->calls() }, $method;
		$self->object->$coderef( @_ );
	}

	package Logged;

	sub new
	{
		my $class = shift;
		bless \$class, $class;
	}

	sub foo
	{
		my $self = shift;
		return 'foo'; }

	package Liar;

	use vars '$AUTOLOAD';

	sub can
	{
		my $self = shift;
		return Logger->can( shift );
	}

	sub DESTROY {}

	sub AUTOLOAD
	{
		my $self     = shift;
		my ($method) = $AUTOLOAD =~ /::(\w+)$/;
		return Logger->$method( @_ );
	}
}

my $logger  = Logger->new( 'Logged' );

my $can_new = $logger->can( 'new' );
my $can_foo = $logger->can( 'foo' );
ok( defined  $can_new, 'can() should return true for defined class methods' );
ok( defined &$can_new, '... returning a code reference' );
is( $can_foo, \&Logged::foo, '... the correct code reference' );

my $uncan_foo;
warning_like { $uncan_foo = UNIVERSAL::can( $logger, 'foo' ) }
	qr/Called UNIVERSAL::can\(\) as a function, not a method at t.class.t/,
	'calling UNIVERSAL::can() as function on invocant should warn';
ok( defined  $uncan_foo, 'UNIVERSAL::can() should return true then too' );
ok( defined &$uncan_foo, '... returning a code reference' );
is( $uncan_foo, \&Logged::foo, '... the correct code reference' );

my $can_calls = Logger->can( 'calls' );
ok(  defined $can_calls,
	'can() should return true for methods called as class methods' );
my $can_falls = Logger->can( 'falls' );
ok( ! defined $can_falls,
	'... and false for nonexistant methods' );

my $uncan_liar;
warning_like { $uncan_liar = UNIVERSAL::can( 'Liar', 'new' ) }
	qr/Called UNIVERSAL::can\(\) as a function, not a method at t.class.t/,
	'calling UNIVERSAL::can() as function on class name invocant should warn';

{
	no warnings;
	warnings_are { $uncan_liar = UNIVERSAL::can( 'Liar', 'new' ) }
		[], '... but only with warnings enabled';
}

{
	no warnings 'UNIVERSAL::can';
	warnings_are { $uncan_liar = UNIVERSAL::can( 'Liar', 'new' ) }
		[], '... and not with warnings diabled for UNIVERSAL::can';
}

ok( defined  $uncan_liar, 'can() should return true for class can() method' );
ok( defined &$uncan_liar, '... returning a code reference' );
is( $uncan_liar, \&Logger::new, '... the correct code reference' );
