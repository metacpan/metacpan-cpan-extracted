package Buddha::TestFixture;

use strict;
use warnings;
use base qw(Test::FITesque::Fixture);

our $RECORDED = [];

sub one : Test : Plan(3) {
  my ($self, @args) = @_;
  push @$RECORDED, ['ONE', @args];
}

sub apple : Test {
  my ($self, @args) = @_;
  push @$RECORDED, ['APPLE', @args];
}

sub click_here : Test : Plan(2) {
  my ($self, @args) = @_;
  push @$RECORDED, ['CLICK_HERE', @args];
}

1;
