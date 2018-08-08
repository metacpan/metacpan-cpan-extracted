package UR::Object::View::Aspect;

use warnings;
use strict;
require UR;

our $VERSION = "0.47"; # UR $VERSION;

class UR::Object::View::Aspect {
    id_by => [
        parent_view     => { is => 'UR::Object::View', id_by => 'parent_view_id', 
                            doc => "the id of the view object this is an aspect-of" },
        
        number          => { is => 'Integer', 
                            doc => "aspects of a view are numbered" },
    ],
    has => [
        name            => { is => 'Text', 
                            is_mutable => 0, 
                            doc => 'the name of the property/method on the subject which returns the value to be viewed' },
    ],
    has_optional => [
        label           => { is => 'Text', 
                            doc => 'display name for this aspect' },
        
        position        => { is => 'Scalar', 
                            doc => 'position of this aspect within the parent view (meaning is view and toolkit dependent)' },

        delegate_view      => { is => 'UR::Object::View', id_by => 'delegate_view_id', 
                            doc => "This aspect gets rendered via another view" },
    ],
};

sub create {
    my $class = shift;
    my($bx,%extra) = $class->define_boolexpr(@_);

    # TODO: it would be nice to have this in the class definition:
    #  increment_for => 'parent_view'
    unless ($bx->value_for('number')) {
        if (my $parent_view_id = $bx->value_for('parent_view_id')) {
            my $parent_view = UR::Object::View->get($parent_view_id);
            my @previous_aspects = $parent_view->aspects;
            $bx = $bx->add_filter(number => scalar(@previous_aspects)+1);
        }
    }
    unless ($bx->value_for('label')) {
        if (my $label = $bx->value_for('name')) {
            $label =~ s/_/ /g;
            $bx = $bx->add_filter(label => $label);
        }
    }

    if (keys %extra) {
        # This is a sub-view
        my $delegate_subject_class_name;
        if (exists $extra{'subject_class_name'}) {
            $delegate_subject_class_name = $extra{'subject_class_name'};
        } else {
            # FIXME This duplicates functionality below in generate_delegate_view, but generate_delegate_view()
            # doesn't take any args to tweak the properties of that delegated view :(
            # Try to figure it out based on the name of the aspect...
            my $parent_view;
            if (my $view_id = $bx->value_for('parent_view_id')) {
                $parent_view = UR::Object::View->get($view_id);
            } elsif ($bx->specifies_value_for('parent_view')) {
                $parent_view = $bx->value_for('parent_view');
            } 
            unless ($parent_view) {
                Carp::croak("Can't determine parent view from keys/values: ",join(', ', map { sprintf("%s => '%s'", $_, $extra{$_}) } keys %extra));
            }

            my $class_meta = $parent_view->subject_class_name->__meta__;
            unless ($class_meta) {
                Carp::croak("No class metadata for class "
                            . $parent_view->subject_class_meta
                            . ".  Can't create delegate view on aspect named "
                            . $bx->value_for('name') );
            }

            my $property_meta = $class_meta->property_meta_for_name($bx->value_for('name'));
            unless ($property_meta) {
                Carp::croak("No property metadata for class " . $class_meta->class_name
                            . " property " . $bx->value_for('name')
                            . ".  Can't create delegate view on aspect named " . $bx->value_for('name'));
            }

            unless ($property_meta->data_type) {
                Carp::croak("Property metadata for class " . $class_meta->class_name
                            . " property " . $property_meta->property_name
                            . " has no data_type.  Can't create delegate view on aspect named " . $bx->value_for('name'));
            }

            $delegate_subject_class_name = $property_meta->data_type;
        }
        unless ($delegate_subject_class_name) {
            Carp::croak("Can't determine subject_class_name for delegate view on aspect named " . $bx->value_for('name'));
        }
                 
        my $delegate_view = $delegate_subject_class_name->create_view(
                                perspective => $bx->value_for('perspective'),
                                toolkit     => $bx->value_for('toolkit'),
                                %extra
                             );
        unless ($delegate_view) {
            Carp::croak("Can't create delegate view for aspect named " . $bx->value_for('name') . ": ".$delegate_subject_class_name->error_message);
        }
        #$bx->add_filter(delegate_view_id => $delegate_view->id);
        $bx = $bx->add_filter(delegate_view => $delegate_view);
    }
                                

    my $self = $class->SUPER::create($bx);
    return unless $self;

    my $name = $self->name;
    unless ($name) {
        $self->error_message("No name specified for aspect!");
        $self->delete;
        return;
    }

    return $self; 
}

sub _look_for_recursion {
    my $self = shift;

    my $parent_view = $self->parent_view;
    my $subject = $parent_view->subject;

    $parent_view = $parent_view->parent_view;
    while($parent_view) {
        return 1 if ($parent_view->subject eq $subject);
        $parent_view = $parent_view->parent_view;
    }
    return 0;
}

sub generate_delegate_view {
no warnings;
    my $self = shift;

    my $parent_view = $self->parent_view;

    my $name = $self->name;
    my $subject_class_name = $parent_view->subject_class_name;

    my $retval;
    
    my $property_meta = $subject_class_name->__meta__->property($name);
    my $aspect_type;
    if ($property_meta) {
        $aspect_type = $property_meta->_data_type_as_class_name;
        unless ($aspect_type) {
            Carp::confess("Undefined aspect type. Set 'is' for $name in class " . $property_meta->class_name);
        }

        unless ($aspect_type->can("__meta__")) {
            Carp::croak("$aspect_type has no meta data?  cannot generate a view for $subject_class_name $name!"); 
        }
    }
    else {
        unless ($subject_class_name->can($name)) {
            $self->error_message("No property/method $name found on $subject_class_name!  Invalid aspect!");
            $self->delete;
            Carp::croak($self->error_message);
        }
        $aspect_type = 'UR::Value::Text'
    }

    my $aspect_meta = $aspect_type->__meta__;

    my $delegate_view;
    local $@;
    eval {
        $delegate_view = $aspect_type->create_view(
            subject_class_name => $aspect_type,
            perspective => $parent_view->perspective,
            toolkit => $parent_view->toolkit,
            parent_view => $parent_view,
            aspects => [],
        );
    };

    unless ($delegate_view) {
        # try again using the "default" perspective
        my $err1 = $@; 
        eval {
            $delegate_view = $aspect_type->create_view(
                subject_class_name => $aspect_type,
                perspective => 'default', 
                toolkit => $parent_view->toolkit,
                parent_view => $parent_view,
                aspects => [],
            );
        };
        my $err2 = $@; 

        unless ($delegate_view) {
            $self->error_message(
                "Error creating delegate view for $name ($aspect_type)! $err1\n"
                . "Also failed to fall back to the default perspective for $name ($aspect_type)! $err2"
            );
            return;
        }
    }

    my @default_aspects_params = $delegate_view->_resolve_default_aspects();
        
    # add aspects which do not "go backward"
    # no one wants to see an order, with a list of line items, which re-reprsent thier order on each
    for my $aspect_params (@default_aspects_params) {
        my $aspect_param_name = (ref($aspect_params) ?  $aspect_params->{name} : $aspect_params);
        my $aspect_property_meta = $aspect_meta->property($aspect_param_name);
        no strict; no warnings;
        next if (!$aspect_property_meta or !$property_meta);

        if ($aspect_property_meta->reverse_as ne $name
            and
            $property_meta->reverse_as ne $aspect_param_name
        ) {
            $delegate_view->add_aspect(ref($aspect_params) ? %$aspect_params : $aspect_params);
        }
    }
    $self->delegate_view($delegate_view);
    $retval = $delegate_view;

    return $retval;
}

1;

=pod

=head1 NAME

UR::Object::View::Aspect - a specification for one aspect of a view 

=head1 SYNOPSIS

 my $v = $o->create_view(
   perspective => 'default',
   toolkit => 'xml',
   aspects => [
     'id',
     'name',
     'title',
     { 
        name => 'department', 
        perspective => 'logo'
     },
     { 
        name => 'boss',
        label => 'Supervisor',
        aspects => [
            'name',
            'title',
            { 
              name => 'subordinates',
              perspective => 'graph by title'
            }
        ]
     }
   ]
 );

=cut


