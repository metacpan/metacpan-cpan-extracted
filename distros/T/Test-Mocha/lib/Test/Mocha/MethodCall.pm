package Test::Mocha::MethodCall;
# ABSTRACT: Objects to represent method calls
$Test::Mocha::MethodCall::VERSION = '0.65';
use parent 'Test::Mocha::Method';
use strict;
use warnings;

sub new {
    # uncoverable pod
    my ( $class, %args ) = @_;
    # caller should be an arrayref tuple [file, line]
    ### assert: defined $args{invocant}
    ### assert: defined $args{caller}
    ### assert: ref $args{caller} eq 'ARRAY' && @{$args{caller}} == 2
    return $class->SUPER::new(%args);
}

sub invocant {
    # uncoverable pod
    return $_[0]->{invocant};
}

sub caller {  ## no critic (ProhibitBuiltinHomonyms)
                                  # uncoverable pod
    return @{ $_[0]->{caller} };  # ($file, $line)
}

sub stringify_long {
    # uncoverable pod
    my ($self) = @_;
    return sprintf '%s called at %s line %d',
      $self->SUPER::stringify, $self->caller;
}

1;
