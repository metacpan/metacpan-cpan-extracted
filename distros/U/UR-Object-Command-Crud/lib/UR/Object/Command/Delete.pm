package UR::Object::Command::Delete;

use strict;
use warnings 'FATAL';

class UR::Object::Command::Delete {
    is => 'Command::V2',
    is_abstract => 1,
    has_constant => {
        target_name_ub => { via => 'namespace', to => 'target_name_ub', },
    },
    doc => 'CRUD delete command class.',
};

sub help_brief { $_[0]->__meta__->doc }
sub help_detail { $_[0]->__meta__->doc }

sub execute {
    my $self = shift;

    my $tx = UR::Context::Transaction->begin;

    my $target_name_ub = $self->target_name_ub;
    my $obj = $self->$target_name_ub;
    my $msg = sprintf('DELETE %s %s', $obj->class, $obj->id);
    $obj->delete;

    if (!$tx->commit ) {
        $tx->rollback;
        $self->fatal_message('Failed to commit software transaction!');
    }

    $self->status_message($msg);
    1;
}

1;
