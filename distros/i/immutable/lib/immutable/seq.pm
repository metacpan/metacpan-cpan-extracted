use strict; use warnings;
package immutable::seq;

sub import {
    die "Don't 'use immutable::seq' directly";
}



package immutable::seq::tied;
use Tie::Array;
use base 'Tie::StdArray';
use immutable::tied;


# Prevent tied changes to immutable::seq.
# Mutation operations must use method calls which will return a new seq.

sub STORE { err 'set a value on', '->set($index, $val)' }
sub PUSH { err 'push values onto', '->push($val, ...)' }
sub POP { err 'pop a value from', '->pop()' }
sub UNSHIFT { err 'unshift values onto', '->unshift($val, ...)' }
sub SHIFT { err 'shift a value from', '->shift()' }
sub SPLICE { err 'splice values from', '->splice(...)' }

sub DELETE { err }
sub STORESIZE { err }
sub CLEAR { err }
sub EXTEND { err }



package immutable::seq;
use immutable::base;
use base 'immutable::base';

sub new {
    my ($class, @data) = @_;
    $class = ref($class) if ref($class);
    tie my @array, 'immutable::seq::tied';
    push @{tied(@array)}, @data;
    bless \@array, $class;
}

sub get {
    tied(@{$_[0]})->[$_[1]];
}

sub set {
    my ($self, $index, $value) = @_;
    my @data = @$self;
    $data[$index] = $value;
    $self->new(@data);
}

sub push {
    my ($self, @data) = @_;
    $self->new(@$self, @data);
}

sub pop {
    my ($self) = @_;
    my @data = @$self;
    my $val = pop @data;
    my $new = $self->new(@data);
    wantarray ? ($new, $val) : $new;
}

sub shift {
    my ($self) = @_;
    my @data = @$self;
    my $val = shift @data;
    my $new = $self->new(@data);
    wantarray ? ($new, $val) : $new;
}

sub unshift {
    my ($self, @data) = @_;
    $self->new(@data, @$self);
}

sub size {
    0 + @{$_[0]};
}

sub DESTROY {
    untie(@{$_[0]});
}

1;
