
package UR::BoolExpr::Template::PropertyComparison::True;

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name  => __PACKAGE__, 
    is => ['UR::BoolExpr::Template::PropertyComparison'],
);

sub _compare {
    my ($class,$comparison_value,@property_value) = @_;
    no warnings;
    if (@property_value == 0) {
        return '';

    } else {
        for (@property_value) {
            return 1 if ($_);     # Returns true if _any_ of the values are true
        }
        return '';
    }
}


1;

=pod

=head1 NAME

UR::BoolExpr::Template::PropertyComparison::True - Evaluates to true if the property's value is true

If the property returns multiple values, this comparison returns true if any of the values are true

=cut
