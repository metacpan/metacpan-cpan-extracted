package Test::Expectation::Base;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Sub::Override;

sub new {
    my ($class, $expectedClass, $expectedMethod) = @_;

    $expectedClass = ref($expectedClass) if (ref($expectedClass));

    my $methodString = "${expectedClass}::${expectedMethod}";

    my $self = {
        -met => 0,
        -method => $methodString,
        -class => $expectedClass,
        -failure => $methodString . " not called",
        -returnValues => []
    };

    $self->{-expectationsSet} = {};

    bless($self, $class);

    $self->_setReplacement(sub {
        $self->met();
        $self->_doReturn
    });

    return $self;
}

sub _doReturn {
    my $self = shift;

    if (wantarray) {
        return @{$self->{-returnValues}};
    }
    else {
        return $self->{-returnValues}->[0];
    }
}

# if an expectation is being set against one of these classes, then something
# has probably gone wrong.
sub expects {
    croak('Cannot set multiple expectations against a single method')
}
*does_not_expect = *expects;

sub _setReplacement {
    my ($self, $code) = @_;

    eval {
        $self->_restore();
        $self->{-replacement} = Sub::Override->new(
            $self->{-method} => $code
        );
    };
}

sub with {
    my ($self, @expectedParams) = @_;

    croak('Cannot define "with" more than once against a single expectation')
        if ($self->{-expectationsSet}->{-with})
    ;

    $self->{-expectationsSet}->{-with} = 1;

    $self->{-failure} = $self->{-failure} . " with '@expectedParams'";

    $self->_setReplacement(sub {
        my (@params) = @_;

        shift(@params) if (ref($params[0]) && (ref($params[0]) eq $self->{-class}));

        $self->{-failure} .= ", got '@params'";

        $self->met() if (Dumper(@params) eq Dumper(@expectedParams));

        $self->_doReturn;
    });

    return $self;
}

# this isn't camel-cased so it's external interface is consistent
sub to_return {
    my ($self, @returnValues) = @_;

    croak('Cannot set more that one return expectation')
        if ($self->{-expectationsSet}->{-return})
    ;

    $self->{-expectationsSet}->{-return} = 1;

    @{$self->{-returnValues}} = @returnValues;

    return $self
}

sub to_raise {
    my ($self, $exception) = @_;

    croak('Cannot expect more than one exception')
        if ($self->{-expectationsSet}->{-exception})
    ;

    $self->{-expectationsSet}->{-exception} = 1;

    $self->_setReplacement(sub {
        $self->met();
        die($exception . "\n");
    });

    return $self;
}

sub met {
    shift->{-met} = 1;
}

sub isMet {
    shift->{-met};
}

sub class {
    shift->{-class};
}

sub failure {
    shift->{-failure}
}

sub _restore {
    my $self = shift;
    $self->{-replacement}->restore() if $self->{-replacement};
}

sub DESTROY {
    shift->_restore();
}

1;

