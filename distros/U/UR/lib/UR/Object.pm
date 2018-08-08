package UR::Object;

use warnings;
use strict;

require UR;

use Scalar::Util qw(looks_like_number refaddr isweak);
use List::MoreUtils qw(any);

our @ISA = ('UR::ModuleBase');
our $VERSION = "0.47"; # UR $VERSION;

# Base object API

sub class { ref($_[0]) || $_[0] }

sub id { $_[0]->{id} }

sub create {
    $UR::Context::current->create_entity(@_);
}

sub get {
    $UR::Context::current->query(@_);
}

sub delete {
    $UR::Context::current->delete_entity(@_);
}

sub copy {
    my $self = shift;
    my %override = @_;

    my $meta = $self->__meta__;
    my @copyable_properties =
        grep { !$_->is_delegated && !$_->is_id }
        $meta->properties;

    my %params;
    for my $p (@copyable_properties) {
        my $name = $p->property_name;
        if ($p->is_many) {
            if (my @value = $self->$name) {
                $params{$name} = \@value;
            }
        }
        else {
            if (defined(my $value = $self->$name)) {
                $params{$name} = $value;
            }
        }
    }

    return $self->class->create(%params, %override);
}


# Meta API

sub __context__ {
    # In UR, a "context" handles inter-object references so they can cross
    # process boundaries, and interact with persistence systems automatically.

    # For efficiency, all context switches update a package-level value.

    # We will ultimately need to support objects recording their context explicitly
    # for things such as data maintenance operations.  This shouldn't happen
    # during "business logic".

    return $UR::Context::current;
}

sub __meta__  {
    # the class meta object
    # subclasses set this specifically for efficiency upon construction
    # the base class has a generic implementation for boostrapping
    Carp::cluck("using the default __meta__!");
    my $class_name = shift;
    return $UR::Context::all_objects_loaded->{"UR::Object::Type"}{$class_name};
}

# The identity operation.  Not particularly useful by itself, but makes
# things like mapping operations easier and calculate_from metadata able
# to include the object as function args to calculated properties
sub __self__ {
    return $_[0] if @_ == 1;
    my $self = shift;
    my $bx = $self->class->define_boolexpr(@_);
    if ($bx->evaluate($self)) {
        return $self;
    }
    else {
        return;
    }
}

sub does {
    my($self, $role_name) = @_;

    my @roles = map { @{ $_->roles } }
                $self->__meta__->all_class_metas();

    any { $role_name eq $_->role_name } @roles;
}


# Used to traverse n levels of indirect properties, even if the total
# indirection is not defined on the primary ofhect this is called on.
# For example: $obj->__get_attr__('a.b.c');
# gets $obj's 'a' value, calls 'b' on that, and calls 'c' on the last thing
sub __get_attr__ {
    my ($self, $property_name) = @_;
    my @property_values;
    if (index($property_name,'.') == -1) {
        @property_values = $self->$property_name;
    }
    else {
        my @links = split(/\./,$property_name);
        @property_values = ($self);
        for my $full_link (@links) {
            my $pos = index($full_link,'-');
            my $link = ($pos == -1 ? $full_link : substr($full_link,0,$pos) );
            @property_values = map { defined($_) ? $_->$link : undef } @property_values;
        }
    }
    return if not defined wantarray;
    return @property_values if wantarray;
    if (@property_values > 1) {
        my $class_name = $self->__meta__->class_name;
        Carp::confess("Multiple values returned for $class_name $property_name in scalar context!");
    }
    return $property_values[0];
}

sub __label_name__ {
    # override to provide default labeling of the object
    my $self = $_[0];
    my $class = ref($self) || $self;
    my ($label) = ($class =~ /([^:]+)$/);
    $label =~ s/([a-z])([A-Z])/$1 $2/g;
    $label =~ s/([A-Z])([A-Z]([a-z]|\s|$))/$1 $2/g;
    $label = uc($label) if $label =~ /_id$/i;
    return $label;
}

sub __display_name__ {
    # default stringification (does override "" unless you specifically choose to)
    my $self = shift;
    my $in_context_of_related_object = shift;

    my $name = $self->id;
    $name =~ s/\t/ /g;
    return $name;

    if (not $in_context_of_related_object) {
        # no in_context_of_related_object.
        # the object is identified globally
        return $self->label_name . ' ' . $name;
    }
    elsif ($in_context_of_related_object eq ref($self)) {
        # the class is completely known
        # show only the core display name
        # -> less text, more in_context_of_related_object
        return $name
    }
    else {
        # some intermediate base class is known,
        # TODO: make this smarter
        # For now, just show the whole class name with the ID
        return $self->label_name . ' ' . $name;
    }
}

sub __errors__ {
    # This is the basis for software constraint checking.
    # Return a list of values describing the problems on the object.

    my ($self,@property_names) = @_;

    my $class_object = $self->__meta__;

    unless (scalar @property_names) {
        @property_names = $class_object->all_property_names;
    }

    my @properties = map {
        $class_object->property_meta_for_name($_);
    } @property_names;

    my @tags;
    for my $property_metadata (@properties) {
        # For now we don't validate these.
        # Ultimately, we should delegate to the property metadata object for value validation.
        my($is_delegated, $is_calculated, $property_name, $is_optional, $generic_data_type, $data_length)
            = @$property_metadata{'is_delegated','is_calculated','property_name','is_optional', 'data_type','data_length'};

        next if $is_delegated || $is_calculated;

        # TODO: is this making commits slow by calling lots of indirect accessors?
        my @values = $self->$property_name;
        next if @values > 1;

        my $value = $values[0];

        # account for minus sign in dummy ID
        if ($ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} and $property_metadata->is_id and defined($value) and index($value, '-') == 0 and defined $data_length) {
            $data_length++;
        }

        if (! ($is_optional or defined($value))) {
            push @tags, UR::Object::Tag->create(
                            type => 'invalid',
                            properties => [$property_name],
                            desc => "No value specified for required property",
                         );
        }

        # The tests below don't apply do undefined values.
        # Save the trouble and move on.
        next unless defined $value;

        # Check data type
        # TODO: delegate to the data type module for this
        $generic_data_type = '' unless (defined $generic_data_type);

        if ($generic_data_type eq 'Float' || $generic_data_type eq 'Integer') {
            if (looks_like_number($value)) {
                $value = $value + 0;
            }
            else{
                push @tags, UR::Object::Tag->create (
                    type => 'invalid',
                    properties => [$property_name],
                    desc => "Invalid $generic_data_type value."
                );
            }
        }
        elsif ($generic_data_type eq 'DateTime') {
            # This check is currently disabled b/c of time format irrecularities
            # We rely on underlying database constraints for real invalidity checking.
            # TODO: fix me
            if (1) {

            }
            elsif ($value =~ /^\s*\d\d\d\d\-\d\d-\d\d\s*(\d\d:\d\d:\d\d|)\s*$/) {
                # TODO more validation here for a real date.
            }
            else {
                push @tags, UR::Object::Tag->create (
                    type => 'invalid',
                    properties => [$property_name],
                    desc => 'Invalid date string.'
                );
            }
        }

        # Check size
        if ($generic_data_type ne 'DateTime') {
            if ( defined($data_length) and ($data_length < length($value)) ) {
                push @tags,
                    UR::Object::Tag->create(
                        type => 'invalid',
                        properties => [$property_name],
                        desc => sprintf('Value too long (%s of %s has length of %d and should be <= %d).',
                                        $property_name,
                                        $self->$property_name,
                                        length($value),
                                        $data_length)
                    );
            }
        }

        # Check valid values if there is an explicit list
        if (my $constraints = $property_metadata->valid_values) {
            my $valid = 0;
            for my $valid_value (@$constraints) {
                no warnings; # undef == ''
                if ($value eq $valid_value) {
                    $valid = 1;
                    last;
                }
            }
            unless ($valid) {
                # undef is a valid value in the constraints list
                my $value_list = join(', ',map { defined($_) ? $_ : '' } @$constraints);
                push @tags,
                    UR::Object::Tag->create(
                        type => 'invalid',
                        properties => [$property_name],
                        desc => sprintf(
                                'The value %s is not in the list of valid values for %s.  Valid values are: %s',
                                $value,
                                $property_name,
                                $value_list
                            )
                    );
            }
        }

        # Check FK if it is easy to do.
        # TODO: This is a heavy weight check, and is disabled for performance reasons.
        # Ideally we'd check a foreign key value _if_ it was changed only, since
        # saved foreign keys presumably could not have been save if they were invalid.
        if (0) {
            my $r_class;
            unless ($r_class->get(id => $value)) {
                push @tags, UR::Object::Tag->create (
                    type => 'invalid',
                    properties => [$property_name],
                    desc => "$value does not reference a valid " . $r_class . '.'
                );
            }
        }
    }

    return @tags;
}

# Standard API for working with UR fixtures
#  boolean expressions
#  sets
#  iterators
#  views
#  mock objects

sub define_boolexpr {
    if (ref($_[0])) {
        my $class = ref(shift);
        return UR::BoolExpr->resolve($class,@_);
    }
    else {
        return UR::BoolExpr->resolve(@_);
    }
}

sub define_set {
    my $class = shift;
    $class = ref($class) || $class;
    my $rule = UR::BoolExpr->resolve_normalized($class,@_);
    my $flattened_rule = $rule->flatten_hard_refs();
    my $set_class = $class . "::Set";
    return $set_class->get($flattened_rule->id);
}

sub add_observer {
    my $self = shift;
    my %params = @_;

    if (ref($self)) {
        $params{subject_id} = $self->id;
    }
    my $observer = UR::Observer->create(
        subject_class_name => $self->class,
        %params,
    );
    unless ($observer) {
        $self->error_message(
            "Failed to create observer: "
            . UR::Observer->error_message
        );
        return;
    }
    return $observer;
}

sub remove_observers {
    my $self = shift;
    my %params = @_;

    my $aspect = delete $params{'aspect'};
    my $callback = delete $params{'callback'};
    if (%params) {
        Carp::croak('Unrecognized parameters for observer removal: '
                    . Data::Dumper::Dumper(\%params)
                     . "Expected 'aspect' and 'callback'");
    }

    my %args = ( subject_class_name => $self->class );
    $args{'subject_id'} = $self->id if (ref $self);
    $args{'aspect'} = $aspect if (defined $aspect);
    $args{'callback'} = $callback if (defined $callback);
    my @observers = UR::Observer->get(%args);

    $_->delete foreach @observers;
    return @observers;
}

sub create_iterator {
    my $class = shift;

    # old syntax = create_iterator(where => [param_a => A, param_b => B])
    if (@_ > 1) {
        my %params = @_;
        if (exists $params{'where'}) {
            Carp::carp('create_iterator called with old syntax create_iterator(where => \@params) should be called as create_iterator(@params)');
            @_ = $params{'where'};
        }
    }

    # new syntax, same as get() = create_iterator($bx) or create_iterator(param_a => A, param_b => B)
    my $filter;
    if (Scalar::Util::blessed($_[0]) && $_[0]->isa('UR::BoolExpr')) {
        $filter = $_[0];
    } else {
        $filter = UR::BoolExpr->resolve($class, @_)
    }

    my $iterator = UR::Object::Iterator->create_for_filter_rule($filter);
    unless ($iterator) {
        $class->error_message(UR::Object::Iterator->error_message);
        return;
    }

    return $iterator;
}

sub create_view {
    my $self = shift;
    my $class = $self->class;
    # this will auto-subclass into ${class}::View::${perspective}::${toolkit},
    # using $class or some parent class of $class
    my $view = UR::Object::View->create(
        subject_class_name => $class,
        perspective => "default",
        @_
    );

    unless ($view) {
        $self->error_message("Error creating view: " . UR::Object::View->error_message);
        return;
    }

    if (ref($self)) {
        $view->subject($self);
    }

    return $view;
}

sub create_mock {
    my $class = shift;
    my %params = @_;

    require Test::MockObject;

    my $self = Test::MockObject->new();
    my $subject_class_object = $class->__meta__;
    for my $class_object ($subject_class_object,$subject_class_object->ancestry_class_metas) {
        for my $property ($class_object->direct_property_metas) {
            my $property_name = $property->property_name;
            if (($property->is_delegated || $property->is_optional) && !exists($params{$property_name})) {
                next;
            }
            if ($property->is_mutable || $property->is_calculated || $property->is_delegated) {
                my $sub = sub {
                    my $self = shift;
                    if (@_) {
                        if ($property->is_many) {
                            $self->{'_'. $property_name} = @_;
                        } else {
                            $self->{'_'. $property_name} = shift;
                        }
                    }
                    return $self->{'_'. $property_name};
                };
                $self->mock($property_name, $sub);
                if ($property->is_optional) {
                    if (exists($params{$property_name})) {
                        $self->$property_name($params{$property_name});
                    }
                } else {
                    unless (exists($params{$property_name})) {
                        if (defined($property->default_value)) {
                            $params{$property_name} = $property->default_value;
                        } else {
                            unless ($property->is_calculated) {
                                Carp::croak("Failed to provide value for required mutable property '$property_name'");
                            }
                        }
                    }
                    $self->$property_name($params{$property_name});
                }
            } else {
                unless (exists($params{$property_name})) {
                    if (defined($property->default_value)) {
                        $params{$property_name} = $property->default_value;
                    } else {
                        Carp::croak("Failed to provide value for required property '$property_name'");
                    }
                }
                if ($property->is_many) {
                    $self->set_list($property_name,$params{$property_name});
                } else {
                    $self->set_always($property_name,$params{$property_name});
                }
            }
        }
    }
    my @classes = ($class, $subject_class_object->ancestry_class_names);
    $self->set_isa(@classes);
    $UR::Context::all_objects_loaded->{$class}->{$self->id} = $self;
    return $self;
}

# Typically only used internally by UR except when debugging.

sub __changes__ {
    # Return a list of changes present on the object _directly_.
    # This is really only useful internally because the boundary of the object
    # is internal/subjective.

    my $self = shift;

    # performance optimization
    return unless $self->{_change_count};

    my $meta = $self->__meta__;
    if (ref($meta) eq 'UR::DeletedRef') {
        print Data::Dumper::Dumper($self,$meta);
        Carp::confess("Meta is deleted for object requesting changes: $self\n");
    }
    if (!$meta->is_transactional and !$meta->is_meta_meta) {
        return;
    }

    my $orig = $self->{db_saved_uncommitted} || $self->{db_committed};

    my %prop_metas;
    my $prop_is_changed = sub {
        my $prop_name = shift;
        my $property_meta = $prop_metas{$prop_name} ||= $meta->property_meta_for_name($prop_name);
        no warnings 'uninitialized';
        return ($orig->{$prop_name} ne $self->{$prop_name})
                &&
                ($self->can($prop_name) and ! UR::Object->can($prop_name))
                &&
                defined($property_meta)
                &&
               (! $property_meta->is_transient)
            ;
    };

    unless (wantarray) {
        # scalar context only cares if there are any changes or not
        if (@_) {
            foreach (@_) {
                return 1 if $prop_is_changed->($_);
            }
            return '';
        } else {
            return ($self->{__defined} and $self->{_change_count} == 1)
                    ? ''
                    : $self->{_change_count};
        }
    }

    no warnings;
    my @changed;
    if ($orig) {
        my $class_name = $meta->class_name;
        @changed =
            grep { $prop_is_changed->($_) }
            grep { $_ }
            @_ ? (@_) : keys(%$orig);
    }
    else {
        @changed = $meta->all_property_names
    }

    return map {
        UR::Object::Tag->create
        (
            type => 'changed',
            properties => [$_]
        )
    } @changed;
}


sub _changed_property_names {
    my $self = shift;

    my @changes = $self->__changes__;
    my %changed_properties;
    foreach my $change ( @changes ) {
        next unless ($change->type eq 'changed');
        $changed_properties{$_} = 1 foreach $change->properties;
    }
    return keys %changed_properties;
}

sub __signal_change__ {
    # all mutable property accessors ("setters") call this method to tell the
    # current context about a state change.
    $UR::Context::current->add_change_to_transaction_log(@_);
    $UR::Context::current->send_notification_to_observers(@_);
}

# send notifications that aren't state changes to observers
sub __signal_observers__ {
    $UR::Context::current->send_notification_to_observers(@_);
}

sub __define__ {
    # This is used internally to "virtually load" things.

    # Simply assert they already existed externally, and act as though they were just loaded...
    # It is used for classes defined in the source code (which is the default) by the "class {}" magic
    # instead of in some database, as we'd do for regular objects.  It is also used by some test cases.
    if ($UR::initialized and $_[0] ne 'UR::Object::Property') {
        # the nornal implementation has all create() features
        my $self;
        do {
            local $UR::Context::construction_method = '__define__';
            $self = $UR::Context::current->create_entity(@_);
        };
        return unless $self;
        $self->{db_committed} = { %$self };
        $self->{'__defined'} = 1;
        $self->__signal_change__("load");
        return $self;
    }
    else {
        # used during boostrapping
        my $class = shift;
        my $class_meta = $class->__meta__;
        if (my $method_name = $class_meta->sub_classification_method_name) {
            my($rule, %extra) = UR::BoolExpr->resolve_normalized($class, @_);
            my $sub_class_name = $class->$method_name(@_);
            if ($sub_class_name ne $class) {
                # delegate to the sub-class to create the object
                return $sub_class_name->__define__(@_);
            }
        }

        my $self = $UR::Context::current->_construct_object($class, @_);
        return unless $self;
        $self->{db_committed} = { %$self };
        $self->__signal_change__("load");
        return $self;
    }
}

sub __extend_namespace__ {
    # A class Foo can implement this method to have a chance to auto-define Foo::Bar
    # TODO: make a Class::Autouse::ExtendNamespace Foo => sub { } to handle this.
    # Right now, UR::ModuleLoader will try it after "use".
    my $class  = shift;
    my $ext = shift;
    my $class_meta = $class->__meta__;
    return $class_meta->generate_support_class_for_extension($ext);
}

# Handling of references within the current process

sub is_weakened {
    my $self = shift;
    return (exists $self->{__weakened} && $self->{__weakened});
}

sub __weaken__ {
    # Mark this object as unloadable by the object cache pruner.
    # If the class has a data source, then a weakened object is dropped
    # at the first opportunity, reguardless of its __get_serial number.
    # For classes without a data source, then it will be dropped according to
    # the normal rules w/r/t the __get_serial (classes without data sources
    # normally are never dropped by the pruner)
    my $self = $_[0];
    delete $self->{'__strengthened'};
    $self->{'__weakened'} = 1;
}

sub is_strengthened {
    my $self = shift;
    return (exists $self->{__strengthened} && $self->{__strengthened});
}

sub __strengthen__ {
    # Indicate this object should never be unloaded by the object cache pruner
    # or AutoUnloadPool
    my $self = $_[0];
    delete $self->{'__weakened'};
    $self->{'__strengthened'} = 1;
}

sub is_prunable {
    my $self = shift;
    return 0 if $self->is_strengthened;
    return 1 if $self->is_weakened;
    return 0 if $self->__meta__->is_meta;
    return 0 if $self->{__get_serial} && $self->__changes__ && @{[$self->__changes__]};
    return 1;
}


sub __rollback__ {
    my $self = shift;

    my $saved = $self->{db_saved_uncommitted} || $self->{db_committed};
    unless ($saved) {
        return UR::Object::delete($self);
    }

    my $meta = $self->__meta__;

    my $should_rollback = sub {
        my $property_meta = shift;
        return ! (
            defined $property_meta->is_id
            || ! defined $property_meta->column_name
            || $property_meta->is_delegated
            || $property_meta->is_legacy_eav
            || ! $property_meta->is_mutable
            || $property_meta->is_transient
            || $property_meta->is_constant
        );
    };
    my @rollback_property_names =
        map { $_->property_name }
        grep { $should_rollback->($_) }
        map { $meta->property_meta_for_name($_) }
        $meta->all_property_names;

    # Existing object.  Undo all changes since last sync, or since load
    # occurred when there have been no syncs.
    foreach my $property_name ( @rollback_property_names ) {
        $self->__rollback_property__($property_name);
    }

    delete $self->{'_change_count'};

    return $self;
}


sub __rollback_property__ {
    my ($self, $property_name) = @_;
    my $saved = $self->{db_saved_uncommitted} || $self->{db_committed};
    unless ($saved) {
        Carp::croak(qq(Cannot rollback property '$property_name' because it has no saved state));
    }
    my $saved_value = UR::Context->current->value_for_object_property_in_underlying_context($self, $property_name);
    return $self->$property_name($saved_value);
}


sub DESTROY {
    # Handle weak references in the object cache.
    my $obj = shift;

    # objects_may_go_out_of_scope will be true if either light_cache is on, or
    # the cache_size_highwater mark is a valid value
    my($class, $id) = (ref($obj), $obj->{id});

    if (isweak($UR::Context::all_objects_loaded->{$class}{$id})
        and
        refaddr($UR::Context::all_objects_loaded->{$class}{$id}) == refaddr($obj)
    ) {
        # This object was dropped by the cache pruner or an AutoUnloadPool
        if (() = $obj->__changes__) {
            print STDERR "MEM DESTROY keeping changed object $class id $id\n" if $ENV{'UR_DEBUG_OBJECT_RELEASE'};
            $obj->_save_object_from_destruction();
            return;
        } else {
            print STDERR "MEM DESTROY object $obj class $class if $id\n" if $ENV{'UR_DEBUG_OBJECT_RELEASE'};
            $obj->unload();
            return $obj->SUPER::DESTROY();
        }
    }
    elsif (UR::Context::objects_may_go_out_of_scope()) {
        my $obj_from_cache = delete $UR::Context::all_objects_loaded->{$class}{$id};
        if ($obj->__meta__->is_meta_meta or @{[$obj->__changes__]}) {
            die "Object found in all_objects_loaded does not match destroyed ref/id! $obj/$id!" unless refaddr($obj) == refaddr($obj_from_cache);
            $obj->_save_object_from_destruction();
            print "MEM DESTROY Keeping infrastructure/changed object $obj class $class if $id\n" if $ENV{'UR_DEBUG_OBJECT_RELEASE'};
            return;
        }
        else {
            if ($ENV{'UR_DEBUG_OBJECT_RELEASE'}) {
                print STDERR "MEM DESTROY object $obj class $class id $id\n";
            }
            $obj->unload();
            return $obj->SUPER::DESTROY();
        }
    }
    else {
        if ($ENV{'UR_DEBUG_OBJECT_RELEASE'}) {
            print STDERR "MEM DESTROY object $obj class $class id $id\n";
        }
        $obj->SUPER::DESTROY();
    }
};

sub _save_object_from_destruction {
    my $obj = shift;
    my($class, $id) = (ref($obj), $obj->{id});
    $UR::Context::all_objects_loaded->{$class}{$id} = $obj;
}

END {
    # Turn off monitoring of the DESTROY handler at application exit.
    # setting the typeglob to undef does not work. -sms
    delete $UR::Object::{DESTROY};
};

# This module implements the deprecated parts of the UR::Object API
require UR::ObjectDeprecated;

1;

=pod

=head1 NAME

UR::Object - transactional, queryable, process-independent entities

=head1 SYNOPSIS

Create a new object in the current context, and return it:

  $elmo = Acme::Puppet->create(
    name => 'Elmo',
    father => $ernie,
    mother => $bigbird,
    jobs => [$dance, $sing],
    favorite_color => 'red',
  );

Plain accessors work in the typial fashion:

  $color = $elmo->favorite_color();

Changes occur in a transaction in the current context:

  $elmo->favorite_color('blue');

Non-scalar (has_many) properties have a variety of accessors:

  @jobs = $elmo->jobs();
  $jobs = $elmo->job_arrayref();
  $set  = $elmo->job_set();
  $iter = $elmo->job_iterator();
  $job  = $elmo->add_job($snore);
  $success = $elmo->remove_job($sing);

Query the current context to find objects:

  $existing_obj  = Acme::Puppet->get(name => 'Elmo');
  # same reference as $existing_obj

  @existing_objs = Acme::Puppet->get(
    favorite_color => ['red','yellow'],
  );
  # this will not get elmo because his favorite color is now blue

  @existing_objs = Acme::Puppet->get(job => $snore);
  # this will return $elmo along with other puppets that snore,
  # though we haven't saved the change yet..

Save our changes:

  UR::Context->current->commit;

Too many puppets...:

  $elmo->delete;

  $elmo->play; # this will throw an exception now

  $elmo = Acme::Puppet->get(name => 'Elmo'); # this returns nothing now

Just kidding:

  UR::Context->current->rollback; # not a database rollback, an in-memory undo

All is well:

  $elmo = Acme::Puppet->get(name => 'Elmo'); # back again!

=head1 DESCRIPTION

UR::Objects are transactional, queryable, representations of entities, built to maintain
separation between the physical reference in a program, and the logical entity the
reference represents, using a well-defined interface.

UR uses that separation to automatically handle I/O.  It provides a query API,
and manages the difference between the state of entities in the application,
and their state in external persistence systems.  It aims to do so transparently,
keeping I/O logic orthogonally to "business logic", and hopefully making code
around I/O unnecessary to write at all for most programs.

Rather than explicitly constructing and serializing/deserializing objects, the
application layer just requests objects from the current "context", according to
their characteristics.  The context manages database connections, object state
changes, references, relationships, in-memory transactions, queries and caching in
tunable ways.

Accessors dynamically fabricate references lazily, as needed through the same
query API, so objects work as the developer would traditionally expect in
most cases.  The goal of UR::Object is that your application doesn't have to do
data management.  Just ask for what you want, use it, and let it go.

UR::Objects support full reflection and meta-programming.  Its meta-object
layer is fully self-bootstrapping (most classes of which UR is composed are
themselves UR::Objects), so the class data can introspect itself,
such that even classes can be created within transactions and discarded.

=head1 INHERITANCE

  UR::ModuleBase    Basic error, warning, and status messages for modules in UR.
    UR::Object      This class - general OO transactional OO features

=head1 WRITING CLASSES

See L<UR::Manual::Tutorial> for a narrative explanation of how to write clases.

For a complete reference see L<UR::Manual::WritingClasses>.

For the meta-object API see L<UR::Object::Type>.

A simple example, declaring the class used above:

  class Acme::Puppet {
      id_by => 'name',
      has_optional => [
          father => { is => 'Acme::Puppet' },
          mother => { is => 'Acme::Puppet' },
          jobs   => { is => 'Acme::Job', is_many => 1 },
      ]
  };

You can also declare the same API, but specifying additional internal details to make
database mapping occur the way you'd like:

  class Acme::Puppet {
      id_by => 'name',
      has_optional => [
          father => { is => 'Acme::Puppet', id_by => 'father_id' },
          mother => { is => 'Acme::Puppet', id_by => 'mother_id' },
      },
      has_many_optional => [
          job_assignments => { is => 'Acme::PuppetJob', im_its => 'puppet' },
          jobs            => { is => 'Acme::Job', via => 'job_assignments', to => 'job'  },
      ]
  };


=head1 CONSTRUCTING OBJECTS

New objects are returned by create() and get(), which delegate to the current
context for all object construction.

The create() method will always create something new or will return undef if
the identity is already known to be in use.

The get() method lets the context internally decide whether to return a cached
reference for the specified logical entities or to construct new objects
by loading data from the outside.

=head1 METHODS

The examples below use $obj where an actual object reference is required,
and SomeClass where the class name can be used.  In some cases the
example in the synopsisis is continued for deeper illustration.

=head2 Base API

=over 4

=item get

  $obj = SomeClass->get($id);
  $obj = SomeClass->get(property1 => value1, ...);
  @obj = SomeClass->get(property1 => value1, ...);
  @obj = SomeClass->get('property1 operator1' => value1, ...);

Query the current context for objects.

It turns the passed-in parameters into a L<UR::BoolExpr> and returns all
objects of the given class which match.  The current context determines
whether the request can be fulfilled without external queries.  Data
is loaded from underlying database(s) lazliy as needed to fulfuill the
request.

In the simplest case of requesting an object by id which is cached, the
call to get() is an immediate hash lookup, and is very fast.

See L<UR::Manual::Queries>, or look at L<UR::Object::Set>, L<UR::BoolExpr>,
and L<UR::Context> for details.

If called in scalar context and more than one object matches the given
parameters, get() will raise an exception through C<die>.

=item create

  $obj = SomeClass->create(
    property1 => $value1,
    properties2 => \@values2,
  );

Create a new entity in the current context, and return a reference to it.

The only required property to create an object is the "id",
and that is only required for objects which do not autogenerate their
own ids.  This requirement may be overridden in subclasses to be
more restrictive.

If entities of this type persist in an underlying context, the entity will
not appear there until commit.  (i.e. no insert is done until just before
a real database commit)  The object in question does not need to pass its own
constraints when initially created, but must be fully valid before the
transaction which created it commits.

=item delete

  $obj->delete

Deletes an object in the current context.

The $obj reference will be garbage collected at the discretion of the Perl interpreter as soon as possible.
Any attempt to use the reference after delete() is called will result in an exception.

If the represented entity was loaded from the parent context (i.e. persistent database objects),
it will not be deleted from that context (the database) until commit is called.  The commit call
will do both the delete and the commit, presuming the complete save works across all involved
data sources.

Should the transaction roll-back, the deleted object will be re-created in the current context,
and a fresh reference will later be returnable by get().  See the documentation on L<UR::Context>
for details on how deleted objects are rememberd and removed later from the database, and how
deleted objects are re-constructed on STM rollback.

=item copy

  $obj->copy(%overrides)

Copies the existing C<$obj> by copying the values of all direct properties,
except for ID properties, to a newly created object of the same type.  A list
of params and values may be provided as overrides to the existing values or to
specify an ID.

=item class

 $class_name = $obj->class;
 $class_name = SomeClass->class;

Returns the name of the class of the object in question.  See __meta__ below
for the class meta-object.

=item id

 $id = $obj->id;

The unique identifier of the object within its class.

For database-tracked entities this is the primary key value, or a composite
blob containing the primary key values for multi-column primary keys.

For regular objects private to the process, the default id embeds the
hostname, process ID, and a timestamp to uniquely identify the
UR::Context::Process object which is its final home.

When inheritance is involved beneath UR::Object, the 'id' may identify the object
within the super-class as well.  It is also possible for an object to have a
different id upon sub-classification.


=back

=head2 Accessors

Every relationship declared in the class definition results in at least one
accesor being generated for the class in question.

Identity properties are read-only, while non-identity properties are read-write
unless is_mutable is explicitly set to false.

Assigning an invalid value is allowed temporarily, but the current transaction
will be in an invalid state until corrected, and will not be commitable.

The return value of an the accessor when it mutates the object is
the value of the property after the mutation has occurred.


=head3 Single-value property accessors:

By default, properties are expected to return a single value.

=over 4

=item NAME

Regular accessors have the same name as the property, as declared, and also work
as mutators as is commonly expected:

  $value = $obj->property_name;
  $obj->property_name($new_value);

When the property is declared with id_by instead of recording the refereince, it
records the id of the object automatically, such that both will return different
values after either changes.

=back

=head3 Muli-value property accessors:

When a property is declared with the "is_many" flag, a variety of accessors are made
available on the object.  See C<UR::Manual::WritingClasses> for more details
on the ways to declare relationships between objects when writing classes.

Using the example from the synopsis:

=over 4

=item NAMEs (the property name pluralized)

A "has_many" relationship is declared using the plural form of the relationship name.
An accessor returning the list of property values is generated for the class.  It
is usable with or without additional filters:

  @jobs = $elmo->jobs();
  @fun_jobs = $elmo->jobs(is_fun => 1);

The singular name is used for the remainder of the accessors...

=item NAME (the property name in singular form)

Returns one item from the group, which must be specified in parameters.  If more
than one item is matched, an exception is thrown via die():

 $job = $elmo->job(name => 'Sing');

 $job = $elmo->job(is_fun => 1);
 # die: too many things are fun for Elmo

=item NAME_list

The default accessor is available as *_list.  Usable with or without additional filters:

  @jobs = $elmo->job_list();
  @fun_jobs = $elmo_>job_list(is_fun => 1);


=item NAME_set

Return a L<UR::Object::Set> value representing the values with *_set:

  $set  = $elmo->job_set();
  $set  = $elmo->job_set(is_hard => 1);


=item NAME_iterator

Create a new iterator for the set of property values with *_iterator:

  $iter = $elmo->job_iterator();
  $iter = $elmo->job_iterator(is_fun => 1, -order_by => ['name]);
  while($obj = $iter->next()) { ... }

=item add_NAME

Add an item to the set of values with add_*:

  $added  = $elmo->add_job($snore);

A variation of the above will construt the item and add it at once.
This second form of add_* automatically would identify that the line items
also reference the order, and establish the correct converse relationship
automatically.

  @lines = $order->lines;
  # 2 lines, for instance

  $line = $order->add_line(
     product => $p,
     quantity => $q,
  );
  print $line->num;
  # 3, if the line item has a multi-column primary key with auto_increment on the 2nd column called num

=item remove_NAME

Items can be removed from the assigned group in a way symetrical with how they are added:

  $removed = $elmo->remove_job($sing);

=back

=head2 Extended API

These methods are available on any class defined by UR.  They
are convenience methods around L<UR::Context>, L<UR::Object::Set>,
L<UR::BoolExpr>, L<UR::Object::View>, L<UR::Observer>
and L<Mock::Object>.

=over 4

=item create_iterator

  $iter = SomeClass->create_iterator(
    property1 => $explicit_value,
    property2 => \@my_in_clause,
    'property3 like' => 'some_pattern_with_%_as_wildcard',
    'property4 between' => [$low,$high],
  );

  while (my $obj = $iter->next) {
    ...
  }

Takes the same sort of parameters as get(), but returns a L<UR::Object::Iterator>
for the matching objects.

The next() method will return one object from the resulting set each time it is
called, and undef when the results have been exhausted.

C<UR::Object::Iterator> instances are normal object references in the current
process, not context-oriented UR::Objects.  They vanish upon dereference,
and cannot be retrieved by querying the context.

When using an iterator, the system attempts to return objects matching the params
at the time the iterator is created, even if those objects do not match the
params at the time they are returned from next().  Consider this case:

  # many objects in the DB match this
  my $iter = SomeClass->create_iterator(job => 'cleaner');

  my $an_obj = SomeClass->get(job => 'cleaner', id => 1);
  $an_obj->job('messer-upper');    # This no longer matches the iterator's params

  my @iter_objs;
  while (my $o = $iter->next) {
      push @iter_objs, $o;
  }

At the end, @iter_objs will contain several objects, including the object with id 1,
even though its job is no longer 'cleaner'.  However, if an object matching the
iterator's params is deleted between the time the iterator is created and the time
next() would return that object, then next() will throw an exception.

=item define_set

 $set = SomeClass->define_set(
    property1 => $explicit_value,
    property2 => \@my_in_clause,
    'property3 like' => 'some_pattern_with_%_as_wildcard',
    'property4 between' => [$low,$high],
 );

 @subsets = $set->group_by('property3','property4');

 @some_members = $subsets[0]->members;

Takes the same sort of parameters as get(), but returns a set object.

Sets are lazy, and only query underlying databases as much as necessary.  At any point
in time the members() method returns all matches to the specified parameters.

See L<UR::Object::Set> for details.

=item define_boolexpr

 $bx = SomeClass->define_boolexpr(
    property1 => $explicit_value,
    property2 => \@my_in_clause,
    'property3 like' => 'some_pattern_with_%_as_wildcard',
    'property4 between' => [$low,$high],
 );

 $bx->evaluate($obj1); # true or false?

Takes the same sort of parameters as get(), but returns a L<UR::BoolExpr> object.

The boolean expression can be used to evaluate other objects to see if they match
the given condition.  The "id" of the object embeds the complete "where clause",
and as a semi-human-readable blob, such is reconstitutable from it.

See L<UR::BoolExpr> for details on how to use this to do advanced work on
defining sets, comparing objects, creating query templates, adding
object constraints, etc.

=item add_observer

 $o = $obj1->add_observer(
    aspect => 'someproperty'
    callback => sub { print "change!\n" },
 );

 $obj1->property1('new value');

 # observer callback fires....

 $o->delete;

Adds an observer to an object, monitoring one or more of its properties for changes.

The specified callback is fired upon property changes which match the observation request.

See L<UR::Observer> for details.

=item create_mock

 $mock = SomeClass->create_mock(
    property1 => $value,
    method1 => $return_value,
 );

Creates a mock object using using the class meta-data for "SomeClass" via L<Mock::Object>.

Useful for test cases.

=back

=head2 Meta API

The following methods allow the application to interrogate UR for information
about the object in question.

=over 4

=item __meta__

  $class_obj = $obj->__meta__();

Returns the class metadata object for the given object's class.  Class objects
are from the class L<UR::Object::Type>, and hold information about the class'
properties, data source, relationships to other classes, etc.

=item __extend_namespace__

  package Foo::Bar;

  class Foo::Bar { has => ['stuff','things'] };

  sub __extend_namespace__ {
     my $class = shift;
     my $ext = shift;
     return class {$class . '::' . $ext} { has => ['more'] };
  }

Dynamically generate new classes under a given namespace.
This is called automatically by UR::ModuleLoader when an unidentified class name is used.

If Foo::Bar::Baz is not a UR class, and this occurs:

  Foo::Bar::Baz->some_method()

This is called:

  Foo::Bar->__extend_namespace__("Baz")

If it returns a new class meta, the code will proceed on as though the class
had always existed.

If Foo::Bar does not exist, the above will be called recursively:

  Foo->__extend_namespace__("Bar")

If Foo::Bar, whether loaded or generated, cannot extend itself for "Baz",
the loader will go up the tree before giving up.  This means a top-level
module could dynamically define classes for any given class name used
under it:

  Foo->__extend_namespace__("Bar::Baz")

=item __errors__

  @tags = $obj->__errors__()

Return a list of L<UR::Object::Tag> values describing the issues which would
prevent a commit in the current transaction.

The base implementation check the validity of an object by applying any constraints
layed out in the class such as making sure any non-optional properties contain values,
numeric properties contain numeric data, and properties with enumerated values only
contain valid values.

Sub-classes can override this method to add additional validity checking.

=item __display_name__

 $text = $obj->__display_name__;
 # the class and id of $obj, by default

 $text = $line_item->__display_name__($order);

Stringifies an object.  Some classes may choose to actually overload the stringification operator
with this method.  Even if they do not, this method will still attempt to identify this object in
text form.  The default returns the class name and id value of the object within a string.

It can be overridden to do a more nuanced job.  The class might also choose to overload the
stringification operator itself with this method, but even if it doesn not the system will
presume this method can be called directly on an object for reasonable stringificaiton.

=item __context__

 $c = $self->__context__;

Return the L<UR::Context> for the object reference in question.

In UR, a "context" handles connextions between objects, instead of relying
on having objects directly reference each other.  This allows an object
to have a relationship with a large number of other logical entities,
without having a "physical" reference present within the process in question.

All attempts to resolve non-primitive attribute access go through the context.

=back

=head2 Extension API

These methods are primarily of interest for debugging, for test cases, and internal UR development.

They are likely to change before the 1.0 release.

=over 4

=item __signal_change__

Called by all mutators to tell the current context about a state change.

=item __changes__

  @tags = $obj->__changes__()

  @tags = $obj->__changes__('prop1', 'prop2', ...)

Return a list of changes present on the object _directly_.  This is really only
useful internally because the boundary of the object is internal/subjective.
Callers may also request only changes to particular properties.

Changes to objects' properties are tracked by the system.  If an object has been
changed since it was defined or loaded from its external data source, then changed()
will return a list of L<UR::Object::Tag> objects describing which properties have been
changed.

Work is in-progress on an API to request the portion of the changes in effect in the
current transaction which would impact the return value of a given list of properties.
This would be directly usable by a view/observer.

=item __define__

This is used internally to "virtually load" things.  Simply assert they already existed
externally, and act as though they were just loaded...  It is used for classes defined in
the source code (which is the default) by the "class {}" magic instead of in some database,
as we'd do for regular objects.

=item __strengthen__

  $obj->__strengthen__();

Mark this object as unloadable by the object cache pruner.

UR objects are normally tracked by the current Context for the life of the
application, but the programmer can specify a limit to cache size, in
which case old, unchanged objects are periodically pruned from the cache.
If strengthen() is called on an object, it will effectively be locked in
the cache, and will not be considered for pruning.

See L<UR::Context> for more information about the pruning mechanism.

=item is_strengthened

Check if an object has been stengthened, C<__stengthen__>.

=item __weaken__

  $obj->__weaken__();

Give a hint to the object cache pruner that this instance is not going to be used
in the application in the future, and should be removed with preference when
pruning the cache.

=item is_weakened

Check if an object has been weakened, C<__weaken__>.

=item DESTROY

Perl calls this method on any object before garbage collecting it.  It
should never by called by your application explicitly.

The DESTROY handler is overridden in UR::Object.  If you override it in
a subclass, be sure to call $self->SUPER::DESTROY() before exiting your
override, or errors will occur.

=back

=head1 ERRORS, WARNINGS and STATUS MESSAGES

When an error occurs which is "exceptional" the API will throw an exception via die().

In some cases, when the possibility of failure is "not-exceptional", the method will simply
return false.  In scalar context this will be undef.  In list context an empty list.

When there is ambiguity as to whether this is an error or not (get() for instance, might
simply match zero items, ...or fail to understand your parameters), an exception is used.

=over 4

=item error_message

The standard way to convey the error which has occurred is to set ->error_message() on
the object.  This will propagate to the class, and through its inheritance.  This is
much like DBI's errstr method, which affects the handle on which it was called, its source
handle, and the DBI package itself.

=item warning_message

Calls to warning_message also record themselves on the object in question, and its class(es).

They also emit a standard Perl warn(), which will invoke $SIG{__WARN__};

=item status_message

Calls to status_message are also recorded on the object in question.  They can be
monitored through hooks, as can the other messages.

=back

See L<UR::ModuleBase> for more information.

=head1 SEE ALSO

L<UR>, L<UR::Object::Type>, L<UR::Context>

L<UR::Maual::Tutorial>, L<UR::Manual::WritingClasses>, L<UR::Manual::Queries>, L<UR::Manual::Transactions>

L<UR::ObjectDeprecated> contains additional methods which are deprecated in the API.

=cut

