package UR::Context::ObjectFabricator;

use strict;
use warnings;

use Scalar::Util;
use UR::Context;

our $VERSION = "0.46"; # UR $VERSION;

# A helper package for UR::Context to keep track of the subrefs used
# to create objects from database data
# These are normal Perl objects, not UR objects, so they get 
# regular refcounting and scoping

our @CARP_NOT = qw( UR::Context );

my %all_object_fabricators;

sub _create {
    my $class = shift;

    my %params = @_;

    unless ($params{'fabricator'} and ref($params{'fabricator'}) eq 'CODE') {
        Carp::croak("UR::Context::ObjectFabricator::create requires a subroutine ref for the 'fabricator' parameter");
    }

    unless ($params{'context'} and ref($params{'context'}) and $params{'context'}->isa('UR::Context')) {
        Carp::croak("UR::Context::ObjectFabricator::create requires a UR::Context object for the 'context' parameter");
    }

    my $self = bless {}, $class;

    $self->{'fabricator'} = $params{'fabricator'};
    $self->{'context'} = $params{'context'};

    $self->{'all_params_loaded'} = $params{'all_params_loaded'} || {};
    $self->{'in_clause_values'} = $params{'in_clause_values'} || {};

    $all_object_fabricators{$self} = $self;
    Scalar::Util::weaken($all_object_fabricators{$self});

    return $self;
}


sub create_for_loading_template {
    my($fab_class, $context, $loading_template, $query_plan, $rule, $rule_template, $values, $dsx) = @_;
    my @values = @$values;

    my $class_name                                  = $loading_template->{final_class_name};
    #$class_name or Carp::croak("No final_class_name in loading template?");
    unless ($class_name) {
        #Carp::carp("No final_class_name in loading template for rule $rule");
        return;   # This join doesn't result in an object? - i think this happens when you do a get() with -hints
    }

    my $class_meta                                  = $class_name->__meta__;
    my $class_data                                  = $dsx->_get_class_data_for_loading($class_meta);
    my $class = $class_name;

    my $ghost_class                                 = $class_data->{ghost_class};
    my $sub_classification_meta_class_name          = $class_data->{sub_classification_meta_class_name};
    my $subclassify_by            = $class_data->{subclassify_by};
    my $sub_classification_method_name              = $class_data->{sub_classification_method_name};

    # FIXME, right now, we don't have a rule template for joined entities...

    my $rule_template_id                            = $query_plan->{rule_template_id};
    my $rule_template_without_recursion_desc        = $query_plan->{rule_template_without_recursion_desc};
    my $rule_template_id_without_recursion_desc     = $query_plan->{rule_template_id_without_recursion_desc};
    my $rule_matches_all                            = $query_plan->{rule_matches_all};
    my $rule_template_is_id_only                    = $query_plan->{rule_template_is_id_only};
    my $rule_specifies_id                           = $query_plan->{rule_specifies_id};
    my $rule_template_specifies_value_for_subtype   = $query_plan->{rule_template_specifies_value_for_subtype};

    my $recursion_desc                              = $query_plan->{recursion_desc};
    my $recurse_property_on_this_row                = $query_plan->{recurse_property_on_this_row};
    my $recurse_property_referencing_other_rows     = $query_plan->{recurse_property_referencing_other_rows};

    my $needs_further_boolexpr_evaluation_after_loading = $query_plan->{'needs_further_boolexpr_evaluation_after_loading'};

    my $rule_id = $rule->id;
    my $rule_without_recursion_desc = $rule_template_without_recursion_desc->get_rule_for_values(@values);

    my $loading_base_object;
    if ($loading_template == $query_plan->{loading_templates}[0]) {
        $loading_base_object = 1;
    }
    else {
        $loading_base_object = 0;
        $needs_further_boolexpr_evaluation_after_loading = 0;
    }

    my %subclass_is_safe_for_re_bless;
    my %subclass_for_subtype_name;
    my %recurse_property_value_found;

    my @property_names      = @{ $loading_template->{property_names} };
    my @id_property_names   = @{ $loading_template->{id_property_names} };
    my @column_positions    = @{ $loading_template->{column_positions} };
    my @id_positions        = @{ $loading_template->{id_column_positions} };
    my $multi_column_id     = (@id_positions > 1 ? 1 : 0);
    my $composite_id_resolver = $class_meta->get_composite_id_resolver;

    # The old way of specifying that some values were constant for all objects returned
    # by a get().  The data source would wrap the method that builds the loading template
    # and wedge in some constant_property_names.  The new way is to add columns to the
    # loading template, and then add the values onto the list returned by the data source
    # iterator.  
    my %initial_object_data;
    if ($loading_template->{constant_property_names}) {
        my @constant_property_names  = @{ $loading_template->{constant_property_names} };
        my @constant_property_values = map { $rule->value_for($_) } @constant_property_names;
        @initial_object_data{@constant_property_names} = @constant_property_values;
    }

    my $rule_class_name = $rule_template->subject_class_name;
    my $template_id     = $rule_template->id;
    my $load_class_name = $class;
    # $rule can contain params that may not apply to the subclass that's currently loading.
    # define_boolexpr() in array context will return the portion of the rule that actually applies
    #my($load_rule, undef) = $load_class_name->define_boolexpr($rule->params_list);
    my($load_rule, @extra_params) = UR::BoolExpr->resolve($load_class_name, $rule->params_list);
    my $load_rule_id = $load_rule->id;
    my $load_template_id = $load_rule->template_id;

    my @rule_properties_with_in_clauses =
        grep { $rule_template_without_recursion_desc->operator_for($_) eq 'in' }
             $rule_template_without_recursion_desc->_property_names;

    my($rule_template_without_in_clause,$rule_template_id_without_in_clause,%in_clause_values,@all_rule_property_names);
    my $do_record_in_all_params_loaded = 1;
    if (@rule_properties_with_in_clauses) {
        $rule_template_id_without_in_clause = $rule_template_without_recursion_desc->id;
        foreach my $property_name ( @rule_properties_with_in_clauses ) {
            # FIXME - removing and re-adding the filter should have the same effect as the substitute below,
            # but the two result in different rules in the end.
            #$rule_template_without_in_clause = $rule_template_without_in_clause->remove_filter($property_name);
            #$rule_template_without_in_clause = $rule_template_without_in_clause->add_filter($property_name);
            $rule_template_id_without_in_clause =~ s/($property_name) in/$1/;
        }
        $rule_template_without_in_clause = UR::BoolExpr::Template->get($rule_template_id_without_in_clause);
        # Make a note of all the values in the in-clauses.  As the objects get returned from the 
        # data source, we'll remove these notes.  Anything that's left by the time the iterator is
        # finalized must be values that matched nothing.  Then, finalize can put data in
        # all_params_loaded showing it matches nothing
        my %rule_properties_with_in_clauses = map { $_ => 1 } @rule_properties_with_in_clauses;
        @all_rule_property_names = $rule_template_without_in_clause->_property_names;
        foreach my $property ( @rule_properties_with_in_clauses ) {
            my $values_for_in_clause = $rule_without_recursion_desc->value_for($property);
            unless ($values_for_in_clause) {
                Carp::confess("rule has no value for property $property: $rule_without_recursion_desc");
            }
            if (@$values_for_in_clause > 100) {
                $do_record_in_all_params_loaded = 0;
                next;
            }

            my @other_values = map { exists $rule_properties_with_in_clauses{$_}
                                     ? undef   # placeholder filled in below
                                     : $rule_without_recursion_desc->value_for($_) }
                               $rule_template_without_in_clause->_property_names;
            my $position_for_this_property = $rule_template_without_in_clause->value_position_for_property_name($property);


            # If the number of items in the in-clause is over this number, then don't bother recording
            # the template-id/rule-id, since searching the list to see if this query has been done before
            # is going to take longer than just re-doing the query
            foreach my $value ( @$values_for_in_clause ) {
                $value = '' if (!defined $value);
                $other_values[$position_for_this_property] = $value;
                my $rule_with_this_in_property = $rule_template_without_in_clause->get_rule_for_values(@other_values);
                $in_clause_values{$property}->{$value}
                    = [$rule_template_id_without_in_clause, $rule_with_this_in_property->id];
            }
        }

    }

    # This is a local copy of what we want to put in all_params_loaded, when the object fabricator is
    # finalized
    my $local_all_params_loaded = {};

    my($hints_or_delegation,$delegations_with_no_objects);
    if (!$loading_base_object) {
        ($hints_or_delegation,$delegations_with_no_objects)
             = $fab_class->_resolve_delegation_data($rule,$loading_template,$query_plan,$local_all_params_loaded);
    }

    my $update_apl_for_loaded_object = sub {
        my $pending_db_object = shift;

        # Make a note in all_params_loaded (essentially, the query cache) that we've made a
        # match on this rule, and some equivalent rules
        if ($loading_base_object and not $rule_specifies_id) {
            if ($do_record_in_all_params_loaded) {
                if ($rule_class_name ne $load_class_name and scalar(@extra_params) == 0) {
                    $pending_db_object->{__load}->{$load_template_id}{$load_rule_id}++;
                    $UR::Context::all_params_loaded->{$load_template_id}{$load_rule_id} = undef;
                    $local_all_params_loaded->{$load_template_id}{$load_rule_id}++;
                }
                $pending_db_object->{__load}->{$template_id}{$rule_id}++;
                $UR::Context::all_params_loaded->{$template_id}{$rule_id} = undef;
                $local_all_params_loaded->{$template_id}{$rule_id}++;
            }

            if (@rule_properties_with_in_clauses) {
                # FIXME - confirm that all the object properties are filled in at this point, right?
                #my @values = @$pending_db_object{@rule_properties_with_in_clauses};
                my @values = @$pending_db_object{@all_rule_property_names};
                my $r = $rule_template_without_in_clause->get_normalized_rule_for_values(@values);
                my $r_id = $r->id;

                $UR::Context::all_params_loaded->{$rule_template_id_without_in_clause}{$r_id} = undef;
                $local_all_params_loaded->{$rule_template_id_without_in_clause}{$r_id}++;
                # remove the notes about these in-clause values since they matched something
                no warnings; # undef treated as an empty string below
                foreach my $property (@rule_properties_with_in_clauses) {
                    my $value = $pending_db_object->{$property};
                    delete $in_clause_values{$property}->{$value};
                }
            }
        }
    };


    my $fabricator_obj;  # filled in after the closure definition
    my $object_fabricator = sub {

        my $next_db_row = $_[0];

        # If all the columns for this object are undef, then this doesn't encode an actual
        # object, it's a result of a left join that matched nothing
        my $values_exist;
        foreach my $column ( @column_positions ) {
            if (defined($next_db_row->[$column])) {
                $values_exist = 1;
                last;
            }
        }
        if (!$loading_base_object and !$values_exist and $delegations_with_no_objects) {
            my $templates_and_rules = $fab_class->_lapl_data_for_delegation_data($delegations_with_no_objects, $next_db_row);
            while ( my($template_id, $rule_id) = each %$templates_and_rules) {
                $local_all_params_loaded->{$template_id}->{$rule_id} = 0;
                $UR::Context::all_params_loaded->{$template_id}->{$rule_id} = 0;
            }
            return;
        }
            

        my $pending_db_object_data = { %initial_object_data };
        @$pending_db_object_data{@property_names} = @$next_db_row[@column_positions];

        # resolve id
        my $pending_db_object_id;
        if ($multi_column_id) {
            $pending_db_object_id = $composite_id_resolver->(@$pending_db_object_data{@id_property_names})
        }
        else {
            $pending_db_object_id = $pending_db_object_data->{$id_property_names[0]};
        }

        unless (defined $pending_db_object_id) {
            return undef;
            Carp::confess(
                "no id found in object data for $class_name?\n"
                . Data::Dumper::Dumper($pending_db_object_data)
            );
        }

        my $pending_db_object;

        # skip if this object has been deleted but not committed
        do {
            no warnings;
            if ($UR::Context::all_objects_loaded->{$ghost_class}{$pending_db_object_id}) {
                return;
                #$pending_db_object = undef;
                #redo;
            }
        };

        # Handle the object based-on whether it is already loaded in the current context.
        if ($pending_db_object = $UR::Context::all_objects_loaded->{$class}{$pending_db_object_id}) {
            $context->__merge_db_data_with_existing_object($class, $pending_db_object, $pending_db_object_data, \@property_names);
            if ($loading_base_object
                and
                $needs_further_boolexpr_evaluation_after_loading
                and
                not $rule->evaluate($pending_db_object)
            ) {
                return;
            }
            $update_apl_for_loaded_object->($pending_db_object);
        }
        else {
            # Handle the case in which the object is completely new in the current context.

            # Create a new object for the resultset row
            $pending_db_object = bless { %$pending_db_object_data, id => $pending_db_object_id }, $class;
            $pending_db_object->{db_committed} = $pending_db_object_data;

            # determine the subclass name for classes which automatically sub-classify
            my $subclass_name;
            if (
                    (
                        $sub_classification_method_name
                        or $subclassify_by
                        or $sub_classification_meta_class_name
                    )
                    and
                    (ref($pending_db_object) eq $class) # not already subclased  
            ) {
                if ($sub_classification_method_name) {
                    $subclass_name = $class->$sub_classification_method_name($pending_db_object);
                    unless ($subclass_name) {
                        my $pending_obj_id = eval { $pending_db_object->id };
                        Carp::confess(
                            "Object with id '$pending_obj_id' loaded as abstract class $class failed to subclassify itself using method "
                            . $sub_classification_method_name
                        );
                    }
                }
                elsif ($sub_classification_meta_class_name) {
                    # Group objects requiring reclassification by type, 
                    # and catch anything which doesn't need reclassification.

                    my $subtype_name = $pending_db_object->$subclassify_by;
                    $subclass_name = $subclass_for_subtype_name{$subtype_name};
                    unless ($subclass_name) {
                        my $type_obj = $sub_classification_meta_class_name->get($subtype_name);

                        unless ($type_obj) {
                            # The base type may give the final subclass, or an intermediate
                            # either choice has trade-offs, but we support both.
                            # If an intermediate subclass is specified, that subclass
                            # will join to a table with another field to indicate additional 
                            # subclassing.  This means we have to do this part the hard way.
                            # TODO: handle more than one level.
                            my @all_type_objects = $sub_classification_meta_class_name->get();
                            for my $some_type_obj (@all_type_objects) {
                                my $some_subclass_name = $some_type_obj->subclass_name($class);
                                unless (UR::Object::Type->get($some_subclass_name)->is_abstract) {
                                    next;
                                }
                                my $some_subclass_meta = $some_subclass_name->__meta__;
                                my $some_subclass_type_class =
                                                $some_subclass_meta->sub_classification_meta_class_name;
                                if ($type_obj = $some_subclass_type_class->get($subtype_name)) {
                                    # this second-tier subclass works
                                    last;
                                }
                                else {
                                    # try another subclass, and check the subclasses under it
                                    #print "skipping $some_subclass_name: no $subtype_name for $some_subclass_type_class\n";
                                }
                            }
                        }

                        if ($type_obj) {
                            $subclass_name = $type_obj->subclass_name($class);
                        }
                        else {
                            warn "Failed to find $class_name sub-class for type '$subtype_name'!";
                            $subclass_name = $class_name;
                        }

                        unless ($subclass_name) {
                            Carp::confess(
                                "Failed to sub-classify $class using "
                                . $type_obj->class
                                . " '" . $type_obj->id . "'"
                            );
                        }

                        $subclass_name->class;
                    }
                    $subclass_for_subtype_name{$subtype_name} = $subclass_name;
                }
                else {
                    $subclass_name = $pending_db_object->$subclassify_by;
                    unless ($subclass_name) {
                        Carp::croak("Failed to sub-classify $class while loading; calling method "
                                    . "'$subclassify_by' returned false.  Relevant object data: "
                                    . Data::Dumper::Dumper($pending_db_object));
                    }
                }

                # note: we check this again with the real base class, but this keeps junk objects out of the core hash
                unless ($subclass_name->isa($class)) {
                    # We may have done a load on the base class, and not been able to use properties to narrow down to the correct subtype.
                    # The resultset returned more data than we needed, and we're filtering out the other subclasses here.
                    return;
                }
            }
            else {
                # regular, non-subclassifier
                $subclass_name = $class;
            }

            # store the object
            # note that we do this on the base class even if we know it's going to be put into a subclass below
            $UR::Context::all_objects_loaded->{$class}{$pending_db_object_id} = $pending_db_object;
            $UR::Context::all_objects_cache_size++;

            # If we're using a light cache, weaken the reference.
            if ($UR::Context::light_cache and substr($class,0,5) ne 'App::') {
                Scalar::Util::weaken($UR::Context::all_objects_loaded->{$class_name}->{$pending_db_object_id});
            }

            $update_apl_for_loaded_object->($pending_db_object);

            my $boolexpr_evaluated_ok;
            if ($subclass_name eq $class) {
                # This object doesn't need additional subclassing
                # Signal that the object has been loaded
                # NOTE: until this is done indexes cannot be used to look-up an object
                $pending_db_object->__signal_change__('load');
            } 
            else {
                # we did this above, but only checked the base class
                my $subclass_ghost_class = $subclass_name->ghost_class;
                if ($UR::Context::all_objects_loaded->{$subclass_ghost_class}{$pending_db_object_id}) {
                    # We put it in the object cache a few lines above.
                    # FIXME - why not wait until we know we're keeping it before putting it in there?
                    delete $UR::Context::all_objects_loaded->{$class}{$pending_db_object_id};
                    $UR::Context::all_objects_cache_size--;
                    return;
                    #$pending_db_object = undef;
                    #redo;
                }

                my $re_bless = $subclass_is_safe_for_re_bless{$subclass_name};
                if (not defined $re_bless) {
                    $re_bless = $dsx->_class_is_safe_to_rebless_from_parent_class($subclass_name, $class);
                    $re_bless ||= 0;
                    $subclass_is_safe_for_re_bless{$subclass_name} = $re_bless;
                }

                my $loading_info;

                if (!$re_bless) {
                    # This object cannot just be re-classified into a subclass because the subclass joins to additional tables.
                    # We'll make a parallel iterator for each subclass we encounter.

                    # Note that we let the calling db-based iterator do that, so that if multiple objects on the row need 
                    # sub-classing, we do them all at once.

                    # Decrement all of the param_keys it is using.
                    if ($loading_base_object) {
                        $loading_info = $dsx->_get_object_loading_info($pending_db_object);
                        $loading_info = $dsx->_reclassify_object_loading_info_for_new_class($loading_info,$subclass_name);
                    }

                    #$pending_db_object->unload;
                    delete $UR::Context::all_objects_loaded->{$class}->{$pending_db_object_id};

                    if ($loading_base_object) {
                        $dsx->_record_that_loading_has_occurred($loading_info);
                    }

                    # NOTE: we're returning a class name instead of an object
                    # this tells the caller to re-do the entire row using a subclass to get the real data.
                    # Hack?  Probably so...
                    return $subclass_name;
                }

                # Performance shortcut.
                # These need to be subclassed, but there is no additional data to load.
                # Just remove from the object cache, rebless to the proper subclass, and
                # re-add to the object cache
                my $already_loaded = $subclass_name->is_loaded($pending_db_object_id);

                my $different;
                my $merge_exception;
                if ($already_loaded) {
                    eval { $different = $context->__merge_db_data_with_existing_object($class, $already_loaded, $pending_db_object_data, \@property_names) };
                    $merge_exception = $@;
                }

                if ($already_loaded and !$different and !$merge_exception) {
                    if ($pending_db_object == $already_loaded) {
                        Carp::croak("An object of type ".$already_loaded->class." with ID '".$already_loaded->id
                                    ."' was just loaded, but already exists in the object cache in the proper subclass");
                    }
                    if ($loading_base_object) {
                        # Get our records about loading this object
                        $loading_info = $dsx->_get_object_loading_info($pending_db_object);

                        # Transfer the load info for the load we _just_ did to the subclass too.
                        my $subclassified_template = $rule_template->sub_classify($subclass_name);
                        $loading_info->{$subclassified_template->id} = $loading_info->{$template_id};
                        $loading_info = $dsx->_reclassify_object_loading_info_for_new_class($loading_info,$subclass_name);
                    }

                    # This will wipe the above data from the object and the contex...
                    delete $UR::Context::all_objects_loaded->{$class}->{$pending_db_object_id};

                    if ($loading_base_object) {
                        # ...now we put it back for both.
                        $dsx->_add_object_loading_info($already_loaded, $loading_info);
                        $dsx->_record_that_loading_has_occurred($loading_info);
                    }

                    bless($pending_db_object,'UR::DeletedRef');
                    $pending_db_object = $already_loaded;
                }
                else {
                    if ($loading_base_object) {
                        my $subclassified_template = $rule_template->sub_classify($subclass_name);

                        $loading_info = $dsx->_get_object_loading_info($pending_db_object);
                        $dsx->_record_that_loading_has_occurred($loading_info);
                        $loading_info->{$subclassified_template->id} = delete $loading_info->{$template_id};
                        $loading_info = $dsx->_reclassify_object_loading_info_for_new_class($loading_info,$subclass_name);
                    }

                    my $prev_class_name = $pending_db_object->class;
                    #my $id = $pending_db_object->id;
                    #$pending_db_object->__signal_change__("unload");
                    delete $UR::Context::all_objects_loaded->{$prev_class_name}->{$pending_db_object_id};
                    delete $UR::Context::all_objects_are_loaded->{$prev_class_name};
                    if ($merge_exception) {
                        # Now that we've removed traces of the incorrectly-subclassed $pending_db_object,
                        # we can pass up any exception generated in __merge_db_data_with_existing_object
                        Carp::croak($merge_exception);
                    }
                    if ($already_loaded) {
                        # The new object should replace the old object.  Since other parts of the user's program
                        # may have references to this object, we need to copy the values from the new object into
                        # the existing cached object
                        bless($pending_db_object,'UR::DeletedRef');
                        $pending_db_object = $already_loaded;
                    } else {
                        # This is a completely new object
                        $UR::Context::all_objects_loaded->{$subclass_name}->{$pending_db_object_id} = $pending_db_object;
                    }
                    bless $pending_db_object, $subclass_name;
                    $pending_db_object->__signal_change__("load");

                    $dsx->_add_object_loading_info($pending_db_object, $loading_info);
                    $dsx->_record_that_loading_has_occurred($loading_info);
                }

                # the object may no longer match the rule after subclassifying...
                if ($needs_further_boolexpr_evaluation_after_loading
                    and
                    $loading_base_object
                    and
                    not $rule->evaluate($pending_db_object)
                ) {
                    #print "Object does not match rule!" . Dumper($pending_db_object,[$rule->params_list]) . "\n";
                    #$rule->evaluate($pending_db_object);
                    return;
                } else {
                    $boolexpr_evaluated_ok = 1;
                }
            } # end of sub-classification code

            if (
                $loading_base_object
                and
                $needs_further_boolexpr_evaluation_after_loading
                and
                ( ! $boolexpr_evaluated_ok )
                and
                ( ! $rule->evaluate($pending_db_object) )
            ) {
                return;
            }
        } # end handling newly loaded objects

        # If the rule had hints, mark that we loaded those things too, in all_params_loaded
        if ($hints_or_delegation) {
            my $templates_and_rules = $fab_class->_lapl_data_for_delegation_data($hints_or_delegation,
                                                                                 $next_db_row,
                                                                                 $pending_db_object);
            while ( my($template_id, $rule_id) = each %$templates_and_rules) {
                $local_all_params_loaded->{$template_id}->{$rule_id}++;
                $UR::Context::all_params_loaded->{$template_id}->{$rule_id} = undef;
            }
        }

        # note all of the joins which follow this object as having been "done"
        if (my $next_joins = $loading_template->{next_joins}) {
            if (0) {
                # disabled until a fully reframed query is the basis for these joins
                for my $next_join (@$next_joins) {
                    my ($bxt_id, $values, $value_position_property_name) = @$next_join;
                    for (my $n = 0; $n < @$value_position_property_name; $n+=2) {
                        my $pos = $value_position_property_name->[$n];
                        my $name = $value_position_property_name->[$n+1];
                        $values->[$pos] = $pending_db_object->$name;
                    }   
                    my $bxt = UR::BoolExpr::Template::And->get($bxt_id);
                    my $bx = $bxt->get_rule_for_values(@$values);
                    $UR::Context::all_params_loaded->{$bxt->{id}}->{$bx->{id}} = undef;
                    $local_all_params_loaded->{$bxt->{id}}->{$bx->{id}}++;
                    print "remembering $bx\n";
                }
            }
        }

        # When there is recursion in the query, we record data from each 
        # recursive "level" as though the query was done individually.
        if ($recursion_desc and $loading_base_object) {
            # if we got a row from a query, the object must have
            # a db_committed or db_saved_committed                                
            my $dbc = $pending_db_object->{db_committed} || $pending_db_object->{db_saved_uncommitted};
            Carp::croak("Loaded database data has no save data for $class id ".$pending_db_object->id
                        .". Something bad happened.".Data::Dumper::Dumper($pending_db_object)) unless $dbc;

            my $value_by_which_this_object_is_loaded_via_recursion = $dbc->{$recurse_property_on_this_row};
            my $value_referencing_other_object = $dbc->{$recurse_property_referencing_other_rows};
            $value_referencing_other_object = '' unless (defined $value_referencing_other_object);
            unless ($recurse_property_value_found{$value_referencing_other_object}) {
                # This row points to another row which will be grabbed because the query is hierarchical.
                # Log the smaller query which would get the hierarchically linked data directly as though it happened directly.
                $recurse_property_value_found{$value_referencing_other_object} = 1;
                # note that the direct query need not be done again
                my $equiv_rule = UR::BoolExpr->resolve_normalized(
                                       $class,
                                       $recurse_property_on_this_row => $value_referencing_other_object,
                                   );
                my $equiv_rule_id = $equiv_rule->id;
                my $equiv_template_id = $equiv_rule->template_id;

                # note that the recursive query need not be done again
                my $equiv_rule_2 = UR::BoolExpr->resolve_normalized(
                                        $class,
                                        $recurse_property_on_this_row => $value_referencing_other_object,
                                        -recurse => $recursion_desc,
                                     );
                my $equiv_rule_id_2 = $equiv_rule_2->id;
                my $equiv_template_id_2 = $equiv_rule_2->template_id;

                # For any of the hierarchically related data which is already loaded, 
                # note on those objects that they are part of that query.  These may have loaded earlier in this
                # query, or in a previous query.  Anything NOT already loaded will be hit later by the if-block below.
                my @subset_loaded = $class->is_loaded($recurse_property_on_this_row => $value_referencing_other_object);
                $UR::Context::all_params_loaded->{$equiv_template_id}->{$equiv_rule_id} = undef;
                $UR::Context::all_params_loaded->{$equiv_template_id_2}->{$equiv_rule_id_2} = undef;
                $local_all_params_loaded->{$equiv_template_id}->{$equiv_rule_id} = scalar(@subset_loaded);
                $local_all_params_loaded->{$equiv_template_id_2}->{$equiv_rule_id_2} = scalar(@subset_loaded);
                for my $pending_db_object (@subset_loaded) {
                    $pending_db_object->{__load}->{$equiv_template_id}->{$equiv_rule_id}++;
                    $pending_db_object->{__load}->{$equiv_template_id_2}->{$equiv_rule_id_2}++;
                }
            }

            # NOTE: if it were possible to use undef values in a connect-by, this could be a problem
            # however, connect by in UR is always COL = COL, which would always fail on NULLs.
            if (defined($value_by_which_this_object_is_loaded_via_recursion) and $recurse_property_value_found{$value_by_which_this_object_is_loaded_via_recursion}) {
                # This row was expected because some other row in the hierarchical query referenced it.
                # Up the object count, and note on the object that it is a result of this query.
                my $equiv_rule = UR::BoolExpr->resolve_normalized(
                                       $class,
                                       $recurse_property_on_this_row => $value_by_which_this_object_is_loaded_via_recursion,
                                    );
                my $equiv_rule_id     = $equiv_rule->id;
                my $equiv_template_id = $equiv_rule->template_id;

                # note that the recursive query need not be done again
                my $equiv_rule_2 = UR::BoolExpr->resolve_normalized(
                                        $class,
                                        $recurse_property_on_this_row => $value_by_which_this_object_is_loaded_via_recursion,
                                        -recurse => $recursion_desc
                                     );
                my $equiv_rule_id_2     = $equiv_rule_2->id;
                my $equiv_template_id_2 = $equiv_rule_2->template_id;

                $UR::Context::all_params_loaded->{$equiv_template_id}->{$equiv_rule_id} = undef;
                $UR::Context::all_params_loaded->{$equiv_template_id_2}->{$equiv_rule_id_2} = undef;
                $local_all_params_loaded->{$equiv_template_id}->{$equiv_rule_id}++;
                $local_all_params_loaded->{$equiv_template_id_2}->{$equiv_rule_id_2}++;
                $pending_db_object->{__load}->{$equiv_template_id}->{$equiv_rule_id}++;
                $pending_db_object->{__load}->{$equiv_template_id_2}->{$equiv_rule_id_2}++;
            }
        } # end of handling recursion

        return $pending_db_object;

    }; # end of per-class object fabricator
    Sub::Name::subname("UR::Context::__object_fabricator(closure)__ ($class_name)", $object_fabricator);

    # remember all the changes to $UR::Context::all_params_loaded that should be made.
    # This fixes the problem where you create an iterator for a query, read back some of
    # the items, but not all, then later make the same query.  The old behavior made
    # entries in all_params_loaded as objects got loaded from the DB, so that at the time
    # the second query is made, UR::Context::_cache_is_complete_for_class_and_normalized_rule()
    # sees there are entries in all_params_loaded, and so reports yes, the cache is complete,
    # and the second query only returns the objects that were loaded during the first query.
    #
    # The new behavior builds up changes to be made to all_params_loaded, and someone
    # needs to call $object_fabricator->finalize() to apply these changes
    $fabricator_obj = $fab_class->_create(fabricator => $object_fabricator,
                                          context    => $context,
                                          all_params_loaded => $local_all_params_loaded,
                                          in_clause_values  => \%in_clause_values);

    return $fabricator_obj;
}


# Given the data created in _resolve_delegation_data (rule templates and values/valuerefs)
# return a hash of template IDs => rule IDs that need to be manipulated in local_all_params_loaded
sub _lapl_data_for_delegation_data {
    my($fab_class, $delegation_data_list, $next_db_row, $pending_db_object) = @_;

    my %tmpl_and_rules;

    foreach my $delegation_data ( @$delegation_data_list ) {
        my $value_sources = $delegation_data->[0];
        my $rule_tmpl  = $delegation_data->[1];
        my @values;
        foreach my $value_source ( @$value_sources ) {
            if (! ref($value_source)) {
                push @values, $value_source;
            } elsif (Scalar::Util::looks_like_number($$value_source)) {
                push @values, $next_db_row->[$$value_source];
            } elsif ($pending_db_object) {
                my $method_name = $$value_source;
                my $result = eval { $pending_db_object->$method_name };
                push @values, $result;
            } else {
                Carp::croak("Can't resolve value for '".$$value_source."' in delegation data when there is no object involved");
            }
        }
        my $rule = $rule_tmpl->get_normalized_rule_for_values(@values);
        $tmpl_and_rules{$rule_tmpl->id} = $rule->id;
    }
    return \%tmpl_and_rules;
}


# This is used by fabricators created as a result of filters or hints on delegated properties
# of the primary object to pre-calculate rule templates and value sources that can be combined
# with these templates to make rules.  The resulting template and rule IDs are then plugged into
# all_params_loaded to indicate these related objects are loaded so that subsequent queries
# will not hit the data sources.
sub _resolve_delegation_data {
    my($fab_class,$rule,$loading_template,$query_plan,$local_all_params_loaded) = @_;

    my $rule_template = $rule->template;

    my $query_class_meta = $rule_template->subject_class_name->__meta__;

    my %hints;
    if ($rule_template->hints) {
        $hints{$_} = 1 foreach(@{ $rule_template->hints });
    }
    my %delegations;
    if (@{ $query_plan->{'joins'}} ) {
        foreach my $delegated_property_name ( $rule_template->_property_names ) {
            my $delegated_property_meta = $query_class_meta->property_meta_for_name($delegated_property_name);
            next unless ($delegated_property_meta and $delegated_property_meta->is_delegated);
            $delegations{$delegated_property_name} = 1;
        }
    }

    my $this_object_num = $loading_template->{'object_num'};

    my $join = $query_plan->_get_alias_join($loading_template->{'table_alias'});
    return unless $join;  # would this ever be false?
    return unless ($join->{'foreign_class'} eq $loading_template->{'data_class_name'}); # sanity check

    my $delegated_property_meta;
    # Find out which delegation property was responsible for this object being loaded
    DELEGATIONS:
    foreach my $delegation ((keys %hints), (keys %delegations)) {
        my $query_property_meta = $query_class_meta->property_meta_for_name($delegation);
        next DELEGATIONS unless $query_property_meta;

        my @joins_from_delegation = $query_property_meta->_resolve_join_chain();
        foreach my $join_from_delegation ( @joins_from_delegation ) {
            if ($join_from_delegation->id eq $join->id) {
                $delegated_property_meta = $query_property_meta;
                last DELEGATIONS;
            }
        }
    }
    return unless $delegated_property_meta;
    my $delegated_property_name = $delegated_property_meta->property_name;

    return if $join->destination_is_all_id_properties();

    my @template_filter_names = @{$join->{'foreign_property_names'}};
    my %template_filter_values;
    foreach my $name ( @template_filter_names ) {
        my $column_num = $query_plan->column_index_for_class_property_and_object_num(
                                          $join->{'foreign_class'},
                                          $name,
                                          $this_object_num);
        if (defined $column_num) {
             $template_filter_values{$name} = \$column_num;
        } else {
             my $prop_name = $name;
             $template_filter_values{$name} = \$prop_name;
        }
    }

    if ($delegations{$delegated_property_name}) {
        my $delegation_final_property_meta = $delegated_property_meta->final_property_meta;
        if ($delegation_final_property_meta
            and
            $delegation_final_property_meta->class_name eq $join->{'foreign_class'}
        ) {
            # This delegation points to (or at least through) this join's foreign class
            # We'll note that these related objects were loaded as a result of being
            # connected to the primary object by this value, and filtered by the
            # delegation property's value
            my $delegation_final_property_name = $delegation_final_property_meta->property_name;
            my $column_num = $query_plan->column_index_for_class_property_and_object_num(
                                              $join->{'foreign_class'},
                                              $delegation_final_property_name,
                                              $this_object_num);
            push @template_filter_names, $delegation_final_property_name;
            if ($delegation_final_property_meta->column_name and ! defined ($column_num)) {
                # sanity check
                Carp::carp("Could not determine column offset in result set for property "
                           . "$delegation_final_property_name of class " . $join->{'foreign_class'}
                           . " even though it has column_name " . $delegation_final_property_meta->column_name);
                $column_num = undef;
            }
            if (defined $column_num) {
                $template_filter_values{$delegation_final_property_name} = \$column_num;
            } else {
                $template_filter_values{$delegation_final_property_name} = \$delegation_final_property_name;
            }
        }
    }

    # For missing objects, ie. a left join was done and it matched nothing
    my @missing_prop_names;
    my %missing_values;
    for (my $i = 0; $i < @{ $join->{'foreign_property_names'}}; $i++) {
        # we're using the source class/property here because we're going to denote that a value
        # of the source class of the join matched nothing
        my $prop_name = $join->{'foreign_property_names'}->[$i];
        push @missing_prop_names, $prop_name;
        my $source_class = $join->{'source_class'};
        my $source_prop_name = $join->{'source_property_names'}->[$i];
        my $column_num;
        if( my($actual_prop_meta) = $source_class->__meta__->_concrete_property_meta_for_class_and_name($source_prop_name) ) {
            $column_num = $query_plan->column_index_for_class_and_property_before_object_num($actual_prop_meta->class_name,
                                                                                             $actual_prop_meta->property_name,
                                                                                             $this_object_num);
        }
        if (defined $column_num) {
            $missing_values{$prop_name} = \$column_num;
        } else {
            Carp::croak("Can't determine resultset column for $source_class property $source_prop_name for rule $rule");
        }
    }
    if ($join->{'where'}) {
        for (my $i = 0; $i < @{$join->{'where'}}; $i += 2) {
            my $where_prop = $join->{'where'}->[$i];
            push @template_filter_names, $where_prop;
            push @missing_prop_names, $where_prop;

            my $pos = index($where_prop, ' ');
            if ($pos != -1) {
                # the key is "propname op"
                $where_prop = substr($where_prop,0,$pos);
            }
            my $where_value = $join->{'where'}->[$i+1];
            $template_filter_values{$where_prop} = $where_value;
            $missing_values{$where_prop} = $where_value;
        }
    }

    my $missing_rule_tmpl = UR::BoolExpr::Template->resolve($join->{'foreign_class'}, @missing_prop_names)->get_normalized_template_equivalent;

    my $related_rule_tmpl = UR::BoolExpr::Template->resolve($join->{'foreign_class'},
                                                            @template_filter_names)->get_normalized_template_equivalent;

    my(@hints_or_delegation, @delegations_with_no_objects);
    # Items in the first listref can be one of three things:
    # 1) a reference to an integer - meaning retrieve the value from this column in the result set
    # 2) a reference to a string   - meaning retrieve the value from the object usign this as a property name
    # 3) a string - meaning this is a literal value to fill in directly
    # The second item is a rule template we'll be feeding these values in to
    my @template_filter_values = @template_filter_values{$related_rule_tmpl->_property_names};
    push @hints_or_delegation, [ \@template_filter_values, $related_rule_tmpl];

    my @missing_values = @missing_values{$missing_rule_tmpl->_property_names};
    push @delegations_with_no_objects, [\@missing_values, $missing_rule_tmpl];

    return (\@hints_or_delegation, \@delegations_with_no_objects);
}



sub all_object_fabricators {
    return values %all_object_fabricators;
}

# simple accessors

sub fabricator {
    my $self = shift;
    return $self->{'fabricator'};
}

sub context {
   my $self = shift;
   return $self->{'context'};
}

sub all_params_loaded {
    my $self = shift;
    return $self->{'all_params_loaded'};
}

sub in_clause_values {
    my $self = shift;
    return $self->{'in_clause_values'};
}

# call the object fabricator closure
sub fabricate {
    my $self = shift;

    &{$self->{'fabricator'}};
}



# Returns true if this fabricator has loaded an object matching this boolexpr
sub is_loading_in_progress_for_boolexpr {
    my $self = shift;
    my $boolexpr = shift;

    my $template_id = $boolexpr->template_id;
    # FIXME should it use is_subsest_of here?
    return unless exists $self->{'all_params_loaded'}->{$template_id};
    return unless exists $self->{'all_params_loaded'}->{$template_id}->{$boolexpr->id};
    return 1;
}


# UR::Contect::_abandon_object calls this to forget about loading an object
sub delete_from_all_params_loaded {
    my($self,$template_id,$boolexpr_id) = @_;

    return unless ($template_id and $boolexpr_id);

    my $all_params_loaded = $self->all_params_loaded;

    return unless $all_params_loaded;
    return unless exists($all_params_loaded->{$template_id});
    delete $all_params_loaded->{$template_id}->{$boolexpr_id};
}


sub finalize {
    my $self = shift;

    $self->apply_all_params_loaded();

    delete $all_object_fabricators{$self};
    $self->{'all_params_loaded'} = undef;
}   


sub apply_all_params_loaded {
    my $self = shift;

    my $local_all_params_loaded = $self->{'all_params_loaded'};

    my @template_ids = keys %$local_all_params_loaded;
    foreach my $template_id ( @template_ids ) {
        my @rule_ids = keys %{$local_all_params_loaded->{$template_id}};
        foreach my $rule_id ( @rule_ids ) {
            my $val = $local_all_params_loaded->{$template_id}->{$rule_id};
            next unless exists $UR::Context::all_params_loaded->{$template_id}->{$rule_id};  # Has unload() removed this one earlier?
            $UR::Context::all_params_loaded->{$template_id}->{$rule_id} += $val;
        }
    }

    # Anything left in here is in-clause values that matched nothing.  Make a note in
    # all_params_loaded showing that so later queries for those values won't hit the 
    # data source
    my $in_clause_values = $self->{'in_clause_values'};
    my @properties = keys %$in_clause_values;
    foreach my $property ( @properties ) {
        my @values = keys %{$in_clause_values->{$property}};
        foreach my $value ( @values ) {
            my $data = $in_clause_values->{$property}->{$value};
            $UR::Context::all_params_loaded->{$data->[0]}->{$data->[1]} = 0;
        }
    }

    $self->{'all_params_loaded'} = {};
}


sub DESTROY {
    my $self = shift;
    # Don't apply the changes.  Maybe the importer closure just went out of scope before
    # it read all the data
    my $local_all_params_loaded = $self->{'all_params_loaded'};
    if ($local_all_params_loaded) {
        # finalize wasn't called on this iterator; maybe the importer closure went out
        # of scope before it read all the data.
        # Conditionally apply the changes from the local all_params_loaded.  If the Context's
        # all_params_loaded is defined, then another query has successfully run to
        # completion, and we should add our data to it.  Otherwise, we're the only query like
        # this and all_params_loaded should be cleaned out
        foreach my $template_id ( keys %$local_all_params_loaded ) {
            while(1) {
                my($rule_id, $val) = each %{$local_all_params_loaded->{$template_id}};
                last unless $rule_id;
                if (defined $UR::Context::all_params_loaded->{$template_id}->{$rule_id}) {
                    $UR::Context::all_params_loaded->{$template_id}->{$rule_id} += $val;
                } else {
                    delete $UR::Context::all_params_loaded->{$template_id}->{$rule_id};
                }
            }
        }
    }
    delete $all_object_fabricators{$self};
}

1;

=pod

=head1 NAME

UR::Context::ObjectFabricator - Track closures used to fabricate objects from data sources

=head1 DESCRIPTION

Object Fabricators are closures that accept listrefs of data returned by
data source iterators, take slices out of them, and construct UR objects
out of the results.  They also handle updating the query cache and merging 
changed DB data with previously cached objects.

UR::Context::ObjectFabricator objects are used internally by UR::Context,
and not intended to be used directly.

=head1 METHODS

=over 4

=item create_for_loading_template

  my $fab = UR::Context::ObjectFabricator->create_for_loading_template(
                $context, $loading_tmpl_hashref, $template_data,
                $rule, $rule_template, $values, $dsx);

Returns an object fabricator instance that is able to construct objects
of the rule's target class from rows of data returned by data source
iterators.  Object fabricators are used a part of the object loading
process, and are called by UR::Context::get_objects_for_class_and_rule()
to transform a row of data returned by a data source iterator into a UR
object.

For each class involved in a get request, the system prepares a loading
template that describes which columns of the data source data are to be
used to construct an instance of that class.  For example, in the case where
a get() is done on a child class, and the parent and child classes store data
in separate tables linked by a relation-property/foreign-key, then the query
against the data source will involve and SQL join (for RDBMS data sources).
That join will produce a result set that includes data from both tables.

The C<$loading_tmpl_hashref> will have information about which columns of
that result set map to which properties of each involved class.  The heart
of the fabricator closure is a list slice extracting the data for that class
and assigning it to a hash slice of properties to fill in the initial object
data for its class.  The remainder of the closure is bookkeeping to keep the
object cache ($UR::Context::all_objects_loaded) and query cache 
($UR::Context::all_params_loaded) consistent.

The interaction of the object fabricator, the query cache, object cache
pruner and object loading iterators that may or may not have loaded all
their data requires that the object fabricators keep a list of changes they
plan to make to the query cache instead of applying them directly.  When
the Underlying Context Loading iterator has loaded the last row from the
Data Source Iterator, it calls C<finalize()> on the object fabricator to
tell it to go ahead and apply its changes; essentially treating that
data as a transaction.

=item all_object_fabricators

  my @fabs = UR::Context::ObjectFabricator->all_object_fabricators();

Returns a list of all object fabricators that have not yet been finalized

=item fabricate

  my $ur_object = $fab->fabricate([columns,from,data,source]);

Given a listref of data pulled from a data source iterator, it slices out
the appropriate columns from the list and constructs a single object to
return.

=item is_loading_in_progress_for_boolexpr

    my $bool = $fab->is_loading_in_progress_for_boolexpr($boolexpr);

Given a UR::BoolExpr instance, it returns true if the given fabricator is
prepared to construct objects matching this boolexpr.  This is used by 
UR::Context to know if other iterators are still pulling in objects that
could match another iterator's boolexpr, and it should therefore not trust
that the object cache is conplete.

=item finalize

  $fab->finalize();

Indicates to the iterator that the caller is done using it for constructing
objects, probably because the data source has no more data or the iterator
that was using this fabricator has gone out of scope.

=item apply_all_params_loaded

  $fab->apply_all_params_loaded();

As the fabricator constructs objects, it buffers changes to all_params_loaded
(the Context's query cache) to maintain consistency if multiple iterators are
working concurrently.  At the appripriate time, call apply_all_params_loaded()
to take those changes and apply them to the current Context's all_params_loaded.

=back

=cut

