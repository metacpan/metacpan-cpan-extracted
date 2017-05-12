
package UR::BoolExpr::Template::PropertyComparison::NotEquals;

use strict;
use warnings;
use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name  => __PACKAGE__, 
    is => ['UR::BoolExpr::Template::PropertyComparison'],
);

sub _compare {
    my ($class,$comparison_value,@property_value) = @_;

    no warnings 'uninitialized';
    if (@property_value == 0) {
        return ($comparison_value eq '' ? '' : 1);
    }

    my $cv_is_number = Scalar::Util::looks_like_number($comparison_value);

    foreach my $property_value ( @property_value ) {
        my $pv_is_number = Scalar::Util::looks_like_number($property_value);

        if ($cv_is_number and $pv_is_number) {
             return '' if ( $property_value == $comparison_value );
        } else {
             return '' if ( $property_value eq $comparison_value );
        }
    }
    return 1;
}


1;

=pod

=head1 NAME

UR::BoolExpr::Template::PropertyComparison::NotEqual - perform a not-equal test

=head1 DESCRIPTION

If the property returns multiple values, this comparison returns false if any if the values
are equal to the comparison value

=cut
