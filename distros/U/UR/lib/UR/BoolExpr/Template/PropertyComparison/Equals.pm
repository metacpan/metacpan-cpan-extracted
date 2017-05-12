package UR::BoolExpr::Template::PropertyComparison::Equals;
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
    
    no warnings 'uninitialized';
    if (@property_values == 0) {
        return ($comparison_value eq '' ? 1 : '');
    }

    no warnings 'numeric';
    my $cv_is_number = Scalar::Util::looks_like_number($comparison_value);

    foreach my $property_value ( @property_values ) {
        my $pv_is_number = Scalar::Util::looks_like_number($property_value);
        if ($pv_is_number and $cv_is_number) {
            return 1 if $property_value == $comparison_value;
        } else {
            return 1 if $property_value eq $comparison_value;
        }
    }

    return '';
}


1;

=pod

=head1 NAME

UR::BoolExpr::Template::PropertyComparison::Equals - perform a strictly equals test

=head1 DESCRIPTION

If the property returns multiple values, this comparison returns true if any of the values are equal to the comparison value

=cut
