package UR::Value::Set;
use strict;
use warnings;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

sub members {
    my $self = shift;
    my %params = $self->rule->params_list;
    my $id = $params{id};
    if (ref($id) eq 'ARRAY') {
        return (@$id);
    }
    else {
        return ($id);
    }
}

1;

