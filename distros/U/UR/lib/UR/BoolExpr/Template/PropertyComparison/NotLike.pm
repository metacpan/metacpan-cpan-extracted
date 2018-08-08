
package UR::BoolExpr::Template::PropertyComparison::NotLike;

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
    my $escape = '\\';    
    my $regex = $class->
        comparison_value_and_escape_character_to_regex(
            $comparison_value,
            $escape
        );
    no warnings 'uninitialized';
    foreach my $property_value ( @property_value ) {
        return '' if ($property_value =~ $regex);
    }
    return 1;
}

1;

=pod

=head1 NAME

UR::BoolExpr::Template::PropertyComparison::NotLike - perform a negated SQL-ish like test

=head1 DESCRIPTION

The input test value is assumed to be an SQL 'like' value, where '_'
represents a one character wildcard, and '%' means a 0 or more character
wildcard.  It gets converted to a perl regular expression and used in a
negated match against an object's properties

If the property returns multiple values, this comparison returns false if
any of the values matches the pattern

=cut

