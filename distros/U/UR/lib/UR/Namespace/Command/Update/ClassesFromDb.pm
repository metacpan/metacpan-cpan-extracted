
package UR::Namespace::Command::Update::ClassesFromDb;

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;
use Text::Diff;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::RunsOnModulesInTree',
    has => [
        data_source                 => { is => 'List',      is_optional => 1, doc => 'Limit updates to these data sources' },        
        force_check_all_tables      => { is => 'Boolean',   is_optional => 1, doc => 'By default we only look at tables with a new DDL time for changed database schema information.  This explicitly (slowly) checks each table against our cache.' },
        force_rewrite_all_classes   => { is => 'Boolean',   is_optional => 1, doc => 'By default we only rewrite classes where there are database changes.  Set this flag to rewrite all classes even where there are no schema changes.' },
        table_name                  => { is => 'List',      is_optional => 1, doc => 'Update the specified table.' },
        class_name                  => { is => 'List',      is_optional => 1, doc => 'Update only the specified classes.' },
    ],
);

sub sub_command_sort_position { 2 };

sub help_brief {
    "Update class definitions (and data dictionary cache) to reflect changes in the database schema."
}

sub help_detail {
    return <<EOS;

Reads from the data sources in the current working directory's namespace,
and updates the local class tree.

This hits the data dictionary for the remote database, and gets changes there
first.  Those changes are then used to mutate the class tree.

If specific data sources are specified on the command-line, it will limit
its database examination to just data in those data sources.  This command
will, however, always load ALL classes in the namespace when doing this update,
to find classes which currently reference the updated table, or are connected
to its class indirectly.

EOS
}



sub create {
    my($class,%params) = @_;

    for my $param_name (qw/data_source class_name table_name/) {
        if (exists $params{$param_name} && ! ref($params{$param_name})) {
            # Make sure the data_source parameter is always a listref, even if there's only one item
            $params{$param_name} = [ $params{$param_name} ];
        }
    }

    # This is used by the test case to turn on no-commit for the metadata DB,
    # but still have _sync_filesystem write out the modules
    my $override = delete $params{'_override_no_commit_for_filesystem_items'};

    my $obj =  $class->SUPER::create(%params);
    return unless $obj;

    $obj->{'_override_no_commit_for_filesystem_items'} = $override if $override;

    return $obj;
}


our @dd_classes = (
    'UR::DataSource::RDBMS::Table',
    'UR::DataSource::RDBMS::TableColumn',
    'UR::DataSource::RDBMS::FkConstraint',
    'UR::DataSource::RDBMS::Table::Ghost',
    'UR::DataSource::RDBMS::TableColumn::Ghost',
    'UR::DataSource::RDBMS::FkConstraint::Ghost',
);    

sub execute {
    my $self = shift;

    #
    # Command parameter checking
    #
    
    my $force_check_all_tables = $self->force_check_all_tables;
    my $force_rewrite_all_classes = $self->force_rewrite_all_classes;
    
    my $namespace = $self->namespace_name;
    $self->status_message("Updating namespace: $namespace\n");

    my @namespace_data_sources = $namespace->get_data_sources;

    my $specified_table_name_arrayref = $self->table_name;
    my $specified_data_source_arrayref = $self->data_source;
    my $specified_class_name_arrayref = $self->class_name;
   
 
    my @data_dictionary_objects;
    
    if ($specified_class_name_arrayref or $specified_table_name_arrayref) {
        my $ds_table_list;
        if ($specified_class_name_arrayref) {
            $ds_table_list = [
                map { [$_->data_source, $_->table_name] }
                grep { $_->data_source }
                map { $_->__meta__ }
                @$specified_class_name_arrayref
            ];        
        }
        else {
            $ds_table_list = [
                map { [$_->data_source, $_->table_name] }
                UR::DataSource::RDBMS::Table->get(table_name => $specified_table_name_arrayref)
            ];
            for my $item (@$ds_table_list) {
                UR::Object::Type->get(data_source => $item->[0], table_name => $item->[1]);
            }
        }

        for my $item (@$ds_table_list) {
            my ($data_source, $table_name) = @$item;
            $self->_update_database_metadata_objects_for_schema_changes(
                data_source => $data_source,
                force_check_all_tables => $force_check_all_tables,
                table_name => $table_name,
            );
            for my $dd_class (qw/UR::DataSource::RDBMS::Table UR::DataSource::RDBMS::FkConstraint UR::DataSource::RDBMS::TableColumn/) {
                push @data_dictionary_objects,
                    $dd_class->get(data_source_obj => $data_source, table_name => $table_name);
            }
        }
    }
    else {
        # Do the update by data source, all or whatever is specified.
        
        #
        # Determine which data sources to update from.
        # By default, we do all datasources owned by the namespace.
        #
        
        my @target_data_sources;
        if ($specified_data_source_arrayref) {
            @target_data_sources = ();
            my %data_source_is_specified = map { $_ => 1 } @$specified_data_source_arrayref;
            for my $ds (@namespace_data_sources) {
                if ($data_source_is_specified{$ds->id}) {
                    push @target_data_sources, $ds;
                    delete $data_source_is_specified{$ds->id};
                }
            }
            #delete @data_source_is_specified{@namespace_data_sources};
            if (my @unknown = keys %data_source_is_specified) {
                $self->error_message(
                    "Unknown data source(s) for namespace $namespace: @unknown!\n"
                    . "Select from:\n"
                    . join("\n",map { $_->id } @namespace_data_sources)
                    . "\n"
                );
                return;
            }
        } else {
            # Don't update the Meta datasource, unless they specificly asked for it
            @target_data_sources = grep { $_->id !~ /::Meta$/ } @namespace_data_sources;
        }

        # Some data sources can't handle the magic required for automatic class updating...
        @target_data_sources = grep { $_->can('get_table_names') } @target_data_sources;
        
        $self->status_message("Found data sources: " 
            .   join(", " , 
                    map { /${namespace}::DataSource::(.*)$/; $1 || $_ } 
                    map { $_->id }
                    @target_data_sources
                )
        );
        
        #
        # A copy of the database metadata is in the ::Meta sqlite datasource.
        # Get updates to it first.
        #
        
        ##$DB::single = 1;
        
        for my $data_source (@target_data_sources) {
            # ensure the class has been lazy-loaded until UNIVERSAL::can is smarter...
            $data_source->class;
            $self->status_message("Checking " . $data_source->id . " for schema changes ...");
            my $success =
                $self->_update_database_metadata_objects_for_schema_changes(
                    data_source => $data_source,
                    force_check_all_tables => $force_check_all_tables,
                );
            unless ($success) {
                return;
            }
        }

        #
        # Summarize the database changes by table.  We'll create/update/delete the class which goes with that table.
        #

        ##$DB::single = 1;

        my $cx = UR::Context->current; 
        for my $dd_class (qw/UR::DataSource::RDBMS::Table UR::DataSource::RDBMS::FkConstraint UR::DataSource::RDBMS::TableColumn/) {
            push @data_dictionary_objects, 
                grep { $force_rewrite_all_classes ? 1 : $_->__changes__ or exists($_->{'db_saved_uncommitted'}) } 
                $cx->all_objects_loaded($dd_class);

            my $ghost_class = $dd_class . "::Ghost";
            push @data_dictionary_objects, $cx->all_objects_loaded($ghost_class);
        }
    }
    
    # The @data_dictionary_objects array has all dd meta which should be used to rewrite classes.
    
    my %changed_tables;    
    for my $obj (
        @data_dictionary_objects
    ) {
        my $table;
        if ($obj->can("get_table")) {
            $table = $obj->get_table;
            unless ($table) {
                Carp::confess("No table object for $obj" . $obj->id);
            }
        }
        elsif ($obj->isa("UR::DataSource::RDBMS::Table") or $obj->isa("UR::DataSource::RDBMS::Table::Ghost")) {
            $table = $obj
        }
        # we may find no table if it was dropped, and this is one of its old cols/constraints
        next unless $table;

        $changed_tables{$table->id} = 1;
    }


    # Some ill-behaved modules might set no_commit to true at compile time.
    # Reset it back to whatever it is now after going through the namespace's modules
    # Note that when we have class info in the metadata DB, this probably won't be
    # necessary anymore since we won't have to actually load up the .pm files to 
    # discover classes in the namespace
    
    my $remembered_no_commit_setting = UR::DBI->no_commit(); 
    my $remembered_dummy_ids_setting = UR::DataSource->use_dummy_autogenerated_ids();


    #
    # Update the classes based-on changes to the database schemas
    #

    ##$DB::single = 1;

    if (@data_dictionary_objects) {
        $self->status_message("Found " . keys(%changed_tables) . " tables with changes.") unless $force_rewrite_all_classes;
        $self->status_message("Resolving corresponding class changes...");
        my $success =
            $self->_update_class_metadata_objects_to_match_database_metadata_changes(
                data_dictionary_objects => \@data_dictionary_objects
            );
        unless ($success) {
            return;
        }
    }
    else {
        $self->status_message("No data schema changes.");
    }

    UR::DBI->no_commit($remembered_no_commit_setting);
    UR::DataSource->use_dummy_autogenerated_ids($remembered_dummy_ids_setting);


    #
    # The namespace module may have special rules for creating classes from regular (non-schema) data.
    # At this point we allow the namespace to adjust the class tree as it chooses.
    #

    $namespace->class;
    if (
        $namespace->can("_update_classes_from_data_sources") 
        and not $specified_table_name_arrayref 
        and not $specified_class_name_arrayref
        and not $specified_data_source_arrayref
    ) {
        $self->status_message("Checking for custom changes for the $namespace namespace...");
        $namespace->_update_classes_from_data_sources();
    }

    $self->status_message("Saving metadata changes...");
    my $sync_success = UR::Context->_sync_databases();
    unless ($sync_success) {
        ##$DB::single = 1;
        $self->error_message("Metadata sync_database failed");
        UR::Context->_rollback_databases();
        return;
    }

    # 
    # Re-write the class headers for changed classes.
    # Output a summary report of what has been changed.
    # This block of logic shold be part of saving class data.
    # Right now, it's done with a _load() override, no data_source, and this block of code. :(
    #

    ##$DB::single = 1;

    my $cx = UR::Context->current;
    my @changed_class_meta_objects;
    my %changed_classes;
    my $module_update_success = eval {
        for my $meta_class (qw/
            UR::Object::Type
            UR::Object::Property
        /) {
            push @changed_class_meta_objects, grep { $_->__changes__ } $cx->all_objects_loaded($meta_class);

            my $ghost_class = $meta_class . "::Ghost";
            push @changed_class_meta_objects, $cx->all_objects_loaded($ghost_class);
        }

        for my $obj (
            @changed_class_meta_objects
        ) {
            my $class_name = $obj->class_name;
            next unless $class_name;  #if $obj is a ghost, class_name might return undef?
            $changed_classes{$class_name} = 1;
        }
        unless (@changed_class_meta_objects) {
            $self->status_message("No class changes.");
        }

        my $changed_class_count = scalar(keys %changed_classes);
        my $subj = $changed_class_count == 1 ? "class" : "classes";
        $self->status_message("Resolved changes for $changed_class_count $subj");

        $self->status_message("Updating the filesystem...");
        my $success = $self->_sync_filesystem(
            changed_class_names => [sort keys %changed_classes],
        );
        return $success;
    };

    if ($@) {
        $self->error_message("Error updating the filesystem: $@");
        return;
    }
    elsif (!$module_update_success) {
        $self->status_message("Error updating filesystem!");
        return;
    } 
  
    $self->status_message("Filesystem update complete.");
             

    #
    # This commit actually records the data dictionary changes in the ::Meta datasource sqlite database.
    #

    $self->status_message("Committing changes to data sources...");

    unless (UR::Context->_commit_databases()) {
        ##$DB::single = 1;
        $self->error_message("Metadata commit failed");
        return;
    }


    #
    # The logic below is only necessary if this process is run as part of some larger process.
    # Right now that includes the automated test for this module.
    # After classes have been updated they won't function properly.
    # Ungenerate and re-generate each of the classes we touched, so that it functions according to its new spec.
    # 

    $self->status_message("Cleaning up.");

    my $success = 1;
    for my $class_name (sort keys %changed_classes) {
        my $class_obj = UR::Object::Type->get($class_name);
        next unless $class_obj;
        $class_obj->ungenerate;
        Carp::confess("class $class_name didn't ungenerate properly") if $class_obj->generated;
        unless (eval { $class_obj->generate } ) {
            $self->warning_message("Class $class_name didn't re-generate properly: $@");
            $success = 0;
        }
    }

    unless ($success) {
        $self->status_message("Errors occurred re-generating some classes after update.");
        return;
    }

    #
    # Done
    #

    $self->status_message("Update complete.");
    return 1;
}

#
# The execute() method above is broken into three parts:
#   ->_update_database_metadata_objects_for_schema_changes()
#   ->_update_class_metadata_objects_to_match_database_metadata_changes()
#   ->_sync_filesystem()
#

sub _update_database_metadata_objects_for_schema_changes {
    my ($self, %params) = @_;
    my $data_source = delete $params{data_source};
    my $force_check_all_tables = delete $params{force_check_all_tables};
    my $table_name = delete $params{table_name};
    die "unknown params " . Dumper(\%params) if keys %params;

    #$data_source = $data_source->class;

    my @changed;

    my $last_ddl_time_for_table_name = {};
    if ($data_source->can("get_table_last_ddl_times_by_table_name") and !$force_check_all_tables) {
        # the driver implements a way to get the last DDL time
        $last_ddl_time_for_table_name = $data_source->get_table_last_ddl_times_by_table_name;
    }

    # from the cache of known tables
    my @previous_table_names = $data_source->get_table_names;
    my %previous_table_names = map { $_ => 1 } @previous_table_names;

    # from the database now
    my @current_table_names = $data_source->_get_table_names_from_data_dictionary();
    my %current_table_names = map { s/"|'//g; $_ => $_ } @current_table_names;

    my %all_table_names = $table_name
                            ? ( $table_name => 1 )
                            : ( %current_table_names, %previous_table_names);

    my $new_object_revision = $UR::Context::current->now();

    # handle tables which are new/updated by updating the class
    my (@create,@delete,@update);
    my $pattern = '%-42s';
    my ($dsn) = ($data_source->id =~ /^.*::DataSource::(.*?)$/);
    for my $table_name (keys %all_table_names) {
        my $last_actual_ddl_time = $last_ddl_time_for_table_name->{$table_name};

        my $table_object;
        my $last_recorded_ddl_time;
        my $last_object_revision;

        my $db_table_name = $current_table_names{$table_name};

        eval {
            #($table_object) = $data_source->get_tables(table_name => $table_name);

            # Using the above doesn't account for a table switching databases, which happens.
            # Once the data source is _part_ of the id we'll just have a delete/add, but for now it's an update.
            $table_object = UR::DataSource::RDBMS::Table->get(data_source => $data_source->id,
                                                              table_name => $table_name);
        };

        if ($current_table_names{$table_name} and not $table_object) {
            # new table
            push @create, $table_name;
            $self->status_message(
                sprintf(
                    "A  $pattern Schema changes " . ($last_actual_ddl_time ? "on $last_actual_ddl_time" : ""),
                    $dsn . " " . $table_name
                )
            );
            my $table_object = $data_source->refresh_database_metadata_for_table_name($db_table_name);
            next unless $table_object; 

            $table_object->last_ddl_time($last_ddl_time_for_table_name->{$table_name});
        }
        elsif ($current_table_names{$table_name} and $table_object) {
            # retained table
            # either we know it changed, or we can't know, so update it anyway
            if (! exists $last_ddl_time_for_table_name->{$table_name} or
                ! defined $table_object->last_ddl_time or
                $last_ddl_time_for_table_name->{$table_name} gt $table_object->last_ddl_time
            ) {
                my $last_update = $table_object->last_ddl_time || $table_object->last_object_revision;
                my $this_update = $last_ddl_time_for_table_name->{$table_name} || "<unknown date>";
                my $table_object = $data_source->refresh_database_metadata_for_table_name($db_table_name);
                unless ($table_object) {
                    ##$DB::single = 1;
                    print;
                }
                my @changes =
                #    grep { not  ($_->properties == 1 and ($_->properties)[0] eq "last_object_revision") }
                    $table_object->__changes__;
                if (@changes) {
                    $self->status_message(
                        sprintf("U  $pattern Last updated on $last_update.  Newer schema changes on $this_update."
                            , $dsn . " " . $table_name
                        )
                    );                        
                    push @update, $table_name;
                }
                $table_object->last_ddl_time($last_ddl_time_for_table_name->{$table_name});
            }
        }
        elsif ($table_object and not $current_table_names{$table_name}) {
            # deleted table
            push @delete, $table_name;
            $self->status_message(
                sprintf(
                    "D  $pattern Last updated on %s.  Table dropped.",
                    $dsn . " " . $table_name,
                    $last_object_revision || "<unknown date>"
                )
            );
            my $table_object = UR::DataSource::RDBMS::Table->get(
                                       data_source => $data_source->id,
                                       table_name => $table_name,
                                   );
            $table_object->delete;
        }
        else {
            Carp::confess("Unable to categorize table $table_name as new/old/deleted?!");
        }
    }

    return 1;
}



# Keep a cache of class meta objects so we don't have to keep asking the 
# object system to do it for us.  This should be a speed optimization because
# the asking eventually filters down to calling get_material_classes() on the
# namespace which can be extremely slow.  If it's not in the cache, defer to 
# asking the data source
sub _get_class_meta_for_table_name {
    my($self,%param) = @_;

    my $data_source = $param{'data_source'};
    my $data_source_name = $data_source->get_name();
    my $table_name = $param{'table_name'};

    my ($obj) = 
        grep { not $_->isa("UR::Object::Ghost") } 
        UR::Object::Type->is_loaded(
            data_source_id => $data_source,
            table_name => $table_name
        );
    return $obj if $obj;


    unless ($self->{'_class_meta_cache'}{$data_source_name}) {
        my @classes =
            grep { not $_->class_name->isa('UR::Object::Ghost') } 
            UR::Object::Type->get(data_source_id => $data_source);
            
        for my $class (@classes) {
            my $table_name = $class->table_name;
            next unless $table_name;
            $self->{'_class_meta_cache'}->{$data_source_name}->{$table_name} = $class;
        }        
    }
    
    $obj = $self->{'_class_meta_cache'}->{$data_source_name}->{$table_name};
    return $obj if $obj;
    return;
}


sub  _update_class_metadata_objects_to_match_database_metadata_changes {
    my ($self, %params) = @_;

    my $data_dictionary_objects = delete $params{data_dictionary_objects};
    if (%params) {
        $self->error_message("Unknown params!");
        return;
    }

    #
    # INITIALIZATION AND SANITY CHECKING
    #

    my $namespace = $self->namespace_name;

    $self->status_message("Updating classes...");

    my %dd_changes_by_class = (
        'UR::DataSource::RDBMS::Table' => [],
        'UR::DataSource::RDBMS::TableColumn' => [],
        'UR::DataSource::RDBMS::FkConstraint' => [],
        'UR::DataSource::RDBMS::Table::Ghost' => [],
        'UR::DataSource::RDBMS::TableColumn::Ghost' => [],
        'UR::DataSource::RDBMS::FkConstraint::Ghost' => [],
    );
    for my $changed_obj (@$data_dictionary_objects) {
        my $changed_class = $changed_obj->class;
        my $bucket = $dd_changes_by_class{$changed_class};
        push @$bucket, $changed_obj;
    }
    my $sorter = sub($$) { no warnings 'uninitialized';
                        $_[0]->table_name cmp $_[1]->table_name || $_[0]->id cmp $_[1]->id
                     };

    # FKs are special, in that they might change names, but we use the name as the "id".
    # This should change, really, but until it does we need to identify them by their "content",

    #
    # DELETIONS
    #

    # DELETED FK CONSTRAINTS
    #  Just detach the object reference meta-data from the constraint.
    #  We only actually delete references when their properties all go away,
    #  which can happen when the columns go away (through table deletion or alteration).
    #  It can also happen when one of the involved classes is deleted, which never happens
    #  automatically.
    
    for my $fk (sort $sorter @{ $dd_changes_by_class{'UR::DataSource::RDBMS::FkConstraint::Ghost'} }) {
        unless ($fk->table_name) {
            $self->status_message(sprintf("~ No table name for deleted foreign key constraint %-32s\n", $fk->id));
            next;
        }

        my $table = $fk->get_table;
        my $class = $self->_get_class_meta_for_table_name(data_source => $table->data_source,
                                                          table_name  => $table->table_name);

        unless ($class) {
            ##$DB::single = 1;
            $self->status_message(sprintf("~ No class found for deleted foreign key constraint %-32s %-32s\n",$table->table_name, $fk->id));
            next;
        }
        my $class_name = $class->class_name;
        my $property = UR::Object::Property->get(class_name => $class_name, constraint_name => $fk->fk_constraint_name);
        unless ($property) {
            $self->status_message(sprintf("~ No property found for deleted foreign key constraint %-32s %-32s class $class_name\n",
                                          $table->table_name, $fk->fk_constraint_name));
            next;
        }
        $property->delete;
 
    }

    # DELETED UNIQUE CONSTRAINTS
    # DELETED PK CONSTRAINTS
    #  We do nothing here, because we don't track these as individual DD objects, just values on the table object.
    #  If a table changes constraints, that is handled below after table/column add/update.
    #  If a table is dropped entirely, we leave all pk/unique constraints in place,
    #  since, if the class is not manually deleted by the developer, it should continue
    #  to function as it did before.

    # DELETED COLUMNS
    my @saved_removed_column_messages;  # Delete them now, but report about them later in the 'Updating class properties' section
    for my $column (sort $sorter @{ $dd_changes_by_class{"UR::DataSource::RDBMS::TableColumn::Ghost"} }) {
        my $table = $column->get_table;
        unless ($table) {
            $self->status_message(sprintf("~ No table found for deleted column %-32s\n", $column->id));
            next;
        }
        my $column_name = $column->column_name;

        my $class = $self->_get_class_meta_for_table_name(data_source => $table->data_source,
                                                          table_name  => $table->table_name);
        unless ($class) {
            $self->status_message(sprintf("~ No class found for deleted column %-32s %-32s\n", $table->table_name, $column_name));
            next;
        }
        my $class_name = $class->class_name;

        my ($property) = $class->direct_property_metas(
            column_name => $column_name
        );
        unless ($property) {
            $self->status_message(sprintf("~ No property found for deleted column %-32s %-32s\n",$table->table_name, $column_name));
            next;
        }

        unless ($table->isa("UR::DataSource::RDBMS::Table::Ghost")) {
            push(@saved_removed_column_messages, 
                sprintf("D %-40s property %-16s for removed column %s.%s\n",
                        $class->class_name,
                        $property->property_name,
                        $column->table_name, 
                        $column->column_name,
                )
            );
        }

        $property->delete;

        unless ($property->isa("UR::DeletedRef")) {
            Carp::confess("Error deleting property " . $property->id);
        }
    }

    # DELETED TABLES
    my %classes_with_deleted_tables;
    for my $table (sort $sorter @{ $dd_changes_by_class{"UR::DataSource::RDBMS::Table::Ghost"} }) {
        # Though we create classes for tables, we don't immediately delete them, just deflate them.
        my $table_name = $table->table_name;
        unless ($table_name) {
            $self->status_message("~ No table_name for deleted table object ".$table->id);
            next;
        }

        if (not defined UR::Context->_get_committed_property_value($table,'table_name')) {
            print Data::Dumper::Dumper($table);
            ##$DB::single = 1;
        }
        # FIXME should this use $data_source->get_class_meta_for_table($table) instead?
        my $committed_data_source_id = UR::Context->_get_committed_property_value($table,'data_source');
        my $committed_table_name     = UR::Context->_get_committed_property_value($table,'table_name');
        my $class = UR::Object::Type->get(
            data_source_id => $committed_data_source_id, 
            table_name     => $committed_table_name, 
        );
        unless ($class) {
            $self->status_message(sprintf("~ No class found for deleted table %-32s" . "\n",$table->id));
            next;
        }
        $classes_with_deleted_tables{$table_name} = $class;
        $class->data_source(undef);
        $class->table_name(undef);
    } # next deleted table

    for my $table_name (keys %classes_with_deleted_tables) {
        my $class = $classes_with_deleted_tables{$table_name};
        my $class_name = $class->class_name;

        my %ancestory = map { $_ => 1 } $class->inheritance;
        my @ancestors_with_tables =
            grep {
                $a = UR::Object::Type->get(class_name => $_)
                    || UR::Object::Type::Ghost->get(class_name => $_);
                $a && $a->table_name;
            } sort keys %ancestory;
        if (@ancestors_with_tables) {
            $self->status_message(
                sprintf("U %-40s class is now detached from deleted table %-32s.  It still inherits from classes with persistent storage." . "\n",$class_name,$table_name)
            );
        }
        else {
            $self->status_message(
                sprintf("D %-40s class deleted for deleted table %s" . "\n",$class_name,$table_name)
            );
        }
    } # next deleted table

    # This is the data structure used by _get_class_meta_for_table_name
    # There's a bad interaction with software transactions that can lead
    # to this cache containing deleted class objects if the caller holds
    # on to a reference to this command object and repetedly calls execute()
    # but rolls back transactions between those calls.
    $self->{'_class_meta_cache'} = {};

    ##$DB::single = 1;

    #
    # EXISTING DD OBJECTS
    #
    # TABLE
    for my $table (sort $sorter @{ $dd_changes_by_class{"UR::DataSource::RDBMS::Table"} }) {
        my $table_name = $table->table_name;
        my $data_source = $table->data_source;

        my $class = $self->_get_class_meta_for_table_name(data_source => $data_source,
                                                          table_name => $table_name);
      
        if ($class) {
            # update

            if ($class->data_source ne $table->data_source) {
                $class->data_source($table->data_source);
            }

            my $class_name = $class->class_name;
            no warnings;
            if ($table->remarks ne UR::Context->_get_committed_property_value($table,'remarks')) {
                $class->doc($table->remarks);
            }
            if ($table->data_source ne UR::Context->_get_committed_property_value($table,'data_source')) {
                $class->data_source($table->data_source);
            }
            
            if ($class->__changes__) {
                $self->status_message(
                    sprintf("U %-40s class uses %s %s %s" . "\n",
                            $class_name,
                            $table->data_source->get_name,
                            lc($table->table_type),
                            $table_name)
                );
            }
        }
        else {
            # create
            my $data_source = $table->data_source;
            my $data_source_id = (ref $data_source ? $data_source->id : $data_source);
            my $class_name = $data_source->resolve_class_name_for_table_name($table_name,$table->table_type);
            unless ($class_name) {
                Carp::confess(
                        "Failed to resolve a class name for new table "
                        . $table_name
                );
            }

            # if the original table_name was empty (ie. not backed by a table), and the
            # new one actually has a table, then this is just another schema change and
            # not an error.  Set the table_name attribute and go on...
            my $class = UR::Object::Type->get(class_name => $class_name);
            my $prev_table_name = ($class ? $class->table_name : undef);
            my $prev_data_source_id = ($class ? $class->data_source_id : undef);
            if ($class && $prev_table_name) {

                Carp::confess(
                    "Class $class_name already exists for table '$prev_table_name' in $prev_data_source_id."
                    . "  Cannot generate class for $table_name in $data_source_id."
                );
            }

            $self->status_message(
                     sprintf("A %-40s class uses %s %s %s" . "\n",
                             $class_name,
                             $table->data_source->get_name,
                             lc($table->table_type),
                             $table_name)
                     );

            if ($class) {
                $class->doc($table->remarks ? $table->remarks: undef);
                $class->data_source($data_source);
                $class->table_name($table_name);
                $class->er_role($table->er_type);
            } else {
                $class = UR::Object::Type->create(
                            class_name => $class_name,
                            doc => ($table->remarks ? $table->remarks: undef),
                            data_source_id => $data_source,
                            table_name => $table_name,
                            er_role => $table->er_type,
                            # generate => 0,
                );                
                unless ($class) {
                    Carp::confess(
                        "Failed to create class $class_name for new table "
                        . $table_name
                        . ". " . UR::Object::Type->error_message
                    );
                }
            }
        }
    } # next table

    $self->status_message("Updating direct class properties...\n");

    $self->status_message($_) foreach @saved_removed_column_messages;

    # COLUMN
    
    for my $column (sort $sorter @{ $dd_changes_by_class{'UR::DataSource::RDBMS::TableColumn'} }) {
        my $table = $column->get_table;
        my $column_name = $column->column_name;
        my $data_source = $table->data_source;
        my($ur_data_type, $default_length) = @{ $data_source->ur_data_type_for_data_source_data_type($column->data_type) };
        my $ur_data_length = defined($column->data_length) ? $column->data_length : $default_length;

        my $class = $self->_get_class_meta_for_table_name(data_source => $data_source,
                                                          table_name => $table->table_name);

        unless ($class) {
            $class = $self->_get_class_meta_for_table_name(data_source => $data_source,
                                                          table_name => $table->table_name);
            Carp::confess("Class object missing for table " . $table->table_name) unless $class;
        }
        my $class_name = $class->class_name;
        my $property;
        foreach my $prop_object ( $class->direct_property_metas ) {
            if (defined $prop_object->column_name and lc($prop_object->column_name) eq lc($column_name)) {
                $property = $prop_object;
                last;
            }
        }

        # We care less whether the column is new/updated, than whether there is property metadata for it.
        if ($property) {
            my @column_property_translations = (
                # [ column_name, property_name, conversion_sub(column_obj, value) ]
                ['data_length'  => 'data_length',
                    # lengths for these data types are based on the number of bytes used internally in the
                    # database.  The UR-based objects will store the text version, which will always be longer,
                    # making $obj->__errors__() complain about the length being out of bounds
                    sub { my ($c, $av) = @_;  defined($av) ? $av : ($c->is_time_data ? undef : $ur_data_length) } ],
                ['data_type'    => 'data_type',
                    sub { my ($c, $av) = @_;  defined($ur_data_type) ? $ur_data_type : $av } ],
                ['nullable'     => 'is_optional',
                    sub { my ($c, $av) = @_; (defined($av) and ($av eq "Y")) ? 1 : 0 } ],
                ['remarks'      => 'doc',
                    # Ideally this would only use DB value ($av) if the last_ddl_time was newer.
                    sub { my ($c, $av) = @_; defined($av) ? $av : $property->doc } ],
            );
            # update
            for my $translation (@column_property_translations) {
                my ($column_attr, $property_attr, $conversion_sub) = @$translation;
                $property_attr ||= $column_attr;

                no warnings;
                if (UR::Context->_get_committed_property_value($column,$column_attr) ne $column->$column_attr) {
                    if ($conversion_sub) {
                        $property->$property_attr($conversion_sub->($column, $column->$column_attr));
                    }
                    else {
                        $property->$property_attr($column->$column_attr);
                    }
                }
            }

            if ($property->__changes__) {
                no warnings;
                $self->status_message(
                    sprintf("U %-40s property %-20s for column %s.%s (%s %s)\n",
                                                            $class_name,
                                                            $property->property_name,
                                                            $table->table_name, 
                                                            $column_name,
                                                            $column->data_type,
                                                            $column->data_length)
                );
            }
        }
        else {
            # create
            my $property_name = $data_source->resolve_property_name_for_column_name($column->column_name);
            unless ($property_name) {
                Carp::confess(
                        "Failed to resolve a property name for new column "
                        . $column->column_name
                );
            }

            my $create_exception;
            for (my $attempt = 0; $attempt < 3; $attempt++) {
                $property_name = '_' . $property_name if $attempt;

                $create_exception = do {
                    local $@;
                    eval {
                        $property = UR::Object::Property->create(
                            class_name     => $class_name,
                            property_name  => $property_name,
                            column_name    => $column_name,
                            data_type      => $ur_data_type,
                            data_length    => $ur_data_length,
                            is_optional    => $column->nullable eq "Y" ? 1 : 0,
                            is_volatile    => 0,
                            doc            => $column->remarks,
                            is_specified_in_module_header => 1,
                        );
                    };
                    $@;
                };
                last if $property;
            }

            no warnings 'uninitialized';
            $self->status_message(
                sprintf("A %-40s property %-16s for column %s.%s (%s %s)\n",
                                                        $class_name,
                                                        $property->property_name,
                                                        $table->table_name, 
                                                        $column_name,
                                                        $column->data_type,
                                                        $column->data_length)
            );
            
            unless ($property) {
                if ($create_exception =~ m/An object of class UR::Object::Property already exists/) {
                    $self->warning_message("Conflicting property names already exist in class $class_name for column $column_name in table ".$table->table_name);
                } else {
                    Carp::confess(
                            "Failed to create property $property_name on class $class_name. "
                            . UR::Object::Property->error_message
                    );
                }
            }
        }
    } # next column

    $self->status_message("Updating class ID properties...\n");

    # PK CONSTRAINTS (loop table objects again, since the DD doesn't do individual ID objects)
    for my $table (sort $sorter @{ $dd_changes_by_class{'UR::DataSource::RDBMS::Table'} }) {
        # created/updated/unchanged
        # delete and re-create these objects: they're "bridges", so no developer supplied data is presesent
        my $table_name = $table->table_name;

        my $class = $self->_get_class_meta_for_table_name(data_source => $table->data_source,
                                                          table_name => $table_name);
        my $class_name = $class->class_name;
        my @properties = UR::Object::Property->get(class_name => $class_name);

        unless (@properties) {
            $self->warning_message("no properties on class $class_name?");
            ##$DB::single = 1;
        }

        my @expected_pk_cols = grep { defined }
                               map { $_->column_name }
                               grep { defined $_->is_id }
                               @properties;
        
        my @pk_cols = $table->primary_key_constraint_column_names;
        
        if ("@expected_pk_cols" eq "@pk_cols") {
            next;
        }
        
        unless (@pk_cols) {
            # If there are no primary keys defined, then treat _all_ the columns
            # as primary keys.  This means we don't support multiple rows in a
            # table containing the same data.
            @pk_cols = $table->column_names;
        }

        my %pk_cols;
        for my $pos (1 .. @pk_cols) {
            my $pk_col = $pk_cols[$pos-1];
            my ($property) = grep { defined($_->column_name) and ($_->column_name eq $pk_col) } @properties;
            
            unless ($property) {
                # the column has been removed
                next;
            }
            $pk_cols{$property->property_name} = $pos;
        }

        # all primary key properties are non-nullable, regardless of what the DB allows
        for my $property (@properties) {
            my $name = $property->property_name;
            if ($pk_cols{$name}) {
                $property->is_optional(0);
                $property->is_id($pk_cols{$name});
            }
        }
    } # next table (looking just for PK constraint changes)

    # Make another pass to make sure if a class has a property called 'id' with a column attached,
    # then it must be the only ID property of that class
    my %classes_to_check_id_properties;
    foreach my $thing ( qw(UR::DataSource::RDBMS::Table UR::DataSource::RDBMS::TableColumn ) ) {
        foreach my $item ( @{ $dd_changes_by_class{$thing} } ) {
            my $class_meta = $self->_get_class_meta_for_table_name(data_source => $item->data_source,
                                                                   table_name => $item->table_name);
            $classes_to_check_id_properties{$class_meta->class_name} ||= $class_meta;
        }
    }
    foreach my $class_name ( keys %classes_to_check_id_properties ) {
        my $class_meta = $classes_to_check_id_properties{$class_name};
        my $property_meta = $class_meta->property_meta_for_name('id');
        if ($property_meta && $property_meta->column_name && scalar($class_meta->direct_id_property_metas) > 1) {
            $self->warning_message("Class $class_name cannot have multiple ID properties when one concrete ID property is named 'id'. It will likely not function correctly unless it is renamed");
        }
        unless (defined $property_meta->is_id) {
            $self->warning_message("Class $class_name has a property named 'id' that is not an ID property.  It will likely not function correctly unless it is renamed");
        }
    }
                                         


    $self->status_message("Updating class unique constraints...\n");

    # UNIQUE CONSTRAINT / UNIQUE INDEX -> UNIQUE GROUP (loop table objecs since we have no PK DD objects)
    for my $table (sort $sorter @{ $dd_changes_by_class{'UR::DataSource::RDBMS::Table'} }) {
        # created/updated/unchanged
        # delete and re-create

        my $class = $self->_get_class_meta_for_table_name(data_source => $table->data_source,
                                                          table_name => $table->table_name);
        my $class_name = $class->class_name;

        my @properties = UR::Object::Property->get(class_name => $class_name);

        my @uc_names = $table->unique_constraint_names;
        for my $uc_name (@uc_names)
        {
            eval { $class->remove_unique_constraint($uc_name) };
            if ($@ =~ m/There is no constraint named/) {
                next;  # it's OK if there's no UR metadata for this constraint yet
            } elsif ($@) {
                die $@;
            }

            my @uc_cols = map { ref($_) ? @$_ : $_ } $table->unique_constraint_column_names($uc_name);
            my @uc_property_names;
            for my $uc_col (@uc_cols)
            {
                my ($property) = grep { defined($_->column_name) and ($_->column_name eq $uc_col) } @properties;
                unless ($property) {
                    $self->warning_message("No property found for column $uc_col for unique constraint $uc_name");
                    #$DB::single = 1;
                    next;
                }
                push @uc_property_names, $property->property_name;
            }
            $class->add_unique_constraint($uc_name, @uc_property_names);
        }
    } # next table (checking separately for unique constraints)


    # FK CONSTRAINTS
    #  These often change name, and as such need to be identified by their actual content.
    #  Each constraint must match some relationship in the system, or a new one will be added.

    $self->status_message("Updating class relationships...\n");

    my $last_class_name = '';
    FK:
    for my $fk (sort $sorter @{ $dd_changes_by_class{'UR::DataSource::RDBMS::FkConstraint'} }) {

        my $table = $fk->get_table;
        my $data_source = $fk->data_source;

        my $table_name = $fk->table_name;
        my $r_table_name = $fk->r_table_name;

        my $class = $self->_get_class_meta_for_table_name(data_source => $data_source,
                                                          table_name => $table_name);
        unless ($class) {
            $self->warning_message(
                  sprintf("No class found for table for foreign key constraint %-32s %s" . "\n",$table_name, $fk->id)
               );
               next;
        }

        my $r_class = $self->_get_class_meta_for_table_name(data_source => $data_source,
                                                            table_name => $r_table_name);
        unless ($r_class) {
            $self->warning_message(
                  sprintf("No class found for r_table for foreign key constraint %-32s %-32s" . "\n",$r_table_name, $fk->id)
               );
               next;
        }

        my $class_name = $class->class_name;
        my $r_class_name = $r_class->class_name;

        # Create an object-accessor property to go with this FK
        # First we have to figure out a proper delegation name
        # which is a rather convoluted process

        my @column_names = $fk->column_names;
        my @r_column_names = $fk->r_column_names;
        my (@properties,@property_names,@r_properties,@r_property_names,$prefix,$suffix,$matched);
        foreach my $i ( 0 .. $#column_names ) {
            my $column_name = $column_names[$i];
            my $property = UR::Object::Property->get(
                                  class_name => $class_name,
                                  column_name => $column_name, 
                            );
            unless ($property) {
                Carp::confess("Failed to find a property for column $column_name on class $class_name");
            }
            push @properties,$property;
            my $property_name = $property->property_name;
            push @property_names,$property_name;

            my $r_column_name = $r_column_names[$i];
            my $r_property = UR::Object::Property->get(
                                  class_name => $r_class_name,
                                  column_name => $r_column_name,
                            );
            unless ($r_property) {
                Carp::cluck("Failed to find a property for column $r_column_name on class $r_class_name");
                #$DB::single = 1;
                next FK;
            }
            push @r_properties,$r_property;
            my $r_property_name = $r_property->property_name;
            push @r_property_names,$r_property_name;

            if ($property_name =~ /^(.*)$r_property_name(.*)$/
                or $property_name =~ /^(.*)_id$/) {

                $prefix = $1;
                $prefix =~ s/_$//g if defined $prefix;
                $suffix = $2;
                $suffix =~ s/^_//g if defined $suffix;
                $matched = 1;
            }
        }

        my @r_class_name_parts = split('::', $r_class->class_name);
        shift @r_class_name_parts;  # drop the namespace name
        my $delegation_name = lc(join('_', @r_class_name_parts));

        if ($matched) {
            $delegation_name = $delegation_name . "_" . $prefix if $prefix;
            $delegation_name .= ($suffix !~ /\D/ ? "" : "_") . $suffix if $suffix;
        }
        else {
            $delegation_name = join("_", @property_names) . "_" . $delegation_name;
        }

        # Generate a delegation name that dosen't conflict with another already in use
        my %property_names_used = map { $_ => 1 }
                                        $class->all_property_names;
        while($property_names_used{$delegation_name}) {
            $delegation_name =~ /^(.*?)(\d*)$/;
            $delegation_name = $1 . ( ($2 ? $2 : 0) + 1 );
        }

        # FK columns may have been in an odd order.  Get the reference columns in ID order.
        for my $i (0..$#column_names)
        {
            my $column_name = $column_names[$i];
            my $property = $properties[$i];
            my $property_name = $property_names[$i];

            my $r_column_name = $r_column_names[$i];
            my $r_property = $r_properties[$i];
            my $r_property_name = $r_property_names[$i];
        }

        # Pick a name that isn't already a property in that class
        PICK_A_NAME:
        for ( 1 ) {
            if (UR::Object::Property->get(class_name => $class_name,
                                          property_name => $delegation_name)) {
                if (UR::Object::Property->get(class_name => $class_name,
                                              property_name => $delegation_name.'_obj')) {
                    foreach my $i ( 1 .. 10 ) {
                        unless (UR::Object::Property->get(class_name => $class_name,
                                                          property_name => $delegation_name."_$i")) {
                            $delegation_name .= "_$i";
                            last PICK_A_NAME;
                        }
                    }
                    $self->warning_message("Can't generate a relationship property name for $class_name table name $table_name constraint_name ",$fk->fk_constraint_name);
                    next FK;
                } else {
                    $delegation_name = $delegation_name.'_obj';
                }
            }
        }

        unless ($class->property_meta_for_name($delegation_name)) {
            my $property = UR::Object::Property->create(class_name => $class_name,
                                                        property_name => $delegation_name, 
                                                        data_type => $r_class_name,
                                                        id_by => \@property_names,
                                                        constraint_name => $fk->fk_constraint_name,
                                                        is_delegated => 1,
                                                        is_specified_in_module_header => 1,
                                                       );
            no warnings;
            $self->status_message(
                sprintf("A %-40s property %-16s id by %-16s (%s)\n",
                                                        $class_name,
                                                        $delegation_name,
                                                        join(',',@property_names),
                                                        $r_class_name
                                                      )
            );
}

    } # next fk constraint

    return 1;
}


sub _foreign_key_fingerprint {
my($self,$fk) = @_;

    my $class = $self->_get_class_meta_for_table_name(data_source => $fk->data_source,
                                                      table_name => $fk->table_name);

    return $class->class_name . ':' . join(',',sort $fk->column_names) . ':' . join(',',sort $fk->r_column_names);
}




sub _sync_filesystem {
    my $self = shift;
    my %params = @_;

    my $changed_class_names = delete $params{changed_class_names};
    if (%params) {
        Carp::confess("Invalid params passed to _sync_filesystem: " . join(",", keys %params) . "\n");
    }

    my $obsolete_module_directory = $self->namespace_name->get_deleted_module_directory_name;

    my $namespace = $self->namespace_name;
    my $no_commit = UR::DBI->no_commit;
    $no_commit = 0 if $self->{'_override_no_commit_for_filesystem_items'};

    for my $class_name (@$changed_class_names) {        
        my $status_message_this_update = '';
        my $class_obj;
        my $prev;
        if ($class_obj = UR::Object::Type->get(class_name => $class_name)) {
            if ($class_obj->{is}[0] =~ /::Type$/ and $class_obj->{is}[0]->isa('UR::Object::Type')) {
                next;
            }
            if ($class_obj->{db_committed}) {
                $status_message_this_update .= "U " . $class_obj->module_path;
            }
            else {
                $status_message_this_update .= "A " . $class_obj->module_path;
            }
            $class_obj->rewrite_module_header() unless ($no_commit);
            # FIXME A test of automatically making DBIx::Class modules
            #$class_obj->dbic_rewrite_module_header() unless ($no_commit);

        }
        elsif ($class_obj = UR::Object::Type::Ghost->get(class_name => $class_name)) {
            if ($class_obj->{is}[0] eq 'UR::Object::Type') {
                next;
            }
            
            $status_message_this_update = "D " . $class_obj->module_path;
            
            unless ($no_commit) {
                unless (-d $obsolete_module_directory) {
                    mkdir $obsolete_module_directory;
                    unless (-d $obsolete_module_directory) {
                        $self->error_message("Unable to create $obsolete_module_directory for the deleted module for $class_name.");
                        next;
                    }
                }

                my $f = IO::File->new($class_obj->module_path);
                my $old_file_data = join('',$f->getlines);
                $f->close();

                my $old_module_path = $class_obj->module_path;
                my $new_module_path = $old_module_path;
                $new_module_path =~ s/\/$namespace\//\/$namespace\/\.deleted\//;
                $status_message_this_update .= " (moving $old_module_path to $new_module_path)";
                rename $old_module_path, $new_module_path;

                UR::Context::Transaction->log_change($class_obj, $class_obj->class_name, $class_obj->id, 'rewrite_module_header', Data::Dumper::Dumper({path => $new_module_path, data => $old_file_data}));
            }
        }
        else {
            Carp::confess("Failed to find regular or ghost class meta-object for class $class_name!?");
        }
       
        if ($no_commit) {
            $status_message_this_update .= ' (ignored - no-commit)';
        }
        $self->status_message($status_message_this_update);

    }

    return 1;
}

1;

