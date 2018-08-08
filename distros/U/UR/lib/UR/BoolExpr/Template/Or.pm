package UR::BoolExpr::Template::Or;

use warnings;
use strict;
our $VERSION = "0.47"; # UR $VERSION;

require UR;

UR::Object::Type->define(
    class_name      => __PACKAGE__,
    is              => ['UR::BoolExpr::Template::Composite'],    
);

sub _flatten_bx {
    my ($class, $bx) = @_;
    my @old = $bx->underlying_rules;
    my @new;
    for my $old (@old) {
        my $new = $old->flatten;
        push @new, [ $new->_params_list ];
    }
    my $flattened_bx = $class->_compose($bx->subject_class_name,\@new);
    return $flattened_bx;
}

sub _reframe_bx {
    my ($class, $bx, $in_terms_of) = @_;
    my @old = $bx->underlying_rules;
    my @new;
    for my $old (@old) {
        my $new = $old->reframe($in_terms_of);
        push @new, [ $new->_params_list ];
    }
    my @meta = $bx->subject_class_name->__meta__->property_meta_for_name($in_terms_of);
    my @joins = $meta[-1]->_resolve_join_chain($in_terms_of);
    my $reframed_bx = $class->_compose($joins[-1]{foreign_class},\@new);
    return $reframed_bx;
}

sub _compose {
    my $self = shift;
    my $subject_class = shift;
    my $sub_queries  = shift;
    my $meta_params = shift;

    my @underlying_rules;
    my @expressions;
    my @values;
    while (@$sub_queries) {
        my $underlying_query;
        if (ref($sub_queries->[0]) eq 'ARRAY') {
            $underlying_query = UR::BoolExpr->resolve($subject_class, @{$sub_queries->[0]}, @$meta_params);
            shift @$sub_queries;
        }
        elsif (ref($sub_queries->[0]) eq 'UR::BoolExpr::And') {
            $underlying_query = shift @$sub_queries;
        }
        else  {
            $underlying_query = UR::BoolExpr->resolve($subject_class, @$sub_queries[0,1], @$meta_params);
            shift @$sub_queries;
            shift @$sub_queries;
        }

        if ($underlying_query->{'_constant_values'}) {
            Carp::confess("cannot use -* expressions in subordinate clauses of a logical <or>");
        }
        
        unless ($underlying_query->template->isa("UR::BoolExpr::Template::And")) {
            Carp::confess("$underlying_query is not an AND template");
        }
        push @underlying_rules, $underlying_query;

        push @expressions, $underlying_query->template->logic_detail;
        push @values, $underlying_query->values;
    }
    my $bxt = UR::BoolExpr::Template::Or->get_by_subject_class_name_logic_type_and_logic_detail($subject_class,'Or',join('|',@expressions));
    my $bx = $bxt->get_rule_for_values(@values);
    # This (and accompanying "caching" in UR::BoolExpr::underlying_rules())
    # is a giant hack to allow composite rules to have -order and -group
    # The real fix is to coax the above combination of
    # get_by_subject_class_name_logic_type_and_logic_detail() and get_rule_for_values() to
    # properly encode these constant/template values into the rule and template IDs,
    # and subsequently reconsitiute them when you call $template->order_by
    $bx->{'_underlying_rules'} = \@underlying_rules;
    for (my $i = 0; $i < @$meta_params; $i += 2) {
        my $method = $meta_params->[$i];
        substr($method, 0, 1, '');  # remove the -
        if ($method eq 'recurse') {
            $bx->template->recursion_desc($meta_params->[$i + 1]);
        } elsif ($method eq 'order') {
            $bx->template->order_by($meta_params->[$i + 1]);
        } else {
            $bx->template->$method($meta_params->[$i + 1]);
        }
    }

    return $bx;
}

sub _underlying_keys {
    my $self = shift;
    my $logic_detail = $self->logic_detail;
    return unless $logic_detail;
    my @underlying_keys = split('\|',$logic_detail);
    return @underlying_keys;
}

# sub get_underlying_rules_for_values

sub get_underlying_rule_templates {
    my $self = shift;
    my @underlying_keys = $self->_underlying_keys();
    my $subject_class_name = $self->subject_class_name;
    return map {                
            UR::BoolExpr::Template::And
                ->_get_for_subject_class_name_and_logic_detail(
                    $subject_class_name,
                    $_
                );
        } @underlying_keys;
}

sub specifies_value_for {
    my ($self, $property_name) = @_;
    Carp::confess() if not defined $property_name;
    my @underlying_templates = $self->get_underlying_rule_templates();        
    my @all_specified;
    for my $template (@underlying_templates) {
        my @specified = $template->specifies_value_for($property_name);
        if (@specified) {
            push @all_specified, @specified;
        }
        else {
            return;
        }
    }
    return @all_specified;
}

sub evaluate_subject_and_values {
    my $self = shift;
    my $subject = shift;
    return unless (ref($subject) && $subject->isa($self->subject_class_name));
    my @underlying = $self->get_underlying_rule_templates;
    while (my $underlying = shift (@underlying)) {
        my $n = $underlying->_variable_value_count;
        my @next_values = splice(@_,0,$n);
        if ($underlying->evaluate_subject_and_values($subject,@_)) {
            return 1;
        }
    }
    return;
}

sub params_list_for_values {
    my $self = shift;
    my @values_sorted = @_;
    my @list;
    my @t = $self->get_underlying_rule_templates;
    for my $t (@t) {
        my $c = $t->_variable_value_count;
        my @l = $t->params_list_for_values(splice(@values_sorted,0,$c));
        push @list, \@l; 
    }
    return -or => \@list;
}

sub get_normalized_rule_for_values {
    my $self = shift;
    return $self->get_rule_for_values(@_);
}

1;

=pod

=head1 NAME

UR::BoolExpr::Or -  a rule which is true if ANY of the underlying conditions are true 

=head1 SEE ALSO

UR::BoolExpr;(3)

=cut 
