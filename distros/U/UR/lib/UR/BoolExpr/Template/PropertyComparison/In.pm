
package UR::BoolExpr::Template::PropertyComparison::In;

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name  => __PACKAGE__, 
    is => ['UR::BoolExpr::Template::PropertyComparison'],
    doc => "Returns true if any of the property's values appears in the comparison value list",
);

sub _compare {
    my ($class,$comparison_values,@property_values) = @_;

    if (@property_values == 1 and ref($property_values[0]) eq 'ARRAY') {
        @property_values = @{$property_values[0]};
    }

    # undef should match missing values, which will be sorted at the end - the sorter in
    # UR::BoolExpr::resolve() takes care of the sorting for us
    if (! @property_values and !defined($comparison_values->[-1])) {
        return 1;
    }

    my($pv_idx, $cv_idx);
    no warnings;
    my $sorter = sub { return $property_values[$pv_idx] cmp $comparison_values->[$cv_idx] };
    use warnings;

    # Binary search within @$comparison_values
    for ( $pv_idx = 0; $pv_idx < @property_values; $pv_idx++ ) {
        my $cv_min = 0;
        my $cv_max = $#$comparison_values;
        do {
            $cv_idx = ($cv_min + $cv_max) >> 1;
            my $result = &$sorter;
            if (!$result) {
                return 1;
            } elsif ($result > 0) {
                $cv_min = $cv_idx + 1;
            } else {
                $cv_max = $cv_idx - 1;
            }
        } until ($cv_min > $cv_max);
    }
    return '';
}

1;

=pod

=head1 NAME

UR::BoolExpr::Template::PropertyComparison::In - perform an In test

=head1 DESCRIPTION

Returns true if any of the property's values appears in the comparison value list.
Think of 'in' as short for 'intersect', and not just SQL's 'IN' operator.

=cut
