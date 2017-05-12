use strict;

package Counter;
use selfvars -self => 'this', -args => 'vars', -opts => 'vars';

sub new {
    my $class = shift;
    return bless { v => 0 }, $class;
}

sub set {
    my ($v) = @vars;
    $this->{v} = $v;
}

sub set_named {
    $this->{v} = $vars{v};
}

sub out {
    $this->{v};
}

sub inc {
    $this->{v}++;
}

package ChildofCounter;
use base 'Counter';

package SecondCounter;
use selfvars;

sub new {
    my $class = shift;
    return bless { v => 0 }, $class;
}

sub set {
    my ($v) = @args;
    $self->{v} = $v;
}

sub out {
    $self->{v};
}

sub inc {
    $self->{v}++;
}

1;
