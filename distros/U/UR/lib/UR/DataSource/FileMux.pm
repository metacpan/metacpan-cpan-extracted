package UR::DataSource::FileMux;

# NOTE! This module is deprecated.  Use UR::DataSource::Filesystem instead.

use UR;
use strict;
use warnings;
our $VERSION = "0.46"; # UR $VERSION;

class UR::DataSource::FileMux {
    is => ['UR::DataSource'],
    doc => 'A factory for other datasource factories that is able to pivot depending on parameters in the rule used for get()',
    has => [
        delimiter             => { is => 'String', default_value => '\s*,\s*', doc => 'Delimiter between columns on the same line' },
        record_separator      => { is => 'String', default_value => "\n", doc => 'Delimiter between lines in the file' },
        column_order          => { is => 'ARRAY',  doc => 'Names of the columns in the file, in order' },
        cache_size            => { is => 'Integer', default_value => 100 },
        skip_first_line       => { is => 'Integer', default_value => 0 },
        handle_class          => { is => 'String',  default_value => 'IO::File', doc => 'Class to use for new file handles' },
        quick_disconnect      => { is => 'Boolean', default_value => 1, doc => 'Do not hold the file handle open between requests' },
        file_resolver         => { is => 'CODE',   doc => 'subref that will return a pathname given a rule' },
        constant_values       => { is => 'ARRAY',  default_value => undef, doc => 'Property names which are not in the data file(s), but are part of the objects loaded from the data source' },
    ],
    has_optional => [
        server                => { is => 'String', doc => 'pathname to the data file' },
        file_list             => { is => 'ARRAY',  doc => 'list of pathnames of equivalent files' },
        sort_order            => { is => 'ARRAY',  doc => 'Names of the columns by which the data file is sorted' },
        required_for_get      => { is => 'ARRAY',  doc => 'Property names which must appear in any get() request using this data source.  It is used to build the argument list for the file_resolver sub' },
        delegate_file_ds      => { is => 'UR:DataFile::FileMuxFile', reverse_as => 'controlling_filemux', is_many => 1 },
    ],
};

UR::Object::Type->define(
    class_name => 'UR::DataSource::FileMuxFile',
    is => 'UR::DataSource::File',
    has_transient => [
        controlling_filemux => { is => 'UR::DataSource::FileMux', id_by => 'controlling_filemux_id' },
    ],
)->is_uncachable(1);


# FileMux doesn't have a 'default_handle'
sub create_default_handle {
    return undef;
}

sub disconnect {
    my $self = shift;
    my @delegates = $self->delegate_file_ds();
    $_->disconnect_default_handle foreach @delegates;
}

# The concreate data sources will be of this type
sub _delegate_data_source_class {
    'UR::DataSource::FileMuxFile';
}



sub sql_fh {
    return UR::DBI->sql_fh();
}

sub can_savepoint { 0;}  # Doesn't support savepoints

my %WORKING_RULES; # Avoid recusion when infering values from rules
sub create_iterator_closure_for_rule {
    my($self,$rule) = @_;
    
    if ($WORKING_RULES{$rule->id}++) {
        my $subject_class = $rule->subject_class_name;
        $self->error_message("Recursive entry into create_iterator_closure_for_rule() for class $subject_class rule_id ".$rule->id);
        $WORKING_RULES{$rule->id}--;
        return;
    }

    my $context = UR::Context->get_current;
    my $required_for_get = $self->required_for_get;

    if ($ENV{'UR_DBI_MONITOR_SQL'}) {
        $self->sql_fh->printf("FILEMux: Resolving values for %d params (%s)\n",
                              scalar(@$required_for_get),
                              join(',',@$required_for_get));
    }

    my @all_resolver_params;
    for(my $i = 0; $i < @$required_for_get; $i++) {
        my $param_name = $required_for_get->[$i];
        my @values = $context->infer_property_value_from_rule($param_name, $rule);
        unless (@values) {
            # Hack: the above infer...rule()  returned 0 objects, so $all_params_loaded made
            # a note of it.  Later on, if the user supplies more params such that it would be
            # able to resolve a file, we'll never get here, because the Context will see that a
            # superset of the params (this current invocation without sufficient params) was already
            # tried and results should be entirely in the cache - ie. no objects.
            # So... remove the evidence that we tried this in case the user is catching the die
            # below and will continue on
            $context->_forget_loading_was_done_with_template_and_rule($rule->template_id, $rule->id);
            Carp::croak "Can't resolve data source: no $param_name specified in rule $rule";
        }

        if (@values == 1 and ref($values[0]) eq 'ARRAY') {
            @values = @{$values[0]};
        }

        if ($ENV{'UR_DBI_MONITOR_SQL'}) {
            $self->sql_fh->print("    FILEMux: $param_name: (",join(',',@values),")\n");
        }

        unless ($rule->specifies_value_for($param_name)) {
            if (scalar(@values) == 1) {
                $rule = $rule->add_filter($param_name => $values[0]);
            } else {
                $rule = $rule->add_filter($param_name => \@values);
            }
        }
        $all_resolver_params[$i] = \@values;
    }
    my @resolver_param_combinations = UR::Util::combinations_of_values(@all_resolver_params);

    # Each combination of params ends up being from a different data source.  Make an
    # iterator pulling from each of them
    my $file_resolver = $self->{'file_resolver'};
    if (ref($file_resolver) ne 'CODE') {
        # Hack!  The data source is probably a singleton class and there's a file_resolver method
        # defined
        $file_resolver = $self->can('file_resolver');
    } 

    my $concrete_ds_type = $self->_delegate_data_source_class;
    #my %sub_ds_params = $self->_common_params_for_concrete_data_sources();
    my @constant_value_properties = @{$self->constant_values};

    my @data_source_construction_data;
    foreach my $resolver_params ( @resolver_param_combinations ) {
        push @data_source_construction_data, { subject_class_name => $rule->subject_class_name,
                                               file_resolver => $file_resolver,
                                               file_resolver_params => $resolver_params,
                                             };
 
    }
    delete $WORKING_RULES{$rule->id};

    my($monitor_start_time,$monitor_printed_first_fetch);
    if ($ENV{'UR_DBI_MONITOR_SQL'}) {
        $monitor_start_time = Time::HiRes::time();
        $monitor_printed_first_fetch = 0;
    }

    my $base_sub_ds_name = $self->id;

    # Fill in @ds_iterators with iterators for all the underlying data sources
    # pre-fill @ds_next_row with the next object from each data source
    # @ds_constant_values is the constant_values for objects of those data sources
    my(@ds_iterators, @ds_next_row, @ds_constant_values);
    foreach my $data_source_construction_data ( @data_source_construction_data ) {
        my $subject_class_name   = $data_source_construction_data->{'subject_class_name'};
        my $file_resolver        = $data_source_construction_data->{'file_resolver'};
        my $file_resolver_params = $data_source_construction_data->{'file_resolver_params'};

        my @sub_ds_name_parts;
        my $this_ds_rule_params = $rule->legacy_params_hash;
        for (my $i = 0; $i < @$required_for_get; $i++) {
            my $param_name = $required_for_get->[$i];
            my $param_value = $file_resolver_params->[$i];
            push @sub_ds_name_parts, $param_name . $param_value;
            $this_ds_rule_params->{$param_name} = $param_value;
        }
        my $sub_ds_id = join('::', $base_sub_ds_name, @sub_ds_name_parts);

        my $resolved_file = $file_resolver->(@$file_resolver_params);
        unless ($resolved_file) {
            Carp::croak "Can't create data source: file resolver for $sub_ds_id returned false for params "
                        . join(',',@$file_resolver_params);
        }
        my $this_ds_obj  = $self->get_or_create_data_source($concrete_ds_type, $sub_ds_id, $resolved_file);
        my $this_ds_rule = UR::BoolExpr->resolve($subject_class_name,%$this_ds_rule_params);

        my @constant_values = map { $this_ds_rule->value_for($_) }
                                  @constant_value_properties;

        my $ds_iterator = $this_ds_obj->create_iterator_closure_for_rule($this_ds_rule);
        my $initial_obj = $ds_iterator->();
        next unless $initial_obj;

        push @ds_constant_values, \@constant_values;
        push @ds_iterators, $ds_iterator;
        push @ds_next_row, $initial_obj;
    }

    unless (scalar(@ds_constant_values) == scalar(@ds_iterators)
               and
            scalar(@ds_constant_values) == scalar(@ds_next_row) )
    {
        Carp::croak("Internal error in UR::DataSource::FileMux: arrays for iterators, constant_values and next_row have differing sizes");
    }
 

    # Create a closure that can sort the next possible rows in @ds_next_row and return the index of
    # the one that sorts earliest
    my $sorter;
    if (@ds_iterators == 0 ) {
       # No underlying data sources, no data to return
       return sub {};

    } elsif (@ds_iterators == 1 ) {
        # Only one underlying data source.  
        $sorter = sub { 0 };

    } else {
        # more than one underlying data source, make a real sorter

        my %column_name_to_row_index;
        my $column_order_names = $self->column_order;
        my $constant_values = $self->constant_values;
        push @$column_order_names, @$constant_values;
        for (my $i = 0; $i < @$column_order_names; $i++) {
            $column_name_to_row_index{$column_order_names->[$i]} = $i;
        }

        my $sort_order = $self->sort_order;
        if (! $sort_order or ! @$sort_order ) {
            # They didn't specify sorting,  Try finding out the class' ID properties
            # and sort by them

            my $subject_class_meta = $rule->subject_class_name->__meta__;
            my @id_properties = $subject_class_meta->direct_id_property_names;

            $sort_order = [];
            foreach my $property_name ( @id_properties ) {
                my $property_meta = $subject_class_meta->property_meta_for_name($property_name);
                my $column_name = $property_meta->column_name;
                next unless $column_name;
                next unless ($column_name_to_row_index{$column_name});
                push @$sort_order, $column_name;
            }
        }
        my @row_index_sort_order = map { $column_name_to_row_index{$_} } @$sort_order;

        $sorter = sub {
            my $lowest_obj_idx = 0;
            COMPARE_OBJECTS:
            for(my $compare_obj_idx = 1; $compare_obj_idx < @ds_next_row; $compare_obj_idx++) {

                COMPARE_COLUMNS:
                for (my $i = 0; $i < @row_index_sort_order; $i++) {
                    my $column_num = $row_index_sort_order[$i];

                    my $comparison = $ds_next_row[$lowest_obj_idx]->[$column_num] <=> $ds_next_row[$compare_obj_idx]->[$column_num]
                                     ||
                                     $ds_next_row[$lowest_obj_idx]->[$column_num] cmp $ds_next_row[$compare_obj_idx]->[$column_num];

                    if ($comparison == -1) {
                        next COMPARE_OBJECTS;
                    } elsif ($comparison == 1) {
                        $lowest_obj_idx = $compare_obj_idx;
                        next COMPARE_OBJECTS;
                    }
                }
            }

            return $lowest_obj_idx;
        };
    }


    my $iterator = sub {
        if ($monitor_start_time and ! $monitor_printed_first_fetch) {
            $self->sql_fh->printf("FILEMux: FIRST FETCH TIME: %.4f s\n", Time::HiRes::time() - $monitor_start_time);
            $monitor_printed_first_fetch = 1;
        }
        
        while (@ds_next_row) {
            my $next_row_idx = $sorter->();
            my $next_row_to_return = $ds_next_row[$next_row_idx];

            push @$next_row_to_return, @{$ds_constant_values[$next_row_idx]};

            my $refill_row = $ds_iterators[$next_row_idx]->();
            if ($refill_row) {
                $ds_next_row[$next_row_idx] = $refill_row;
            } else {
                # This iterator is exhausted
                splice(@ds_iterators, $next_row_idx, 1);
                splice(@ds_constant_values, $next_row_idx, 1);
                splice(@ds_next_row, $next_row_idx, 1);
            }
            return $next_row_to_return;
        }

        if ($monitor_start_time) {
            $self->sql_fh->printf("FILEMux: TOTAL EXECUTE-FETCH TIME: %.4f s\n",
                                  Time::HiRes::time() - $monitor_start_time);
        }

        return;
    };

    Sub::Name::subname('UR::DataSource::FileMux::__datasource_iterator(closure)__', $iterator);
    return $iterator;
}


sub get_or_create_data_source {
    my($self, $concrete_ds_type, $sub_ds_id, $file_path) = @_;

    my $sub_ds;
    unless ($sub_ds = $concrete_ds_type->get($sub_ds_id)) {
        if ($ENV{'UR_DBI_MONITOR_SQL'}) {
            $self->sql_fh->print("FILEMux: $file_path is data source $sub_ds_id\n");
        }

        my %sub_ds_params = $self->_common_params_for_concrete_data_sources();
        $concrete_ds_type->define(
                      id => $sub_ds_id,
                      %sub_ds_params,
                      server => $file_path,
                      controlling_filemux_id => $self->id,
                  );
        $UR::Context::all_objects_cache_size++;
        $sub_ds = $concrete_ds_type->get($sub_ds_id);
         
        unless ($sub_ds) {
            Carp::croak "Can't create data source: retrieving newly defined data source $sub_ds_id returned nothing";
        }

        # Since these $sub_ds objects have no data_source, this will indicate to
        # UR::Context::prune_object_cache() that it's ok to go ahead and drop them
        $sub_ds->__weaken__();
    }
    return $sub_ds;
}


sub _generate_loading_templates_arrayref {
    my $self = shift;
    my $delegate_class = $self->_delegate_data_source_class();
    $delegate_class->class;  # trigger the autoloader, if necessary

    my $sub = $delegate_class->can('_generate_loading_templates_arrayref');
    unless ($sub) {
        Carp::croak(qq(FileMux can't locate method "_generate_loading_templates_arrayref" via package $delegate_class.  Is $delegate_class a File-type DataSource?));
    }
    $self->$sub(@_);
}


sub _normalize_file_resolver_details {
    my($class, $class_data, $ds_data) = @_;

    my $path_resolver_coderef;
    my @required_for_get;
    my $class_name = $class_data->{'class_name'};

    if (exists $ds_data->{'required_for_get'}) {
        @required_for_get = @{$ds_data->{'required_for_get'}};
        my $user_supplied_resolver = $ds_data->{'file_resolver'} || $ds_data->{'resolve_file_with'} ||
                                     $ds_data->{'resolve_path_with'};
        if (ref($user_supplied_resolver) eq 'CODE') {
            $path_resolver_coderef = $user_supplied_resolver;
        } elsif (! ref($user_supplied_resolver)) {
            # It's a functcion name
            $path_resolver_coderef = $class_name->can($user_supplied_resolver);
            unless ($path_resolver_coderef) {
                die "Can't locate function $user_supplied_resolver via class $class_name during creation of inline data source";
            }
        } else {
            $class->error_message("The data_source specified 'required_for_get', but the file resolver was not a coderef or function name");
            return;
        }
    } else {
        my $resolve_path_with = $ds_data->{'resolve_path_with'} || $ds_data->{'path'} ||
                                $ds_data->{'server'} || $ds_data->{'file_resolver'};
        unless ($resolve_path_with or $ds_data->{'file_list'}) {
           $class->error_message("A data_source's definition must include 'resolve_path_with', 'path', 'server', or 'file_list'");
           return;
        }

        if (! ref($resolve_path_with)) {
            # a simple string
            if ($class_name->can($resolve_path_with) or grep { $_ eq $resolve_path_with } @{$class_data->{'has'}}) {
               # a method or property name
               no strict 'refs';
               $path_resolver_coderef = \&{ $class_name . "::$resolve_path_with"};
            } else {
               # a hardcoded pathname
               $path_resolver_coderef = sub { $resolve_path_with };
            }
        } elsif (ref($resolve_path_with) eq 'CODE') {
            $path_resolver_coderef = $resolve_path_with;

        } elsif (ref($resolve_path_with) ne 'ARRAY') {
            $class->error_message("A data_source's 'resolve_path_with' must be a coderef, arrayref, pathname or method name");
            return;

        } elsif (ref($resolve_path_with) eq 'ARRAY') {
            # A list of things
            if (ref($resolve_path_with->[0]) eq 'CODE') {
                # A coderef, then property list
                @required_for_get = @{$ds_data->{'resolve_path_with'}};
                $path_resolver_coderef = shift @required_for_get;

            } elsif (grep { $_ eq $resolve_path_with->[0] }
                          keys(%{$class_data->{'has'}})      ) {
                # a list of property names, join them with /s
                unless ($ds_data->{'base_path'}) {
                    $class->warning_message("$class_name inline data source: 'resolve_path_with' is a list of method names, but 'base_path' is undefined'");
                }
                @required_for_get = @{$resolve_path_with};
                my $base_path = $ds_data->{'base_path'};
                $path_resolver_coderef = sub { no warnings 'uninitialized';
                                              return join('/', $base_path, @_)
                                            };
 
            } elsif ($class_name->can($resolve_path_with->[0])) {
                # a method compiled into the class, but not one that's a property
                @required_for_get = @{$resolve_path_with};
                my $fcn_name = shift @required_for_get;
                my $path_resolver_coderef = $class_name->can($fcn_name);
                unless ($path_resolver_coderef) {
                    die "Can't locate function $fcn_name via class $class_name during creation of inline data source";
                }

            } elsif (! ref($resolve_path_with->[0])) {
                # treat the first element as a sprintf format
                @required_for_get = @{$resolve_path_with};
                my $format = shift @required_for_get;
                $path_resolver_coderef = sub { no warnings 'uninitialized';
                                               return sprintf($format, @_);
                                             };
            } else {
                $class->error_message("Unrecognized layout for 'resolve_path_with'");
                return;
            }
        } else {
            $class->error_message("Unrecognized layout for 'resolve_path_with'");
            return;
        }
    }

    return ($path_resolver_coderef, @required_for_get);
}


# Properties we'll copy from $self when creating a concrete data source
sub _common_params_for_concrete_data_sources {
    my $self = shift;

    my %params;
    foreach my $param ( qw( delimiter skip_first_line column_order sort_order record_separator constant_values handle_class quick_disconnect ) ) {
        next unless defined $self->$param;
        my @vals = $self->$param;
        if (@vals > 1) {
            $params{$param} = \@vals;
        } else {
            $params{$param} = $vals[0];
        }
    }
    return %params;
}
        

sub initializer_should_create_column_name_for_class_properties {
    1;
}
    
# Called by the class initializer 
sub create_from_inline_class_data {
    my($class, $class_data, $ds_data) = @_;

    unless ($ds_data->{'column_order'}) {
        die "Can't create inline data source for ".$class_data->{'class_name'}.": 'column_order' is a required param";
    }


    my($file_resolver, @required_for_get) = $class->_normalize_file_resolver_details($class_data, $ds_data);
    return unless $file_resolver;

    if (!exists($ds_data->{'constant_values'}) and @required_for_get) {
        # If there are required_for_get params, but the user didn't specify any constant_values,
        # then all the required_for_get items that are real properties become constant_values
        $ds_data->{'constant_values'} = [];
        my %columns_from_ds = map { $_ => 1 } @{$ds_data->{'column_order'}};

        foreach my $param_name ( @required_for_get ) {
            my $param_data = $class_data->{'has'}->{$param_name};
            next unless $param_data;

            my $param_column = $param_data->{'column_name'};
            next unless $param_column;

            unless ($columns_from_ds{$param_column}) {
                push @{$ds_data->{'constant_values'}}, $param_name;
            }
        }
    }


    my %ds_creation_params;
    foreach my $param ( qw( delimiter record_separator column_order cache_size skip_first_line sort_order constant_values ) ) {
        if (exists $ds_data->{$param}) {
            $ds_creation_params{$param} = $ds_data->{$param};
        }
    }

    my($namespace, $class_name) = ($class_data->{'class_name'} =~ m/^(\w+?)::(.*)/);
    my $ds_id = "${namespace}::DataSource::${class_name}";
    my $ds_type = delete $ds_data->{'is'};
 
    my $ds = $ds_type->create(
        %ds_creation_params,
        id => $ds_id,
        required_for_get => \@required_for_get,
        file_resolver => $file_resolver
    );

    return $ds;
}


sub _sync_database {
    my $self = shift;
    my %params = @_;

    unless (ref($self)) {
        if ($self->isa("UR::Singleton")) {
            $self = $self->_singleton_object;
        }
        else {
            die "Called as a class-method on a non-singleton datasource!";
        }
    }

    my $changed_objects = delete $params{'changed_objects'};

    my $context = UR::Context->get_current;
    my $required_for_get = $self->required_for_get;

    my $file_resolver = $self->{'file_resolver'};
    if (ref($file_resolver) ne 'CODE') {
        # Hack!  The data source is probably a singleton class and there's a file_resolver method
        # defined
        $file_resolver = $self->can('file_resolver');
    }

    my $monitor_start_time;
    if ($ENV{'UR_DBI_MONITOR_SQL'}) {
        $monitor_start_time = Time::HiRes::time();
        my $time = time();
        $self->sql_fh->printf("FILEMux: SYNC_DATABASE AT %d [%s].\n", $time, scalar(localtime($time)));
    }

    my $concrete_ds_type = $self->_delegate_data_source_class;
    my %sub_ds_params = $self->_common_params_for_concrete_data_sources();

    my %datasource_for_dsid;
    my %objects_by_datasource;
    foreach my $obj ( @$changed_objects ) {
        my @obj_values;
        for (my $i = 0; $i < @$required_for_get; $i++) {
        
            my $property = $required_for_get->[$i];
            my $value = $obj->$property;
            unless ($value) {
                my $class = $obj->class;
                my $id = $obj->id;
                $self->error_message("No value for required-for-get property $property on object of class $class id $id");
                return;
            }
            if (ref $value) {
                my $class = $obj->class;
                my $id = $obj->id;
                $self->error_message("Pivoting based on a non-scalar property is not supported.  $class object id $id property $property did not return a scalar value");
                return;
            }

            push @obj_values, $value;
        }

        my @sub_ds_name_parts;
        for (my $i = 0; $i < @obj_values; $i++) {
            push @sub_ds_name_parts, $required_for_get->[$i] . $obj_values[$i];
        }
        my $sub_ds_id = join('::', $self->id, @sub_ds_name_parts);

        my $sub_ds = $datasource_for_dsid{$sub_ds_id} || $concrete_ds_type->get($sub_ds_id);
        unless ($sub_ds) {
            my $file_path = $file_resolver->(@obj_values);
            unless (defined $file_path) {
                die "Can't resolve data source: resolver for " .
                    $self->class .
                    " returned undef for params " . join(',',@obj_values);
            }

            if ($ENV{'UR_DBI_MONITOR_SQL'}) {
                $self->sql_fh->print("FILEMux: $file_path is data source $sub_ds_id\n");
            }

            $concrete_ds_type->define(
                          id => $sub_ds_id,
                          %sub_ds_params,
                          server => $file_path,
                          controlling_filemux_id => $self->id,
                      );
            $UR::Context::all_objects_cache_size++;
            $sub_ds = $concrete_ds_type->get($sub_ds_id);

            # Since these $sub_ds objects have no data_source, this will indicate to
            # UR::Context::prune_object_cache() that it's ok to go ahead and drop them
            $sub_ds->__weaken__();
        }
        unless ($sub_ds) {
            die "Can't get data source with ID $sub_ds_id";
        }
        $datasource_for_dsid{$sub_ds_id} ||= $sub_ds;


        unless ($objects_by_datasource{$sub_ds_id}) {
            $objects_by_datasource{$sub_ds_id}->{'ds_obj'} = $sub_ds;
            $objects_by_datasource{$sub_ds_id}->{'changed_objects'} = [];
        }
        push(@{$objects_by_datasource{$sub_ds_id}->{'changed_objects'}}, $obj);
    }

    foreach my $h ( values %objects_by_datasource ) {
        my $sub_ds = $h->{'ds_obj'};
        my $changed_objects = $h->{'changed_objects'};

        $sub_ds->_sync_database(changed_objects => $changed_objects);
    }

    if ($ENV{'UR_DBI_MONITOR_SQL'}) {
        $self->sql_fh->printf("FILEMux: TOTAL COMMIT TIME: %.4f s\n", Time::HiRes::time() - $monitor_start_time);
    }

    return 1;
}


            

1;

=pod

=head1 NAME

UR::DataSource::FileMux - Parent class for datasources which can multiplex many files together

=head1 DEPRECATED

This module is deprecated.  Use UR::DataSource::Filesystem instead.

=head1 SYNOPSIS

  package MyNamespace::DataSource::MyFileMux;
  class MyNamespace::DataSource::MyFileMux {
      is => ['UR::DataSource::FileMux', 'UR::Singleton'],
  };
  sub column_order { ['thing_id', 'thing_name', 'thing_color'] }
  sub sort_order { ['thing_id'] }
  sub delimiter { "\t" }
  sub constant_values { ['thing_type'] }
  sub required_for_get { ['thing_type'] }
  sub file_resolver {
      my $thing_type = shift;
      return '/base/path/to/files/' . $thing_type;
  }

  package main;
  class MyNamespace::ThingMux {
      id_by => ['thing_id', 'thing_type' ],
      has => ['thing_id', 'thing_type', 'thing_name','thing_color'],
      data_source => 'MyNamespace::DataSource::MyFileMux',
  };

  my @objs = MyNamespace::Thing->get(thing_type => 'people', thing_name => 'Bob');

=head1 DESCRIPTION

UR::DataSource::FileMux provides a framework for file-based data sources where the
data files are split up between one or more parameters of the class.  For example,
in the synopsis above, the data for the class is stored in several files in the
directory /base/path/to/files/.  Each file may have a name such as 'people' and 'cars'.

When a get() request is made on the class, the parameter 'thing_type' must be present
in the rule, and the value of that parameter is used to complete the file's pathname,
via the file_resolver() function.  Note that even though the 'thing_type' parameter
is not actually stored in the file, its value for the loaded objects gets filled in
because that parameter exists in the constant_values() configuration list, and in
the get() request.

=head2 Configuration

These methods determine the configuration for your data source and should appear as
properties of the data source or as functions in the package.

=over 4

=item delimiter()

=item record_separator()

=item skip_first_line()

=item column_order()

=item sort_order()

These configuration items behave the same as in a UR::DataSource::File-based data source.

=item required_for_get()

required_for_get() should return a listref of parameter names.  Whenever a get() request is
made on the class, the listed parameters must appear in the rule, or be derivable via
UR::Context::infer_property_value_from_rule().  

=item file_resolver()

file_resolver() is called as a function (not a method).  It should accept the same number
of parameters as are mentioned in required_for_get().  When a get() request is made,
those named parameters are extracted from the rule and passed in to the file_resolver()
function in the same order.  file_resolver() must return a string that is used as the
pathname to the file that contains the needed data.  The function must not have any
other side effects.

In the case where the data source is a regular object (not a UR::Singleton'), then 
the file_resover parameter should return a coderef.

=item constant_values()

constant_values() should return a listref of parameter names.  These parameter names are used by
the object loader system to fill in data that may not be present in the data files.  If the
class has parameters that are not actually stored in the data files, then the parameter
values are extracted from the rule and stored in the loaded object instances before being
returned to the user.  

In the synopsis above, thing_type is not stored in the data files, even though it exists
as a parameter of the MyNamespace::ThingMux class.

=back

=head2 Theory of Operation

As part of the data-loading infrastructure inside UR, the parameters in a get() 
request are transformed into a UR::BoolExpr instance, also called a rule.  
UR::DataSource::FilMux hooks into that infrastructure by implementing
create_iterator_closure_for_rule().  It first collects the values for all the
parameters mentioned in required_for_get() by passing the rule and needed
parameter to infer_property_value_from_rule() of the current Context.  If any
of the needed parameters is not resolvable, an excpetion is raised.

Some of the rule's parameters may have multiple values.  In those cases, all the 
combinations of values are expanded.  For example of param_a has 2 values, and
param_b has 3 values, then there are 6 possible combinations.

For each combination of values, the file_resolver() function is called and 
returns a pathname.  For each pathname, a file-specific data source is created
(if it does not already exist), the server() configuration parameter created
to return that pathname.  Other parameters are copied from the values in the
FileMux data source, such as column_names and delimiter.
create_iterator_closure_for_rule() is called on each of those data sources.

Finally, an iterator is created to wrap all of those iterators, and is returned.
  
=head1 INHERITANCE

UR::DataSource

=head1 SEE ALSO

UR, UR::DataSource, UR::DataSource::File

=cut

