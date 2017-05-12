package UR::Context;

use strict;
use warnings;
use Sub::Name;
use Scalar::Util;

require UR;
our $VERSION = "0.46"; # UR $VERSION;

use UR::Context::ImportIterator;
use UR::Context::ObjectFabricator;
use UR::Context::LoadingIterator;

UR::Object::Type->define(
    class_name => 'UR::Context',    
    is_abstract => 1,
    has => [
        parent  => { is => 'UR::Context', id_by => 'parent_id', is_optional => 1 },
        query_underlying_context => { is => 'Boolean',
                                      is_optional => 1,
                                      default_value => undef,
                                      doc => 'Flag indicating whether the context must (1), must not (0) or may (undef) query underlying contexts when handling a query'  },
    ],
    valid_signals => [qw(precommit sync_databases commit prerollback rollback)],
    doc => <<EOS
The environment in which all data examination and change occurs in UR.  The current context represents the current 
state of everything, and acts as a manager/intermediary between the current application and underlying database(s).
This is responsible for mapping object requests to database requests, managing caching, transaction
consistency, locking, etc. by delegating to the correct components to handle these tasks.
EOS
);

our @CARP_NOT = qw( UR::Object::Iterator Class::AutoloadCAN );

# These references all point to internal structures of the current process context.
# They are created here for boostrapping purposes, because they must exist before the object itself does.
our $all_objects_loaded ||= {};               # Master index of all tracked objects by class and then id.
our $all_change_subscriptions ||= {};         # Index of other properties by class, property_name, and then value.
our $all_objects_are_loaded ||= {};           # Track when a class informs us that all objects which exist are loaded.
our $all_params_loaded ||= {};                # Track parameters used to load by template_id then by rule_id

# These items are used by prune_object_cache() to control the cache size
our $all_objects_cache_size ||= 0;            # count of the unloadable objects we've loaded from data sources
our $cache_last_prune_serial ||= 0;           # serial number the last time we pruned objects
our $cache_size_highwater;                    # high water mark for cache size.  Start pruning when $all_objects_cache_size goes over
our $cache_size_lowwater;                     # low water mark for cache size
our $GET_COUNTER = 1;                         # This is where the serial number for the __get_serial key comes from
our $light_cache = 0;                         # whether refs in all_objects_loaded should be weak

# For bootstrapping.
$UR::Context::current = __PACKAGE__;

# called by UR.pm during bootstraping
our $initialized = 0;
sub _initialize_for_current_process {
    my $class = shift;
    if ($initialized) {
        die "Attempt to re-initialize the current process?";
    }

    my $root_id = $ENV{UR_CONTEXT_ROOT} ||= 'UR::Context::DefaultRoot';
    $UR::Context::root = UR::Context::Root->get($root_id);
    unless ($UR::Context::root) {
        die "Failed to find root context object '$root_id':!?  Odd value in environment variable UR_CONTEXT_ROOT?";
    }

    if (my $base_id = $ENV{UR_CONTEXT_BASE}) {
        $UR::Context::base = UR::Context::Process->get($base_id);
        unless ($UR::Context::base) {
            die "Failed to find base context object '$base_id':!?  Odd value in environment variable UR_CONTEXT_BASE?";
        }
    } 
    else {
        $UR::Context::base = $UR::Context::root;
    }

    $UR::Context::process = UR::Context::Process->_create_for_current_process(parent_id => $UR::Context::base->id);

    if (exists $ENV{'UR_CONTEXT_CACHE_SIZE_LOWWATER'} || exists $ENV{'UR_CONTEXT_CACHE_SIZE_HIGHWATER'}) {
        $cache_size_highwater = $ENV{'UR_CONTEXT_CACHE_SIZE_HIGHWATER'} || 0;
        $cache_size_lowwater = $ENV{'UR_CONTEXT_CACHE_SIZE_LOWWATER'} || 0;
        manage_objects_may_go_out_of_scope();
    }


    # This changes when we initiate in-memory transactions on-top of the basic, heavier weight one for the process.
    $UR::Context::current = $UR::Context::process;

    if (exists $ENV{'UR_CONTEXT_MONITOR_QUERY'}) {
        $UR::Context::current->monitor_query($ENV{'UR_CONTEXT_MONITOR_QUERY'});
    }

    $initialized = 1;
    return $UR::Context::current;
}

# whether some UR objects might go out of scope, for example if pruning is on,
# light cache is on, or an AutoUnloadPool is alive
my $objects_may_go_out_of_scope = 0;
sub objects_may_go_out_of_scope {
    if (@_) {
        $objects_may_go_out_of_scope = shift;
    }
    return $objects_may_go_out_of_scope;
}

sub manage_objects_may_go_out_of_scope {
    if ((defined($cache_size_highwater) and $cache_size_highwater > 0)
        or
        $light_cache
        or
        UR::Context::AutoUnloadPool->_pool_count
    ) {
        objects_may_go_out_of_scope(1);
    } else {
        objects_may_go_out_of_scope(0);
    }
}


# the current context is either the process context, or the current transaction on-top of it
*get_current = \&current;
sub current {
    return $UR::Context::current;
}

sub process {
    return $UR::Context::process;
}

sub date_template {
    return q|%Y-%m-%d %H:%M:%S|;
}

sub now {
    return Date::Format::time2str(date_template(), time());
}

my $master_monitor_query = 0;
sub monitor_query {
    return if $UR::Object::Type::bootstrapping;
    my $self = shift;
    $self = $UR::Context::current unless (ref $self);

    if (@_) {
        if (ref $self) {
            $self->{'monitor_query'} = shift;
        } else {
            $master_monitor_query = shift;
        }

    }
    return ref($self) ? $self->{'monitor_query'} : $master_monitor_query;
}

my %_query_log_times;
my $query_logging_fh = IO::Handle->new();
$query_logging_fh->fdopen(fileno(STDERR), 'w');
$query_logging_fh->autoflush(1);
sub query_logging_fh {
    $query_logging_fh = $_[1] if @_ > 1;
    return $query_logging_fh;
}

sub _log_query_for_rule {
    return if $UR::Object::Type::bootstrapping;
    my $self = shift;
    my($subject_class,$rule,$message) = @_;

    my $monitor_level;
    return unless ($monitor_level = $self->monitor_query);
    return if (substr($subject_class, 0,4) eq 'UR::' and $monitor_level < 2);   # Don't log queries for internal classes

    my $elapsed_time = 0;
    if (defined($rule)) {
        my $time_now = Time::HiRes::time();
        if (! exists $_query_log_times{$rule->id}) {
            $_query_log_times{$rule->id} = $time_now;
        } else {
            $elapsed_time = $time_now - $_query_log_times{$rule->id};
        }
    }

    if ($elapsed_time) {
        $message .= sprintf("  Elapsed %.4f s", $elapsed_time);
    }
    $query_logging_fh->print($message."\n");
}

sub _log_done_elapsed_time_for_rule {
    my($self, $rule) = @_;

    delete $_query_log_times{$rule->id};
}


sub resolve_data_sources_for_class_meta_and_rule {
    my $self = shift;
    my $class_meta = shift;
    my $boolexpr = shift;  ## ignored in the default case    

    my $class_name = $class_meta->class_name;

    # These are some hard-coded cases for splitting up class-classes
    # and data dictionary entities into namespace-specific meta DBs.
    # Maybe there's some more generic way to move this somewhere else

    # FIXME This part is commented out for the moment.  When class info is in the 
    # Meta DBs, then try getting this to work
    #if ($class_name eq 'UR::Object::Type') {
    #    my %params = $boolexpr->legacy_params_hash;
    #    my($namespace) = ($params->{'class_name'} =~ m/^(\w+?)::/);
    #    $namespace ||= $params->{'class_name'};  # In case the class name is just the namespace
    #    
    #    return $namespace . '::DataSource::Meta';
    #}

    my $data_source;

    # For data dictionary items
    # When the FileMux datasource is more generalized and works for
    # any kind of underlying datasource, this code can move from here 
    # and into the base class for Meta datasources
    if ($class_name->isa('UR::DataSource::RDBMS::Entity')) {
        my $params = $boolexpr->legacy_params_hash;
        my $namespace;
        if ($params->{'namespace'}) {
            $namespace = $params->{'namespace'};
            $data_source = $params->{'namespace'} . '::DataSource::Meta';

        } elsif ($params->{'data_source'} &&
                 ! ref($params->{'data_source'}) &&
                 $params->{'data_source'}->can('get_namespace')) {

            $namespace = $params->{'data_source'}->get_namespace;
            $data_source = $namespace . '::DataSource::Meta';

        } elsif ($params->{'data_source'} &&
                 ref($params->{'data_source'}) eq 'ARRAY') {
            my %namespaces = map { $_->get_namespace => 1 } @{$params->{'data_source'}};
            unless (scalar(keys %namespaces) == 1) {
                Carp::confess("get() across multiple namespaces is not supported");
            }
            $namespace = $params->{'data_source'}->[0]->get_namespace;
            $data_source = $namespace . '::DataSource::Meta';
        } else {
            Carp::confess("Required parameter (namespace or data_source_id) missing");
            #$data_source = 'UR::DataSource::Meta';
        }

        if (my $exists = UR::Object::Type->get($data_source)) {
            # switch the terminology above to stop using $data_source for the class name
            # now it's the object..
            $data_source = $data_source->get();
        }
        else {
            $self->warning_message("no data source $data_source: generating for $namespace...");
            UR::DataSource::Meta->generate_for_namespace($namespace);
            $data_source = $data_source->get();
        }

        unless ($data_source) {
            Carp::confess "Failed to find or generate a data source for meta data for namespace $namespace!";
        }

    } else {
        $data_source = $class_meta->data_source;
    }

    if ($data_source) {
        $data_source = $data_source->resolve_data_sources_for_rule($boolexpr);
    }
    return $data_source;
}


# this is used to determine which data source an object should be saved-to

sub resolve_data_source_for_object {
    my $self = shift;
    my $object = shift;
    my $class_meta = $object->__meta__;
    my $class_name = $class_meta->class_name;
    
    if ($class_name->isa('UR::DataSource::RDBMS::Entity') || $class_name->isa('UR::DataSource::RDBMS::Entity::Ghost')) {
        my $data_source = $object->data_source;
        my($namespace) = ($data_source =~ m/(^\w+?)::DataSource/);
        unless ($namespace) {
            Carp::croak("Can't resolve data source for object of type $class_name: The object's namespace could not be inferred from its data_source $data_source");
        }
        my $ds_name = $namespace . '::DataSource::Meta';
        return $ds_name->get();
    }

    # Default behavior
    my $ds = $class_meta->data_source;
    return $ds;
}

# this turns on and off light caching (weak refs)

sub _light_cache {
    if (@_ > 1) {
        $light_cache = $_[1];
        manage_objects_may_go_out_of_scope();
    }
    return $light_cache;
}


# Given a rule, and a property name not mentioned in the rule,
# can we infer the value of that property from what actually is in the rule?

sub infer_property_value_from_rule {
    my($self,$wanted_property_name,$rule) = @_;

    # First, the easy case...  The property is directly mentioned in the rule
    if ($rule->specifies_value_for($wanted_property_name)) {
        return $rule->value_for($wanted_property_name);
    }

    my $subject_class_name = $rule->subject_class_name;
    my $subject_class_meta = UR::Object::Type->get($subject_class_name);
    my $wanted_property_meta = $subject_class_meta->property_meta_for_name($wanted_property_name);
    unless ($wanted_property_meta) {
        $self->error_message("Class $subject_class_name has no property named $wanted_property_name");
        return;
    }

    if ($wanted_property_meta->is_delegated) {
        $self->context_return($self->_infer_delegated_property_from_rule($wanted_property_name,$rule));
    } else {
        $self->context_return($self->_infer_direct_property_from_rule($wanted_property_name,$rule));
    }
}

# These are things that are changes to the program state, but not changes to the object instance
# so they shouldn't be counted in the object's change_count
my %changes_not_counted = map { $_ => 1 } qw(load define unload query connect);
sub add_change_to_transaction_log {
    my ($self,$subject, $property, @data) = @_;

    my ($class,$id);
    if (ref($subject)) {
        $class = ref($subject);
        $id = $subject->id;
        unless ($changes_not_counted{$property} ) {
            $subject->{_change_count}++;
            #print "changing $subject $property @data\n";    
        }
    }
    else {
        $class = $subject;
        $subject = undef;
        $id = undef;
    }

    if ($UR::Context::Transaction::log_all_changes) {
        # eventually all calls to __signal_change__ will go directly here
        UR::Context::Transaction->log_change($subject, $class, $id, $property, @data);
    }

    if (my $index_list = $UR::Object::Index::all_by_class_name_and_property_name{$class}{$property}) {
        unless ($property eq 'create' or $property eq 'load' or $property eq 'define') {
            for my $index (@$index_list) {
                $index->_remove_object(
                    $subject, 
                    { $property => $data[0] }
                ) 
            }
        }
        
        unless ($property eq 'delete' or $property eq 'unload') {
            for my $index (@$index_list) {
                $index->_add_object($subject)
            }
        }
    }
}

our $sig_depth = 0;
my %subscription_classes;
sub send_notification_to_observers {
    my ($self,$subject, $property, @data) = @_;

    my ($class,$id);
    if (ref($subject)) {
        $class = ref($subject);
        $id = $subject->id;
    } else {
        $class = $subject;
    }

    my $check_classes = $subscription_classes{$class};
    unless ($check_classes) {
        $subscription_classes{$class} = $check_classes  = [
            $class
            ? (
                $class,
                (grep { $_->isa("UR::Object") } $class->inheritance),
                ''
            )
            : ('')
        ];
    }
    my @check_properties    = ($property    ? ($property, '')    : ('') );
    my @check_ids           = (defined($id) ? ($id, '')          : ('') );

    my @matches =
        map { @$_ }
        grep { defined $_ } map { defined($id) ? @$_{@check_ids} : values(%$_) }
        grep { defined $_ } map { @$_{@check_properties} }
        grep { defined $_ } @$UR::Context::all_change_subscriptions{@$check_classes};

    return unless @matches;

    $sig_depth++;
    if (@matches > 1) {
        no warnings;
        # sort by priority
        @matches = sort { $a->[2] <=> $b->[2] } @matches;
    };
    
    foreach my $callback_info (@matches) {
        my ($callback, $note, undef, $id, $once) = @$callback_info;
        UR::Observer->get($id)->delete() if $once;
        $callback->($subject, $property, @data);
    }

    $sig_depth--;

    return scalar(@matches);
}


sub query {
    my $self = shift;

    # Fast optimization for the default case.
    if ( ( !ref($self) or ! $self->query_underlying_context) 
         and ! Scalar::Util::blessed($_[1]) # This happens when query() is called with a class name and boolexpr
    ) {
        no warnings;
        if (exists $UR::Context::all_objects_loaded->{$_[0]}) {
            my $is_monitor_query = $self->monitor_query;
            if (defined(my $obj = $UR::Context::all_objects_loaded->{$_[0]}->{$_[1]})) {
                # Matched the class and ID directly - pull it right out of the cache
                if ($is_monitor_query) {
                    $self->_log_query_for_rule($_[0], undef, Carp::shortmess("QUERY: class $_[0] by ID $_[1]"));
                    $self->_log_query_for_rule($_[0], undef, "QUERY: matched 1 cached object\nQUERY: returning 1 object\n\n");
                }

                $obj->{'__get_serial'} = $UR::Context::GET_COUNTER++;
                return $obj;

            } elsif (my $subclasses = $UR::Object::Type::_init_subclasses_loaded{$_[0]}) {
                # Check subclasses of the requested class, along with the ID
                # yes, it only goes one level deep.  This should catch enough cases to be worth it.
                # Deeper searches will be covered by get_objects_for_class_and_rule()
                foreach my $subclass (@$subclasses) {
                    if (exists $UR::Context::all_objects_loaded->{$subclass} and
                        my $obj = $UR::Context::all_objects_loaded->{$subclass}->{$_[1]}
                    ) {
                        if ($is_monitor_query) {
                            $self->_log_query_for_rule($_[0], undef, Carp::shortmess("QUERY: class $_[0] by ID $_[1]"));
                            $self->_log_query_for_rule($_[0], undef, "QUERY: matched 1 cached object in subclass $subclass\nQUERY: returning 1 object\n\n");
                        }

                        $obj->{'__get_serial'} = $UR::Context::GET_COUNTER++;
                        return $obj;
                    }
                }
            }
        }
    };

    # Normal logic for finding objects smartly is below.

    my $class = shift;

    # Handle the case in which this is called as an object method.
    # Functionality is completely different.

    if(ref($class)) {
        my @rvals;
        foreach my $prop (@_) {
            push(@rvals, $class->$prop());
        }

        if(wantarray) {
            return @rvals;
        }
        else {
            return \@rvals;
        }
    }
    
    my ($rule, @extra) = UR::BoolExpr->resolve($class,@_);        
    
    if (@extra) {
        # remove this and have the developer go to the datasource 
        if (scalar @extra == 2 and ($extra[0] eq "sql" or $extra[0] eq 'sql in')) {
            return $UR::Context::current->_get_objects_for_class_and_sql($class,$extra[1]);
        }
        
        # keep this part: let the sub-class handle special params if it can
        return $class->get_with_special_parameters($rule, @extra);
    }

    # This is here for bootstrapping reasons: we must be able to load class singletons
    # in order to have metadata for regular loading....
    # UR::DataSource::QueryPlan isa UR::Value (which has custom loading logic), but we need to be able to generate
    # a QueryPlan independant of the normal loading process, otherwise there'd be endless recursion (Can't generate a QueryPlan
    # for a QueryPlan without generating a QueryPlan first....)
    if (!$rule->has_meta_options and ($class->isa("UR::Object::Type") or $class->isa("UR::Singleton") or $class->isa("UR::DataSource::QueryPlan"))) {
        my $normalized_rule = $rule->normalize;
        my @objects = $class->_load($normalized_rule);
        
        return unless defined wantarray;
        return @objects if wantarray;
        
        if ( @objects > 1 and defined(wantarray)) {
            Carp::croak("Multiple matches for $class query called in scalar context. $rule matches " . scalar(@objects). " objects");
        }
        
        return $objects[0];
    }

    return $UR::Context::current->get_objects_for_class_and_rule($class, $rule);
}

sub _resolve_id_for_class_and_rule {
    my ($self,$class_meta,$rule) = @_;
   
    my $class = $class_meta->class_name;
    my $id;
    my @id_property_names = $class_meta->id_property_names
        or Carp::confess( # Bad should be at least one
        "No id property names for class ($class).  This should not have happened."
    );

    if ( @id_property_names == 1 ) { # only 1 - try to auto generate
        $id = $class_meta->autogenerate_new_object_id($rule);
        unless ( defined $id ) {
            $class->error_message("Failed to auto-generate an ID for single ID property class ($class)");
            return;
        }
    }
    else { # multiple
        # Try to give a useful message by getting id prop names that are not deinfed
        my @missed_names;
        for my $name ( @id_property_names ) {
            push @missed_names, $name unless $rule->specifies_value_for($name);
        }
        if ( @missed_names ) { # Ok - prob w/ class def, list the ones we missed
            $class->error_message("Attempt to create $class with multiple ids without these properties: ".join(', ', @missed_names));
            return;
        }
        else { # Bad - something is really wrong... 
            Carp::confess("Attempt to create $class failed to resolve id from underlying id properties.");
        }
    }
    
    return $id;
}

our $construction_method = 'create';

# Pulled out the complicated code of create_entity() below that deals with
# abstract classes and subclassify_by
sub _create_entity_from_abstract_class {
    my $self = shift;

    my $class = shift;
    my $class_meta = $class->__meta__;
    my($rule, %extra) = UR::BoolExpr->resolve_normalized($class, @_);

    # If we can easily determine the correct subclass, delegate to that subclass' create()
    my $subclassify_by = $class_meta->subclassify_by();
    unless (defined $subclassify_by) {
        Carp::croak("Can't call $construction_method on abstract class $class without a subclassify_by property");
    }

    my $sub_class_name = $rule->value_for($subclassify_by);
    unless (defined $sub_class_name) {
        # The subclassification wasn't included in the rule
        my $property_meta = $class_meta->property($subclassify_by);
        unless ($property_meta) {
            Carp::croak("Abstract class $class has subclassify_by $subclassify_by, but no property exists by that name");
        }

        # There are a few different ways the property can supply a value for subclassify_by...
        # The sure-fire way to get a value is to go ahead an instantiate the object into the
        # base/abstract class, and then we can just call the property as a method.  There's
        # a lot of overhead in that, so first we'll try some of the easier, common-case ways

        if ($property_meta->default_value) {
            # The property has a default value
            $sub_class_name = $property_meta->default_value();

        } elsif ($property_meta->is_calculated and ref($property_meta->calculate) eq 'CODE') {
            # It's calculated via a coderef

            my $calculate_from = $property_meta->calculate_from;
            my @calculate_params;
            foreach my $prop_name ( @$calculate_from ) {
                # The things in calculate_from must appear in the rule
                unless ($rule->specifies_value_for($prop_name)) {
                    Carp::croak("Class $class subclassify_by calculation property '$subclassify_by' "
                                . "requires '$prop_name' in the $construction_method() params\n"
                                . "Params were: " . UR::Util->display_string_for_params_list($rule->params_list));
                }
                push @calculate_params, $rule->value_for($prop_name);
            }

            my $sub = $property_meta->calculate;
            unless ($sub) {
                Carp::croak("Can't use undefined value as subroutine reference while resolving "
                            . "value for class $class calculated property '$subclassify_by'");
            }
            $sub_class_name = $sub->(@calculate_params);

        } elsif ($property_meta->is_calculated and !ref($property_meta->calculate)) {
            # It's calculated via a string that's eval-ed
            Carp::croak("Can't use a non-coderef as a calculation for class $class subclassify_by");

        } elsif ($property_meta->is_delegated) {
            #Carp::croak("Delegated properties are not supported for subclassifying $class with property '$subclassify_by'");
            my @values = $self->infer_property_value_from_rule($subclassify_by, $rule);
            if (! @values ) {
                Carp::croak("Invalid parameters for $class->$construction_method(): "
                            . "Couldn't infer a value for indirect property '$subclassify_by' via rule $rule");
            } elsif (@values > 1) {
                Carp::croak("Invalid parameters for $class->$construction_method(): "
                            . "Infering a value for property '$subclassify_by' via rule $rule returned multiple values: "
                            . join(', ', @values));
            } else {
                $sub_class_name = $values[0];
            }

        } else {
            Carp::croak("Can't use undefined value as a subclass name for $class property '$subclassify_by'");
        }
    }

    unless (defined $sub_class_name) {
        Carp::croak("Invalid parameters for $class->$construction_method(): "
                    . "Can't use undefined value as a subclass name for param '$subclassify_by'");
    }
    if ($sub_class_name eq $class) {
        Carp::croak("Invalid parameters for $class->$construction_method(): "
                    . "Value for $subclassify_by cannot be the same as the original class");
    }
    unless ($sub_class_name->isa($class)) {
        Carp::croak("Invalid parameters for $class->$construction_method(): "
                    . "Class $sub_class_name is not a subclass of $class");
    }
    return $sub_class_name->$construction_method(@_); 
}

my %memos;
my %memos2;
sub create_entity {
    my $self = shift;

    my $class = shift;

    my $memo = $memos{$class};
    unless ($memo) {
        # we only want to grab the data necessary for object construction once
        # this occurs the first time a new object is created for a given class
        
        my $class_meta = $class->__meta__;
        my @inheritance = reverse ($class_meta, $class_meta->ancestry_class_metas);

        # %property_objects maps property names to UR::Object::Property objects
        # by going through the reversed list of UR::Object::Type objects below
        # We set up this hash to have the correct property objects for each property
        # name.  This is important in the case of property name overlap via
        # inheritance.  The property object used should be the one "closest"
        # to the class.  In other words, a property directly on the class gets
        # used instead of an inherited one.
        my %property_objects;
        my %direct_properties;
        my %indirect_properties; 
        my %set_properties;
        my %default_values;
        my %default_value_requires_query;
        my %default_value_requires_call;
        my %immutable_properties;
        my @deep_copy_default_values;

        for my $co ( @inheritance ) {
            # Reverse map the ID into property values.
            # This has to occur for all subclasses which represent table rows.
    
            # deal with %property_objects
            my @property_objects = $co->direct_property_metas;
            my @property_names = map { $_->property_name } @property_objects;
            @property_objects{@property_names} = @property_objects;            
    
            foreach my $prop ( @property_objects ) {
                my $name = $prop->property_name;
   
                unless (defined $name) {
                    Carp::confess("no name on property for class " . $co->class_name . "?\n" . Data::Dumper::Dumper($prop));
                }

                my $default_value = $prop->default_value;
                if (defined $default_value) {
                    if ($prop->data_type and $prop->_data_type_as_class_name eq $prop->data_type and $prop->_data_type_as_class_name->can("get")) {
                        # an ID or other query params in hash/array form return an object or objects
                        $default_value_requires_query{$name} = $default_value;
                    }
                    elsif (ref($default_value)) {
                        #warn (
                        #    "a reference value $default_value is used as a default on "
                        #    . $co->class_name 
                        #    . " forcing a copy during construction "
                        #    . " of $class $name..."
                        #);
                        push @deep_copy_default_values, $name;
                    }
                    $default_values{$name} = $default_value; 
                }

                if ($prop->calculated_default) {
                    $default_value_requires_call{$name} = $prop->calculated_default;
                }
    
                if ($prop->is_many) {
                    $set_properties{$name} = $prop;
                }
                elsif ($prop->is_delegated) {
                    $indirect_properties{$name} = $prop;
                }
                else {
                    $direct_properties{$name} = $prop;
                }
                
                unless ($prop->is_mutable) {
                    $immutable_properties{$name} = 1;
                }
            }
         }
    
        my @indirect_property_names = keys %indirect_properties;
        my @direct_property_names = keys %direct_properties;

        my @subclassify_by_methods;
        foreach my $co ( @inheritance ) {
            # If this class inherits from something with subclassify_by, make sure the param
            # actually matches.  If it's not supplied, then set it to the same as the class create()
            # is being called on
            if ( $class ne $co->class_name
                     and $co->is_abstract
                     and my $method = $co->subclassify_by
               ) {
                push @subclassify_by_methods, $method;
            }
        }

        $memos{$class} = $memo = [
            $class_meta,
            $class_meta->first_sub_classification_method_name,
            $class_meta->is_abstract,
            \@inheritance,
            \%property_objects,
            \%direct_properties,
            \%indirect_properties, 
            \%set_properties,
            \%immutable_properties,
            \@subclassify_by_methods,
            \%default_values,
            (@deep_copy_default_values ? \@deep_copy_default_values : undef),
            \%default_value_requires_query,
            \%default_value_requires_call,
        ];
    }
    
    my (
        $class_meta,
        $first_sub_classification_method_name, 
        $is_abstract,
        $inheritance,
        $property_objects,
        $direct_properties,
        $indirect_properties,
        $set_properties,
        $immutable_properties,
        $subclassify_by_methods,
        $initial_default_values,
        $deep_copy_default_values,
        $default_value_requires_query,
        $initial_default_value_requires_call,
    ) = @$memo;

    # The old way of automagic subclassing...
    # The class specifies that we should call a class method (sub_classification_method_name)
    # to determine the correct subclass
    if ($first_sub_classification_method_name) {
        my $sub_class_name = $class->$first_sub_classification_method_name(@_);
        if (defined($sub_class_name) and ($sub_class_name ne $class)) {
            # delegate to the sub-class to create the object
            unless ($sub_class_name->can($construction_method)) {
                Carp::croak("Can't locate object method '$construction_method' via package '$sub_class_name' "
                            . "while resolving proper subclass for $class during $construction_method");

            }
            return $sub_class_name->$construction_method(@_);
        }
        # fall through if the class names match
    }

    if ($is_abstract) {
        # The new way of automagic subclassing.  The class specifies a property (subclassify_by)
        # that holds/returns the correct subclass name
        return $self->_create_entity_from_abstract_class($class, @_);
    }

    # normal case: make a rule out of the passed-in params
    # rather than normalizing the rule, we just do the extension part which is fast
    my $rule = UR::BoolExpr->resolve($class, @_); 
    my $template = $rule->template;

    my $params = { $rule->_params_list, $template->extend_params_list_for_values(@{$rule->{values}}) };
    if (my $a = $template->{_ambiguous_keys}) {
        my $p = $template->{_ambiguous_property_names};
        @$params{@$p} = delete @$params{@$a};
    }

    my $id = $params->{id};
    unless (defined $id) {
        $id = $self->_resolve_id_for_class_and_rule($class_meta,$rule);
        unless ($id) {
            return;
        }
        $rule = UR::BoolExpr->resolve_normalized($class, %$params, id => $id);
        $params = { $rule->params_list }; ;
    }

    my %default_value_requires_call = %$initial_default_value_requires_call;
    delete @default_value_requires_call{ keys %$params };

    # handle postprocessing default values
    
    my %default_values = %$initial_default_values;
    
    for my $name (keys %$default_value_requires_query) {
        my @id_by;
        if (my $id_by = $property_objects->{$name}->id_by) {
            @id_by = (ref($id_by) ? @$id_by : ($id_by));
        }

        if ($params->{$name}) {
            delete $default_values{$name};
        }
        elsif (@$params{@id_by}) {
            # some or all of the id is present
            # don't fall back to the default
            for my $id_by (@id_by) {
                delete $default_values{$id_by} if exists $params->{$id_by};
            }
            delete $default_values{$name};
        }
        else {
            my $query = $default_value_requires_query->{$name};
            my @query;
            if (ref($query) eq 'HASH') {
                # queries come in as a hash 
                @query = %$query;
            }
            else {
                # an ID or a boolean expression
                @query = ($query);
            }
            my $prop = $property_objects->{$name};
            my $class = $prop->_data_type_as_class_name;
            eval {
                if ($prop->is_many) {
                    $default_values{$name} = [ $class->get(@query) ];
                }
                else {
                    $default_values{$name} = $class->get(@query);
                }
            };
            if ($@) {
                warn "error setting " . $prop->class_name . " " . $prop->property_name . " to default_value from query $query for type $class!";
            };
        }
    }

    if ($deep_copy_default_values) {
        for my $name (@$deep_copy_default_values) {
            if ($params->{$name}) {
                delete $default_values{$name};
            }
            else {
                $default_values{$name} = UR::Util::deep_copy($default_values{$name});
            }
        }
    }

    # @extra is extra values gotten by inheritance
    my @extra;

    my $indirect_values = {};
    for my $property_name (keys %$indirect_properties) {
        # pull indirect values out of the constructor hash
        # so we can apply them separately after making the object
        if ( exists $params->{ $property_name } ) {
            $indirect_values->{ $property_name } = delete $params->{ $property_name };
            delete $default_values{$property_name};
        }
        elsif (exists $default_values{$property_name}) {
            $indirect_values->{ $property_name } = delete $default_values{$property_name};
        }
    }

    # if the indirect property is immutable, but it is via something which is
    # mutable, we use those values to get or create the bridge.
    my %indirect_immutable_properties_via;
    for my $property_name (keys %$indirect_values) {
        if ($immutable_properties->{$property_name}) {
            my $meta = $indirect_properties->{$property_name};
            next unless $meta; # not indirect
            my $via = $meta->via;
            next unless $via;  # not a via/to (id_by or reverse_id_by)
            $indirect_immutable_properties_via{$via}{$property_name} = delete $indirect_values->{$property_name};
        }
    }

    for my $via (keys %indirect_immutable_properties_via) {
        my $via_property_meta = $class_meta->property_meta_for_name($via);
        my ($source_indirect_property, $source_value) = each %{$indirect_immutable_properties_via{$via}};  # There'll only ever be one key/value

        unless ($via_property_meta) {
            Carp::croak("No metadata for class $class property $via while resolving indirect value for property $source_indirect_property");
        }

        my $indirect_property_meta = $class_meta->property_meta_for_name($source_indirect_property);
        unless ($indirect_property_meta) {
            Carp::croak("No metadata for class $class property $source_indirect_property while resolving indirect value for property $source_indirect_property");
        }

        unless ($indirect_property_meta->to) {
            # We're probably dealing with a subclassify_by property where the subclass has
            # implicitly overridden the indirect property in the parent class with a constant-value
            # property in the subclass.  Try asking the parent class about a property of the same name
            ($indirect_property_meta) = grep { $_->property_name eq $indirect_property_meta->property_name } $class_meta->ancestry_property_metas();
            unless ($indirect_property_meta and $indirect_property_meta->to) {
                Carp::croak("Can't resolve indirect relationship for possibly overridden property '$source_indirect_property'"
                            . " in class $class.  Parent classes have no property named '$source_indirect_property'");
            }
        }
        my $foreign_class = $via_property_meta->data_type;
        my $foreign_property = $indirect_property_meta->to;
        my $foreign_object = $foreign_class->get($foreign_property => $source_value);
        unless ($foreign_object) {
            # This will trigger recursion back here (into create_entity() ) if this property is multiply
            # indirect, such as through a bridge object
            $foreign_object = $foreign_class->create($foreign_property => $source_value);
            unless ($foreign_object) {
                Carp::croak("Can't create object of class $foreign_class with params ($foreign_property => '$source_value')"
                            . " while resolving indirect value for class $class property $source_indirect_property");
            }
        }

        my @joins = $indirect_property_meta->_resolve_join_chain();
        my %local_properties_to_set;
        foreach my $join ( @joins ) {
            if ($join->{foreign_class}->isa("UR::Value")) {
                # this final "join" is to the set of values available to the raw primitive type
                # ...not what we really mean by delegation
                next;
            }
            for (my $i = 0; $i < @{$join->{'source_property_names'}}; $i++) {
                my $source_property_name = $join->{'source_property_names'}->[$i];
                next unless (exists $direct_properties->{$source_property_name});
                my $foreign_property_name = $join->{'foreign_property_names'}->[$i];
                my $value = $foreign_object->$foreign_property_name;

                if ($rule->specifies_value_for($source_property_name)
                        and
                        $rule->value_for($source_property_name) ne $value)
                {
                    Carp::croak("Invalid parameters for $class->$construction_method(): "
                                . "Conflicting values for property '$source_property_name'.  $construction_method rule "
                                . "specifies value '" . $rule->value_for($source_property_name) . "' but "
                                . "indirect immutable property '$source_indirect_property' with value "
                                . "$source_value requires it to be '$value'");
                }

                $local_properties_to_set{$source_property_name} = $value;
            }
        }
        # transfer the values we resolved back into %$params
        my @param_keys = keys %local_properties_to_set;
        @$params{@param_keys} = @local_properties_to_set{@param_keys};
    }

    my $set_values = {};
    for my $property_name (keys %$set_properties) {
        if (exists $params->{ $property_name }) {
            delete $default_values{ $property_name };
            $set_values->{ $property_name } = delete $params->{ $property_name };
        }
    }

    my $entity = $self->_construct_object($class, %default_values, %$params, @extra);
    return unless defined $entity;
    $self->add_change_to_transaction_log($entity, $construction_method);
    $self->add_change_to_transaction_log($entity, 'load') if $construction_method eq '__define__';

    for my $property_name ( keys %default_value_requires_call ) {
        my $method = $default_value_requires_call{$property_name};
        my $value = $method->($entity);
        $entity->$property_name($value);
    }

    # If a property is calculated + immutable, and it wasn't supplied in the params,
    # that means we need to run the calculation once and store the value in the
    # object as a read-only attribute
    foreach my $property_name ( keys %$immutable_properties )  {
        my $property_meta = $property_objects->{$property_name};
        if (!exists($params->{$property_name}) and $property_meta and $property_meta->is_calculated) {
            my $value = $entity->$property_name;
            $params->{$property_name} = $value;
        }
    }

    for my $subclassify_by (@$subclassify_by_methods) {
        my $param_value = $rule->value_for($subclassify_by);
        $param_value = eval { $entity->$subclassify_by } unless (defined $param_value);
        $param_value = $default_values{$subclassify_by} unless (defined $param_value);
        
        if (! defined $param_value) {
            
            # This should have been taken care of by the time we got here...
            Carp::croak("Invalid parameters for $class->$construction_method(): " .
                        "Can't use an undefined value as a subclass name for param '$subclassify_by'");

        } elsif ($param_value ne $class) {
            Carp::croak("Invalid parameters for $class->$construction_method(): " .
                        "Value for subclassifying param '$subclassify_by' " .
                        "($param_value) does not match the class it was called on ($class)");
        }
    }

    # add items for any multi properties
    if (%$set_values) {
        for my $property_name (keys %$set_values) {
            my $meta = $set_properties->{$property_name};
            my $singular_name = $meta->singular_name;
            my $adder = 'add_' . $singular_name;
            my $value = $set_values->{$property_name};
            unless (ref($value) eq 'ARRAY') {
                $value = [$value];
            }
            for my $item (@$value) {
                if (ref($item) eq 'ARRAY') {
                    $entity->$adder(@$item);
                }
                elsif (ref($item) eq 'HASH') {
                    $entity->$adder(%$item);
                }
                else {
                    $entity->$adder($item);
                }
            }
        }
    }    

    # set any indirect mutable properties
    if (%$indirect_values) {
        for my $property_name (keys %$indirect_values) {
            $entity->$property_name($indirect_values->{$property_name});
        }
    }

    if (%$immutable_properties) {
        my @problems = $entity->__errors__();
        if (@problems) {
            my @errors_fatal_to_construction;
            
            my %problems_by_property_name;
            for my $problem (@problems) {
                my @problem_properties;
                for my $name ($problem->properties) {
                    if ($immutable_properties->{$name}) {
                        push @problem_properties, $name;                        
                    }
                }
                if (@problem_properties) {
                    push @errors_fatal_to_construction, join(" and ", @problem_properties) . ': ' . $problem->desc;
                }
            }
            
            if (@errors_fatal_to_construction) {
                my $msg = 'Failed to $construction_method ' . $class . ' with invalid immutable properties:'
                    . join("\n", @errors_fatal_to_construction);
            }
        }
    }

    $entity->__signal_observers__($construction_method);
    $entity->__signal_observers__('load') if $construction_method eq '__define__';
    $entity->{'__get_serial'} = $UR::Context::GET_COUNTER++;
    $UR::Context::all_objects_cache_size++;
    return $entity;
}

sub _construct_object {
    my $self = shift;
    my $class = shift;
 
    my $params = { @_ };    

    my $id = $params->{id};
    unless (defined($id)) {
        Carp::confess(
            "No ID specified (or incomplete id params) for $class _construct_object.  Params were:\n" 
            . Data::Dumper::Dumper($params)
        );
    }

    if ($UR::Context::all_objects_loaded->{$class}->{$id}) {
        # The object exists.  This is not an exception for some reason?
        # We just return false to indicate that the object is not creatable.
        $class->error_message("An object of class $class already exists with id value '$id'");
        return;
    }

    my $object;
    if ($object = $UR::DeletedRef::all_objects_deleted->{$class}->{$id}) {
        UR::DeletedRef->resurrect($object);
        %$object = %$params;
    } else {
        $object = bless $params, $class;
    }
    
    if (my $ghost = $UR::Context::all_objects_loaded->{$class . "::Ghost"}->{$id}) {    
        # we're making something which was previously deleted and is pending save.
        # we must capture the old db_committed data to ensure eventual saving is done correctly.
        # note this object's database state in the new object so saves occurr correctly,
        # as an update instead of an insert.
        if (my $committed_data = $ghost->{db_committed}) {
            $object->{db_committed} = { %$committed_data };
        }

        if (my $unsaved_data = $ghost->{'db_saved_uncommitted'}) {
            $object->{'db_saved_uncommitted'} = { %$unsaved_data };
        }
        $ghost->__signal_change__("delete");
        $self->_abandon_object($ghost);
    }

    # put the object in the master repository of objects for the application.
    $UR::Context::all_objects_loaded->{$class}{$id} = $object;

    # If we're using a light cache, weaken the reference.
    if ($light_cache) { # and substr($class,0,5) ne 'App::') {
        Scalar::Util::weaken($UR::Context::all_objects_loaded->{$class}->{$id});
    }

    return $object;
}

sub delete_entity {
    my ($self,$entity) = @_;

    if (ref($entity)) {
        # Delete the specified object.
        if ($entity->{db_committed} || $entity->{db_saved_uncommitted}) {

            # gather params for the ghost object
            my $do_data_source;
            my %ghost_params;
            #my @pn;
            #{ no warnings 'syntax';
            #   @pn = grep { $_ ne 'data_source_id' || ($do_data_source=1 and 0) } # yes this really is '=' and not '=='
            #         grep { exists $entity->{$_} }
            #         $entity->__meta__->all_property_names;
            #}
            my(@prop_names, @many_prop_names);
            foreach my $prop_name ( $entity->__meta__->all_property_names) {
                next unless exists $entity->{$prop_name};  # skip non-directly-stored properties
                if ($prop_name eq 'data_source_id') {
                    $do_data_source = 1;
                    next;
                }
                if (ref($entity->{$prop_name}) eq 'ARRAY') {
                    push @many_prop_names, $prop_name;
                } else {
                    push @prop_names, $prop_name;
                }
            }
 
            
            # we're not really allowed to interrogate the data_source property directly
            @ghost_params{@prop_names} = $entity->get(@prop_names);  # hrm doesn't work for is_many properties :(
            foreach my $prop_name ( @many_prop_names ) {
                my @values = $entity->get($prop_name);
                $ghost_params{$prop_name} = \@values;
            }
            if ($do_data_source) {
                $ghost_params{'data_source_id'} = $entity->{'data_source_id'};
            }    

            # create ghost object
            my $ghost = $self->_construct_object($entity->ghost_class, id => $entity->id, %ghost_params);
            unless ($ghost) {
                Carp::confess("Failed to constructe a deletion record for an unsync'd delete.");
            }
            $ghost->__signal_change__("create");

            for my $com (qw(db_committed db_saved_uncommitted)) {
                $ghost->{$com} = $entity->{$com}
                    if $entity->{$com};
            }

        }
        $entity->__signal_change__('delete');
        $self->_abandon_object($entity);
        return $entity;
    }
    else {
        Carp::confess("Can't call delete as a class method.");
    }
}

sub _abandon_object {
    my $self = shift;
    my $object = $_[0];
    my $class = $object->class;
    my $id = $object->id;

    if ($object->{'__get_serial'}) {
        # Keep a correct accounting of objects.  This one is getting deleted by a method
        # other than UR::Context::prune_object_cache
        $UR::Context::all_objects_cache_size--;
    }

    # Remove the object from the main hash.
    delete $UR::Context::all_objects_loaded->{$class}->{$id};
    delete $UR::Context::all_objects_are_loaded->{$class};

    # Remove all of the load info it is using so it'll get re-loaded if asked for later
    if ($object->{'__load'}) {
        while (my ($template_id, $rules) = each %{ $object->{'__load'}} ) {
            foreach my $rule_id ( keys %$rules ) {
                delete $UR::Context::all_params_loaded->{$template_id}->{$rule_id};

                foreach my $fabricator ( UR::Context::ObjectFabricator->all_object_fabricators ) {
                    $fabricator->delete_from_all_params_loaded($template_id, $rule_id);
                }
            }
        }
    }

    # Turn our $object reference into a UR::DeletedRef.
    # Further attempts to use it will result in readable errors.
    # The object can be resurrected.
    if ($ENV{'UR_DEBUG_OBJECT_RELEASE'}) {
        print STDERR  "MEM DELETE object $object class ",$object->class," id ",$object->id,"\n";
    }
    UR::DeletedRef->bury($object);

    return $object;
}


# This one works when the rule specifies the value of an indirect property, and we want
# the value of a direct property of the class
sub _infer_direct_property_from_rule {
    my($self,$wanted_property_name,$rule) = @_;

    my $rule_template = $rule->template;
    my @properties_in_rule = $rule_template->_property_names; # FIXME - why is this method private?
    my $subject_class_name = $rule->subject_class_name;
    my $subject_class_meta = $subject_class_name->__meta__;

    my($alternate_class,$alternate_get_property, $alternate_wanted_property);

    my @r_values; # There may be multiple properties in the rule that will get to the wanted property
    PROPERTY_IN_RULE:
    foreach my $property_name ( @properties_in_rule) {
        my $property_meta = $subject_class_meta->property_meta_for_name($property_name);
        my $final_property_meta = $property_meta->final_property_meta || $property_meta;
        $alternate_get_property = $final_property_meta->property_name;
        $alternate_class   = $final_property_meta->class_name;

        unless ($alternate_wanted_property) {
            # Either this was also a direct property of the rule, or there's no
            # obvious link between the indirect property and the wanted property.
            # the caller probably just should have done a get()
            $alternate_wanted_property = $wanted_property_name;
            $alternate_get_property = $property_name;
            $alternate_class = $subject_class_name;
        }
     
        my $value_from_rule = $rule->value_for($property_name);
        my @alternate_values;
        eval {
            # Inside an eval in case the get() throws an exception, the next 
            # property in the rule may succeed
            my @alternate_objects = $self->query($alternate_class, $alternate_get_property  => $value_from_rule );
            @alternate_values = map { $_->$alternate_wanted_property } @alternate_objects;
        };
        next unless (@alternate_values);

        push @r_values, \@alternate_values;
    }

    if (@r_values == 0) {
        # no solutions found
        return;

    } elsif (@r_values == 1) {
        # there was only one solution
        return @{$r_values[0]};

    } else {
        # multiple solutions.  Only return the intersection of them all
        # FIXME - this totally won't work for properties that return objects, listrefs or hashrefs
        # FIXME - this only works for AND rules - for now, that's all that exist
        my %intersection = map { $_ => 1 } @{ shift @r_values };
        foreach my $list ( @r_values ) {
            %intersection = map { $_ => 1 } grep { $intersection{$_} } @$list;
        }
        return keys %intersection;
    }
}


# we want the value of a delegated property, and the rule specifies
# a direct value
sub _infer_delegated_property_from_rule {
    my($self, $wanted_property_name, $rule) = @_;

    my $rule_template = $rule->template;
    my $subject_class_name = $rule->subject_class_name;
    my $subject_class_meta = $subject_class_name->__meta__;

    my $wanted_property_meta = $subject_class_meta->property_meta_for_name($wanted_property_name);
    unless ($wanted_property_meta->via) {
        Carp::croak("There is no linking meta-property (via) on property $wanted_property_name on $subject_class_name");
    }

    my $linking_property_meta = $subject_class_meta->property_meta_for_name($wanted_property_meta->via);
    my $final_property_meta = $wanted_property_meta->final_property_meta;

    if ($linking_property_meta->reverse_as) {
        eval{ $linking_property_meta->data_type->class() };  # Load the class if it isn't already loaded
        if ($linking_property_meta->data_type ne $final_property_meta->class_name) {
            Carp::croak("UR::Context::_infer_delegated_property_from_rule() doesn't handle multiple levels of indiretion yet");
        }
    }

    my @rule_translation = $linking_property_meta->get_property_name_pairs_for_join();

    my %alternate_get_params;
    foreach my $pair ( @rule_translation ) {
        my $rule_param = $pair->[0];
        next unless ($rule_template->specifies_value_for($rule_param));
        my $alternate_param = $pair->[1];

        my $value = $rule->value_for($rule_param);
        $alternate_get_params{$alternate_param} = $value;
    }

    my $alternate_class = $final_property_meta->class_name;
    my $alternate_wanted_property = $wanted_property_meta->to;
    my @alternate_values;
    eval {
        my @alternate_objects = $self->query($alternate_class, %alternate_get_params);
        @alternate_values = map { $_->$alternate_wanted_property } @alternate_objects;
    };
    return @alternate_values;
}


sub object_cache_size_highwater {
    my $self = shift;

    if (@_) {
        my $value = shift;
        $cache_size_highwater = $value;

        if (defined $value) {
            if ($cache_size_lowwater and $value <= $cache_size_lowwater) {
                Carp::confess("Can't set the highwater mark less than or equal to the lowwater mark");
                return;
            }
            $self->prune_object_cache();
        }
        manage_objects_may_go_out_of_scope();
    }
    return $cache_size_highwater;
}

sub object_cache_size_lowwater {
    my $self = shift;
    if (@_) {
        my $value = shift;
        $cache_size_lowwater = $value;

        if (defined($value) and $cache_size_highwater and $value >= $cache_size_highwater) {
            Carp::confess("Can't set the lowwater mark greater than or equal to the highwater mark");
            return;
        }
    }
    return $cache_size_lowwater;
}


sub get_data_sources_for_loaded_classes {
    my $class = shift;

    my %data_source_for_class;
    foreach my $class ( keys %$UR::Context::all_objects_loaded ) {
        next if (substr($class,0,-6) eq '::Type'); # skip class objects

        next unless exists $UR::Context::all_objects_loaded->{$class . '::Type'};
        my $class_meta = $UR::Context::all_objects_loaded->{$class . '::Type'}->{$class};
        next unless $class_meta;
        next unless ($class_meta->is_uncachable());
        $data_source_for_class{$class} = $class_meta->data_source_id;
    }

    return %data_source_for_class;
}


our $is_pruning = 0;
sub prune_object_cache {
    my $self = shift;

    return if ($is_pruning);  # Don't recurse into here

    return if (!defined($cache_size_highwater) or !defined($cache_size_lowwater));
    return unless ($all_objects_cache_size > $cache_size_highwater);

    $is_pruning = 1;
    my $t1;
    if ($ENV{'UR_DEBUG_OBJECT_RELEASE'} || $ENV{'UR_DEBUG_OBJECT_PRUNING'}) {
        $t1 = Time::HiRes::time();
        print STDERR Carp::longmess("MEM PRUNE begin at $t1 ",scalar(localtime($t1)),"\n");
    }

    my $index_id_sep = UR::Object::Index->__meta__->composite_id_separator() || "\t";

    my %data_source_for_class = $self->get_data_sources_for_loaded_classes;

    # NOTE: This pokes right into the object cache and futzes with Index IDs directly.
    # We can't get the Index objects though get() because we'd recurse right back into here
    my %indexes_by_class;
    foreach my $idx_id ( keys %{$UR::Context::all_objects_loaded->{'UR::Object::Index'}} ) {
        my $class = substr($idx_id, 0, index($idx_id, $index_id_sep));
        next unless exists $data_source_for_class{$class};
        push @{$indexes_by_class{$class}}, $UR::Context::all_objects_loaded->{'UR::Object::Index'}->{$idx_id};
    }

    my $deleted_count = 0;
    my $pass = 0;

    $cache_size_highwater = 1 if ($cache_size_highwater < 1);
    $cache_size_lowwater = 1 if ($cache_size_lowwater < 1);

    # Instead of sorting object cache by __get_serial, since we are trying to
    # conserve memory, we pass through the object cache reviewing chunks of older objects
    # first while working our way through the whole cache.
    my $target_serial = $cache_last_prune_serial;

    my $serial_range = ($GET_COUNTER - $target_serial);
    my $max_passes = 10;
    my $target_serial_increment = int($serial_range / $max_passes) + 1;
    while ($all_objects_cache_size > $cache_size_lowwater && $target_serial < $GET_COUNTER) {
        $pass++;
        $target_serial += $target_serial_increment;

        my @objects_to_prune;
        foreach my $class (keys %data_source_for_class) {
            my $objects_for_class = $UR::Context::all_objects_loaded->{$class};
            $indexes_by_class{$class} ||= [];

            foreach my $id ( keys ( %$objects_for_class ) ) {
                my $obj = $objects_for_class->{$id};
                next unless defined $obj;  # object with this ID does not exist
                if (
                    $obj->is_weakened
                    || $obj->is_prunable && $obj->{__get_serial} && $obj->{__get_serial} <= $target_serial
                ) {
                    if ($ENV{'UR_DEBUG_OBJECT_RELEASE'}) {
                        print STDERR "MEM PRUNE object $obj class $class id $id\n";
                    }
                    push @objects_to_prune, $obj;
                    $deleted_count++;
                }
            }
        }
        $self->_weaken_references_for_objects(\@objects_to_prune);
    }
    $is_pruning = 0;

    $cache_last_prune_serial = $target_serial;
    if ($ENV{'UR_DEBUG_OBJECT_RELEASE'} || $ENV{'UR_DEBUG_OBJECT_PRUNING'}) {
        my $t2 = Time::HiRes::time();
        printf("MEM PRUNE complete, $deleted_count objects marked after $pass passes in %.4f sec\n\n\n",$t2-$t1);
    }
    if ($all_objects_cache_size > $cache_size_lowwater) {
        Carp::carp "After several passes of pruning the object cache, there are still $all_objects_cache_size objects";
        if ($ENV{'UR_DEBUG_OBJECT_PRUNING'}) {
            warn "Top 10 classes by object count:\n" . $self->_object_cache_pruning_report;
        }
    }
    return 1;
}

sub _weaken_references_for_objects {
    my($self, $obj_list) = @_;

    Carp::croak('Argument to _weaken_references_to_objects must be an arrayref')
        unless ref($obj_list) eq 'ARRAY';

    my %indexes_by_class;
    foreach my $obj ( @$obj_list) {
        my $class = $obj->class;
        $indexes_by_class{ $class } ||= [ UR::Object::Index->get(indexed_class_name => $class) ];

        $_->weaken_reference_for_object($obj) foreach @{ $indexes_by_class{ $class }};
        delete $obj->{__get_serial};
        Scalar::Util::weaken($UR::Context::all_objects_loaded->{$class}->{$obj->id});
        $all_objects_cache_size--;
    }
}


sub _object_cache_pruning_report {
    my $self = shift;
    my $max_show = shift;

    $max_show = 10 unless defined ($max_show);

    my @sorted_counts = sort { $b->[1] <=> $a->[1] }
                        map { [ $_ => scalar(keys %{$UR::Context::all_objects_loaded->{$_}}) ] }
                        grep { !$_->__meta__->is_meta_meta }
                        keys %$UR::Context::all_objects_loaded;
    my $message = '';
    for (my $i = 0; $i < 10 and $i < @sorted_counts; $i++) {
        my $class_name = $sorted_counts[$i]->[0];
        my $count      = $sorted_counts[$i]->[1];
        $message .= "$class_name: $count\n";

        if ($ENV{'UR_DEBUG_OBJECT_PRUNING'} > 1) {
            # more detailed info
            my $no_data_source = 0;
            my $other_references = 0;
            my $strengthened = 0;
            my $has_changes = 0;
            my $prunable = 0;
            my $class_data_source = eval { $class_name->__meta__->data_source_id; };
            foreach my $obj ( values %{$UR::Context::all_objects_loaded->{$class_name}} ) {
                next unless $obj;

                my $is_prunable = 1;
                if (! $class_data_source ) {
                    $no_data_source++;
                    $is_prunable = 0;
                }
                if (! exists $obj->{'__get_serial'}) {
                    $other_references++;
                    $is_prunable = 0;
                }
                if (exists $obj->{'__strengthened'}) {
                    $strengthened++;
                    $is_prunable = 0;
                }
                if ($obj->__changes__) {
                    $has_changes++;
                    $is_prunable = 0;
                }
                if ($is_prunable) {
                    $prunable++;
                }
            }
            $message .= sprintf("\tNo data source: %d  other refs: %d  strengthend: %d  has changes: %d  prunable: %d\n",
                                $no_data_source, $other_references, $strengthened, $has_changes, $prunable);
        }
    }
    return $message;
}


sub value_for_object_property_in_underlying_context {
    my ($self, $obj, $property_name) = @_;

    my $saved = $obj->{db_saved_uncommitted} || $obj->{db_committed};
    unless ($saved) {
        Carp::croak(qq(No object found in underlying context));
    }

    return $saved->{$property_name};
}


# True if the object was loaded from an underlying context and/or datasource, or if the
# object has been committed to the underlying context
sub object_exists_in_underlying_context {
    my($self, $obj) = @_;

    return if ($obj->{'__defined'});
    return (exists($obj->{'db_committed'}) || exists($obj->{'db_saved_uncommitted'}));
}


# Holds the logic for handling OR-type rules passed to get_objects_for_class_and_rule()
sub _get_objects_for_class_and_or_rule {
    my ($self, $class, $rule, $load, $return_closure) = @_;

    $rule = $rule->normalize;
    my @u = $rule->underlying_rules;
    my @results;
    for my $u (@u) {
        if (wantarray or not defined wantarray) {
            push @results, $self->get_objects_for_class_and_rule($class,$u,$load,$return_closure);
        }
        else {
            my $result = $self->get_objects_for_class_and_rule($class,$u,$load,$return_closure);
            push @results, $result;
        }
    }
    if ($return_closure) {
        my $object_sorter = $rule->template->sorter();

        my @next;
        return sub {
            # fill in missing slots in @next
            for(my $i = 0; $i < @results; $i++) {
                unless (defined $next[$i]) {
                    # This slot got used last time through
                    $next[$i] = $results[$i]->();
                    unless (defined $next[$i]) {
                        # That iterator is exhausted, splice it out
                        splice(@results, $i, 1);
                        splice(@next, $i, 1);
                        redo if $i < @results; #the next iterator is now at $i, not $i++
                    }
                }
            }

            my $lowest_slot = 0;
            for(my $i = 1; $i < @results; $i++) {
                my $cmp = $object_sorter->($next[$lowest_slot], $next[$i]);
                if ($cmp > 0) {
                    $lowest_slot = $i;
                } elsif ($cmp == 0) {
                    # duplicate object, mark this slot to fill in next time around
                    $next[$i] = undef;
                }
            }

            my $retval = $next[$lowest_slot];
            $next[$lowest_slot] = undef;
            return $retval;
        };
    }

    # remove duplicates
    my $last = 0;
    my $plast = 0;
    my $next = 0;
    @results = grep { $plast = $last; $last = $_; $plast == $_ ? () : ($_) } sort @results;

    return unless defined wantarray;
    return @results if wantarray;
    if (@results > 1) {
        $self->_exception_for_multi_objects_in_scalar_context($rule,\@results);
    }
    return $results[0];
}


# this is the underlying method for get/load/is_loaded in ::Object

sub get_objects_for_class_and_rule {
    my ($self, $class, $rule, $load, $return_closure) = @_;
    my $initial_load = $load;
    #my @params = $rule->params_list;
    #print "GET: $class @params\n";

    my $rule_template = $rule->template;
    
    my $group_by = $rule_template->group_by;

    if (ref($self) and !defined($load)) {
        $load = $self->query_underlying_context;  # could still be undef...
    }

    if ($group_by and $rule_template->order_by) {
        my %group_by = map { $_ => 1 } @{ $rule->template->group_by };
        foreach my $order_by_property ( @{ $rule->template->order_by } ) {
            unless ($group_by{$order_by_property}) {
                Carp::croak("Property '$order_by_property' in the -order_by list must appear in the -group_by list for BoolExpr $rule");
            }
        }
    }

    if (
        $cache_size_highwater
        and
        $all_objects_cache_size > $cache_size_highwater
    ) {
        $self->prune_object_cache();
    }

    if ($rule_template->isa("UR::BoolExpr::Template::Or")) {
        return $self->_get_objects_for_class_and_or_rule($class,$rule,$load,$return_closure);
    }

    # an identifier for all objects gotten in this request will be set/updated on each of them for pruning later
    my $this_get_serial = $GET_COUNTER++;
    
    my $meta = $class->__meta__();    

    # A query on a subclass where the parent class is_abstract and has a subclassify_by property
    # (meaning that the parent class has a property which directly stores the proper subclass for
    # each row - subclasses inherit the property from the parent, and the subclass isn't is_abstract)
    # should have a filter added to the rule to keep only rows of the subclass we're interested in.
    # This will improve the SQL performance when it's later constructed.
    my $subclassify_by = $meta->subclassify_by;
    if ($subclassify_by 
        and ! $meta->is_abstract 
        and ! $rule->template->group_by 
        and ! $rule->specifies_value_for($subclassify_by)
    ) {
        $rule = $rule->add_filter($subclassify_by => $class);
    }

    # If $load is undefined, and there is no underlying context, we define it to FALSE explicitly
    # TODO: instead of checking for a data source, skip this
    # We'll always go to the underlying context, even if it has nothing. 
    # This optimization only works by coincidence since we don't stack contexts currently beyond 1.
    my $ds;
    if (!defined($load) or $load) {
        ($ds) = $self->resolve_data_sources_for_class_meta_and_rule($meta,$rule);
        if (! $ds or $class =~ m/::Ghost$/) {
            # Classes without data sources and Ghosts can only ever come from the cache
            $load = 0;  
        } 
    }
 
    # this is an arrayref of all of the cached data
    # it is set in one of two places below
    my $cached;
   
    # this will turn foo=>$foo into foo.id=>$foo->id where possible
    my $no_hard_refs_rule = $rule->flatten_hard_refs;
    
    # we do not currently fully "flatten" b/c the bx constant_values do not flatten/reframe
    #my $flat_rule = ( (1 or $no_hard_refs_rule->subject_class_name eq 'UR::Object::Property') ? $no_hard_refs_rule : $no_hard_refs_rule->flatten);
    
    # this is a no-op if the rule is already normalized
    my $normalized_rule = $no_hard_refs_rule->normalize;

    my $is_monitor_query = $self->monitor_query;
    $self->_log_query_for_rule($class,$normalized_rule,Carp::shortmess("QUERY: Query start for rule $normalized_rule")) if ($is_monitor_query);

    # see if we need to load if load was not defined
    unless (defined $load) {
        # check to see if the cache is complete
        # also returns a list of the complete cached objects where that list is found as a side-effect
        my ($cache_is_complete, $cached) = $self->_cache_is_complete_for_class_and_normalized_rule($class, $normalized_rule);
        $load = ($cache_is_complete ? 0 : 1);
    }

    if ($ds and $load and $rule_template->order_by) {
        # if any of the order_by is calculated, then we need to do an unordered query against the
        # data source, then we can do it as a non-load query and do the sorting on all the in-memory
        # objects
        my $qp = $ds->_resolve_query_plan($rule_template);
        if ($qp->order_by_non_column_data) {
            $self->_log_query_for_rule($class,$normalized_rule,"QUERY: Doing an unordered query on the datasource because one of the order_by properties of the rule is not expressable by the data source") if ($is_monitor_query);
            $self->get_objects_for_class_and_rule($class, $rule->remove_filter('-order')->remove_filter('-order_by'), 1);
            $load = 0;
        }
    }

    my $normalized_rule_template = $normalized_rule->template;

    # optimization for the common case
    if (!$load and !$return_closure) {
        my @c = $self->_get_objects_for_class_and_rule_from_cache($class,$normalized_rule);
        my $obj_count = scalar(@c);
        foreach ( @c ) {
            unless (exists $_->{'__get_serial'}) {
                # This is a weakened reference.  Convert it back to a regular ref
                my $class = ref $_;
                my $id = $_->id;
                my $ref = $UR::Context::all_objects_loaded->{$class}->{$id};
                $UR::Context::all_objects_loaded->{$class}->{$id} = $ref;
            }
            $_->{'__get_serial'} = $this_get_serial;
        }

        if ($is_monitor_query) {
            $self->_log_query_for_rule($class,$normalized_rule,"QUERY: matched $obj_count cached objects (no loading)");
            $self->_log_query_for_rule($class,$normalized_rule,"QUERY: Query complete after returning $obj_count object(s) for rule $rule");
            $self->_log_done_elapsed_time_for_rule($normalized_rule);
        }

        if (defined($normalized_rule_template->limit) || defined($normalized_rule_template->offset)) {
            $self->_prune_obj_list_for_limit_and_offset(\@c,$normalized_rule_template);
        }

        return @c if wantarray;           # array context
        return unless defined wantarray;  # null context
        Carp::confess("multiple objects found for a call in scalar context!" . Data::Dumper::Dumper(\@c)) if @c > 1;
        return $c[0];                     # scalar context
    }

    my $object_sorter = $normalized_rule_template->sorter();

    # the above process might have found all of the cached data required as a side-effect in which case
    # we have a value for this early 
    # either way: ensure the cached data is known and sorted
    if ($cached) {
        @$cached = sort $object_sorter @$cached;
    }
    else {
        $cached = [ sort $object_sorter $self->_get_objects_for_class_and_rule_from_cache($class,$normalized_rule) ];
    }
    $self->_log_query_for_rule($class, $normalized_rule, "QUERY: matched ".scalar(@$cached)." cached objects") if ($is_monitor_query);
    foreach ( @$cached ) {
        unless (exists $_->{'__get_serial'}) {
            # This is a weakened reference.  Convert it back to a regular ref
            my $class = ref $_;
            my $id = $_->id;
            my $ref = $UR::Context::all_objects_loaded->{$class}->{$id};
            $UR::Context::all_objects_loaded->{$class}->{$id} = $ref;
        }
        $_->{'__get_serial'} = $this_get_serial;
    }

    
    # make a loading iterator if loading must be done for this rule
    my $loading_iterator;
    if ($load) {
        # this returns objects from the underlying context after importing them into the current context,
        # but only if they did not exist in the current context already
        $self->_log_query_for_rule($class, $normalized_rule, "QUERY: importing from underlying context with rule $normalized_rule") if ($is_monitor_query);

        $loading_iterator = UR::Context::LoadingIterator->_create($cached, $self,$normalized_rule, $ds,$this_get_serial);
    }

    if ($return_closure) {
        if ($load) {
            # return the iterator made above
            return $loading_iterator;
        }
        else {
            # make a quick iterator for the cached data
            if(defined($normalized_rule_template->limit) || defined($normalized_rule_template->offset)) {
                $self->_prune_obj_list_for_limit_and_offset($cached,$normalized_rule_template);
            }
            return sub { return shift @$cached };
        }
    }
    else {
        my @results;
        if ($loading_iterator) {
            # use the iterator made above
            my $found;
            while (defined($found = $loading_iterator->(1))) {
                push @results, $found;
            }
        }
        else {
            # just get the cached data
            if(defined($normalized_rule_template->limit) || defined($normalized_rule_template->offset)) {
                $self->_prune_obj_list_for_limit_and_offset($cached,$normalized_rule_template);
            }
            @results = @$cached;
        }
        return unless defined wantarray;
        return @results if wantarray;
        if (@results > 1) {
            $self->_exception_for_multi_objects_in_scalar_context($rule,\@results);
        }
        return $results[0];
    }
}


sub _exception_for_multi_objects_in_scalar_context {
    my($self,$rule,$resultsref) = @_;

    my $message = sprintf("Multiple results unexpected for query.\n\tClass %s\n\trule params: %s\n\tGot %d results",
                          $rule->subject_class_name,
                          join(',', $rule->params_list),
                          scalar(@$resultsref));
    my $lastidx = $#$resultsref;
    if (@$resultsref > 10) {
        $message .= "; the first 10 are";
        $lastidx = 9;
    }
    Carp::confess($message . ":\n" . Data::Dumper::Dumper([@$resultsref[0..$lastidx]]));
}

sub _prune_obj_list_for_limit_and_offset {
    my($self, $obj_list, $tmpl) = @_;

    my $limit = defined($tmpl->limit) ? $tmpl->limit : $#$obj_list;
    my $offset = $tmpl->offset || 0;

    if ($offset > @$obj_list) {
        Carp::carp('-offset is larger than the result list');
        @$obj_list = ();
    } else {
        @$obj_list = splice(@$obj_list, $offset, $limit);
    }
}


sub __merge_db_data_with_existing_object {
    my($self, $class_name, $existing_object, $pending_db_object_data, $property_names) = @_;

    unless (defined $pending_db_object_data) {
        # This means a row in the database is missing for an object we loaded before
        if (defined($existing_object)
            and $self->object_exists_in_underlying_context($existing_object)
            and $existing_object->__changes__
        ) {
            my $id = $existing_object->id;
            Carp::croak("$class_name ID '$id' previously existed in an underlying context, has since been deleted from that context, and the cached object now has unsavable changes.\nDump: ".Data::Dumper::Dumper($existing_object)."\n");
        } else {
#print "Removing object id ".$existing_object->id." because it has been removed from the database\n";
            UR::Context::LoadingIterator->_remove_object_from_other_loading_iterators($existing_object);
            $existing_object->__signal_change__('delete');
            $self->_abandon_object($existing_object);
            return $existing_object;
        }
    }

    my $expected_db_data;
    if (exists $existing_object->{'db_saved_uncommitted'}) {
        $expected_db_data = $existing_object->{'db_saved_uncommitted'};

    } elsif (exists $existing_object->{'db_committed'}) {
        $expected_db_data = $existing_object->{'db_committed'};

    } else {
        my $id = $existing_object->id;
        Carp::croak("$class_name ID '$id' has just been loaded, but it exists in the application as a new unsaved object!\nDump: " . Data::Dumper::Dumper($existing_object) . "\n");
    }

    my $different = 0;
    my $conflict = undef;

    foreach my $property ( @$property_names ) {
        no warnings 'uninitialized';

        # All direct properties are stored in the same-named hash key, right?
        next unless (exists $existing_object->{$property});

        my $object_value      = $existing_object->{$property};
        my $db_value          = $pending_db_object_data->{$property};
        my $expected_db_value = $expected_db_data->{$property};

        if ($object_value ne $expected_db_value) {
            $different++;
        }

        
        if ( $object_value eq $db_value              # current value matches DB value
             or
             ($object_value eq $expected_db_value)   # current value hasn't changed since it was loaded from the DB
             or
             ($db_value eq $expected_db_value)       # DB value matches what it was when we loaded it from the DB
        ) {
            # no conflict.  Check the next one
            next;
        } else {
            $conflict = $property;
            last;
        }
    }

    if (defined $conflict) {
        # conflicting change!
        # Since the user could be catching this exception, go ahead and update the
        # object's notion of what is in the database
        my %old_dbc = %$expected_db_data;
        @$expected_db_data{@$property_names} = @$pending_db_object_data{@$property_names};

        my $old_value = defined($old_dbc{$conflict})
                        ? "'" . $old_dbc{$conflict} . "'"
                        : '(undef)';
        my $new_db_value = defined($pending_db_object_data->{$conflict})
                        ? "'" . $pending_db_object_data->{$conflict} . "'"
                        : '(undef)';
        my $new_obj_value = defined($existing_object->{$conflict})
                        ? "'" . $existing_object->{$conflict} . "'"
                        : '(undef)';

        my $obj_id = $existing_object->id;

        Carp::croak("\nA change has occurred in the database for $class_name property '$conflict' on object ID $obj_id from $old_value to $new_db_value.\n"
                    . "At the same time, this application has made a change to that value to $new_obj_value.\n\n"
                    . "The application should lock data which it will update and might be updated by other applications.");

    }
 
    # No conflicts.  Update db_committed and db_saved_uncommitted based on the DB data
    %$expected_db_data = (%$expected_db_data, %$pending_db_object_data);

    if (! $different) {
        # FIXME HACK!  This is to handle the case when you get an object, start a software transaction,
        # change something in the database for that object, reload the object (so __merge updates the value 
        # found in the DB), then rollback the transaction.  The act of updating the value here in __merge makes
        # a change record that gets undone when the transaction is rolled back.  After the rollback, the current
        # value goes back to the originally loaded value, db_committed has the newly clhanged DB value, but
        # _change_count is 0 turning off change tracking makes it so this internal change isn't undone by rollback
        local $UR::Context::Transaction::log_all_changes = 0;  # HACK!
        # The object has no local changes.  Go ahead and update the current value, too
        foreach my $property ( @$property_names ) {
            no warnings 'uninitialized';
            next if ($existing_object->{$property} eq $pending_db_object_data->{$property});

            $existing_object->$property($pending_db_object_data->{$property});
        }
    }

    # re-figure how many changes are really there
    my @change_count = $existing_object->__changes__;
    $existing_object->{'_change_count'} = scalar(@change_count);

    return $different;
}



sub _get_objects_for_class_and_sql {
    # this is a depracated back-door to get objects with raw sql
    # only use it if you know what you're doing
    my ($self, $class, $sql) = @_;
    my $meta = $class->__meta__;        
    #my $ds = $self->resolve_data_sources_for_class_meta_and_rule($meta,$class->define_boolexpr());    
    my $ds = $self->resolve_data_sources_for_class_meta_and_rule($meta,UR::BoolExpr->resolve($class));
    my $id_list = $ds->_resolve_ids_from_class_name_and_sql($class,$sql);
    return unless (defined($id_list) and @$id_list);

    my $rule = UR::BoolExpr->resolve_normalized($class, id => $id_list);
    
    return $self->get_objects_for_class_and_rule($class,$rule);
}

sub _cache_is_complete_for_class_and_normalized_rule {
    my ($self,$class,$normalized_rule) = @_;

    # TODO: convert this to use the rule object instead of going back to the legacy hash format

    my ($id,$params,@objects,$cache_is_complete);
    $params = $normalized_rule->legacy_params_hash;
    $id = $params->{id};

    # Determine ahead of time whether we believe the object MUST be loaded if it exists.
    # If this is true, we will shortcut out of any action which loads or prepares for loading.

    # Try to resolve without loading in cases where we are sure
    # that doing so will return the complete results.
    
    my $id_only = $params->{_id_only};
    $id_only = undef if ref($id) and ref($id) eq 'HASH';
    if ($id_only) {
        # _id_only means that only id parameters were passed in.
        # Either a single id or an arrayref of ids.
        # Try to pull objects from the cache in either case
        if (ref $id) {
            # arrayref id
            
            # we check the immediate class and all derived
            # classes for any of the ids in the set.
            @objects =
                grep { $_ }
                map { @$_{@$id} }
                map { $all_objects_loaded->{$_} }
                ($class, $class->__meta__->subclasses_loaded);

            # see if we found all of the requested objects
            if (@objects == @$id) {
                # we found them all
                # return them all
                $cache_is_complete = 1;
            }
            else {
                # Ideally we'd filter out the ones we found,
                # but that gets complicated.
                # For now, we do it the slow way for partial matches
                @objects = ();
            }
        }
        else {
            # scalar id
            # Check for objects already loaded.
            no warnings;
            if (exists $all_objects_loaded->{$class}->{$id}) {
                $cache_is_complete = 1;
                @objects =
                    grep { $_ }
                    $all_objects_loaded->{$class}->{$id};
            }
            elsif (not $class->isa("UR::Value")) {
                # we already checked the immediate class,
                # so just check derived classes
                # this is not done for values because an identity can exist 
                # with independent objects with values, unlike entities
                @objects =
                    grep { $_ }
                    map { $all_objects_loaded->{$_}->{$id} }
                    $class->__meta__->subclasses_loaded;
                if (@objects) {
                    $cache_is_complete = 1;
                }
            }
        }
    }
    elsif ($params->{_unique}) {
        # _unique means that this set of params could never
        # result in more than 1 object.  
        
        # See if the 1 is in the cache
        # If not we have to load
        
        @objects = $self->_get_objects_for_class_and_rule_from_cache($class,$normalized_rule);
        if (@objects) {
            $cache_is_complete = 1;
        }        
    }
    
    if ($cache_is_complete) {
        # if the $cache_is_comlete, the $cached list DEFINITELY represents all objects we need to return        
        # we know that loading is NOT necessary because what we've found cached must be the entire set
    
        # Because we happen to have that set, we return it in addition to the boolean flag
        return wantarray ? (1, \@objects) : ();
    }
    
    # We need to do more checking to see if loading is necessary
    # Either the parameters were non-unique, or they were unique
    # and we didn't find the object checking the cache.

    # See if we need to do a load():

    my $template_id = $normalized_rule->template_id;
    my $rule_id     = $normalized_rule->id;
    my $loading_is_in_progress_on_another_iterator = 
            grep { $_->is_loading_in_progress_for_boolexpr($normalized_rule) }
                UR::Context::ObjectFabricator->all_object_fabricators;

    return 0 if $loading_is_in_progress_on_another_iterator;

    # complex (non-single-id) params
    my $loading_was_done_before_with_these_params = (
                # exact match to previous attempt
                (    exists ($UR::Context::all_params_loaded->{$template_id})
                     and
                     exists ($UR::Context::all_params_loaded->{$template_id}->{$rule_id})
                )
                ||
                # this is a subset of a previous attempt
                ($self->_loading_was_done_before_with_a_superset_of_this_rule($normalized_rule))
            );
    
    my $object_is_loaded_or_non_existent =
        $loading_was_done_before_with_these_params
        || $class->all_objects_are_loaded;
    
    if ($object_is_loaded_or_non_existent) {
        # These same non-unique parameters were used to load previously,
        # or we loaded everything at some point.
        # No load necessary.
        return 1;
    }
    else {
        # Load according to params
        return;
    }
} # done setting $load, and possibly filling $cached/$cache_is_complete as a side-effect


sub all_objects_loaded  {
    my $self = shift;
    my $class = $_[0];
    return(
        grep {$_}
        map { values %{ $UR::Context::all_objects_loaded->{$_} } } 
        $class, $class->__meta__->subclasses_loaded
    );  
}

sub all_objects_loaded_unsubclassed  {
    my $self = shift;
    my $class = $_[0];
    return (grep {$_} values %{ $UR::Context::all_objects_loaded->{$class} } );
}


sub _get_objects_for_class_and_rule_from_cache {
    # Get all objects which are loaded in the application which match
    # the specified parameters.
    my ($self, $class, $rule) = @_;
    
    my ($template,@values) = $rule->template_and_values;

    #my @param_list = $rule->params_list;
    #print "CACHE-GET: $class @param_list\n";

    my $strategy = $rule->{_context_query_strategy};    
    unless ($strategy) {
        if ($rule->template->group_by) {
            $strategy = $rule->{_context_query_strategy} = "set intersection";
        }
        elsif ($rule->num_values == 0) {
            $strategy = $rule->{_context_query_strategy} = "all";
        }
        elsif ($rule->is_id_only) {
            $strategy = $rule->{_context_query_strategy} = "id";
        }        
        else {
            $strategy = $rule->{_context_query_strategy} = "index";
        }
    }
    
    my @results = eval {
    
        if ($strategy eq "all") {
            return $self->all_objects_loaded($class);
        }
        elsif ($strategy eq "id") {
            my $id = $rule->value_for_id();
            
            unless (defined $id) {
                $id = $rule->value_for_id();
            }
            
            # Try to get the object(s) from this class directly with the ID.
            # Note that the code below is longer than it needs to be, but
            # is written to run quickly by resolving the most common cases
            # first, and gathering data only if and when it must.
    
            my @matches;
            if (ref($id) eq 'ARRAY') {
                # The $id is an arrayref.  Get all of the set.
                @matches = grep { $_ } map { @$_{@$id} } map { $all_objects_loaded->{$_} } ($class);
                
                # We're done if the number found matches the number of ID values.
                return @matches if @matches == @$id;
            }
            else {
                # The $id is a normal scalar.
                if (not defined $id) {
                    #Carp::carp("Undefined id passed as params for query on $class");
                    Carp::cluck("\n\n****  Undefined id passed as params for query on $class");
                    $id ||= '';
                }
                my $match;
                # FIXME This is a performance optimization for class metadata to avoid the search through
                # @subclasses_loaded a few lines further down.  When 100s of classes are loaded it gets
                # a bit slow.  Maybe UR::Object::Type should override get() instad and put it there?
                if (! $UR::Object::Type::bootstrapping and $class eq 'UR::Object::Type') {
                    my $meta_class_name = $id . '::Type';
                    $match = $all_objects_loaded->{$meta_class_name}->{$id}
                             ||
                             $all_objects_loaded->{'UR::Object::Type'}->{$id};
                    if ($match) {
                        return $match;
                    } else {
                        return;
                    }
                }   

                $match = $all_objects_loaded->{$class}->{$id};
    
                # We're done if we found anything.  If not we keep checking.
                return $match if $match;
            }
    
            # Try to get the object(s) from this class's subclasses.
            # We may be adding to matches made above is we used an arrayref
            # and the results are incomplete.
    
            my @subclasses_loaded = $class->__meta__->subclasses_loaded;
            return @matches unless @subclasses_loaded;
    
            if (ref($id) eq 'ARRAY') {
                # The $id is an arrayref.  Get all of the set and add it to anything found above.
                push @matches,
                    grep { $_  }
                    map { @$_{@$id} }
                    map { $all_objects_loaded->{$_} }
                    @subclasses_loaded;    
            }
            else {
                # The $id is a normal scalar, but we didn't find it above.
                # Try each subclass, exiting if we find anything.
                for (@subclasses_loaded) {
                    my $match = $all_objects_loaded->{$_}->{$id};
                    return $match if $match;
                }
            }
            
            # Since an ID was specified, and we've scanned the core hash every way possible,
            # we're done.  Return nothing if necessary.
            return @matches;
        }
        elsif ($strategy eq "index") {
            # FIXME - optimize by using the rule (template?)'s param names directly to get the
            # index id instead of re-figuring it out each time

            my $class_meta = $rule->subject_class_name->__meta__;
            my %params = $rule->params_list;
            my $should_evaluate_later;
            for my $key (keys %params) {
                if (substr($key,0,1) eq '-' or substr($key,0,1) eq '_') {
                    delete $params{$key};
                }
                elsif ($key =~ /^\w*\./) {
                    # a chain of properties
                    $should_evaluate_later = 1;
                    delete $params{$key};
                }
                else { 
                    my $prop_meta = $class_meta->property_meta_for_name($key);
                    # NOTE: We _could_ remove the is_delegated check if we knew we were operating on
                    # a read-only context.
                    if ($prop_meta && ($prop_meta->is_many or $prop_meta->is_delegated)) {
                        # These indexes perform poorly in the general case if we try to index
                        # the is_many properties.  Instead, strip them out from the basic param
                        # list, and evaluate the superset of indexed objects through the rule
                        $should_evaluate_later = 1;
                        delete $params{$key};
                    }
                }
            }
            
            my @properties = sort keys %params;
            unless (@properties) {
                # All the supplied filters were is_many properties
                return grep { $rule->evaluate($_) } $self->all_objects_loaded($class);
            }

            my @values = map { $params{$_} } @properties;
            
            unless (@properties == @values) {
                Carp::confess();
            }
            
            # find or create the index
            my $pstring = join(",",@properties);
            my $index_id = UR::Object::Index->__meta__->resolve_composite_id_from_ordered_values($class,$pstring);
            my $index = $all_objects_loaded->{'UR::Object::Index'}{$index_id};
            $index ||= UR::Object::Index->create(
                id => $index_id,
                indexed_class_name => $class,
                indexed_property_string => $pstring
            );
            

            # add the indexed objects to the results list
            
            
            if ($UR::Debug::verify_indexes) {
                my @matches = $index->get_objects_matching(@values);        
                @matches = sort @matches;
                my @matches2 = sort grep { $rule->evaluate($_) } $self->all_objects_loaded($class);
                unless ("@matches" eq "@matches2") {
                    print "@matches\n";
                    print "@matches2\n";
                    #Carp::cluck("Mismatch!");
                    my @matches3 = $index->get_objects_matching(@values);
                    my @matches4 = $index->get_objects_matching(@values);                
                    return @matches2; 
                }
                return @matches;
            }
            
            if ($should_evaluate_later) {
                return grep { $rule->evaluate($_) } $index->get_objects_matching(@values);
            } else {
                return $index->get_objects_matching(@values);
            }
        }
        elsif ($strategy eq 'set intersection') {
            #print $rule->num_values, "  ", $rule->is_id_only, "\n";
            my $template = $rule->template;
            my $group_by = $template->group_by;

            # get the objects in memory, and make sets for them if they do not exist 
            my $rule_no_group = $rule->remove_filter('-group_by');
            $rule_no_group = $rule_no_group->remove_filter('-order_by');
            my @objects_in_set = $self->_get_objects_for_class_and_rule_from_cache($class, $rule_no_group);
            my @sets_from_grouped_objects = _group_objects($rule_no_group->template,\@values,$group_by,\@objects_in_set);

            # determine the template that the grouped subsets will use
            # find templates which are subsets of that template
            # find sets with a 
            my $set_class = $class . '::Set';
            my $expected_template_id = $rule->template->_template_for_grouped_subsets->id;
            my @matches = 
                grep {
                    # TODO: make the template something indexable so we can pull from index
                    my $bx = UR::BoolExpr->get($_->id);
                    my $bxt = $bx->template;
                    if ($bxt->id ne $expected_template_id) {
                        #print "TEMPLATE MISMATCH $expected_template_id does not match $bxt->{id}! set: $_ with bxid $bx->{id} cannot be under rule $rule_no_group" . Data::Dumper::Dumper($_);
                        ();
                    }
                    elsif (not $bx->is_subset_of($rule_no_group) ) {
                        #print "SUBSET MISMATCH: $rule_no_group is not a superset of $_ with bxid $bx->{id}" . Data::Dumper::Dumper($_);
                        ();
                    }
                    else {
                        #print "MATCH: $rule_no_group with $expected_template_id matches $bx $bx->{id}" . Data::Dumper::Dumper($_);
                        ($_);
                    }
                }
                $self->all_objects_loaded($set_class);
           
            # Code to check that newly fabricated set definitions are in the set we query back out:
            # my @all = $self->all_objects_loaded($set_class);
            # my %expected;
            # @expected{@sets_from_grouped_objects} = @sets_from_grouped_objects;
            # for my $match (@matches) {
            #    delete $expected{$match};
            # }
            # if (keys %expected) {
            #    #$DB::single = 1;
            #    print Data::Dumper::Dumper(\%expected);
            # }

            return @matches;
        }
        else {
            die "unknown strategy $strategy";
        }
    };
        
    # Handle passing-through any exceptions.
    die $@ if $@;

    if (my $recurse = $template->recursion_desc) {        
        my ($this,$prior) = @$recurse;
        # remove undef items.  undef/NULL in the recursion linkage means it doesn't link to anything
        my @values = grep { defined }
                     map { $_->$prior }
                     @results;
        if (@values) {
            # We do get here, so that adjustments to intermediate foreign keys
            # in the cache will result in a new query at the correct point,
            # and not result in missing data.
            #push @results, $class->get($this => \@values, -recurse => $recurse);
            push @results, map { $class->get($this => $_, -recurse => $recurse) } @values;
        }
    }

    my $group_by = $template->group_by;
    #if ($group_by) {
    #    # return sets instead of the actual objects
    #    @results = _group_objects($template,\@values,$group_by,\@results);
    #}

    if (@results > 1) {
        my $sorter;
        if ($group_by) {
            # We need to rewrite the original rule on the member class to be a rule
            # on the Set class to do proper ordering
            my $set_class = $template->subject_class_name . '::Set';
            my $set_template = UR::BoolExpr::Template->resolve($set_class, -group_by => $group_by);
            $sorter = $set_template->sorter;
        } else {
            $sorter = $template->sorter;
        }
        @results = sort $sorter @results;
    }

    # Return in the standard way.
    return @results if (wantarray);
    Carp::confess("Multiple matches for $class @_!") if (@results > 1);
    return $results[0];
}

sub _group_objects {
    my ($template,$values,$group_by,$objects)  = @_;
    my $sub_template = $template->remove_filter('-group_by');
    for my $property (@$group_by) {
        $sub_template = $sub_template->add_filter($property);
    }
    my $set_class = $template->subject_class_name . '::Set';
    my @groups;
    my %seen;
    for my $result (@$objects) {
        my %values_for_group_property;
        foreach my $group_property ( @$group_by ) {
            my @values = $result->$group_property;
            if (@values) {
                $values_for_group_property{$group_property} = \@values;
            } else {
                $values_for_group_property{$group_property} = [ undef ];
            }
        }
        my @combinations = UR::Util::combinations_of_values(map { $values_for_group_property{$_} } @$group_by);
        foreach my $extra_values ( @combinations ) {
            my $bx = $sub_template->get_rule_for_values(@$values,@$extra_values);
            next if $seen{$bx->id}++;
            my $group = $set_class->get($bx->id);
            push @groups, $group;
        }
    }
    return @groups;
}

sub _loading_was_done_before_with_a_superset_of_this_rule {
    my($self,$rule) = @_;

    my $template = $rule->template;

    if (exists $UR::Context::all_params_loaded->{$template->id}
        and exists $UR::Context::all_params_loaded->{$template->id}->{$rule->id}
    ) {
        return 1;
    }

    if ($template->subject_class_name->isa("UR::Value")) {
        return;
    }

    my @rule_values = $rule->values;
    my @rule_param_names = $template->_property_names;
    my %rule_values;
    for (my $i = 0; $i < @rule_param_names; $i++) {
        $rule_values{ $rule_param_names[$i] } = $rule_values[$i];
    }

    foreach my $loaded_template_id ( keys %$UR::Context::all_params_loaded ) {
        my $loaded_template = UR::BoolExpr::Template->get($loaded_template_id);
        if($template->is_subset_of($loaded_template)) {
            # Try limiting the possibilities by matching the previously-loaded rule value_id's
            # on this rule's values
            my @param_names = $loaded_template->_property_names;
            my @values = @rule_values{ @param_names };
            my $value_id;
            { no warnings 'uninitialized';
              $value_id = join($UR::BoolExpr::Util::record_sep, @values);
            }
            my @candidates = grep { index($_, $value_id) > 0 } keys(%{ $UR::Context::all_params_loaded->{$loaded_template_id} });
            foreach my $loaded_rule_id ( @candidates ) {
                my $loaded_rule = UR::BoolExpr->get($loaded_rule_id);
                return 1 if ($rule->is_subset_of($loaded_rule));
            }
        }
    }
    return;
}



sub _forget_loading_was_done_with_template_and_rule {
    my($self,$template_id, $rule_id) = @_;

    delete $all_params_loaded->{$template_id}->{$rule_id};
}

# Given a list of values, returns a list of lists containing all subsets of
# the input list, including the original list and the empty list
sub _get_all_subsets_of_params {
    my $self = shift;

    return [] unless @_;
    my $first = shift;
    my @rest = $self->_get_all_subsets_of_params(@_);
    return @rest, map { [$first, @$_ ] } @rest;
}

sub query_underlying_context {
    my $self = shift;
    unless (ref $self) {
        $self = $self->current;
    }
    if (@_) {
        $self->{'query_underlying_context'} = shift;
    }
    return $self->{'query_underlying_context'};
}


# all of these delegate to the current context...

sub has_changes {
    return shift->get_current->has_changes(@_);
}

sub commit {
    Carp::carp 'UR::Context::commit() called as a function, not a method.  Assumming commit on current context' unless @_;

    my $self = shift;
    $self = UR::Context->current() unless ref $self;

    $self->__signal_change__('precommit');

    unless ($self->_sync_databases) {
        $self->__signal_observers__('sync_databases', 0);
        $self->__signal_change__('commit',0);
        return;
    }

    $self->__signal_observers__('sync_databases', 1);

    unless ($self->_commit_databases) {
        $self->__signal_change__('commit',0);
        die "Application failure during commit!";
    }
    $self->__signal_change__('commit',1);

    $_->delete foreach UR::Change->get();

    foreach ( $self->all_objects_loaded('UR::Object') ) {
        delete $_->{'_change_count'};
    }

    return 1;
}

sub rollback {
    my $self = shift;
    unless ($self) {
        warn 'UR::Context::rollback() called as a function, not a method.  Assumming rollback on current context';
        $self = UR::Context->current();
    }
    $self->__signal_change__('prerollback');

    unless ($self->_reverse_all_changes) {
        $self->__signal_change__('rollback', 0);
        die "Application failure during reverse_all_changes?!";
    }
    unless ($self->_rollback_databases) {
        $self->__signal_change__('rollback', 0);
        die "Application failure during rollback!";
    }
    $self->__signal_change__('rollback', 1);
    return 1;
}

sub _tmp_self {
    my $self = shift;
    if (ref($self)) {
        return ($self,ref($self));
    }
    else {
        return ($UR::Context::current, $self);
    }
}

sub clear_cache {
    my ($self,$class) = _tmp_self(shift @_);
    my %args = @_;

    # dont unload any of the infrastructional classes, or any classes
    # the user requested to be saved
    my %local_dont_unload;
    if ($args{'dont_unload'}) {
        for my $class_name (@{$args{'dont_unload'}}) {
            $local_dont_unload{$class_name} = 1;
            for my $subclass_name ($class_name->__meta__->subclasses_loaded) {
                $local_dont_unload{$subclass_name} = 1;
            }
        }
    }

    for my $class_name (UR::Object->__meta__->subclasses_loaded) {

        # Once transactions are fully implemented, the command params will sit
        # beneath the regular transaction, so we won't need this.  For now,
        # we need a work-around.
        next if $class_name eq "UR::Command::Param";
        next if $class_name->isa('UR::Singleton');
        
        my $class_obj = $class_name->__meta__;
        #if ($class_obj->data_source and $class_obj->is_transactional) {
        #    # normal
        #}
        #elsif (!$class_obj->data_source and !$class_obj->is_transactional) {
        #    # expected
        #}
        #elsif ($class_obj->data_source and !$class_obj->is_transactional) {
        #    Carp::confess("!!!!!data source on non-transactional class $class_name?");
        #}
        #elsif (!$class_obj->data_source and $class_obj->is_transactional) {
        #    # okay
        #}

        next unless $class_obj->is_uncachable;
        next if $class_obj->is_meta_meta;
        next unless $class_obj->is_transactional;

        next if ($local_dont_unload{$class_name} ||
                 grep { $class_name->isa($_) } @{$args{'dont_unload'}});

        next if $class_obj->is_meta;

        next if not defined $class_obj->data_source;

        for my $obj ($self->all_objects_loaded_unsubclassed($class_name)) {
            # Check the type against %local_dont_unload again, because all_objects_loaded()
            # will return child class objects, as well as the class you asked for.  For example,
            # GSC::DNA->a_o_l() will also return GSC::ReadExp objects, and the user may have wanted
            # to save those.  We also check whether the $obj type isa one of the requested classes
            # because, for example, GSC::Sequence->a_o_l returns GSC::ReadExp types, and the user
            # may have wanted to save all GSC::DNAs
            my $obj_type = ref $obj;
            next if ($local_dont_unload{$obj_type} ||
                     grep {$obj_type->isa($_) } @{$args{'dont_unload'}});
            $obj->unload;
        }
        my @obj = grep { defined($_) } values %{ $UR::Context::all_objects_loaded->{$class_name} };
        if (@obj) {
            $class->warning_message("Skipped unload of $class_name objects during clear_cache: "
                . join(",",map { $_->id } @obj )
                . "\n"
            );
            if (my @changed = grep { $_->__changes__ } @obj) {
                require YAML;
                $class->error_message(
                    "The following objects have changes:\n"
                    . Data::Dumper::Dumper(\@changed)
                    . "The clear_cache method cannot be called with unsaved changes on objects.\n"
                    . "Use reverse_all_changes() first to really undo everything, then clear_cache(),"
                    . " or call sync_database() and clear_cache() if you want to just lighten memory but keep your changes.\n"
                    . "Clearing the cache with active changes will be supported after we're sure all code like this is gone. :)\n"                    
                );
                exit 1;
            }
        }
        delete $UR::Context::all_objects_loaded->{$class_name};
        delete $UR::Context::all_objects_are_loaded->{$class_name};
        delete $UR::Context::all_params_loaded->{$class_name};
    }
    1;
}

sub _order_data_sources_for_saving {
    my @data_sources = @_;

    my %can_savepoint = map { $_->id => $_->can_savepoint } @data_sources;
    my %classes = map { $_->id => $_->class } @data_sources;
    my %is_default = map { $_->id => $_->isa('UR::DataSource::Default') ? 1 : 0 } @data_sources;  # Default data sources go last

    return
        sort {
            $is_default{$a->id} <=> $is_default{$b->id}
            ||
            $can_savepoint{$a->id} <=> $can_savepoint{$b->id}
            ||
            $classes{$a->id} cmp $classes{$b->id}
        }
        @data_sources;
}


our $IS_SYNCING_DATABASE = 0;
sub _sync_databases {
    my $self = shift;
    my %params = @_;

    # Glue App::DB->sync_database with UR::Context->_sync_databases()
    # and avoid endless recursion.
    # FIXME Remove this when we're totally off of the old API
    # You'll also want to remove all the gotos from this function and uncomment
    # the returns
    return 1 if $IS_SYNCING_DATABASE;
    $IS_SYNCING_DATABASE = 1;
    if ($App::DB::{'sync_database'}) {
        unless (App::DB->sync_database() ) {
            $IS_SYNCING_DATABASE = 0;
            $self->error_message(App::DB->error_message());
            return;
        }
    }
    $IS_SYNCING_DATABASE = 0;  # This should be far down enough to avoid recursion, right?
 
    my @o = grep { ref($_) eq 'UR::DeletedRef' } $self->all_objects_loaded('UR::Object');
    if (@o) {
        print Data::Dumper::Dumper(\@o);
        Carp::confess();
    }

    # Determine what has changed.
    my @changed_objects = (
        $self->all_objects_loaded('UR::Object::Ghost'),
        grep { $_->__changes__ } $self->all_objects_loaded('UR::Object')
        #UR::Util->mapreduce_grep(sub { $_[0]->__changes__ },$self->all_objects_loaded('UR::Object'))
    );

    return 1 unless (@changed_objects);

    # Ensure validity.
    # This is primarily to catch custom validity logic in class overrides.
    my @invalid = grep { $_->__errors__ } @changed_objects;
    #my @invalid = UR::Util->mapreduce_grep(sub { $_[0]->__errors__}, @changed_objects);
    if (@invalid) {
        $self->display_invalid_data_for_save(\@invalid);
        goto PROBLEM_SAVING;
        #return;
    }

    # group changed objects by data source
    my %ds_objects;
    for my $obj (@changed_objects) {
        my $data_source = $self->resolve_data_source_for_object($obj);
        next unless $data_source;
        my $data_source_id = $data_source->id;
        $ds_objects{$data_source_id} ||= { 'ds_obj' => $data_source, 'changed_objects' => []};
        push @{ $ds_objects{$data_source_id}->{'changed_objects'} }, $obj;
    }

    my @ds_in_order =
        map { $_->id }
        _order_data_sources_for_saving(map { $_->{ds_obj} } values(%ds_objects));

    # save on each in succession
    my @done;
    my $rollback_on_non_savepoint_handle;
    for my $data_source_id (@ds_in_order) {
        my $obj_list = $ds_objects{$data_source_id}->{'changed_objects'};
        my $data_source = $ds_objects{$data_source_id}->{'ds_obj'};
        my $result = $data_source->_sync_database(
            %params,
            changed_objects => $obj_list,
        );
        if ($result) {
            push @done, $data_source;
            next;
        }
        else {
            $self->error_message(
                "Failed to sync data source: $data_source_id: "
                . $data_source->error_message
            );
            for my $prev_data_source (@done) {
                $prev_data_source->_reverse_sync_database;
            }
            goto PROBLEM_SAVING;
            #return;
        }
    }
    
    return 1;

    PROBLEM_SAVING:
    if ($App::DB::{'rollback'}) {
        App::DB->rollback();
    }
    return;
}


sub display_invalid_data_for_save {
    my $self = shift;
    my @objects_with_errors = @{shift @_};

    $self->error_message('Invalid data for save!');

    for my $obj (@objects_with_errors) {
        no warnings;
        my $identifier = eval { $obj->__display_name__ } || $obj->id;
        my $msg = $obj->class . " identified by " . $identifier . " has problems on\n";
        my @problems = $obj->__errors__;
        foreach my $error ( @problems ) {
            $msg .= $error->__display_name__ . "\n";
        }

        $msg .= "    Current state:\n";
        my $datadumper = Data::Dumper::Dumper($obj);
        my $nr_of_lines = $datadumper =~ tr/\n//;
        if ($nr_of_lines > 40) {
            # trim it down to the first 15 and last 3 lines
            $datadumper =~ m/^((?:.*\n){15})/;
            $msg .= $1;
            $datadumper =~ m/((?:.*(?:\n|$)){3})$/;
            $msg .= "[...]\n$1\n";
        } else {
            $msg .= $datadumper;
        }
        $self->error_message($msg);
    }

    return 1;
}


sub _reverse_all_changes {
    my $self = shift;
    my $class;
    if (ref($self)) {
        $class = ref($self);
    }
    else {
        $class = $self;
        $self = $UR::Context::current;
    }

    @UR::Context::Transaction::open_transaction_stack = ();
    @UR::Context::Transaction::change_log = ();
    $UR::Context::Transaction::log_all_changes = 0;
    $UR::Context::current = $UR::Context::process;

    my @objects =
        map { $self->all_objects_loaded_unsubclassed($_) }
        grep { $_->__meta__->is_transactional }
        grep { ! $_->isa('UR::Value') }
        sort UR::Object->__meta__->subclasses_loaded();

    for my $object (@objects) {
        $object->__rollback__();
    }

    return 1;
}

our $IS_COMMITTING_DATABASE = 0;
sub _commit_databases {
    my $class = shift;

    # Glue App::DB->commit() with UR::Context->_commit_databases()
    # and avoid endless recursion.
    # FIXME Remove this when we're totally off of the old API
    return 1 if $IS_COMMITTING_DATABASE;
    $IS_COMMITTING_DATABASE = 1;
    if ($App::DB::{'commit'}) {
        unless (App::DB->commit() ) {
	    $IS_COMMITTING_DATABASE = 0;
            $class->error_message(App::DB->error_message());
            return;
        }
    }
    $IS_COMMITTING_DATABASE = 0;

    my @ds_in_order = _order_data_sources_for_saving($UR::Context::current->all_objects_loaded('UR::DataSource'));
    my @committed;
    foreach my $ds ( @ds_in_order ) {
        if ($ds->commit) {
            push @committed, $ds;
        } else {
            my $message = 'Data source ' . $ds->get_name . ' failed to commit: ' . join("\n\t", $ds->error_messages);
            if (@committed) {
                $message .= "\nThese data sources were successfully committed, resulting in a FRAGMENTED DISTRIBUTED TRANSACTION: "
                            . join(', ', map { $_->get_name } @committed);
            }
            Carp::croak($message);
        }
    }

    return 1;
}


our $IS_ROLLINGBACK_DATABASE = 0;
sub _rollback_databases {
    my $class = shift;

    # Glue App::DB->rollback() with UR::Context->_rollback_databases()
    # and avoid endless recursion.
    # FIXME Remove this when we're totally off of the old API
    return 1 if $IS_ROLLINGBACK_DATABASE;
    $IS_ROLLINGBACK_DATABASE = 1;
    if ($App::DB::{'rollback'}) {
        unless (App::DB->rollback()) {
            $IS_ROLLINGBACK_DATABASE = 0;
            $class->error_message(App::DB->error_message());
            return;
        }
    }
    $IS_ROLLINGBACK_DATABASE = 0;

    $class->_for_each_data_source("rollback")
        or die "FAILED TO ROLLBACK!: " . $class->error_message;
    return 1;
}

sub _disconnect_databases {
    my $class = shift;
    $class->_for_each_data_source("disconnect");
    return 1;
}    

sub _for_each_data_source {
    my($class,$method) = @_;

    my @ds = $UR::Context::current->all_objects_loaded('UR::DataSource');
    foreach my $ds ( @ds ) {
       unless ($ds->$method) {
           $class->error_message("$method failed on DataSource ",$ds->get_name);
           return; 
       }
    }
    return 1;
}

sub _get_committed_property_value {
    my $class = shift;
    my $object = shift;
    my $property_name = shift;

    if ($object->{'db_committed'}) {
        return $object->{'db_committed'}->{$property_name};
    } elsif ($object->{'db_saved_uncommitted'}) {
        return $object->{'db_saved_uncommitted'}->{$property_name};
    } else {
        return;
    }
}

sub _dump_change_snapshot {
    my $class = shift;
    my %params = @_;

    my @c = grep { $_->__changes__ } $UR::Context::current->all_objects_loaded('UR::Object');

    my $fh;
    if (my $filename = $params{filename})
    {
        $fh = IO::File->new(">$filename");
        unless ($fh)
        {
            $class->error_message("Failed to open file $filename: $!");
            return;
        }
    }
    else
    {
        $fh = "STDOUT";
    }
    require YAML;
    $fh->print(YAML::Dump(\@c));
    $fh->close;
}

sub reload {
    my $self = shift;

    # this is here for backward external compatability
    # get() now goes directly to the context
    
    my $class = shift;
    if (ref $class) {
        # Trying to reload a specific object?
        if (@_) {
            Carp::confess("load() on an instance with parameters is not supported");
            return;
        }
        @_ = ('id' ,$class->id());
        $class = ref $class;
    }

    my ($rule, @extra) = UR::BoolExpr->resolve_normalized($class,@_);
    
    if (@extra) {
        if (scalar @extra == 2 and ($extra[0] eq "sql" or $extra[0] eq 'sql in')) {
           return $UR::Context::current->_get_objects_for_class_and_sql($class,$extra[1]);
        }
        else {
            die "Odd parameters passed directly to $class load(): @extra.\n"
                . "Processable params were: "
                . Data::Dumper::Dumper({ $rule->params_list });
        }
    }
    return $UR::Context::current->get_objects_for_class_and_rule($class,$rule,1);
}

## This is old, untested code that we may wany to resurrect at some point
#
#our $CORE_DUMP_VERSION = 1;
## Use Data::Dumper to save a representation of the object cache to a file.  Args are:
## filename => the name of the file to save to
## dumpall => boolean flagging whether to dump _everything_, or just the things
##            that would actually be loaded later in core_restore()
#
#sub _core_dump {
#    my $class = shift;
#    my %args = @_;
#
#    my $filename = $args{'filename'} || "/tmp/core." . UR::Context::Process->prog_name . ".$ENV{HOST}.$$";
#    my $dumpall = $args{'dumpall'};
#
#    my $fh = IO::File->new(">$filename");
#    if (!$fh) {
#      $class->error_message("Can't open dump file $filename for writing: $!");
#      return undef;
#    }
#
#    my $dumper;
#    if ($dumpall) {  # Go ahead and dump everything
#        $dumper = Data::Dumper->new([$CORE_DUMP_VERSION,
#                                     $UR::Context::all_objects_loaded,
#                                     $UR::Context::all_objects_are_loaded,
#                                     $UR::Context::all_params_loaded,
#                                     $UR::Context::all_change_subscriptions],
#                                    ['dump_version','all_objects_loaded','all_objects_are_loaded',
#                                     'all_params_loaded','all_change_subscriptions']);
#    } else {
#        my %DONT_UNLOAD =
#            map {
#                my $co = $_->__meta__;
#                if ($co and not $co->is_transactional) {
#                    ($_ => 1)
#                }
#                else {
#                    ()
#                }
#            }
#             $UR::Context::current->all_objects_loaded('UR::Object');
#
#        my %aol = map { ($_ => $UR::Context::all_objects_loaded->{$_}) }
#                     grep { ! $DONT_UNLOAD{$_} } keys %$UR::Context::all_objects_loaded;
#        my %aoal = map { ($_ => $UR::Context::all_objects_are_loaded->{$_}) }
#                      grep { ! $DONT_UNLOAD{$_} } keys %$UR::Context::all_objects_are_loaded;
#        my %apl = map { ($_ => $UR::Context::all_params_loaded->{$_}) }
#                      grep { ! $DONT_UNLOAD{$_} } keys %$UR::Context::all_params_loaded;
#        # don't dump $UR::Context::all_change_subscriptions
#        $dumper = Data::Dumper->new([$CORE_DUMP_VERSION,\%aol, \%aoal, \%apl],
#                                    ['dump_version','all_objects_loaded','all_objects_are_loaded',
#                                     'all_params_loaded']);
#
#    }
#
#    $dumper->Purity(1);   # For dumping self-referential data structures
#    $dumper->Sortkeys(1); # Makes quick and dirty file comparisons with sum/diff work correctly-ish
#
#    $fh->print($dumper->Dump() . "\n");
#
#    $fh->close;
#
#    return $filename;
#}
#
## Read a file previously generated with core_dump() and repopulate the object cache.  Args are:
## filename => name of the coredump file
## force => boolean flag whether to go ahead and attempt to load the file even if it thinks
##          there is a formatting problem
#sub _core_restore {
#    my $class = shift;
#    my %args = @_;
#    my $filename = $args{'filename'};
#    my $forcerestore = $args{'force'};
#
#    my $fh = IO::File->new("$filename");
#    if (!$fh) {
#        $class->error_message("Can't open dump file $filename for restoring: $!");
#        return undef;
#    }
#
#    my $code;
#    while (<$fh>) { $code .= $_ }
#
#    my($dump_version,$all_objects_loaded,$all_objects_are_loaded,$all_params_loaded,$all_change_subscriptions);
#    eval $code;
#
#    if ($@)
#    {
#        $class->error_message("Failed to restore core file state: $@");
#        return undef;
#    }
#    if ($dump_version != $CORE_DUMP_VERSION) {
#      $class->error_message("core file's version $dump_version differs from expected $CORE_DUMP_VERSION");
#      return 0 unless $forcerestore;
#    }
#
#    my %DONT_UNLOAD =
#        map {
#            my $co = $_->__meta__;
#            if ($co and not $co->is_transactional) {
#                ($_ => 1)
#            }
#            else {
#                ()
#            }
#        }
#        $UR::Context::current->all_objects_loaded('UR::Object');
#
#    # Go through the loaded all_objects_loaded, prune out the things that
#    # are in %DONT_UNLOAD
#    my %loaded_classes;
#    foreach ( keys %$all_objects_loaded ) {
#        next if ($DONT_UNLOAD{$_});
#        $UR::Context::all_objects_loaded->{$_} = $all_objects_loaded->{$_};
#        $loaded_classes{$_} = 1;
#
#    }
#    foreach ( keys %$all_objects_are_loaded ) {
#        next if ($DONT_UNLOAD{$_});
#        $UR::Context::all_objects_are_loaded->{$_} = $all_objects_are_loaded->{$_};
#        $loaded_classes{$_} = 1;
#    }
#    foreach ( keys %$all_params_loaded ) {
#        next if ($DONT_UNLOAD{$_});
#        $UR::Context::all_params_loaded->{$_} = $all_params_loaded->{$_};
#        $loaded_classes{$_} = 1;
#    }
#    # $UR::Context::all_change_subscriptions is basically a bunch of coderef
#    # callbacks that can't reliably be dumped anyway, so we skip it
#
#    # Now, get the classes to instantiate themselves
#    foreach ( keys %loaded_classes ) {
#        $_->class() unless m/::Ghost$/;
#    }
#
#    return 1;
#}

1;

=pod

=head1 NAME

UR::Context - Manage the current state of the application

=head1 SYNOPSIS

  use AppNamespace;

  my $obj = AppNamespace::SomeClass->get(id => 1234);
  $obj->some_property('I am changed');

  UR::Context->get_current->rollback; # some_property reverts to its original value

  $obj->other_property('Now, I am changed');

  UR::Context->commit; # other_property now permanently has that value


=head1 DESCRIPTION

The main application code will rarely interact with UR::Context objects
directly, except for the C<commit> and C<rollback> methods.  It manages
the mappings between an application's classes, object cache, and external
data sources.

=head1 SUBCLASSES

UR::Context is an abstract class.  When an application starts up, the system
creates a handful of Contexts that logically exist within one another:

=over 2

=item 1.
L<UR::Context::Root> - A context to represent all the data reachable in the
application's namespace.  It connects the application to external data
sources.

=item 2.
L<UR::Context::Process> - A context to represent the state of data within
the currently running application.  It handles the transfer of data to and
from the Root context, through the object cache, on behalf of the application
code.

=item 3.
L<UR::Context::Transaction> - A context to represent an in-memory transaction
as a diff of the object cache.  The Transaction keeps a list of changes to
objects and is able to revert those changes with C<rollback()>, or apply them
to the underlying context with C<commit()>.

=back

=head1 CONSTRUCTOR

=over 4

=item begin

  my $trans = UR::Context::Transaction->begin();

L<UR::Context::Transaction> instances are created through C<begin()>.  

=back

A L<UR::Context::Root> and L<UR::Context::Process> context will be created
for you when the application initializes.  Additional instances of these
classes are not usually instantiated.

=head1 METHODS

Most of the methods below can be called as either a class or object method
of UR::Context.  If called as a class method, they will operate on the current
context.

=over 4

=item get_current

  my $context = UR::Context::get_current();

Returns the UR::Context instance of whatever is the most currently created
Context.  Can be called as a class or object method.

=item query_underlying_context

  my $should_load = $context->query_underlying_context();
  $context->query_underlying_context(1);

A property of the Context that sets the default value of the C<$should_load>
flag inside C<get_objects_for_class_and_rule> as described below.  Initially,
its value is undef, meaning that during a get(), the Context will query the
underlying data sources only if this query has not been done before.  Setting
this property to 0 will make the Context never query data sources, meaning
that the only objects retrievable are those already in memory.  Setting the
property to 1 means that every query will hit the data sources, even if the
query has been done before.

=item get_objects_for_class_and_rule

  @objs = $context->get_objects_for_class_and_rule(
                        $class_name,
                        $boolexpr,
                        $should_load,
                        $should_return_iterator
                    );

This is the method that serves as the main entry point to the Context behind
the C<get()>, and C<is_loaded()> methods of L<UR::Object>, and C<reload()> method
of UR::Context.

C<$class_name> and C<$boolexpr> are required arguments, and specify the 
target class by name and the rule used to filter the objects the caller
is interested in.  

C<$should_load> is a flag indicating whether the Context should load objects
satisfying the rule from external data sources.  A true value means it should
always ask the relevant data sources, even if the Context believes the
requested data is in the object cache,  A false but defined value means the
Context should not ask the data sources for new data, but only return what
is currently in the cache matching the rule.  The value C<undef> means the
Context should use the value of its query_underlying_context property.  If
that is also undef, then it will use its own judgement about asking the
data sources for new data, and will merge cached and external data as
necessary to fulfill the request.

C<$should_return_iterator> is a flag indicating whether this method should
return the objects directly as a list, or iterator function instead.  If
true, it returns a subref that returns one object each time it is called,
and undef after the last matching object:

  my $iter = $context->get_objects_for_class_and_rule(
                           'MyClass',
                           $rule,
                           undef,
                           1
                       );
  my @objs;
  while (my $obj = $iter->());
      push @objs, $obj;
  }

=item has_changes

  my $bool = $context->has_changes();

Returns true if any objects in the given Context's object cache (or the
current Context if called as a class method) have any changes that haven't
been saved to the underlying context.

=item commit

  UR::Context->commit();

Causes all objects with changes to save their changes back to the underlying
context.  If the current context is a L<UR::Context::Transaction>, then the
changes will be applied to whatever Context the transaction is a part of.
if the current context is a L<UR::Context::Process> context, then C<commit()>
pushes the changes to the underlying L<UR::Context::Root> context, meaning 
that those changes will be applied to the relevant data sources.

In the usual case, where no transactions are in play and all data sources
are RDBMS databases, calling C<commit()> will cause the program to begin
issuing SQL against the databases to update changed objects, insert rows
for newly created objects, and delete rows from deleted objects as part of
an SQL transaction.  If all the changes apply cleanly, it will do and SQL
C<commit>, or C<rollback> if not.

commit() returns true if all the changes have been safely transferred to the
underlying context, false if there were problems.

=item rollback

  UR::Context->rollback();

Causes all objects' changes for the current transaction to be reversed.
If the current context is a L<UR::Context::Transaction>, then the
transactional properties of those objects will be reverted to the values
they had when the transaction started.  Outside of a transaction, object
properties will be reverted to their values when they were loaded from the
underlying data source.  rollback() will also ask all the underlying
databases to rollback.

=item clear_cache

  UR::Context->clear_cache();

Asks the current context to remove all non-infrastructional data from its
object cache.  This method will fail and return false if any object has
changes.

=item resolve_data_source_for_object

  my $ds = $obj->resolve_data_source_for_object();

For the given C<$obj> object, return the L<UR::DataSource> instance that 
object was loaded from or would be saved to.  If objects of that class do
not have a data source, then it will return C<undef>.

=item resolve_data_sources_for_class_meta_and_rule

  my @ds = $context->resolve_data_sources_for_class_meta_and_rule($class_obj, $boolexpr);

For the given class metaobject and boolean expression (rule), return the list of
data sources that will need to be queried in order to return the objects
matching the rule.  In most cases, only one data source will be returned.

=item infer_property_value_from_rule

  my $value = $context->infer_property_value_from_rule($property_name, $boolexpr);

For the given boolean expression (rule), and a property name not mentioned in
the rule, but is a property of the class the rule is against, return the value
that property must logically have.

For example, if this object is the only TestClass object where C<foo> is
the value 'bar', it can infer that the TestClass property C<baz> must
have the value 'blah' in the current context.

  my $obj = TestClass->create(id => 1, foo => 'bar', baz=> 'blah');
  my $rule = UR::BoolExpr->resolve('TestClass', foo => 'bar);
  my $val = $context->infer_property_value_from_rule('baz', $rule);
  # val now is 'blah'

=item object_cache_size_highwater

  UR::Context->object_cache_size_highwater(5000);
  my $highwater = UR::Context->object_cache_size_highwater();

Set or get the value for the Context's object cache pruning high water
mark.  The object cache pruner will be run during the next C<get()> if the
cache contains more than this number of prunable objects.  See the 
L</Object Cache Pruner> section below for more information.

=item object_cache_size_lowwater

  UR::Context->object_cache_size_lowwater(5000);
  my $lowwater = UR::Context->object_cache_size_lowwater();

Set or get the value for the Context's object cache pruning high water
mark.  The object cache pruner will stop when the number of prunable objects
falls below this number.

=item prune_object_cache

  UR::Context->prune_object_cache();

Manually run the object cache pruner.

=item reload

  UR::Context->reload($object);
  UR::Context->reload('Some::Class', 'property_name', value);

Ask the context to load an object's data from an underlying Context, even if
the object is already cached.  With a single parameter, it will use that
object's ID parameters as the basis for querying the data source.  C<reload>
will also accept a class name and list of key/value parameters the same as
C<get>.

=item _light_cache

  UR::Context->_light_cache(1);

Turn on or off the light caching flag.  Light caching alters the behavior 
of the object cache in that all object references in the cache are made weak
by Scalar::Util::weaken().  This means that the application code must keep
hold of any object references it wants to keep alive.  Light caching defaults
to being off, and must be explicitly turned on with this method.

=back

=head1 Custom observer aspects

UR::Context sends signals for observers watching for some non-standard aspects.

=over 2

=item precommit

After C<commit()> has been called, but before any changes are saved to the
data sources.  The only parameters to the Observer's callback are the Context
object and the aspect ("precommit").

=item commit

After C<commit()> has been called, and after an attempt has been made to save
the changes to the data sources.  The parameters to the callback are the
Context object, the aspect ("commit"), and a boolean value indicating whether
the commit succeeded or not.

=item prerollback

After C<rollback()> has been called, but before and object state is reverted.

=item rollback

After C<rollback()> has been called, and after an attempt has been made to
revert the state of all the loaded objects.  The parameters to the callback
are the Context object, the aspect ("rollback"), and a boolean value
indicating whether the rollback succeeded or not.

=back

=head1 Data Concurrency

Currently, the Context is optimistic about data concurrency, meaning that 
it does very little to prevent clobbering data in underlying Contexts during
a commit() if other processes have changed an object's data after the Context
has cached and object.  For example, a database has an object with ID 1 and
a property with value 'bob'.  A program loads this object and changes the
property to 'fred', but does not yet commit().  Meanwhile, another program
loads the same object, changes the value to 'joe' and does commit().  Finally
the first program calls commit().  The final value in the database will be
'fred', and no exceptions will be raised.

As part of the caching behavior, the Context keeps a record of what the
object's state is as it's loaded from the underlying Context.  This is how 
the Context knows what object have been changed during C<commit()>.

If an already cached object's data is reloaded as part of some other query,
data consistency of each property will be checked.  If there are no
conflicting changes, then any differences between the object's initial state
and the current state in the underlying Context will be applied to the
object's notion of what it thinks its initial state is.

In some future release, UR may support additional data concurrency methods
such as pessimistic concurrency: check that the current state of all
changed (or even all cached) objects in the underlying Context matches the
initial state before committing changes downstream.  Or allowing the object
cache to operate in write-through mode for some or all classes.

=head1 Internal Methods

There are many methods in UR::Context meant to be used internally, but are
worth documenting for anyone interested in the inner workings of the Context
code.

=over 4

=item _create_import_iterator_for_underlying_context

  $subref = $context->_create_import_iterator_for_underlying_context(
                          $boolexpr, $data_source, $serial_number
                      );
  $next_obj = $subref->();

This method is part of the object loading process, and is called by
L</get_objects_for_class_and_rule> when it is determined that the requested
data does not exist in the object cache, and data should be brought in from
another, underlying Context.  Usually this means the data will be loaded
from an external data source.

C<$boolexpr> is the L<UR::BoolExpr> rule, usually from the application code.

C<$data_source> is the L<UR::DataSource> that will be used to load data from.

C<$serial_number> is used by the object cache pruner.  Each object loaded
through this iterator will have $serial_number in its C<__get_serial> hashref
key.

It works by first getting an iterator for the data source (the
C<$db_iterator>).  It calls L</_resolve_query_plan_for_ds_and_bxt> to find out
how data is to be loaded and whether this request spans multiple data
sources.  It calls L</__create_object_fabricator_for_loading_template> to get
a list of closures to transform the primary data source's data into UR
objects, and L</_create_secondary_loading_closures> (if necessary) to get
more closures that can load and join data from the primary to the secondary
data source(s).

It returns a subref that works as an iterator, loading and returning objects
one at a time from the underlying context into the current context.  It 
returns undef when there are no more objects to return.

The returned iterator works by first asking the C<$db_iterator> for the next
row of data as a listref.  Asks the secondary data source joiners whether
there is any matching data.  Calls the object fabricator closures to convert
the data source data into UR objects.  If any of the object requires
subclassing, then additional importing iterators are created to handle that.
Finally, the objects matching the rule are returned to the caller one at a
time.

=item _resolve_query_plan_for_ds_and_bxt

  my $query_plan = $context->_resolve_query_plan_for_ds_and_bxt(
                                    $data_source,
                                    $boolexpr_tmpl
                                );
  my($query_plan, @addl_info) = $context->_resolve_query_plan_for_ds_and_bxt(
                                                 $data_source,
                                                 $boolexpr_tmpl
                                             );

When a request is made that will hit one or more data sources,
C<_resolve_query_plan_for_ds_and_bxt> is used to call a method of the same name
on the data source.  It returns a hashref used by many other parts of the
object loading system, and describes what data source to use, how to query
that data source to get the objects, how to use the raw data returned by
the data source to construct objects and how to resolve any delegated
properties that are a part of the rule.

C<$data_source> is a L<UR::DataSource> object ID.  C<$coolexpr_tmpl> is a
L<UR::BoolExpr::Template> object.

In the common case, the query will only use one data source, and this method
returns that data directly.  But if the primary data source sets the 
C<joins_across_data_sources> key on the data structure as may be the case
when a rule involves a delegated property to a class that uses a different
data source, then this methods returns an additional list of data.  For
each additional data source needed to resolve the query, this list will have
three items:

=over 2

=item 1.

The secondary data source ID

=item 2. 

A listref of delegated L<UR::Object::Property> objects joining the primary
data source to this secondary data source.

=item 3. 

A L<UR::BoolExpr::Template> rule template applicable against the secondary
data source

=back

=item _create_secondary_rule_from_primary

  my $new_rule = $context->_create_secondary_rule_from_primary(
                               $primary_rule,
                               $delegated_properties,
                               $secondary_rule_tmpl
                           );

When resolving a request that requires multiple data sources,
this method is used to construct a rule against applicable against the
secondary data source.  C<$primary_rule> is the L<UR::BoolExpr> rule used
in the original query.  C<$delegated_properties> is a listref of
L<UR::Object::Property> objects as returned by
L</_resolve_query_plan_for_ds_and_bxt()> linking the primary to the secondary data
source.  C<$secondary_rule_tmpl> is the rule template, also as returned by 
L</_resolve_query_plan_for_ds_and_bxt()>.

=item _create_secondary_loading_closures

  my($obj_importers, $joiners) = $context->_create_secondary_loading_closures(
                                               $primary_rule_tmpl,
                                               @addl_info);

When reolving a request that spans multiple data sources,
this method is used to construct two lists of subrefs to aid in the request.
C<$primary_rule_tmpl> is the L<UR::BoolExpr::Template> rule template made
from the original rule.  C<@addl_info> is the same list returned by
L</_resolve_query_plan_for_ds_and_bxt>.  For each secondary data source, there
will be one item in the two listrefs that are returned, and in the same
order.

C<$obj_importers> is a listref of subrefs used as object importers.  They
transform the raw data returned by the data sources into UR objects.

C<$joiners> is also a listref of subrefs.  These closures know how the
properties link the primary data source data to the secondary data source.
They take the raw data from the primary data source, load the next row of
data from the secondary data source, and returns the secondary data that
successfully joins to the primary data.  You can think of these closures as
performing the same work as an SQL C<join> between data in different data
sources.

=item _cache_is_complete_for_class_and_normalized_rule

  ($is_cache_complete, $objects_listref) =
      $context->_cache_is_complete_for_class_and_normalized_rule(
                    $class_name, $boolexpr
                );

This method is part of the object loading process, and is called by
L</get_objects_for_class_and_rule> to determine if the objects requested
by the L<UR::BoolExpr> C<$boolexpr> will be found entirely in the object
cache.  If the answer is yes then C<$is_cache_complete> will be true.
C<$objects_listef> may or may not contain objects matching the rule from
the cache.  If that list is not returned, then
L</get_objects_for_class_and_rule> does additional work to locate the
matching objects itself via L</_get_objects_for_class_and_rule_from_cache>

It does its magic by looking at the C<$boolexpr> and loosely matching it
against the query cache C<$UR::Context::all_params_loaded>

=item _get_objects_for_class_and_rule_from_cache

  @objects = $context->_get_objects_for_class_and_rule_from_cache(
                           $class_name, $boolexpr
                       );

This method is called by L</get_objects_for_class_and_rule> when 
L<_cache_is_complete_for_class_and_normalized_rule> says the requested
objects do exist in the cache, but did not return those items directly.

The L<UR::BoolExpr> C<$boolexpr> contains hints about how the matching data
is likely to be found.  Its C<_context_query_strategy> key will contain
one of three values

=over 2

=item 1. all

This rule is against a class with no filters, meaning it should return every
member of that class.  It calls C<$class-E<gt>all_objects_loaded> to extract
all objects of that class in the object cache.

=item 2. id

This rule is against a class and filters by only a single ID, or a list of
IDs.  The request is fulfilled by plucking the matching objects right out
of the object cache.

=item 3. index

This rule is against one more more non-id properties.  An index is built
mapping the filtered properties and their values, and the cached objects
which have those values.  The request is fulfilled by using the index to
find objects matching the filter.

=item 4. set intersection

This is a group-by rule and will return a ::Set object.

=back

=item _loading_was_done_before_with_a_superset_of_this_params_hashref

  $bool = $context->_loading_was_done_before_with_a_superset_of_this_params_hashref(
                        $class_name,
                        $params_hashref
                    );

This method is used by L</_cache_is_complete_for_class_and_normalized_rule>
to determine if the requested data was asked for previously, either from a
get() asking for a superset of the current request, or from a request on
a parent class of the current request.

For example, if a get() is done on a class with one param:

  @objs = ParentClass->get(param_1 => 'foo');

And then later, another request is done with an additional param:

  @objs2 = ParentClass->get(param_1 => 'foo', param_2 => 'bar');

Then the first request must have returned all the data that could have
possibly satisfied the second request, and so the system will not issue
a query against the data source.

As another example, given those two previously done queries, if another
get() is done on a class that inherits from ParentClass

  @objs3 = ChildClass->get(param_1 => 'foo');

again, the first request has already loaded all the relevant data, and
therefore won't query the data source.

=item _sync_databases

  $bool = $context->_sync_databases();

Starts the process of committing all the Context's changes to the external
data sources.  _sync_databases() is the workhorse behind L</commit>.

First, it finds all objects with changes.  Checks those changed objects
for validity with C<$obj-E<gt>invalid>.  If any objects are found invalid,
then _sync_databases() will fail.  Finally, it bins all the changed objects
by data source, and asks each data source to save those objects' changes.
It returns true if all the data sources were able to save the changes,
false otherwise.

=item _reverse_all_changes

  $bool = $context->_reverse_all_changes();

_reverse_all_changes() is the workhorse behind L</rollback>.  

For each class, it goes through each object of that class.  If the object
is a L<UR::Object::Ghost>, representing a deleted object, it converts the
ghost back to the live version of the object.  For other classes, it makes
a list of properties that have changed since they were loaded (represented
by the C<db_committed> hash key in the object), and reverts those changes
by using each property's accessor method.

=back

=head1 The Object Cache

The object cache is integral to the way the Context works, and also the main
difference between UR and other ORMs.  Other systems do no caching and
require the calling application to hold references to any objects it 
is interested in.  Say one part of the app loads data from the database and
gives up its references, then if another part of the app does the same or
similar query, it will have to ask the database again.

UR handles caching of classes, objects and queries to avoid asking the data
sources for data it has loaded previously.  The object cache is essentially
a software transaction that sits above whatever database transaction is
active.  After objects are loaded, any changes, creations or deletions exist
only in the object cache, and are not saved to the underlying data sources
until the application explicitly requests a commit or rollback.  

Objects are returned to the application only after they are inserted into
the object cache.  This means that if disconnected parts of the application
are returned objects with the same class and ID, they will have references
to the same exact object reference, and changes made in one part will be
visible to all other parts of the app.  An unchanged object can be removed
from the object cache by calling its C<unload()> method.

Since changes to the underlying data sources are effectively delayed, it is
possible that the application's notion of the object's current state does
not match the data stored in the data source.  You can mitigate this by using
the C<load()> class or object method to fetch the latest data if it's a
problem.  Another issue to be aware of is if multiple programs are likely
to commit conflicting changes to the same data, then whichever applies its
changes last will win; some kind of external locking needs to be applied.
Finally, if two programs attempt to insert data with the same ID columns
into an RDBMS table, the second application's commit will fail, since that
will likely violate a constraint.

=head2 Object Change Tracking

As objects are loaded from their data sources, their properties are
initialized with the data from the query, and a copy of the same data is
stored in the object in its C<db_committed> hash key.  Anyone can ask the
object for a list of its changes by calling C<$obj-E<gt>changed>.
Internally, changed() goes through all the object's properties, comparing
the current values in the object's hash with the same keys under
'db_committed'.  

Objects created through the C<create()> class method have no 'db_committed',
and so the object knows it it a newly created object in this context.

Every time an object is retrieved with get() or through an iterator, it is
assigned a serial number in its C<__get_serial> hash key from the
C<$UR::Context::GET_SERIAL> counter.  This number is unique and increases
with each get(), and is used by the L</Object Cache Pruner> to expire the
least recently requested data.

Objects also track what parameters have been used to get() them in the hash
C<$obj-E<gt>{__load}>.  This is a copy of the data in
C<$UR::Context::all_params_loaded-E<gt>{$template_id}>.  For each rule
ID, it will have a count of the number of times that rule was used in a get().

=head2 Deleted Objects and Ghosts

Calling delete() on an object is tracked in a different way.  First, a new
object is created, called a ghost.  Ghost classes exist for every
class in the application and are subclasses of L<UR::Object::Ghost>.  For
example, the ghost class for MyClass is MyClass::Ghost.  This ghost object
is initialized with the data from the original object.  The original object
is removed from the object cache, and is reblessed into the UR::DeletedRef
class.  Any attempt to interact with the object further will raise an
exception.

Ghost objects are not included in a get() request on the regular class,
though the app can ask for them specifically using
C<MyClass::Ghost-E<gt>get(%params)>.

Ghost classes do not have ghost classes themselves.  Calling create() or
delete() on a Ghost class or object will raise an exception.  Calling other
methods on the Ghost object that exist on the original, live class will
delegate over to the live class's method.

=head2 all_objects_are_loaded

C<$UR::Context::all_objects_are_loaded> is a hashref keyed by class names.
If the value is true, then L</_cache_is_complete_for_class_and_normalized_rule>
knows that all the instances of that class exist in the object cache, and
it can avoid asking the underlying context/datasource for that class' data.

=head2 all_params_loaded

C<$UR::Context::all_params_loaded> is a two-level hashref.  The first level
is template (L<UR::BoolExpr::Template>) IDs.  The second level is rule
(L<UR::BoolExpr>) IDs.  The values are how many times that class and rule
have been involved in a get().  This data is used by
L</_loading_was_done_before_with_a_superset_of_this_params_hashref>
to determine if the requested data will be found in the object cache for
non-id queries.

=head2 all_objects_loaded

C<$UR::Context::all_objects_loaded> is a two-level hashref.  The first level
is class names.  The second level is object IDs.  Every time an object is
created, defined or loaded from an underlying context, it is inserted into
the C<all_objects_loaded> hash.  For queries involving only ID properties,
the Context can retrieve them directly out of the cache if they appear there.

The entire cache can be purged of non-infrastructional objects by calling
L</clear_cache>.

=head2 Object Cache Pruner

The default Context behavior is to cache all objects it knows about for the
entire life of the process.  For programs that churn through large amounts 
of data, or live for a long time, this is probably not what you want.  

The Context has two settings to loosely control the size of the object
cache.  L</object_cache_size_highwater> and L</object_cache_size_lowwater>.
As objects are created and loaded, a count of uncachable objects is kept
in C<$UR::Context::all_objects_cache_size>.  The first part of 
L</get_objects_for_class_and_rule> checks to see of the current size is
greater than the highwater setting, and call L</prune_object_cache> if so.

prune_object_cache() works by looking at what C<$UR::Context::GET_SERIAL>
was the last time it ran, and what it is now, and making a guess about 
what object serial number to use as a guide for removing objects by starting
at 10% of the difference between the last serial and the current value,
called the target serial.


It then starts executing a loop as long as C<$UR::Context::all_objects_cache_size>
is greater than the lowwater setting.  For each uncachable object, if its
C<__get_serial> is less than the target serial, it is weakened from any
L<UR::Object::Index>es it may be a member of, and then weakened from the
main object cache, C<$UR::Context::all_objects_loaded>.

The application may lock an object in the cache by calling C<__strengthen__> on
it,  Likewise, the app may hint to the pruner to throw away an object as 
soon as possible by calling C<__weaken__>.

=head1 SEE ALSO

L<UR::Context::Root>, L<UR::Context::Process>, L<UR::Object>,
L<UR::DataSource>, L<UR::Object::Ghost>, L<UR::Observer>

=cut

