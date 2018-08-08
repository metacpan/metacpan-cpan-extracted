
package UR::BoolExpr::Template::PropertyComparison::Matches;

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
    no warnings 'uninitialized';
    foreach my $property_value ( @property_value ) {
        return 1 if ( $property_value =~ m/$comparison_value/ );
    }
    return '';
}


1;

=pod

=head1 NAME 

UR::BoolExpr::Template::PropertyComparison::Matches - perform a Perl regular expression match

=head1 DESCRIPTION

If the property returns multiple values, this comparison returns true if any of the values match

=cut
