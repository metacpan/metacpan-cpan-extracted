package UR::Object::Command::UpdateIsMany;

use strict;
use warnings 'FATAL';

class UR::Object::Command::UpdateIsMany {
    is => 'Command::V2',
    is_abstract => 1,
    has_constant_transient => {
        target_name_ub_pl => { via => 'namespace', to => 'target_name_ub_pl', },
    },
    doc => 'CRUD update is many property command class.',
};

sub help_brief { $_[0]->__meta__->doc }
sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;

    my $target_name_ub_pl = $self->target_name_ub_pl;
    my $property_function = $self->property_function;
    my @new_values = $self->values;
    OBJECT: for my $object ( $self->$target_name_ub_pl ) {
        my $object_id = UR::Object::Command::CrudUtil->display_id_for_value($object);
        for my $new_value ( $self->values ) {
            my $new_value_id = UR::Object::Command::CrudUtil->display_id_for_value($new_value);
            $self->status_message("%s\t%s\t%s", uc($property_function), $object_id, $new_value_id);
            $object->$property_function($new_value);
        }
    }

    1;
}

1;
