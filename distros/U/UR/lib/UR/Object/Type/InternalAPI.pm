package UR::Object::Type;
use warnings;
use strict;

require UR;
our $VERSION = "0.47"; # UR $VERSION;

use Sys::Hostname;
use Cwd;
use Scalar::Util qw(blessed);
use Sub::Name;

our %meta_classes;
our $bootstrapping = 1;
our @partially_defined_classes;
our $pwd_at_compile_time = cwd();

# each method which caches data on the class for properties stores its hash key here
# when properties mutate this is cleared
our @cache_keys;

sub property_metas {
    my $self = $_[0];
    my @a = map { $self->property_meta_for_name($_) } $self->all_property_names();    
    return @a;
}

# Some accessor methods drawn from properties need to be overridden.
# Some times because they need to operate during bootstrapping.  Sometimes
# because the method needs some special behavior like sorting or filtering.
# Sometimes to optimize performance or cache data

# This needs to remain overridden to enforce the restriction on callers
sub data_source {
    my $self = shift;
    my $ds = $self->data_source_id(@_);
    
    return undef unless $ds;
    local $@;
    my $obj = eval { UR::DataSource->get($ds) || $ds->get() };

    return $obj;
}

sub ancestry_class_metas {
    #my $rule_template = UR::BoolExpr::Template->resolve(__PACKAGE__,'id');

    # Can't use the speed optimization of getting a template here.  Using the Context to get 
    # objects here causes endless recursion during bootstrapping
    map { __PACKAGE__->get($_) } shift->ancestry_class_names;
    #return map { $UR::Context::current->get_objects_for_class_and_rule(__PACKAGE__, $_) }
    #       map { $rule_template->get_rule_for_values($_) }
    #       shift->ancestry_class_names;

}

our $PROPERTY_META_FOR_NAME_TEMPLATE;
push @cache_keys, '_property_meta_for_name';
sub property_meta_for_name {
    my ($self, $property_name) = @_;

    return unless $property_name;

    if (index($property_name,'.') != -1) {
        my @chain = split(/\./,$property_name);
        my $last_class_meta = $self;
        my $last_class_name = $self->id;
        my @pmeta;
        for my $full_link (@chain) {
            my ($link) = ($full_link =~ /^([^\-\?]+)/);
            my $property_meta = $last_class_meta->property_meta_for_name($link);
            push @pmeta, $property_meta;
            last if $link eq $chain[-1];
            my @joins = UR::Object::Join->resolve_chain($last_class_name, $link);
            return unless @joins;

            $last_class_name = $joins[-1]{foreign_class};
            $last_class_meta = $last_class_name->__meta__;
        }
        return unless (@pmeta and $pmeta[-1]);
        return @pmeta if wantarray;
        return $pmeta[-1];
    }

    my $pos = index($property_name,'-'); 
    if ($pos != -1) {
        $property_name = substr($property_name,0,$pos);
    }

    if (exists($self->{'_property_meta_for_name'}) and $self->{'_property_meta_for_name'}->{$property_name}) {
       return $self->{'_property_meta_for_name'}->{$property_name};
    }
    $PROPERTY_META_FOR_NAME_TEMPLATE ||= UR::BoolExpr::Template->resolve('UR::Object::Property', 'class_name', 'property_name');

    my $property;
    for my $class ($self->class_name, $self->ancestry_class_names) {
        my $rule = $PROPERTY_META_FOR_NAME_TEMPLATE->get_rule_for_values($class, $property_name);
        $property = $UR::Context::current->get_objects_for_class_and_rule('UR::Object::Property', $rule);
        if ($property) {
            return $self->{'_property_meta_for_name'}->{$property_name} = $property;
        }
    }
    return;
}

# A front-end for property_meta_for_name, but
# will translate the generic 'id' property into the class' real ID property,
# if it's not called 'id'
sub _concrete_property_meta_for_class_and_name {
    my($self,$property_name) = @_;

    my @property_metas = $self->property_meta_for_name($property_name);

    for (my $i = 0; $i < @property_metas; $i++) {
        if ($property_metas[$i]->id eq "UR::Object\tid"
            and $property_name !~ /\./) #If we're looking at a foreign object's id, can't replace with our own
        {
            # This is the generic id property.  Remap it to the class' real ID property name
            my @id_properties = $self->id_property_names;
            if (@id_properties == 1 and $id_properties[0] eq 'id') {
                next; # this class doesn't have any other ID properties
            }
            #return map { $self->_concrete_property_meta_for_class_and_name($_) } @id_properties;
            my @remapped = map { $self->_concrete_property_meta_for_class_and_name($_) } @id_properties;
            splice(@property_metas, $i, 1, @remapped);
        }
    }
    return @property_metas;
}



sub _flatten_property_name {
    my ($self, $name) = @_;
    
    my $flattened_name = '';
    my @add_keys;
    my @add_values;

    my @meta = $self->property_meta_for_name($name);
    for my $meta (@meta) {
        my @joins = $meta->_resolve_join_chain();
        for my $join (@joins) {
            if ($flattened_name) {
                $flattened_name .= '.'; 
            }
            $flattened_name .= $join->{source_name_for_foreign};
            if (my $where = $join->{where}) {
                $flattened_name .= '-' . $join->sub_group_label; 
                my $join_class = $join->{foreign_class};
                my $bx2 = UR::BoolExpr->resolve($join_class,@$where);
                my $bx2_flat = $bx2->flatten(); # recurses through this
                my ($bx2_flat_template, @values) = $bx2_flat->template_and_values();
                my @keys = @{ $bx2_flat_template->{_keys} };
                for my $key (@keys) {
                    next if substr($key,0,1) eq '-';
                    my $full_key = $flattened_name . '?.' . $key;
                    push @add_keys, $full_key;
                    push @add_values, shift @values;
                }
                if (@values) {
                    Carp:confess("Unexpected mismatch in count of keys and values!");
                }
            }
        }
    }
    return ($flattened_name, \@add_keys, \@add_values);
};

our $DIRECT_ID_PROPERTY_METAS_TEMPLATE;
sub direct_id_property_metas {
    my $self = _object(shift);
    $DIRECT_ID_PROPERTY_METAS_TEMPLATE ||= UR::BoolExpr::Template->resolve('UR::Object::Property', 'class_name', 'property_name', 'is_id >=');
    my $class_name = $self->class_name;
    my @id_property_objects =
        map { $UR::Context::current->get_objects_for_class_and_rule('UR::Object::Property', $_) }
        map { $DIRECT_ID_PROPERTY_METAS_TEMPLATE->get_rule_for_values($class_name, $_, 0) }
        @{$self->{'id_by'}};

    my $sort_sub = sub ($$) { return $_[0]->is_id cmp $_[1]->is_id };
    @id_property_objects = sort $sort_sub @id_property_objects;
    if (@id_property_objects == 0) {
        @id_property_objects = $self->property_meta_for_name("id");
    }
    return @id_property_objects;
}

sub parent_class_names {
    my $self = shift;   
    return @{ $self->{is} };
}


# If $property_name represents an alias-type property (via => '__self__'),
# then return a string with all the aliases removed
push @cache_keys, '_resolve_property_aliases';
sub resolve_property_aliases {
    my($self,$property_name) = @_;

    return unless $property_name;
    unless ($self->{'_resolve_property_aliases'} && $self->{'_resolve_property_aliases'}->{$property_name}) {
        $self->{'_resolve_property_aliases'} ||= {};

        my @property_metas = $self->property_meta_for_name($property_name);
        my @property_names;
        if (@property_metas) {
            @property_names = map { $_->alias_for } @property_metas;
        } else {
            # there was a problem resolving the chain of properties
            # This happens in the case of an object accessor (is => 'Some::Class') without an id_by
            my @split_names = split(/\./,$property_name);
            my $name_count = @split_names;
            my $prop_meta = $self->property_meta_for_name(shift @split_names);
            return unless $prop_meta;
            my $foreign_class = $prop_meta->data_type && eval { $prop_meta->data_type->__meta__};
            return unless $foreign_class;
            @property_names = ( $prop_meta->alias_for, $foreign_class->resolve_property_aliases(join('.', @split_names)));
            unless (@property_names >= $name_count) {
                Carp::croak("Some parts from property '$property_name' of class ".$self->class_name
                            . " didn't resolve");
            }
        }
        $self->{'_resolve_property_aliases'}->{$property_name} = join('.', @property_names);
    }
    return $self->{'_resolve_property_aliases'}->{$property_name};
}


push @cache_keys, '_id_property_names';
sub id_property_names {
    # FIXME Take a look at id_property_names and all_id_property_names.  
    # They look extremely similar, but tests start dying if you replace one
    # with the other, or remove both and rely on the property's accessor method

    my $self = _object(shift);

    unless ($self->{'_id_property_names'}) {
        my @id_by;
        unless ($self->{id_by} and @id_by = @{ $self->{id_by} }) {
            foreach my $parent ( @{ $self->{'is'} } ) {
                my $parent_class = $parent->class->__meta__;
                next unless $parent_class;
                @id_by = $parent_class->id_property_names;
                last if @id_by;
            }
        }
        $self->{'_id_property_names'} = \@id_by;
    }
    return @{$self->{'_id_property_names'}};
}

push @cache_keys, '_all_id_property_names';
sub all_id_property_names {
    # return shift->id_property_names(@_); This makes URT/t/99_transaction.t fail
    my $self = shift;
    unless ($self->{_all_id_property_names}) {
        my ($tmp,$last) = ('','');
        $self->{_all_id_property_names} = [
            grep { $tmp = $last; $last = $_; $tmp ne $_ }
            sort 
            map { @{ $_->{id_by} } } 
            map { __PACKAGE__->get($_) }
            ($self->class_name, $self->ancestry_class_names)
        ];
    }
    return @{ $self->{_all_id_property_names} };
}

sub direct_id_column_names {
    my $self = _object(shift);
    my @id_column_names =
        map { $_->column_name }
        $self->direct_id_property_metas;
    return @id_column_names;
}


sub ancestry_table_names {
    my $self = _object(shift);
    my @inherited_table_names =
        grep { defined($_) }
        map { $_->table_name }
        $self->ancestry_class_metas;
    return @inherited_table_names;
}

sub all_table_names {
    my $self = _object(shift);
    my @table_names =
        grep { defined($_) }
        ( $self->table_name, $self->ancestry_table_names );
    return @table_names;
}

sub first_table_name {
    my $self = _object(shift);
    if ($self->{_first_table_name}) {
        return $self->{first_table_name};
    }

    my @classes = ($self);
    while(@classes) {
        my $co = shift @classes;
        if (my $table_name = $co->table_name) {
            $self->{first_table_name} = $table_name;
            return $table_name;
        }
        my @parents = map { $_->__meta__ } @{$co->{'is'}};
        push @classes, @parents;
    }
    return;
}
    

sub ancestry_class_names {
    my $self = shift;
    
    if ($self->{_ordered_inherited_class_names}) {
        return @{ $self->{_ordered_inherited_class_names} };
    }
    
    my $ordered_inherited_class_names = $self->{_ordered_inherited_class_names} = [ @{ $self->{is} } ];    
    my @unchecked = @$ordered_inherited_class_names;
    my %seen = ( $self->{class_name} => 1 );
    while (my $ancestor_class_name = shift @unchecked) {
        next if $seen{$ancestor_class_name};
        $seen{$ancestor_class_name} = 1;
        my $class_meta = $ancestor_class_name->__meta__;
        Carp::confess("Can't find meta for $ancestor_class_name!") unless $class_meta;
        next unless $class_meta->{is};
        push @$ordered_inherited_class_names, @{ $class_meta->{is} };
        unshift @unchecked, $_ for reverse @{ $class_meta->{is} };
    }    
    return @$ordered_inherited_class_names;
}

push @cache_keys, '_all_property_names';
sub all_property_names {
    my $self = shift;
    
    if ($self->{_all_property_names}) {
        return @{ $self->{_all_property_names} };
    }
 
    my %seen = ();   
    my $all_property_names = $self->{_all_property_names} = [];
    for my $class_name ($self->class_name, $self->ancestry_class_names) {
        next if $class_name eq 'UR::Object';
        my $class_meta = UR::Object::Type->get($class_name);
        if (my $has = $class_meta->{has}) {
            push @$all_property_names, 
                grep { 
                    not exists $has->{$_}{id_by}
                }
                grep { !exists $seen{$_} } 
                sort keys %$has;
            foreach (@$all_property_names) {
                $seen{$_} = 1;
            }
        }
    }
    return @$all_property_names;
}


########################################################################
# End of overridden property methods
########################################################################

sub _resolve_meta_class_name_for_class_name {
    my $class = shift;
    my $class_name = shift;
    #if ($class_name->isa("UR::Object::Type") or $meta_classes{$class_name} or $class_name =~ '::Type') {
    if ($meta_classes{$class_name} or $class_name =~ '::Type') {
        return "UR::Object::Type"
    }
    else {
        return $class_name . "::Type";
    }    
}

sub _resolve_meta_class_name {
    my $class = shift;
    my ($rule,%extra) = UR::BoolExpr->resolve_normalized($class, @_);
    my %params = $rule->params_list;
    my $class_name = $params{class_name};
    return unless $class_name;
    return $class->_resolve_meta_class_name_for_class_name($class_name);
}


# This method can go away when we have the is_cached meta-property
sub first_sub_classification_method_name {
    my $self = shift;
    
    # This may be one of many things which class meta-data should "inherit" from classes which 
    # its instances inherit from.  This value is set to the value found on the most concrete class
    # in the inheritance tree.

    return $self->{___first_sub_classification_method_name} if exists $self->{___first_sub_classification_method_name};
    
    $self->{___first_sub_classification_method_name} = $self->sub_classification_method_name;
    unless ($self->{___first_sub_classification_method_name}) {
        for my $parent_class ($self->ancestry_class_metas) {
            last if ($self->{___first_sub_classification_method_name} = $parent_class->sub_classification_method_name);
        }
    }
    
    return $self->{___first_sub_classification_method_name};
}


# Another thing that is "inherited" from parent class metas
sub subclassify_by {
    my $self = shift;

    return $self->{'__subclassify_by'} if exists $self->{'__subclassify_by'};

    $self->{'__subclassify_by'} = $self->__subclassify_by;
    unless ($self->{'__subclassify_by'}) {
        for my $parent_class ($self->ancestry_class_metas) {
            last if ($self->{'__subclassify_by'} = $parent_class->__subclassify_by);
        }
    }

    return $self->{'__subclassify_by'};
}

sub resolve_composite_id_from_ordered_values {    
    my $self = shift;
    my $resolver = $self->get_composite_id_resolver;
    return $resolver->(@_);
}

sub resolve_ordered_values_from_composite_id {
    my $self = shift;
    my $decomposer = $self->get_composite_id_decomposer;
    return $decomposer->(@_);
}

sub get_composite_id_decomposer {
    my $self = shift;
    my $decomposer;
    unless ($decomposer = $self->{get_composite_id_decomposer}) {
        my @id_property_names = $self->id_property_names;        
        if (@id_property_names == 1) {
            $decomposer = sub { $_[0] };
        }
        else {
            my $separator = $self->_resolve_composite_id_separator;
            $decomposer = sub { 
                if (ref($_[0])) {
                    # ID is an arrayref, or we'll throw an exception.                    
                    my $id = $_[0];
                    my $underlying_id_count = scalar(@$id);
                    
                    # Handle each underlying ID, turning each into an arrayref divided by property value.
                    my @decomposed_ids;
                    for my $underlying_id (@$id) {
                        push @decomposed_ids, [map { $_ eq '' ? undef : $_ } split($separator,$underlying_id)];
                    }
            
                    # Count the property values.
                    my $underlying_property_count = scalar(@{$decomposed_ids[0]}) if @decomposed_ids;
                    $underlying_property_count ||= 0;
            
                    # Make a list of property values, but each value will be an
                    # arrayref of a set of values instead of a single value.
                    my @property_values;
                    for (my $n = 0; $n < $underlying_property_count; $n++) {
                        $property_values[$n] = [ map { $_->[$n] } @decomposed_ids ];
                    }
                    return @property_values;                
                }
                else {
                    # Regular scalar ID.
                    no warnings 'uninitialized';  # $_[0] can be undef in some cases...
                    return split($separator,$_[0])  
                }
            };
        }
        Sub::Name::subname('UR::Object::Type::InternalAPI::composite_id_decomposer(closure)',$decomposer);
        $self->{get_composite_id_decomposer} = $decomposer;
    }
    return $decomposer;
}

sub _resolve_composite_id_separator {   
    # TODO: make the class pull this from its parent at creation time
    # and only have it dump it if it differs from its parent
    my $self = shift;
    my $separator = "\t";
    for my $class_meta ($self, $self->ancestry_class_metas) {
        if ($class_meta->composite_id_separator) {
            $separator = $class_meta->composite_id_separator;
            last;
        }
    }
    return $separator; 
}

sub get_composite_id_resolver {
    my $self = shift;    
    my $resolver;
    unless($resolver = $self->{get_composite_id_resolver}) {
        my @id_property_names = $self->id_property_names;        
        if (@id_property_names == 1) {
            $resolver = sub { $_[0] };
        }
        else {
            my $separator = $self->_resolve_composite_id_separator;
            $resolver = sub { 
                if (ref($_[0]) eq 'ARRAY') {                
                    # Determine how big the arrayrefs are.
                    my $underlying_id_count = scalar(@{$_[0]});
                    
                    # We presume that, if one value is an arrayref, the others are also,
                    # and are of equal length.
                    my @id;
                    for (my $id_num = 0; $id_num < $underlying_id_count; $id_num++) {
                        # One value per id_property on the class.
                        # Each value is an arrayref in this case.
                        for my $value (@_) {
                            no warnings 'uninitialized';  # Some values in the list might be undef
                            $id[$id_num] .= $separator if $id[$id_num];
                            $id[$id_num] .= $value->[$id_num];
                        }
                    }
                    return \@id;           
                }
                else {
                    no warnings 'uninitialized';  # Some values in the list might be undef
                    return join($separator,@_) 
                }
            };
        }
        Sub::Name::subname('UR::Object::Type::InternalAPI::composite_id_resolver(closure)',$resolver);
        $self->{get_composite_id_resolver} = $resolver;
    }    
    return $resolver;
}

# UNUSED, BUT BETTER FOR MULTI-COLUMN FK
sub composite_id_list_scalar_mix {
    # This is like the above, but handles the case of arrayrefs
    # mixing with scalar values in a multi-property id.

    my ($self, @values) = @_;

    my @id_sets;
    for my $value (@values) {
        if (@id_sets == 0) {
            if (not ref $value) {
                @id_sets = ($value);
            }
            else {
                @id_sets = @$value;
            }
        }
        else {
            if (not ref $value) {
                for my $id_set (@id_sets) {
                    $id_set .= "\t" . $value;
                }
            }
            else {
                for my $new_id (@$value) {
                    for my $id_set (@id_sets) {
                        $id_set .= "\t" . $value;
                    }
                }
            }
        }
    }

    if (@id_sets == 1) {
        return $id_sets[0];
    }
    else {
        return \@id_sets;
    }
}


sub id_property_sorter {
    # Return a closure that sort can use to sort objects by all their ID properties
    # This should be the same order that an SQL query with 'order by ...' would return them
    my $self = shift;
    return $self->{'_id_property_sorter'} ||= $self->sorter(); 
}

sub sorter {
    my ($self,@properties) = @_;
    push @properties, $self->id_property_names;
    my $key = join("__",@properties);
    my $sorter = $self->{_sorter}{$key};
    unless ($sorter) {
        my @is_numeric;
        my @is_descending;
        for my $property (@properties) {
            if ($property =~ m/^(-|\+)(.*)$/) {
                push @is_descending, $1 eq '-';
                $property = $2;  # yes, we're manipulating the original list element
            } else {
                push @is_descending, 0;
            }

            my ($pmeta,@extra) = $self->_concrete_property_meta_for_class_and_name($property);
            if(@extra) {
                # maybe a composite property (typically ID), or a chained property (prop.other_prop)
                $pmeta = $self->property_meta_for_name($property);
            }

            if ($pmeta) {
                my $is_numeric = $pmeta->is_numeric;
                push @is_numeric, $is_numeric;
            }
            elsif ($UR::initialized) {
                Carp::cluck("Failed to find property meta for $property on $self?  Cannot produce a sorter for @properties");
                push @is_numeric, 0;
            }
            else {
                push @is_numeric, 0;
            }
        }

        no warnings 'uninitialized';
        $sorter = $self->{_sorter}{$key} ||= sub($$) {

            for (my $n = 0; $n < @properties; $n++) {
                my $property = $properties[$n];
                my @property_string = split('\.',$property);

                my($first,$second) = $is_descending[$n] ? ($_[1], $_[0]) : ($_[0], $_[1]);
                for my $current (@property_string) {
                    $first = $first->$current;
                    $second = $second->$current;
                    if (!defined($second)) {
                        return -1;
                    } elsif (!defined($first)) {
                        return 1;
                    }
                }

                my $cmp = $is_numeric[$n] ? $first <=> $second : $first cmp $second;
                return $cmp if $cmp;
            }
            return 0;
        };
    }
    Sub::Name::subname("UR::Object::Type::sorter__" . $self->class_name . '__' . $key, $sorter);
    return $sorter;
}

sub is_meta {
    my $self = shift;
    my $class_name = $self->class_name;
    return grep { $_ ne 'UR::Object' and $class_name->isa($_) } keys %meta_classes;
}

sub is_meta_meta {
    my $self = shift;
    my $class_name = $self->class_name;
    return 1 if $meta_classes{$class_name};
    return;
}

# Things that can't safely be removed from the object cache.
our %uncachable_types = ( ( map { $_ => 0 } keys %UR::Object::Type::meta_classes),   # meta-classes are locked in the cache...
                          'UR::Object' => 1,        # .. except for UR::Object
                          'UR::Object::Ghost' => 0,
                          'UR::DataSource' => 0,
                          'UR::Context' => 0,
                          'UR::Object::Index' => 0,
                        );
sub is_uncachable {
    my $self = shift;

    my $class_name = $self->class_name;

    if (@_) {
        # setting the is_uncachable value
        return $uncachable_types{$class_name} = shift;
    }

    unless (exists $uncachable_types{$class_name}) {
        my $is_uncachable = 1;
        foreach my $type ( keys %uncachable_types ) {
            if ($class_name->isa($type) and ! $uncachable_types{$type}) {
                $is_uncachable = 0;
                last;
            }
        }
        $uncachable_types{$class_name} = $is_uncachable;
        unless (exists $uncachable_types{$class_name}) {
            die "Couldn't determine is_uncachable() for $class_name";
        }
    }
    return $uncachable_types{$class_name};
}


# Mechanisms for generating object IDs when none were specified at
# creation time

sub autogenerate_new_object_id_uuid {
    require Data::UUID;
    my $uuid = Data::UUID->new->create_hex();
    $uuid =~ s/^0x//;
    return $uuid;
}

our $autogenerate_id_base_format = join(" ",Sys::Hostname::hostname(), "%s", time); # the %s gets $$ when needed
our $autogenerate_id_iter = 10000;
sub autogenerate_new_object_id_urinternal {
    my($self, $rule) = @_;

    my @id_property_names = $self->id_property_names;
    if (@id_property_names > 1) {
        # we really could, but it seems like if you 
        # asked to do it, it _has_ to be a mistake.  If there's a legitimate
        # reason, this check should be removed
        $self->error_message("Can't autogenerate ID property values for multiple ID property class " . $self->class_name);
        return;
    }
    return sprintf($autogenerate_id_base_format, $$) . " " . (++$autogenerate_id_iter);
}

sub autogenerate_new_object_id_datasource {
    my($self,$rule) = @_;

    my ($data_source) = $UR::Context::current->resolve_data_sources_for_class_meta_and_rule($self);
    if ($data_source) {
        return $data_source->autogenerate_new_object_id_for_class_name_and_rule(
            $self->class_name,
            $rule
        );
    } else {
        Carp::croak("Class ".$self->class." has id_generator '-datasource', but the class has no data source to delegate to");
    }
}


# Support the autogeneration of unique IDs for objects which require them.
sub autogenerate_new_object_id {
    my $self = _object($_[0]);
    #my $rule = shift;

    unless ($self->{'_resolved_id_generator'}) {
        my $id_generator = $self->id_generator;

        if (ref($id_generator) eq 'CODE') {
            $self->{'_resolved_id_generator'} = $id_generator;

        } elsif ($id_generator and $id_generator =~ m/^\-(\S+)/) {
            my $id_method = 'autogenerate_new_object_id_' . $1;
            my $subref = $self->can($id_method);
            unless ($subref) {
                Carp::croak("'$id_generator' is an invalid id_generator for class "
                            . $self->class_name
                            . ": Can't locate object method '$id_method' via package ".ref($self));
            }
            $self->{'_resolved_id_generator'} = $subref;

        } else {
            # delegate to the data source
            my ($data_source) = $UR::Context::current->resolve_data_sources_for_class_meta_and_rule($self);
            if ($data_source) {
                $self->{'_resolved_id_generator'} = sub {
                    $data_source->autogenerate_new_object_id_for_class_name_and_rule(
                        shift->class_name,
                        shift
                    )
                };
            }
        }
    }
    goto $self->{'_resolved_id_generator'};
}

# from ::Object->generate_support_class
our %support_class_suffixes = map { $_ => 1 } qw/Set View Viewer Ghost Iterator Value/;
sub generate_support_class_for_extension {
    my $self = shift;
    my $extension_for_support_class = shift;
    my $subject_class_name = $self->class_name;

    unless ($subject_class_name) {
        Carp::confess("No subject class name for $self?"); 
    }

    return unless defined $extension_for_support_class;

    if ($subject_class_name eq "UR::Object") {
        # Carp::cluck("can't generate $extension_for_support_class for UR::Object!\n");
        # NOTE: we hit this a bunch of times when "getting" meta-data objects during boostrap.
        return;
    }

    unless ($support_class_suffixes{$extension_for_support_class})
    {
        #$self->debug_message("Cannot generate a class with extension $extension_for_support_class.");
        return;
    }

    my $subject_class_obj = UR::Object::Type->get(class_name => $subject_class_name);
    unless ($subject_class_obj)  {
        $self->debug_message("Cannot autogenerate $extension_for_support_class because $subject_class_name does not exist.");
        return;
    }

    my $new_class_name = $subject_class_name . "::" . $extension_for_support_class;
    my $class_obj;
    if ($class_obj = UR::Object::Type->is_loaded($new_class_name)) {
        # getting the subject class autogenerated the support class automatically
        # shortcut out
        return $class_obj;
    }

    no strict 'refs';
    my @subject_parent_class_names = @{ $subject_class_name . "::ISA" };
    my @parent_class_names =
        grep { UR::Object::Type->get(class_name => $_) }
        map { $_ . "::" . $extension_for_support_class }
        grep { $_->isa("UR::Object") }
        grep { $_ !~ /^UR::/  or $extension_for_support_class eq "Ghost" }
        @subject_parent_class_names;
    use strict 'refs';

    unless (@parent_class_names) {
        if (UR::Object::Type->get(class_name => ("UR::Object::" . $extension_for_support_class))) {
            @parent_class_names = "UR::Object::" . $extension_for_support_class;
        }
    }

    unless (@parent_class_names) {
        #print Carp::longmess();
        #$self->error_message("Cannot autogenerate $extension_for_support_class for $subject_class_name because parent classes (@subject_parent_class_names) do not have classes with that extension.");
        return;
    }
    
    my @id_property_names = $subject_class_obj->id_property_names;
    my %id_property_names = map { $_ => 1 } @id_property_names;
    
    if ($extension_for_support_class eq 'Ghost') {
        my $subject_class_metaobj = UR::Object::Type->get($self->meta_class_name);  # Class object for the subject_class
        my %class_params = map { $_ => $subject_class_obj->$_ }
                           grep { my $p = $subject_class_metaobj->property_meta_for_name($_)
                                    || Carp::croak("Can't no metadata for property '$_' of class ".$self->meta_class_name);
                                  ! $p->is_delegated and ! $p->is_calculated }
                           $subject_class_obj->__meta__->all_property_names;
        delete $class_params{generated};
        delete $class_params{meta_class_name};
        delete $class_params{subclassify_by};
        delete $class_params{sub_classification_meta_class_name};
        delete $class_params{id_generator};
        delete $class_params{id};
        delete $class_params{is};
        delete $class_params{roles};

        my $attributes_have = UR::Util::deep_copy($subject_class_obj->{attributes_have});
        my $class_props = UR::Util::deep_copy($subject_class_obj->{has});    
        for (values %$class_props) {
            delete $_->{class_name};
            delete $_->{property_name};
        }
        
        %class_params = (
                %class_params,
                class_name => $new_class_name,
                is => \@parent_class_names, 
                is_abstract => 0,
                has => [%$class_props],
                attributes_have => $attributes_have,
                id_properties => \@id_property_names,
        );
        $class_obj = UR::Object::Type->define(%class_params);
    }
    else {
        $class_obj = UR::Object::Type->define(
            class_name => $subject_class_name . "::" . $extension_for_support_class,
            is => \@parent_class_names,
        );
    }
    return $class_obj;
}

sub has_table {
    my $self = shift;
    if ($bootstrapping) {
        return 0;
    }
    return 1 if $self->table_name;
    # FIXME - shouldn't this call inheritance() instead of parent_classes()?
    my @parent_classes = $self->parent_classes;
    for my $class_name (@parent_classes) {
        next if $class_name eq "UR::Object";
        my $class_obj = UR::Object::Type->get(class_name => $class_name);
        if ($class_obj->has_direct_table) {
            return 1;
        }
    }
    return;
}

sub has_direct_table {
    my $self = shift;
    return 1 if $self->table_name;

    if ($self->data_source_id and $self->data_source_id->isa('UR::DataSource::Default')) {
        my $load_function_name = join('::', $self->class_name, '__load__');
        return 1 if exists &$load_function_name;
    }
    return;
}

sub most_specific_subclass_with_table {
    my $self = shift;

    return $self->class_name if $self->table_name;

    foreach my $class_name ( $self->class_name->inheritance ) {
        my $class_obj = UR::Object::Type->get(class_name => $class_name);
        return $class_name if ($class_obj and $class_obj->has_direct_table);
    }
    return;
}

sub most_general_subclass_with_table {
    my $self = shift;

    my @subclass_list = reverse ( $self->class_name, $self->class_name->inheritance );
    foreach my $class_name ( $self->inheritance ) {
        my $class_obj = UR::Object::Type->get(class_name => $class_name);
        return $class_name if ($class_obj && $class_obj->has_direct_table);
    }
    return;
}

    

sub _load {
    my $class = shift;
    my $rule = shift;

    $rule = $rule->normalize;
    my $params = $rule->legacy_params_hash;

    # While core entity classes are actually loaded,
    # support classes dynamically generate for them as needed.
    # Examples are Acme::Employee::View::emp_id, and Acme::Equipment::Ghost

    # Try to parse the class name.
    my $class_name = $params->{class_name};

    # See if the class autogenerates from another class.
    # i.e.: Acme::Foo::Bar might be generated by Acme::Foo
    unless ($class_name) {
        my $namespace = $params->{namespace};
        if (my $data_source = $params->{data_source_id}) {
            $namespace = $data_source->get_namespace;
        }
        if ($namespace) {
            # FIXME This chunk seems to be getting called each time there's a new table/class
            #Carp::cluck("Getting all classes for namespace $namespace from the filesystem...");
            my @classes = $namespace->get_material_classes;
            return $class->is_loaded($params);
        }
        Carp::confess("Non-class_name used to find a class object: "
                    . join(', ', map { "$_ => " . (defined $params->{$_} ? "'" . $params->{$_} . "'" : 'undef') } keys %$params));
    }

    # Besides the common case of asking for a class by its name, the next most
    # common thing is asking for multiple classes by their names.  Rather than doing the
    # hard work of doing it "right" right here, just recursively call myself with each
    # item in that list
    if (ref $class_name eq 'ARRAY') {
        # FIXME is there a more efficient way to add/remove class_name from the rule?
        my $rule_without_class_name = $rule->remove_filter('class_name');
        $rule_without_class_name = $rule_without_class_name->remove_filter('id');  # id is a synonym for class_name
        my @objs = map { $class->_load($rule_without_class_name->add_filter(class_name => $_)) } @$class_name;
        return $class->context_return(@objs);
    }
        
    # If the class is loaded, we're done.
    # This is an un-documented unique constraint right now.
    my $class_obj = $class->is_loaded(class_name => $class_name);
    return $class_obj if $class_obj;

    # Handle deleted classes.
    # This is written in non-oo notation for bootstrapping.
    no warnings;
    if (
        $class_name ne "UR::Object::Type::Ghost"
        and
        UR::Object::Type::Ghost->can("class")
        and
        $UR::Context::current->get_objects_for_class_and_rule("UR::Object::Type::Ghost",$rule,0)
    ) {
        return;
    }

    # Check the filesystem.  The file may create its metadata object.
    my $exception = do {
        local $@;
        eval "use $class_name";
        $@;
    };
    unless ($exception) {
        # If the above module was loaded, and is an UR::Object,
        # this will find the object.  If not, it will return nothing.
        $class_obj = $UR::Context::current->get_objects_for_class_and_rule($class,$rule,0);
        return $class_obj if $class_obj;
    }
    if ($exception) {
        # We need to handle $@ here otherwise we'll see
        # "Can't locate UR/Object/Type/Ghost.pm in @INC" error.
        # We want to fall through "in the right circumstances".
        (my $module_path = $class_name . '.pm') =~ s/::/\//g;
        unless ($exception =~ /Can't locate $module_path in \@INC/) {
            die "Error while autoloading with 'use $class_name': $exception";
        }
    }

    # Parse the specified class name to check for a suffix.
    my ($prefix, $base, $suffix) = ($class_name =~ /^([^\:]+)::(.*)::([^:]+)/);

    my @parts;
    ($prefix, @parts) = split(/::/,$class_name);

    for (my $suffix_pos = $#parts; $suffix_pos >= 0; $suffix_pos--)
    {
        $class_obj = $UR::Context::current->get_objects_for_class_and_rule($class,$rule,0);
        if ($class_obj) {
            # the class was somehow generated while we were checking other classes for it and failing.
            # this can happen b/c some class with a name which is a subset of the one we're looking
            # for might "use" the one we want.
            return $class_obj if $class_obj;
        } 

        my $base   = join("::", @parts[0 .. $suffix_pos-1]);
        my $suffix = join("::", @parts[$suffix_pos..$#parts]);

        # See if a class exists for the same name w/o the suffix.
        # This may cause this function to be called recursively for
        # classes like Acme::Equipment::Set::View::upc_code,
        # which would fire recursively for three extensions of
        # Acme::Equipment.
        my $full_base_class_name = $prefix . ($base ? "::" . $base : "");
        my $base_class_obj;
        my $exception = do {
            local $@;
            $base_class_obj = eval { $full_base_class_name->__meta__ };
            $@;
        };
        if ($exception && $exception =~ m/^Error while autoloading/) {
            die $exception;
        }

        if ($base_class_obj)
        {
            # If so, that class may be able to generate a support
            # class.
            $class_obj = $full_base_class_name->__extend_namespace__($suffix);
            if ($class_obj)
            {
                # Autogeneration worked.
                # We still defer to is_loaded, since other parameters
                # may prevent the newly "loaded" class from being
                # returned.                
                return $UR::Context::current->get_objects_for_class_and_rule($class,$rule,0)
            }
        }
    }

    # If we fall-through to this point, no class was found and no module.
    return;
}


sub use_module_with_namespace_constraints {
    use strict;
    use warnings;

    my $self = shift;
    my $target_class = shift;

    # If you do "use Acme; $o = Acme::Rocket->new();", and Perl finds Acme.pm
    # at "/foo/bar/Acme.pm", Acme::Rocket must be under /foo/bar/Acme/
    # in order to be dynamically loaded.

    my @words = split("::",$target_class);
    my $path;
    while (@words > 1) {
        my $namespace_name = join("::",@words[0..$#words-1]);
        my $namespace_expected_module = join("/",@words[0..$#words-1]) . ".pm";


        if ($path = $INC{$namespace_expected_module}) {
            #print "got mod $namespace_expected_module at $path for $target_class\n";
            $path =~ s/\/*$namespace_expected_module//g;
        }
        else {
            my $namespace_obj =  UR::Object::Type->is_loaded(class_name => $namespace_name);
            if ($namespace_obj) {
                eval { $path = $namespace_obj->module_directory };
                if ($@) {
                    # non-module class
                    # don't auto-use, but don't make a lot of noise about it either
                }
            }
        }    
        last if $path;
        pop @words;
    }

    unless ($path) {
        #Carp::cluck("No module_directory found for namespace $namespace_name."
        #    . "  Cannot dynamically load $target_class.");
        return;
    }


    $self->_use_safe($target_class,$path);
    my $meta = UR::Object::Type->is_loaded(class_name => $target_class);
    if ($meta) {
        return $meta;
    }
    else {
        return;
    }
}

sub _use_safe {
    use strict;
    use warnings;

    my ($self, $target_class, $expected_directory) = @_;

    # TODO: use some smart module to determine whether the path is
    # relative on the current system.
    if (defined($expected_directory) and $expected_directory !~ /^[\/\\]/) {
        $expected_directory = $pwd_at_compile_time . "/" . $expected_directory;
    }

    my $class_path = $target_class . ".pm";
    $class_path =~ s/\:\:/\//g;

    my @INC_COPY = @INC;
    if ($expected_directory) {
        unshift @INC, $expected_directory;
    }
    my $found = "";
    for my $dir (@INC) {
        if ($dir and (-e $dir . "/" . $class_path)) {
            $found = $dir;
            last;
        }
    }

    if (!$found) {
        # not found
        @INC = @INC_COPY;
        return;
    }

    if ($expected_directory and $expected_directory ne $found) {
        # not found in the specified location
        @INC = @INC_COPY;
        return;
    }

    do {
        local $SIG{__DIE__};
        local $SIG{__WARN__};
        eval "use $target_class";
    };

    # FIXME - if the use above failed because of a compilation error in the module we're trying to
    # load, then the error message below just tells the user that "Compilation failed in require"
    # and isn't propogating the error message about what caused the compile to fail
    if ($@) {
        #local $SIG{__DIE__};

        @INC = @INC_COPY;
        die ("ERROR DYNAMICALLY LOADING CLASS $target_class\n$@");
    }

    for (0..$#INC) {
        if ($INC[$_] eq $expected_directory) {
            splice @INC, $_, 1;
            last;
        }
    }

    return 1;
}


# sub _object
# This is used to make sure that methods are called
# as object methods and not class methods.
# The typical case that's important is when something
# like UR::Object::Type->method(...) is called.
# If an object is expected in a method and it gets
# a class instead, well, unpredictable things can
# happen.
#
# For many methods on UR::Objects, the implementation
# is in UR::Object.  However, some of those methods
# have the same name as methods in here (purposefully),
# and those UR::Object methods often get the
# UR::Object::Type object and call the same method,
# which ends up in this file.  The problem is when
# those methods are called on UR::Object::Type
# itself it come directly here, without getting
# the UR::Object::Type object for UR::Object::Type
# (confused yet?).  So to fix this, we use _object to
# make sure we have an object and not a class.
#
# Basically, we make sure we're working with a class
# object and not a class name.
#

sub _object {
    return ref($_[0]) ? $_[0] : $_[0]->__meta__;
}

# new version gets everything, including "id" itself and object ref properties
push @cache_keys, '_all_property_type_names';
sub all_property_type_names {
    my $self = shift;
    
    if ($self->{_all_property_type_names}) {
        return @{ $self->{_all_property_type_names} };
    }
    
    #my $rule_template = UR::BoolExpr::Template->resolve('UR::Object::Type', 'id');

    my $all_property_type_names = $self->{_all_property_type_names} = [];
    for my $class_name ($self->class_name, $self->ancestry_class_names) {
        my $class_meta = UR::Object::Type->get($class_name);
        #my $rule = $rule_template->get_rule_for_values($class_name);
        #my $class_meta = $UR::Context::current->get_objects_for_class_and_rule('UR::Object::Type',$rule);
        if (my $has = $class_meta->{has}) {            
            push @$all_property_type_names, sort keys %$has;
        }
    }
    return @$all_property_type_names;
}

sub table_for_property {
    my $self = _object(shift);
    Carp::croak('must pass a property_name to table_for_property') unless @_;
    my $property_name = shift;
    for my $class_object ( $self, $self->ancestry_class_metas )
    {
        my $property_object = UR::Object::Property->get( class_name => $class_object->class_name, property_name => $property_name );
        if ( $property_object )
        {
            next unless $property_object->column_name;
            return $class_object->table_name;
        }
    }

    return;
}

sub column_for_property {
    my $self = _object(shift);
    Carp::croak('must pass a property_name to column_for_property') unless @_;
    my $property_name = shift;

    my($properties,$columns) = @{$self->{'_all_properties_columns'}};
    for (my $i = 0; $i < @$properties; $i++) {
        if ($properties->[$i] eq $property_name) {
            return $columns->[$i];
        }
    }

    for my $class_object ( $self->ancestry_class_metas ) {
        my $column_name = $class_object->column_for_property($property_name);
        return $column_name if $column_name;
    }
    return;
}

sub property_for_column {
    my $self = _object(shift);
    Carp::croak('must pass a column_name to property_for_column') unless @_;
    my $column_name = lc(shift);

    my $data_source = $self->data_source || 'UR::DataSource';
    my($table_name,$self_table_name);
    ($table_name, $column_name) = $data_source->_resolve_table_and_column_from_column_name($column_name);
    (undef, $self_table_name) = $data_source->_resolve_owner_and_table_from_table_name($self->table_name);

    if (! $table_name) {
        my($properties,$columns) = @{$self->{'_all_properties_columns'}};
        for (my $i = 0; $i < @$columns; $i++) {
            if (lc($columns->[$i]) eq $column_name) {
                return $properties->[$i];
            }
        }
    } elsif ($table_name
             and
             $self_table_name
             and lc($self_table_name) eq lc($table_name)
    ) {
        # @$properties and @$columns contain items inherited from parent classes
        # make sure the property we find with that name goes to this class
        my $property_name = $self->property_for_column($column_name);
        return undef unless $property_name;
        my $prop_meta = $self->property_meta_for_name($property_name);
        if ($prop_meta->class_name eq $self->class_name
            and
            lc($prop_meta->column_name) eq $column_name
        ) {
            return $property_name;
        }

    } elsif ($table_name) {

        for my $class_object ( $self, $self->ancestry_class_metas ) {
            next unless $class_object->data_source;
            my $class_object_table_name;
            (undef, $class_object_table_name)
                = $class_object->data_source->_resolve_owner_and_table_from_table_name($class_object->table_name);

            if (! $class_object_table_name
                or
                $table_name ne lc($class_object_table_name)
            ) {
                (undef, $class_object_table_name) = $class_object->data_source->parse_view_and_alias_from_inline_view($class_object->table_name);
            }
            next if (! $class_object_table_name
                or
                $table_name ne lc($class_object_table_name));

            my $property_name = $class_object->property_for_column($column_name);
            return $property_name if $property_name;
        }
    }

    return;
}

# Methods for maintaining unique constraints
# This is primarily used by the class re-writer (ur update classes-from-db), but
# BoolExprs use them,too

# Adds a constraint by name and property list to the class metadata.  The class initializer
# fills this data in via the 'constraints' key, so it shouldn't call add_unique_constraint()
# directly
sub add_unique_constraint {
    my $self = shift;

    unless (@_) {
        Carp::croak('method add_unique_constraint requires a constraint name as a parameter');
    }
    my $constraint_name = shift;

    my $constraints = $self->unique_property_set_hashref();
    if (exists $constraints->{$constraint_name}) {
        Carp::croak("A constraint named '$constraint_name' already exists for class ".$self->class_name);
    }

    unless (@_) {
        Carp::croak('method add_unique_constraint requires one or more property names as parameters');
    }
    my @property_names = @_;

    # Add a new constraint record
    push @{ $self->{'constraints'} } , { sql => $constraint_name, properties => \@property_names };
    # invalidate the other cached data
    $self->_invalidate_cached_data_for_subclasses('_unique_property_sets', '_unique_property_set_hashref');
}

sub remove_unique_constraint {
    my $self = shift;

    unless (@_) {
        Carp::croak("method remove_unique_constraint requires a constraint name as a parameter");
    }

    my $constraint_name = shift;
    my $constraints = $self->unique_property_set_hashref();
    unless (exists $constraints->{$constraint_name}) {
        Carp::croak("There is no constraint named '$constraint_name' for class ".$self->class_name);
    }

    # Remove the constraint record
    for (my $i = 0; $i < @{$self->{'constraints'}}; $i++) {
        if ($self->{'constraints'}->[$i]->{'sql'} = $constraint_name) {
            splice(@{$self->{'constraints'}}, $i, 1);
        }
    }
    $self->_invalidate_cached_data_for_subclasses('_unique_property_sets', '_unique_property_set_hashref');
}


# This returns a list of lists.  Each inner list is the properties/columns
# involved in the constraint
sub unique_property_sets {
    my $self = shift; 
    if ($self->{_unique_property_sets}) {
        return @{ $self->{_unique_property_sets} };
    }

    my $unique_property_sets = $self->{_unique_property_sets} = [];

    for my $class_name ($self->class_name, $self->ancestry_class_names) {
        my $class_meta = UR::Object::Type->get($class_name);
        if ($class_meta->{constraints}) {            
            for my $spec (@{ $class_meta->{constraints} }) {
                push @$unique_property_sets, [ @{ $spec->{properties} } ] 
            }
        }
    }
    return @$unique_property_sets;
}

# Return the constraint information as a hashref
# keys are the SQL constraint name, values are a listref of property/column names involved
sub unique_property_set_hashref {
    my $self = shift;

    if ($self->{_unique_property_set_hashref}) {
        return $self->{_unique_property_set_hashref};
    }

    my $unique_property_set_hashref = $self->{_unique_property_set_hashref} = {};
   
    for my $class_name ($self->class_name, $self->ancestry_class_names) {
        my $class_meta = UR::Object::Type->get($class_name);
        if ($class_meta->{'constraints'}) {
            for my $spec (@{ $class_meta->{'constraints'} }) {
                my $unique_group = $spec->{'sql'};
                next if ($unique_property_set_hashref->{$unique_group});  # child classes override parents
                $unique_property_set_hashref->{$unique_group} = [ @{$spec->{properties}} ];
            }
        }
    }

    return $unique_property_set_hashref;
}


# Used by the class meta meta data constructors to make changes in the 
# raw data stored in the class object's hash.  These should really
# only matter while running ur update

# Args are:
# 1) An UR::Object::Property object with attribute_name, class_name, id, property_name, type_name
# 2) The method called: _construct_object, load, 
# 3) An id?
sub _property_change_callback {
    my($property_obj,$method, $old_val, $new_val) = @_;

    return if ($method eq 'load' || $method eq 'unload');
    return unless ref($property_obj);  # happens when, say, error_message is called on the UR::Object::Property class

    my $class_obj = UR::Object::Type->get(class_name => $property_obj->class_name);
    my $property_name = $property_obj->property_name;

    $old_val = '' unless(defined $old_val);
    $new_val = '' unless(defined $new_val);

    if ($method eq 'create') {
        unless ($class_obj->{'has'}->{$property_name}) {
            my @attr = qw( class_name data_length data_type is_delegated is_optional property_name );

            my %new_property;
            foreach my $attr_name (@attr ) {
                $new_property{$attr_name} = $property_obj->$attr_name();
            }
            $class_obj->{'has'}->{$property_name} = \%new_property;
        }
        if (defined $property_obj->is_id) {
            &_id_property_change_callback($property_obj, 'create');
        }

    } elsif ($method eq 'delete') {
        if (defined $property_obj->is_id) {
            &_id_property_change_callback($property_obj, 'delete');
        }
        delete $class_obj->{'has'}->{$property_name};

    } elsif ($method eq 'is_id' and $new_val ne $old_val) {
        my $change = $new_val ? 'create' : 'delete';
        &_id_property_change_callback($property_obj, $change);
    }

    if (exists $class_obj->{'has'}->{$property_name}
        && exists $class_obj->{'has'}->{$property_name}->{$method}) {
        $class_obj->{'has'}->{$property_name}->{$method} = $new_val;

    } 

    # Invalidate the cache used by all_property_names()
    for my $key (@cache_keys) {
        $class_obj->_invalidate_cached_data_for_subclasses($key);
    }
}


# Some expensive-to-calculate data gets stored in the class meta hashref
# and needs to be removed for all the existing subclasses
sub _invalidate_cached_data_for_subclasses {
    my($class_meta, @cache_keys) = @_;

    delete @$class_meta{@cache_keys};

    my @subclasses = @{$UR::Object::Type::_init_subclasses_loaded{$class_meta->class_name}};
    my %seen;
    while (my $subclass = shift @subclasses) {
        next if ($seen{$subclass}++);
        my $sub_meta = UR::Object::Type->get(class_name => $subclass);
        delete @$sub_meta{@cache_keys};
        push @subclasses, @{$UR::Object::Type::_init_subclasses_loaded{$sub_meta->class_name}};
    }
}


# A streamlined version of the method just below that dosen't check that the
# data in both places is the same before a delete operation.  What was happening
# was that an ID property got deleted and the position checks out ok, but then
# a second ID property gets deleted and now the position dosen't match because we
# aren't able to update the object's position property 'cause it's an ID property
# and can't be changed.  
#
# The short story is that we've lowered the bar for making sure it's safe to delete info
sub _id_property_change_callback {
    my $property_obj = shift;
    my $method = shift;

    return if ($method eq 'load' || $method eq 'unload');

    my $class = UR::Object::Type->get(class_name => $property_obj->class_name);
    
    if ($method eq 'create') {
        my $pos = $property_obj->id_by;
        $pos += 0;  # make sure it's a number
        if ($pos <= @{$class->{'id_by'}}) {
            splice(@{$class->{'id_by'}}, $pos, 0, $property_obj->property_name);
        } else {
            # $pos is past the end... probably an id property was deleted and another added
            push @{$class->{'id_by'}}, $property_obj->property_name;
        }
    } elsif ($method eq 'delete') {
        my $property_name = $property_obj->property_name;
        for (my $i = 0; $i < @{$class->{'id_by'}}; $i++) {
            if ($class->{'id_by'}->[$i] eq $property_name) {
                splice(@{$class->{'id_by'}}, $i, 1);
                return;
            }
        }
        #$DB::single = 1;
        Carp::confess("Internal data consistancy problem: could not find property named $property_name in id_by list for class meta " . $class->class_name);

    } else {
        # Shouldn't get here since ID properties can't be changed, right?
        #$DB::single = 1;
        Carp::confess("Shouldn't be here as ID properties can't change");
        1;
    }

    $class->{'_all_id_property_names'} = undef;  #  Invalidate the cache used by all_id_property_names
}


#
# BOOTSTRAP CODE
#

sub get_with_special_parameters {
    my $class = shift;
    my $rule = shift;
    my %extra = @_;
    if (my $namespace = delete $extra{'namespace'}) {
        unless (keys %extra) {
            my @c = $namespace->get_material_classes();
            @c = grep { $_->namespace eq $namespace } $class->is_loaded($rule->params_list);
            return $class->context_return(@c);
        }
    }
    return $class->SUPER::get_with_special_parameters($rule,@_);
}

sub __signal_change__ {
    my $self = shift;
    my @rv = $self->SUPER::__signal_change__(@_);
    if ($_[0] eq "delete") {
        my $class_name = $self->{class_name};
        $self->ungenerate();
    }
    return @rv;
}

my @default_valid_signals = qw(create delete commit rollback load unload load_external subclass_loaded);
our %STANDARD_VALID_SIGNALS;
@STANDARD_VALID_SIGNALS{@default_valid_signals} = (1) x @default_valid_signals;
sub _is_valid_signal {
    my $self = shift;
    my $aspect = shift;

    # An aspect of empty string (or undef) means all aspects are being observed.
    return 1 unless (defined($aspect) and length($aspect));

    # All standard creation and destruction methods emit a signal.
    return 1 if ($STANDARD_VALID_SIGNALS{$aspect});

    for my $property ($self->all_property_names)
    {
        return 1 if $property eq $aspect;
    }

    if (!exists $self->{'_is_valid_signal'}) {
        $self->{'_is_valid_signal'} = { map { $_ => 1 } @{$self->{'valid_signals'}} };
    }

    return 1 if ($self->{'_is_valid_signal'}->{$aspect});

    foreach my $parent_meta ( $self->parent_class_metas ) {
        if ($parent_meta->_is_valid_signal($aspect)) {
            $self->{'_is_valid_signal'}->{$aspect} = 1;
            return 1;
        }
    }

    return 0;
}


sub generated {
    my $self = shift;
    if (@_) {
        $self->{'generated'} = shift;
    }
    return $self->{'generated'};
}

sub ungenerate {
    my $self = shift;
    my $class_name = $self->class_name;
    delete $UR::Object::_init_subclass->{$class_name};
    delete $UR::Object::Type::_inform_all_parent_classes_of_newly_loaded_subclass{$class_name};    
    do {
        no strict;
        no warnings;
        my @symbols_which_are_not_subordinate_namespaces =
            grep { substr($_,-2) ne '::' }
            keys %{ $class_name . "::" };
        my $hr = \%{ $class_name . "::" };
        delete @$hr{@symbols_which_are_not_subordinate_namespaces};        
    };
    my $module_name = $class_name;
    $module_name =~ s/::/\//g;
    $module_name .= ".pm";
    delete $INC{$module_name};    
    $self->{'generated'} = 0;
}

sub singular_accessor_name_for_is_many_accessor {
    my($self, $property_name) = @_;
    unless (exists $self->{_accessor_singular_names}->{$property_name}) {
        my $property_meta = $self->property_meta_for_name($property_name) if ($self->generated);
        if ($bootstrapping  # trust the caller when bootstrapping
            or
            ! $self->generated # when called from UR::Object::Type::AccessorWriter and the property isn't created yet
            or
            ($property_meta && $property_meta->is_many)
        ) {
            require Lingua::EN::Inflect;
            $self->{_accessor_singular_names}->{$property_name} = Lingua::EN::Inflect::PL_V($property_name);
        } else {
            $self->{_accessor_singular_names}->{$property_name} = undef;
        }
    }
    return $self->{_accessor_singular_names}->{$property_name};
}

sub iterator_accessor_name_for_is_many_accessor {
    my($self, $property_name) = @_;

    my $singular = $self->singular_accessor_name_for_is_many_accessor($property_name);
    return $singular && "${singular}_iterator";
}

sub set_accessor_name_for_is_many_accessor {
    my($self, $property_name) = @_;

    my $singular = $self->singular_accessor_name_for_is_many_accessor($property_name);
    return $singular && "${singular}_set";
}

sub rule_accessor_name_for_is_many_accessor {
    my($self, $property_name) = @_;

    my $singular = $self->singular_accessor_name_for_is_many_accessor($property_name);
    return $singular && "__${singular}_rule";
}

sub arrayref_accessor_name_for_is_many_accessor {
    my($self, $property_name) = @_;

    my $singular = $self->singular_accessor_name_for_is_many_accessor($property_name);
    return $singular && "${singular}_arrayref";
}

sub adder_name_for_is_many_accessor {
    my($self, $property_name) = @_;

    my $singular = $self->singular_accessor_name_for_is_many_accessor($property_name);
    return $singular && "add_${singular}";
}

sub remover_name_for_is_many_accessor {
    my($self, $property_name) = @_;

    my $singular = $self->singular_accessor_name_for_is_many_accessor($property_name);
    return $singular && "remove_${singular}";
}

1;

