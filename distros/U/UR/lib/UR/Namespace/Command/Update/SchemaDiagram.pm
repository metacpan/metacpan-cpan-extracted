
package UR::Namespace::Command::Update::SchemaDiagram;



use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::Base',
    has => [ 
        data_source => {type => 'String', doc => 'Which datasource to use', is_optional => 1},
        depth => { type => 'Integer', doc => 'Max distance of related tables to include.  Default is 1.  0 means show only the named tables, -1 means to include everything', is_optional => 1},
        file => { type => 'String', doc => 'Pathname of the Umlet (.uxf) file' },
        show_columns => { type => 'Boolean', is_optional => 1, default => 1, doc => 'Include column names in the diagram' },
        initial_name => {
            is_many => 1,
            is_optional => 1,
            shell_args_position => 1
        }
    ],
);

sub sub_command_sort_position { 3 };


sub help_brief {
    "Update an Umlet diagram based on the current schema"
}

sub help_detail {
    return <<EOS;
Creates a new Umlet diagram, or updates an existing diagram.  Bare arguments
are taken as table names to include in the diagram.  Other tables may be
included in the diagram based on their distance from the names tables
and the --depth parameter.

If an existing file is being updated, the position of existing elements 
will not change.

EOS
}

# The max X coord to use when placing boxes.  After this, move down a line and go back to the left
use constant MAX_X_AUTO_POSITION => 1000;

# FIXME   This execute() and the one from ur update class-diagram should be combined since they share
# most of the code
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


    # FIXME this is a workaround for a bug.  If you try to get Table objects filtered by namespace,
    # you have to have already instantiated the namespace's data source objects into the object cache 
    # first
    map { $_->_singleton_object } $namespace->get_data_sources;

    my @initial_name_list;
    if ($params->{'depth'} == -1) {
        # They wanted them all...  Ignore whatever is on the command line
        @initial_name_list = map { $_->table_name}
                                 UR::DataSource::RDBMS::Table->get(namespace => $namespace);
    } else {
        @initial_name_list = $self->initial_name;
    }

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
        $self->show_columns(1);
    }
        
    my @involved_tables = map { UR::DataSource::RDBMS::Table->get(table_name => $_, namespace => $namespace) }
                            @initial_name_list;
    #foreach my $table_name ( @initial_name_list ) {
    #    # FIXME namespace dosen't work here either
    #    push @involved_tables, UR::DataSource::RDBMS::Table->get(namespace => $namespace, table_name => $table_name);
    #}

#$DB::single = 1;
    push @involved_tables ,$self->_get_related_items( names => \@initial_name_list,
                                                      depth => $params->{'depth'},
                                                      namespace => $namespace,
                                                      item_class => 'UR::DataSource::RDBMS::Table',
                                                      item_param => 'table_name',
                                                      related_class => 'UR::DataSource::RDBMS::FkConstraint',
                                                      related_param => 'r_table_name',
                                                    );
    my %involved_table_names = map { $_->table_name => 1 } @involved_tables;

    # Figure out the initial placement
    # The initial placement, and how much to move over for the next box
    my($x_coord, $y_coord, $x_inc, $y_inc) = (20,20,40,40);
    my @objs = sort { $b->y <=> $a->y or $b->x <=> $a->x } UR::Object::Umlet::Class->get();
    if (@objs) {
        my $maxobj = $objs[0];
        $x_coord = $maxobj->x + $maxobj->width + $x_inc;
        $y_coord = $maxobj->y + $maxobj->height + $y_inc;
    }
    

    # First, place all the tables' boxes
    my @all_boxes = UR::Object::Umlet::Class->get( diagram_name => $diagram->name );
    foreach my $table ( @involved_tables ) {
        my $umlet_table = UR::Object::Umlet::Class->get(diagram_name => $diagram->name,
                                                        subject_id => $table->table_name);
        my $created = 0;
        unless ($umlet_table) {
            $created = 1;
            $umlet_table = UR::Object::Umlet::Class->create( diagram_name => $diagram->name,
                                                             subject_id => $table->table_name,
                                                             label => $table->table_name,
                                                             x => $x_coord,
                                                             y => $y_coord,
                                                           );
                                                                        
            if ($self->show_columns) {
                my $attributes = $umlet_table->attributes || [];
                my %attributes_already_in_diagram = map { $_->{'name'} => 1 } @{ $attributes };
                my %pk_properties = map { $_ => 1 } $table->primary_key_constraint_column_names;
    
                my $line_count = scalar @$attributes;
                foreach my $column_name ( $table->column_names ) {
                    next if $attributes_already_in_diagram{$column_name};
                    $line_count++;
                    my $column = UR::DataSource::RDBMS::TableColumn->get(table_name => $table->table_name,
                                                                         column_name => $column_name,
                                                                         namespace => $namespace);
                    push @$attributes, { is_id => $pk_properties{$column_name} ? '+' : ' ',
                                         name => $column_name,
                                         type => $column->data_type,
                                         line => $line_count,
                                       };
                }
                $umlet_table->attributes($attributes);
            }

            # Make sure this box dosen't overlap other boxes
            while(my $overlapped = $umlet_table->is_overlapping(@all_boxes) ) {
                    if ($umlet_table->x > MAX_X_AUTO_POSITION) {
                        $umlet_table->x(20);
                        $umlet_table->y( $umlet_table->y + $y_inc);
                    } else {
                        $umlet_table->x( $overlapped->x + $overlapped->width + $x_inc );
                    }
            }

            push @all_boxes, $umlet_table;
        }

        if ($created) {
            $x_coord = $umlet_table->x + $umlet_table->width + $x_inc;
            if ($x_coord > MAX_X_AUTO_POSITION) {
                $x_coord = 20;
                $y_coord += $y_inc;
            }
        }
    }

    # Next, connect the tables together
    foreach my $table ( @involved_tables ) {
        foreach my $fk ( UR::DataSource::RDBMS::FkConstraint->get(table_name => $table->table_name, namespace => $namespace) )  {

            next unless ($involved_table_names{$fk->r_table_name});

            my $umlet_relation = UR::Object::Umlet::Relation->get( #diagram_name => $diagram->name,
                                                                   from_entity_name => $fk->table_name,
                                                                   to_entity_name => $fk->r_table_name,
                                                                 );
            unless ($umlet_relation) {
                my @fk_column_names = $fk->column_name_map();
                my $label = join("\n", map { $_->[0] . " -> " . $_->[1] } @fk_column_names);
                $umlet_relation = UR::Object::Umlet::Relation->create( diagram_name => $diagram->name,
                                                                       relation_type => '&lt;-',
                                                                       label => $label,
                                                                       from_entity_name => $fk->table_name,
                                                                       to_entity_name => $fk->r_table_name,
                                                                     );
                 $umlet_relation->connect_entities();
            }
        }
    }

    $diagram->save_to_file($params->{'file'});

    1;
}


sub _get_related_items {
my($self, %params) = @_;

    return unless (@{$params{'names'}});
    return unless $params{'depth'};

    my $item_class = $params{'item_class'};
    my $item_param = $params{'item_param'};

    my $related_class = $params{'related_class'};
    my $related_param = $params{'related_param'};

    # Get everything linked to the named things
    my @related_names = map { $_->$related_param } $related_class->get($item_param => $params{'names'}, namespace => $params{'namespace'});
    push @related_names, map { $_->$item_param } $related_class->get($related_param => $params{'names'}, namespace => $params{'namespace'});
    return unless @related_names;

    my @objs = $item_class->get($item_param => \@related_names, namespace => $params{'namespace'});

    # make a recursive call to get the related objects by name
    return ( @objs, $self->_get_related_items( %params, names => \@related_names, depth => --$params{'depth'}) );
}
    



1;

