package UR::Object::Set;

use strict;
use warnings;
use UR;
use List::MoreUtils qw(any);
our $VERSION = "0.46"; # UR $VERSION;

our @CARP_NOT = qw( UR::Object::Type );

use overload ('""' => '__display_name__');
use overload ('==' => sub { $_[0] . ''  eq $_[1] . '' } );
use overload ('eq' => sub { $_[0] . ''  eq $_[1] . '' } );
use overload ('!=' => sub { $_[0] . ''  ne $_[1] . '' } );
use overload ('ne' => sub { $_[0] . ''  ne $_[1] . '' } );
use overload ('cmp' => sub { $_[0]->id cmp $_[1]->id } );

class UR::Object::Set {
    is => 'UR::Value',
    is_abstract => 1,
    has => [
        rule                => { is => 'UR::BoolExpr', id_by => 'id' },
        rule_display        => { is => 'Text', via => 'rule', to => '__display_name__'},
        member_class_name   => { is => 'Text', via => 'rule', to => 'subject_class_name' },
        members             => { is => 'UR::Object', is_many => 1, is_calculated => 1 }
    ],
    doc => 'an unordered group of distinct UR::Objects'
};

# override the UR/system display name
# this is used in stringification overload
sub __display_name__ {
    my $self = shift;
    my %b = $self->rule->_params_list;
    my $s = Data::Dumper->new([\%b])->Terse(1)->Indent(0)->Useqq(1)->Dump;
    $s =~ s/\n/ /gs;
    $s =~ s/^\s*{//; 
    $s =~ s/\}\s*$//;
    $s =~ s/\"(\w+)\" \=\> / $1 => /g;
    return '(' . ref($self) . ' ' . $s . ')';
}

# When a set comes into existance, set up a subscription to monitor changes
# to the set's members
UR::Object::Set->create_subscription(
    method  => 'load',
    note    => 'set creation monitor',
    callback => sub {
        my $set = shift;
        my $rule = $set->rule;
        my %set_defining_attributes = map { $_ => 1 } $rule->template->_property_names();
        my $deps = $set->{__aggregate_deps} ||= {};

        $set->member_class_name->create_subscription(
            note        => 'set monitor '.$set->id,
            priority    => 0,
            callback    => sub {
                return unless exists($set->{__aggregates});  # nothing cached  yet

                my ($member, $attr_name, $before, $after) = @_;
                # load/unload won't affect aggregate values
                return if ($attr_name eq 'load' or $attr_name eq 'unload');

                # If a set-defining attribute changes, or an object matching
                # the set is created or deleted, then the set membership has
                # possibly changed.  Invalidate the whole aggregate cache.
                if (exists($set_defining_attributes{$attr_name})
                    ||
                    (   ($attr_name eq 'create' or $attr_name eq 'delete')
                        &&
                        $rule->evaluate($member)
                    )
                ) {
                    $set->__invalidate_cache__;
                    # A later call to _members_have_changes() would miss the case
                    # where a member becomes deleted or a member-defining attribute
                    # changes
                    $set->{__members_have_changes} = 1;

                }
                # if the changed attribute is a dependancy for a cached aggregation
                # value, and it's a set member...
                elsif ((my $dependant_aggregates = $deps->{$attr_name})
                        &&
                        $rule->evaluate($member)
                ) {
                    # remove the cached aggregates that depend on this attribute
                    delete @{$set->{__aggregates}}{@$dependant_aggregates};
                    # remove the dependancy records
                    delete @$deps{@$dependant_aggregates};
                    delete $deps->{$attr_name}
                }
            }
        );
    }
);

# When a transaction rolls back, it doesn't trigger subscriptions for the
# member objects as they get changed back to their original values.
# The safe thing is to set wipe out all Sets' aggregate caches :(
# It would be helpful if sets had a db_committed like other objects
# and we could just revert their values back to their db_committed values
UR::Context::Transaction->create_subscription(
    method  => 'rollback',
    note    => 'rollback set cache invalidator',
    callback => sub {
        delete(@$_{'__aggregates','__aggregate_deps','__members_have_changes'}) foreach UR::Object::Set->is_loaded();
    }
);

UR::Context->create_subscription(
    method => 'commit',
    callback => sub {
        my $worked = shift;
        return unless $worked;  # skip if the commit failed
        delete $_->{__members_have_changes} foreach UR::Object::Set->is_loaded();
    }
);


sub get_with_special_parameters {
    Carp::cluck("Getting sets by directly properties of their members method will be removed shortly because of ambiguity on the meaning of 'id'.  Please update the code which calls this.");
    my $class = shift;
    my $bx = shift;
    my @params = @_;
    my $member_class = $class;
    $member_class =~ s/::Set$//;
    return $member_class->define_set($bx->params_list, @params);
}

sub members {
    my $self = shift;
    my $rule = $self->rule;
    while (@_) {
        $rule = $rule->add_filter(shift, shift);
    }
    return $self->member_class_name->get($rule);
}

sub member_iterator {
    my $self = shift;
    my $rule = $self->rule;
    while (@_) {
        $rule = $rule->add_filter(shift, shift);
    }
    return $self->member_class_name->create_iterator($rule);
}

sub _members_have_changes {
    my $self = shift;
    return 1 if $self->{__members_have_changes};

    my @property_names = @_;
    my $rule = $self->rule;
    return any { $rule->evaluate($_) && $_->__changes__(@property_names) } $self->member_class_name->is_loaded;
}

sub subset {
    my $self = shift;
    my $member_class_name = $self->member_class_name;
    my $bx = UR::BoolExpr->resolve($member_class_name,@_);
    my $subset = $self->class->get($bx->id);
    return $subset;
}

sub group_by {
    my $self = shift;
    my @group_by = @_;
    my $grouping_rule = $self->rule->add_filter(-group_by => \@group_by);
    my @groups = UR::Context->current->get_objects_for_class_and_rule( 
        $self->member_class_name, 
        $grouping_rule, 
        undef,  #$load, 
        0,      #$return_closure, 
    );
    return $self->context_return(@groups);
}


sub __invalidate_cache__ {
    my $self = shift;
    if (@_) {
        my $aggregate = shift;
        delete $self->{__aggregates}->{$aggregate};
    } else {
        delete @$self{'__aggregates','__aggregate_deps'};
    }
}

sub __aggregate__ {
    my $self = shift;
    my $aggr = shift;

    my $f = $aggr->{f};
    my $aggr_properties = $aggr->{properties};

    Carp::croak("$f is a group operation, and is not writable") if @_;

    my $subject_class_meta = $self->rule->subject_class_name->__meta__;

    my $not_ds_expressable = grep { $_->is_calculated or $_->is_transient or $_->is_constant }
                             map { $_->final_property_meta or $_ }
                             map { $subject_class_meta->property_meta_for_name($_) || () }
                             $self->rule->template->_property_names;

    my($cache, $deps) = @$self{'__aggregates','__aggregate_deps'};

    # If there are no member-class objects with changes, we can just interrogate the DB
    if (! exists($cache->{$f})) {
        if ($not_ds_expressable or $self->_members_have_changes(@$aggr_properties)) {
            my $fname;
            my @fargs;
            if ($f =~ /^(\w+)\((.*)\)$/) {
                $fname = $1;
                @fargs = ($2 ? split(',',$2) : ());
            }
            else {
                $fname = $f;
                @fargs = ();
            }
            my $local_method = '__aggregate_' . $fname . '__';
            $self->{__aggregates}->{$f} = $self->$local_method(@fargs);

        } else {
            my $rule = $self->rule->add_filter(-aggregate => [$f])->add_filter(-group_by => []);
            UR::Context->current->get_objects_for_class_and_rule(
                  $self->member_class_name,
                  $rule,
                  1,    # load
                  0,    # return_closure
             );

        }
        # keep 2-way mapping of dependances...
        # First, keep a list of properties this aggregate cached value depends on
        $deps->{$f} = $aggr_properties;
        # And add this aggregate to the lists these properties are dependancies for
        foreach ( @$aggr_properties ) {
            $deps->{$_} ||= [];
            push @{$deps->{$_}}, $f;
        }
    }
    return $self->{__aggregates}->{$f};
}

sub __aggregate_count__ {
    my $self = shift;
    my @members = $self->members;
    return scalar(@members);
}

sub __aggregate_min__ {
    my $self = shift;
    my $p = shift;
    my $min = undef;
    no warnings;
    for my $member ($self->members) {
        my $v = $member->$p;
        next unless defined $v;
        $min = $v if (!defined($min) || ($v < $min) || ($v lt $min));
    }
    return $min;
}

sub __aggregate_max__ {
    my $self = shift;
    my $p = shift;
    my $max = undef;
    no warnings;
    for my $member ($self->members) {
        my $v = $member->$p;
        next unless defined $v;
        $max = $v if (!defined($max) || ($v > $max) || ($v gt $max));
    }
    return $max;
}

sub __aggregate_sum__ {
    my $self = shift;
    my $p = shift;
    my $sum = undef;
    no warnings;
    for my $member ($self->members) {
        my $v = $member->$p;
        next unless defined $v;
        $sum += $v;
    }
    return $sum;
}

sub __related_set__ {
    my $self = $_[0];
    my $property_name = $_[1];
    my $bx1 = $self->rule;
    my $bx2 = $bx1->reframe($property_name);
    return $bx2->subject_class_name->define_set($bx2);
}

require Class::AutoloadCAN;
Class::AutoloadCAN->import();

sub CAN {
    my ($class,$method,$self) = @_;
    
    if ($method =~ /^__aggregate_(.*)__/) {
        # prevent circularity issues since this actually calls ->can();
        return;
    }


    my $member_class_name = $class;
    $member_class_name =~ s/::Set$//g; 
    return unless $member_class_name; 

    my $is_class_method = !ref($self);
    my $member_method_closure = $member_class_name->can($method);
    if ($is_class_method && $member_method_closure) {
        # We should only get here if the Set class has not implemented the method.
        # In which case we will delegate to the member class.
        return sub {
            my $self = shift;
            return $member_method_closure->($member_class_name, @_);
        };
    }

    if ($member_method_closure) {
        my $member_class_meta = $member_class_name->__meta__;
        my $member_property_meta = $member_class_meta->property_meta_for_name($method);
        
        # regular property access
        if ($member_property_meta) {
            return sub {
                my $self = shift;
                if (@_) {
                    Carp::croak("Cannot use method $method as a mutator: Set properties are not mutable");
                }
                my $rule = $self->rule;
                if ($rule->specifies_value_for($method)) {
                    return $rule->value_for($method);
                } 
                else {
                    my @members = $self->members;
                    my @values = map { $_->$method } @members;
                    return @values if wantarray;
                    return if not defined wantarray;
                    Carp::confess("Multiple matches for $class method '$method' called in scalar context.  The set has ".scalar(@values)." values to return") if @values > 1 and not wantarray;
                    return $values[0];
                }
            }; 
        }

        # set relaying with $s->foo_set->bar_set->baz_set;
        if (my ($property_name) = ($method =~ /^(.*)_set$/)) {
            return sub {
                shift->__related_set__($property_name, @_)
            }
        }

        # other method
        return sub {
            my $self = shift;
            if (@_) {
                Carp::croak("Cannot use method $method as a mutator: Set properties are not mutable");
            }
            my @members = $self->members;
            my @values = map { $_->$method } @members;
            return @values if wantarray;
            return if not defined wantarray;
            Carp::confess("Multiple matches for $class method '$method' called in scalar context.  The set has ".scalar(@values)." values to return") if @values > 1 and not wantarray;
            return $values[0];
        }; 

    }
    else {
        # a possible aggregation function
        # see if the method ___aggregate__ uses exists, and if so, delegate to __aggregate__
        # TODO: delegate these to aggregation function modules instead of having them in this module
        my $aggregator = '__aggregate_' . $method . '__';
        if ($self->can($aggregator)) {
            return sub {
                my $self = shift;
                my $f = $method;
                my @aggr_properties = @_;
                if (@aggr_properties) {
                    $f .= '(' . join(',',@aggr_properties) . ')';
                }
                return $self->__aggregate__({ f => $f, properties => \@aggr_properties });
            };
        }
        
        # set relaying with $s->foo_set->bar_set->baz_set;
        if (my ($property_name) = ($method =~ /^(.*)_set$/)) {
            return sub {
                shift->__related_set__($property_name, @_)
            }
        }
    }
    return;
}

1;

