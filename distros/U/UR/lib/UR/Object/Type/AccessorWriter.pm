
package UR::Object::Type::AccessorWriter;

package UR::Object::Type;

use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;
#use warnings FATAL => 'all';

use Carp ();
use Sub::Name ();
use Sub::Install ();
use List::Util;

sub mk_rw_accessor {
    my ($self, $class_name, $accessor_name, $column_name, $property_name, $is_transient) = @_;
    $property_name ||= $accessor_name;

    my $full_name = join( '::', $class_name, $accessor_name );
    my $accessor = Sub::Name::subname $full_name => sub {
        if (@_ > 1) {
            my $old = $_[0]->{ $property_name };
            my $new = $_[1];

            # The accessors may compare undef and an empty
            # string.  For speed, we turn warnings off rather
            # than add extra code to make the warning disappear.
            local $@;
            my $different = eval { no warnings;  $old ne $new };
            if ($different or $@ =~ m/has no overloaded magic/)
            {
                $_[0]->{ $property_name } = $new;
                $_[0]->__signal_change__( $property_name, $old, $new ) unless $is_transient; # FIXME is $is_transient right here?  Maybe is_volatile instead (if at all)?
            }
            return $new;
        }
        $_[0]->{ $property_name }
    };

    if (_class_is_singleton($class_name)) {
        my $basic_accessor = $accessor;
        $accessor = sub {
            shift->_singleton_object->$basic_accessor(@_);
        };
    }

    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $accessor_name,
        code => $accessor,
    });

}

sub mk_ro_accessor {
    my ($self, $class_name, $accessor_name, $column_name, $property_name) = @_;
    $property_name ||= $accessor_name;

    my $full_name = join( '::', $class_name, $accessor_name );
    my $accessor = Sub::Name::subname $full_name => sub {
        if (@_ > 1) {
            my $old = $_[0]->{ $property_name};
            my $new = $_[1];

            my $different;
            my $exception = do {
                local $@;
                $different = eval { no warnings;  $old ne $new };
                $@;
            };
            if ($different or $exception =~ m/has no overloaded magic/)
            {
                Carp::croak("Cannot change read-only property $accessor_name for class $class_name!"
                . "  Failed to update " . $_[0]->__display_name__ . " property: $property_name from $old to $new");
            }
            return $new;
        }
        return $_[0]->{ $property_name };
    };

    if (_class_is_singleton($class_name)) {
        my $basic_accessor = $accessor;
        $accessor = sub {
            shift->_singleton_object->$basic_accessor(@_);
        };
    }

    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $accessor_name,
        code => $accessor,
    });

}

sub _class_is_singleton {
    my $class_name = shift;
    return grep { $_->isa('UR::Singleton') } @{ $class_name->__meta__->{is} };
}

sub mk_id_based_flex_accessor {
    my ($self, $class_name, $accessor_name, $id_by, $r_class_name, $where, $id_class_by) = @_;

    unless (ref($id_by)) {
        $id_by = [ $id_by ];
    }

    my $id_resolver;
    my $id_decomposer;
    my @id;
    my $id;
    my $full_name = join( '::', $class_name, $accessor_name );
    my $concrete_r_class_name = $r_class_name;
    my $accessor = Sub::Name::subname $full_name => sub {
        my $self = shift;
        if (@_ == 1) {
            # This one is to support syntax like this
            # $cd->artist($different_artist);
            # to switch which artist object this cd points to
            my $object_value = shift;
            if ($id_class_by and not ref $object_value) {
                # when we have an id-class-by accessor and get a primitive, store it as a UR::Value
                $object_value = UR::Value->get($object_value);
            }
            if (defined $object_value) {
                if ($id_class_by) {
                    $concrete_r_class_name = ($object_value->can('class') ? $object_value->class : ref($object_value));
                    $id_decomposer = undef;
                    $id_resolver = undef;
                    $self->$id_class_by($concrete_r_class_name);
                } elsif (! Scalar::Util::blessed($object_value) and ! $object_value->can('id')) {
                    Carp::croak("Can't call method \"id\" without a package or object reference.  Expected an object as parameter to '$accessor_name', not the value '$object_value'");
                }

                my $r_class_meta = do {
                    local $@;
                    eval { $concrete_r_class_name->__meta__ };
                };
                unless ($r_class_meta) {
                    Carp::croak("Can't get metadata for class $concrete_r_class_name.  Is it a UR class?");
                }

                $id_decomposer ||= $r_class_meta->get_composite_id_decomposer;
                @id = $id_decomposer->($object_value->id);
                if (@$id_by == 1) {
                    my $id_property_name = $id_by->[0];
                    $self->$id_property_name($object_value->id);
                } else {
                    @id = $id_decomposer->($object_value->id);
                    Carp::croak("Cannot alter value for '$accessor_name' on $class_name: The passed-in object of type "
                                . $object_value->class . " has " . scalar(@id) . " id properties, but the accessor '$accessor_name' has "
                                . scalar(@$id_by) . " id_by properties");
                    for my $id_property_name (@$id_by) {
                        $self->$id_property_name(shift @id);
                    }
                }
            }
            else {
                if ($id_class_by) {
                    $self->$id_class_by(undef);
                }
                for my $id_property_name (@$id_by) {
                    $self->$id_property_name(undef);
                }
            }
            return $object_value;
        }
        else {
            if ($id_class_by) {
                $concrete_r_class_name = $self->$id_class_by;
                $id_decomposer = undef;
                $id_resolver = undef;
                return unless $concrete_r_class_name;
            }
            unless ($id_resolver) {
                my $concrete_r_class_meta = UR::Object::Type->get($concrete_r_class_name);
                unless ($concrete_r_class_meta) {
                    Carp::croak("Can't resolve value for '$accessor_name' on class $class_name id '".$self->id
                                . "': No class metadata for value '$concrete_r_class_name' referenced as property '$id_class_by'");
                }
                $id_resolver = $concrete_r_class_meta->get_composite_id_resolver;
            }

            # eliminate the old map{} because of side effects with $_
            # when the id_by property happens to be calculated
            #@id = map { $self->$_ } @$id_by;
            @id=();
            for my $property_name (@$id_by) {      # no implicit topic
                my $value = $self->$property_name; # scalar context
                push @id, $value;
            }

            $id = $id_resolver->(@id);
            return if not defined $id;
            if ($concrete_r_class_name eq 'UR::Object') {
                Carp::carp("Querying by using UR::Object class is deprecated.");
            }

            if ($concrete_r_class_name->isa("UR::Value")) {
                return $id;
            }
            else {
                if (@_ || $where) {
                    # There were additional params passed in
                    return $concrete_r_class_name->get(id => $id, @_, @$where);
                } else {
                    return $concrete_r_class_name->get($id);
                }
            }
        }
    };

    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $accessor_name,
        code => $accessor,
    });
}

sub mk_id_based_object_accessor {
    my ($self, $class_name, $accessor_name, $id_by, $r_class_name, $where, $id_class_by) = @_;

    unless (ref($id_by)) {
        $id_by = [ $id_by ];
    }

    my $id_resolver;
    my $id_decomposer;
    my @id;
    my $id;
    my $full_name = join( '::', $class_name, $accessor_name );
    my $concrete_r_class_name = $r_class_name;
    my $accessor = Sub::Name::subname $full_name => sub {
        my $self = shift;
        if (@_ == 1) {
            # This one is to support syntax like this
            # $cd->artist($different_artist);
            # to switch which artist object this cd points to
            my $object_value = shift;
            if (defined $object_value) {
                if ($id_class_by) {
                    $concrete_r_class_name = ($object_value->can('class') ? $object_value->class : ref($object_value));
                    $id_decomposer = undef;
                    $id_resolver = undef;
                    $self->$id_class_by($concrete_r_class_name);
                } elsif (! Scalar::Util::blessed($object_value) and ! $object_value->can('id')) {
                    Carp::croak("Can't call method \"id\" without a package or object reference.  Expected an object as parameter to '$accessor_name', not the value '$object_value'");
                }

                my $r_class_meta = do {
                    local $@;
                    eval { $concrete_r_class_name->__meta__ };
                };
                unless ($r_class_meta) {
                    Carp::croak("Can't get metadata for class $concrete_r_class_name.  Is it a UR class?");
                }

                $id_decomposer ||= $r_class_meta->get_composite_id_decomposer;
                @id = $id_decomposer->($object_value->id);
                if (@$id_by == 1) {
                    my $id_property_name = $id_by->[0];
                    $self->$id_property_name($object_value->id);
                } else {
                    @id = $id_decomposer->($object_value->id);
                    Carp::croak("Cannot alter value for '$accessor_name' on $class_name: The passed-in object of type "
                                . $object_value->class . " has " . scalar(@id) . " id properties, but the accessor '$accessor_name' has "
                                . scalar(@$id_by) . " id_by properties");
                    for my $id_property_name (@$id_by) {
                        $self->$id_property_name(shift @id);
                    }
                }
            }
            else {
                if ($id_class_by) {
                    $self->$id_class_by(undef);
                }
                for my $id_property_name (@$id_by) {
                    $self->$id_property_name(undef);
                }
            }
            return $object_value;
        }
        else {
            if ($id_class_by) {
                $concrete_r_class_name = $self->$id_class_by;
                $id_decomposer = undef;
                $id_resolver = undef;
                return unless $concrete_r_class_name;
            }
            unless ($id_resolver) {
                my $concrete_r_class_meta = UR::Object::Type->get($concrete_r_class_name);
                unless ($concrete_r_class_meta) {
                    Carp::croak("Can't resolve value for '$accessor_name' on class $class_name id '".$self->id
                                . "': No class metadata for value '$concrete_r_class_name' referenced as property '$id_class_by'");
                }
                $id_resolver = $concrete_r_class_meta->get_composite_id_resolver;
            }

            @id=();
            for my $property_name (@$id_by) {      # no implicit topic
                my $value = $self->$property_name; # scalar context
                push @id, $value;
            }

            $id = @id > 1
                    ? $id_resolver->(@id)
                    : $id[0];

            return if not defined $id;
            if ($concrete_r_class_name eq 'UR::Object') {
                Carp::carp("Querying by using UR::Object class is deprecated.");
            }
            if (@_ || $where) {
                # There were additional params passed in
                return $concrete_r_class_name->get(id => $id, @_, @$where);
            } else {
                return $concrete_r_class_name->get($id);
            }
        }
    };

    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $accessor_name,
        code => $accessor,
    });
}


sub _resolve_bridge_logic_for_indirect_property {
    my ($ur_object_type, $class_name, $accessor_name, $via, $to, $where) = @_;

    my $bridge_collector = sub {
        my $self = shift;
        my @results = $self->$via(@$where);
        # Indirect has one properties must return a single undef value for an empty result, even in list context.
        return if @results == 1 and not defined $results[0];
        return @results;
    };
    my $bridge_crosser = sub {
        my $bridges = shift;
        return map { $_->$to(@_) } @$bridges;
    };

    return($bridge_collector, $bridge_crosser) if ($UR::Object::Type::bootstrapping);

    # bail out and use the default subs if any of these fail
    my ($my_class_meta, $my_property_meta, $via_property_meta, $to_property_meta);

    $my_class_meta = $class_name->__meta__;
    $my_property_meta = $my_class_meta->property_meta_for_name($accessor_name) if ($my_class_meta);
    $via_property_meta = $my_class_meta->property_meta_for_name($via) if ($my_class_meta);
    $to_property_meta  = $my_property_meta->to_property_meta() if ($my_property_meta);

    if (! $my_class_meta || ! $my_property_meta  || ! $via_property_meta || ! $to_property_meta) {
        # Something didn't link right, use the default methods
        return ($bridge_collector, $bridge_crosser);
    }

    if ($my_property_meta->is_delegated and $my_property_meta->is_many
        and $via_property_meta->is_many and $via_property_meta->reverse_as
        and $via_property_meta->data_type and $via_property_meta->data_type->isa('UR::Object')
    ) {
        my $bridge_class = $via_property_meta->data_type;

        my @via_join_properties = do {
            local $@;
            eval { $via_property_meta->get_property_name_pairs_for_join };
        };
        if (! @via_join_properties) {
            # this can happen if the properties aren't linked together as expected.
            # For example, a property involved in a many-to-many relationship, but is
            # defined as a one-to-many with reverse_as.
            return ($bridge_collector, $bridge_crosser);
        }

        my (@my_join_properties,@their_join_properties);
        for (my $i = 0; $i < @via_join_properties; $i++) {
            ($my_join_properties[$i], $their_join_properties[$i]) = @{ $via_join_properties[$i] };
        }

        my(@where_properties, @where_values, %bridge_meta_params);
        if ($where or $via_property_meta->where) {
            my @collected_where;
            @collected_where = @$where if ($where);
            push @collected_where, @{ $via_property_meta->where } if ($via_property_meta->where);
            while (@collected_where) {
                my $where_property = shift @collected_where;
                my $where_value = shift @collected_where;

                if (UR::BoolExpr::Util::is_meta_param($where_property)) {
                    $bridge_meta_params{$where_property} = $where_value;

                } else {
                    if (ref($where_value) eq 'HASH' and $where_value->{'operator'}) {
                        $where_property .= ' ' .$where_value->{'operator'};
                        $where_value = $where_value->{'value'};
                    }
                    push @where_properties, $where_property;
                    push @where_values, $where_value;
                }
            }
        }

        my $bridge_template = UR::BoolExpr::Template->resolve($bridge_class, @their_join_properties, @where_properties, %bridge_meta_params);

        $bridge_collector = sub {
            my $self = shift;
            my @my_values = map { $self->$_} @my_join_properties;
            my $bx = $bridge_template->get_rule_for_values(@my_values, @where_values);
            return $bridge_class->get($bx);
        };

        if ($to_property_meta->is_delegated
            and
            my $doubly_deledated_bridge_crosser = _resolve_bridge_crosser_for_doubly_delegated_property($to_property_meta, \%bridge_meta_params)
        ) {
            $bridge_crosser = $doubly_deledated_bridge_crosser;
        }
    }
    return ($bridge_collector, $bridge_crosser);
}

sub _make_results_sorter_for_doubly_delegated_bridge_crosser {
    my($bridges, $bridge_linker, $results_linker) = @_;

    my $rank = 0;
    my %bridge_rankings = map  { $bridge_linker->() => $rank++ } @$bridges;
    return sub {
        my $results = shift;

        return map { $_->[1] }
               sort { $bridge_rankings{ $a->[0] } <=> $bridge_rankings{ $b->[0] } }
               map { [ $results_linker->(), $_ ] }
               @$results;
    };
}

sub _resolve_bridge_crosser_for_doubly_delegated_property {
    my($to_property_meta, $bridge_meta_params) = @_;
    # This property's value is doubly delegated.  The simple thing to
    # do is to collect the bridge objects, then call the second
    # delegation method on each bridge in a loop to collect the final
    # results, which may trigger one query per result.  Depending on
    # the type of delegation, the final results can be collected with
    # one query

    my($result_class_resolver, $bridge_linking_properties, $final_result_property_name, $result_filtering_property);
    if ($to_property_meta->via) {
        # bridges through another via-to property
        my $second_via_property_meta = $to_property_meta->via_property_meta;
        my $final_class_name = $second_via_property_meta->data_type;
        if ($final_class_name and $final_class_name ne 'UR::Value' and $final_class_name->isa('UR::Object')) {
            if ( 1 == (my @via2_join_properties = $second_via_property_meta->get_property_name_pairs_for_join)) {
                $bridge_linking_properties = [ $via2_join_properties[0]->[0] ];
                $result_filtering_property = $via2_join_properties[0]->[1];
                $result_class_resolver = sub { $final_class_name };

                $final_result_property_name = $to_property_meta->to;
            }
        }

    } elsif ($to_property_meta->id_by) {
        $bridge_linking_properties = $to_property_meta->id_by;
        $result_filtering_property = 'id';
        if ($to_property_meta->id_class_by) {
            # Bridging through an 'id_class_by' property
            # bucket the bridge items by the result class and do a get for
            # each of those classes with a listref of IDs
            my $result_class_resolving_property = $to_property_meta->id_class_by;
            $result_class_resolver = sub { shift->$result_class_resolving_property };

        } else {
            # Bridging through a regular id-by property
            my $result_class = $to_property_meta->data_type;
            $result_class_resolver = sub { $result_class };
        }

    } elsif ($to_property_meta->reverse_as) {
        if (1 == (my @reverse_as_join_properties = $to_property_meta->get_property_name_pairs_for_join)) {
            $bridge_linking_properties = [ map { $_->[0] } @reverse_as_join_properties ];
            $result_filtering_property = $reverse_as_join_properties[0]->[1];

            my $result_class = $to_property_meta->data_type;
            $result_class_resolver = sub { $result_class };
        }
    }

    if ($result_class_resolver) {
        my $linking_id_value_for_bridge = do {
            my %composite_id_resolver_for_class;

            sub {
                my $bridge = shift;
                my @id = map { $bridge->$_ } @$bridge_linking_properties;

                my $result_class = $result_class_resolver->($bridge);
                my $id_resolver = $composite_id_resolver_for_class{ $result_class }
                                    ||= $result_class->__meta__->get_composite_id_resolver;

                return $id_resolver->(@id);
            };
        };

        return sub {
            my $bridges = shift;
            my %result_class_names_and_ids;

            foreach my $bridge ( @$bridges ) {
                my $result_class = $result_class_resolver->($bridge);
                $result_class_names_and_ids{$result_class} ||= [];

                my $id = $linking_id_value_for_bridge->($bridge);
                push @{ $result_class_names_and_ids{ $result_class } }, $id;
            }

            my @results;
            foreach my $result_class ( keys %result_class_names_and_ids ) {
                if($result_class->isa('UR::Value')) { #can't group queries together for UR::Values
                    push @results, map { $result_class->get($result_filtering_property => $_, @_) } @{$result_class_names_and_ids{$result_class}};
                } else {
                    push @results, $result_class->get($result_filtering_property => $result_class_names_and_ids{$result_class}, @_);
                }
            }

            if ($bridge_meta_params->{'-order'} || $bridge_meta_params->{'-order_by'}) {
                my $results_sorter = _make_results_sorter_for_doubly_delegated_bridge_crosser(
                                        $bridges,
                                        sub { return $linking_id_value_for_bridge->($_) },
                                        sub { $_->id } );
                @results = $results_sorter->(\@results);
            }

            @results = map { $_->$final_result_property_name } @results if ($to_property_meta->via);
            return @results;
        };
    }

    return;
}

sub _is_assignment_value {
    return (
        @_ == 1
        and not (ref($_[0]) and Scalar::Util::blessed($_[0]) and $_[0]->isa("UR::BoolExpr"))
    );
}

sub mk_indirect_ro_accessor {
    my ($ur_object_type, $class_name, $accessor_name, $via, $to, $where) = @_;
    my @where = ($where ? @$where : ());
    my $full_name = join( '::', $class_name, $accessor_name );
    my $filterable_accessor_name = 'get_' . $accessor_name;  # FIXME we need a better name for
    my $filterable_full_name = join( '::', $class_name, $filterable_accessor_name );

    # This is part of an experimental refactoring of indirect accessors.  The goal is to
    # get rid of all the special cases inside of _resolve_bridge_logic_for_indirect_property()
    # and do the right thing with the Join data
    my (@collectors, @crossers);
    my $accessor2 = Sub::Name::subname $full_name.'_new' => sub {
        my $self = shift;
        Carp::croak("Assignment value passed to read-only indirect accessor $accessor_name for class $class_name") if @_ and _is_assignment_value(@_);

        if ($class_name =~ m/^UR::/) {
            # Some methods will recurse into here if called on a UR::* class (especially
            # UR::BoolExpr), so do the dumb but safe thing
            my $bridge_collector = sub {
                my $self = shift;
                my @results = $self->$via(@$where);
                # Indirect has one properties must return a single undef value for an empty result, even in list context.
                return if @results == 1 and not defined $results[0];
                return @results;
            };

            #TODO: move this crosser closure logic down and get rid of the closure
            my @filter = @_;
            my $bridge_crosser = sub { return map { $_->$to(@filter) } @_ };
            my @bridges = $bridge_collector->($self);
            return unless @bridges;
            return $self->context_return(@bridges) if ($to eq '-filter');

            my @results = $bridge_crosser->(@bridges);
            return $self->context_return(@results);
        }

        unless (@collectors) {
            require List::MoreUtils;

            my $prop_meta = $class_name->__meta__->property_meta_for_name($accessor_name);
            my @join_list = $prop_meta->_resolve_join_chain();
            foreach my $join ( @join_list ) {
                my @source_property_names = @{$join->{source_property_names}};
                my $collector = sub {
                    my @list = grep { defined && length } map { my $o = $_; map { $o->$_ } @source_property_names} @_;
                    return @list == 1 ? $list[0] : \@list;
                };
                push @collectors, $collector;

                my $foreign_class = $join->{foreign_class};
                my $crosser;
                if (! $foreign_class->isa('UR::Value')) {
                    my @foreign_property_names = @{$join->{foreign_property_names}};

                    $crosser = sub { my @get_params = List::MoreUtils::pairwise
                                                                { $a => $b } @foreign_property_names, @_;
                                          return $foreign_class->get(@get_params); };
                }
                push @crossers, $crosser;
            }
        }

        my @working = ($self);

        # This can probably be rewritten with List::Util::reduce
        for (my $i = 0; $i < @collectors; $i++) {
            last unless @working;
            my @working = $collectors[$i]->(@working);
            next unless $crossers[$i];
            @working = $crossers[$i]->(@working);
        }
        $self->context_return(@working);
    };
    #Sub::Install::reinstall_sub({
    #    into => $class_name,
    #    as   => $accessor_name.'_new',
    #    code => $accessor2,
    #});


    my($bridge_collector, $bridge_crosser);

    my $accessor = Sub::Name::subname $full_name => sub {
        my $self = shift;
        Carp::croak("Assignment value passed to read-only indirect accessor $accessor_name for class $class_name") if @_ == 1 and _is_assignment_value(@_);

        unless ($bridge_collector) {
            ($bridge_collector, $bridge_crosser)
                = $ur_object_type->_resolve_bridge_logic_for_indirect_property($class_name, $accessor_name, $via, $to, \@where);
        }

        my @bridges = $bridge_collector->($self);

        return unless @bridges;
        return $self->context_return(@bridges) if ($to eq '-filter');

        my @results = $bridge_crosser->(\@bridges, @_);
        $self->context_return(@results);
    };

    unless ($accessor_name) {
        Carp::croak("No accessor name specified for read-only indirect accessor $accessor_name for class $class_name");
    }

    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $accessor_name,
        code => $accessor,
    });

    my $r_class_name;
    my $r_class_name_resolver = sub {
        return $r_class_name if $r_class_name;

        my $linking_property = UR::Object::Property->get(class_name => $class_name, property_name => $via);
        unless ($linking_property->data_type) {
            Carp::croak "Property ${class_name}::${accessor_name}: via refers to a property with no data_type.  Can't process filter";
        }
        my $final_property = UR::Object::Property->get(class_name => $linking_property->data_type,
                                                       property_name => $to);
        unless ($final_property->data_type) {
            Carp::croak "Property ${class_name}::${accessor_name}: to refers to a property with no data_type.  Can't process filter";
        }
        $r_class_name = $final_property->data_type;
    };

    my $filterable_accessor = Sub::Name::subname $filterable_full_name => sub {
        my $self = shift;
        my @results = $self->$accessor_name();
        if (@_) {
            my $rule;
            if (@_ == 1 and ref($_[0]) and $_[0]->isa('UR::BoolExpr')) {
                $rule = shift;
            } else {
                $r_class_name ||= $r_class_name_resolver->();
                $rule = UR::BoolExpr->resolve_normalized($r_class_name, @_);
            }
            @results = grep { $rule->evaluate($_) } @results;
        }
        $self->context_return(@results);
    };
    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $filterable_accessor_name,
        code => $filterable_accessor,
    });

}


sub mk_indirect_rw_accessor {
    my ($ur_object_type, $class_name, $accessor_name, $via, $to, $where, $singular_name, $property_name) = @_;
    $property_name ||= $accessor_name;
    my @where = ($where ? @$where : ());
    my $full_name = join( '::', $class_name, $accessor_name );

    my $update_strategy; # defined the first time we "set" a value through this
    my $adder;
    my $via_property_meta;
    my $r_class_name;
    my $is_many;

    my $resolve_update_strategy = sub {
        unless (defined $update_strategy) {
            # Resolve the strategy.  We need to figure out if $to
            # refers to an id-property.  This is only called once, when the
            # accessor is first used.

            # If we reference a remote object, and go to one of its id properties
            # we must do a delete/create instead of property change.  Note that
            # this is only allowed when the remote object has no direct properties
            # which are not id properties.

            my $my_property_meta = $class_name->__meta__->property_meta_for_name($property_name);
            unless ($my_property_meta) {
                Carp::croak("Failed to find property meta for '$property_name' on class $class_name");
            }
            $is_many = $my_property_meta->is_many;

            $via_property_meta ||= $class_name->__meta__->property_meta_for_name($via);
            unless ($via_property_meta) {
                Carp::croak("Failed to find property metadata for via property '$via' while resolving property '$property_name' on class $class_name");
            }

            $r_class_name ||= $via_property_meta->data_type;
            unless ($r_class_name) {
                Carp::croak("Cannot resolve property '$property_name' on class $class_name: It is via property '$via' which has no data_type");
            }
            my $r_class_meta = $r_class_name->__meta__;
            unless ($r_class_meta) {
                Carp::croak("Cannot resolve property '$property_name' on class $class_name: It is via property '$via' with data_type $r_class_name which is not a valid class name");
            }

            $adder = "add_" . $via_property_meta->singular_name;

            if ($my_property_meta->_involves_id_property) {
                $update_strategy = 'delete-create'
            }
            else {
                $update_strategy = 'change';
            }
        }
        return $update_strategy;
    };

    my ($bridge_collector, $bridge_crosser);
    my $accessor = Sub::Name::subname $full_name => sub {
        my $self = shift;

        unless ($bridge_collector) {
            ($bridge_collector, $bridge_crosser)
                = $ur_object_type->_resolve_bridge_logic_for_indirect_property($class_name, $accessor_name, $via, $to, \@where);
        }

        my @bridges = $bridge_collector->($self);

        if ( @_ == 1 and _is_assignment_value(@_) ) {
            $resolve_update_strategy->() unless (defined $update_strategy);

            if ($update_strategy eq 'change') {
                if (@bridges == 0) {
                    #print "adding via $adder @where :::> $to @_\n";
                    my $exception = do {
                        local $@;
                        @bridges = eval { $self->$adder(@where, $to => $_[0]) };
                        $@;
                    };
                    if ($exception) {
                        my $r_class_meta = $r_class_name->__meta__;
                        my $property_meta = $r_class_meta->property($to);
                        if ($property_meta) {
                            # Re-throw the original exception
                            die $exception;
                        } else {
                            Carp::croak("Couldn't create a new object through indirect property "
                                        . "'$accessor_name' on $class_name.  'to' is $to which is not a property on $r_class_name.");
                        }
                    }
                    #WAS > Carp::confess("Cannot set $accessor_name on $class_name $self->{id}: property is via $via which is not set!");
                }
                elsif (@bridges > 1) {
                    Carp::croak("Cannot set '$accessor_name' on $class_name id '$self->{id}': multiple instances of '$via' found, via which the property is set");
                }
                #print "updating $bridges[0] $to to @_\n";
                return $bridges[0]->$to(@_);
            }
            elsif ($update_strategy eq 'delete-create') {
                if (@bridges > 1) {
                    Carp::croak("Cannot set '$accessor_name' on $class_name $self->{id}: multiple instances of '$via' found, via which the property is set");
                }
                else {
                    if (@bridges) {
                        #print "deleting $bridges[0]\n";
                        $bridges[0]->delete;
                    }
                    #print "adding via $adder @where :::> $to @_\n";
                    @bridges = $self->$adder(@where, $to => $_[0]);
                    unless (@bridges) {
                        Carp::croak("Failed to add bridge for '$accessor_name' on $class_name if '$self->{id}': method $adder returned false");
                    }
                }
            }
        }
        if (not defined $is_many) {
            $resolve_update_strategy->();
        }

        if ($is_many) {
            return unless @bridges;
            my @results = $bridge_crosser->(\@bridges, @_);
            $self->context_return(@results);
        } else {
            return undef unless @bridges;
            my @results = map { $_->$to(@_) } @bridges;
            $self->context_return(@results);
        }
    };

    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $accessor_name,
        code => $accessor,
    });

    if ($singular_name) {  # True if we're defining an is_many indirect property
        # Add
        my $via_adder;
        my $adder_method_name = 'add_' . $singular_name;
        if ($class_name->can($adder_method_name)) {
            $adder_method_name = '__' . $adder_method_name;
        }
        my $adder_method = Sub::Name::subname $class_name . '::' . $adder_method_name => sub {
            my($self) = shift;


            $resolve_update_strategy->() unless (defined $update_strategy);
            unless (defined $via_adder) {
                $via_adder = "add_" . $via_property_meta->singular_name;
            }

            # By default, a single value will come in which is the remote value
            # we just add the appropriate property name to it.  If multiple
            # values come in we trust the caller to be giving additional params.
            if (@_ == 1) {
                unshift @_, $to;
            }
            $self->$via_adder(@where,@_);
        };
        Sub::Install::reinstall_sub({
                into => $class_name,
                as   => $adder_method_name,
                code => $adder_method,
            });

        # Remove
        my $via_remover;
        my $remover_method_name = 'remove_' . $singular_name;
        if ($class_name->can($remover_method_name)) {
            $remover_method_name = '__' . $remover_method_name;
        }
        my $remover_method = Sub::Name::subname $class_name . '::' . $remover_method_name => sub {
            my($self) = shift;

            $resolve_update_strategy->() unless (defined $update_strategy);
            unless (defined $via_remover) {
                $via_remover = "remove_" . $via_property_meta->singular_name;
            }

            # By default, a single value will come in which is the remote value
            # we just remove the appropriate property name to it.  If multiple
            # values come in we trust the caller to be giving removeitional params.
            if (@_ == 1) {
                unshift @_, $to;
            }
            $self->$via_remover(@where,@_);
        };
        Sub::Install::reinstall_sub({
                into => $class_name,
                as   => $remover_method_name,
                code => $remover_method,
        });
    }

}


sub mk_calculation_accessor {
    my ($self, $class_name, $accessor_name, $calculation_src, $calculate_from, $params, $is_cached, $column_name) = @_;

    my $accessor;
    my @src;

    if (not defined $calculation_src or $calculation_src eq '') {
        $accessor = \&{ $class_name . '::' . $accessor_name };
        unless ($accessor) {
            Carp::croak "$accessor_name not defined in $class_name!  Define it, or specify a calculate => sub{} or calculate => \$perl_src in the class definition.";
        }
    }
    elsif (ref($calculation_src) eq 'CODE') {
        $accessor = sub {
            my $self = shift;
            if (@_) {
                Carp::croak("$class_name $accessor_name is a read-only property derived from @$calculate_from");
            }
            return $calculation_src->(map { $self->$_ } @$calculate_from);
        };
    }
    elsif ($calculation_src =~ /^[^\:\W]+$/) {
        # built-in formula like 'sum' or 'product'
        my $module_name = "UR::Object::Type::AccessorWriter::" . ucfirst(lc($calculation_src));
        my $exception = do {
            local $@;
            eval "use $module_name";
            $@;
        };
        die $exception if $exception;
        @src = (
            "sub ${class_name}::${accessor_name} {",
            'my $self = $_[0];',
            "${module_name}->calculate(\$self, [" . join(",", map { "'$_'" } @$calculate_from) . "], \@_)",
            '}'
        );
    }
    else {
        @src = (
            "sub ${class_name}::${accessor_name} {",
            ($params ? 'my ($self,%params) = @_;' : 'my $self = $_[0];'),
            (map { "my \$$_ = \$self->$_;" } @$calculate_from),
            ($params ? (map { "my \$$_ = delete \$params{'$_'};" } @$params) : ()),
            $calculation_src,
            '}'
        );
    }

    if (!$accessor) {
        if (@src) {
            my $src = join("\n",@src);
            #print ">>$src<<\n";
            my $exception = do {
                local $@;
                eval $src;
                $@;
            };
            if ($exception) {
                Carp::croak "ERROR IN CALCULATED PROPERTY SOURCE: $class_name $accessor_name\n$exception\n";
            }
            $accessor = \&{ $class_name . '::' . $accessor_name };
            unless ($accessor) {
                Carp::confess("Failed to generate code body for calculated property ${class_name}::${accessor_name}!");
            }
        }
        else {
            Carp::croak "Error implementing calcuation accessor for $class_name $accessor_name!";
        }
    }

    if ($accessor and $is_cached) {
        # Wrap the already-compiled accessor in another function to memoize the
        # result and save the data into the object
        my $calculator_sub = $accessor;
        $accessor = sub {
            if (@_ > 1) {
                Carp::croak("Cannot change property $accessor_name for class $class_name: cached calculated properties are read-only");
            }
            unless (exists $_[0]->{$accessor_name}) {
                $_[0]->{$accessor_name} = $calculator_sub->(@_);
            }
            return $_[0]->{$accessor_name};
        };

        # Make a method to clear the cached value and force another calculation
        my $invalidator_name;
        ($invalidator_name = $accessor_name) =~ s/^_+//;
        $invalidator_name = "__invalidate_${invalidator_name}__";
        Sub::Install::reinstall_sub({
            into => $class_name,
            as   => $invalidator_name,
            code => sub { delete $_[0]->{$accessor_name} },
        });
    }

    my $full_name = join( '::', $class_name, $accessor_name );
    $accessor = Sub::Name::subname $full_name => $accessor;
    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $accessor_name,
        code => $accessor,
    });

    return $accessor;
}

sub mk_dimension_delegate_accessors {
    my ($self, $accessor_name, $ref_class_name, $non_id_properties, $other_accessor_name, $is_transient) = @_;

    # Like mk_rw_accessor, but knows that this accessor is a foreign
    # key to a dimension table, and configures additional accessors.
    # Also makes this accessor "smart", to resolve the dimension
    # id only when needed.

    # Make EAV-like accessors for all of the remote properties
    my $class_name = $self->class_name;

    my $full_name = join( '::', $class_name, $other_accessor_name );
    my $other_accessor = Sub::Name::subname $full_name => sub {
        my $self = shift;
        my $delegate_id = $self->{$accessor_name};
        if (defined($delegate_id)) {
            # We're currently delegating.
            my $delegate = $ref_class_name->get($delegate_id);
            if (not @_) {
                # A simple get.  Delegate.
                return $delegate->$other_accessor_name(@_);
            }
            else {
                # We're setting a value.
                # Switch from delegating to local access.
                # We'll switch back next-time the dimension ID
                # is actually requested by its accessor
                # (farther below).
                my $old = $delegate->$other_accessor_name;
                my $new = shift;
                my $different;
                my $exception = do {
                    local $@;
                    $different = eval { no warnings; $old ne $new };
                    $@;
                };
                if ($different or $exception =~ m/has no overloaded magic/) {
                    $self->{$accessor_name} = undef;
                    for my $property (@$non_id_properties) {
                        if ($property eq $other_accessor_name) {
                            # set the value locally
                            $self->{$property} = $new;
                        }
                        else {
                            # grab the data from the (now previous) delegate
                            $self->{$property} = $delegate->$property;
                        }
                    }
                    $self->__signal_change__( $other_accessor_name, $old, $new ) unless $is_transient;
                    return $new;
                }
            }
        }
        else {
            # We are not currently delegating.
            if (@_) {
                # set
                my $old = $self->{ $other_accessor_name };
                my $new = shift;
                my $different;
                my $exception = do {
                    local $@;
                    $different = eval { no warnings; $old ne $new };
                    $@;
                };
                if ($different or $exception =~ m/has no overloaded magic/) {
                    $self->{ $other_accessor_name } = $new;
                    $self->__signal_change__( $other_accessor_name, $old, $new ) unless $is_transient;
                }
                return $new;
            }
            else {
                # get
                return $self->{ $other_accessor_name };
            }
        }
    };

    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $other_accessor_name,
        code => $other_accessor,
    });
}

sub mk_dimension_identifying_accessor {
    my ($self, $accessor_name, $ref_class_name, $non_id_properties, $is_transient) = @_;

    # Like mk_rw_accessor, but knows that this accessor is a foreign
    # key to a dimension table, and configures additional accessors.
    # Also makes this accessor "smart", to resolve the dimension
    # id only when needed.

    # Make EAV-like accessors for all of the remote properties
    my $class_name = $self->class_name;

    # Make the actual accessor for the id_by property
    my $full_name = join( '::', $class_name, $accessor_name );
    my $accessor = Sub::Name::subname $full_name => sub {
        if (@_ > 1) {
            my $old = $_[0]->{ $accessor_name };
            my $new = $_[1];
            my $different;
            my $exception = do {
                local $@;
                $different = eval { no warnings; $old ne $new };
                $@;
            };
            if ($different or $exception =~ m/has no overloaded magic/) {
                $_[0]->{ $accessor_name } = $new;
                $_[0]->__signal_change__( $accessor_name, $old, $new ) unless $is_transient;
            }
            return $new;
        }
        if (not defined $_[0]->{ $accessor_name }) {
            # Resolve an ID for the current set of values
            # Switch to delegating to that object.
            my %params;
            my $self = $_[0];
            @params{@$non_id_properties} = delete @$self{@$non_id_properties};
            my $delegate = $ref_class_name->get_or_create(%params);
            return undef unless $delegate;
            $_[0]->{ $accessor_name } = $delegate->id;
        }
        return $_[0]->{ $accessor_name };
    };

    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $accessor_name,
        code => $accessor,
    });
}

sub mk_rw_class_accessor
{
    my ($self, $class_name, $accessor_name, $column_name, $is_transient, $variable_value, $calc_default) = @_;

    my $full_accessor_name = $class_name . "::" . $accessor_name;
    my $accessor = Sub::Name::subname $full_accessor_name => sub {
            if (@_ > 1) {
                my $old = $variable_value;
                $variable_value = $_[1];

                my $different;
                my $exception = do {
                    local $@;
                    $different = eval { no warnings; $old ne $variable_value };
                    $@;
                };
                if ($different or $exception =~ m/has no overloaded magic/) {
                    $_[0]->__signal_change__( $accessor_name, $old, $variable_value ) unless $is_transient;
                }
            } elsif (defined $calc_default) {
                $variable_value = $calc_default->();
            }
            undef $calc_default;
            return $variable_value;
    };
    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $accessor_name,
        code => $accessor,
    });

}

sub mk_ro_class_accessor {
    my($self, $class_name, $accessor_name, $column_name, $variable_value, $calc_default) = @_;

    my $full_accessor_name = $class_name . "::" . $accessor_name;
    my $accessor = Sub::Name::subname $full_accessor_name => sub {
        if (@_ > 1) {
            my $new = $_[1];

            my $different;
            my $exception = do{
                local $@;
                $different = eval { no warnings; $variable_value ne $new };
                $@;
            };
            if ($different or $exception =~ m/has no overloaded magic/) {
                $new = defined($new) ? $new : '(undef)';
                my $report_variable_value = defined($variable_value) ? $variable_value : '(undef)';
                Carp::croak("Cannot change read-only class-wide property $accessor_name for class $class_name from $report_variable_value to $new!");
            }
        } elsif (defined $calc_default) {
            $variable_value = $calc_default->();
        }
        undef $calc_default;
        return $variable_value;
    };
    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $accessor_name,
        code => $accessor,
    });
}




sub mk_object_set_accessors {
    my ($self, $class_name, $singular_name, $plural_name, $reverse_as, $r_class_name, $where) = @_;

    # These are set by the resolver closure below, and kept in scope by the other closures
    my $rule_template;
    my $r_class_meta;
    my @property_names;
    my @where = ($where ? @$where : ());

    my $rule_resolver = sub {
        my ($obj) = @_;
        my $loading_r_class_error = '';
        if (defined $r_class_name) {
            my $exception = do {
                local $@;
                eval {
                    $r_class_meta = UR::Object::Type->is_loaded($r_class_name);
                    unless ($r_class_meta or __PACKAGE__->use_module_with_namespace_constraints($r_class_name)) {
                        # Don't die yet.  The named class may not have a file associated with it
                        $loading_r_class_error = "Couldn't load class $r_class_name: $@";
                        $@ = '';
                    }

                    unless ($r_class_meta) {
                        $r_class_name->class;
                        $r_class_meta = UR::Object::Type->get(class_name => $r_class_name);
                    }
                };
                $@;
            };
            if ($exception) {
                $loading_r_class_error .= "Couldn't get class object for $r_class_name: $exception";
            }
        }
        if ($r_class_meta and not $reverse_as) {
            # We have a real class on the other end, and it did not specify know to link back to us.
            # Try to infer how, otherwise fall back to the same logic we use with "primitives".
            my @possible_relationships = grep { $_->data_type eq $class_name }
                                         grep { defined $_->data_type }
                                         $r_class_meta->all_property_metas();

            if (@possible_relationships > 1) {
                Carp::croak "$class_name has an ambiguous definition for property \"$singular_name\"."
                    . "  The target class $r_class_name has " . scalar(@possible_relationships)
                    . " relationships which reference back to $class_name."
                    . "  Correct by adding \"reverse_as => X\" to ${class_name}'s \"$singular_name\" definition one of the following values:  "
                    . join(",",map { '"' . $_->delegation_name . '"' } @possible_relationships) . ".\n";
            }
            elsif (@possible_relationships == 1) {
                $reverse_as = $possible_relationships[0]->property_name;
            }
            elsif (@possible_relationships == 0) {
                # we now fall through to the logic below and try direct arrayref storage
                #die "No relationships found between $r_class_name and $class_name.  Error in definition for $class_name $singular_name!"
            }
        }
        if ($reverse_as and ! $r_class_meta) {
            # we've resolved reverse_as, but there's not r_class_meta?!
            $self->error_message("Can't resolve reverse relationship $class_name -> $plural_name.  No class metadata for $r_class_name");
            if ($loading_r_class_error) {
                Carp::croak "While loading $r_class_name: $loading_r_class_error";
            } else {
                Carp::croak "Is class $r_class_name defined anywhere?";
            }
        }

        if ($reverse_as) {
            # join to get the data...
            unless ($r_class_meta) {
                Carp::croak("No remote class metadata found for class $r_class_name while resolving property '$singular_name' of class $class_name");
            }
            my $property_meta = $r_class_meta->property_meta_for_name($reverse_as);
            unless ($property_meta) {
                Carp::croak "Can't resolve reverse relationship $class_name -> $plural_name.  Remote class $r_class_name has no property $reverse_as";
            }
            my @get_params;
            if ($property_meta->via) {
                # get_property_name_pairs_for_join() only works for properties connected directly.
                # we still need to use it during initialization, but for more complicated relationships
                # this should do the right thing
                push @get_params, $property_meta->property_name . '.id' => $obj->id;
                push @property_names, 'id';
            } else {
                my @property_links = $property_meta->get_property_name_pairs_for_join;
                for my $link (@property_links) {
                    my $my_property_name = $link->[1];
                    push @property_names, $my_property_name;
                    unless ($obj->can($my_property_name)) {
                        Carp::croak "Cannot handle indirect relationship $r_class_name -> $reverse_as.  Class $class_name has no property named $my_property_name";
                    }
                    push @get_params, $link->[0], ($obj->$my_property_name || undef);
                }
            }

            if (my $id_class_by = $property_meta->id_class_by) {
                push @get_params, $id_class_by, $obj->class;
                push @property_names, 'class';
            }
            my $tmp_rule = $r_class_name->define_boolexpr(@get_params,@where);
            if (my $order_by = $property_meta->order_by) {
                push @get_params, $order_by;
            }
            $rule_template = $tmp_rule->template;
            unless ($rule_template) {
                Carp::croak "Error generating rule template to handle indirect relationship $class_name $singular_name referencing $r_class_name!";
            }
            return $tmp_rule;
        }
        else {
            # data is stored locally on the hashref
            #die "No relationships found between $r_class_name and $class_name.  Error in definition for $class_name $singular_name!"
        }
    };

    my @where_values;
    for (my $i = 1; $i < @where; $i+=2) {
        if (ref($where[$i]) eq 'HASH' and exists($where[$i]->{'operator'})) {
            push @where_values, $where[$i]->{'value'};  # the operator is already stored in the template
        } else {
            push @where_values, $where[$i];
        }
    }

    # These will behave specially if the rule does not specify the ID, or all of the ID.
    my @params_prefix;
    my $params_prefix_resolved = 0;
    my $params_prefix_resolver = sub {
        # handle the case of has-many primitives
        return unless $r_class_meta;

        my $r_ids = $r_class_meta->property_meta_for_name($reverse_as)->{id_by};

        my $cmeta = UR::Object::Type->get($class_name);
        my $pmeta = $plural_name ? $cmeta->{has}{$plural_name} : $cmeta->{has}{$singular_name};
        if (my $specify_by = $pmeta->{specify_by}) {
            @params_prefix = ($specify_by);
        }
        else {
            # TODO: should this really be an auto-setting of the specify_by meta property?
            my @id_property_names = $r_class_name->__meta__->id_property_names;
            @params_prefix =
                grep {
                    my $id_property_name = $_;
                    ( (grep { $id_property_name eq $_ } @$r_ids) ? 0 : 1)
                }
                @id_property_names;

            # We only do the special single-value spec when there is one property not specified by the rule.
            # This is common for a multi-column primary key where all columns reference a parent object, except an index value, etc.
            @params_prefix = () unless scalar(@params_prefix) == 1;
        }
        $params_prefix_resolved = 1;
    };

    if (!$plural_name || $singular_name ne $plural_name) {
        my $single_accessor = Sub::Name::subname $class_name ."::$singular_name" => sub {
            my $self = shift;
            my $rule;
            $rule = $rule_resolver->($self) unless (defined $rule_template);
            if ($rule_template) {
                $rule = $rule_template->get_rule_for_values((map { $self->$_ } @property_names), @where_values) unless (defined $rule);
                $params_prefix_resolver->() unless $params_prefix_resolved;
                unshift @_, @params_prefix if @_ == 1;
                if (@_) {
                    return my $obj = $r_class_name->get($rule->params_list,@_);
                }
                else {
                    return my $obj = $r_class_name->get($rule);
                }
            }
            else {
                return unless $self->{$plural_name};
                return unless @_;  # Can't compare our list to nothing...
                if (@_ > 1) {
                    Carp::croak "rule-based selection of single-item accessor not supported.  Instead of single value, got @_";
                }
                unless (ref($self->{$plural_name}) eq 'ARRAY') {
                    Carp::croak("${class_name}::$singular_name($_[0]): $plural_name does not contain an arrayref");
                }
                no warnings 'uninitialized';
                my @matches = grep { $_ eq $_[0]  } @{ $self->{$plural_name} };
                return $matches[0] if @matches < 2;
                return $self->context_return(@matches);
            }
        };
        Sub::Install::reinstall_sub({
            into => $class_name,
            as   => $singular_name,
            code => $single_accessor,
        });

        # return now for reverse_as but not is_many
        unless ($plural_name) {
            return;
        }
    }

    my $rule_name = $self->rule_accessor_name_for_is_many_accessor($plural_name);
    my $rule_accessor = Sub::Name::subname $class_name ."::$rule_name" => sub {
        my $self = shift;
        $rule_resolver->($self) unless ($rule_template);
        unless ($rule_template) {
            Carp::croak "No indirect rule available for locally-stored 'has-many' relationship";
        }
        if (@_) {
            my $tmp_rule = $rule_template->get_rule_for_values((map { $self->$_ } @property_names), @where_values);
            return $r_class_name->define_boolexpr($tmp_rule->params_list, @_);
        }
        else {
            return $rule_template->get_rule_for_values((map { $self->$_ } @property_names),@where_values);
        }
    };

    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $rule_name,
        code => $rule_accessor,
    });

    my $list_accessor = Sub::Name::subname $class_name ."::$plural_name" => sub {
        my $self = shift;
        my $rule;
        $rule = $rule_resolver->($self) unless (defined $rule_template);
        if ($rule_template) {
            $rule = $rule_template->get_rule_for_values((map { $self->$_ } @property_names), @where_values) unless (defined $rule);
            if (@_) {
                return $UR::Context::current->query($r_class_name, $rule->params_list,@_);
            }
            else {
                return $UR::Context::current->query($r_class_name, $rule);
            }
        }
        else {
            if (@_) {
                if (@_ != 1) {
                    Carp::croak "expected a single arrayref when setting a multi-value $class_name $plural_name!  Got " . scalar(@_) . " args";
                } elsif ( ref($_[0]) ne 'ARRAY' ) {
                    $self->{$plural_name} = [ $_[0] ];
                } else {
                    $self->{$plural_name} = [ @{$_[0]} ];
                }
                return @{ $self->{$plural_name} };
            }
            else {
                return unless $self->{$plural_name};
                if (ref($self->{$plural_name}) ne 'ARRAY') {
                    Carp::carp("$class_name with id ".$self->id." does not hold an arrayref in its $plural_name property");
                    $self->{$plural_name} = [ $self->{$plural_name} ];
                }
                return @{ $self->{$plural_name} };
            }
        }
    };

    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $plural_name,
        code => $list_accessor,
    });

    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $singular_name . '_list',
        code => $list_accessor,
    });

    my $arrayref_name = $self->arrayref_accessor_name_for_is_many_accessor($plural_name);
    my $arrayref_accessor = Sub::Name::subname $class_name ."::$arrayref_name" => sub {
        return [ $list_accessor->(@_) ];
    };

    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $arrayref_name,
        code => $arrayref_accessor,
    });

    my $iterator_name = $self->iterator_accessor_name_for_is_many_accessor($plural_name);
    my $iterator_accessor = Sub::Name::subname $class_name ."::$iterator_name" => sub {
        my $self = shift;
        my $rule;
        $rule = $rule_resolver->($self) unless (defined $rule_template);
        if ($rule_template) {
            $rule = $rule_template->get_rule_for_values((map { $self->$_ } @property_names), @where_values) unless (defined $rule);
            if (@_) {
                return $r_class_name->create_iterator($rule->params_list,@_);
            } else {
                return UR::Object::Iterator->create_for_filter_rule($rule);
            }
        }
        else {
            return UR::Value::Iterator->create_for_value_arrayref($self->{$plural_name} || []);
        }
    };
    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $iterator_name,
        code => $iterator_accessor,
    });

    my $set_name = $self->set_accessor_name_for_is_many_accessor($plural_name);
    my $set_accessor = Sub::Name::subname $class_name ."::$set_name" => sub {
        my $self = shift;
        my $rule;
        $rule = $rule_resolver->($self) unless (defined $rule_template);
        if ($rule_template) {
            $rule = $rule_template->get_rule_for_values((map { $self->$_ } @property_names),@where_values) unless (defined $rule);
            return $r_class_name->define_set($rule->params_list,@_);
        }
        else {
            # this is a bit inside-out, but works for primitives
            my @members = $self->$plural_name;
            return UR::Value->define_set(id => \@members);
        }
    };
    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $set_name,
        code => $set_accessor,
    });

    my $adder_method_name = $self->adder_name_for_is_many_accessor($plural_name);
    if ($class_name->can($adder_method_name)) {
        $adder_method_name = '__' . $adder_method_name;
    }
    my $adder_method = Sub::Name::subname $class_name . '::' . $adder_method_name => sub {
        # TODO: this handles only a single item when making objects: support a list of hashrefs
        my $self = shift;
        my $rule;
        $rule = $rule_resolver->($self) unless (defined $rule_template);
        if ($rule_template) {
            $params_prefix_resolver->() unless $params_prefix_resolved;
            unshift @_, @params_prefix if @_ == 1;
            $rule = $rule_template->get_rule_for_values((map { $self->$_ } @property_names), @where_values) unless (defined $rule);
            $r_class_name->create($rule->params_list,@_);
        }
        else {
            if ($r_class_meta) {
                my $obj;
                if (@_ == 1 and $_[0]->isa($r_class_name)) {
                    $obj = $_[0];
                }
                else {
                    $obj = $r_class_name->create(@where,@_);
                    unless ($obj) {
                        $self->error_message("Failed to add $singular_name:" . $r_class_name->error_message);
                        return;
                    }
                }
                push @{ $self->{$plural_name} ||= [] }, $obj;
            }
            else {
                if (@_ != 1) {
                    Carp::croak "$class_name $adder_method_name expects a single value to add.  Got " . scalar(@_) . " args";
                }
                push @{ $self->{$plural_name} ||= [] }, $_[0];
                return $_[0];
            }
        }
    };
    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $adder_method_name,
        code => $adder_method,
    });

    my $remover_method_name = $self->remover_name_for_is_many_accessor($plural_name);
    if ($class_name->can($remover_method_name)) {
        $remover_method_name = '__' . $remover_method_name;
    }
    my $remover_method = Sub::Name::subname $class_name . '::' . $remover_method_name => sub {
        my $self = shift;
        my $rule;
        $rule = $rule_resolver->($self) unless (defined $rule_template);
        if ($rule_template) {
            # an id-linked "has-many"
            $rule = $rule_template->get_rule_for_values((map { $self->$_ } @property_names), @where_values) unless (defined $rule);
            $params_prefix_resolver->() unless $params_prefix_resolved;
            my @matches;
            if (@_ == 1 and ref($_[0])) {
                # the object to remove was passed-in
                unless ($rule->evaluate($_[0])) {
                    Carp::croak "Object " . $_[0]->__display_name__ . " is not a member of the $singular_name set!";
                }
                @matches = ($_[0]);
            }
            else {
                # the parameters to find objects to remove were passed-in
                unshift @_, @params_prefix if @_ == 1; # a single "id" is the remainder of the id of the object
                @matches = $r_class_name->get($rule->params_list,@_);
            }
            my $trans = UR::Context::Transaction->begin;
            @matches = map {
                $_->delete or Carp::croak "Error deleting $r_class_name " . $_->id . " for $remover_method_name!: " . $_->error_message;
            } @matches;
            $trans->commit;
            return @matches;
        }
        else {
            # direct storage in an arrayref
            $self->{$plural_name} ||= [];
            if ($r_class_meta) {
                # object
                my @remove;
                my @keep;
                my $rule = $r_class_name->define_boolexpr(@_);
                for my $value (@{ $self->{$plural_name} }) {
                    if ($rule->evaluate($value)) {
                        push @keep, $value;
                    }
                    else {
                        push @remove, $value;
                    }
                }
                if (@remove) {
                    @{ $self->{$plural_name} } = @keep;
                }
                return @remove;
            }
            else {
                # value (or non-ur object)
                if (@_ == 1) {
                    # remove specific value
                    my $removed;
                    my $n = 0;
                    for my $value (@{ $self->{$plural_name} }) {
                        if ($value eq $_[0]) {
                            $removed = splice(@{ $self->{$plural_name} }, $n, 1);
                            Carp::croak("Internal object inconsistency removing value '$value'.  Value '$removed' was removed instead!?") unless $removed eq $value;
                            return $removed;
                        }
                        $n++;
                    }
                    Carp::croak("Failed to find item $_[0] in $class_name $plural_name.   Object has " . scalar(@{$self->{$plural_name}}) . " values: ".join(', ', @{$self->{$plural_name}}));
                }
                elsif (@_ == 0) {
                    # remove all if no params are specified
                    @{ $self->{$plural_name} ||= [] } = ();
                }
                else {
                    Carp::croak("$class_name $remover_method_name should be called with zero or one arg, got ".scalar(@_));
                }
            }
        }
    };

    # check here
    Sub::Install::reinstall_sub({
        into => $class_name,
        as   => $remover_method_name,
        code => $remover_method,
    });

}

use Data::Dumper;

sub initialize_direct_accessors {
    my $self = shift;
    my $class_name = $self->{class_name};

    my %id_property_names;
    for my $property_name (@{ $self->{id_by} }) {
        $id_property_names{$property_name} = 1;
        next if $property_name eq "id";
    }

    my %dimensions_by_fk;
    for my $property_name (sort keys %{ $self->{has} }) {
        my $property_data = $self->{has}{$property_name};
        if ($property_data->{is_dimension}) {
            my $id_by = $property_data->{id_by};
            unless ($id_by) {
                Carp::croak "No id_by specified for dimension $property_name?";
            }
            if (@$id_by != 1) {
                Carp::croak "The id_by specified for dimension $property_name must list a single property name!";
            }

            my $dimension_class_name = $property_data->{data_type};
            $dimensions_by_fk{$id_by->[0]} = $dimension_class_name;

            my $ref_class_meta = $dimension_class_name->__meta__;
            my %remote_id_properties = map { $_ => 1 } $ref_class_meta->id_property_names;
            my @non_id_properties = grep { not $remote_id_properties{$_} } $ref_class_meta->all_property_names;
            for my $expected_delegate_property_name (@non_id_properties) {
                unless ($self->{has}{$expected_delegate_property_name}) {
                    $self->{has}{$expected_delegate_property_name} = {
                        $self->_normalize_property_description(
                            $expected_delegate_property_name,
                            { via => $property_name, to => $expected_delegate_property_name, implied_by => $property_name }
                        )
                    }
                }
            }
        }
    }

    for my $pname (sort keys %{ $self->{has} }) {
        my $property_name = $pname; # mutable
        my $accessor_name = $pname;

        my $property_data = $self->{has}{$property_name};

        # handle aliases
        # the underlying property_name and data will change, though the accessor will not
        my $n = 0;
        while ($property_data->{via} and $property_data->{via} eq '__self__') {
            $property_name = $property_data->{to};
            $property_data = $self->{has}{$property_name};
            unless ($property_data) {
                Carp::confess("Property $accessor_name is an alias for $property_name, which does not exist!")
            }
            if ($n > 100) {
                Carp::confess("Deep recursion in property aliases behind $accessor_name!");
            }
        }

        my $column_name = $property_data->{column_name};
        my $is_transient = $property_data->{is_transient};
        my $where = $property_data->{where};

        do {
            # Handle the case where the software module has an explicit
            # override for one of the accessors.
            no strict 'refs';
            my $isa = \@{ $class_name . "::ISA" };
            my @old_isa = @$isa;
            @$isa = ();
            if ($class_name->can($accessor_name)) {
                #warn "property $class_name $accessor_name exists!";
                $accessor_name = "__$accessor_name";
            }
            @$isa = @old_isa;
        };

        unless ($accessor_name) {
            Carp::croak("No accessor name for property '$property_name' of class $class_name");
        }

        my $accessor_type;
        my @calculation_fields = (qw/calculate calc_perl calc_sql calculate_from/);
        if (my $id_by = $property_data->{id_by}) {
            my $r_class_name = $property_data->{data_type};
            #$self->mk_id_based_object_accessor($class_name, $accessor_name, $id_by, $r_class_name,$where);
            my $id_class_by = $property_data->{id_class_by};
            if ($property_data->{access_as} and $property_data->{access_as} eq 'auto') {
                $self->mk_id_based_flex_accessor($class_name, $accessor_name, $id_by, $r_class_name,$where, $id_class_by);
                $self->mk_id_based_object_accessor($class_name, $accessor_name . ($property_data->{is_many} ? '_objs' : '_obj'), $id_by, $r_class_name,$where, $id_class_by);
            }
            else {
                $self->mk_id_based_object_accessor($class_name, $accessor_name, $id_by, $r_class_name,$where, $id_class_by);
            }
        }
        elsif ($property_data->{'is_calculated'} and ! $property_data->{'is_mutable'}) {# and $property_data->{'column_name'}) {
            # For calculated + immutable properties, their calculation function is called
            # by UR::Context->create_entity(), which then stores the value in the object's
            # hash.  So, the accessor just needs to pull the data like a regular r/o accessor
            #$self->mk_ro_accessor($class_name, $accessor_name, $property_data->{'column_name'});
            $self->mk_calculation_accessor(
                $class_name,
                $accessor_name,
                $property_data->{'calculate'},
                $property_data->{calculate_from},
                $property_data->{calculate_params},
                1,  # the value should be cached
                $property_data->{'column_name'},
            );
        }
        elsif (my $via = $property_data->{via}) {
            my $to = $property_data->{to} || $property_data->{property_name};
            if ($via eq '__self__') {
                Carp::croak "aliases should be caught above!";

            }
            if ($property_data->{is_mutable}) {
                my $singular_name;
                if ($property_data->{'is_many'}) {
                    require Lingua::EN::Inflect;
                    $singular_name = Lingua::EN::Inflect::PL_V($accessor_name);
                }
                $self->mk_indirect_rw_accessor($class_name,$accessor_name,$via,$to,$where,$property_data->{'is_many'} && $singular_name, $property_name);
            }
            else {
                $self->mk_indirect_ro_accessor($class_name,$accessor_name,$via,$to,$where);
            }
        }
        elsif (my $calculate = $property_data->{calculate}) {
            $self->mk_calculation_accessor(
                $class_name,
                $accessor_name,
                $property_data->{calculate},
                $property_data->{calculate_from},
                $property_data->{calculate_params},
                $property_data->{is_constant},
                $property_data->{column_name},
            );
        }
        elsif (my $calculate_sql = $property_data->{'calculate_sql'}) {
            # The data gets filled in by the object loader behind the scenes.
            # To the user, it's a read-only property
            $self->mk_ro_accessor($class_name, $accessor_name, $calculate_sql);

        }
        elsif ($property_data->{is_many} or $property_data->{reverse_as}){
            my $reverse_as = $property_data->{reverse_as};
            my $r_class_name = $property_data->{data_type};
            my $singular_name;
            my $plural_name;
            if ($property_data->{is_many}) {
                $plural_name = $accessor_name;
                $singular_name = $self->singular_accessor_name_for_is_many_accessor($accessor_name);
            }
            else {
                $singular_name = $accessor_name;
            }
            $self->mk_object_set_accessors($class_name, $singular_name, $plural_name, $reverse_as, $r_class_name, $where);
        }
        elsif ($property_data->{'is_classwide'}) {
            my($value, $column_name, $is_transient, $calc_default)
                = @$property_data{'default_value','column_name','is_transient', 'calculated_default'};
            if ($property_data->{'is_constant'}) {
                $self->mk_ro_class_accessor($class_name,$accessor_name,$column_name,$value, $calc_default);
            } else {
                $self->mk_rw_class_accessor($class_name,$accessor_name,$column_name,$is_transient,$value, $calc_default);
            }
        }
        else {
            # Just use key/value pairs in the hash for normal
            # table stuff, and also non-database stuff.

            #if ($column_name) {
            #    push @$props, $property_name;
            #    push @$cols, $column_name;
            #}

            my $maker;
            if ($id_property_names{$property_name} or not $property_data->{is_mutable}) {
                $maker = 'mk_ro_accessor';
            }
            else {
            	$maker = 'mk_rw_accessor';
            }
            $self->$maker($class_name, $accessor_name, $column_name, $property_name,$is_transient);
        }
    }

    # right now we just stomp on the default accessors constructed above where they are:
    # 1. the fk behind a dimensional relationships
    # 2. the indirect properties created for the dimensional relationship
    for my $dimension_id (keys %dimensions_by_fk) {
        my $dimension_class_name = $dimensions_by_fk{$dimension_id};
        my $ref_class_meta = $dimension_class_name->__meta__;
        my %remote_id_properties = map { $_ => 1 } $ref_class_meta->id_property_names;
        my @non_id_properties = grep { not $remote_id_properties{$_} } $ref_class_meta->all_property_names;
        for my $added_property_name (@non_id_properties) {
            $self->mk_dimension_delegate_accessors($dimension_id,$dimension_class_name, \@non_id_properties, $added_property_name);
        }
        $self->mk_dimension_identifying_accessor($dimension_id,$dimension_class_name, \@non_id_properties);
    }

    return 1;
}


1;

=pod

=head1 NAME

UR::Object::Type::AccessorWriter - Helper module for UR::Object::Type responsible for creating accessors for properties

=head1 DESCRIPTION

Subroutines within this module actually live in the UR::Object::Type
namespace;  this module is just a convienent place to collect them.  The
class initializer uses these subroutines when it's time to create accessor
methods for a newly defined class.  Each accessor is implemented by a closure
that is then assigned a name by Sub::Name and inserted into the defined
class's namespace by Sub::Install.

=head1 METHODS

=over 4

=item initialize_direct_accessors

  $classobj->initialize_direct_accessors();

This is the entry point into the accessor writing system.  It inspects each
item in the 'has' key of the class object's hashref, and creates methods for
each property.

=item mk_rw_accessor

  $classobj->mk_rw_accessor($class_name, $accessor_name, $column_name, $property_name, $is_transient);

Creates a mutable accessor named $accessor_name which stores its value in
the $property_name key of the object's hashref.

=item mk_ro_accessor

  $classobj->mk_ro_accessor($class_name, $accessor_name, $column_name, $property_name);

Creates a read-only accessor named $accessor_name which retrieves its value
in the $property_name key of the object's hashref.  If the method is used
as a mutator by passing in a value to the method, it will throw an exception
with Carp::croak.

=item mk_id_based_object_accessor

  $classobj->mk_id_based_object_accessor($class_name, $accessor_name, $id_by,
                                         $r_class_name, $where);

Creates an object accessor named $accessor_name.  It returns objects of type
$r_class_name, id-ed by the parameters named in the $id_by arrayref.  $where
is an optional  listref of additional filters to apply when retrieving
objects.

The behavior of the created accessor depends on the number of parameters
passed to it.  For 0 params, it retrieves the object pointed to by
$r_class_name and $id_by.  For 1 param, it looks up the ID param values
of the passed-in object-parameter, and reassigns value stored in the $id_by
properties of the acted-upon object, effectively acting as a mutator.

For more than 1 param, the additional parameters are taken as
properties/values to filter the returned objects on

=item mk_indirect_ro_accessor

  $classobj->mk_indirect_ro_accessor($class_name, $accessor_name, $via, $to, $where);

Creates a read-only via accessor named $accessor_name.  Its value is
obtained by calling the object accessor named $via, and then calling
the method $to on that object.  The optional $where listref is used
as additional filters when calling $via.

=item mk_indirect_rw_accessor

    $classobj->mk_indirect_rw_accessor($class_name, $accessor_name, $via, $to,
                                       $where, $singular_name);

Creates a via accessor named $accessor_name that is able to change the
property it points to with $to when called as a mutator.  If the $to property
on the remote object is an ID property of its class, it deletes the refered-to
object and creates a new one with the appropriate properties.  Otherwise, it
updates the $to property on the refered-to object.

=item mk_calculation_accessor

    $classobj->mk_calculation_accessor($class_name, $accessor_name, $calculation_src,
                                       $calculate_from, $params, $is_constant, $column_name);

Creates a calculated accessor called $accessor_name.  If the $is_constant
flag is true, then the accessor runs the calculation once, caches the result,
and returns that result for subsequent calls to the accessor.

$calculation_src can be one of: coderef, string containing Perl code, or
the name of a module under UR::Object::Type::AccessorWriter which has a
method called C<calculate>.  If $calculation_src is empty, then $accessor_name
must be the name of an already-existing subroutine in the class's namespace.

=item mk_dimension_delegate_accessors

=item mk_dimension_identifying_accessor

These create accessors for dealing with dimension tables in OLAP-type schemas.
They need more documentation.

=item mk_rw_class_accessor

  $classobj->mk_rw_class_accessor($class_name, $accessor_name, $column_name, $is_transient, $variable_value);

Creates a read-write accessor called $accessor_name which stores its value
in a scalar captured by the accessor's closure.  Since the closure is
inserted into the class's namespace, all instances of the class share the
same closure (and therefore the same scalar), and the property effectively
acts as a class-wide property.

=item mk_ro_class_accessor

  $classobj->mk_ro_class_accessor($class_name, $accessor_name, $column_name, $variable_value);

Creates a read-only accessor called $accessor_name which retrieves its value
from a scalar captured by the accessor's closure.  The value is initialized
to $variable_value.  If called as a mutator, it throws an exception through
Carp::croak

=back

=head1 SEE ALSO

UR::Object::Type::AccessorWriter, UR::Object::Type

=cut
