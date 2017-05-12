package Types::XMLSchema;
BEGIN {
  $Types::XMLSchema::AUTHORITY = 'cpan:AJGB';
}
#ABSTRACT: XMLSchema compatible Moose types library
$Types::XMLSchema::VERSION = '0.01';
use warnings;
use strict;

use Type::Library
    -base,
    -declare => [qw(
        XsString
        XsInteger
        XsPositiveInteger
        XsNonPositiveInteger
        XsNegativeInteger
        XsNonNegativeInteger
        XsLong
        XsUnsignedLong
        XsInt
        XsUnsignedInt
        XsShort
        XsUnsignedShort
        XsByte
        XsUnsignedByte
        XsBoolean
        XsFloat
        XsDouble
        XsDecimal
        XsDuration
        XsDateTime
        XsTime
        XsDate
        XsGYearMonth
        XsGYear
        XsGMonthDay
        XsGDay
        XsGMonth
        XsBase64Binary
        XsAnyURI

        MathBigFloat
        DateTimeDuration
        DateTime
        IOHandle
        URI
    )];
use Type::Utils -all;
use Types::Standard qw/
    Int
    Str
    Bool
    Num
    ArrayRef
/;

use Regexp::Common qw( number );
use MIME::Base64 qw( encode_base64 );
use Encode qw( encode );
use DateTime::Duration;
use DateTime::TimeZone;
use DateTime;
use IO::Handle;
use URI;
use Math::BigInt;
use Math::BigFloat;


my $MathBigInt       = class_type { class => 'Math::BigInt' };
my $MathBigFloat     = class_type { class => 'Math::BigFloat' };
my $DateTimeDuration = class_type { class => 'DateTime::Duration' };
my $DateTime         = class_type { class => 'DateTime' };
my $IOHandle         = class_type { class => 'IO::Handle' };
my $URI              = class_type { class => 'URI' };


declare XsString =>
    as Str;



declare XsInteger =>
    as $MathBigInt,
    where { ! $_->is_nan && ! $_->is_inf };

coerce XsInteger
    => from Int, via { Math::BigInt->new($_) }
    => from Str, via { Math::BigInt->new($_) };


declare XsPositiveInteger => as $MathBigInt, where { $_ > 0 };
coerce XsPositiveInteger
    => from Int, via { Math::BigInt->new($_) }
    => from Str, via { Math::BigInt->new($_) };


declare XsNonPositiveInteger => as $MathBigInt, where { $_ <= 0 };
coerce XsNonPositiveInteger
    => from Int, via { Math::BigInt->new($_) }
    => from Str, via { Math::BigInt->new($_) };


declare XsNegativeInteger => as $MathBigInt, where { $_ < 0 };
coerce XsNegativeInteger
    => from Int, via { Math::BigInt->new($_) }
    => from Str, via { Math::BigInt->new($_) };


declare XsNonNegativeInteger =>
    as $MathBigInt,
        where { $_ >= 0 };
coerce XsNonNegativeInteger
    => from Int, via { Math::BigInt->new($_) }
    => from Str, via { Math::BigInt->new($_) };


{
    my $min = Math::BigInt->new('-9223372036854775808');
    my $max = Math::BigInt->new('9223372036854775807');

    declare XsLong =>
        as $MathBigInt,
            where { $_ <= $max && $_ >= $min };
    coerce XsLong
        => from Int, via { Math::BigInt->new($_) }
        => from Str, via { Math::BigInt->new($_) };
}


{
    my $max = Math::BigInt->new('18446744073709551615');

    declare XsUnsignedLong =>
        as $MathBigInt,
            where { $_ >= 0 && $_ <= $max };
    coerce XsUnsignedLong
        => from Int, via { Math::BigInt->new($_) }
        => from Str, via { Math::BigInt->new($_) };
}


declare XsInt =>
    as Int,
        where { $_ <= 2147483647 && $_ >= -2147483648 };


declare XsUnsignedInt =>
    as Int,
        where { $_ <= 4294967295 && $_ >= 0};


declare XsShort =>
    as Int,
        where { $_ <= 32767 && $_ >= -32768 };


declare XsUnsignedShort =>
    as Int,
        where { $_ <= 65535 && $_ >= 0 };


declare XsByte =>
    as Int,
        where { $_ <= 127 && $_ >= -128 };


declare XsUnsignedByte =>
    as Int,
        where { $_ <= 255 && $_ >= 0 };


declare XsBoolean =>
    as Bool;



{
    my $m = Math::BigFloat->new(2 ** 24);
    my $min = $m * Math::BigFloat->new(2 ** -149);
    my $max = $m * Math::BigFloat->new(2 ** 104);

    declare XsFloat =>
        as $MathBigFloat,
            where { $_->is_nan || $_->is_inf || ( $_ <= $max && $_ >= $min ) };
    coerce XsFloat
        => from Num, via { Math::BigFloat->new($_) }
        => from Str, via { Math::BigFloat->new($_) };
}


{
    my $m = Math::BigFloat->new(2 ** 53);
    my $min = $m * Math::BigFloat->new(2 ** -1075);
    my $max = $m * Math::BigFloat->new(2 ** 970);

    declare XsDouble =>
        as $MathBigFloat,
            where { $_->is_nan || $_->is_inf || ( $_ < $max && $_ > $min ) };
    coerce XsDouble
        => from Num, via { Math::BigFloat->new($_) }
        => from Str, via { Math::BigFloat->new($_) };
}


declare XsDecimal =>
    as $MathBigFloat,
    where { ! $_->is_nan && ! $_->is_inf };
coerce XsDecimal
    => from Num, via { Math::BigFloat->new($_) }
    => from Str, via { Math::BigFloat->new($_) };



declare XsDuration =>
    as Str,
    where { /^\-?P\d+Y\d+M\d+DT\d+H\d+M\d+(?:\.\d+)?S$/ };

coerce XsDuration
    => from $DateTimeDuration =>
        via {
            my $is_negative;
            if ($_->is_negative) {
                $is_negative = 1;
                $_ = $_->inverse;
            }
            my ($s, $ns) = $_->in_units(qw(
                seconds
                nanoseconds
            ));
            if ( int($ns) ) {
                $s = sprintf("%d.%09d", $s, $ns);
                $s =~ s/0+$//;
            }
            return sprintf('%sP%dY%dM%dDT%dH%dM%sS',
                $is_negative ? '-' : '',
                $_->in_units(qw(
                    years
                    months
                    days
                    hours
                    minutes
                )),
                $s
            );
        };



declare XsDateTime =>
    as Str,
        where { /^\-?\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?(?:[\-\+]\d{2}:?\d{2})?$/ };

coerce XsDateTime
    => from $DateTime =>
        via {
            my $datetime = $_->strftime( $_->nanosecond ? "%FT%T.%N" : "%FT%T");
            $datetime =~ s/0+$// if $_->nanosecond;
            my $tz = $_->time_zone;

            return $datetime if $tz->is_floating;
            return $datetime .'Z' if $tz->is_utc;

            if ( DateTime::TimeZone->offset_as_string($_->offset) =~
                /^([\+\-]\d{2})(\d{2})/ ) {
                return "$datetime$1:$2";
            }
            return $datetime;
        };



declare XsTime =>
    as Str,
        where { /^\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?(?:[\-\+]\d{2}:?\d{2})?$/ };

coerce XsTime
    => from $DateTime =>
        via {
            my $time = $_->strftime( $_->nanosecond ? "%T.%N" : "%T");
            $time =~ s/0+$// if $_->nanosecond;
            my $tz = $_->time_zone;

            return $time if $tz->is_floating;
            return $time .'Z' if $tz->is_utc;

            if ( DateTime::TimeZone->offset_as_string($_->offset) =~
                /^([\+\-]\d{2})(\d{2})/ ) {
                return "$time$1:$2";
            }
            return $time;
        };



declare XsDate =>
    as Str,
        where { /^\-?\d{4}\-\d{2}\-\d{2}Z?(?:[\-\+]\d{2}:?\d{2})?$/ };

coerce XsDate
    => from $DateTime =>
        via {
            my $date = $_->strftime("%F");
            my $tz = $_->time_zone;

            return $date if $tz->is_floating;
            return $date .'Z' if $tz->is_utc;

            if ( DateTime::TimeZone->offset_as_string($_->offset) =~
                /^([\+\-]\d{2})(\d{2})/ ) {
                return "$date$1:$2";
            }
            return $date;

        };



declare __XsIntPair =>
    as ArrayRef[Int] =>
        where { @$_ == 2 };


declare XsGYearMonth =>
    as Str,
        where { /^\d{4}\-\d{2}$/ };

coerce XsGYearMonth
    => from __XsIntPair =>
        via {
            return sprintf("%02d-%02d", @$_);
        }
    => from $DateTime =>
        via {
            return $_->strftime("%Y-%m");
        };



declare XsGYear =>
    as Str,
        where { /^\d{4}$/ };

coerce XsGYear
    => from $DateTime =>
        via {
            return $_->strftime("%Y");
        };



declare XsGMonthDay =>
    as Str,
        where { /^\-\-\d{2}\-\d{2}$/ };

coerce XsGMonthDay
    => from __XsIntPair =>
        via {
            return sprintf("--%02d-%02d", @$_);
        }
    => from $DateTime =>
        via {
            return $_->strftime("--%m-%d");
        };



declare XsGDay =>
    as Str,
        where { /^\-\-\-\d{2}$/ };

coerce XsGDay
    => from Int,
        via {
            return sprintf("---%02d", $_);
        }
    => from $DateTime =>
        via {
            return $_->strftime("---%d");
        };



declare XsGMonth =>
    as Str,
        where { $_ => /^\-\-\d{2}$/ };

coerce XsGMonth
    => from Int,
        via {
            return sprintf("--%02d", $_);
        }
    => from $DateTime =>
        via {
            return $_->strftime("--%m");
        };



declare XsBase64Binary =>
    as Str,
        where { $_ =~ /^[a-zA-Z0-9=\+\/]+$/m };

coerce XsBase64Binary
    => from $IOHandle =>
        via {
            local $/;
            my $content = <$_>;
            return encode_base64(encode("UTF-8", $content));
        };



declare XsAnyURI =>
    as Str,
        where { $_ =~ /^\w+:\/\/.*$/ };

coerce XsAnyURI
    => from $URI,
        via {
            return $_->as_string;
        };


1; # End of Types::XMLSchema

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::XMLSchema - XMLSchema compatible Moose types library

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    package My::Class;
    use Moose;
    use Types::XMLSchema qw( :all );

    has 'string'       => ( is => 'rw', isa => XsString );

    has 'boolean'      => ( is => 'rw', isa => XsBoolean );

    has 'byte'         => ( is => 'rw', isa => XsByte );
    has 'short'        => ( is => 'rw', isa => XsShort );
    has 'int'          => ( is => 'rw', isa => XsInt );
    has 'long'         => ( is => 'rw', isa => XsLong, coerce => 1 );
    has 'integer'      => ( is => 'rw', isa => XsInteger, coerce => 1 );
    has 'float'        => ( is => 'rw', isa => XsFloat, coerce => 1 );
    has 'double'       => ( is => 'rw', isa => XsDouble, coerce => 1 );
    has 'decimal'      => ( is => 'rw', isa => XsDecimal, coerce => 1 );

    has 'duration'     => ( is => 'rw', isa => XsDuration, coerce => 1 );
    has 'datetime'     => ( is => 'rw', isa => XsDateTime, coerce => 1 );
    has 'time'         => ( is => 'rw', isa => XsTime, coerce => 1 );
    has 'date'         => ( is => 'rw', isa => XsDate, coerce => 1 );
    has 'gYearMonth'   => ( is => 'rw', isa => XsGYearMonth, coerce => 1 );
    has 'gYear'        => ( is => 'rw', isa => XsGYear, coerce => 1 );
    has 'gMonthDay'    => ( is => 'rw', isa => XsGMonthDay, coerce => 1 );
    has 'gDay'         => ( is => 'rw', isa => XsGDay, coerce => 1 );
    has 'gMonth'       => ( is => 'rw', isa => XsGMonth, coerce => 1 );

    has 'base64Binary' => ( is => 'rw', isa => XsBase64Binary, coerce => 1 );

    has 'anyURI'            => ( is => 'rw', isa => XsAnyURI, coerce => 1 );

    has 'nonPositiveInteger' => ( is => 'rw', isa => XsNonPositiveInteger, coerce => 1 );
    has 'positiveInteger'    => ( is => 'rw', isa => XsPositiveInteger, coerce => 1 );
    has 'nonNegativeInteger' => ( is => 'rw', isa => XsNonNegativeInteger, coerce => 1 );
    has 'negativeInteger'    => ( is => 'rw', isa => XsNegativeInteger, coerce => 1 );

    has 'unsignedByte'    => ( is => 'rw', isa => XsUnsignedByte );
    has 'unsignedShort'   => ( is => 'rw', isa => XsUnsignedShort );
    has 'unsignedInt'     => ( is => 'rw', isa => XsUnsignedInt );
    has 'unsignedLong'    => ( is => 'rw', isa => XsUnsignedLong, coerce => 1 );

Then, elsewhere:

    my $object = My::Class->new(
        string          => 'string',
        decimal         => Math::BigFloat->new(20.12),
        duration        => DateTime->now - DateTime->(year => 1990),
        base64Binary    => IO::File->new($0),
    );

=head1 DESCRIPTION

This class provides a number of XMLSchema compatible types for your Moose
classes.

=head1 TYPES

=head2 XsString

    has 'string'       => (
        is => 'rw',
        isa => XsString
    );

A wrapper around built-in Str.

=head2 XsInteger

    has 'integer'      => (
        is => 'rw',
        isa => XsInteger,
        coerce => 1
    );

A L<Math::BigInt> object. Set to coerce from Int/Str.

This is defined in XSchema to be an arbitrary size integer.

=head2 XsPositiveInteger

    has 'positiveInteger' => (
        is => 'rw',
        isa => XsPositiveInteger,
        coerce => 1,
    );

A L<Math::BigInt> object. Set to coerce from Int/Str.

This is defined in XSchema to be an arbitrary size integer greater than zero.

=head2 XsNonPositiveInteger

    has 'nonPositiveInteger' => (
        is => 'rw',
        isa => XsNonPositiveInteger,
        coerce => 1,
    );

A L<Math::BigInt> object. Set to coerce from Int/Str.

This is defined in XSchema to be an arbitrary size integer less than or equal
to zero.

=head2 XsNegativeInteger

    has 'negativeInteger' => (
        is => 'rw',
        isa => XsNegativeInteger,
        coerce => 1,
    );

A L<Math::BigInt> object. Set to coerce from Int/Str.

This is defined in XSchema to be an arbitrary size integer less than zero.

=head2 XsNonNegativeInteger

    has 'nonPositiveInteger' => (
        is => 'rw',
        isa => XsNonNegativeInteger,
        coerce => 1,
    );

A L<Math::BigInt> object. Set to coerce from Int/Str.

This is defined in XSchema to be an arbitrary size integer greater than or
equal to zero.

=head2 XsLong

    has 'long' => (
        is => 'rw',
        isa => XsLong,
        coerce => 1,
    );

A 64-bit Integer. Represented as a L<Math::Bigint> object, but limited to the
64-bit (signed) range. Set to coerce from Int/Str.

=head2 XsUnsignedLong

    has 'unsignedLong' => (
        is => 'rw',
        isa => XsUnsignedLong,
        coerce => 1,
    );

A 64-bit Integer. Represented as a L<Math::Bigint> object, but limited to the
64-bit (unsigned) range. Set to coerce from Int/Str.

=head2 XsInt

    has 'int' => (
        is => 'rw',
        isa => XsInt
    );

A 32-bit integer. Represented natively.

=head2 XsUnsignedInt

    has 'unsignedInt' => (
        is => 'rw',
        isa => XsUnsignedInt
    );

A 32-bit integer. Represented natively.

=head2 XsShort

    has 'short' => (
        is => 'rw',
        isa => XsShort
    );

A 16-bit integer. Represented natively.

=head2 XsUnsignedShort

    has 'unsignedShort' => (
        is => 'rw',
        isa => XsUnsignedShort
    );

A 16-bit integer. Represented natively.

=head2 XsByte

    has 'byte' => (
        is => 'rw',
        isa => XsByte
    );

An 8-bit integer. Represented natively.

=head2 XsUnsignedByte

    has 'unsignedByte' => (
        is => 'rw',
        isa => XsUnsignedByte
    );

An 8-bit integer. Represented natively.

=head2 XsBoolean

    has 'boolean' => (
        is => 'rw',
        isa => XsBoolean
    );

A wrapper around built-in Bool.

=head2 XsFloat

    has 'float' => (
        is => 'rw',
        isa => XsFloat,
        coerce => 1,
    );

A single-precision 32-bit Float. Represented as a L<Math::BigFloat> object, but limited to the
32-bit range. Set to coerce from Num/Str.

=head2 XsDouble

    has 'double' => (
        is => 'rw',
        isa => XsDouble,
        coerce => 1,
    );

A double-precision 64-bit Float. Represented as a L<Math::BigFloat> object, but limited to the
64-bit range. Set to coerce from Num/Str.

=head2 XsDecimal

    has 'decimal' => (
        is => 'rw',
        isa => XsDecimal,
        coerce => 1,
    );

Any base-10 fixed-point number. Represented as a L<Math::BigFloat> object. Set to coerce from Num/Str.

=head2 XsDuration

    has 'duration' => (
        is => 'rw',
        isa => XsDuration,
        coerce => 1,
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime::Duration object.

=head2 XsDateTime

    has 'datetime' => (
        is => 'rw',
        isa => XsDateTime,
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object.

=head2 XsTime

    has 'time' => (
        is => 'rw',
        isa => XsTime,
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object.

=head2 XsDate

    has 'date'  => (
        is => 'rw',
        isa => XsDate,
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object.

=head2 XsGYearMonth

    has 'gYearMonth' => (
        is => 'rw',
        isa => XsGYearMonth,
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object or a ArrayRef of two
integers.

=head2 XsGYear

    has 'gYear' => (
        is => 'rw',
        isa => XsGYear,
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object.

=head2 XsGMonthDay

    has 'gMonthDay' => (
        is => 'rw',
        isa => XsGMonthDay,
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object or a ArrayRef of two
integers.

=head2 XsGDay

    has 'gDay' => (
        is => 'rw',
        isa => XsGDay,
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object or Int eg. 24.

=head2 XsGMonth

    has 'gMonth' => (
        is => 'rw',
        isa => XsGMonth,
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object or Int eg. 10.

=head2 XsBase64Binary

    has 'base64Binary' => (
        is => 'rw',
        isa => XsBase64Binary,
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a IO::Handle object - the content of the
file will be encoded to UTF-8 before encoding with base64.

=head2 XsAnyURI

    has 'anyURI' => (
        is => 'rw',
        isa => XsAnyURI,
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a URI object.

=head1 SEE ALSO

=over 4

=item * Enable attributes coercion automatically with

L<MooseX::AlwaysCoerce>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
