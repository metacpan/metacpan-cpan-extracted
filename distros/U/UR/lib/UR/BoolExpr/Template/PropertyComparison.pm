
package UR::BoolExpr::Template::PropertyComparison;

use warnings;
use strict;
our $VERSION = "0.47"; # UR $VERSION;

# Define the class metadata.

require UR;

UR::Object::Type->define(
    class_name      => __PACKAGE__,
    is              => ['UR::BoolExpr::Template'],
    #has => [qw/
    #    rule_type        
    #    subject_class_name
    #    property_name
    #    comparison_operator
    #    value
    #    resolution_code_perl
    #    resolution_code_sql
    #/],
    #id_by => ['subject_class_name','logic_string']
);

use UR::BoolExpr::Template::PropertyComparison::Equals;
use UR::BoolExpr::Template::PropertyComparison::LessThan;
use UR::BoolExpr::Template::PropertyComparison::In;
use UR::BoolExpr::Template::PropertyComparison::Like;

sub property_name {
    (split(' ',$_[0]->logic_detail))[0]
}


sub comparison_operator {
    (split(' ',$_[0]->logic_detail))[1]
}

sub sub_group {
    my $self = shift;
    my $spec = $self->property_name;
    if ($spec =~ /-/) {
        #$DB::single = 1;
    }
    if ($spec =~ /^(.*)+\-(\w+)(\?|)(\..+|)/) {
        return $2 . $3; 
    }
    else {
        return '';
    }
}

sub get_underlying_rules_for_values {
    return;
}

sub num_values {
    # Not strictly correct...
    return 1;
}

sub evaluate_subject_and_values {
    my ($self,$subject,$comparison_value) = @_;
    my @property_values = $subject->__get_attr__($self->property_name);
    return $self->_compare($comparison_value, @property_values);
}

sub resolve_subclass_for_comparison_operator {
    my $class = shift;
    my $comparison_operator = shift;

    # Remove any escape sequence that may have been put in at UR::BoolExpr::resolve()
    $comparison_operator =~ s/-.+$// if $comparison_operator;
    
    my $suffix = UR::Util::class_suffix_for_operator($comparison_operator);

    my $subclass_name = join('::', $class, $suffix);

    my $subclass_meta = UR::Object::Type->get($subclass_name);
    unless ($subclass_meta) {
        Carp::confess("Unknown operator '$comparison_operator'");
    }
    return $subclass_name;
}

sub _get_for_subject_class_name_and_logic_detail {
    my $class = shift;
    my $subject_class_name = shift;
    my $logic_detail = shift;

    my ($property_name, $comparison_operator) = split(' ',$logic_detail, 2);    
    my $subclass_name = $class->resolve_subclass_for_comparison_operator($comparison_operator);    
    my $id = $subclass_name->__meta__->resolve_composite_id_from_ordered_values($subject_class_name, 'PropertyComparison', $logic_detail);
    
    return $subclass_name->get($id);
}

sub comparison_value_and_escape_character_to_regex {    
    my ($class, $value, $escape) = @_;
	
    return '' unless defined($value);

    # anyone who uses the % as an escape character deserves to suffer
    if ($value eq '%') {
	return '^.+$';
    }

    my $regex = $value;

    # Escape all special characters in the regex.
    $regex =~ s/([\(\)\[\]\{\}\+\*\.\?\|\^\$\-])/\\$1/g;
    
    # Handle the escape sequence    
    if (defined $escape)
    {
        $escape =~ s/\\/\\\\/g; # replace \ with \\
        $regex =~ s/(?<!${escape})\%/\.\*/g;
        $regex =~ s/(?<!${escape})\_/./g;
        #LSF: Take away the escape characters.
        $regex =~ s/$escape\%/\%/g;
        $regex =~ s/$escape\_/\_/g;
    }
    else
    {
        $regex =~ s/\%/\.\*/g;
        $regex =~ s/\_/\./g;
    }

    # Wrap the regex in delimiters.
    $regex = "^${regex}\$";

    my $exception = do {
        local $@;
        $regex = eval { qr($regex) };
        $@;
    };
    if ($exception) {
        Carp::confess($exception);
    }

    return $regex;
}

1;

=head1 NAME

UR::BoolExpr::Template::PropertyComparison - implements logic for rules with a logic_type of "PropertyComparison" 

=head1 SEE ALSO

UR::Object(3), UR::BoolExpr::Temmplate(3), UR::BoolExpr(3), UR::BoolExpr::Template::PropertyComparison::*

=cut

