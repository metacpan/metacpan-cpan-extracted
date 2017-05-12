package UR::DataSource::QueryPlan;
use strict;
use warnings;
use UR;
our $VERSION = "0.46"; # UR $VERSION;

# this class is an evolving attempt to formalize
# the blob of cached value used for query construction

class UR::DataSource::QueryPlan {
    is => 'UR::Value',
    id_by => [ 
        rule_template => { is => 'UR::BoolExpr::Template', id_by => ['subject_class_name','logic_type','logic_detail','constant_values_id'] }, 
        data_source   => { is => 'UR::DataSource', id_by => 'data_source_id' },
    ],
    has => [
        limit         => { is => 'Integer', via => 'rule_template', to => 'limit' },
        offset        => { is => 'Integer', via => 'rule_template', to => 'offset' },
    ],
    has_transient => [
        _is_initialized => { is => 'Boolean' },

        needs_further_boolexpr_evaluation_after_loading => { is => 'Boolean' },
        
        # data tracked for the whole query by property,alias,join_id
        _delegation_chain_data                          => { is => 'HASH' },
        _alias_data                                     => { is => 'HASH' },
        _join_data                                      => { is => 'HASH' },

        # the old $alias_num
        _alias_count                                    => { is => 'Number' },
        
        # the old @sql_joins
        _db_joins                                       => { is => 'ARRAY' },
        
        # the new @obj_joins
        _obj_joins                                      => { is => 'ARRAY' },

        # the old all_table_properties, which has a small array of loading info
        _db_column_data                                 => { is => 'ARRAY' },

        # the old hashes by the same names
        _group_by_property_names                        => { is => 'HASH' },
        _order_by_property_names                        => { is => 'HASH' },

        _sql_filters    => { is => 'ARRAY' },
        _sql_params     => { is => 'ARRAY' },
        
        lob_column_names                            => {},
        lob_column_positions                        => {},
        query_config                                => {},
        post_process_results_callback               => {},
        
        select_clause                               => {},
        select_hint                                 => {},
        from_clause                                 => {},
        where_clause                                => {},
        connect_by_clause                           => {},
        group_by_clause                             => {},
        order_by_columns                            => {},
        order_by_non_column_data                    => {}, # flag that's true if asked to order_by something not in the data source
       
        sql_params                                  => {},
        filter_specs                                => {},
        
        property_names_in_resultset_order           => {},

        rule_template_id                            => {},
        rule_template_id_without_recursion_desc     => {},
        rule_template_without_recursion_desc        => {},

        joins                                       => {},
        recursion_desc                              => {},
        recurse_property_on_this_row                => {},
        recurse_property_referencing_other_rows     => {},
        recurse_resolution_by_iteration             => {},  # For data sources that don't support recursive queries
        
        joins_across_data_sources                   => {}, # context _resolve_query_plan_for_ds_and_bxt
        loading_templates                           => {},
        class_name                                  => {},
        rule_matches_all                            => {},
        rule_template_is_id_only                    => {},

        sub_typing_property                         => {},
        class_table_name                            => {},
        rule_template_specifies_value_for_subtype   => {},
        sub_classification_meta_class_name          => {},
    ]
};


sub _load {
        my $class = shift;
    my $rule = shift;

    # See if the requested object is loaded.
    my @loaded = $UR::Context::current->get_objects_for_class_and_rule($class,$rule,0);
    return $class->context_return(@loaded) if @loaded;

    # Auto generate the object on the fly.
    my $id = $rule->value_for_id;
    unless (defined $id) {
        #$DB::single = 1;
        Carp::croak "No id specified for loading members of an infinite set ($class)!"
    }
    my $class_meta = $class->__meta__;
    my @p = (id => $id);
    if (my $alt_ids = $class_meta->{id_by}) {
        if (@$alt_ids == 1) {
            push @p, $alt_ids->[0] => $id;
        }
        else {
            my ($rule, %extra) = UR::BoolExpr->resolve_normalized($class, $rule);
            push @p, $rule->params_list;
        }
    }

    my $obj = $UR::Context::current->_construct_object($class, @p);

    if (my $method_name = $class_meta->sub_classification_method_name) {
        my($rule, %extra) = UR::BoolExpr->resolve_normalized($class, $rule);
        my $sub_class_name = $obj->$method_name;
        if ($sub_class_name ne $class) {
            # delegate to the sub-class to create the object
            $UR::Context::current->_abandon_object($obj);
            $obj = $UR::Context::current->_construct_object($sub_class_name,$rule);
            $obj->__signal_change__("load");
            return $obj;
        }
        # fall through if the class names match
    }

    $obj->__signal_change__("load");
    return $obj;
}

# these hash keys are probably removable
# because they are not above, they will be deleted if _init sets them
# this exists primarily as a cleanup target list
my @extra = qw(
    id_properties
    direct_table_properties
    all_table_properties
    sub_classification_method_name
    subclassify_by
    properties_meta_in_resultset_order
    all_properties
    rule_specifies_id
    all_id_property_names
    id_property_sorter
    properties_for_params
    first_table_name
    base_joins
    parent_class_objects
);

sub _init {
    my $self = shift;
  
    Carp::confess("already initialized???") if $self->_is_initialized;

    # We could have this sub-classify by data source type, but right
    # now it's conditional logic because we'll likely remove the distinctions.
    # This will work because we'll separate out the ds-specific portion
    # and call methods on the DS to get that part.
    my $ds = $self->data_source;
    if ($ds->isa("UR::DataSource::RDBMS")) {
        $self->_init_light();
        $self->_init_rdbms();
    }
    elsif ($ds->isa('UR::DataSource::Filesystem')) {
        $self->_init_core();
        $self->_init_filesystem();
    }
    else {
        # Once all callers are using the API for this we won't need "_init".
        $self->_init_core();
        $self->_init_default() if $ds->isa("UR::DataSource::Default");
        #$self->_init_remote_cache() if $ds->isa("UR::DataSource::RemoteCache");
    }

    # This object is currently still used as a hashref, but the properties
    # are a declaration of the part of the hashref data we are still dependent upon.
    # This removes the other properties to ensure this is the case.
    # Next steps are to clean up the code below to not produce the data,
    # then this loop can throw an exception if extra untracked data is found.
    for my $key (keys %$self) {
        next if $self->can($key);
        delete $self->{$key};
    }

    $self->_is_initialized(1);
    return $self;
}


sub _determine_complete_order_by_list {
    my($self, $rule_template, $class_data, $db_property_data) = @_;

    my $class_meta       = $rule_template->subject_class_name->__meta__;
    my $order_by_columns = $class_data->{order_by_columns} || [];
    my $order_by         = $rule_template->order_by;
    my $ds               = $self->data_source;

    my %order_by_property_names;
    my $order_by_non_column_data;
    if ($order_by) {
        my %db_property_data_map = map { $_->[1]->property_name => $_ } @$db_property_data;

        # we only pull back columns we're ordering by if there is ordering happening
        my %is_descending;
        my @column_data;
        for my $name (@$order_by) {
            my $order_by_prop = $name;
            if ($order_by_prop =~ m/^(-|\+)(.*)$/) {
                $order_by_prop = $2;
                $is_descending{$order_by_prop} = $1 eq '-';
            }

            my($order_by_prop_meta) = $class_meta->_concrete_property_meta_for_class_and_name($order_by_prop);
            unless ($order_by_prop_meta) {
                Carp::croak("Cannot order by '$name': Class "
                            . $class_meta->class_name
                            . " has no property named '$order_by_prop'");
            }

            $name = ( $is_descending{$order_by_prop} ? '-' : '' ) . $order_by_prop_meta->property_name;
            if ($order_by_property_names{$name} = $db_property_data_map{$order_by_prop_meta->property_name}) {  # yes, single =
                push @column_data, $order_by_property_names{$name};

                my $table_column_names = $ds->_select_clause_columns_for_table_property_data($column_data[-1]);
                $is_descending{$table_column_names->[0]} = $is_descending{$order_by_prop}; # copy for table.column designation
                $order_by_property_names{$table_column_names->[0]} = $order_by_property_names{$name};
            } else {
                $order_by_non_column_data = 1;
            }
        }

        if (@column_data) {
            my $additional_order_by_columns = $ds->_select_clause_columns_for_table_property_data(@column_data);

            # Strip out columns named in the original $order_by_columns list that now appear in the
            # additional order by list so we don't duplicate columns names, and the additional columns
            # appear earlier in the list
            my %additional_order_by_columns = map { $_ => 1 } @$additional_order_by_columns;
            my @existing_order_by_columns = grep { ! $additional_order_by_columns{$_} } @$order_by_columns;
            $order_by_columns = [ map { $is_descending{$_} ? '-'. $_  : $_ } ( @$additional_order_by_columns, @existing_order_by_columns ) ];
        }
    }
    $self->_order_by_property_names(\%order_by_property_names);
    return ($order_by_columns, $order_by_non_column_data);
}


sub _init_rdbms {
    my $self = shift;
    my $rule_template = $self->rule_template;
    my $ds = $self->data_source;

    # class-based values
    my $class_name = $rule_template->subject_class_name;
    my $class_meta = $class_name->__meta__;
    my $class_data = $ds->_get_class_data_for_loading($class_meta);       

    my @parent_class_objects                = @{ $class_data->{parent_class_objects} };
    my @all_id_property_names               = @{ $class_data->{all_id_property_names} };
    my @id_properties                       = @{ $class_data->{id_properties} };   
    
    #my $first_table_name                    = $class_data->{first_table_name};
    
    #my $id_property_sorter                  = $class_data->{id_property_sorter};    
    #my @lob_column_names                    = @{ $class_data->{lob_column_names} };
    my @lob_column_positions                = @{ $class_data->{lob_column_positions} };
    #my $query_config                        = $class_data->{query_config}; 
    #my $post_process_results_callback       = $class_data->{post_process_results_callback};
    #my $class_table_name                    = $class_data->{class_table_name};

    # individual template based
    my $hints    = $rule_template->hints;
    my %hints    = map { $_ => 1 } @$hints;
    my $order_by = $rule_template->order_by;
    my $group_by = $rule_template->group_by;
    my $aggregate = $rule_template->aggregate;
    my $recursion_desc = $rule_template->recursion_desc;

    my ($first_table_name, @db_joins) =  _resolve_db_joins_for_inheritance($class_meta);
 
    $self->_db_joins(\@db_joins);
    $self->_obj_joins([]);

    # an array of arrays, containing $table_name, $column_name, $alias, $object_num
    # as joins are done we extend this, and then condense it into object fabricators
    my @db_property_data                    = @{ $class_data->{all_table_properties} };    

    my %group_by_property_names;
    if ($group_by) {
        # we only pull back columns we're grouping by or aggregating if there is grouping happening
        for my $name (@$group_by) {
            unless ($class_name->can($name)) {
                Carp::croak("Cannot group by '$name': Class $class_name has no property/method by that name");
            }
            $group_by_property_names{$name} = 1;
        }
        for my $data (@db_property_data) {
            my $name = $data->[1]->property_name;
            if ($group_by_property_names{$name}) {
                $group_by_property_names{$name} = $data;
            }
        }
        @db_property_data = grep { ref($_) } values %group_by_property_names; 
    }

    my($order_by_columns, $order_by_non_column_data)
        = $self->_determine_complete_order_by_list($rule_template, $class_data,\@db_property_data);

    $self->_db_column_data(\@db_property_data);
    $self->_group_by_property_names(\%group_by_property_names);

    # Find out what delegated properties we'll be dealing with
    my @sql_filters; 
    my @delegated_properties;
    do {
        my %filters =
            map { $_ => $rule_template->operator_for($_) }
            grep { substr($_,0,1) ne '-' }
            $rule_template->_property_names;

        unless (@all_id_property_names == 1 && $all_id_property_names[0] eq "id") {
            delete $filters{'id'};
        }

        # Remove the flag for descending/ascending sort
        my @order_by_properties = $order_by ? @$order_by : ();
        s/^-|\+//  foreach @order_by_properties;

        my %properties_involved = map { $_ => 1 }
                                    keys(%filters),
                                    ($hints ? @$hints : ()),
                                    @order_by_properties,
                                    ($group_by ? @$group_by : ());

        my @properties_involved = sort keys(%properties_involved);
        my @errors;
        while (my $property_name = shift @properties_involved) {
            if (index($property_name,'.') != -1) {
                push @delegated_properties, $property_name;
                next;
            }

            my (@pmeta) = $class_meta->property_meta_for_name($property_name);
            unless (@pmeta) {
                if ($class_name->can($property_name)) {
                    # method, not property
                    next;
                }
                else {
                    push @errors, "Class ".$class_meta->id." has no property or method named '$property_name'";
                    next;
                }
            }

            # For each property in this list, go up the inheritance and find the right property
            # to query on.  Give priority to properties that actually have columns
            FIND_PROPERTY_WITH_COLUMN:
            foreach my $pmeta ( @pmeta ) {
                foreach my $candidate_class ( $class_meta->all_class_metas ) {
                    my $candidate_prop_meta = UR::Object::Property->get(class_name => $candidate_class->class_name,
                                                                        property_name => $property_name);
                    next unless $candidate_prop_meta;
                    if ($candidate_prop_meta->column_name) {
                        $pmeta = $candidate_prop_meta;
                        next FIND_PROPERTY_WITH_COLUMN;
                    }
                }
            }

            my $property = $pmeta[0];
            my $table_name = $property->class_meta->first_table_name;
            my $operator       = $rule_template->operator_for($property_name);
            my $value_position = $rule_template->value_position_for_property_name($property_name);

            if ($property->can("expr_sql")) {
                unless ($table_name) {
                    $ds->warning_message("Property '$property_name' of class '$class_name' can 'expr_sql' but has no table!");
                    next;
                }
                my $expr_sql = $property->expr_sql;
                if (exists $filters{$property_name}) {
                    my @coercion = $self->data_source->cast_for_data_conversion(
                                                            $property->_data_type_as_class_name,
                                                            'UR::Value::String', # We can't know here what the type should be
                                                            $operator,
                                                            'where');
                    push @sql_filters, 
                        $table_name => { 
                            # cheap hack of prefixing with a whitespace differentiates 
                            # from a regular column below
                            " " . $expr_sql => {
                                        operator => $operator,
                                        value_position => $value_position,
                                        left_coercion => $coercion[0],
                                        right_coercion => $coercion[1],
                                    }
                        };
                }
                next;
            }

            # If the property is calculate and has a calculate_from list, add the
            # calculate_from things to the internal hints list, but not the template
            if ($property->is_calculated and $property->calculate_from) {
                my $calculate_from = $property->calculate_from;
                push @properties_involved, @$calculate_from;
                push @$hints, @$calculate_from;
                $hints{$_} = 1 foreach @$calculate_from;
            }

            if (exists($filters{$property_name}) and $filters{$property_name} eq 'isa') {
                # RDBMS databases can't do 'isa'
                $self->needs_further_boolexpr_evaluation_after_loading(1);
                next;
            }
            elsif (my $column_name = $property->column_name) {
                # normal column: filter on it
                unless ($table_name) {
                    $ds->warning_message("Property '$property_name' of class '$class_name'  has column '$column_name' but has no table!");
                    next;
                }
                if (exists $filters{$property_name}) {
                    my @coercion = $self->data_source->cast_for_data_conversion(
                                                            $property->_data_type_as_class_name,
                                                            'UR::Value::String', # We can't know here what the type should be
                                                            $operator,
                                                            'where');
                    push @sql_filters, 
                        $table_name => { 
                            $column_name => {
                                    operator => $operator,
                                    value_position => $value_position,
                                    left_coercion => $coercion[0],
                                    right_coercion => $coercion[1],
                                }
                        };
                }
            }
            elsif ($property->is_delegated) {
                push @delegated_properties, $property->property_name;
            }
            elsif ( ! exists($hints{$property_name}) or exists($filters{$property_name}) ) {
                $self->needs_further_boolexpr_evaluation_after_loading(1);
            }
            else {
                next;
            }

        } # end of properties in the expression which control the query content 

        if (@errors) { 
            my $class_name = $class_meta->class_name;
            $ds->error_message("ERRORS PROCESSING PARAMTERS: (" . join("\n", @errors) . ") used to generate SQL for $class_name!");
            #print Data::Dumper::Dumper($rule_template);
            Carp::croak("Can't continue");
        }
    };

    my $object_num = 0; 
    $self->_alias_count(0);

    my %hints_included;
    my @select_hint;

    # FIXME - this needs to be broken out into delegated-property-join-resolver
    # and inheritance-join-resolver methods that can be called recursively.
    # It would better encapsulate what's going on and avoid bugs with complicated
    # get()s

    # one iteration per target value involved in the query,
    # including values needed for filtering, ordering, grouping, and hints (selecting more)
    # these "properties" may be a single property name or an ad-hoc "chain"
    DELEGATED_PROPERTY:
    for my $delegated_property (sort @delegated_properties) {
        my $property_name = $delegated_property;
        my $delegation_chain_data           = $self->_delegation_chain_data || $self->_delegation_chain_data({});
        $delegation_chain_data->{"__all__"}{table_alias} = {};
        $delegation_chain_data->{"__all__"}{class_alias} = { $first_table_name => $class_meta };

        my ($final_accessor, $is_optional, @joins) = _resolve_object_join_data_for_property_chain($rule_template,$property_name,$property_name);

        # when there is no "final_accessor" it often means we have an object-accessor in a hint
        # we want that to go through the join process, and only be left out at filter construction time
        #unless ($final_accessor) {
            #$self->needs_further_boolexpr_evaluation_after_loading(1);
            #next;
        #}

        # this is gathered here and used below, but previously was gathered internally to the methods which take it
        # since it is no longer needed directly in this method it might be refactored into the places which use it
        my %ds_for_class;
        for my $join (@joins) {
            my $source_class_object = $join->{'source_class'}->__meta__;
            my ($source_data_source) = UR::Context->resolve_data_sources_for_class_meta_and_rule($source_class_object, $rule_template);
            $ds_for_class{$join->{'source_class'}} = $source_data_source;
            
            my $foreign_class_object = $join->{'foreign_class'}->__meta__;
            my ($foreign_data_source) = UR::Context->resolve_data_sources_for_class_meta_and_rule($foreign_class_object, $rule_template);
            $ds_for_class{$join->{'foreign_class'}} = $foreign_data_source;
        }


        # Splice out joins that go through a UR::Value class and back out to the DB, since UR::Value-types
        # don't get stored in the DB
        # TODO: move this into the join creation logic
        for (my $i = 0; $i < @joins; $i++) {
            if (
                $i < $#joins
                and 
                (
                    # db -> UR::Value -> db : shortcut
                    $joins[$i]->{'foreign_class'}->isa('UR::Value')
                    and $joins[$i+1]->{'source_class'}->isa('UR::Value')
                    #and $joins[$i]->{'foreign_class'}->isa($joins[$i+1]->{'source_class'})  ## remove this?
                )
            ) { 
                my $fixed_join = UR::Object::Join->_get_or_define(
                                      source_class => $joins[$i]->{'source_class'},
                                      source_property_names => $joins[$i]->{'source_property_names'},
                                      foreign_class => $joins[$i+1]->{'foreign_class'},
                                      foreign_property_names => $joins[$i+1]->{'foreign_property_names'},
                                      is_optional => $joins[$i]->{'is_optional'},
                                      id => $joins[$i]->{id} . "->" . $joins[$i+1]->{id});
                if ($joins[$i+1]->{where}) {
                    # If there's a where involved, it will always be on the second thing,
                    # where the foreign_class is NOT a UR::Value
                    $fixed_join->{where} = $joins[$i+1]->{where};
                }
                splice(@joins, $i, 2, $fixed_join);
            }
        }

        if (@joins and $joins[-1]{foreign_class}->isa("UR::Value")) {
            # the final join in a chain is often the link between a primitive value
            # and the UR::Value subclass into which it falls ...irrelevent for db joins
            $final_accessor = $joins[-1]->source_property_names->[0]; 
            pop @joins;
            next DELEGATED_PROPERTY unless @joins;
        }

        my $last_class_object_excluding_inherited_joins;
        my $alias_for_property_value;

        # one iteration per table between the start table and target
        while (my $object_join = shift @joins) { 
            $object_num++;
            my @joins_for_object = ($object_join);

            # one iteration per layer of inheritance for this object 
            # or per case of a join having additional filtering
            my $current_inheritance_depth_for_this_target_join = 0;
            while (my $join = shift @joins_for_object) { 

                my $where = $join->{where};

                $current_inheritance_depth_for_this_target_join++;

                my $foreign_class_name = $join->{foreign_class};
                my $foreign_class_object = $join->{'foreign_class_meta'} || $foreign_class_name->__meta__;

                if ($foreign_class_object->join_hint and !($hints_included{$foreign_class_name}++)) {
                    push @select_hint, $foreign_class_object->join_hint;
                }

                if (not exists $ds_for_class{$foreign_class_name}) {
                    # error: we should have at least a key with an empty value if we tried to find the ds
                    die "no data source key for $foreign_class_name when adding a join?"
                }

                my $ds = $ds_for_class{$foreign_class_name};

                if (not $ds) {
                    # no ds for the next piece of data: we will have to resolve this on the client side
                    # this is where things may get slow if the query is insufficiently filtered
                    $self->needs_further_boolexpr_evaluation_after_loading(1);
                    next DELEGATED_PROPERTY;
                }

                my $alias = $self->_add_join(
                    $delegated_property,
                    $join,
                    $object_num,
                    $is_optional,
                    $final_accessor,
                    $ds_for_class{$foreign_class_name},
                );

                if (not $alias) {
                    # unable to add a join for another reason
                    # TODO: is the above the only valid case of a join being impossible?
                    # Can we remove this?
                    $self->needs_further_boolexpr_evaluation_after_loading(1);
                    next DELEGATED_PROPERTY;
                }

                # set these for after all of the joins are done
                my $last_class_name = $foreign_class_name;
                my $last_class_object = $foreign_class_object;

                # on the first iteration, we figure out the remaining inherited iterations
                # if there is inheritance to do, unshift those onto the stack ahead of other things
                if ($current_inheritance_depth_for_this_target_join == 1) {
                    if ($final_accessor and $last_class_object->property_meta_for_name($final_accessor)) {
                        $last_class_object_excluding_inherited_joins = $last_class_object;
                    }
                    my @parents = grep { $_->table_name } $foreign_class_object->ancestry_class_metas;
                    if (@parents) {
                        my @last_id_property_names = $foreign_class_object->id_property_names;
                        for my $parent (@parents) {
                            my @parent_id_property_names = $parent->id_property_names;
                            die if @parent_id_property_names > 1;
                            my $parent_join_foreign_class_name = $parent->class_name;
                            my $inheritance_join = UR::Object::Join->_get_or_define( 
                                source_class => $last_class_name,
                                source_property_names => [@last_id_property_names], # we change content below
                                foreign_class => $parent_join_foreign_class_name,
                                foreign_property_names => \@parent_id_property_names,
                                is_optional => $is_optional,
                                id => "${last_class_name}::" . join(',',@last_id_property_names),
                            );
                            unshift @joins_for_object, $inheritance_join; 
                            @last_id_property_names = @parent_id_property_names;
                            $last_class_name = $foreign_class_name;

                            my $foreign_class_object = $parent_join_foreign_class_name->__meta__;
                            my ($foreign_data_source) = UR::Context->resolve_data_sources_for_class_meta_and_rule($foreign_class_object, $rule_template);
                            $ds_for_class{$parent_join_foreign_class_name} = $foreign_data_source;
                        }
                        next;
                    }
                }

                if (!@joins and not $alias_for_property_value) {
                    # we are out of joins for this delegated property
                    # setting $alias_for_property_value helps map to exactly where we do real filter/order/etc.
                    my $foreign_class_loading_data = $ds->_get_class_data_for_loading($foreign_class_object);
                    if ($final_accessor and
                        grep { $_->[1]->property_name eq $final_accessor } @{ $foreign_class_loading_data->{direct_table_properties} }
                    ) {
                        $alias_for_property_value = $alias;
                        #print "found alias for $property_name on $foreign_class_name: $alias\n";
                    }
                    else {
                        # The thing we're joining to isn't a database-backed column (maybe calculated?)
                        $self->needs_further_boolexpr_evaluation_after_loading(1);
                        next DELEGATED_PROPERTY;
                    }
                }

            } # next join in the inheritance for this object

        } # next join across objects from the query subject to the delegated property target

        # done adding any new joins for this delegated property/property-chain

        # now see if anything in the where-clause needs to filter on the item joined-to
        my $value_position = $rule_template->value_position_for_property_name($property_name);
        if (defined $value_position) {
            # this property _is_ used to filter results 
            if (not $final_accessor) {
                # on the client side :(
                $self->needs_further_boolexpr_evaluation_after_loading(1);
                next;
            }
            else {
                # at the database level :)
                my $final_accessor_property_meta = $last_class_object_excluding_inherited_joins->property_meta_for_name($final_accessor);
                unless ($final_accessor_property_meta) {
                    Carp::croak("No property metadata for property named '$final_accessor' in class "
                                . $last_class_object_excluding_inherited_joins->class_name
                                . " while resolving joins for property '" . $delegated_property->property_name . "' in class "
                                . $delegated_property->class_name);
                }

                my $sql_lvalue;
                if ($final_accessor_property_meta->is_calculated) {
                    $sql_lvalue = $final_accessor_property_meta->calculate_sql;
                    unless (defined($sql_lvalue)) {
                        $self->needs_further_boolexpr_evaluation_after_loading(1);
                        next;
                    }
                }
                else {
                    $sql_lvalue = $final_accessor_property_meta->column_name;
                    unless (defined($sql_lvalue)) {
                        Carp::confess("No column name set for non-delegated/calculated property $property_name of $class_name");
                    }
                }

                my $operator       = $rule_template->operator_for($property_name);

                unless ($alias_for_property_value) {
                    die "No alias found for $property_name?!";
                }

                my @coercion = $self->data_source->cast_for_data_conversion(
                                                        $final_accessor_property_meta->_data_type_as_class_name,
                                                        'UR::Value::String', # We can't know here what the type should be
                                                        $operator,
                                                        'where');

                push @sql_filters, 
                    $alias_for_property_value => { 
                        $sql_lvalue => {
                            operator => $operator,
                            value_position => $value_position,
                            left_coercion => $coercion[0],
                            right_coercion => $coercion[1],
                         }
                    };
            }
        }
        
    } # next delegated property

    # the columns to query
    my $db_property_data = $self->_db_column_data;

    # the following two sets of variables hold the net result of the logic
    my $select_clause;
    my $from_clause;
    my $connect_by_clause;
    my $group_by_clause;

    # Build the SELECT clause explicitly.
    $select_clause = $ds->_select_clause_for_table_property_data(@$db_property_data);

    # Oracle places group_by in a comment in the select 
    unshift(@select_hint, $class_meta->select_hint) if $class_meta->select_hint;

    # Build the FROM clause base.
    # Add joins to the from clause as necessary, then
    $from_clause = (defined $first_table_name ? "$first_table_name" : '');        

    my $cnt = 0;
    my @sql_params;
    my @sql_joins = @{ $self->_db_joins };
    while (@sql_joins) {
        my $table_name = shift (@sql_joins);
        my $condition  = shift (@sql_joins);
        my ($table_alias) = ($table_name =~ /(\S+)\s*$/s);

        my $join_type;
        if ($condition->{-is_required}) {
            $join_type = 'INNER';
        }
        else {
            $join_type = 'LEFT';
        }

        $from_clause .= "\n$join_type join " . $table_name . " on ";
        # Restart the counter on each join for the from clause,
        # but for the where clause keep counting w/o reset.
        $cnt = 0;

        for my $column_name (keys %$condition) {
            next if substr($column_name,0,1) eq '-';

            my $linkage_data = $condition->{$column_name};
            my $expr_sql = (substr($column_name,0,1) eq " " ? $column_name : "${table_alias}.${column_name}");
            my ($operator, $value_position, $value, $link_table_name, $link_column_name, $left_coercion, $right_coercion)
                = @$linkage_data{qw/operator value_position value link_table_name link_column_name left_coercion right_coercion/};

            $expr_sql = sprintf($right_coercion, $expr_sql) if ($right_coercion);

            $from_clause .= "\n    and " if ($cnt++);

            if ($link_table_name and $link_column_name) {
                # the linkage data is a join specifier
                my $link_sql = "${link_table_name}.${link_column_name}";
                $link_sql = sprintf($left_coercion, $link_sql) if ($left_coercion);
                $from_clause .= "$link_sql = $expr_sql";
            }
            elsif (defined $value_position) {
                Carp::croak("Joins cannot use variable values currently!");
            }
            else {
                my ($more_sql, @more_params) = $ds->_extend_sql_for_column_operator_and_value($expr_sql, $operator, $value);   
                if ($more_sql) {
                    $from_clause .= $more_sql;
                    push @sql_params, @more_params;
                }
                else {
                    # error
                    return;
                }
            }
        } # next column
    } # next db join

    # build the WHERE clause by making a data structure which will be parsed outside of this module
    # special handling of different size lists, and NULLs, make a completely reusable SQL template very hard.
    my @filter_specs;
    while (@sql_filters) {
        my $table_name = shift (@sql_filters);
        my $condition  = shift (@sql_filters);
        my ($table_alias) = ($table_name =~ /(\S+)\s*$/s);

        for my $column_name (keys %$condition) {
            my $linkage_data = $condition->{$column_name};
            my $expr_sql = (substr($column_name,0,1) eq " " ? $column_name : "${table_alias}.${column_name}");                                
            my ($operator, $value_position, $value, $link_table_name, $link_column_name, $left_coercion, $right_coercion)
                = @$linkage_data{qw/operator value_position value link_table_name
                                    link_column_name left_coercion right_coercion/};

            if ($link_table_name and $link_column_name) {
                # the linkage data is a join specifier
                Carp::confess("explicit column linkage in where clause?");
                #$sql .= "${link_table_name}.${link_column_name} = $expr_sql";
            }
            else {         
                # the linkage data is a value position from the @values list       
                unless (defined $value_position) {
                    Carp::confess("No value position for $column_name in query!");
                }                

                $expr_sql = sprintf($left_coercion, $expr_sql);

                push @filter_specs, [$expr_sql, $operator, $value_position];
            }
        } # next column                
    } # next db filter

    $connect_by_clause = ''; 
    my $recurse_resolution_by_iteration = 0;
    if ($recursion_desc) {
        unless (ref($recursion_desc) eq 'ARRAY') {
            Carp::croak("Recursion description must be an arrayref with exactly 2 items");
        }
        if (@$recursion_desc != 2) {
            Carp::croak("Recursion description must contain exactly 2 items; got ".scalar(@$recursion_desc)
                        . ': ' . join(', ',@$recursion_desc));
        }

        # Oracle supports "connect by" queries.
        if ($ds->does_support_recursive_queries eq 'connect by') {
            my ($this,$prior) = @{ $recursion_desc };

            my $this_property_meta = $class_meta->property_meta_for_name($this);
            unless ($this_property_meta) {
                Carp::croak("Class ".$class_meta->class_name." has no property named '$this', named in the recursion description");
            }
            my $prior_property_meta = $class_meta->property_meta_for_name($prior);
            unless ($prior_property_meta) {
                Carp::croak("Class ".$class_meta->class_name." has no property named '$prior', named in the recursion description");
            }

            my $this_class_meta = $this_property_meta->class_meta;
            my $prior_class_meta = $prior_property_meta->class_meta;

            my $this_table_name = $this_class_meta->table_name;
            unless ($this_table_name) {
                Carp::croak("Cannot resolve table name from class ".$class_meta->class_name." and property '$this', named in the recursion description");
            }
            my $prior_table_name = $prior_class_meta->table_name;
            unless ($prior_table_name) {
                Carp::croak("Cannot resolve table name from class ".$class_meta->class_name." and property '$prior', named in the recursion description");
            }

            my $this_column_name = $this_property_meta->column_name || $this;
            my $prior_column_name = $prior_property_meta->column_name || $prior;

            $connect_by_clause = "connect by $this_table_name.$this_column_name = prior $prior_table_name.$prior_column_name\n";
        } else {
            $recurse_resolution_by_iteration = 1;
        }
    }    

    my @property_names_in_resultset_order;
    for my $property_meta_array (@$db_property_data) {
        push @property_names_in_resultset_order, $property_meta_array->[1]->property_name; 
    }

    # this is only used when making a real instance object instead of a "set"
    my $per_object_in_resultset_loading_detail;
    unless ($group_by) {
        $per_object_in_resultset_loading_detail = $ds->_generate_loading_templates_arrayref(\@$db_property_data, $self->_obj_joins);
    }

    if ($group_by) {
        # when grouping, we're making set objects instead of regular objects
        # this means that we re-constitute the select clause and add a group_by clause
        $group_by_clause = 'group by ' . $select_clause if (scalar(@$group_by));

        # Q: - does it even make sense for the user to specify an order_by in the
        #    get() request for Set objects?  If so, then we need to concatonate these order_by_columns
        #    with the ones that already exist in $order_by_columns from the class data
        # A: - yes, because group by means "return a list of subsets", and this lets you sort the subsets
        $order_by_columns = $ds->_select_clause_columns_for_table_property_data(@$db_property_data);

        $select_clause .= ', ' if $select_clause;
        $select_clause .= 'count(*) count';
        for my $ag (@$aggregate) {
            next if $ag eq 'count';
             # TODO: translate property names to column names, and skip non-column properties 
            $select_clause .= ', ' . $ag;
        }
        unless (@$group_by == @$db_property_data) {
            print "mismatch table properties vs group by!\n";
        }
    }

    %$self = (
        %$self,

        # custom for RDBMS
        select_clause                               => $select_clause,
        select_hint                                 => scalar(@select_hint) ? \@select_hint : undef,
        from_clause                                 => $from_clause,        
        connect_by_clause                           => $connect_by_clause,
        group_by_clause                             => $group_by_clause,
        order_by_columns                            => $order_by_columns,        
        order_by_non_column_data                    => $order_by_non_column_data,
        filter_specs                                => \@filter_specs,
        sql_params                                  => \@sql_params,
        recurse_resolution_by_iteration             => $recurse_resolution_by_iteration,

        # override defaults in the regular datasource $parent_template_data
        property_names_in_resultset_order           => \@property_names_in_resultset_order,
        properties_meta_in_resultset_order          => $db_property_data,  # duplicate?!
        loading_templates                           => $per_object_in_resultset_loading_detail,
    );

    my $template_data = $rule_template->{loading_data_cache} = $self; 
    return $self;
}

sub _init_filesystem {
    my $self = shift;
    my $rule_template = $self->rule_template;
    my $ds = $self->data_source;

    # class-based values
    my $class_name = $rule_template->subject_class_name;
    my $class_meta = $class_name->__meta__;
    my $class_data = $ds->_get_class_data_for_loading($class_meta);

    my @db_property_data                    = @{ $class_data->{all_table_properties} };

    my($order_by_columns, $order_by_non_column_data)
        = $self->_determine_complete_order_by_list($rule_template, $class_data, \@db_property_data);

    %$self = (
        %$self,

        order_by_columns            => $order_by_columns,
        order_by_non_column_data    => $order_by_non_column_data,
    );

    my $template_data = $rule_template->{loading_data_cache} = $self;
    return $self;
}

sub _add_join {
    my ($self, 
        $property_name,
        $join,
        $object_num,
        $is_optional,
        $final_accessor,
        $foreign_data_source,
    ) = @_;

    my $delegation_chain_data           = $self->_delegation_chain_data || $self->_delegation_chain_data({});
    my $table_alias                     = $delegation_chain_data->{"__all__"}{table_alias} ||= {};
    my $source_table_and_column_names   = $delegation_chain_data->{$property_name}{latest_source_table_and_column_names} ||= [];

    my $source_class_name = $join->{source_class};
    my $source_class_object = $join->{'source_class_meta'} || $source_class_name->__meta__;                    

    my $class_alias                     = $delegation_chain_data->{"__all__"}{class_alias} ||= {};
    if (! %$class_alias and $source_class_object->table_name) {
        $class_alias->{$source_class_object->table_name} = $source_class_object;
    }

    my $foreign_class_name = $join->{foreign_class};
    my $foreign_class_object = $join->{'foreign_class_meta'} || $foreign_class_name->__meta__;

    my $rule_template = $self->rule_template;
    my $ds = $self->data_source;

    my $group_by = $rule_template->group_by;
    
    #my($foreign_data_source) = UR::Context->resolve_data_sources_for_class_meta_and_rule($foreign_class_object, $rule_template);
    if (!$foreign_data_source or ($foreign_data_source ne $ds)) {
        # FIXME - do something smarter in the future where it can do a join-y thing in memory
        $self->needs_further_boolexpr_evaluation_after_loading(1);
        return; 
    }

    my $foreign_class_loading_data = $ds->_get_class_data_for_loading($foreign_class_object);

    # This will get filled in during the first pass, and every time after we've successfully
    # performed a join - ie. that the delegated property points directly to a class/property
    # that is a real table/column, and not a tableless class or another delegated property
    my @source_property_names;
    unless (@$source_table_and_column_names) {
        @source_property_names = @{ $join->{source_property_names} };

        @$source_table_and_column_names =
            map {
                if (my($view, $alias) = $ds->parse_view_and_alias_from_inline_view($_->[0])) {
                    # This "table_name" was actually a bit of SQL with an inline view and an alias
                    $_->[0] = $view;
                    $_->[2] = $alias;
                }
                $_;
            }
            map {
                my($p) = $source_class_object->_concrete_property_meta_for_class_and_name($_);
                unless ($p) {
                    Carp::croak("No property $_ for class ".$source_class_object->class_name);
                }
                my($table_name,$column_name) = $p->table_and_column_name_for_property();
                if ($table_name && $column_name) {
                    [$table_name, $column_name];
                } else {
                    #Carp::confess("Can't determine table and column for property $_ in class " .
                    #              $source_class_object->class_name);
                    ();
                }
            }
            @source_property_names;
    }
    return unless @$source_table_and_column_names;

    #my @source_property_names = @{ $join->{source_property_names} };
    #my ($source_table_name, $fcols, $fprops) = $self->_resolve_table_and_column_data($source_class_object, @source_property_names);
    #my @source_column_names = @$fcols;
    #my @source_property_meta = @$fprops;

    my @foreign_property_names = @{ $join->{foreign_property_names} };
    my ($foreign_table_name, $fcols, $fprops) = $self->_resolve_table_and_column_data($foreign_class_object, @foreign_property_names);
    my @foreign_column_names = @$fcols;
    my @foreign_property_meta = @$fprops;
    
    unless (@foreign_column_names) {
        # all calculated properties: don't try to join any further
        return;
    }

    unless ($foreign_table_name) {
        # If we can't make the join because there is no datasource representation
        # for this class, we're done following the joins for this property
        # and will NOT try to filter on it at the datasource level
        $self->needs_further_boolexpr_evaluation_after_loading(1);
        return; 
    }
    
    unless (@foreign_column_names == @foreign_property_meta) {
        # some calculated properties, be sure to re-check for a match after loading the object
        $self->needs_further_boolexpr_evaluation_after_loading(1);
    }

    my $alias = $self->_get_join_alias($join, $property_name);

    unless ($alias) {
        my $alias_num = $self->_alias_count($self->_alias_count+1);
        
        my $alias_name = $join->sub_group_label || $property_name;
        if (substr($alias_name,-1) eq '?') {
            chop($alias_name) if substr($alias_name,-1) eq '?';
        }

        my $alias_length = length($alias_name)+length($alias_num)+1;
        my $alias_max_length = 29;
        if ($alias_length > $alias_max_length) {
            $alias = substr($alias_name,0,$alias_max_length-length($alias_num)-1); 
        }
        else {
            $alias = $alias_name;
        }
        $alias =~ s/\./_/g;
        $alias .= '_' . $alias_num; 

        $self->_set_join_alias($join, $property_name, $alias);

        if ($foreign_class_object->table_name) {
            my @extra_db_filters;
            my @extra_obj_filters;

            # TODO: when "flatten" correctly feeds the "ON" clause we can remove this
            # This will crash if the "where" happens to use indirect things 
            my $where = $join->{where};
            if ($where) {
                for (my $n = 0; $n < @$where; $n += 2) {
                    my $key =$where->[$n];
                    my ($name,$op) = ($key =~ /^(\S+)\s*(.*)/);

                    if(index($name, '-') == 0) {
                        #skip '-order_by', '-hint' and the like for joins
                        next;
                    }

                    #my $meta = $foreign_class_object->property_meta_for_name($name);
                    #my $column = $meta->is_calculated ? (defined($meta->calculate_sql) ? ($meta->calculate_sql) : () ) : ($meta->column_name);
                    my ($table_name, $column_names, $property_metas) = $self->_resolve_table_and_column_data($foreign_class_object, $name);
                    my $column = $column_names->[0];

                    if (not $column) {
                        Carp::confess("No column for $foreign_class_object->{id} $name?  Indirect property flattening must be enabled to use indirect filters in where with via/to.");
                    }

                    my $value = $where->[$n+1];
                    push @extra_db_filters, $column => { value => $value, ($op ? (operator => $op) : ()) };
                    push @extra_obj_filters, $name  => { value => $value, ($op ? (operator => $op) : ()) };
                }
            }

            my @db_join_data;
            for (my $n = 0; $n < @foreign_column_names; $n++) {

                my $link_table_name = $table_alias->{$source_table_and_column_names->[$n][0]}
                                    || $source_table_and_column_names->[$n][2]
                                    || $source_table_and_column_names->[$n][0];

                my $link_column_name = $source_table_and_column_names->[$n][1];
                
                my $foreign_column_name = $foreign_column_names[$n];

                my $link_class_meta = $class_alias->{$link_table_name} || $source_class_object;
                my $link_property_name = $link_class_meta->property_for_column($link_column_name);

                # _concrete_property_meta_for_class_and_name returns a list :(
                # since we're inspecting the joins by their "real" names and not the generic
                # "id", it will only ever return a 1-element list
                my($link_prop) = $link_class_meta->_concrete_property_meta_for_class_and_name($link_property_name);
                my $left_type = $link_prop->_data_type_as_class_name;
                my $right_type = $foreign_property_meta[$n]->_data_type_as_class_name;
                my @coercion = $self->data_source->cast_for_data_conversion($left_type, $right_type, '=', 'join');

                push @db_join_data,
                        $foreign_column_name => {
                            link_table_name     => $link_table_name,
                            link_column_name    => $link_column_name,
                            left_coercion       => $coercion[0],
                            right_coercion      => $coercion[1],
                        };
            }

            $self->_add_db_join(
                "$foreign_table_name $alias" => {
                    @db_join_data,
                    @extra_db_filters,
                }
            );
            
            $self->_add_obj_join( 
                "$alias" => {
                    (
                        map {
                            $foreign_property_names[$_] => {
                                link_class_name     => $source_class_name,
                                link_alias          => $table_alias->{$source_table_and_column_names->[$_][0]} # join alias
                                                        || $source_table_and_column_names->[$_][2]  # SQL inline view alias
                                                        || $source_table_and_column_names->[$_][0], # table_name
                                link_property_name    => $source_property_names[$_] 
                            }
                        }
                        (0..$#foreign_property_names)
                    ),
                    @extra_obj_filters,
                }
            );

            # Add all of the columns in the join table to the return list
            # Note that we increment the object numbers.
            # Note: we add grouping columns individually instead of in chunks
            unless ($group_by) {
                $self->_add_columns( 
                        map {
                            my $new = [@$_]; 
                            $new->[2] = $alias;
                            $new->[3] = $object_num; 
                            $new 
                        }
                        @{ $foreign_class_loading_data->{direct_table_properties} }
                );                
            }
        }


        if ($group_by) {
            if ($self->_groups_by_property($property_name)) {
                my ($p) = 
                    map {
                        my $new = [@$_]; 
                        $new->[2] = $alias;
                        $new->[3] = 0; 
                        $new 
                    }
                    grep { $_->[1]->property_name eq $final_accessor }
                    @{ $foreign_class_loading_data->{direct_table_properties} };
                $self->_add_columns($p); 
            }
        }


        if ($self->_orders_by_property($property_name)) {
            my ($p) = 
                map {
                    my $new = [@$_]; 
                    $new->[2] = $alias;
                    $new->[3] = 0; 
                    $new 
                }
                grep { $_->[1]->property_name eq $final_accessor }
                @{ $foreign_class_loading_data->{direct_table_properties} };
            # ??? what do we do here now with $p? 
        }

        unless ($is_optional) {
            # if _any_ part requires this, mark it required
            $self->_set_alias_required($alias); 
        }

    } # done adding a new join alias for a join which has not yet been done

    if ($foreign_class_object->table_name) {
        $table_alias->{$foreign_table_name} = $alias;
        $class_alias->{$alias} = $foreign_class_object;
        @$source_table_and_column_names = ();  # Flag that we need to re-derive this at the top of the loop
    }

    return $alias;
}

sub _resolve_table_and_column_data {
    my ($class, $class_meta, @property_names) = @_;
    my @property_meta = 
        map { $class_meta->_concrete_property_meta_for_class_and_name($_) }
        @property_names;
    my $table_name;
    my @column_names = 
        map {
            # TODO: encapsulate
            if ($_->is_calculated) {
                if ($_->calculate_sql) {
                    $_->calculate_sql;
                } else {
                    ();
                }
            } else {
                my $column_name;
                ($table_name, $column_name) = $_->table_and_column_name_for_property();
                $column_name;
            }
        }
        @property_meta;

    if ($table_name and $table_name =~ /^(.*)\s+(\w+)\s*$/s) {
        $table_name = $1;
    }

    return ($table_name, \@column_names, \@property_meta);
}

sub _set_join_alias {
    my ($self, $join, $property_name, $alias) = @_;
    $self->_join_data->{$join->id}{$property_name}{alias} = $alias;
    $self->_alias_data({}) unless $self->_alias_data();
    $self->_alias_data->{$alias}{join_id} = $join->id;
}

sub _get_join_alias {
    my ($self,$join,$property_name) = @_;
    $self->_join_data({}) unless $self->_join_data();
    return $self->_join_data->{$join->id}{$property_name}{alias};
}

sub _get_alias_join {
    my ($self,$alias) = @_;
    my $alias_data = $self->_alias_data;
    return if (! $alias_data or ! exists($alias_data->{$alias}));
    my $join_id = $self->_alias_data->{$alias}{join_id};
    UR::Object::Join->get($join_id);
}

sub _add_db_join {
    my ($self, $key, $data) = @_;
    
    my ($alias) = ($key =~/\w+$/);
    my $alias_data = $self->_alias_data || $self->_alias_data({});
    $alias_data->{$alias}{db_join} = $data;
    
    my $db_joins = $self->_db_joins || $self->_db_joins([]);
    push @$db_joins, $key, $data;
}

sub _add_obj_join {
    my ($self, $key, $data) = @_;
   
    Carp::confess() unless ref $data;
    my $alias_data = $self->_alias_data || $self->_alias_data({});
    $alias_data->{$key}{obj_join} = $data; # the key is the alias here
    
    my $obj_joins = $self->_obj_joins || $self->_obj_joins([]);
    push @$obj_joins, $key, $data;
}

sub _set_alias_required {
    my ($self, $alias) = @_;
    my $alias_data = $self->_alias_data || $self->_alias_data({});
    $alias_data->{$alias}{is_required} = 1;
    $alias_data->{$alias}{db_join}{-is_required} = 1;
    $alias_data->{$alias}{obj_join}{-is_required} = 1;
}

sub _add_columns {
    my $self = shift;
    my @new = @_;
    my $old = $self->_db_column_data;
    my $pos = @$old;
    my $lob_column_positions = $self->{lob_column_positions};
    my $lob_column_names = $self->{lob_column_names};
    for my $class_property (@new) {
        my ($sql_class,$sql_property,$sql_table_name) = @$class_property;
        my $data_type = $sql_property->data_type || '';             
        if ($data_type =~ /LOB$/) {
            push @$lob_column_names, $sql_property->column_name;
            push @$lob_column_positions, $pos;
        }
        $pos++;
    }
    push @$old, @new;
}

# Used by the object fabricator to find out which resultset column a
# property's data is stored
sub column_index_for_class_property_and_object_num {
    my($self, $class_name, $property_name, $object_num) = @_;

   $object_num ||= 0;

    my $db_column_data = $self->_db_column_data;
    for (my $resultset_col = 0; $resultset_col < @$db_column_data; $resultset_col++) {
        if ($db_column_data->[$resultset_col]->[1]->class_name eq $class_name
            and $db_column_data->[$resultset_col]->[1]->property_name eq $property_name
            and $db_column_data->[$resultset_col]->[3] == $object_num
        ) {
            return $resultset_col;
        }
    }
    return undef;
}

# used by the object fabricator to determine the resultset column
# the source property of a join is stored.
sub column_index_for_class_and_property_before_object_num {
    my($self, $class_name, $property_name, $object_num) = @_;
    return unless $object_num;

    my $db_column_data = $self->_db_column_data;
    my $index;
    for (my $resultset_col = 0; $resultset_col < @$db_column_data; $resultset_col++) {
        last if ($db_column_data->[$resultset_col]->[3] >= $object_num);
        if ($db_column_data->[$resultset_col]->[1]->class_name eq $class_name
            and
            $db_column_data->[$resultset_col]->[1]->property_name eq $property_name
        ) {
            $index = $resultset_col;
        }
    }
    return $index;
}


sub _groups_by_property {
    my ($self, $property_name) = @_;
    return $self->_group_by_property_names->{$property_name};
}

sub _orders_by_property {
    my ($self, $property_name) = @_;
    return $self->_order_by_property_names->{$property_name};
}

sub _resolve_db_joins_for_inheritance {
    my $class_meta = $_[0];

    my $first_table_name;
    my @sql_joins;

    my $prev_table_name; 
    my $prev_id_column_name; 
    my $prev_property_meta;

    my @parent_class_objects  = $class_meta->ancestry_class_metas;

    my %seen;
    for my $co ( $class_meta, @parent_class_objects ) {
        my $class_name = $co->class_name;
        next if $seen{$class_name}++;

        my @id_property_objects = $co->direct_id_property_metas;
        my %id_properties = map { $_->property_name => 1 } @id_property_objects;
        my @id_column_names =
            map { $_->column_name }
            @id_property_objects;

        my $table_name = $co->table_name;
        if ($table_name) {
            $first_table_name ||= $table_name;
            if ($prev_table_name) {
                die "Database-level inheritance cannot be used with multi-value-id classes ($class_name)!" if @id_property_objects > 1;
                my $prev_table_alias;
                if ($prev_table_name =~ /.*\s+(\w+)\s*$/) {
                    $prev_table_alias = $1;
                }
                else {
                    $prev_table_alias = $prev_table_name;
                }

                my @coercion = $co->data_source->cast_for_data_conversion(
                                    $prev_property_meta->_data_type_as_class_name,
                                    $id_property_objects[0]->_data_type_as_class_name,
                                    '=',
                                    'join');
                push @sql_joins,
                    $table_name =>
                    {
                        $id_property_objects[0]->column_name => { 
                            link_table_name => $prev_table_alias, 
                            link_column_name => $prev_id_column_name,
                            left_coercion   => $coercion[0],
                            right_coercion  => $coercion[1],
                        },
                        -is_required => 1,
                    };
            }
            $prev_table_name = $table_name;
            $prev_id_column_name = $id_property_objects[0]->column_name;
            $prev_property_meta = $id_property_objects[0];
        }
    }

    return ($first_table_name, @sql_joins);
}

sub _resolve_object_join_data_for_property_chain {
    my ($rule_template, $property_name) = @_;
    my $class_meta = $rule_template->subject_class_name->__meta__;
    
    my @joins;
    my $is_optional;
    my $final_accessor;

    my @pmeta = $class_meta->_concrete_property_meta_for_class_and_name($property_name);

    my $last_class_meta = $class_meta;
    for my $meta (@pmeta) {
        if (!$meta) {
            Carp::croak "Can't resolve joins for ".$rule_template->subject_class_name . " property '$property_name': No property metadata found for that class and property_name";
        }
        #id is a special property that we want to look up, but isn't necessarily on a table
        #so if it aliases another property, we look at that instead
        if($meta->property_name eq 'id' and $meta->class_name eq 'UR::Object') {
            my @id_properties = grep {$_->class_name ne 'UR::Object'} $last_class_meta->id_properties;
            if(@id_properties == 1) {
                $meta = $id_properties[0];
                $last_class_meta = $meta->class_name->__meta__;
                next;
            }
            elsif (@id_properties > 1) {
                Carp::confess "can't join to class " . $last_class_meta->class_name . " with multiple id properties: @id_properties";
            }
        }
        if($meta->data_type and $meta->data_type =~ /::/) {
            $last_class_meta = UR::Object::Type->get($meta->data_type);
        } else {
            $last_class_meta = UR::Object::Type->get($meta->class_name);
        }
        last unless $last_class_meta;
    }

    # we can't actually get this from the joins because 
    # a bunch of optional things can be chained together to form
    # something non-optional
    $is_optional = 0;
    for my $pmeta (@pmeta) {
        push @joins, $pmeta->_resolve_join_chain();
        $is_optional = 1 if $pmeta->is_optional or $pmeta->is_many;
    }

    return unless @joins;
    return ($joins[-1]->{source_name_for_foreign}, $is_optional, @joins)
};

sub _init_light {
    my $self = shift;
    my $rule_template = $self->rule_template;
    my $ds = $self->data_source;

    my $class_name = $rule_template->subject_class_name;
    my $class_meta = $class_name->__meta__;
    my $class_data = $ds->_get_class_data_for_loading($class_meta);       

    my @parent_class_objects                = @{ $class_data->{parent_class_objects} };
    my @all_properties                      = @{ $class_data->{all_properties} };
    my $sub_classification_meta_class_name  = $class_data->{sub_classification_meta_class_name};
    my $subclassify_by    = $class_data->{subclassify_by};
    
    my @all_id_property_names               = @{ $class_data->{all_id_property_names} };
    my @id_properties                       = @{ $class_data->{id_properties} };   
    my $id_property_sorter                  = $class_data->{id_property_sorter};    
    my $sub_typing_property                 = $class_data->{sub_typing_property};
    my $class_table_name                    = $class_data->{class_table_name};
    
    my $recursion_desc = $rule_template->recursion_desc;
    my $recurse_property_on_this_row;
    my $recurse_property_referencing_other_rows;
    my $recurse_resolution_by_iteration;
    if ($recursion_desc) {
        ($recurse_property_on_this_row,$recurse_property_referencing_other_rows) = @$recursion_desc;        
        $recurse_resolution_by_iteration = ! $ds->does_support_recursive_queries;
    }        
    
    my $needs_further_boolexpr_evaluation_after_loading; 
    
    my $is_join_across_data_source;

    my @sql_params;
    my @filter_specs;         
    my @property_names_in_resultset_order;
    my $object_num = 0; # 0-based, usually zero unless there are joins
    
    my @filters = $rule_template->_property_names;
    my %filters =     
        map { $_ => 0 }
        grep { substr($_,0,1) ne '-' }
        @filters;
    
    unless (@all_id_property_names == 1 && $all_id_property_names[0] eq "id") {
        delete $filters{'id'};
    }
    
    my (
        @sql_joins,
        @sql_filters, 
        $prev_table_name, 
        $prev_id_column_name, 
        $pk_used,
        @delegated_properties,    
        %chain_delegates,
    );

    for my $key (keys %filters) {
        if (index($key,'.') != -1) {
            $chain_delegates{$key} = delete $filters{$key};
        }
    }

    for my $co ( $class_meta, @parent_class_objects ) {
        my $class_name = $co->class_name;
        last if ( ($class_name eq 'UR::Object') or (not $class_name->isa("UR::Object")) );
        my @id_property_objects = $co->direct_id_property_metas;
        if (@id_property_objects == 0) {
            @id_property_objects = $co->property_meta_for_name("id");
            if (@id_property_objects == 0) {
                Carp::confess("Couldn't determine ID properties for $class_name\n");
            }
        }
        my %id_properties = map { $_->property_name => 1 } @id_property_objects;
        my @id_column_names =
            map { $_->column_name }
            @id_property_objects;
        for my $property_name (sort keys %filters) {
            my $property = UR::Object::Property->get(class_name => $class_name, property_name => $property_name);
            next unless $property;
            my $operator       = $rule_template->operator_for($property_name);
            my $value_position = $rule_template->value_position_for_property_name($property_name);
            delete $filters{$property_name};
            $pk_used = 1 if $id_properties{ $property_name };
            if ($property->is_legacy_eav) {
                die "Old GSC EAV can be handled with a via/to/where/is_mutable=1";
            }
            elsif ($property->is_delegated) {
                push @delegated_properties, $property;
            }
            elsif ($property->is_calculated || $property->is_transient) {
                $needs_further_boolexpr_evaluation_after_loading = 1;
            }
            else {
                push @sql_filters, 
                    $class_name => 
                        { 
                            $property_name => { operator => $operator, value_position => $value_position }
                        };
            }
        }
        $prev_id_column_name = $id_property_objects[0]->column_name;
    } # end of inheritance loop
        
    if ( my @errors = keys(%filters) ) { 
        my $class_name = $class_meta->class_name;
        $ds->error_message('Unknown param(s) (' . join(',',@errors) . ") used to generate SQL for $class_name!");
        Carp::confess();
    }

    my $last_class_name = $class_name;
    my $last_class_object = $class_meta;        
    my $alias_num = 1;
    my %joins_done;
    my $joins_across_data_sources;

    DELEGATED_PROPERTY:
    for my $delegated_property (@delegated_properties) {
        my $last_alias_for_this_chain;
        my $property_name = $delegated_property->property_name;
        my @joins = $delegated_property->_resolve_join_chain($property_name);
        my $relationship_name = $delegated_property->via;
        unless ($relationship_name) {
           $relationship_name = $property_name;
           $needs_further_boolexpr_evaluation_after_loading = 1;
        }

        my $delegate_class_meta = $delegated_property->class_meta;
        my($via_accessor_meta) = $delegate_class_meta->_concrete_property_meta_for_class_and_name($relationship_name);
        next unless $via_accessor_meta;
        my $final_accessor = $delegated_property->to;            

        my $data_type = $via_accessor_meta->data_type;
        unless ($data_type) {
            Carp::croak "Can't resolve delegation for $property_name on class $class_name: via property $relationship_name has no data type";
        }

        my $data_type_meta = UR::Object::Type->get($via_accessor_meta->data_type);
        unless ($data_type_meta) {
            Carp::croak "No class meta data for " . $via_accessor_meta->data_type . 
                " while resolving property $property_name on class $class_name";
        }
        my($final_accessor_meta) = $data_type_meta->_concrete_property_meta_for_class_and_name(
                                             $final_accessor
                                         );
        unless ($final_accessor_meta) {
            Carp::croak("No property '$final_accessor' on class " . $via_accessor_meta->data_type .
                          " while resolving property $property_name on class $class_name");
        }

        # Follow the chain of via/to delegation down to where the data ultimately lives
        while($final_accessor_meta->is_delegated) {
            # May have been 'to' an id_by/id_class_by property.  Stop chaining and do two queries
            # If we had access to the value at this point, we could continue joining through that
            # value's class and id
            next DELEGATED_PROPERTY if ($final_accessor_meta->id_by or $final_accessor_meta->id_class_by);

            my $prev_accessor_meta = $final_accessor_meta;
            $final_accessor_meta = $final_accessor_meta->to_property_meta();
            unless ($final_accessor_meta) {
                Carp::croak("Can't resolve property '$final_accessor' of class " . $via_accessor_meta->data_type
                            . ": Resolution involved property '" . $prev_accessor_meta->property_name . "' of class "
                            . $prev_accessor_meta->class_name
                            . " which is delegated, but its via/to metadata does not resolve to a known class and property");
            }
        }
        $final_accessor = $final_accessor_meta->property_name;
        for my $join (@joins) {
            my $source_class_name = $join->{source_class};
            my $source_class_object = $join->{'source_class_meta'} || $source_class_name->__meta__;

            my $foreign_class_name = $join->{foreign_class};
            next DELEGATED_PROPERTY if ($foreign_class_name->isa('UR::Value'));
            my $foreign_class_object = $join->{'foreign_class_meta'} || $foreign_class_name->__meta__;
            my($foreign_data_source) = $UR::Context::current->resolve_data_sources_for_class_meta_and_rule($foreign_class_object, $rule_template);
            if (! $foreign_data_source) {
                $needs_further_boolexpr_evaluation_after_loading = 1;
                next DELEGATED_PROPERTY;

            } elsif ($foreign_data_source ne $ds or
                    ! $ds->does_support_joins or
                    ! $foreign_data_source->does_support_joins
                )
            {
                push(@{$joins_across_data_sources->{$foreign_data_source->id}}, $delegated_property);
                next DELEGATED_PROPERTY;
            }
            my @source_property_names = @{ $join->{source_property_names} };
            my @source_table_and_column_names = 
                map {
                    my($p) = $source_class_object->_concrete_property_meta_for_class_and_name($_);
                    unless ($p) {
                        Carp::confess("No property $_ for class $source_class_object->{class_name}\n");
                    }
                    unless ($p->class_name->__meta__) {
                        Carp::croak("Can't get class metadata for " . $p->class_name);
                    }
                    [$p->class_name->__meta__->class_name, $p->property_name];
                }
                @source_property_names;
            my $foreign_table_name = $foreign_class_name;
            unless ($foreign_table_name) {
                # If we can't make the join because there is no datasource representation
                # for this class, we're done following the joins for this property
                # and will NOT try to filter on it at the datasource level
                $needs_further_boolexpr_evaluation_after_loading = 1;
                next DELEGATED_PROPERTY;
            }
            my @foreign_property_names = @{ $join->{foreign_property_names} };
            my @foreign_property_meta = 
                map {
                    $foreign_class_object->_concrete_property_meta_for_class_and_name($_)
                }
                @foreign_property_names;
            
            my @foreign_column_names = 
                map {
                    # TODO: encapsulate
                    $_->is_calculated ? (defined($_->calculate_sql) ? ($_->calculate_sql) : () ) : ($_->property_name)
                }
                @foreign_property_meta;
                
            unless (@foreign_column_names) {
                # all calculated properties: don't try to join any further
                last;
            }
            unless (@foreign_column_names == @foreign_property_meta) {
                # some calculated properties, be sure to re-check for a match after loading the object
                $needs_further_boolexpr_evaluation_after_loading = 1;
            }
            my $alias = $joins_done{$join->{id}};
            unless ($alias) {            
                $alias = "${relationship_name}_${alias_num}";
                $alias_num++;
                $object_num++;
                
                push @sql_joins,
                    "$foreign_table_name $alias" =>
                        {
                            map {
                                $foreign_property_names[$_] => { 
                                    link_table_name     => $last_alias_for_this_chain || $source_table_and_column_names[$_][0],
                                    link_column_name    => $source_table_and_column_names[$_][1]
                                }
                            }
                            (0..$#foreign_property_names)
                        };
                    
                # Add all of the columns in the join table to the return list.                
                push @all_properties, 
                    map { [$foreign_class_object, $_, $alias, $object_num] }
                    map { $_->[1] }                    # These three lines are to get around a bug in perl
                    sort { $a->[0] cmp $b->[0] }       # 5.8's sort involving method calls within the sort
                    map { [ $_->property_name, $_ ] }  # sub that do sorts of their own
                    grep { defined($_->column_name) && $_->column_name ne '' }
                    UR::Object::Property->get( class_name => $foreign_class_name );
              
                $joins_done{$join->{id}} = $alias;
                
            }
            # Set these for after all of the joins are done
            $last_class_name = $foreign_class_name;
            $last_class_object = $foreign_class_object;
            $last_alias_for_this_chain = $alias;
        } # next join
        unless ($delegated_property->via) {
            next;
        }
        my($final_accessor_property_meta) = $last_class_object->_concrete_property_meta_for_class_and_name($final_accessor);
        unless ($final_accessor_property_meta) {
            Carp::croak("No property metadata for property named '$final_accessor' in class " . $last_class_object->class_name
                        . " while resolving joins for property '" .$delegated_property->property_name . "' in class "
                        . $delegated_property->class_name);
        }
        my $sql_lvalue;
        if ($final_accessor_property_meta->is_calculated) {
            $sql_lvalue = $final_accessor_property_meta->calculate_sql;
            unless (defined($sql_lvalue)) {
                $needs_further_boolexpr_evaluation_after_loading = 1;
                next;
            }
        }
        else {
            $sql_lvalue = $final_accessor_property_meta->column_name;
            unless (defined($sql_lvalue)) {
                Carp::confess("No column name set for non-delegated/calculated property $property_name of $class_name");
            }
        }
        my $operator       = $rule_template->operator_for($property_name);
        my $value_position = $rule_template->value_position_for_property_name($property_name);                
    } # next delegated property
    for my $property_meta_array (@all_properties) {
        push @property_names_in_resultset_order, $property_meta_array->[1]->property_name; 
    }
    my $rule_template_without_recursion_desc = ($recursion_desc ? $rule_template->remove_filter('-recurse') : $rule_template);
    my $rule_template_specifies_value_for_subtype;
    if ($sub_typing_property) {
        $rule_template_specifies_value_for_subtype = $rule_template->specifies_value_for($sub_typing_property)
    }
    #my $per_object_in_resultset_loading_detail = $ds->_generate_loading_templates_arrayref(\@all_properties);
    %$self = (
        %$self,
        %$class_data,
        properties_for_params                       => \@all_properties,  
        property_names_in_resultset_order           => \@property_names_in_resultset_order,
        joins                                       => \@sql_joins,
        rule_template_id                            => $rule_template->id,
        rule_template_without_recursion_desc        => $rule_template_without_recursion_desc,
        rule_template_id_without_recursion_desc     => $rule_template_without_recursion_desc->id,
        rule_matches_all                            => $rule_template->matches_all,
        rule_specifies_id                           => ($rule_template->specifies_value_for('id') || undef),
        rule_template_is_id_only                    => $rule_template->is_id_only,
        rule_template_specifies_value_for_subtype   => $rule_template_specifies_value_for_subtype,
        recursion_desc                              => $rule_template->recursion_desc,
        recurse_property_on_this_row                => $recurse_property_on_this_row,
        recurse_property_referencing_other_rows     => $recurse_property_referencing_other_rows,
        recurse_resolution_by_iteration             => $recurse_resolution_by_iteration,
        #loading_templates                           => $per_object_in_resultset_loading_detail,
        joins_across_data_sources                   => $joins_across_data_sources,
    );
    return $self;
}

sub _init_core {
    my $self = shift;
    my $rule_template = $self->rule_template;
    my $ds = $self->data_source;

    # TODO: most of this only applies to the RDBMS subclass,
    # but some applies to any datasource.  It doesn't hurt to have the RDBMS stuff
    # here and ignored, but it's not placed correctly.
        
    # class-based values
    
    my $class_name = $rule_template->subject_class_name;
    my $class_meta = $class_name->__meta__;
    my $class_data = $ds->_get_class_data_for_loading($class_meta);       

    my @parent_class_objects                = @{ $class_data->{parent_class_objects} };
    my @all_properties                      = @{ $class_data->{all_properties} };
    my $sub_classification_meta_class_name  = $class_data->{sub_classification_meta_class_name};
    my $subclassify_by    = $class_data->{subclassify_by};
    
    my @all_id_property_names               = @{ $class_data->{all_id_property_names} };
    my @id_properties                       = @{ $class_data->{id_properties} };   
    my $id_property_sorter                  = $class_data->{id_property_sorter};    
    
    my $sub_typing_property                 = $class_data->{sub_typing_property};
    my $class_table_name                    = $class_data->{class_table_name};
    
    # individual query/boolexpr based
    
    my $recursion_desc = $rule_template->recursion_desc;
    my $recurse_property_on_this_row;
    my $recurse_property_referencing_other_rows;
    if ($recursion_desc) {
        ($recurse_property_on_this_row,$recurse_property_referencing_other_rows) = @$recursion_desc;        
    }        
    
    # _usually_ items freshly loaded from the DB don't need to be evaluated through the rule
    # because the SQL gets constructed in such a way that all the items returned would pass anyway.
    # But in certain cases (a delegated property trying to match a non-object value (which is a bug
    # in the caller's code from one point of view) or with calculated non-sql properties, then the
    # sql will return a superset of the items we're actually asking for, and the loader needs to
    # validate them through the rule
    my $needs_further_boolexpr_evaluation_after_loading; 
    
    # Does fulfilling this request involve querying more than one data source?
    my $is_join_across_data_source;

    my @sql_params;
    my @filter_specs;         
    my @property_names_in_resultset_order;
    my $object_num = 0; # 0-based, usually zero unless there are joins
    
    my @filters = $rule_template->_property_names;
    my %filters =     
        map { $_ => 0 }
        grep { substr($_,0,1) ne '-' }
        @filters;
    
    unless (@all_id_property_names == 1 && $all_id_property_names[0] eq "id") {
        delete $filters{'id'};
    }
    
    my (
        @sql_joins,
        @sql_filters, 
        $prev_table_name, 
        $prev_id_column_name, 
        $pk_used,
        @delegated_properties,    
        %chain_delegates,
    );

    for my $key (keys %filters) {
        if (index($key,'.') != -1) {
            $chain_delegates{$key} = delete $filters{$key};
        }
    }
    for my $co ( $class_meta, @parent_class_objects ) {
        my $class_name = $co->class_name;
        
        last if ( ($class_name eq 'UR::Object') or (not $class_name->isa("UR::Object")) );
        
        my @id_property_objects = $co->direct_id_property_metas;
        
        if (@id_property_objects == 0) {
            @id_property_objects = $co->property_meta_for_name("id");
            if (@id_property_objects == 0) {
                Carp::confess("Couldn't determine ID properties for $class_name\n");
            }
        }
        
        my %id_properties = map { $_->property_name => 1 } @id_property_objects;
        my @id_column_names =
            map { $_->column_name }
            @id_property_objects;
        
        for my $property_name (sort keys %filters)
        {
            my $property = UR::Object::Property->get(class_name => $class_name, property_name => $property_name);
            next unless $property;

            my $operator       = $rule_template->operator_for($property_name);
            my $value_position = $rule_template->value_position_for_property_name($property_name);

            delete $filters{$property_name};
            $pk_used = 1 if $id_properties{ $property_name };

            if ($property->is_legacy_eav) {
                die "Old GSC EAV can be handled with a via/to/where/is_mutable=1";
            }
            elsif ($property->is_transient) {
                die "Query by transient property $property_name on $class_name cannot be done!";
            }
            elsif ($property->is_delegated) {
                push @delegated_properties, $property;
            }
            elsif ($property->is_calculated) {
                $needs_further_boolexpr_evaluation_after_loading = 1;
            }
            else {
                # normal column: filter on it
                push @sql_filters, 
                    $class_name => 
                        { 
                            $property_name => { operator => $operator, value_position => $value_position }
                        };
            }
        }
        
        $prev_id_column_name = $id_property_objects[0]->column_name;
        
    } # end of inheritance loop
        
    if ( my @errors = keys(%filters) ) { 
        my $class_name = $class_meta->class_name;
        $ds->error_message('Unknown param(s) (' . join(',',@errors) . ") used to generate SQL for $class_name!");
        Carp::confess();
    }

    my $last_class_name = $class_name;
    my $last_class_object = $class_meta;        
    my $alias_num = 1;

    my %joins_done;
    my $joins_across_data_sources;

    DELEGATED_PROPERTY:
    for my $delegated_property (@delegated_properties) {
        my $last_alias_for_this_chain;
    
        my $property_name = $delegated_property->property_name;
        my @joins = $delegated_property->_resolve_join_chain($property_name);
        #pop @joins if $joins[-1]->{foreign_class}->isa("UR::Value");
        my $relationship_name = $delegated_property->via;
        unless ($relationship_name) {
           $relationship_name = $property_name;
           $needs_further_boolexpr_evaluation_after_loading = 1;
        }

        my $delegate_class_meta = $delegated_property->class_meta;
        my($via_accessor_meta) = $delegate_class_meta->_concrete_property_meta_for_class_and_name($relationship_name);
        my $final_accessor = $delegated_property->to;            
        my($final_accessor_meta) = $via_accessor_meta->data_type->__meta__->_concrete_property_meta_for_class_and_name(
                                             $final_accessor
                                         );
        unless ($final_accessor_meta) {
            Carp::croak("No property '$final_accessor' on class " . $via_accessor_meta->data_type .
                          " while resolving property $property_name on class $class_name");
        }
        while($final_accessor_meta->is_delegated) {
            $final_accessor_meta = $final_accessor_meta->to_property_meta();
            unless ($final_accessor_meta) {
                Carp::croak("No property '$final_accessor' on class " . $via_accessor_meta->data_type .
                              " while resolving property $property_name on class $class_name");
            }
        }
        $final_accessor = $final_accessor_meta->property_name;
        
        for my $join (@joins) {

            my $source_class_name = $join->{source_class};
            my $source_class_object = $join->{'source_class_meta'} || $source_class_name->__meta__;

            my $foreign_class_name = $join->{foreign_class};
            my $foreign_class_object = $join->{'foreign_class_meta'} || $foreign_class_name->__meta__;
            my($foreign_data_source) = $UR::Context::current->resolve_data_sources_for_class_meta_and_rule($foreign_class_object, $rule_template);
            if (! $foreign_data_source) {
                $needs_further_boolexpr_evaluation_after_loading = 1;
                next DELEGATED_PROPERTY;

            } elsif ($foreign_data_source ne $ds or
                    ! $ds->does_support_joins or
                    ! $foreign_data_source->does_support_joins
                )
            {
                push(@{$joins_across_data_sources->{$foreign_data_source->id}}, $delegated_property);
                next DELEGATED_PROPERTY;
            }

            my @source_property_names = @{ $join->{source_property_names} };

            my @source_table_and_column_names = 
                map {
                    my($p) = $source_class_object->_concrete_property_meta_for_class_and_name($_);
                    unless ($p) {
                        Carp::confess("No property $_ for class $source_class_object->{class_name}\n");
                    }
                    [$p->class_name->__meta__->class_name, $p->property_name];
                }
                @source_property_names;


            my $foreign_table_name = $foreign_class_name;

            unless ($foreign_table_name) {
                # If we can't make the join because there is no datasource representation
                # for this class, we're done following the joins for this property
                # and will NOT try to filter on it at the datasource level
                $needs_further_boolexpr_evaluation_after_loading = 1;
                next DELEGATED_PROPERTY;
            }

            my @foreign_property_names = @{ $join->{foreign_property_names} };
            my @foreign_property_meta = 
                map {
                    $foreign_class_object->_concrete_property_meta_for_class_and_name($_);
                }
                @foreign_property_names;
            
            my @foreign_column_names = 
                map {
                    # TODO: encapsulate
                    $_->is_calculated ? (defined($_->calculate_sql) ? ($_->calculate_sql) : () ) : ($_->property_name)
                }
                @foreign_property_meta;
                
            unless (@foreign_column_names) {
                # all calculated properties: don't try to join any further
                last;
            }
            unless (@foreign_column_names == @foreign_property_meta) {
                # some calculated properties, be sure to re-check for a match after loading the object
                $needs_further_boolexpr_evaluation_after_loading = 1;
            }
            
            my $alias = $joins_done{$join->{id}};
            unless ($alias) {            
                $alias = "${relationship_name}_${alias_num}";
                $alias_num++;
                $object_num++;

                my @source_property_meta = map { $source_class_object->_concrete_property_meta_for_class_and_name($_) }
                                            @source_property_names;
                push @sql_joins,
                    "$foreign_table_name $alias" =>
                        {
                            map {
                                my @coercion = $ds->cast_for_data_conversion(
                                        $source_property_meta[$_]->_data_type_as_class_name,
                                        $foreign_property_meta[$_]->_data_type_as_class_name,
                                        '=',
                                        'join');
                                $foreign_property_names[$_] => { 
                                    link_table_name     => $last_alias_for_this_chain || $source_table_and_column_names[$_][0],
                                    link_column_name    => $source_table_and_column_names[$_][1],
                                    left_coercion       => $coercion[0],
                                    right_coercion      => $coercion[1],
                                }
                            }
                            (0..$#foreign_property_names)
                        };
                    
                # Add all of the columns in the join table to the return list.                
                push @all_properties, 
                    map { [$foreign_class_object, $_, $alias, $object_num] }
                    map { $_->[1] }                    # These three lines are to get around a bug in perl
                    sort { $a->[0] cmp $b->[0] }       # 5.8's sort involving method calls within the sort
                    map  { [ $_->property_name, $_ ] } # sub that do sorts of their own
                    grep { defined($_->column_name) && $_->column_name ne '' }
                    UR::Object::Property->get( class_name => $foreign_class_name );
              
                $joins_done{$join->{id}} = $alias;
                
            }
            
            # Set these for after all of the joins are done
            $last_class_name = $foreign_class_name;
            $last_class_object = $foreign_class_object;
            $last_alias_for_this_chain = $alias;
            
        } # next join

        unless ($delegated_property->via) {
            next;
        }

        my($final_accessor_property_meta) = $last_class_object->_concrete_property_meta_for_class_and_name($id_properties[0]);
        unless ($final_accessor_property_meta) {
            Carp::croak("No property metadata for property named '$final_accessor' in class " . $last_class_object->class_name
                        . " while resolving joins for property '" .$delegated_property->property_name . "' in class "
                        . $delegated_property->class_name);
        }
       
        my $sql_lvalue;
        if ($final_accessor_property_meta->is_calculated) {
            $sql_lvalue = $final_accessor_property_meta->calculate_sql;
            unless (defined($sql_lvalue)) {
                $needs_further_boolexpr_evaluation_after_loading = 1;
                next;
            }
        }
        else {
            $sql_lvalue = $final_accessor_property_meta->column_name;
            unless (defined($sql_lvalue)) {
                Carp::confess("No column name set for non-delegated/calculated property $property_name of $class_name");
            }
        }

        my $operator       = $rule_template->operator_for($property_name);
        my $value_position = $rule_template->value_position_for_property_name($property_name);                
    } # next delegated property
    
    for my $property_meta_array (@all_properties) {
        push @property_names_in_resultset_order, $property_meta_array->[1]->property_name; 
    }
    
    my $rule_template_without_recursion_desc = ($recursion_desc ? $rule_template->remove_filter('-recurse') : $rule_template);
    
    my $rule_template_specifies_value_for_subtype;
    if ($sub_typing_property) {
        $rule_template_specifies_value_for_subtype = $rule_template->specifies_value_for($sub_typing_property)
    }

    my @this_ds_properties = grep { ! $_->[1]->is_delegated
                                    and (! $_->[1]->is_calculated or $_->[1]->calculate_sql)
                                  }
                             @all_properties;

    my $per_object_in_resultset_loading_detail = $ds->_generate_loading_templates_arrayref(\@this_ds_properties);

    %$self = (
        %$self,

        %$class_data,
        
        properties_for_params                       => \@all_properties,  
        property_names_in_resultset_order           => \@property_names_in_resultset_order,
        joins                                       => \@sql_joins,
        
        rule_template_id                            => $rule_template->id,
        rule_template_without_recursion_desc        => $rule_template_without_recursion_desc,
        rule_template_id_without_recursion_desc     => $rule_template_without_recursion_desc->id,
        rule_matches_all                            => $rule_template->matches_all,
        rule_specifies_id                           => ($rule_template->specifies_value_for('id') || undef),
        rule_template_is_id_only                    => $rule_template->is_id_only,
        rule_template_specifies_value_for_subtype   => $rule_template_specifies_value_for_subtype,
        
        recursion_desc                              => $rule_template->recursion_desc,
        recurse_property_on_this_row                => $recurse_property_on_this_row,
        recurse_property_referencing_other_rows     => $recurse_property_referencing_other_rows,
        
        loading_templates                           => $per_object_in_resultset_loading_detail,

        joins_across_data_sources                   => $joins_across_data_sources,
    );
        
    return $self;
}

sub _init_default {
    my $self = shift;
    my $bx_template = $self->rule_template;
    $self->{needs_further_boolexpr_evaluation_after_loading} = 1;
    my $all_possible_headers = $self->{loading_templates}[0]{property_names};
    my $expected_headers;
    my $class_meta = $bx_template->subject_class_name->__meta__;
    for my $pname (@$all_possible_headers) {
        my $pmeta = $class_meta->property($pname);
        if ($pmeta->is_delegated) {
            next;
        }
        push @$expected_headers, $pname;
    }
    $self->{loading_templates}[0]{property_names} = $expected_headers;

    if ($bx_template->subject_class_name->isa('UR::Value')) {
        # Hack so the objects get blessed into the proper subclass in the Object Fabricator.
        # This is necessary so every possible UR::Value subclass doesn't need its
        # own "id" property defined.  Without it, the data shows that these objects get
        # loaded as the base UR::Value class (since its "id" is defined on UR:Value)
        # and then would get automagically subclassed.
        $self->{'loading_templates'}->[0]->{'final_class_name'} = $bx_template->subject_class_name
    }

    return $self;
}


sub _init_remote_cache {
    my $self = shift;
    my $rule_template = $self->rule_template;
    my $ds = $self->data_source;

    my $class_name = $rule_template->subject_class_name;
    my $class_meta = $class_name->__meta__;
    my $class_data = $ds->_get_class_data_for_loading($class_meta);

    my $recursion_desc = $rule_template->recursion_desc;
    my $rule_template_without_recursion_desc = ($recursion_desc ? $rule_template->remove_filter('-recurse') : $rule_template);
    my $rule_template_specifies_value_for_subtype;
    my $sub_typing_property = $class_data->{'sub_typing_property'};
    if ($sub_typing_property) {
        $rule_template_specifies_value_for_subtype = $rule_template->specifies_value_for($sub_typing_property)
    }

    my @property_names = $class_name->__meta__->all_property_names;

    %$self = (
        %$self,

        select_clause                               => '',
        select_hint                                 => undef,
        from_clause                                 => '',
        where_clause                                => '',
        connect_by_clause                           => '',
        order_by_clause                             => '',

        needs_further_boolexpr_evaluation_after_loading => undef,
        loading_templates                           => [],

        sql_params                                  => [],
        filter_specs                                => [],
        property_names_in_resultset_order           => \@property_names,
        properties_for_params                       => [],

        rule_template_id                            => $rule_template->id,
        rule_template_without_recursion_desc        => $rule_template_without_recursion_desc,
        rule_template_id_without_recursion_desc     => $rule_template_without_recursion_desc->id,
        rule_matches_all                            => $rule_template->matches_all,
        rule_specifies_id                           => ($rule_template->specifies_value_for('id') || undef),
        rule_template_is_id_only                    => $rule_template->is_id_only,
        rule_template_specifies_value_for_subtype   => $rule_template_specifies_value_for_subtype,

        recursion_desc                              => undef,
        recurse_property_on_this_row                => undef,
        recurse_property_referencing_other_rows     => undef,

        %$class_data,
    );

    return $self;
}

sub order_by_column_list {
    my $self = shift;

    $self->_resolve_order_by_and_descending_data();
    return $self->{_order_by_column_list};
}

sub _resolve_order_by_and_descending_data {
    my $self = shift;

    unless ($self->{_order_by_column_list}) {
        my %is_descending;
        my @order_by_columns =
                map {
                    m/^-(.*)/
                        ? $is_descending{$1} = $1
                        : $_;
                }
                @{ $self->order_by_columns || [] };

        $self->{_order_by_column_list} = \@order_by_columns;
        $self->{_order_by_column_is_descending} = \%is_descending;
    }
}

sub order_by_column_is_descending {
    my($self, $column_name) = @_;

    $self->_resolve_order_by_and_descending_data();
    return $self->{_order_by_column_is_descending}->{$column_name};
}

sub property_meta_for_column {
    my($self, $table_and_column_name) = @_;

    $table_and_column_name = lc($table_and_column_name);

    my $data_source = $self->data_source();
    my ($table_name, $column_name) = $data_source->_resolve_table_and_column_from_column_name($table_and_column_name);

    if (my $join = $self->_get_alias_join($table_name)) {
        # The given $table_name was actually a join alias
        my $foreign_class_meta = $join->foreign_class->__meta__;
        my $prop_name = $foreign_class_meta->property_for_column($column_name);
        return $prop_name
            ? $foreign_class_meta->property_meta_for_name($prop_name)
            : undef;

    } else {
        my $class_meta = $self->class_name->__meta__;
        my $prop_name = $class_meta->property_for_column($table_and_column_name);
        return $class_meta->property_meta_for_name($prop_name);
    }
}

1;

