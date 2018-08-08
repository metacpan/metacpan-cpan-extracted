package UR::Observer;

use strict;
use warnings;

BEGIN {
    require UR;
    require UR::Context::Transaction;
};

our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    has => [
        subject_class_name => { is => 'Text',    is_optional => 1, default_value => 'UR::Object' },
        subject_id         => { is => 'SCALAR',  is_optional => 1, default_value => '' },
        aspect             => { is => 'String',  is_optional => 1, default_value => '' },
        priority           => { is => 'Number',  is_optional => 1, default_value => 1  },
        note               => { is => 'String',  is_optional => 1, default_value => '' },
        once               => { is => 'Boolean', is_optional => 1, default_value => 0  },
        subject            => { is => 'UR::Object', id_by => 'subject_id', id_class_by => 'subject_class_name' },
    ],
    is_transactional => 1,
);

# This is not implemented as a "real" observer via create() because at the point during bootstrapping
# that this module is loaded, we're not yet ready to start creating objects
__PACKAGE__->_insert_record_into_all_change_subscriptions('UR::Observer', 'priority', '',
                                          [\&_modify_priority, '', 0, UR::Object::Type->autogenerate_new_object_id_uuid]);

sub create {
    my $class = shift;

    $class->_create_or_define('create', @_);
}

sub __define__ {
    my $class = shift;

    $class->_create_or_define('__define__', @_);
}

my @required_params_for_register = qw(aspect callback note once priority subject_class_name subject_id id);
sub required_params_for_register { @required_params_for_register }

sub _create_or_define {
    my $class = shift;
    my $method = shift;
    my %params = @_;

    my $callback = delete $params{callback};

    my $self = UR::Context::Transaction::do {
        my $inner_self;
        if ($method eq 'create') {
            $inner_self = $class->SUPER::create(%params);
        } elsif ($method eq '__define__') {
            $inner_self = $class->SUPER::__define__(%params);
        } else {
            Carp::croak('Instantiating a UR::Observer with some method other than create() or __define__() is not supported');
        }
        $inner_self->{callback} = $callback;
        $inner_self->register_callback(map { $_ => $inner_self->$_ } @required_params_for_register);
        return $inner_self;
    };

    return $self;
}


{
    my @has_defaults = qw(aspect note once priority subject_class_name subject_id);
    sub has_defaults { @has_defaults }

    my %defaults =
        map {
            $_ => __PACKAGE__->__meta__->{has}->{$_}->{default_value}
        }
        grep {
            exists __PACKAGE__->__meta__->{has}->{$_}
            && exists __PACKAGE__->__meta__->{has}->{$_}->{default_value}
        } @has_defaults;
    sub defaults_for_register_callback { %defaults }
}

sub register_callback {
    my $class = shift;
    my %params = @_;

    unless (defined $params{id}) {
        $params{id} = UR::Object::Type->autogenerate_new_object_id_uuid;
    }

    my %values = $class->defaults_for_register_callback();
    my @specified_params = grep { exists $params{$_} } @required_params_for_register;
    @values{@specified_params} = map { delete $params{$_} } @specified_params;

    my @bad_params = keys %params;
    if (@bad_params) {
        Carp::croak('invalid params: ' . join(', ', @bad_params));
    }

    my @missing_params = grep { not exists $values{$_} } @required_params_for_register;
    if (@missing_params) {
        Carp::croak('missing required params: ' . join(', ', @missing_params));
    }

    my @undef_values = grep { not defined $values{$_} } keys %values;
    if (@undef_values) {
        Carp::croak('undefined values: ' . join(', ', @undef_values));
    }

    my $subject_class_name = $values{subject_class_name};
    my $subject_class_meta = eval { $subject_class_name->__meta__ };
    if ($@) {
        Carp::croak("Can't create observer with subject_class_name '$subject_class_name': Can't get class metadata for class '$subject_class_name': $@");
    }
    unless ($subject_class_meta) {
        Carp::croak("Class $subject_class_name cannot be the subject class for an observer because there is no class metadata");
    }

    my $aspect = $values{aspect};
    my $subject_id = $values{subject_id};
    unless ($subject_class_meta->_is_valid_signal($aspect)) {
        my $croak =  sub { Carp::croak("'$aspect' is not a valid aspect for class $subject_class_name") };
        unless ($subject_class_name->can('validate_subscription')) {
            $croak->();
        }
        unless ($subject_class_name->validate_subscription($aspect, $subject_id, $values{callback})) {
            $croak->();
        }
    }

    $class->_insert_record_into_all_change_subscriptions(
        @values{qw(subject_class_name aspect subject_id)},
        [@values{qw(callback note priority id once)}],
    );

    return $values{id};
}

sub _insert_record_into_all_change_subscriptions {
    my($class,$subject_class_name, $aspect,$subject_id, $new_record) = @_;

    if ($subject_class_name eq 'UR::Object') {
        $subject_class_name = '';
    };

    my $list = $UR::Context::all_change_subscriptions->{$subject_class_name}->{$aspect}->{$subject_id} ||= [];
    push @$list, $new_record;
}

sub _modify_priority {
    my($self, $aspect, $old_val, $new_val) = @_;

    my $subject_class_name = $self->subject_class_name;
    my $subject_aspect = $self->aspect;
    my $subject_id = $self->subject_id;

    my $list = $UR::Context::all_change_subscriptions->{$subject_class_name}->{$subject_aspect}->{$subject_id};
    return unless $list;  # this is probably an error condition

    my $data;
    for (my $i = 0; $i < @$list; $i++) {
        if ($list->[$i]->[3] eq $self->id) {
            ($data) = splice(@$list,$i, 1);
            last;
        }
    }
    return unless $data;  # This is probably an error condition...

    $data->[2] = $new_val;

    $self->_insert_record_into_all_change_subscriptions($subject_class_name, $subject_aspect, $subject_id, $data);
}

sub callback {
    shift->{callback};
}

sub subscription {
    shift->{subscription}
}

sub unregister_callback {
    my $class = shift;
    my %params = @_;

    my $id = delete $params{id};
    unless (defined $id) {
        Carp::croak('missing required parameter: id');
    }

    my @undef_params = grep { not defined $params{$_} } keys %params;
    if (@undef_params) {
        Carp::croak('undefined params: ' . join(', ', @undef_params));
    }

    my $aspect = delete $params{aspect};
    my $subject_class_name = delete $params{subject_class_name};
    my $subject_id = delete $params{subject_id};

    my @bad_params = keys %params;
    if (@bad_params) {
        Carp::croak('invalid params: ' . join(', ', @bad_params));
    }

    my @subject_class_names = $subject_class_name || keys %{$UR::Context::all_change_subscriptions};
    for my $subject_class_name (@subject_class_names) {
        my @aspects = $aspect || keys %{$UR::Context::all_change_subscriptions->{$subject_class_name}};
        for my $aspect (@aspects) {
            my @subject_ids = $subject_id || keys %{$UR::Context::all_change_subscriptions->{$subject_class_name}->{$aspect}};
            for my $subject_id (@subject_ids) {
                my $arrayref = $UR::Context::all_change_subscriptions->{$subject_class_name}->{$aspect}->{$subject_id};
                for (my $i = 0; $i < @$arrayref; $i++) {
                    if ($arrayref->[$i]->[3] eq $id) {
                        splice(@$arrayref, $i, 1);
                        if (@$arrayref == 0) {
                            $arrayref = undef;
                            delete $UR::Context::all_change_subscriptions->{$subject_class_name}->{$aspect}->{$subject_id};
                            if (not keys %{ $UR::Context::all_change_subscriptions->{$subject_class_name}->{$aspect} }) {
                                delete $UR::Context::all_change_subscriptions->{$subject_class_name}->{$aspect};
                            }
                        }
                        return 1;
                    }
                }
            }
        }
    }

    return;
}

sub delete {
    my $self = shift;
    #$DB::single = 1;

    my $subject_class_name = $self->subject_class_name;
    my $subject_id         = $self->subject_id;
    my $aspect             = $self->aspect;

    $subject_class_name = '' if (! $subject_class_name or $subject_class_name eq 'UR::Object');
    $subject_id         = '' unless (defined $subject_id);
    $aspect             = '' unless (defined $aspect);

    my $unregistered = $self->unregister_callback(
        aspect => $aspect,
        id => $self->id,
        subject_class_name => $subject_class_name,
        subject_id => $subject_id,
    );
    if ($unregistered) {
        unless ($subject_class_name eq '' || $subject_class_name->inform_subscription_cancellation($aspect, $subject_id, $self->{'callback'})) {
            Carp::confess("Failed to validate requested subscription cancellation for aspect '$aspect' on class $subject_class_name");
        }
    }
    $self->SUPER::delete();
}

sub __rollback__ {
    my $self = shift;
    return UR::Observer::delete($self);
}

sub get_with_special_parameters {
    my($class,$rule,%extra) = @_;

    my $callback = delete $extra{'callback'};
    if (keys %extra) {
        Carp::croak("Unrecognized parameters in get(): " . join(', ', keys(%extra)));
    }
    my @matches = $class->get($rule);
    return grep { $_->callback eq $callback } @matches;
}

1;


=pod

=head1 NAME

UR::Observer - bind callbacks to object changes 

=head1 SYNOPSIS

    $rocket = Acme::Rocket->create(
        fuel_level => 100
    );
    
    $observer = $rocket->add_observer(
        aspect => 'fuel_level',
        callback => 
            sub {
                print "fuel level is: " . shift->fuel_level . "\n"
            },
        priority => 2,
    );

    $observer2 = UR::Observer->create(
        subject_class_name => 'Acme::Rocket',
        subject_id    => $rocket->id,
        aspect => 'fuel_level',
        callback =>
            sub {
                my($self,$changed_aspect,$old_value,$new_value) = @_;
                if ($new_value == 0) {
                    print "Bail out!\n";
                }
            },
        priority => 0
    );


    for (3 .. 0) {
        $rocket->fuel_level($_);
    }
    # fuel level is: 3
    # fuel level is: 2
    # fuel level is: 1
    # Bail out!
    # fuel level is: 0
    
    $observer->delete;

=head1 DESCRIPTION

UR::Observer implements the observer pattern for UR objects.  These observers
can be attached to individual object instances, or to whole classes.  They
can send notifications for changes to object attributes, or to other state
changes such as when an object is loaded from its datasource or deleted.

=head1 CONSTRUCTOR

Observers can be created either by using the method C<add_observer()> on
another class, or by calling C<create()> on the UR::Observer class.

  my $o1 = Some::Other::Class->add_observer(...);
  my $o2 = $object_instance->add_observer(...);
  my $o3 = UR::Observer->create(...);

The constructor accepts these parameters:

=over 2

=item subject_class_name

The name of the class the observer is watching.  If this observer is being
created via C<add_observer()>, then it figures out the subject_class_name
from the class or object it is being called on.

=item subject_id

The ID of the object the observer is watching.  If this observer is being
created via C<add_observer()>, then it figures out the subject_id from the
object it was called on.  If C<add_observer()> was called as a class method,
then subject_id is omitted, and means that the observer should fire for
changes on any instance of the class or sub-class.

=item priority

A numeric value used to determine the order the callbacks are fired.  Lower
numbers are higher priority, and are run before callbacks with a numerically
higher priority.  The default priority is 1.  Negative numbers are ok.

=item aspect

The attribute the observer is watching for changes on.  The aspect is commonly
one of the properties of the class.  In this case, the callback is fired after
the property's value changes.  aspect can be omitted, which means the observer
should fire for any change in the object state.  If both subject_id and aspect
are omitted, then the observer will fire for any change to any instance of the
class.

There are other, system-level aspects that can be watched for that correspond to other types
of state change:

=over 2

=item create

After a new object instance is created

=item delete

After an n object instance is deleted

=item load

After an object instance is loaded from its data source

=item commit

After an object instance has changes saved to its data source

=back

=item callback

A coderef that is called after the observer's event happens.  The coderef is
passed four parameters: $self, $aspect, $old_value, $new_value.  In this case,
$self is the object that is changing, not the UR::Observer instance (unless,
of course, you have created an observer on UR::Observer).  The return value of
the callback is ignored.

=item once

If the 'once' attribute is true, the observer is deleted immediately after
the callback is run.  This has the effect of running the callback only once,
no matter how many times the observer condition is triggered.

=item note

A text string that is ignored by the system

=back

=head2 Custom aspects

You can create an observer for an aspect that is neither a property nor one
of the system aspects by listing the aspect names in the metadata for the
class.

    class My::Class {
        has => [ 'prop_a', 'another_prop' ],
        valid_signals => ['custom', 'pow' ],
    };

    my $o = My::Class->add_observer(
                aspect => 'pow',
                callback => sub { print "POW!\n" },
            );
    My::Class->__signal_observers__('pow');  # POW!

    my $obj = My::Class->create(prop_a => 1);
    $obj->__signal_observers__('custom');  # not an error

To help catch typos, creating an observer for a non-standard aspect throws an
exception unless the named aspect is in the list of 'valid_signals' in the
class metadata.  Nothing in the system will trigger these observers, but they
can be triggered in your own code using the C<__signal_observers()__> class or
object method.  Sending a signal for an aspect that no observers are watching
for is not an error.

=cut

