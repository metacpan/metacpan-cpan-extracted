package Helm::Log::Channel;
use strict;
use warnings;
use Moose;
use namespace::autoclean;

has uri            => (is => 'ro', writer => '_uri',            isa => 'URI');
has task           => (is => 'ro', writer => '_task',           isa => 'Str');
has current_server => (is => 'ro', writer => '_current_server', isa => 'Helm::Server|Undef');

sub initialize {
    my ($self, $helm) = @_;
    die "You must implement the initialize() method in your child class " . ref($self) . "!";
}

sub finalize {
    my ($self, $helm) = @_;
    die "You must implement the finalize() method in your child class " . ref($self) . "!";
}

sub parallelize {
    my ($self, $helm) = @_;
    die "You must implement the parallelize() method in your child class " . ref($self) . "!";
}

sub start_server {
    my ($self, $server) = @_;
    $self->_current_server($server);
}

sub end_server {
    my ($self, $server) = @_;
    $self->_current_server(undef);
}

sub debug {
    my ($self, $msg) = @_;
    die "You must implement the debug() method in your child class " . ref($self) . "!";
}

sub info {
    my ($self, $msg) = @_;
    die "You must implement the info() method in your child class " . ref($self) . "!";
}

sub warn {
    my ($self, $msg) = @_;
    die "You must implement the warn() method in your child class " . ref($self) . "!";
}

sub error {
    my ($self, $msg) = @_;
    die "You must implement the error() method in your child class " . ref($self) . "!";
}

sub forked {
    my ($self, $type) = @_;
    die "You must implement the forked() method in your child class " . ref($self) . "!";
}

__PACKAGE__->meta->make_immutable;

1;
