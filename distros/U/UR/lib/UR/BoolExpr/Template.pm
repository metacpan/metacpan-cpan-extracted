
=head1 NAME

UR::BoolExpr::Template - a UR::BoolExpr minus specific values

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

package UR::BoolExpr::Template;

use warnings;
use strict;

use Scalar::Util qw(blessed);
use Data::Dumper;
use UR;

our @CARP_NOT = qw(UR::BoolExpr);

# readable stringification
use overload ('""' => 'id');
use overload ('==' => sub { $_[0] . ''  eq $_[1] . '' } );
use overload ('eq' => sub { $_[0] . ''  eq $_[1] . '' } );

UR::Object::Type->define(
    class_name  => __PACKAGE__, 
    is_transactional => 0,
    composite_id_separator => '/',
    id_by => [
        subject_class_name              => { is => 'Text' },
        logic_type                      => { is => 'Text' },
        logic_detail                    => { is => 'Text' },
        constant_value_id               => { is => 'Text' }
    ],
    has => [
        is_normalized                   => { is => 'Boolean' },
        is_id_only                      => { is => 'Boolean' },
        is_partial_id                   => { is => 'Boolean' },  # True if at least 1, but not all the ID props are mentioned
        is_unique                       => { is => 'Boolean' },
        
        matches_all                     => { is => 'Boolean' },
        key_op_hash                     => { is => 'HASH' },
        id_position                     => { is => 'Integer' },
        normalized_id                   => { is => 'Text' },        
        normalized_positions_arrayref   => { is => 'ARRAY' },        
        normalization_extender_arrayref => { is => 'ARRAY' },
        _property_meta_hash             => { is => 'HASH' },
        _property_names_arrayref        => { is => 'ARRAY' },
        num_values                      => { is => 'Integer' },
        _ambiguous_keys                 => { is => 'ARRAY' },
        
        _keys                           => { is => 'ARRAY' },
        _constant_values                => { is => 'ARRAY' },
    ],
    has_optional => [
        hints                           => { is => 'ARRAY' },
        recursion_desc                  => { is => 'ARRAY' },
        order_by                        => { is => 'ARRAY' },
        group_by                        => { is => 'ARRAY' },
        aggregate                       => { is => 'ARRAY' },
        limit                           => { is => 'Integer' },
        offset                          => { is => 'Integer' },
    ]
);

our $VERSION = "0.47"; # UR $VERSION;

# Borrow from the util package.
# This will go away with refactoring.

our $id_sep         = $UR::BoolExpr::Util::id_sep;
our $record_sep     = $UR::BoolExpr::Util::record_sep;
our $unit_sep       = $UR::BoolExpr::Util::unit_sep;
our $null_value     = $UR::BoolExpr::Util::null_value;
our $empty_string   = $UR::BoolExpr::Util::empty_string;
our $empty_list     = $UR::BoolExpr::Util::empty_list;

# Names of the optional flags you can add to a rule
our @meta_param_names = qw(recursion_desc hints order_by group_by aggregate limit offset);

# Wrappers for regular properties

sub _property_names {
    return @{ $_[0]->{_property_names_arrayref} };
}

# Indexability methods

sub _indexable_property_names {
    $_[0]->_resolve_indexing_params unless $_[0]->{_resolve_indexing_params};
    @{ $_[0]->{_indexable_property_names} }
}

sub _indexable_property_positions {
    $_[0]->_resolve_indexing_params unless $_[0]->{_resolve_indexing_params};
    @{ $_[0]->{_indexable_property_positions} }
}

sub _is_fully_indexable {
    $_[0]->_resolve_indexing_params unless $_[0]->{_resolve_indexing_params};
    $_[0]->{_is_fully_indexable};
}

sub _resolve_indexing_params {
    my $self = $_[0];

    my $class_meta = UR::Object::Type->get($self->subject_class_name);

    my @all_names = $self->_property_names;

    for my $name (@all_names) {
        my $m = $class_meta->property($name);
        unless ($m) {
            #$DB::single = 1;
            $class_meta->property($name);
            #$DB::single = 1;
            $class_meta->property($name);
        }
    }
    
    my @indexable_names =
        sort
        map { $_->property_name }
        grep { $_ } #and $_->is_indexable }
        map { $class_meta->property_meta_for_name($_) }
        @all_names;
        
    my @indexable_positions
        = UR::Util::positions_of_values(\@all_names,\@indexable_names);
    
    $self->{_indexable_property_names} = \@indexable_names;
    $self->{_indexable_property_positions} = \@indexable_positions;
    $self->{_is_fully_indexable} = (@indexable_names == @all_names);
    
    return 1;
}

# Return true if this rule template's parameters is a subset of the other's parameters
# Returns 0 if this rule specifies a parameter not in the other template
# Returns undef if all the properties match, but their operators do not, meaning that
# we do not know if an object evaluated as true under one rule's template would also be in the other
sub is_subset_of {
    my($self,$other_template) = @_;

    my $other_template_id = $other_template->id;
    my $cached_subset_data = $self->{'__cache'}->{'is_subset_of'} ||= {};
    if (exists $cached_subset_data->{$other_template_id}) {
        return $cached_subset_data->{$other_template_id};
    }

    unless (ref($other_template) and $self->isa(ref $other_template)) {
        $cached_subset_data->{$other_template_id} = 0;
        return 0;
    }

    my $my_class = $self->subject_class_name;
    my $other_class = $other_template->subject_class_name;
    unless ($my_class eq $other_class or $my_class->isa($other_class)) {
        $cached_subset_data->{$other_template_id} = undef;
        return;
    }

    my %operators = map { $_ => $self->operator_for($_) } $self->_property_names;
    my $is_subset = 1;
    foreach my $prop ( $other_template->_property_names ) {
        unless (exists $operators{$prop}) {
            $is_subset = 0;
            last;
        }
        $is_subset = undef if ($operators{$prop} ne $other_template->operator_for($prop));
    }

    if ($is_subset) {
        $is_subset = $self->_is_subset_of_limit_offset($other_template);
    }

    return $cached_subset_data->{$other_template_id} = $is_subset;
}

sub _is_subset_of_limit_offset {
    my($self, $other_template) = @_;

    return 1 unless ($self->offset or defined($self->limit)
                    or $other_template->offset or defined($other_template->limit));

    # need to do a more comprehensive filter match.  If one or both templates
    # has -limit and/or -offset, then the filters on both templates must match
    # exactly.  Otherwise, one result set could include objects that were
    # skipped because of the other's offset or limit
    my @my_filters = map { $_ . $self->operator_for($_) } $self->_property_names;
    my @other_filters = map { $_ . $other_template->operator_for($_) } $other_template->_property_names;
    my($both, $only_my, $only_other) = UR::Util::intersect_lists(\@my_filters, \@other_filters);
    return undef if (@$only_my or @$only_other);

    my $my_offset = $self->offset || 0;
    my $my_limit = $self->limit;
    my $other_offset = $other_template->offset || 0;
    my $other_limit = $other_template->limit;

    my $is_subset;
    if (defined($my_limit) and defined($other_limit)) {
        my $my_last = $my_offset + $my_limit;
        my $other_last = $other_offset + $other_limit;

        $is_subset = ($my_offset >= $other_offset) && ($my_last <= $other_last);

    } elsif (!defined($my_limit) and defined($other_limit)) {
        $is_subset = 0;

    } else {
        $is_subset = $my_offset >= $other_offset;
    }
    return $is_subset;
}


# This is set lazily currently

sub is_unique {
    my $self = $_[0];
    if (defined $self->{is_unique}) {
        return $self->{is_unique}
    }

    # since this requires normalization, we don't set the value at construction time
    my $normalized_self;
    if ($self->is_normalized) {
        $normalized_self = $self;
    }
    else {
        $normalized_self = $self->get_normalized_template_equivalent($self);
    }

    my $op = $normalized_self->operator_for('id');
    if (defined($op) and ($op eq '' or $op eq '=')) {
        return $self->{is_unique} = 1;
    }
    else {
        $self->{is_unique} = 0;
        
        # if some combination of params can combine to
        # satisfy at least one unique constraint,
        # then we have uniqueness in the parameters.

        if (my @ps = $self->subject_class_name->__meta__->unique_property_sets) {  
            my $property_meta_hash = $self->_property_meta_hash;      
            for my $property_set (@ps) 
            {
                my $property_set = (ref($property_set) ? $property_set : [$property_set]);
                my @properties_used_from_constraint =  
                    grep { defined($_) } 
                    @$property_meta_hash{@$property_set};
                    
                if (@properties_used_from_constraint == @$property_set) {
                    # filter imprecise operators
                    @properties_used_from_constraint = 
                        grep {  
                            $_->{operator} !~ /^(not |)like(-.|)$/i
                            and
                            $_->{operator} !~ /^(not |)in/i
                        }                                              
                        @properties_used_from_constraint;
                        
                    if (@properties_used_from_constraint == @$property_set) {
                        $self->{is_unique} = 1;
                        last;
                    }
                    else {
                        ## print "some properties use bad operators: @properties_used_from_constraint\n";
                    }
                }
                else {
                    ## print "too few properties in @properties_used_from_constraint\n";
                }
            }
        }

        return $self->{is_unique};
    }
}


# Derivative of the ID. 

sub rule_template_subclass_name {    
    return "UR::BoolExpr::Template::" . shift->logic_type;
}

sub get_normalized_template_equivalent {
    UR::BoolExpr::Template->get($_[0]->{normalized_id});
}

sub get_rule_for_values {
    my $self = shift;
    my $value_id = UR::BoolExpr::Util::values_to_value_id(@_);
    my $rule_id = UR::BoolExpr->__meta__->resolve_composite_id_from_ordered_values($self->id,$value_id);
    my $r = UR::BoolExpr->get($rule_id);
#
#    # FIXME - Don't do this part if the operator is 'in' or 'between'
#    for (my $i = 0; $i < @_; $i++) {
#        if (ref($_[$i]) and ! Scalar::Util::blessed($_[$i])) {
#            $r->{'hard_refs'}->{$i} = $_[$i];
#        }
#    }
    return $r;
}

sub get_rule_for_value_id {
    my $self = shift;
    my $value_id = shift;

    my $rule_id = UR::BoolExpr->__meta__->resolve_composite_id_from_ordered_values($self->id,$value_id);
    return UR::BoolExpr->get($rule_id);
}

sub extend_params_list_for_values {
    my $self = shift;
    #my @prev = @_;
    my $extenders = $self->normalization_extender_arrayref;
    if (@$extenders) {
        my @result;
        my $subject_class = $self->subject_class_name->__meta__;
        for my $n (0 .. @$extenders-1) {
            my $extender = $extenders->[$n];
            my ($input_positions_arrayref,$subref,@more_keys) = @$extender;
            my @more_values = @_[@$input_positions_arrayref];            
            if ($subref) {
                ## print "calling $subref on \n\t" . join("\n\t",@more_values) . "\n";
                @more_values = $subject_class->$subref(@more_values);
                ## print "got: \n\t" . join("\n\t",@more_values) . "\n";
            }
            while (@more_keys) {
                my $k = shift @more_keys;
                my $v = shift @more_values;
                push @result, $k => $v;
            }
        }
        return @result;
    }
    return ();
}

sub get_normalized_rule_for_values {
    my $self = shift;
    my @unnormalized_values = @_;

    if ($self->is_normalized) {
        return $self->get_rule_for_values(@unnormalized_values);
    }

    my $normalized_rule_template = $self->get_normalized_template_equivalent;

    # The normalized rule set may have more values than were actually
    # passed-in.  These 'extenders' will add to the @values array
    # before re-ordering it.
    my $extenders = $self->normalization_extender_arrayref;
    if (@$extenders) {
        my $subject_class = $self->subject_class_name->__meta__;
        for my $extender (@$extenders) {
            my ($input_positions_arrayref,$subref) = @$extender;
            my @more_values = @unnormalized_values[@$input_positions_arrayref];            
            if ($subref) {
                ## print "calling $subref on \n\t" . join("\n\t",@more_values) . "\n";
                @more_values = $subject_class->$subref(@more_values);
                ## print "got: \n\t" . join("\n\t",@more_values) . "\n";
            }
            push @unnormalized_values, @more_values;
        }
    }
    
    # Normalize the values.  Since the normalized template may have added properties, 
    # and a different order we may need to re-order and expand the values list.
    my $normalized_positions_arrayref = $self->normalized_positions_arrayref;
    my @normalized_values = @unnormalized_values[@$normalized_positions_arrayref];

    my $rule = $normalized_rule_template->get_rule_for_values(@normalized_values);
    return $rule;
}

sub _normalize_non_ur_values_hash {
    my ($self,$unnormalized) = @_;
    my %normalized;
    if ($self->subject_class_name ne 'UR::Object::Property') {
        my $normalized_positions_arrayref = $self->normalized_positions_arrayref;
        my @reordered_values = @$unnormalized{@$normalized_positions_arrayref};
        for (my $n = 0; $n < @reordered_values; $n++) {
            my $value = $reordered_values[$n];
            $normalized{$n} = $value if defined $value;
        }
    }
    return \%normalized;
}


sub value_position_for_property_name {
    if (exists $_[0]{_property_meta_hash}{$_[1]}) {
        return $_[0]{_property_meta_hash}{$_[1]}{value_position};
    } else {
        return undef;
    }
}

sub operator_for {
    if (exists $_[0]{_property_meta_hash}{$_[1]}) {
        return $_[0]{_property_meta_hash}{$_[1]}{operator} || '=';
    } else {
        return undef;
    }
}

sub operators_for_properties {
    my %properties = map { $_ => $_[0]->{'_property_meta_hash'}->{$_}->{'operator'} || '=' }
                        @{ $_[0]->{'_property_names_arrayref'} };
    return \%properties;
}

sub add_filter {
    my $self = shift;
    my $property_name = shift;
    my $op = shift;    
    my $new_key = $property_name;
    $new_key .= ' ' . $op if defined $op;    
    my ($subject_class_name, $logic_type, $logic_detail) = split("/",$self->id);
    unless ($logic_type eq 'And') {
        die "Attempt to add a filter to a rule besides an 'And' rule!";
    }
    my @keys = split(',',$logic_detail);
    my $new_id = join('/',$subject_class_name,$logic_type,join(',',@keys,$new_key));
    return $self->class->get($new_id);
}

sub remove_filter {
    my $self = shift;
    my $filter = shift;
    my ($subject_class_name, $logic_type, $logic_detail) = split("/",$self->id);
    my @keys = grep { $_ !~ /^${filter}\b/ } split(',',$logic_detail);
    my $new_id = join('/',$subject_class_name,$logic_type,join(',',@keys));
    #print "$new_id\n";
    return $self->class->get($new_id);
}

sub sub_classify {
    my ($self,$subclass_name) = @_;
    my $new_id = $self->id;
    $new_id =~ s/^.*?\//$subclass_name\//;
    return $self->class->get($new_id);    
}


# flyweight constructor
# NOTE: this caches outside of the regular system since these are stateless objects
sub get_by_subject_class_name_logic_type_and_logic_detail {
    my $class = shift;
    my $subject_class_name = shift;
        Carp::croak("Expected a subject class name as the first arg of UR::BoolExpr::Template constructor, got "
                    . ( defined($subject_class_name) ? "'$subject_class_name'" : "(undef)" ) ) unless ($subject_class_name);
    my $logic_type = shift;
    my $logic_detail = shift;
    my $constant_value_id = shift || UR::BoolExpr::Util::values_to_value_id(); # default is an empty list of values

    return $class->get(join('/',$subject_class_name,$logic_type,$logic_detail,$constant_value_id));
}

# The analogue of resolve in UR::BoolExpr.  @params_list is a list if
# strings containing properties and operators separated by a space.  For ex: "some_param ="
sub resolve {
    my($class,$subject_class_name, @params_list) = @_;

    my(@params, @constant_values);
    for (my $i = 0; $i < @params_list; $i++) {
        push @params, $params_list[$i];
        if (UR::BoolExpr::Util::is_meta_param($params_list[$i])) {
            push @constant_values, $params_list[++$i];
        }
    }

    return $class->get_by_subject_class_name_logic_type_and_logic_detail(
                        $subject_class_name,
                        "And",
                        join(',',@params),
                        UR::BoolExpr::Util::values_to_value_id(@constant_values));
}

sub get {
    my $class = shift;
    my $id = shift;    
    Carp::croak("Non-id params not supported for " . __PACKAGE__ . " yet!") if @_;

    my $self = $UR::Object::rule_templates->{$id};
    return $self if $self;     

    my ($subject_class_name,$logic_type,$logic_detail,$constant_value_id,@extra) = split('/',$id);  
    if (@extra) {
        # account for a possible slash in the constant value id
        $constant_value_id = join('/',$constant_value_id,@extra);
    }

    # work on the base class or on subclasses
    my $sub_class_name = (
        $class eq __PACKAGE__ 
            ? __PACKAGE__ . "::" . $logic_type
            : $class    
    );

    unless ($logic_type) {
        Carp::croak("Could not determine logic type from UR::BoolExpr::Template with id $id");
    }

    if ($logic_type eq "And") {
        # TODO: move into subclass
        my @keys = split(/,/,$logic_detail || '');    
        my @constant_values;
        @constant_values = UR::BoolExpr::Util::value_id_to_values($constant_value_id) if defined $constant_value_id;
        return $sub_class_name->_fast_construct(
            $subject_class_name,
            \@keys,
            \@constant_values,
            $logic_detail,
            $constant_value_id,            
        );
    } 
    else {
        $self = bless {
            id                              => $id,
            subject_class_name              => $subject_class_name,
            logic_type                      => $logic_type,
            logic_detail                    => $logic_detail,
            constant_value_id               => $constant_value_id,
            normalized_id                   => $id,
        }, $sub_class_name;
        $UR::Object::rule_templates->{$id} = $self;  
        return $self;
    }
}


# Return true if the template has recursion_desc, hints, order or page set
sub has_meta_options {
    my $self = shift;
    return 1 if @$self{@meta_param_names};
    return 0;
}


# This is the basis for the hash used by the existing UR::Object system for each rule.
# this is created upon first request and cached in the object

sub legacy_params_hash {
    my $self = shift;
    my $legacy_params_hash = $self->{legacy_params_hash};
    return $legacy_params_hash if $legacy_params_hash;
    
    $legacy_params_hash = {};    
    
    my $template_id = $self->id;
    my $key_op_hash = $self->key_op_hash;
    my $id_only = $self->is_id_only;    
        
    my $subject_class_name  = $self->subject_class_name;
    my $logic_type          = $self->logic_type;    
    my $logic_detail        = $self->logic_detail;    
    my @keys_sorted         = $self->_underlying_keys;
    my $subject_class_meta  = $subject_class_name->__meta__;
    
    if (
        (@keys_sorted and not $logic_detail)
        or
        ($logic_detail and not @keys_sorted)        
    ) {
        Carp::confess();
    }
    
    if (!$logic_detail) {
        %$legacy_params_hash = (_unique => 0, _none => 1);            
    }
    else {        
        # _id_only
        if ($id_only) {
            $legacy_params_hash->{_id_only} = 1;
        }
        else {
            $legacy_params_hash->{_id_only} = 0;
            $legacy_params_hash->{_param_key} = undef;
        }
        
        # _unique
        if (my $id_op = $key_op_hash->{id}) {
            if ($id_op->{""} or $id_op->{"="}) {
                $legacy_params_hash->{_unique} = 1;
                unless ($self->is_unique) {
                    Carp::carp("The BoolExpr includes a filter on ID, but the is_unique flag is unexpectedly false for $self->{id}");
                }
            }
        }

                

        unless ($legacy_params_hash->{_unique}) {         
            if (defined $legacy_params_hash->{id} and not ref $legacy_params_hash->{id}) {
                # if we have the id, then we have uniqueness
                # NOT TRUE: we catch the truly unieq cses of having an id and an unambiguous operator above
                #$legacy_params_hash->{_unique} = 1;
            }
            else {
                # default to non-unique
                $legacy_params_hash->{_unique} = 0;   
               
                # if some combination of params can combine to
                # satisfy at least one unique constraint,
                # then we have uniqueness in the parameters.
                
                my @ps = $subject_class_meta->unique_property_sets;
                for my $property_set (@ps) 
                {                            
                    my $property_set = (ref($property_set) ? $property_set : [$property_set]);
                    my @properties_used_from_constraint =  
                        grep { defined($_) } 
                        (ref($property_set) ? @$key_op_hash{@$property_set} : $key_op_hash->{$property_set});
                        
                    if (@properties_used_from_constraint == @$property_set) {
                        # filter imprecise operators
                        @properties_used_from_constraint = 
                            grep {                                                
				                not (
                                    grep { /^(not |)like(-.|)$/i or /^\[\]/}
                                    keys %$_
                                )
                            }
                            @properties_used_from_constraint;
                            
                        if (@properties_used_from_constraint == @$property_set) {
                            $legacy_params_hash->{_unique} = 1;
                            last;
                        }
                        else {
                            ## print "some properties use bad operators: @properties_used_from_constraint\n";
                        }
                    }
                    else {
                        ## print "too few properties in @properties_used_from_constraint\n";
                    }
                }
            }
            
            # _param_key gets re-set as long as this has a true value
            $legacy_params_hash->{_param_key} = undef unless $id_only;
        }
    }

    if ($self->is_unique and not $legacy_params_hash->{_unique}) {
        Carp::carp "is_unique IS set but legacy params hash is NO for $self->{id}";
        #$DB::single = 1;
        $self->is_unique; 
    }
    if (!$self->is_unique and $legacy_params_hash->{_unique}) {        
        Carp::carp "is_unique NOT set but legacy params hash IS for $self->{id}";
        #$DB::single = 1;
        $self->is_unique; 
    }       

    $self->{legacy_params_hash} = $legacy_params_hash;
    return $legacy_params_hash;
}

sub sorter {
    my $self = shift;

    # return a standard sorter for expressions using this template
    # the template might contain a group_by or order_by clause which affects it...

    die "this method takes no paramters!" if @_;

    my $class = $self->subject_class_name;

    my $sort_meta;
    if ($self->group_by) {
        my $set_class = $class . "::Set";
        $sort_meta = $set_class->__meta__;
    }
    else {
        $sort_meta = $class->__meta__;
    }

    my $sorter;
    if (my $order_by = $self->order_by) {
        $sorter = $sort_meta->sorter(@$order_by);
    }
    else {
        $sorter = $sort_meta->sorter();
    }

    return $sorter;
}


1;

