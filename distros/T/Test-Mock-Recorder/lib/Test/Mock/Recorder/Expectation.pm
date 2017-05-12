package Test::Mock::Recorder::Expectation;
use strict;
use warnings;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_ro_accessors(qw(method));
__PACKAGE__->mk_accessors(qw(method returns dies code));

use Test::Mock::Recorder::InvalidArguments;
use Data::Compare;

sub with {
    my ($self, @argv) = @_;
    $self->_with(\@argv);
}

sub without_arguments {
    my ($self) = @_;
    $self->_with([]);
}

sub _with {
    my ($self, $argv_ref) = @_;

    if ($argv_ref) {
        $self->{_with} = $argv_ref;
        return $self;
    } else {
        return $self->{_with};
    }
}

sub verify {
    my ($self, @argv) = @_;

    if ($self->code) {
        return $self->code->(@argv);
    } else {
        if ($self->_with) {
            if (Compare($self->_with, [ splice @argv, 1 ])) {
                ;
            } else {
                die Test::Mock::Recorder::InvalidArguments->new({
                    method => $self->method
                });
            }
        }

        if ($self->dies) {
            die $self->dies;
        } else {
            return $self->returns;
        }
    }
}

1;
