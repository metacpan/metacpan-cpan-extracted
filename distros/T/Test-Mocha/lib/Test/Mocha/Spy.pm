package Test::Mocha::Spy;
# ABSTRACT: Spy objects
$Test::Mocha::Spy::VERSION = '0.67';
use parent 'Test::Mocha::SpyBase';
use strict;
use warnings;

use Carp 1.22 ();
use Scalar::Util ();
use Test::Mocha::MethodCall;
use Test::Mocha::MethodStub;
use Test::Mocha::Util ();
use Types::Standard   ();
use if $] lt '5.025', 'UNIVERSAL::ref';

our $AUTOLOAD;

my %DEFAULT_STUBS = (
    can => Test::Mocha::MethodStub->new(
        # can() should return a reference to AUTOLOAD() for all methods
        name      => 'can',
        args      => [Types::Standard::Str],
        responses => [
            sub {
                my ( $self, $method_name ) = @_;
                return if !$self->__object->can($method_name);
                return sub {
                    $AUTOLOAD = $method_name;
                    goto &AUTOLOAD;
                };
            }
        ],
    ),
    ref => Test::Mocha::MethodStub->new(
        # ref() is a special stub because we use UNIVERSAL::ref which
        # allows us to call it as a method even though it's not a method
        # in the wrapped object.
        name      => 'ref',
        args      => [],
        responses => [
            sub {
                my ($self) = @_;
                return ref( $self->__object );
            }
        ],
    ),
);

sub __new {
    # uncoverable pod
    my ( $class, $object ) = @_;
    Carp::croak "Can't spy on an unblessed reference"
      if !Scalar::Util::blessed($object);

    my $args = $class->SUPER::__new;

    $args->{object} = $object;
    $args->{stubs}  = {
        map { $_ => [ $DEFAULT_STUBS{$_} ] }
          keys %DEFAULT_STUBS
    };
    return bless $args, $class;
}

sub __object {
    my ($self) = @_;
    return $self->{object};
}

sub AUTOLOAD {
    my ( $self, @args ) = @_;
    Test::Mocha::Util::check_slurpy_arg(@args);

    my $method_name = Test::Mocha::Util::extract_method_name($AUTOLOAD);

    # record the method call for verification
    my $method_call = Test::Mocha::MethodCall->new(
        invocant => $self,
        name     => $method_name,
        args     => \@args,
        caller   => [Test::Mocha::Util::find_caller],
    );

    if ( $self->__CaptureMode ) {
        if (
            !$self->__object->can($method_name)
            # allow ref() to be recorded and verified
            && $method_name ne 'ref'
          )
        {
            Carp::croak(
                sprintf
                  qq{Can't %s object method "%s" because it can't be located via package "%s"},
                $self->__CaptureMode, $method_name, ref( $self->__object )
            );
        }

        $self->__CaptureMethodCall($method_call);
        return;
    }

    # record the method call to allow for verification
    push @{ $self->__calls }, $method_call;

    # find a stub to return a response
    if ( my $stub = $self->__find_stub($method_call) ) {
        return $stub->execute_next_response( $self, @args );
    }

    # delegate the method call to the real object
    Carp::croak(
        sprintf
          qq{Can't call object method "%s" because it can't be located via package "%s"},
        $method_name,
        ref( $self->__object )
    ) if !$self->__object->can($method_name);

    return $self->__object->$method_name(@args);
}

sub isa {
    # uncoverable pod
    my ( $self, $class ) = @_;

    # Don't let AUTOLOAD handle internal isa() calls
    return 1 if $self->SUPER::isa($class);

    $AUTOLOAD = 'isa';
    goto &AUTOLOAD;
}

sub DOES {
    # uncoverable pod
    my ( $self, $role ) = @_;

    # Handle internal calls from UNIVERSAL::ref::_hook()
    # when ref($mock) is called
    return 1 if $role eq __PACKAGE__;

    return if !ref $self;

    $AUTOLOAD = 'DOES';
    goto &AUTOLOAD;
}

sub can {
    # uncoverable pod
    my ( $self, $method_name ) = @_;

    # Handle can('CARP_TRACE') for internal croak()'s (Carp v1.32+)
    return if $method_name eq 'CARP_TRACE';

    $AUTOLOAD = 'can';
    goto &AUTOLOAD;
}

# Don't let AUTOLOAD() handle DESTROY() so that object can be destroyed
sub DESTROY { }

1;
