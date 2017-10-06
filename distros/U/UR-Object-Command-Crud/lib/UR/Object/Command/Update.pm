package UR::Object::Command::Update;

use strict;
use warnings 'FATAL';

class UR::Object::Command::Update {
    is => 'Command::V2',
    is_abstract => 1,
    has_constant_transient => {
        target_name_pl => { via => 'namespace', to => 'target_name_pl', },
        target_name_ub_pl => { via => 'namespace', to => 'target_name_ub_pl', },
    },
    doc => 'CRUD update command class.',
};

sub help_brief { $_[0]->__meta__->doc }
sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;

    my $new_value = $self->value;
    $new_value = undef if $new_value eq '';
    my $new_value_id = UR::Object::Command::CrudUtil->display_id_for_value($new_value);

    my $property_name = $self->property_name;
    my $target_name_ub_pl = $self->target_name_ub_pl;
    my @objects = $self->$target_name_ub_pl;

    $self->status_message("Update %s %s...", $self->target_name_pl, $property_name);
    for my $obj( @objects ) {
        my $old_value = $obj->$property_name;
        my $old_value_id = UR::Object::Command::CrudUtil->display_id_for_value($old_value);
        if ( $self->only_if_null and defined $old_value ) {
            $self->status_message("FAILED_NOT_NULL\t%s\t%s\t%s", $obj->class, $obj->id, $old_value_id);
            next;
        }
        $obj->$property_name($new_value);
        $self->status_message("UPDATE\t%s\t%s\t%s\t%s", $obj->class, $obj->id, $old_value_id, $new_value_id);
    }
    1; 
}

1;
