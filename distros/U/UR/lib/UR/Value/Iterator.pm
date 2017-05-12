package UR::Value::Iterator;

use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;

sub create {
    my $class = shift;
    my $set = $class->define_set(@_);
    my @members = $set->members;
    return $class->create_for_value_arrayref(\@members);
}

sub create_for_value_arrayref {
    my ($class, $arrayref) = @_;
    my @copy = @$arrayref;
    return bless { members => \@copy }, $class;
}

sub next {
    shift @{ shift->{members} };
}

1;

