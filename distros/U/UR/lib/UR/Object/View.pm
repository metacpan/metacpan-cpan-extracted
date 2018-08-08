package UR::Object::View;
use warnings;
use strict;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

class UR::Object::View {
    has_abstract_constant => [
        subject_class_name      => { is_abstract => 1, is_constant => 1 },#is_classwide => 1, is_constant => 1, is_optional => 0 },
        perspective             => { is_abstract => 1, is_constant => 1 },#is_classwide => 1, is_constant => 1, is_optional => 0 },
        toolkit                 => { is_abstract => 1, is_constant => 1 },#is_classwide => 1, is_constant => 1, is_optional => 0 },
    ],
    has_optional => [
        parent_view => {
            is => 'UR::Object::View',
            id_by => 'parent_view_id',
            doc => 'when nested inside another view, this references that view',
        },
        subject => { 
            is => 'UR::Object',  
            id_class_by => 'subject_class_name', id_by => 'subject_id', 
            doc => 'the object being observed' 
        },
        aspects => { 
            is => 'UR::Object::View::Aspect', 
            reverse_as => 'parent_view',
            is_many => 1, 
            specify_by => 'name',
            order_by => 'number',
            doc => 'the aspects of the subject this view renders' 
        },
        default_aspects => {
            is => 'ARRAY',
            is_abstract => 1,
            is_constant => 1,
            is_many => 1, # technically this is one "ARRAY"
            default_value => undef,
            doc => 'a tree of default aspect descriptions' },
    ],
    has_optional_transient => [
        _widget  => { 
            doc => 'the object native to the specified toolkit which does the actual visualization' 
        },
        _observer_data => {
            is => 'HASH',
            is_transient => 1,
            value => undef, # hashref set at construction time
            doc => '  hooks around the subject which monitor it for changes'
        },
    ],
    has_many_optional => [
        aspect_names    => { via => 'aspects', to => 'name' },
    ]
};


sub create {
    my $class = shift;

    my ($params,@extra) = $class->define_boolexpr(@_);

    # set values not specified in the params which can be inferred from the class name
    my ($expected_class,$expected_perspective,$expected_toolkit) = ($class =~ /^(.*)::View::(.*?)::([^\:]+)$/);
    unless ($params->specifies_value_for('subject_class_name')) {
        $params = $params->add_filter(subject_class_name => $expected_class);
    }
    unless ($params->specifies_value_for('perspective')) {
        $expected_perspective = join('-', split( /(?=[A-Z])/, $expected_perspective) ); #convert CamelCase to hyphenated-words
        $params = $params->add_filter(perspective => $expected_perspective);
    }
    unless ($params->specifies_value_for('toolkit')) {
        $params = $params->add_filter(toolkit => $expected_toolkit);
    }

    # now go the other way, and use both to infer a final class name
    $expected_class = $class->_resolve_view_class_for_params($params);
    unless ($expected_class) {
        my $subject_class_name = $params->value_for('subject_class_name');
        Carp::croak("Failed to resolve a subclass of " . __PACKAGE__ 
                . " for $subject_class_name from parameters.  "
                . "Received $params.");
    }

    unless ($class->isa($expected_class)) {
        return $expected_class->create(@_);
    }

    $params->add_filter(_observer_data => {});
    my $self = $expected_class->SUPER::create($params);
    return unless $self;

    $class = ref($self);
    $expected_class = $class->_resolve_view_class_for_params(
        subject_class_name  => $self->subject_class_name,
        perspective         => $self->perspective,
        toolkit             => $self->toolkit
    );
    unless ($expected_class and $expected_class eq $class) {
        $expected_class ||= '<uncertain>';
        Carp::croak("constructed a $class object but properties indicate $expected_class should have been created.");
    }

    unless ($params->specifies_value_for('aspects')) {
        my @aspect_specs = $self->default_aspects();
        if (! @aspect_specs) {
            @aspect_specs = $self->_resolve_default_aspects();
        }
        if (@aspect_specs == 1 and ref($aspect_specs[0]) eq 'ARRAY') {
            # Got an arrayref, expand back into an array
            @aspect_specs = @{$aspect_specs[0]};
        }

        for my $aspect_spec (@aspect_specs) {
            my $aspect = $self->add_aspect(ref($aspect_spec) ? %$aspect_spec : $aspect_spec);
            unless ($aspect) {
                $self->error_message("Failed to add aspect @$aspect_spec to new view " . $self->id);
                $self->delete;
                return;
            }
        }
    }

    return $self;
}

our %view_class_cache = ();
sub _resolve_view_class_for_params {
    # View modules use standardized naming:  SubjectClassName::View::Perspective::Toolkit.
    # The subject must be explicitly of class "SubjectClassName" or some subclass of it.
    my $class = shift;
    my $bx = $class->define_boolexpr(@_);

    if (exists $view_class_cache{$bx->id}) {
        if (!defined $view_class_cache{$bx->id}) {
            return;
        }
        return $view_class_cache{$bx->id};
    }

    my %params = $bx->params_list;

    my $subject_class_name = delete $params{subject_class_name};
    my $perspective = delete $params{perspective};
    my $toolkit = delete $params{toolkit};
    my $aspects = delete $params{aspects};

    unless($subject_class_name and $perspective and $toolkit) {
        Carp::confess("Bad params @_.  Expected subject_class_name, perspective, toolkit.");
    }

    $perspective = lc($perspective);
    $toolkit = lc($toolkit);

    my $namespace = $subject_class_name->__meta__->namespace;
    my $vocabulary = ($namespace and $namespace->can("get_vocabulary") ? $namespace->get_vocabulary() : undef);
    $vocabulary = UR->get_vocabulary;

    my $subject_class_object = $subject_class_name->__meta__;
    my @possible_subject_class_names = ($subject_class_name,$subject_class_name->inheritance);

    my $subclass_name;
    for my $possible_subject_class_name (@possible_subject_class_names) {

        $subclass_name = join("::",
            $possible_subject_class_name,
            "View",
            join ("",
                $vocabulary->convert_to_title_case (
                    map { ucfirst(lc($_)) }
                    split(/-+|\s+/,$perspective)
                )
            ),
            join ("",
                $vocabulary->convert_to_title_case (
                    map { ucfirst(lc($_)) }
                    split(/-+|\s+/,$toolkit)
                )
            )
        );

        my $subclass_meta;
        eval {
            $subclass_meta = $subclass_name->__meta__;
        };
        if ($@ or not $subclass_meta) {
            #not a class... keep looking
            next;
        }

        unless($subclass_name->isa(__PACKAGE__)) {
            Carp::carp("Subclass $subclass_name exists but is not a view?!");
            next;
        }

        $view_class_cache{$bx->id} = $subclass_name;
        return $subclass_name;
    }

    $view_class_cache{$bx->id} = undef;
    return;
}

sub _resolve_default_aspects {
    my $self = shift;
    my $parent_view = $self->parent_view;
    my $subject_class_name = $self->subject_class_name;
    my $meta = $subject_class_name->__meta__;
    my @c = ($meta->class_name, $meta->ancestry_class_names);
    my %aspects =  
        map { $_->property_name => 1 }
        grep { not $_->implied_by }
        UR::Object::Property->get(class_name => \@c);
    my @aspects = sort keys %aspects;
    return @aspects;
}

sub __signal_change__ {
    # ensure that changes to the view which occur 
    # after the widget is produced
    # are reflected in the widget
    my ($self,$method,@details) = @_;

    if ($self->_widget) {
        if ($method eq 'subject' or $method =~ 'aspects') {
            $self->_bind_subject();
        }
        elsif ($method eq 'delete' or $method eq 'unload') {
            my $observer_data = $self->_observer_data;
            for my $subscription (values %$observer_data) {
                my ($class, $id, $method, $callback) = @$subscription;
                $class->cancel_change_subscription($id, $method, $callback);
            }
            $self->_widget(undef);
        }
    }
    return 1;
}

# _encompassing_view() and _subject_is_used_in_an_encompassing_view() are used by the
# default views (UR::Object::View::Default::*) to detect an infinite recursion situation
# where it's asked to render an object A that references a B which refers back to A

# If this view is embedded in another view, return the encompassing view
sub _encompassing_view {
    my $self = shift;

    my @aspects = UR::Object::View::Aspect->get(delegate_view_id => $self->id);
    if (@aspects) {
        # FIXME - is it possible for there to be more than one thing in @aspects here?
        # And if so, how do we differentiate them
        return $aspects[0]->parent_view;
    }

    # $self must be the top-level view
    return;
}

# If the subject of the view is also the subject of an encompassing view, return true
sub _subject_is_used_in_an_encompassing_view {
    my($self,$subject) = @_;

    $subject = $self->subject unless (@_ == 2);

    my $encompassing = $self->_encompassing_view;
    while($encompassing) {
        if ($encompassing->subject eq $subject) {
            return 1;
        } else {
            $encompassing = $encompassing->_encompassing_view();
        }
    }
    return;
}

sub all_subject_classes {
    my $self = shift;
    my @classes = ();

    # suppress error callbacks inside this method
    my $old_cb = UR::ModuleBase->message_callback('error');
    UR::ModuleBase->message_callback('error', sub {}) if ($old_cb);

    for my $aspect ($self->aspects) {
        unless ($aspect->delegate_view) {
            eval {
                $aspect->generate_delegate_view;
            };
        }
        if ($aspect->delegate_view) {
            push @classes, $aspect->delegate_view->all_subject_classes
        }
    }
    UR::ModuleBase->message_callback('error', $old_cb) if ($old_cb);

    push @classes, $self->subject_class_name;

    my %saw;
    my @uclasses = grep(!$saw{$_}++,@classes);

    return @uclasses;
}

sub all_subject_classes_ancestry {
    my $self = shift;

    my @classes = $self->all_subject_classes;

    my @aclasses;
    for my $class (@classes) {
        my $m;
        eval { $m = $class->__meta__ };
        next if $@ or not $m;

        push @aclasses, reverse($class, $m->ancestry_class_names);
    }

    my %saw;
    my @uaclasses = grep(!$saw{$_}++,@aclasses);

    return @uaclasses;
}

# rendering implementation

sub widget {
    my $self = shift;
    if (@_) {
        Carp::confess("Widget() is not settable!  Its value is set from _create_widget() upon first use.");
    }
    my $widget = $self->_widget();
    unless ($widget) {
        $widget = $self->_create_widget();
        return unless $widget;
        $self->_widget($widget);
        $self->_bind_subject(); # works even if subject is undef
    }
    return $widget;
}

sub _create_widget {
    Carp::confess("The _create_widget method must be implemented for all concrete "
        . " view subclasses.  No _create_widget for " 
        . (ref($_[0]) ? ref($_[0]) : $_[0]) . "!");
}

sub _bind_subject {
    # This is called whenever the subject changes, or when the widget is first created.
    # It handles the case in which the subject is undef.
    my $self = shift;
    my $subject = $self->subject();
    return unless defined $subject;

    my $observer_data = $self->_observer_data;
    unless ($observer_data) {
        $self->_observer_data({});
        $observer_data = $self->_observer_data;
    }
    Carp::confess unless $self->_observer_data == $observer_data;

    # See if we've already done this.    
    return 1 if $observer_data->{$subject};

    # Wipe subscriptions from the last bound subscription(s).
    for (keys %$observer_data) {
        my $s = delete $observer_data->{$_};
        my ($class, $id, $method,$callback) = @$s;
        $class->cancel_change_subscription($id, $method,$callback);
    }

    return unless $subject;

    # Make a new subscription for this subject
    my $subscription = $subject->create_subscription(
        callback => sub {
            $self->_update_view_from_subject(@_);
        }
    );
    $observer_data->{$subject} = $subscription;
    
    # Set the view to show initial data.
    $self->_update_view_from_subject;
   
    return 1;
}

sub _update_view_from_subject {
    # This is called whenever the view changes, or the subject changes.
    # It passes the change(s) along, so that the update can be targeted, if the developer chooses.
    Carp::croak("The _update_view_from_subject method must be implemented for all concreate "
        . " view subclasses.  No _update_subject_from_view for " 
        . (ref($_[0]) ? ref($_[0]) : $_[0]) . "!");
}

sub _update_subject_from_view {
    Carp::croak("The _update_subject_from_view method must be implemented for all concreate "
        . " view subclasses.  No _update_subject_from_view for " 
        . (ref($_[0]) ? ref($_[0]) : $_[0]) . "!");
}

# external controls

sub show {
    my $self = shift;
    $self->_toolkit_package->show_view($self);
}

sub show_modal {
    my $self = shift;
    $self->_toolkit_package->show_view_modally($self);
}

sub hide {
    my $self = shift;
    $self->_toolkit_package->hide_view($self);
}

sub _toolkit_package {
    my $self = shift;
    my $toolkit = $self->toolkit;
    return "UR::Object::View::Toolkit::" . ucfirst(lc($toolkit));
}

1;

=pod

=head1 NAME

UR::Object::View - a base class for "views" of UR::Objects

=head1 SYNOPSIS

  $object = Acme::Product->get(1234);

  ## Acme::Product::View::InventoryHistory::Gtk2

  $view = $object->create_view(
    perspective         => 'inventory history',
    toolkit             => 'gtk2',              
  );
  $widget = $view->widget();    # returns the Gtk2::Widget itself directly
  $view->show();                # puts the widget in a Gtk2::Window and shows everything
  
  ##

  $view = $object->create_view(
    perspective         => 'inventory history',
    toolkit             => 'xml',              
  );
  $widget = $view->widget();    # returns an arrayref with the xml string reference, and the output filehandle (stdout) 
  $view->show();                # prints the current xml content to the handle
  
  $xml = $view->content();     # returns the XML directly
  
  ##
  
  $view = $object->create_view(
    perspective         => 'inventory history',
    toolkit             => 'html',              
  );
  $widget = $view->widget();    # returns an arrayref with the html string reference, and the output filehandle (stdout) 
  $view->show();                # prints the html content to the handle
  
  $html = $view->content();     # returns the HTML text directly


=head1 USAGE API 

=over 4

=item create

The constructor requires that the subject_class_name, perspective,
and toolkit be set.  Most concrete subclasses have perspective and toolkit 
set as constant.

Producing a view object does not "render" the view, just creates an 
interface for controlling the view, including encapsualting its creation.  

The subject can be set later and changed.  The aspects viewed may 
be constant for a given perspective, or mutable, depending on how
flexible the of the perspective logic is.

=item show

For stand-alone views, this puts the view widget in its a window.  For 
views which are part of a larger view, this makes the view widget
visible in the parent.

=item hide

Makes the view invisible.  This means hiding the window, or hiding the view
widget in the parent widget for subordinate views.

=item show_modal 

This method shows the view in a window, and only returns after the window is closed.
It should only be used for views which are a full interface capable of closing itself 
when done.

=item widget

Returns the "widget" which renders the view.  This is built lazily
on demand.  The actual object type depends on the toolkit named above.  
This method might return HTML text, or a Gtk object.  This can be used
directly, and is used internally by show/show_modal.

(Note: see UR::Object::View::Toolkit::Text for details on the "text" widget,
used by HTML/XML views, etc.  This is just the content and an I/O handle to 
which it should stream.)

=item delete

Delete the view (along with the widget(s) and infrastructure underlying it).

=back

=head1 CONSTRUCTION PROPERTIES (CONSTANT)

The following three properties are constant for a given view class.  They
determine which class of view to construct, and must be provided to create().

=over 4

=item subject_class_name
    
The class of subject this view will view.  Constant for any given view,
but this may be any abstract class up-to UR::Object itself.
    
=item perspective

Used to describe the layout logic which gives logical content
to the view.

=item toolkit

The specific (typically graphical) toolkit used to construct the UI.
Examples are Gtk, Gkt2, Tk, HTML, XML.

=back

=head1 CONFIGURABLE PROPERTIES

These methods control which object is being viewed, and what properties 
of the object are viewed.  They can be provided at construction time,
or afterward.

=over 4

=item subject

The particular "model" object, in MVC parlance, which is viewed by this view.
This value may change

=item aspects / add_aspect / remove_aspect

Specifications for properties/methods of the subject which are rendered in
the view.  Some views have mutable aspects, while others merely report
which aspects are revealed by the perspective in question.

An "aspect" is some characteristic of the "subject" which is rendered in the 
view.  Any property of the subject is usable, as is any method.

=back

=head1 IMPLEMENTATION INTERFACE 

When writing new view logic, the class name is expected to 
follow a formula:

     Acme::Rocket::View::FlightPath::Gtk2
     \          /           \    /      \
     subject class name    perspective  toolkit

The toolkit is expected to be a single word.   The perspective
is everything before the toolkit, and after the last 'View' word.
The subject_class_name is everything to the left of the final
'::View::'.

There are three methods which require an implementation, unless
the developer inherits from a subclass of UR::Object::View which
provides these methods:

=over 4

=item _create_widget

This creates the widget the first time ->widget() is called on a view.

This should be implemented in a given perspective/toolkit module to actually
create the GUI using the appropriate toolkit.  

It will be called before the specific subject is known, so all widget creation 
which is subject-specific should be done in _bind_subject().  As such it typically
only configures skeletal aspects of the view.

=item _bind_subject

This method is called when the subject is set, or when it is changed, or unset.
It updates the widget to reflect changes to the widget due to a change in subject. 

This method has a default implementation which does a general subscription
to changes on the subject.  It probably does not need to be overridden
in custom views.  Implementations which _do_ override this should take 
an undef subject, and be sure to un-bind a previously existing subject if 
there is one set. 

=item _update_view_from_subject

If and when the property values of the subject change, this method will be called on 
all views which render the changed aspect of the subject.

=item _update_subject_from_view

When the widget changes, it should call this method to save the UI changes
to the subject.  This is not applicable to read-only views.

=back

=head1 OTHER METHODS 

=over 4

=item _toolkit_package

This method is useful to provide generic toolkit-based services to a view,
using a toolkit agnostic API.  It can be used in abstract classes which,
for instance, want to share logic for a given perspective across toolkits.

The toolkit class related to a view is responsible for handling show/hide logic,
etc. in the base UR::Object::View class.

Returns the name of a class which is derived from UR::Object::View::Toolkit
which implements certain utility methods for views of a given toolkit.

=back

=head1 EXAMPLES

$o = Acme::Product->get(1234);

$v = Acme::Product::View::InventoryHistory::HTML->create();
$v->add_aspect('outstanding_orders');
$v->show;

=cut

