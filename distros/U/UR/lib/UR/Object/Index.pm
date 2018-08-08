# Index for cached objects.

package UR::Object::Index;
our $VERSION = "0.47"; # UR $VERSION;
use base qw(UR::Object);

use strict;
use warnings;
require UR;

use List::MoreUtils;

# wrapper for one of the ID properties to make it less ugly

sub indexed_property_names
{
    my $self = shift;
    unless (exists $self->{indexed_property_names}) {
        no warnings;
        $self->{indexed_property_names} = [ split(/,/,$self->{indexed_property_string}) ];
    }
    return @{$self->{indexed_property_names}};
}

sub indexed_property_numericness {
    my $self = shift;
    unless (exists $self->{indexed_property_numericness}) {
        my $class_meta = $self->indexed_class_name->__meta__;
        my @is_numeric = map {
                            my @props = $class_meta->_concrete_property_meta_for_class_and_name($_);
                            @props == 1
                                ? $props[0]->is_numeric
                                : 0     # multiple ID properties are treated as a string
                        }
                        $self->indexed_property_names;

        $self->{indexed_property_numericness} = \@is_numeric;
    }
    return @{ $self->{indexed_property_numericness} };
}


# the only non-id property has an accessor...

sub data_tree
{
    if (@_ > 1)
    {
        my $old = $_[0]->{data_tree};
        my $new = $_[1];
        if ($old ne $new)
        {
            $_[0]->{data_tree} = $new;
            $_[0]->__signal_change__('data_tree', $old, $new);
        }
        return $new;
    }
    return $_[0]->{data_tree};
}

# override create to initilize the index

sub create {
    my $class = shift;
    
    # NOTE: This is called from one location in UR::Context and relies
    # on all properties including the ID being specifically defined.
    
    my $self = $UR::Context::current->_construct_object($class, @_);
    return unless $self;
    $self->{data_tree} ||= {};   
 
    $self->_build_data_tree;
    $self->_setup_change_subscription;
    
    $self->__signal_change__("create");        
    return $self;
}

# this does a lookup as efficiently as possible

sub get_objects_matching
{
    my $self = shift;
    my @values = @_;

    # The hash access below generates warnings
    # where undef is a value.  Ignore these.
    no warnings 'uninitialized';

    my @hr = ($self->{data_tree});
    my @is_numeric = $self->indexed_property_numericness;

    my $iter = List::MoreUtils::each_array(@values, @is_numeric);
    while(my($value, $is_numeric) = $iter->())
    {               
        my $value_ref = ref($value);
        if($value_ref eq "HASH")
        {
            # property => { operator => "not like", value => "H~_WGS%", escape "~" }
            if (my $op = $value->{operator})
            {
                $op = lc($op);
                my $not = 0;
                if ($op =~ m/^(!|not\s*)(.*)/) {
                    $not = 1;
                    $op = $2;
                }

                my $result;

                if ($op eq '=' and !$not) {
                   @hr = grep { $_ } map { $_->{$value->{'value'}} } @hr;
                }
                elsif ($op eq 'like')
                {
                    my $comparison_value = $value->{value};                        
                    my $escape = $value->{escape};
                    
                    my $regex = 
                        UR::BoolExpr::Template::PropertyComparison::Like->
                            comparison_value_and_escape_character_to_regex(
                                $comparison_value,
                                $escape
                            );
                        
                    my @thr;
                    if ($not)
                    {
                        # Get the values using the regular or negative match op.
                        foreach my $h (@hr) {
                            foreach my $k (sort keys %$h) {
                                next if $k eq '';  # an earlier undef value got saved as an empty string here
                                if($k !~ /$regex/) {
                                    push @thr, $h->{$k};
                                }
                            }
                        }
                    }
                    else
                    {
                        # Standard positive match
                        for my $h (@hr) {
                            for my $k (sort keys %$h) {
                                next if $k eq '';  # an earlier undef value got saved as an empty string here
                                if ($k =~ /$regex/) {
                                    push @thr, $h->{$k};
                                }
                            }
                        }
                    }
                    @hr = grep { $_ } @thr;
                } 
                elsif ($op eq 'in' and !$not)
                {                
                    $value = $value->{value};
                    my $has_null = ( (grep { length($_) == 0 } @$value) ? 1 : 0);
                    if ($has_null) {
                        @hr = grep { $_ } map { @$_{@$value} } @hr;
                    } else {
                        my @value = grep { length($_) > 0 } @$value;
                        @hr = grep { $_ } map { @$_{@value} } @hr;
                    }
                }
                elsif ($op eq 'in' and $not)
                {                
                    $value = $value->{value};
                    
                    # make a hash if we got an array as a value
                    #die ">@$value<" if ref($value) eq "ARRAY";
                    $value = { map { $_ => 1 } @$value } if ref($value) eq "ARRAY";
                    
                    # if there is a single null, the not in clause will be false
                    if ($value->{""}) {
                        @hr = ();
                    }
                    else {
                        # return everything NOT in the hash
                        my @thr;
                        for my $h (@hr) {
                            for my $k (sort keys %$h) {
                                next unless length($k);                                
                                unless ($value->{$k}) {
                                    push @thr, $h->{$k};
                                }
                            }
                        }
                        @hr = grep { $_ } @thr;
                    }

                } elsif ($op eq 'isa') {
                    my @thr;
                    foreach my $h ( @hr ) {
                        foreach my $k ( keys %$h) {
                            if ($k->isa($value->{value}) xor $not) {
                                push @thr, $h->{$k};
                            }
                        }
                    }
                    @hr = grep { $_ } @thr;

                } elsif ($op eq 'true' or $op eq 'false') {
                    $not = (( $op eq 'true' && $not) or ($op eq 'false' && !$not));
                    my @thr;
                    foreach my $h ( @hr ) {
                        foreach my $k ( keys %$h ) {
                            if ($k xor $not) {
                                push @thr, $h->{$k};
                            }
                        }
                    }
                    @hr = grep { $_ } @thr;

                } elsif ($not and ($op eq '=' or !$op)) {
                    my @thr;
                    foreach my $h (@hr) {
                        foreach my $k (sort keys %$h) {
                            # An empty string for $k means the object's value was loaded as NULL
                            # and we want things like 0 != NULL to be true to match the SQL that
                            # gets generated for the same rule
                            my $t = ($k eq '')
                                    ||
                                    ($is_numeric
                                        ? $k != $value->{value}
                                        : $k ne $value->{value});
                            if ($t) {
                                push @thr, $h->{$k};
                            }
                        }
                    }
                    @hr = grep { $_ } @thr;
                } elsif($op eq '>') {
                    my @thr;
                    foreach my $h (@hr) {
                        foreach my $k (keys %$h) {
                            next if $k eq '';  # an earlier undef value got saved as an empty string here
                            my $t = $is_numeric
                                        ? $k > $value->{value}
                                        : $k gt $value->{value};
                            if ($t xor $not) {
                                push @thr, $h->{$k};
                            }
                        }
                    }
                    @hr = grep { $_ } @thr;
                } elsif($op eq '<') {
                    my @thr;
                    foreach my $h (@hr) {
                        foreach my $k (keys %$h) {
                            next if $k eq '';  # an earlier undef value got saved as an empty string here
                            my $t = $is_numeric
                                        ? $k < $value->{value}
                                        : $k lt $value->{value};
                            if ($t xor $not) {
                                push @thr, $h->{$k};
                            }
                        }
                    }
                    @hr = grep { $_ } @thr;
                } elsif($op eq '>=') {
                    my @thr;
                    foreach my $h (@hr) {
                        foreach my $k (keys %$h) {
                            next if $k eq '';  # an earlier undef value got saved as an empty string here
                            my $t = $is_numeric
                                        ? $k >= $value->{value}
                                        : $k ge $value->{value};
                            if ($t xor $not) {
                                push @thr, $h->{$k};
                            }
                        }
                    }
                    @hr = grep { $_ } @thr;
                } elsif($op eq '<=') {
                    my @thr;
                    foreach my $h (@hr) {
                        foreach my $k (keys %$h) {
                            next if $k eq '';  # an earlier undef value got saved as an empty string here
                            my $t = $is_numeric
                                        ? $k <= $value->{value}
                                        : $k le $value->{value};
                            if ($t xor $not) {
                                push @thr, $h->{$k};
                            }
                        }
                    }
                    @hr = grep { $_ } @thr;
                } elsif($op eq 'ne') {
                    my @thr;
                    foreach my $h (@hr) {
                        foreach my $k (sort keys %$h) {
                            next if $k eq '';  # an earlier undef value got saved as an empty string here
                            if($k ne $value->{value} xor $not) {
                                push @thr, $h->{$k};
                            }
                        }
                    }
                    @hr = grep { $_ } @thr;                        
                } elsif($op eq '<>') {
                    my @thr;
                    foreach my $h (@hr) {
                        foreach my $k (sort keys %$h) {
                            if((length($k) and length($value->{value}) and $k ne $value->{value}) xor $not) {
                                push @thr, $h->{$k};
                            }
                        }
                    }
                    @hr = grep { $_ } @thr;                        
                } elsif($op eq 'between') {
                    my @thr;
                    my ($min,$max) = @{ $value->{value} };
                    foreach my $h (@hr) {
                        foreach my $k (sort keys %$h) {
                            next if $k eq '';
                            my $t = $is_numeric
                                        ? ( $k >= $min and $k <= $max )
                                        : ( $k ge $min and $k le $max );
                            if ($t xor $not) {
                                push @thr, $h->{$k};
                            }
                        }
                    }
                    @hr = grep { $_ } @thr;                                      
                } else {
                    use Data::Dumper;
                    Carp::confess("Unknown operator in key-value pair used in index lookup for index " . Dumper($value));
                }
            }
            else
            {
                Carp::confess("No operator specified in hashref value!" . Dumper($value));
            }
        }
        elsif (not $value_ref)
        {
            # property => value
            @hr = grep { $_ } map { $_->{$value} } @hr;
        }
        elsif ($value_ref eq "ARRAY")
        {
            # property => [ v1, v2, v3]
            @hr = grep { $_ } map { @$_{@$value} } @hr;
        }
    }
    return (map { values(%$_) } @hr);
}


# private methods

sub _build_data_tree
{        
    my $self = $_[0];
    
    my @indexed_property_names = $self->indexed_property_names;
    my $hr_base = $self->{data_tree};
    
    # _remove_object in bulk.
    %$hr_base = ();
    my $indexed_class_name = $self->indexed_class_name;
    
    if (my @bad_properties = 
        grep { not $indexed_class_name->can($_) }
        @indexed_property_names
    ) {
        Carp::confess(
            "Attempt to index $indexed_class_name by properties which "
            . "do not function:  @bad_properties"
        );
    }
    
    # _add_object in bulk.
    for my $object ($UR::Context::current->all_objects_loaded($indexed_class_name)) {
        my(@values, $hr);
        if (@indexed_property_names) {
            @values = map { my $val = $object->$_; defined $val ? $val : undef } @indexed_property_names;
            @values = (undef) unless(@values);
        }
        $hr = $hr_base;
        for my $value (@values)
        {
            no warnings 'uninitialized';  # in case $value is undef
            $hr->{$value} ||= {};
            $hr = $hr->{$value};
        }
        my $obj_id = $object->id;
        $hr->{$obj_id} = $object;
        if (Scalar::Util::isweak($UR::Context::all_objects_loaded->{$indexed_class_name}->{$obj_id})) {
            Scalar::Util::weaken($hr->{$obj_id});
        }
    }
}

# FIXME maybe objects in an index should always be weakend?
sub weaken_reference_for_object {
    my $self = shift;
    my $object = shift;
    my $overrides = shift;   # FIXME copied from _remove_object - what's this for?

    no warnings;
    my @indexed_property_names = $self->indexed_property_names;
    my @values = 
        map
        {
            ($overrides && exists($overrides->{$_}))
            ?
            $overrides->{$_}
            :
            $object->$_
        }
        @indexed_property_names;

    my $hr = $self->{data_tree};
    my $value;
    for $value (@values)
    {
        $hr = $hr->{$value};
        return unless $hr;
    }
    Scalar::Util::weaken($hr->{$object->id});
}
 
    
sub _setup_change_subscription
{
    
    my $self = shift;
    
    
    my $indexed_class_name = $self->indexed_class_name;        
    my @indexed_property_names = $self->indexed_property_names;
    
    if (1) {            
        # This is a new indexing strategy which pays at index creation time instead of use.
        
        my @properties_to_watch = (@indexed_property_names, qw/create delete load unload/);
        #print "making index $self->{id}\n";
        for my $class ($indexed_class_name, @{ $UR::Object::Type::_init_subclasses_loaded{$indexed_class_name} }) {
            for my $property (@properties_to_watch) {
                my $index_list = $UR::Object::Index::all_by_class_name_and_property_name{$class}{$property} ||= [];
                #print " adding to $class\n";
                push @$index_list, $self;
            }
        }
        
        return 1;
    }
    
    # This will be ignored for now.
    # If the __signal_change__/subscription system is improved, it may be better to go back?
    
    my %properties_to_watch = map { $_ => 1 } (@indexed_property_names, qw/create delete load unload/);
    
    $self->{_get_change_subscription} = $indexed_class_name->create_subscription(            
        callback => 
            sub
            {            
                my ($changed_object, $changed_property, $old_value, $new_value) = @_;
                
                #print "got change $changed_property for $indexed_class_name: $changed_object->{id}: @_\n";
                
                # ensure we don't track changes for subclasses
                #return() unless ref($changed_object) eq $indexed_class_name;
                
                # ensure we only add/remove for selected method calls
                return() unless $properties_to_watch{$_[1]};
                
                #print "changing @_\n";
                
                $self->_remove_object(
                    $changed_object, 
                    { $changed_property => $old_value }
                ) if ($changed_property ne 'create' 
                      and $changed_property ne 'load'
                      and $changed_property ne '__define__');
                
                $self->_add_object($changed_object) if ($changed_property ne 'delete' and $changed_property ne 'unload');
            },
        note => "index monitor " . $self->id,
        priority => 0,
    );        
}

sub _get_change_subscription
{        
    # accessor for the change subscription
    $_[0]->{_get_change_subscription} = $_[1] if (@_ > 1);
    return $_[0]->{_get_change_subscription};
}

sub _remove_object($$)
{
    no warnings;
    
    my ($self, $object, $overrides) = @_;
    my @indexed_property_names = $self->indexed_property_names;
    my @values = 
        map 
        { 
            ($overrides && exists($overrides->{$_}))
            ? 
            $overrides->{$_} 
            : 
            $object->$_ 
        }
        @indexed_property_names;
        
    my $hr = $self->{data_tree};
    my $value;
    for $value (@values)
    {            
        $hr = $hr->{$value};
    }
    delete $hr->{$object->id};
}

sub _add_object($$)
{
    # We get warnings when undef converts into an empty string.
    # For efficiency, we turn warnings off in this method.
    no warnings;
    
    my ($self, $object) = @_;
    my @indexed_property_names = $self->indexed_property_names;
    my @values = map { $object->$_ } @indexed_property_names;        
    my $hr = $self->{data_tree};
    my $value;
    for $value (@values)
    {            
        $hr->{$value} ||= {};
        $hr = $hr->{$value};
    }
    $hr->{$object->id} = $object;        
    
    # This is the exact formula used elsewhere.  TODO: refactor, base on class meta
    if ($UR::Context::light_cache and substr($self->indexed_class_name,0,5) ne 'App::') {
        Scalar::Util::weaken($hr->{$object->id});
    }
}

sub _all_objects_indexed {
    my $self = shift;

    my @object_hashes = ( $self->{data_tree} );

    # Recurse one level deep for each indexed property name
    # and collect the hashes at that level
    foreach ( $self->indexed_property_names ) {
        my @new_object_hashes;
        while (my $hr = shift @object_hashes) {
            push @new_object_hashes, values(%$hr);
        }
        @object_hashes = @new_object_hashes;
    }

    # The final level's values are all the objects
    return map { values %$_ } @object_hashes;
}

1;

=pod

=head1 NAME

UR::Object::Index - Indexing system for retrieving objects by non-id properties

=head1 DESCRIPTION

This class implements an indexing system for objects to retrieve them quickly
by properties other than their ID properties.  Their existence and use is 
managed by the Context as needed, and end-users should never need to interact
with UR::Object::Index instances.

Internally, they are a container for objects of the same class and a set of 
properties used to look them up.  Each time a get() is performed on a new set
of non-id properties, a new Index is created to handle the request for
objects which may already exist in the object cache,

The data_tree inside the Index is a multi-level hash.  The levels are in the
same order as the properties in the get request.  At each level, the hash
keys are the values that target property has.  For that level and key, all the
objects inside have the same value for that property.  A get() by three non-id
properties will have a 3-level hash.

=cut
