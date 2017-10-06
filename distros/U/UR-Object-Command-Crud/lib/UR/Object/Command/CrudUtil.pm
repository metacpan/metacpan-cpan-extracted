package UR::Object::Command::CrudUtil;

use strict;
use warnings 'FATAL';

class UR::Object::Command::CrudUtil {
    doc => 'Utils for CRUD commands',
};

sub display_id_for_value {
    my ($class, $value) = @_;

    if ( not defined $value ) {
        'NULL';
    }
    elsif ( ref($value) eq 'HASH' or ref($value) eq 'ARRAY' ) {
        die 'Do not pass HASH or ARRAY to display_id_for_value!';
    }
    elsif ( not Scalar::Util::blessed($value) ) {
        $value;
    }
    elsif ( $value->can('id') ) {
        $value->id;
    }
    else { # stringify
        "$value";
    }
}

1;
