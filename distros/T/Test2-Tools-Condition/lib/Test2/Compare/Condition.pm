package Test2::Compare::Condition;
use strict;
use warnings;

use base 'Test2::Compare::Base';

use Carp qw/croak/;

use Test2::Util::HashBase qw/code/;

# Overloads '!' for us.
use Test2::Compare::Negatable;

sub init {
    my $self = shift;

    croak "'code' must be a code reference" unless ref $self->{+CODE} eq 'CODE';

    $self->SUPER::init();
}

sub operator {
    my $self = shift;
    return '!=' if $self->{+NEGATE};
    return '==';
}

sub name { '<CONDITION>' }

sub verify {
    my $self = shift;
    my %params = @_;
    my ($got, $exists) = @params{qw/got exists/};

    return 0 unless $params{exists};

    local $_ = $got;
    my $cond = $self->{+CODE}->();
    $cond = $cond ? 0 : 1 if $self->{+NEGATE};

    return $cond;
}

sub run {
    my $self = shift;
    my $delta = $self->SUPER::run(@_) or return;

    my $dne = $delta->dne || "";
    unless ($dne eq 'got') {
        my $got = $delta->got;
        $delta->set_got(_render_bool($got));
    }

    return $delta;
}

sub _render_bool {
    my $bool = shift;
    my $name = $bool ? 'TRUE' : 'FALSE';
    my $val = defined $bool ? $bool : 'undef';
    $val = "''" unless length($val);

    return "<$name ($val)>";
}

1;
