package Test::Mocha::SpyBase;
# ABSTRACT: Abstract base class for Spy and Mock
$Test::Mocha::SpyBase::VERSION = '0.66';
use strict;
use warnings;

use Carp 1.22 ();

# class attributes
our $__CaptureMode         = q{};
our @__CapturedMethodCalls = ();

## no critic (NamingConventions::Capitalization)
sub __CaptureMode {
    my ( $class, $value ) = @_;
    return $__CaptureMode;
}

sub __CaptureMethodCall {
    my ( $class, $method_call ) = @_;
    push @__CapturedMethodCalls, $method_call;
    return;
}
## use critic

sub __new {
    my %args = (
        calls => [],  # ArrayRef[ MethodCall ]
        stubs => {},  # $method_name => ArrayRef[ MethodStub ]
    );
    return \%args;
}

sub __calls {
    my ($self) = @_;
    return $self->{calls};
}

sub __stubs {
    my ($self) = @_;
    return $self->{stubs};
}

sub __find_stub {
    # """
    # Returns the first stub that satisfies the given method call.
    # Returns undef if no stub is found.
    # """
    my ( $self, $method_call ) = @_;
    my $stubs = $self->__stubs;

    return if !defined $stubs->{ $method_call->name };

    foreach my $stub ( @{ $stubs->{ $method_call->name } } ) {
        return $stub if $stub->__satisfied_by($method_call);
    }
    return;
}

sub __capture_method_calls {
    # """
    # Get the last method called on a mock object,
    # removes it from the invocation history,
    # and restores the last method stub response.
    # """
    my ( $class, $coderef, $action ) = @_;

    ### assert: !$__CaptureMode
    my @method_calls;
    {
        local $__CaptureMode         = $action;
        local @__CapturedMethodCalls = ();

        # Execute the coderef. This should in turn include a method call on
        # mock, which should be handled by its AUTOLOAD method.
        $coderef->();

        Carp::croak 'Coderef must have a method invoked on a mock or spy object'
          if @__CapturedMethodCalls == 0;

        @method_calls = @__CapturedMethodCalls;
    }

    return @method_calls;
}

1;
