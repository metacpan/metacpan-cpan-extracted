package Zing::Journal;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Channel';

our $VERSION = '0.20'; # VERSION

# ATTRIBUTES

has 'name' => (
  is => 'ro',
  isa => 'Str',
  init_arg => undef,
  new => 1,
  mod => 1,
);

fun new_name($self) {
  '$journal'
}

has level => (
  is => 'ro',
  isa => 'Str',
  def => 'debug',
);

has tap => (
  is => 'rw',
  isa => 'Bool',
  def => 1,
);

has verbose => (
  is => 'ro',
  isa => 'Bool',
  def => 0,
);

# METHODS

method stream(CodeRef $callback) {
  while ($self->tap) {
    next unless my $info = $self->recv;

    my $from = $info->{from};
    my $data = $info->{data};
    my $logs = $data->{logs};

    $logs->{level} = $self->level;

    my $logger = $self->app->logger(%{$logs});
    my $report = $self->verbose ? 'verbose' : 'simple';
    my $lines = $logger->$report->lines;

    $callback->($info, $data, $lines);
  }

  return $self;
}

1;
