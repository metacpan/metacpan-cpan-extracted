package DataTypeConverter;
use Moose;
use DateTime::Format::ISO8601;
use DateTime::Format::ISO8601::Format;

our %pre_converter_map = ();
our %post_converter_map = ();

sub init
{
    if(%pre_converter_map && %post_converter_map)
    {
        return;
    }

    DataTypeConverter::add_to_map('String',
        sub
        {
            my ( $obj ) = @_;

            return "" . $obj;

        },
        sub
        {
            my ( $obj ) = @_;

            return "" . $obj;

        });

    DataTypeConverter::add_to_map('Long',
        sub
        {
            my ( $obj ) = @_;

            my $long_val = sprintf("%ld", $obj);

            return $long_val;

        },
        sub
        {
            my ( $obj ) = @_;

            my $long_val = sprintf("%ld", $obj);

            return $long_val;

        });

    DataTypeConverter::add_to_map('Integer',
        sub
        {
            my ( $obj ) = @_;

            my $int_val = sprintf("%d", $obj);

            return $int_val

        },
        sub
        {
            my ( $obj ) = @_;

            my $int_val = sprintf("%d", $obj);

            return $int_val

        });

    DataTypeConverter::add_to_map('Double',
        sub
        {
            my ($obj) = @_;

            my $double_val = sprintf("%f", $obj);

            return $double_val;
        },
        sub
        {
            my ($obj) = @_;

            my $double_val = sprintf("%f", $obj);

            return $double_val;
        });

    DataTypeConverter::add_to_map('Float',
    sub
    {
        my ($obj) = @_;

        my $float_val = sprintf("%f", $obj);

        return $float_val;
    },
    sub
    {
        my ($obj) = @_;

        my $float_val = sprintf("%f", $obj);

        return $float_val;
    });

    DataTypeConverter::add_to_map('Boolean',
        sub
        {
            my ( $obj ) = @_;

            my $bool_val = ($obj)? 1 : 0;

            return $bool_val;

        },
        sub
        {
            my ( $obj ) = @_;

            my $bool_val = ( $obj ) ? "true" : "false";

            return $bool_val;

        });

    DataTypeConverter::add_to_map('DateTime',
        sub
        {
            my ( $obj ) = @_;

            my $tz = DateTime::TimeZone->new( name => 'local' );

            $tz = DateTime::TimeZone::Local->TimeZone();

            return DateTime::Format::ISO8601->parse_datetime($obj)->set_time_zone($tz->name);

        },
        sub
        {
            my ( $obj ) = @_;

            $obj->set_nanosecond(0);

            my $format = DateTime::Format::ISO8601::Format->new();

            my $tz = DateTime::TimeZone::Local->TimeZone();

            my $date = $obj->set_time_zone($tz->name);

            my $formatted_datetime = $format->format_datetime($date);

            return $formatted_datetime;

        });

    DataTypeConverter::add_to_map('Date',
        sub
        {
            my ( $obj ) = @_;

            my $tz = DateTime::TimeZone->new( name => 'local' );

            return DateTime::Format::ISO8601->parse_datetime($obj);

        },
        sub
        {
            my ( $obj ) = @_;

            my $test = DateTime::Format::ISO8601::Format->new()->format_date($obj);

            return "".$test;#->format_cldr("yyyy-MM-dd'T'HH:mm:ssZ");

        });
}

sub add_to_map
{
    my ($name, $pre_converter, $post_converter) = @_;

    $pre_converter_map{$name} = $pre_converter;

    $post_converter_map{$name} = $post_converter;
}

sub post_convert
{
    my ($obj, $type) = @_;

    DataTypeConverter::init();

    return $post_converter_map{$type}->($obj);
}

sub pre_convert
{
    my ($obj, $type) = @_;

    DataTypeConverter::init();

    return $pre_converter_map{$type}->($obj);
}

=head1 NAME

com::zoho::crm::api::util::DataTypeConverter - This class converts JSON value to the expected data type.

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<init>

This method is to initialize the PreConverter and PostConverter lambda functions.

=item C<add_to_map>

This method is to add PreConverter and PostConverter instance.

Param name : A String containing the data type class name.

Param pre_converter : A PreConverter method.

Param post_converter : A PostConverter method.

=item C<pre_convert>

This method is to convert JSON value to expected data value.

Param obj : A Object containing the JSON value.

Param type : A String containing the expected method return type.

Returns  A specified data Type containing expected data value.

=item C<post_convert>

This method to convert Perl data to JSON data value.

Param obj : A specified dataType containing a perl data value.

Param type : A String containing the expected method return type.

Returns A specified data Type containing expected data value.


=back

=cut
1;
