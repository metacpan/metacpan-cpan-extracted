
package UR::Namespace::Command::Update::ClassDiagram;



use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::Base',
    has => [ 
        data_source => {type => 'String', doc => 'Which datasource to use', is_optional => 1},
        depth => { type => 'Integer', doc => 'Max distance of related classes to include.  Default is 1.  0 means show only the named class(es), -1 means to include everything', is_optional => 1},
        file => { type => 'String', doc => 'Pathname of the Umlet (.uxf) file' },
        show_attributes => { type => 'Boolean', is_optional => 1, default => 1, doc => 'Include class attributes in the diagram' },
        show_methods => { type => 'Boolean', is_optional => 1, default => 0, doc => 'Include methods in the diagram (not implemented yet' },
        include_ur_object => { type => 'Boolean', is_optional => 1, default => 0, doc => 'Include UR::Object and UR::Entity in the diagram (default = no)' },
        initial_name => {
            is_many => 1,
            is_optional => 1,
            shell_args_position => 1
        }
    ],
);

sub sub_command_sort_position { 4 };

sub help_brief {
    "Update an Umlet diagram based on the current class definitions"
}

sub help_detail {
    return <<EOS;
Creates a new Umlet diagram, or updates an existing diagram.  Bare arguments
are taken as class names to include in the diagram.  Other classes may be
included in the diagram based on their distance from the names classes
and the --depth parameter.

If an existing file is being updated, the position of existing elements 
will not change.

EOS
}

# The max X coord to use when placing boxes.  After this, move down a line and go back to the left
use constant MAX_X_AUTO_POSITION => 800;

sub execute {
    my $self = shift;

    my $params = shift;
    
#$DB::single = 1;
    my $namespace = $self->namespace_name;
    eval "use $namespace";
    if ($@) {
        $self->error_message("Failed to load module for $namespace: $@");
        return;
    }

    my @initial_name_list = $self->initial_name;

    my $diagram;
    if (-f $params->{'file'}) {
        $params->{'depth'} = 0 unless (exists $params->{'depth'});  # Default is just update what's there
        $diagram = UR::Object::Umlet::Diagram->create_from_file($params->{'file'});
        push @initial_name_list, map { $_->subject_id } UR::Object::Umlet::Class->get(diagram_name => $diagram->name);
    } else {
        $params->{'depth'} = 1 unless exists($params->{'depth'});
        $diagram = UR::Object::Umlet::Diagram->create(name => $params->{'file'});
    }

    # FIXME this can get removed when attribute defaults work correctly
    unless (exists $params->{'show_attributes'}) {
        $self->show_attributes(1);
    }
        
    my @involved_classes;
    foreach my $class_name ( @initial_name_list ) {
        push @involved_classes, UR::Object::Type->get(class_name => $class_name);
    }

    push @involved_classes, $self->_get_related_classes_via_inheritance(
                                                        names => \@initial_name_list,
                                                        depth => $params->{'depth'},
                                                      );

    push @involved_classes, $self->_get_related_classes_via_properties(
                                                        #names => [ map { $_->class_name } @involved_classes ],
                                                        names => \@initial_name_list,
                                                        depth => $params->{'depth'},
                                                      );
    my %involved_class_names = map { $_->class_name => $_ } @involved_classes;

    # The initial placement, and how much to move over for the next box
    my($x_coord, $y_coord, $x_inc, $y_inc) = (20,20,40,40);
    my @objs = sort { $b->y <=> $a->y or $b->x <=> $a->x } UR::Object::Umlet::Class->get();
    if (@objs) {
        my $maxobj = $objs[0];
        $x_coord = $maxobj->x + $maxobj->width + $x_inc;
        $y_coord = $maxobj->y + $maxobj->height + $y_inc;
    }
    

    # First, place all the classes
    my @all_boxes = UR::Object::Umlet::Class->get( diagram_name => $diagram->name );
    foreach my $class ( values %involved_class_names ) {
        my $umlet_class = UR::Object::Umlet::Class->get(diagram_name => $diagram->name,
                                                        subject_id => $class->class_name);
        my $created = 0;
        unless ($umlet_class) {
            $created = 1;
            $umlet_class = UR::Object::Umlet::Class->create( diagram_name => $diagram->name,
                                                             subject_id => $class->class_name,
                                                             label => $class->class_name,
                                                             x => $x_coord,
                                                             y => $y_coord,
                                                           );
             # add the attributes
             if ($self->show_attributes) {
                my $attributes = $umlet_class->attributes || [];
                my %attributes_already_in_diagram = map { $_->{'name'} => 1 } @{ $attributes };
                my %id_properties = map { $_ => 1 } $class->id_property_names;
    
                my $line_count = scalar @$attributes;
                foreach my $property_name ( $class->direct_property_names ) {
                    next if $attributes_already_in_diagram{$property_name};
                    $line_count++;
                    my $property = UR::Object::Property->get(class_name => $class->class_name, property_name => $property_name);
                    push @$attributes, { is_id => $id_properties{$property_name} ? '+' : ' ',
                                         name => $property_name,
                                         type => $property->data_type,
                                         line => $line_count,
                                       };
                }
                $umlet_class->attributes($attributes);
            }

            if ($self->show_methods) {
                # Not implemented yet
                # Use the same module the schemabrowser uses to get that info
            }

            # Make sure this box dosen't overlap other boxes
            while(my $overlapped = $umlet_class->is_overlapping(@all_boxes) ) {
                if ($umlet_class->x > MAX_X_AUTO_POSITION) {
                    $umlet_class->x(20);
                    $umlet_class->y( $umlet_class->y + $y_inc);
                } else {
                    $umlet_class->x( $overlapped->x + $overlapped->width + $x_inc );
                }
            }
                                                            
            push @all_boxes, $umlet_class;
        }

        if ($created) {
            $x_coord = $umlet_class->x + $umlet_class->width + $x_inc;
            if ($x_coord > MAX_X_AUTO_POSITION) {
                $x_coord = 20;
                $y_coord += $y_inc;
            }
        }
    }

    # Next, connect the classes together
    foreach my $class ( values %involved_class_names ) {
        my @properties = grep { $_->is_delegated and $_->data_type} $class->all_property_metas();
        foreach my $property ( @properties ) {

            next unless (exists $involved_class_names{$property->data_type});

            my @property_links = eval { $property->get_property_name_pairs_for_join };
            next unless @property_links;

            my $id_by = join(':', map { $_->[0] } @property_links);
            my $their_id_by = join (':', map { $_->[1] } @property_links);

            my $umlet_relation = UR::Object::Umlet::Relation->get( diagram_name => $diagram->name,
                                                                   from_entity_name => $property->class_name,
                                                                   to_entity_name => $property->data_type,
                                                                   from_attribute_name => $id_by,
                                                                   to_attribute_name => $their_id_by,
                                                                 );
            unless ($umlet_relation) {                             
                $umlet_relation = UR::Object::Umlet::Relation->create( diagram_name => $diagram->name,
                                                                       relation_type => '&lt;-',
                                                                       from_entity_name => $property->class_name,
                                                                       to_entity_name => $property->data_type,
                                                                       from_attribute_name => $id_by,
                                                                       to_attribute_name => $their_id_by,
                                                                     );
                 unless ($umlet_relation->connect_entity_attributes()) {
                     # This didn't link to anything on the diagram
                     $umlet_relation->delete;
                 }
            }

        }

        foreach my $parent_class_name ( @{ $class->is } ) {
            next unless ($involved_class_names{$parent_class_name});

            my $umlet_relation = UR::Object::Umlet::Relation->get( diagram_name => $diagram->name,
                                                                   from_entity_name => $class->class_name,
                                                                   to_entity_name => $parent_class_name,
                                                                 );
            unless ($umlet_relation) {
                $umlet_relation = UR::Object::Umlet::Relation->create( diagram_name => $diagram->name,
                                                                       relation_type => '&lt;&lt;-',
                                                                       from_entity_name => $class->class_name,
                                                                       to_entity_name => $parent_class_name,
                                                                     );
                 $umlet_relation->connect_entities();
            }
        }
    }

    $diagram->save_to_file($params->{'file'});

    1;
}



sub _get_related_classes_via_properties {
    my($self, %params) = @_;

    return unless (@{$params{'names'}});
    return unless $params{'depth'};

    # Make sure the named classes are loaded
    foreach ( @{ $params{'names'} } ) {
        eval { $_->class };
    }

    # Get everything linked to the named things
    my @related_names = grep { eval { $_->class } }
                        #grep { $_ }
                        map { $_->data_type }
                        map { UR::Object::Property->get(class_name => $_ ) }
                        @{ $params{'names'}};
    push @related_names, grep { eval { $_->class } }
                         #grep { $_ }
                         map { $_->class_name }
                         map { UR::Object::Property->get(data_type => $_ ) }
                         @{ $params{'names'}};
    return unless @related_names;

    my @objs = map { UR::Object::Type->get(class_name => $_) } @related_names;

    #my @related_names = grep { $_ } map { $_->$related_param } $related_class->get($item_param => $params{'names'});
    #push @related_names, grep { $_ } map { $_->$item_param } $related_class->get($related_param => $params{'names'});
    #return unless @related_names;
#
#    my @objs = $item_class->get($item_param => \@related_names);

    unless ($self->include_ur_object) {
        # Prune out UR::Object and UR::Entity
        @objs = grep { $_->class_name ne 'UR::Object' and $_->class_name ne 'UR::Entity' } @objs;
    }

    # make a recursive call to get the related objects by name
    return ( @objs, $self->_get_related_classes_via_properties( %params, names => \@related_names, depth => --$params{'depth'}) );
}
    
sub _get_related_classes_via_inheritance {
    my($self,%params) = @_;

    return unless (@{$params{'names'}});
    return unless $params{'depth'};

    my @related_class_names;
    foreach my $class_name ( @{ $params{'names'} } ) {
        # get the class loaded
        eval { $class_name->class };
        if ($@) {
            $self->warning_message("Problem loading class $class_name: $@");
            next;
        }

        # Get this class' parents
        #push @related_class_names, $class_name->parent_classes;
        push @related_class_names, @{ $class_name->__meta__->is };
    }

    my @objs = map { $_->__meta__ } @related_class_names;

    unless ($self->include_ur_object) {
        # Prune out UR::Object and UR::Entity
        @objs = grep { $_->class_name ne 'UR::Object' and $_->class_name ne 'UR::Entity' } @objs;
    }

    # make a recursive call to get their parents
    return ( @objs,
             $self->_get_related_classes_via_inheritance( %params,
                                                          names => \@related_class_names,
                                                          depth => --$params{'depth'},
                                                        )
           );
            
}


1;

