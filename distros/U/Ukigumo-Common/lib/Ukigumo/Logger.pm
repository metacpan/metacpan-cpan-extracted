package Ukigumo::Logger;
use strict;
use warnings;
use Log::Minimal;

use Mouse;

has prefix => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { +[ ] },
);

has _prefix => (
    is  => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self   = shift;
        my $prefix = join ' ', @{$self->prefix};
        $prefix .= ' ' if $prefix;
    }
);

has _infof => (
    is      => 'ro',
    default => sub {
        *Log::Minimal::infof{CODE};
    },
);

has _warnf => (
    is      => 'ro',
    default => sub {
        *Log::Minimal::warnf{CODE};
    },
);

no Mouse;

no warnings qw/redefine/;

sub infof {
    my ($self, @info) = @_;
    local $Log::Minimal::TRACE_LEVEL = 1;
    $info[0] = $self->_prefix . $info[0];
    $self->_infof->(@info);
}

sub warnf {
    my ($self, @warn) = @_;
    local $Log::Minimal::TRACE_LEVEL = 1;
    $warn[0] = $self->_prefix . $warn[0];
    $self->_warnf->(@warn);
}

use warnings;

1;

