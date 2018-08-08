package UR::Object;

# deprecated parts of the UR::Object API

use warnings;
use strict;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

use Data::Dumper;
use Scalar::Util qw(blessed);

sub get_with_special_parameters {
    # When overridden, this allows a class to take non-properties as parameters
    # to get(), and handle loading in a special way.  Ideally this is handled by
    # a custom data source, or properties with smart definitions.
    my $class = shift;
    my $rule = shift;        
    Carp::confess(
        "Unknown parameters to $class get().  "
        . "Implement get_with_special_parameters() to handle non-standard"
        . " (non-property) query options.\n"
        . "The special params were " 
        . Dumper(\@_)
        . "Rule ID: " . $rule->id . "\n"
    );
}

sub get_or_create {
    my $self = shift;
    return $self->get( @_ ) || $self->create( @_ );
}

sub set  {
    my $self = shift;
    my @rvals;

    while (@_) {
        my $property_name = shift;
        my $value = shift;
        push(@rvals, $self->$property_name($value));
    }

    if(wantarray) {
        return @rvals;
    }
    else {
        return \@rvals;
    }
}

sub property_diff {
    # Ret hashref of the differences between the object and some other object.
    # The "other object" may be a hashref or hash, in which case it will
    # treat each key as a property.

    my ($self, $other) = @_;
    my $diff = {};

    # If we got a hash instead of a hashref...
    if (@_ > 2)
    {
        shift;
        $other = { @_ }
    }

    no warnings;
    my $self_value;
    my $other_value;
    my $class_object = $self->__meta__;
    for my $property ($class_object->all_property_names)
    {
        if (ref($other) eq 'HASH')
        {
            next unless exists $other->{$property};
            $other_value = $other->{$property};
        }
        else
        {
            $other_value = $other->$property;
        }
        $self_value = $self->$property;
        $diff->{$property} = $self_value if ($other_value ne $self_value);
    }
    return $diff;
}

# TODO: make this a context operation
sub unload {
    my $proto = shift;

    return unless ($proto->class->__meta__->is_uncachable);

    my ($self, $class);
    ref $proto ? $self = $proto : $class = $proto;
    
    my $cx = $UR::Context::current;

    if ( $self ) {
        # object method

        # The only things which can be unloaded are things committed to
        # their database in the exact same state.  Everything else must
        # be reverted or deleted.
        return unless $self->{db_committed};
        if ($self->__changes__) {
            #warn "NOT UNLOADING CHANGED OBJECT! $self $self->{id}\n";
            return;
        }

        $self->__signal_change__('unload');
        if ($ENV{'UR_DEBUG_OBJECT_RELEASE'}) {
            print STDERR "MEM UNLOAD object $self class ",$self->class," id ",$self->id,"\n";
        }
        $cx->_abandon_object($self);
        return $self;
    }
    else {
        # class method

        # unload the objects in the class
        # where there are subclasses of the class
        # delegate to them

        my @unloaded;

        # unload all objects of this class
        my @involved_classes = ( $class );
        for my $obj ($cx->all_objects_loaded_unsubclassed($class))
        {
            push @unloaded, $obj->unload;
        }

        # unload any objects that belong to any subclasses
        for my $subclass ($cx->__meta__->subclasses_loaded($class))
        {
            push @involved_classes, $subclass;
            push @unloaded, $subclass->unload;
        }

        # get rid of the loading info matching this class
        foreach my $template_id ( keys %$UR::Context::all_params_loaded ) {
            if (UR::BoolExpr::Template->get($template_id)->subject_class_name->isa($class)) {
                delete $UR::Context::all_params_loaded->{$template_id};
            }
        }

        # Turn off the all_objects_are_loaded flags
        delete @$UR::Context::all_objects_are_loaded{@involved_classes};

        return @unloaded;
    }
}

# TODO: replace internal calls to go right to the context method
sub is_loaded {
    # this is just here for backward compatability for external calls
    # get() now goes to the context for data
    
    # This shortcut handles the most common case rapidly.
    # A single ID is passed-in, and the class name used is
    # not a super class of the specified object.
    # This logic is in both get() and is_loaded().

    my $quit_early = 0;
    if ( @_ == 2 &&  !ref($_[1]) ) {
        unless (defined($_[1])) {
            Carp::confess();
        }
        my $obj = $UR::Context::all_objects_loaded->{$_[0]}->{$_[1]};
        return $obj if $obj;
        # we could safely return nothing right now, except 
        # that a subclass of this type may have the object
        return unless $_[0]->__meta__->subclasses_loaded;  # nope, there were no subclasses
    }

    my $class = shift;
    my $rule = UR::BoolExpr->resolve_normalized($class,@_);
    return $UR::Context::current->get_objects_for_class_and_rule($class,$rule,0);    
}

sub subclasses_loaded  {
    return shift->__meta__->subclasses_loaded();
}

# THESE SHOULD PROBABLY GO ON THE CLASS META

sub all_objects_are_loaded  {
    # Keep track of which classes claim that they are completely loaded, and that no more loading should be done.
    # Classes which have the above function return true should set this after actually loading everything.
    # This class will do just that if it has to load everything itself.

    my $class = shift;
    #$meta = $class->__meta__;
    if (@_) {
        # Setting the attribute
        $UR::Context::all_objects_are_loaded->{$class} = shift;
    } elsif (! exists $UR::Context::all_objects_are_loaded->{$class}) {
        # unknown... ask the parent classes and remember the answer
        foreach my $parent_class ( $class->inheritance ) {
            if (exists $UR::Context::all_objects_are_loaded->{$parent_class}) {
                $UR::Context::all_objects_are_loaded->{$class} = $UR::Context::all_objects_are_loaded->{$parent_class};
                last;
            }
        }
    }
    return $UR::Context::all_objects_are_loaded->{$class};
}


# Observer pattern (old)

sub create_subscription  {
    my $self = shift;
    my %params = @_;

    # parse parameters
    my ($class,$id,$method,$callback,$note,$priority);

    my %translate = (
        method => 'aspect',
        id => 'subject_id',
    );
    my @param_names = qw(method callback note priority id);
    my %observer_params;
    for my $name (@param_names) {
        if (exists $params{$name}) {
            my $obs_name = $translate{$name} || $name;
            $observer_params{$obs_name} = delete $params{$name};
        }
    }

    $observer_params{'subject_class_name'} = $self->class;
    if (!defined $observer_params{'subject_id'} and ref($self)) {
        $observer_params{'subject_id'} = $self->id;
    }

    if (my @unknown = keys %params) {
        Carp::croak "Unknown options @unknown passed to create_subscription!";
    }

    # validate
    if (my @bad_params = %params) {
        Carp::croak "Bad params passed to add_listener: @bad_params";
    }

    my $observer = UR::Observer->create(%observer_params);
    return unless $observer;
    return [@observer_params{'subject_class_name','subject_id','aspect','callback','note'}];
}


sub validate_subscription
{
    # Everything is invalid unless you make it valid by implementing
    # validate_subscription on your class.  (Or use the new API.)
    return;
}


sub inform_subscription_cancellation
{
    # This can be overridden in derived classes if the class wants to know
    # when subscriptions are cancelled.
    return 1;
}


sub cancel_change_subscription ($@)
{
    my ($class,$id,$property,$callback,$note);

    if (@_ >= 4)
    {
        ($class,$id,$property,$callback,$note) = @_;
        die "Bad parameters." if ref($class);
    }
    elsif ( (@_==3) or (@_==2) )
    {
        ($class, $property, $callback) = @_;
        if (ref($_[0]))
        {
            $class = ref($_[0]);
            $id = $_[0]->id;
        }
    }
    else
    {
        die "Bad parameters.";
    }

    my %params;
    if (defined $class) {
        $params{'subject_class_name'} = $class;
    }
    if (defined $id) {
        $params{'subject_id'} = $id;
    }
    if (defined $property) {
        $params{'aspect'} = $property;
    }
    if (defined $callback) {
        $params{'callback'} = $callback;
    }
    if (defined $note) {
        $params{'note'} = $note;
    }

    my @observers = UR::Observer->get(%params);
    return unless @observers;
    if (@observers > 1) {
        Carp::croak('Matched more than one observer within cancel_change_subscription().  Params were: '
                    . join(', ', map { "$_ => " . $params{$_} } keys %params));
    }
    $observers[0]->delete();
}

# This should go away when we shift to fully to a transaction log for deletions.

sub ghost_class {
    my $class = $_[0]->class;
    $class = $class . '::Ghost';
    return $class;
}


package UR::ModuleBase;
# Method for setting a callback using the old, non-command messaging API

=pod

=over 4

=item message_callback

  $sub_ref = UR::ModuleBase->message_callback($type);
  UR::ModuleBase->message_callback($type, $sub_ref);

This method returns and optionally sets the subroutine that handles
messages of a specific type.

=back

=cut

## set or return a callback that has been created for a message type
sub message_callback
{
    my $self = shift;
    my ($type, $callback) = @_;

    my $methodname = $type . '_messages_callback';

    if (!$callback) {
        # to clear the old, deprecated non-command messaging API callback
        return UR::Object->$methodname($callback);
    }

    my $wrapper_callback = sub {
        my($obj,$msg) = @_;

        my $obj_class = $obj->class;
        my $obj_id = (ref($obj) ? ($obj->can("id") ? $obj->id : $obj) : $obj);

        my $message_package = $type . '_package';
        my $message_object = UR::ModuleBase::Message->create
            (
                text         => $msg,
                level        => 1,
                package_name => $obj->$message_package(),
                call_stack   => ($type eq "error" ? _current_call_stack() : []),
                time_stamp   => time,
                type         => $type,
                owner_class  => $obj_class,
                owner_id     => $obj_id,
            );
        $callback->($message_object, $obj, $type);
        $_[1] = $message_object->text;
    };

    # To support the old, deprecated, non-command messaging API
    UR::Object->$methodname($wrapper_callback);
}

sub message_object
{
    my $self = shift;
    # see how we were called
    if (@_ < 2)
    {
        no strict 'refs';
        # return the message object
        my ($type) = @_;
        my $method = $type . '_message';
        my $msg_text = $self->method();
        my $obj_class = $self->class;
        my $obj_id = (ref($self) ? ($self->can("id") ? $self->id : $self) : $self);
        my $msgdata = $self->_get_msgdata();
        return UR::ModuleBase::Message->create
            (
                text         => $msg_text,
                level        => 1,
                package_name => $msgdata->{$type . '_package'},
                call_stack   => ($type eq "error" ? _current_call_stack() : []),
                time_stamp   => time,
                type         => $type,
                owner_class  => $obj_class,
                owner_id     => $obj_id,
            );
    }
}

foreach my $type ( UR::ModuleBase->message_types ) {
     my $retriever_name = $type . '_text';
     my $compat_name = $type . '_message';
     my $sub = sub {
         my $self = shift;
         return $self->$compat_name();
     };

     no strict 'refs';
     *$retriever_name = $sub;
}


# class that stores and manages messages for the deprecated API
package UR::ModuleBase::Message;

use Scalar::Util qw(weaken);

##- use UR::Util;
UR::Util->generate_readonly_methods
(
    text         => undef,
    level        => undef,
    package_name => undef,
    call_stack   => [],
    time_stamp   => undef,
    owner_class  => undef,
    owner_id     => undef,
    type         => undef,
);

sub create
{
    my $class = shift;
    my $obj = {@_};
    bless ($obj,$class);
   weaken $obj->{'owner_id'} if (ref($obj->{'owner_id'}));

    return $obj;
}

sub owner
{
    my $self = shift;
    my ($owner_class,$owner_id) = ($self->owner_class, $self->owner_id);
    if (not defined($owner_id))
    {
        return $owner_class;
    }
    elsif (ref($owner_id))
    {
        return $owner_id;
    }
    else
    {
        return $owner_class->get($owner_id);
    }
}

sub string
{
    my $self = shift;
    "$self->{time_stamp} $self->{type}: $self->{text}\n";
}

sub _stack_item_params
{
    my ($self, $stack_item) = @_;
    my ($function, $parameters, @parameters);

    return unless ($stack_item =~ s/\) called at [^\)]+ line [^\)]+\s*$/\)/);

    if ($stack_item =~ /^\s*([^\(]*)(.*)$/)
    {
        $function = $1;
        $parameters = $2;
        @parameters = eval $parameters;
        return ($function, @parameters);
    }
    else
    {
        return;
    }
}

package UR::Object;


1;


