package UR::Namespace::Command::Show::Schema;
use strict;
use warnings;

class UR::Namespace::Command::Show::Schema {
    is => 'Command::V2',
    has_input => [
        class_names => { 
          is => 'Text', 
          is_many => 1,
          shell_args_position => 1,
          require_user_verify => 0,
          doc => 'dump the required database schema changes for a class or classes'
        },
        complete => {
          is => 'Boolean',
          default_value => 0,
          doc => 'when set, dump the complete table creation command not just the required changes',
        },
    ],
    doc => 'database DDL',
};

sub execute {
    my $self = shift;
    my @class_names = $self->class_names;
    $ENV{UR_DBI_NO_COMMIT} = 1;
    my $t = UR::Context::Transaction->begin;
    $DB::single = 1;
    for my $class_name (@class_names) {
        my $meta = $class_name->__meta__;

        my $class_name = $meta->class_name;
        $self->status_message("-- class $class_name\n");
        my $ds = $meta->data_source;
        my @schema_objects = $ds->generate_schema_for_class_meta($meta,1); 
        my ($tt) = grep { $_->isa("UR::DataSource::RDBMS::Table") } @schema_objects; 
        my @ddl = $ds->_resolve_ddl_for_table($tt, all => 1);
        if (@ddl) {
            my $ddl = join("\n",@ddl);
            $self->status_message($ddl);
        }
        else {
            $self->status_message("-- no changes for $class_name, run with the 'complete' flag for the full table DDL");
        }
    }
    $t->rollback;
    return 1;
}

1;

