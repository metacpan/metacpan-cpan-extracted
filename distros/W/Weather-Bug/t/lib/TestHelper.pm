use Test::Builder;
use Test::Group;
use DateTime;

#
# Special test method that allows for specialized testing of Temperature
# objects. The arguments to this function are
#
# $temp - Temperature object to test
# $name - name of the test
# $desc - description of the tests to run as a hashref
#
# The $desc hashref contains tells which individual subtests to run on
# the object. The defined subtests are:
#
# null - if set to the true value test is_null() returns true, defaults to
#        testing if it is false.
# f - the result of the f() method must match the value of this parameter
# c - the result of the c() method must match the value of this parameter
# is_SI -the result of the is_SI() method must match the value of this parameter
# str - the results of stringify() direct interpolation of the object must
#       match the value of this parameter.
#
# In addition, the object is always tested if it is a Temperature
#
sub temperature_ok
{
    my $temp = shift;
    my $name = shift;
    my $desc = shift;

    test $name => sub {
        isa_ok( $temp, 'Weather::Bug::Temperature' );
        if( $desc->{null} )
        {
            ok( $temp->is_null(), "is null Temperature" );
        }
        else
        {
            ok( !$temp->is_null(), "is not null Temperature" );
        }
        if( exists $desc->{f} )
        {
            is( $temp->f(), $desc->{f}, "F value matches" );
        }
        if( exists $desc->{c} )
        {
            is( $temp->c(), $desc->{c}, "C value matches" );
        }
        if( exists $desc->{is_SI} )
        {
            is( $temp->is_SI(), $desc->{is_SI}, "Correct units" );
        }
        if( exists $desc->{str} )
        {
            is( $temp->stringify(), $desc->{str}, "Correct string form" );
            is( "$temp", $desc->{str}, "Correct string form, overload" );
        }
    };
}

#
# Special test method that allows for specialized testing of Temperature
# objects. The arguments to this function are
#
# $q - Quantity object to test
# $name - name of the test
# $desc - description of the tests to run as a hashref
#
# The $desc hashref contains tells which individual subtests to run on
# the object. The defined subtests are:
#
# null - if set to the true value test is_null() returns true, defaults to
#        testing if it is false.
# value - the result of the value() method must match the value of this parameter
# units - the result of the units() method must match the value of this parameter
# str - the results of stringify() direct interpolation of the object must
#       match the value of this parameter.
#
# In addition, the object is always tested if it is a Quantity
#
sub quantity_ok
{
    my $q = shift;
    my $name = shift;
    my $desc = shift;

    test $name => sub {
        isa_ok( $q, 'Weather::Bug::Quantity' );
        if( $desc->{null} )
        {
            ok( $q->is_null(), "is null Quantity" );
        }
        else
        {
            ok( !$q->is_null(), "is not null Quantity" );
        }
        if( exists $desc->{value} )
        {
            is( $q->value(), $desc->{value}, "value matches" );
        }
        if( exists $desc->{units} )
        {
            is( $q->units(), $desc->{units}, "units match" );
        }
        if( exists $desc->{str} )
        {
            is( $q->stringify(), $desc->{str}, "string form correct" );
            is( "$q", $desc->{str}, "string form correct, overload" );
        }
    };
}

#
# Special test method that allows for specialized testing of DateTime
# objects. The arguments to this function are
#
# $dt - DateTime object to test
# $name - name of the test
# $desc - description of the tests to run as a hashref
#
# The $desc hashref contains tells which individual subtests to run on
# the object. The defined subtests are:
#
# ymd - supplies a string to be tested against the output of the ymd()
#       method of the object, formatted YYYY-MM-DD
# hms - supplies a string to be tested against the output of the hms()
#       method of the object, formatted HH:MM:SS
# tz - supplies a string to be tested against the name of the result of
#      the time_zone() method of the object.
#
# In addition, the object is always tested if it is a DateTime
#
sub datetime_ok
{
    my $dt = shift;
    my $name = shift;
    my $desc = shift;

    test $name => sub {
        isa_ok( $dt, 'DateTime' );
        if(exists $desc->{ymd})
        {
            is( $dt->ymd(), $desc->{ymd}, 'Date looks right.' );
        }
        if(exists $desc->{hms})
        {
            is( $dt->hms(), $desc->{hms}, 'Time looks right.' );
        }
        if(exists $desc->{tz})
        {
            is( $dt->time_zone()->name(), $desc->{tz}, 'TimeZone looks right.' );
        }
    };
}

1;

