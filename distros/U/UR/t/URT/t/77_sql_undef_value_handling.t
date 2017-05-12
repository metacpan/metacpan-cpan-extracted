use strict;
use warnings;

# Test the different ways that SQL's handling of NULL might differ
# with the way Perl and UR convert NULL to undef and the various
# numeric and string conversions when doing comparisions.  We want UR's
# object cache to return the same results that a query against the database
# would

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 227;
use URT::DataSource::SomeSQLite;


my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

ok($dbh, 'Got DB handle');

ok( $dbh->do("create table things (thing_id integer, value integer)"),
   'Created things table');

$dbh->do("insert into things (thing_id, value) values (1, NULL)");
$dbh->do("Insert into things (thing_id, value) values (2, NULL)");
ok($dbh->commit(), 'DB commit');
           
UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => [
        thing_id => { is => 'Integer' },
    ],
    has_optional => [
        value => { is => 'Integer' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'things',
);


my @result;

# For the equality operator, "value => undef" is converted to SQL as
# "value IS NULL", not "value = NULL, so it should return the items

foreach my $test (
        [ 'undef' => undef ],
        [ "''" => '' ],
) {
    # undef and the empty string both mean NULL
    my($value_as_string, $value) = @$test;

    @result = URT::Thing->get(value => $value);
    is(scalar(@result), 2, "value => $value_as_string loaded 2 items");

    @result = URT::Thing->get(value => $value);
    is(scalar(@result), 2, "value => $value_as_string returned all 2 items");

    URT::Thing->unload();  # clear object and query cache
}

# For other values using the equality operator, it should return nothing
foreach my $value ( 0, 1, -1) {
    operator_returns_object_count('', $value,0);
}


## != for non-null values should return both things
foreach my $value ( 0, 1, -1) {
    my @result = URT::Thing->get(value => { operator => '!=', value => $value});
    is(scalar(@result), 2, "value != $value (old syntax) loaded 2 items");

    @result = URT::Thing->get(value => { operator => '!=', value => $value});
    is(scalar(@result), 2, "value != $value (old syntax) returned 2 items");

    URT::Thing->unload();  # clear object and query cache

    @result = URT::Thing->get('value !=' => $value);
    is(scalar(@result), 2, "value != $value (new syntax) loaded 2 items");

    @result = URT::Thing->get('value !=' => $value);
    is(scalar(@result), 2, "value != $value (new syntax) returned 2 items");

    URT::Thing->unload();  # clear object and query cache
}

# the 'false' operator should return both things, since NULL is false
{
    my @result = URT::Thing->get(value => { operator => 'false', value => '' });
    is(scalar(@result), 2, "value is false (old syntax) loaded 2 items");

    @result = URT::Thing->get(value => { operator => 'false', value => ''});
    is(scalar(@result), 2, "value is false (old syntax) returned 2 items");

    URT::Thing->unload();  # clear object and query cache

    @result = URT::Thing->get('value false' => 1);
    is(scalar(@result), 2, "value is false (new syntax) loaded 2 items");

    @result = URT::Thing->get('value false' => 1);
    is(scalar(@result), 2, "value is false (new syntax) returned 2 items");

    URT::Thing->unload();  # clear object and query cache
}    


foreach my $operator ( qw( < <= > >= true ) ) {
    foreach my $value ( undef, 0, "", 1, -1) {

        operator_returns_object_count($operator,$value,0);

        last if ($operator eq 'true' or $operator eq 'false'); # true and false don't use the 'value' anyway
    }
}

# FIXME - uninitialized warnings here
foreach my $operator ( 'like', 'not like' ) {
    foreach my $value ( undef, '%', '%1', '%1%' ) {

        operator_returns_object_count($operator, $value, 0)
    }
}

# Supress messages about null in-clauses.
URT::DataSource::SomeSQLite->warning_messages_callback(
    sub {
        my ($self,$msg) = @_;
        if ($msg =~ m/Null in-clause passed/) {
            $_[1] = undef;
        }
    }
);

# 'in' operator
# value => [undef] does SQL to include NULL items
operator_returns_object_count('in', [undef], 2);

operator_returns_object_count('not in', [undef], 0);

foreach my $operator ( '', 'in', 'not in' ) {
    foreach my $value ( [], [1] ) {
        operator_returns_object_count($operator, $value, 0);
    }
}

# 'between' operator
foreach my $value ( [undef, undef], [1,1], [0,1], [-1,0], [-1,-1],
                    [undef, 1], [undef, 0], [undef, -1],
                    [1, undef], [0, undef], [-1, undef] )
{
    operator_returns_object_count('between', $value, 0);

}
 
sub operator_returns_object_count {
    my($operator,$value,$expected_count) = @_;

    if (ref($value) eq 'ARRAY' and !$operator) {
        $operator = 'in';
    }

    my $print_operator = $operator || '=>';

    my $print_value;
    if (! defined $value) {
        $print_value = '(undef)';
    } elsif (length($value) == 0 ) {
        $print_value = '""';
    } elsif (ref($value) eq 'ARRAY') {
        $print_value = '[' . join(",", map { defined($_) ? "'$_'" : '(undef)' } @$value) . ']';
    } else {
        $print_value = $value;
    }

    # Original non-eq-operator syntax
    @result = URT::Thing->get(value => { operator => $operator, value => $value });
    is(scalar(@result), $expected_count, "value $print_operator $print_value (old syntax) loads $expected_count item(s)");
    URT::Thing->unload();  # clear object and query cache
    URT::Thing->get(1);    # Get an object into the cache

    @result = URT::Thing->get(value => { operator => $operator, value => $value });
    is(scalar(@result), $expected_count, "value $print_operator $print_value (old syntax) returns $expected_count item(s)");
    URT::Thing->unload();


    # New syntax
    my $property_string = "value $operator";
    @result = URT::Thing->get($property_string => $value);
    is(scalar(@result), $expected_count, "value $print_operator $print_value (new syntax) loads $expected_count item(s)");

    URT::Thing->unload();  # clear object and query cache
    URT::Thing->get(1);    # Get an object into the cache

    @result = URT::Thing->get($property_string => $value);
    is(scalar(@result), $expected_count, "value $print_operator $print_value (new syntax) returns $expected_count item(s)");
    URT::Thing->unload();
}


