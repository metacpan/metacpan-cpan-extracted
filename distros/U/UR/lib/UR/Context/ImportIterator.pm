package UR::Context;

# Methods related to the import iterator (part of the loading process).
#
# They are broken out here for readability purposes.  The methods still live
# in the UR::Context namespace.

use strict;
use warnings;

our $VERSION = "0.47"; # UR $VERSION;


# A wrapper around the method of the same name in UR::DataSource::* to iterate over the
# possible data sources involved in a query.  The easy case (a query against a single data source)
# will return the $primary_template data structure.  If the query involves more than one data source,
# then this method also returns a list containing triples (@addl_loading_info) where each member is:
# 1) The secondary data source name
# 2) a listref of delegated properties joining the primary class to the secondary class
# 3) a rule template applicable against the secondary data source
sub _resolve_query_plan_for_ds_and_bxt {
    my($self,$primary_data_source,$rule_template) = @_;

    my $primary_query_plan = $primary_data_source->_resolve_query_plan($rule_template);

    unless ($primary_query_plan->{'joins_across_data_sources'}) {
        # Common, easy case
        return $primary_query_plan;
    }

    my @addl_loading_info;
    foreach my $secondary_data_source_id ( keys %{$primary_query_plan->{'joins_across_data_sources'}} ) {
        my $this_ds_delegations = $primary_query_plan->{'joins_across_data_sources'}->{$secondary_data_source_id};

        my %seen_properties;
        foreach my $delegated_property ( @$this_ds_delegations ) {
            my $delegated_property_name = $delegated_property->property_name;
            next if ($seen_properties{$delegated_property_name}++);

            my $operator = $rule_template->operator_for($delegated_property_name);
            $operator ||= '=';  # FIXME - shouldn't the template return this for us?
            my @secondary_params = ($delegated_property->to . ' ' . $operator);

            my $class_meta = UR::Object::Type->get($delegated_property->class_name);
            my $relation_property = $class_meta->property_meta_for_name($delegated_property->via);

            my $secondary_class = $relation_property->data_type;

            # we can also add in any properties in the property's joins that also appear in the rule
            my @property_pairs = $relation_property->get_property_name_pairs_for_join();
            foreach my $pair ( @property_pairs ) {
                my($primary_property, $secondary_property) = @$pair;
                next if ($seen_properties{$primary_property}++);
                next unless ($rule_template->specifies_value_for($primary_property));

                my $operator = $rule_template->operator_for($primary_property);
                $operator ||= '=';
                push @secondary_params, "$secondary_property $operator";
             }

            my $secondary_rule_template = UR::BoolExpr::Template->resolve($secondary_class, @secondary_params);

            # FIXME there should be a way to collect all the requests for the same datasource together...
            # FIXME - currently in the process of switching to object-based instead of class-based data sources
            # For now, data sources are still singleton objects, so this get() will work.  When we're fully on
            # regular-object-based data sources, then it'll probably change to UR::DataSource->get($secondary_data_source_id); 
            my $secondary_data_source = UR::DataSource->get($secondary_data_source_id) || $secondary_data_source_id->get();
            push @addl_loading_info,
                     $secondary_data_source,
                     [$delegated_property],
                     $secondary_rule_template;
        }
    }

    return ($primary_query_plan, @addl_loading_info);
}


# Used by _create_secondary_loading_comparators to convert a rule against the primary data source
# to a rule that can be used against a secondary data source
# FIXME this might be made simpler be leaning on infer_property_value_from_rule()?
sub _create_secondary_rule_from_primary {
    my($self,$primary_rule, $delegated_properties, $secondary_rule_template) = @_;

    my @secondary_values;
    my %seen_properties;  # FIXME - we've already been over this list in _resolve_query_plan_for_ds_and_bxt()...
    # FIXME - is there ever a case where @$delegated_properties will be more than one item?
    foreach my $property ( @$delegated_properties ) {
        my $value = $primary_rule->value_for($property->property_name);

        my $secondary_property_name = $property->to;
        my $pos = $secondary_rule_template->value_position_for_property_name($secondary_property_name);
        $secondary_values[$pos] = $value;
        $seen_properties{$property->property_name}++;

        my $class_meta = $property->class_meta;
        my $via_property = $class_meta->property_meta_for_name($property->via);
        my @pairs = $via_property->get_property_name_pairs_for_join();
        foreach my $pair ( @pairs ) {
            my($primary_property_name, $secondary_property_name) = @$pair;

            next if ($seen_properties{$primary_property_name}++);
            $value = $primary_rule->value_for($primary_property_name);
            next unless $value;

            $pos = $secondary_rule_template->value_position_for_property_name($secondary_property_name);
            $secondary_values[$pos] = $value;
        }
    }

    my $secondary_rule = $secondary_rule_template->get_rule_for_values(@secondary_values);

    return $secondary_rule;
}


# Since we'll be appending more "columns" of data to the listrefs returned by
# the primary datasource's query, we need to apply fixups to the column positions
# to all the secondary loading templates
# The column_position and object_num offsets needed for the next call of this method
# are returned
sub _fixup_secondary_loading_template_column_positions {
    my($self,$primary_loading_templates, $secondary_loading_templates, $column_position_offset, $object_num_offset) = @_;

    if (! defined($column_position_offset) or ! defined($object_num_offset)) {
        $column_position_offset = 0;
        foreach my $tmpl ( @{$primary_loading_templates} ) {
            $column_position_offset += scalar(@{$tmpl->{'column_positions'}});
        }
        $object_num_offset = scalar(@{$primary_loading_templates});
    }

    my $this_template_column_count;
    foreach my $tmpl ( @$secondary_loading_templates ) {
        foreach ( @{$tmpl->{'column_positions'}} ) {
            $_ += $column_position_offset;
        }
        foreach ( @{$tmpl->{'id_column_positions'}} ) {
            $_ += $column_position_offset;
        }
        $tmpl->{'object_num'} += $object_num_offset;

        $this_template_column_count += scalar(@{$tmpl->{'column_positions'}});
    }


    return ($column_position_offset + $this_template_column_count,
            $object_num_offset + scalar(@$secondary_loading_templates) );
}

# For queries that have to hit multiple data sources, this method creates two lists of
# closures.  The first is a list of object fabricators, where the loading templates
# have been given fixups to the column positions (see _fixup_secondary_loading_template_column_positions())
# The second is a list of closures for each data source (the @addl_loading_info stuff
# from _resolve_query_plan_for_ds_and_bxt) that's able to compare the row loaded from the
# primary data source and see if it joins to a row from this secondary datasource's database
sub _create_secondary_loading_closures {
    my($self, $primary_template, $rule, @addl_loading_info) = @_;

    my $loading_templates = $primary_template->{'loading_templates'};

    # Make a mapping of property name to column positions returned by the primary query
    my %primary_query_column_positions;
    foreach my $tmpl ( @$loading_templates ) {
        my $property_name_count = scalar(@{$tmpl->{'property_names'}});
        for (my $i = 0; $i < $property_name_count; $i++) {
            my $property_name = $tmpl->{'property_names'}->[$i];
            my $pos = $tmpl->{'column_positions'}->[$i];
            $primary_query_column_positions{$property_name} = $pos;
        }
    }

    my @secondary_object_importers;
    my @addl_join_comparators;

    # used to shift the apparent column position of the secondary loading template info
    my ($column_position_offset,$object_num_offset);

    while (@addl_loading_info) {
        my $secondary_data_source = shift @addl_loading_info;
        my $this_ds_delegations = shift @addl_loading_info;
        my $secondary_rule_template = shift @addl_loading_info;

        my $secondary_rule = $self->_create_secondary_rule_from_primary (
                                              $rule,
                                              $this_ds_delegations,
                                              $secondary_rule_template,
                                       );
        $secondary_data_source = $secondary_data_source->resolve_data_sources_for_rule($secondary_rule);
        my $secondary_template = $self->_resolve_query_plan_for_ds_and_bxt($secondary_data_source,$secondary_rule_template);

        # sets of triples where the first in the triple is the column index in the
        # $secondary_db_row (in the join_comparator closure below), the second is the
        # index in the $next_db_row.  And the last is a flag indicating if we should 
        # perform a numeric comparison.  This way we can preserve the order the comparisons
        # should be done in
        my @join_comparison_info;
        foreach my $property ( @$this_ds_delegations ) {
            # first, map column names in the joined class to column names in the primary class
            my %foreign_property_name_map;
            my @this_property_joins = $property->_resolve_join_chain();
            foreach my $join ( @this_property_joins ) {
                last if ($join->{foreign_class}->isa('UR::Value') and $join eq $this_property_joins[-1]);
                my @source_names = @{$join->{'source_property_names'}};
                my @foreign_names = @{$join->{'foreign_property_names'}};
                @foreign_property_name_map{@foreign_names} = @source_names;
            }

            # Now, find out which numbered column in the result query maps to those names
            my $secondary_loading_templates = $secondary_template->{'loading_templates'};
            foreach my $tmpl ( @$secondary_loading_templates ) {
                my $property_name_count = scalar(@{$tmpl->{'property_names'}});
                for (my $i = 0; $i < $property_name_count; $i++) {
                    my $property_name = $tmpl->{'property_names'}->[$i];
                    if ($foreign_property_name_map{$property_name}) {
                        # This is the one we're interested in...  Where does it come from in the primary query?
                        my $column_position = $tmpl->{'column_positions'}->[$i];
                        # What are the types involved?
                        my $primary_query_column_name = $foreign_property_name_map{$property_name};
                        my $primary_property_class_meta = $primary_template->{'class_name'}->__meta__;
                        my $primary_property_meta = $primary_property_class_meta->property_meta_for_name($primary_query_column_name);
                        unless ($primary_property_meta) {
                            Carp::croak("Can't resolve property metadata for property '$primary_query_column_name' of class ".$primary_template->{'class_name'});
                        }

                        my $secondary_class_meta = $secondary_template->{'class_name'}->__meta__;
                        my $secondary_property_meta = $secondary_class_meta->property_meta_for_name($property_name);
                        unless ($secondary_property_meta) {
                            Carp::croak("Can't resolve property metadata for property '$property_name' of class ".$secondary_template->{'class_name'});
                        }

                        my $comparison_type;
                        if ($primary_property_meta->is_numeric && $secondary_property_meta->is_numeric) {
                            $comparison_type = 1;
                        }

                        my $comparison_position;
                        if (exists $primary_query_column_positions{$primary_query_column_name} ) {
                            $comparison_position = $primary_query_column_positions{$primary_query_column_name};

                        } else {
                            # This isn't a real column we can get from the data source.  Maybe it's
                            # in the constant_property_names of the primary_loading_template?
                            unless (grep { $_ eq $primary_query_column_name}
                                    @{$loading_templates->[0]->{'constant_property_names'}}) {
                                die sprintf("Can't resolve datasource comparison to join %s::%s to %s:%s",
                                            $primary_template->{'class_name'}, $primary_query_column_name,
                                            $secondary_template->{'class_name'}, $property_name);
                            }
                            my $comparison_value = $rule->value_for($primary_query_column_name);
                            unless (defined $comparison_value) {
                                $comparison_value = $self->infer_property_value_from_rule($primary_query_column_name, $rule);
                            }
                            $comparison_position = \$comparison_value;
                        }
                        push @join_comparison_info, $column_position,
                                                    $comparison_position,
                                                    $comparison_type;


                    }
                }
            }
        }
        my $secondary_db_iterator = $secondary_data_source->create_iterator_closure_for_rule($secondary_rule);

        my $secondary_db_row;
        # For this closure, pass in the row we just loaded from the primary DB query.
        # This one will return the data from this secondary DB's row if the passed-in
        # row successfully joins to this secondary db iterator.  It returns an empty list
        # if there were no matches, and returns false if there is no more data from the query
        my $join_comparator = sub {
            my $next_db_row = shift;  # From the primary DB
            READ_DB_ROW:
            while(1) {
                return unless ($secondary_db_iterator);
                unless ($secondary_db_row) {
                    ($secondary_db_row) = $secondary_db_iterator->();
                    unless($secondary_db_row) {
                        # No more data to load 
                        $secondary_db_iterator = undef;
                        return;
                    }
                }

                for (my $i = 0; $i < @join_comparison_info; $i += 3) {
                    my $secondary_column = $join_comparison_info[$i];
                    my $primary_column = $join_comparison_info[$i+1];
                    my $is_numeric = $join_comparison_info[$i+2];

                    my $comparison;
                    if (ref $primary_column) {
                        # This was one of those constant value items
                        if ($is_numeric) {
                            $comparison = $secondary_db_row->[$secondary_column] <=> $$primary_column;
                        } else {
                            $comparison = $secondary_db_row->[$secondary_column] cmp $$primary_column;
                        }
                    } else {
                        if ($join_comparison_info[$i+2]) {
                            $comparison = $secondary_db_row->[$secondary_column] <=> $next_db_row->[$primary_column];
                        } else {
                            $comparison = $secondary_db_row->[$secondary_column] cmp $next_db_row->[$primary_column];
                        }
                    }
                    if ($comparison < 0) {
                        # less than, get the next row from the secondary DB
                        $secondary_db_row = undef;
                        redo READ_DB_ROW;
                    } elsif ($comparison == 0) {
                        # This one was the same, keep looking at the others
                    } else {
                        # greater-than, there's no match for this primary DB row
                        return 0;
                    }
                }
                # All the joined columns compared equal, return the data
                return $secondary_db_row;
            }
        };
        Sub::Name::subname('UR::Context::__join_comparator(closure)__', $join_comparator);
        push @addl_join_comparators, $join_comparator;


        # And for the object importer/fabricator, here's where we need to shift the column order numbers
        # over, because these closures will be called after all the db iterators' rows are concatenated
        # together.  We also need to make a copy of the loading_templates list so as to not mess up the
        # class' notion of where the columns are
        # FIXME - it seems wasteful that we need to re-created this each time.  Look into some way of using 
        # the original copy that lives in $primary_template->{'loading_templates'}?  Somewhere else?
        my @secondary_loading_templates;
        foreach my $tmpl ( @{$secondary_template->{'loading_templates'}} ) {
            my %copy;
            foreach my $key ( keys %$tmpl ) {
                my $value_to_copy = $tmpl->{$key};
                if (ref($value_to_copy) eq 'ARRAY') {
                    $copy{$key} = [ @$value_to_copy ];
                } elsif (ref($value_to_copy) eq 'HASH') {
                    $copy{$key} = { %$value_to_copy };
                } else {
                    $copy{$key} = $value_to_copy;
                }
            }
            push @secondary_loading_templates, \%copy;
        }
        ($column_position_offset,$object_num_offset) =
                $self->_fixup_secondary_loading_template_column_positions($primary_template->{'loading_templates'},
                                                                          \@secondary_loading_templates,
                                                                          $column_position_offset,$object_num_offset);

        #my($secondary_rule_template,@secondary_values) = $secondary_rule->get_template_and_values();
        my @secondary_values = $secondary_rule->values();
        foreach my $secondary_loading_template ( @secondary_loading_templates ) {
            my $secondary_object_importer = UR::Context::ObjectFabricator->create_for_loading_template(
                                                       $self,
                                                       $secondary_loading_template,
                                                       $secondary_template,
                                                       $secondary_rule,
                                                       $secondary_rule_template,
                                                       \@secondary_values,
                                                       $secondary_data_source
                                                );
            next unless $secondary_object_importer;
            push @secondary_object_importers, $secondary_object_importer;
        }


   }

    return (\@secondary_object_importers, \@addl_join_comparators);
}


# This returns an iterator that is used to bring objects in from an underlying
# context into this context.
sub _create_import_iterator_for_underlying_context {
    my ($self, $rule, $dsx, $this_get_serial) = @_;

    # TODO: instead of taking a data source, resolve this internally.
    # The underlying context itself should be responsible for its data sources.

    # Make an iterator for the primary data source.
    # Primary here meaning the one for the class we're explicitly requesting.
    # We may need to join to other data sources to complete the query.
    my ($db_iterator)
        = $dsx->create_iterator_closure_for_rule($rule);

    my ($rule_template, @values) = $rule->template_and_values();
    my ($query_plan,@addl_loading_info) = $self->_resolve_query_plan_for_ds_and_bxt($dsx,$rule_template);
    my $class_name = $query_plan->{class_name};

    my $group_by    = $rule_template->group_by;
    my $order_by    = $rule_template->order_by;
    my $aggregate   = $rule_template->aggregate;

    if (my $sub_typing_property) {
        # When the rule has a property specified which indicates a specific sub-type, catch this and re-call
        # this method recursively with the specific subclass name.
        my ($rule_template, @values) = $rule->template_and_values();
        my $rule_template_specifies_value_for_subtype   = $query_plan->{rule_template_specifies_value_for_subtype};
        my $class_table_name                            = $query_plan->{class_table_name};

        warn "Implement me carefully";

        if ($rule_template_specifies_value_for_subtype) {
            my $sub_classification_meta_class_name          = $query_plan->{sub_classification_meta_class_name};
            my $value = $rule->value_for($sub_typing_property);
            my $type_obj = $sub_classification_meta_class_name->get($value);
            if ($type_obj) {
                my $subclass_name = $type_obj->subclass_name($class_name);
                if ($subclass_name and $subclass_name ne $class_name) {
                    #$rule = $subclass_name->define_boolexpr($rule->params_list, $sub_typing_property => $value);
                    $rule = UR::BoolExpr->resolve_normalized($subclass_name, $rule->params_list, $sub_typing_property => $value);
                    return $self->_create_import_iterator_for_underlying_context($rule,$dsx,$this_get_serial);
                }
            }
            else {
                die "No $value for $class_name?\n";
            }
        }
        elsif (not $class_table_name) {
            die "No longer supported!";
            my $rule = UR::BoolExpr->resolve(
                           $class_name,
                           $rule_template->get_rule_for_values(@values)->params_list,
                        );
            return $self->_create_import_iterator_for_underlying_context($rule,$dsx,$this_get_serial)
        }
        else {
            # continue normally
            # the logic below will handle sub-classifying each returned entity
        }
    }


    my $loading_templates                           = $query_plan->{loading_templates};
    my $sub_typing_property                         = $query_plan->{sub_typing_property};
    my $next_db_row;
    my $rows = 0;                                   # number of rows the query returned

    my $recursion_desc                              = $query_plan->{recursion_desc};
    my($rule_template_without_recursion_desc, $rule_template_id_without_recursion);
    my($rule_without_recursion_desc, $rule_id_without_recursion);
    # These get set if you're doing a -recurse query, and the underlying data source doesn't support recursion
    my($by_hand_recursive_rule_template,$by_hand_recursive_source_property,@by_hand_recursive_source_values,$by_hand_recursing_iterator);
    if ($recursion_desc) {
        $rule_template_without_recursion_desc        = $query_plan->{rule_template_without_recursion_desc};
        $rule_template_id_without_recursion          = $rule_template_without_recursion_desc->id;
        $rule_without_recursion_desc                 = $rule_template_without_recursion_desc->get_rule_for_values(@values);
        $rule_id_without_recursion                   = $rule_without_recursion_desc->id;

        if ($query_plan->{'recurse_resolution_by_iteration'}) {
            # The data source does not support a recursive query.  Accomplish the same thing by
            # recursing back into _create_import_iterator_for_underlying_context for each level
            my $this;
            ($this,$by_hand_recursive_source_property) = @$recursion_desc;

            my @extra;
            $by_hand_recursive_rule_template = UR::BoolExpr::Template->resolve($class_name, "$this in");
            $by_hand_recursive_rule_template->recursion_desc($recursion_desc);
            if (!$by_hand_recursive_rule_template or @extra) {
                Carp::croak("Can't resolve recursive query: Class $class_name cannot filter by one or more properties: "
                            . join(', ', @extra));
            }
        }
    }

    my $rule_id = $rule->id;
    my $rule_template_id = $rule_template->id;

    my $needs_further_boolexpr_evaluation_after_loading = $query_plan->{'needs_further_boolexpr_evaluation_after_loading'};

    my %subordinate_iterator_for_class;

    # TODO: move the creation of the fabricators into the query plan object initializer.
    # instead of making just one import iterator, we make one per loading template
    # we then have our primary iterator use these to fabricate objects for each db row
    my @object_fabricators;
    if ($group_by) {
        # returning sets for each sub-group instead of instance objects...
        my $division_point = scalar(@$group_by)-1;
        my $subset_template = $rule_template->_template_for_grouped_subsets();
        my $set_class = $class_name . '::Set';
        my @aggregate_properties = ($aggregate ? @$aggregate : ());
        unshift(@aggregate_properties, 'count') unless (grep { $_ eq 'count' } @aggregate_properties);

        my $fab_subref = sub {
            my $row = $_[0];
            my @group_values = @$row[0..$division_point];
            my $ss_rule = $subset_template->get_rule_for_values(@values, @group_values);
            my $set = $set_class->get($ss_rule->id);
            unless ($set) {
                Carp::croak("Failed to fabricate $set_class for rule $ss_rule");
            }
            my $aggregates = $set->{__aggregates} ||= {};
            @$aggregates{@aggregate_properties} = @$row[$division_point+1..$#$row];
            return $set;
        };

        my $object_fabricator = UR::Context::ObjectFabricator->_create(
                                    fabricator => $fab_subref,
                                    context    => $self,
                                );
        unshift @object_fabricators, $object_fabricator;
    }
    else {
        # regular instances
        for my $loading_template (@$loading_templates) {
            my $object_fabricator =
                UR::Context::ObjectFabricator->create_for_loading_template(
                    $self,
                    $loading_template,
                    $query_plan,
                    $rule,
                    $rule_template,
                    \@values,
                    $dsx,
                );
            next unless $object_fabricator;
            unshift @object_fabricators, $object_fabricator;
        }
    }

    # For joins across data sources, we need to create importers/fabricators for those
    # classes, as well as callbacks used to perform the equivalent of an SQL join in
    # UR-space
    my @addl_join_comparators;
    if (@addl_loading_info) {
        if ($group_by) {
            Carp::croak("cross-datasource group-by is not supported yet");
        }
        my($addl_object_fabricators, $addl_join_comparators) =
                $self->_create_secondary_loading_closures( $query_plan,
                                                           $rule,
                                                           @addl_loading_info
                                                      );

        unshift @object_fabricators, @$addl_object_fabricators;
        push @addl_join_comparators, @$addl_join_comparators;
    }

    # To avoid calling the useless method 'fabricate' on a fabricator object for each object of each resultset row
    my @object_fabricator_closures = map { $_->fabricator } @object_fabricators;

    # Insert the key into all_objects_are_loaded to indicate that when we're done loading, we'll
    # have everything
    if ($query_plan->{'rule_matches_all'} and not $group_by) {
        $class_name->all_objects_are_loaded(undef);
    }

    #my $is_monitor_query = $self->monitor_query();

    # Make the iterator we'll return.
    my $next_object_to_return;
    my @object_ids_from_fabricators;
    my $underlying_context_iterator = sub {
        return undef unless $db_iterator;

        my $primary_object_for_next_db_row;

        LOAD_AN_OBJECT:
        until (defined $primary_object_for_next_db_row) { # note that we return directly when the db is out of data

            my ($next_db_row);
            ($next_db_row) = $db_iterator->() if ($db_iterator);

            if (! $next_db_row and $by_hand_recursive_rule_template and @by_hand_recursive_source_values) {
                # DB is out of results for this query, we need to handle recursion here in the context
                # and there are values to recurse on
                unless ($by_hand_recursing_iterator) {
                    # Do a new get() on the data source to recursively get more data
                    my $recurse_rule = $by_hand_recursive_rule_template->get_rule_for_values(\@by_hand_recursive_source_values);
                    $by_hand_recursing_iterator = $self->_create_import_iterator_for_underlying_context($recurse_rule,$dsx,$this_get_serial);
                }
                my $retval = $next_object_to_return;
                $next_object_to_return = $by_hand_recursing_iterator->();
                unless ($next_object_to_return) {
                    $by_hand_recursing_iterator = undef;
                    $by_hand_recursive_rule_template = undef;
                }
                return $retval;
            }

            unless ($next_db_row) {
                $db_iterator = undef;

                if ($rows == 0) {
                    # if we got no data at all from the sql then we give a status
                    # message about it and we update all_params_loaded to indicate
                    # that this set of parameters yielded 0 objects

                    my $rule_template_is_id_only = $query_plan->{rule_template_is_id_only};
                    if ($rule_template_is_id_only) {
                        my $id = $rule->value_for_id;
                        $UR::Context::all_objects_loaded->{$class_name}->{$id} = undef;
                    }
                    else {
                        $UR::Context::all_params_loaded->{$rule_template_id}->{$rule_id} = 0;
                    }
                }

                if ( $query_plan->{rule_matches_all} ) {
                    # No parameters.  We loaded the whole class.
                    # Doing a load w/o a specific ID w/o custom SQL loads the whole class.
                    # Set a flag so that certain optimizations can be made, such as 
                    # short-circuiting future loads of this class.        
                    #
                    # If the key still exists in the all_objects_are_loaded hash, then
                    # we can set it to true.  This is needed in the case where the user
                    # gets an iterator for all the objects of some class, but unloads
                    # one or more of the instances (be calling unload or through the 
                    # cache pruner) before the iterator completes.  If so, _abandon_object()
                    # will have removed the key from the hash
                    if (exists($UR::Context::all_objects_are_loaded->{$class_name})) {
                        $class_name->all_objects_are_loaded(1);
                    }
                }

                if ($recursion_desc) {
                    my @results = $class_name->is_loaded($rule_without_recursion_desc);
                    $UR::Context::all_params_loaded->{$rule_template_id_without_recursion}{$rule_id_without_recursion} = scalar(@results);
                    for my $object (@results) {
                        $object->{__load}->{$rule_template_id_without_recursion}->{$rule_id_without_recursion}++;
                    }
                }

                # Apply changes to all_params_loaded that each importer has collected
                foreach (@object_fabricators) {
                    $_->finalize if $_;
                }

                # If the SQL for the subclassed items was constructed properly, then each
                # of these iterators should be at the end, too.  Call them one more time
                # so they'll finalize their object fabricators.
                foreach my $class ( keys %subordinate_iterator_for_class ) {
                    my $obj = $subordinate_iterator_for_class{$class}->();
                    if ($obj) {
                        # The last time this happened, it was because a get() was done on an abstract
                        # base class with only 'id' as a param.  When the subclassified rule was
                        # turned into SQL in UR::DataSource::QueryPlan()
                        # it removed that one 'id' filter, since it assumed any class with more than
                        # one ID property (usually classes have a named whatever_id property, and an alias 'id'
                        # property) will have a rule that covered both ID properties
                        Carp::carp("Leftover objects in subordinate iterator for $class.  This shouldn't happen, but it's not fatal...");
                        while ($obj = $subordinate_iterator_for_class{$class}->()) {1;}
                    }
                }

                my $retval = $next_object_to_return;
                $next_object_to_return = undef;
                return $retval;
            }

            # we count rows processed mainly for more concise sanity checking
            $rows++;
            # For multi-datasource queries, does this row successfully join with all the other datasources?
            #
            # Normally, the policy is for the data source query to return (possibly) more than what you
            # asked for, and then we'd cache everything that may have been loaded.  In this case, we're
            # making the choice not to.  Reason being that a join across databases is likely to involve
            # a lot of objects, and we don't want to be stuffing our object cache with a lot of things
            # we're not interested in.  FIXME - in order for this to be true, then we could never query
            # these secondary data sources against, say, a calculated property because we're never turning
            # them into objects.  FIXME - fix this by setting the $needs_further_boolexpr_evaluation_after_loading
            # flag maybe?
            my @secondary_data;
            foreach my $callback (@addl_join_comparators) {
                # FIXME - (no, not another one...) There's no mechanism for duplicating SQL join's
                # behavior where if a row from a table joins to 2 rows in the secondary table, the 
                # first table's data will be in the result set twice.
                my $secondary_db_row = $callback->($next_db_row);
                unless (defined $secondary_db_row) {
                    # That data source has no more data, so there can be no more joins even if the
                    # primary data source has more data left to read
                    $db_iterator = undef;
                    $primary_object_for_next_db_row = undef;
                    last LOAD_AN_OBJECT;
                }
                unless ($secondary_db_row) {
                    # It returned 0
                    # didn't join (but there is still more data we can read later)... throw this row out.
                    $primary_object_for_next_db_row = undef;
                    redo LOAD_AN_OBJECT;
                }
                # $next_db_row is a read-only value from DBI, so we need to track our additional 
                # data seperately and smash them together before the object importer is called
                push(@secondary_data, @$secondary_db_row);
            }

            # get one or more objects from this row of results
            my $re_iterate = 0;
            my @imported;
            for (my $i = 0; $i < @object_fabricator_closures; $i++) {
                my $object_fabricator = $object_fabricator_closures[$i];

                # The usual case is that the query is just against one data source, and so the importer
                # callback is just given the row returned from the DB query.  For multiple data sources,
                # we need to smash together the primary and all the secondary lists
                my $imported_object;

                #my $object_creation_time;
                #if ($is_monitor_query) {
                #    $object_creation_time = Time::HiRes::time();
                #}

                if (@secondary_data) {
                    $imported_object = $object_fabricator->([@$next_db_row, @secondary_data]);
                } else {
                    $imported_object = $object_fabricator->($next_db_row);
                }

                #if ($is_monitor_query) {
                #    $self->_log_query_for_rule($class_name, $rule, sprintf("QUERY: object fabricator took %.4f s",Time::HiRes::time() - $object_creation_time));
                #}

                if ($imported_object and not ref($imported_object)) {
                    # object requires sub-classsification in a way which involves different db data.
                    $re_iterate = 1;
                }
                push @imported, $imported_object;

                # If the object ID for fabricator slot $i changes, then we can apply the 
                # all_params_loaded changes from iterators 0 .. $i-1 because we know we've
                # loaded all the hangoff data related to the previous object
                # remember that the last fabricator in the list is for the primary object
                if (defined $imported_object and ref($imported_object)) {
                    if (!defined $object_ids_from_fabricators[$i]) {
                        $object_ids_from_fabricators[$i] = $imported_object->id;
                    } elsif ($object_ids_from_fabricators[$i] ne $imported_object->id) {
                        for (my $j = 0; $j < $i; $j++) {
                            $object_fabricators[$j]->apply_all_params_loaded;
                        }
                        $object_ids_from_fabricators[$i] = $imported_object->id;
                    }
                }
            }

            $primary_object_for_next_db_row = $imported[-1];

            # The object importer will return undef for an object if no object
            # got created for that $next_db_row, and will return a string if the object
            # needs to be subclassed before being returned.  Don't put serial numbers on
            # these
            map { $_->{'__get_serial'} = $this_get_serial }
                grep { defined && ref }
                @imported;

            if ($re_iterate and defined($primary_object_for_next_db_row) and ! ref($primary_object_for_next_db_row)) {
                # It is possible that one or more objects go into subclasses which require more
                # data than is on the results row.  For each subclass (or set of subclasses),
                # we make a more specific, subordinate iterator to delegate-to.

                my $subclass_name = $primary_object_for_next_db_row;

                my $subclass_meta = UR::Object::Type->get(class_name => $subclass_name);
                my $table_subclass = $subclass_meta->most_specific_subclass_with_table();
                my $sub_iterator = $subordinate_iterator_for_class{$table_subclass};
                unless ($sub_iterator) {
                    #print "parallel iteration for loading $subclass_name under $class_name!\n";
                    my $sub_classified_rule_template = $rule_template->sub_classify($subclass_name);
                    my $sub_classified_rule = $sub_classified_rule_template->get_normalized_rule_for_values(@values);
                    $sub_iterator
                        = $subordinate_iterator_for_class{$table_subclass}
                            = $self->_create_import_iterator_for_underlying_context($sub_classified_rule,$dsx,$this_get_serial);
                }
                ($primary_object_for_next_db_row) = $sub_iterator->();
                if (! defined $primary_object_for_next_db_row) {
                    # the newly subclassed object 
                    redo LOAD_AN_OBJECT;
                }

            } # end of handling a possible subordinate iterator delegate

            unless (defined $primary_object_for_next_db_row) {
            #if (!$primary_object_for_next_db_row or $rule->evaluate($primary_object_for_next_db_row)) {
                redo LOAD_AN_OBJECT;
            }

            if ( !$group_by and (ref($primary_object_for_next_db_row) ne $class_name) and (not $primary_object_for_next_db_row->isa($class_name)) ) {
                $primary_object_for_next_db_row = undef;
                redo LOAD_AN_OBJECT;
            }

            if ($by_hand_recursive_source_property) {
                my @values = grep { defined } $primary_object_for_next_db_row->$by_hand_recursive_source_property;
                push @by_hand_recursive_source_values, @values;
            }

            if (! defined($next_object_to_return)
                or (Scalar::Util::refaddr($next_object_to_return) == Scalar::Util::refaddr($primary_object_for_next_db_row))
            ) {
                # The first time through the iterator, we need to buffer the object until
                # $primary_object_for_next_db_row is something different.
                $next_object_to_return = $primary_object_for_next_db_row;
                $primary_object_for_next_db_row = undef;
                redo LOAD_AN_OBJECT;
            }


        } # end of loop until we have a defined object to return

        #foreach my $object_fabricator ( @object_fabricators ) {
        #    # Don't apply all_params_loaded for primary fab until it's all done
        #    next if ($object_fabricator eq $object_fabricators[-1]);
        #    $object_fabricator->apply_all_params_loaded;
        #}

        my $retval = $next_object_to_return;
        $next_object_to_return = $primary_object_for_next_db_row;
        return $retval;
    };

    Sub::Name::subname('UR::Context::__underlying_context_iterator(closure)__', $underlying_context_iterator);
    return $underlying_context_iterator;
}



1;
