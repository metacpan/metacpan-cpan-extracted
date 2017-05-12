package UR::BoolExpr::Template::PropertyComparison::Isa;
use strict;
use warnings;
use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name  => __PACKAGE__, 
    is => ['UR::BoolExpr::Template::PropertyComparison'],
);

sub _compare {
    my ($class,$comparison_value,@property_values) = @_;
    
    if (ref $comparison_value) {
        # Reference... maybe an Object?
        local $@;
        if (eval { $comparison_value->isa('UR::Object::Type')} ) {
            # It's a class object.  Compare to the Class's class_name
            $comparison_value = $comparison_value->class_name;
        } else {
            # It's an object... test on that object's type
            $comparison_value = ref($comparison_value);
        }
    }

    foreach my $property_value ( @property_values ) {
        return 1 if (eval { $property_value->isa($comparison_value) });
    }

    return '';
}


1;

=pod

=head1 NAME

UR::BoolExpr::Template::PropertyComparison::Isa - Test whether a value is-a subclass of another class

=head1 DESCRIPTION

If the property returns multiple values, this comparison returns true if any
of the values are a subclass of the comparison value

=cut
