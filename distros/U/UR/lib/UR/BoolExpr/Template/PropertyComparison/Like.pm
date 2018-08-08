
package UR::BoolExpr::Template::PropertyComparison::Like;

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
    return '' unless defined ($comparison_value);  # property like NULL should always be false
    my $escape = '\\';    
    my $regex = $class->
        comparison_value_and_escape_character_to_regex(
            $comparison_value,
            $escape
        );
    no warnings 'uninitialized';
    foreach my $value ( @property_value ) {
        return 1 if $value =~ $regex;
    }
    return '';
}

1;

=pod 

=head1 NAME 

UR::BoolExpr::Template::PropertyComparison::Like - perform an SQL-ish like test

=head1 DESCRIPTION

The input test value is assumed to be an SQL 'like' value, where '_'
represents a one character wildcard, and '%' means a 0 or more character
wildcard.  It gets converted to a perl regular expression and used to match
against an object's properties.

If the property returns multiple values, this comparison returns true if any of the values
match.


=cut

