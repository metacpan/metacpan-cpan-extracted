package Buddha::FITesqueFixture;

use strict;
use warnings;
use base qw(Test::FITesque::Fixture);

our $RECORDED = [];

sub one : Test {
  push @$RECORDED, 'one';
}

sub two : Test {
  push @$RECORDED, 'two';
}

sub three : Test {
  push @$RECORDED, 'three';
}

1;
