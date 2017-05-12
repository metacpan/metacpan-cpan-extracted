#============================================================= -*-perl-*-
#
# XML::Schema::Type::Builtin
#
# DESCRIPTION
#   Definitions of the various simple types built in to XML Schema.
#
# AUTHOR
#   Andy Wardley <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2001 Canon Research Centre Europe Ltd.
#   All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id: Builtin.pm,v 1.2 2001/12/20 13:26:27 abw Exp $
#
# TODO
#   Not yet implemented
#     * uriReference - consult RFC 2396 and RFC 2732
#     * ID - should access document instance to store ID usage
#     * IDREF - should access document instance to check ID exists
#     * IDREFS - as above, and requires list functionality
#     * ENTITY - should access document instance to check ENTITY declared
#     * ENTITIES - as above, and requires list functionality
#     * NMTOKENS - requires list
#     * NOTATION - need document instance to check NOTATION defined
#
#   Incomplete:
#     * float/double - need validation of mantissa length 
#     * long/unsignedLong - can't validate numbers which exceed bounds
#     * QName - needs namespace resolution against prefix
#
#========================================================================

package XML::Schema::Type::Builtin;

use strict;
use XML::Schema::Type::Simple;
use vars qw( $VERSION $DEBUG );

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;


#========================================================================
# Primitive datatypes
#
# Based on XML Schema Part 2: Datatypes, W3C Candidate Recommendation, 
# 24 October 2000, section 3.2.
#========================================================================

#------------------------------------------------------------------------
# string
#------------------------------------------------------------------------

package XML::Schema::Type::string;
use base qw( XML::Schema::Type::Simple );
use vars qw( $ERROR );


#------------------------------------------------------------------------
# boolean
#------------------------------------------------------------------------

package XML::Schema::Type::boolean;
use base qw( XML::Schema::Type::Simple );
use vars qw( $ERROR @FACETS );

@FACETS = (
    whiteSpace  => 'collapse',
    enumeration => {
	value   => [ 'true', 'false' ],
	errmsg  => 'value is not boolean (true/false)',
    },
);


#------------------------------------------------------------------------
# double
#   IEEE double precision 64-bit floating point number.
#------------------------------------------------------------------------

package XML::Schema::Type::double;
use base qw( XML::Schema::Type::Simple );
use vars qw( $ERROR @FACETS );

@FACETS = (
    whiteSpace  => 'collapse',
    \&prepare,
);

sub prepare {
    my ($instance, $type) = @_;
    my $value = $instance->{ value };

    return $type->error('value is empty')
	unless length $value;

    return $type->error("value is not a valid $type->{ name }")
	unless $value =~ /
	    ^
	    ([+-])?		    # sign         ($1)
            (?:
	      (INF)		    # infinity     ($2)
	    | (NaN)		    # not a number ($3) 
	    | (\d+(?:\.\d+)?)	    # mantissa     ($4)
	      (?:[eE]		    # exponent
		([+-])?		    # sign	   ($5)
		(\d+)		    # value        ($6)
	      )?
	    )
	    $
	/x;

    $instance->{ sign      } = $1 || '';
    $instance->{ infinity  } = $2 ? 1 : 0;
    $instance->{ nan       } = $3 ? 1 : 0;
    $instance->{ mantissa  } = $4 || '';
    $instance->{ exp_sign  } = $5 || '';
    $instance->{ exp_value } = $6 || '';
    $instance->{ exponent  } = ($5 || '') . ($6 || '');

    # TODO: need to test bounds of mantissa ( < 2^53 )

    my $exp = $instance->{ exponent };
    return $type->error('double exponent is not valid (-1075 <= e <= 970)')
	if $exp && ($exp < -1075 || $exp > 970);
    
    return 1;
}


#------------------------------------------------------------------------
# float
#   IEEE single precision 32-bit floating point number.  Derived from
#   double with an additional constraint check on the bounds of the
#   mantissa and exponent.
#------------------------------------------------------------------------

package XML::Schema::Type::float;
use base qw( XML::Schema::Type::double );
use vars qw( $ERROR @FACETS );

@FACETS = (
    \&prepare,
);

sub prepare {
    my ($instance, $type) = @_;

    # TODO: need to test bounds of mantissa ( < 2^24 )

    my $exp = $instance->{ exponent };

    return $type->error('float exponent is not valid (-149 <= e <= 104)')
	if $exp && ($exp < -149 || $exp > 104);

    return 1;
}


#------------------------------------------------------------------------
# decimal
#   Arbitrary precision decimal number.
#------------------------------------------------------------------------

package XML::Schema::Type::decimal;
use base qw( XML::Schema::Type::Simple );
use vars qw( $ERROR @FACETS );

@FACETS = (
    whiteSpace => 'collapse',
    \&prepare,
);

sub prepare {
    my ($instance, $type) = @_;
    my $value = $instance->{ value };

    return $type->error('value is empty')
	unless length $value;

    return $type->error("value is not a decimal")
	unless $value =~ /
	    ^
	    ([+-])?		    # sign     ($1)
	    0*(\d+)		    # integer  ($2)
	    (?:\.(\d+)0*)?	    # fraction ($3)
	    $
	/x;

    @$instance{ qw( sign integer fraction ) } = ($1, $2, $3);
    $instance->{ scale     } = length $3;
    $instance->{ precision } = $instance->{ scale } + length $2;

    return 1;
}


#------------------------------------------------------------------------
# timeDuration
#   A duration of time as in the extended format as defined in [ISO 8601
#   Date and Time Formats].  e.g. P7Y1M4DT7H3M12.8S: 7 years, 1 month, 4
#   days, 7 hours, 3 minutes and 12.8 seconds.
#------------------------------------------------------------------------

package XML::Schema::Type::timeDuration;
use base qw( XML::Schema::Type::Simple );
use vars qw( $ERROR @FACETS );

@FACETS = (
    whiteSpace  => 'collapse',
    \&prepare,			    # install direct call to subroutine
);

sub prepare {
    my ($instance, $type) = @_;
    my $value = $instance->{ value };

    return $type->error('value is empty')
	unless length $value;

    return $type->error("value is not a valid timeDuration")
	unless $value =~ /
	    ^
	    (-)?		    # sign ($1)
	    P([^T]*)		    # date ($2)
	    (?:T(.+))?		    # time ($3)
	    $ 
	/x;	    

    return $type->error("value must specify at least one date/time item")
	unless length $2 or $3;

    $instance->{ sign } = $1;
    $instance->{ date } = $2 || '';
    $instance->{ time } = $3 || '';

    return $type->error("value contains an invalid date element")
	unless $instance->{ date } =~ /
	    ^
	    (?:(\d+)Y)?		    # years  ($1)
	    (?:(\d+)M)?		    # months ($2)
	    (?:(\d+)D)?		    # days   ($3)
	    $
	/x;
    @$instance{ qw( years months days ) } = ($1, $2, $3);
    $instance->{ zero_date } = ($1 || $2 || $3) ? 0 : 1;

    return $type->error("value contains an invalid time element")
	unless $instance->{ time } =~ /
	    ^
	    (?:(\d+)H)?		    # hours   ($1)
	    (?:(\d+)M)?		    # minutes ($2)
	    (?:(\d(?:\.\d+)?)S)?    # seconds ($3)
	    $
	/x;
    @$instance{ qw( hours minutes seconds ) } = ($1, $2, $3);
    $instance->{ zero_time } = ($1 || $2 || $3) ? 0 : 1;

    $instance->{ zero } = $instance->{ zero_date } 
                       && $instance->{ zero_time };

    return 1;
}

    
#------------------------------------------------------------------------
# recurringDuration
#   Note that period and duration do not affect the parser implemented in
#   the prepare() method.  Derived types that specify an alternate or
#   truncated lexical format should implement their own prepare()
#   method.
#------------------------------------------------------------------------

package XML::Schema::Type::recurringDuration;
use base qw( XML::Schema::Type::Simple );
use vars qw( $ERROR @FACETS );

@FACETS = (
    whiteSpace => 'collapse',
    sub { $_[1]->prepare($_[0]) },  # install hook to call object method
);

sub init {
    my $self = shift;
    return undef 
	unless $self->SUPER::init(@_);
    return $self->error('duration not defined')
	unless $self->facet('duration');
    return $self->error('period not defined')
	unless $self->facet('period');
    return $self;
}

sub prepare {
    my ($self, $instance) = @_;
    my $value = $instance->{ value };

    return $self->error('value is empty')
	unless length $value;

    return $self->error("value is not a valid recurringDuration")
	unless $value =~ /
	    ^
	    ([+-])?		# sign    ($1)
	    (\d{2,})		# century ($2)
	    (\d{2}) -		# year    ($3)
	    (\d{2}) -		# month   ($4)
	    (\d{2}) T		# day     ($5)
	    (\d{2}) :		# hour    ($6)
            (\d{2}) :		# minute  ($7)
	    (\d{2}(?:.\d+)?)	# second  ($8)
	    (?:			# optional time zone
               (Z)		# UTC     ($9)
	     | ([-+])		# sign    ($10)
	       (\d{2}) :	# hours   ($11)
	       (\d{2})          # minutes ($12)
	    )?
	    $
	/x;

    @$instance{ qw( sign century year month day hour minute second ) }
	= ($1, $2, $3, $4, $5, $6, $7, $8 );
    $instance->{ UTC  } = $9 ? 1 : 0;
    my $zone = $instance->{ zone } = { };
    @$zone{ qw( sign hour minute ) } = ($10, $11, $12);

    return 1;
}


#------------------------------------------------------------------------
# binary
#   Arbitrary binary data.  Must be derived to specify encoding.
#------------------------------------------------------------------------

package XML::Schema::Type::binary;
use base qw( XML::Schema::Type::Simple );
use vars qw( $ERROR @FACETS );

@FACETS = (
    whiteSpace  => 'collapse',
);

sub init {
    my $self = shift;
    return undef 
	unless $self->SUPER::init(@_);
    return $self->error('encoding not defined')
	unless $self->facet('encoding');
    return $self;
}


#------------------------------------------------------------------------
# uriReference
#   Uniform Resource Identifier as defined in Section 4 of [RFC 2396] and
#   amended by [RFC 2732].
#------------------------------------------------------------------------

package XML::Schema::Type::uriReference;
use base qw( XML::Schema::Type::Simple );
use vars qw( $ERROR @FACETS );

@FACETS = (
    whiteSpace  => 'collapse',
    sub { die "uriReference not yet implemented\n" },
);


#------------------------------------------------------------------------
# ENTITY
#------------------------------------------------------------------------

package XML::Schema::Type::ENTITY;
use base qw( XML::Schema::Type::Simple );
use vars qw( $ERROR @FACETS );

@FACETS = (
    whiteSpace  => 'collapse',
    sub { die "ENTITY not yet implemented\n" },
);


#------------------------------------------------------------------------
# QName
#------------------------------------------------------------------------

package XML::Schema::Type::QName;
use base qw( XML::Schema::Type::Simple );
use vars qw( $ERROR @FACETS );

@FACETS = (
    whiteSpace  => 'collapse',
    \&prepare,
);

sub prepare {
    my ($instance, $type) = @_;
    my $value = $instance->{ value };

    return $type->error('value is empty')
	unless length $value;

    return $type->error("value is not a valid QName")
	unless $value =~ /
	    ^
	    (?:
	      ([a-zA-Z_][\w\-.]*?)  # prefix ($1)
	      :
	    )?
	    ([a-zA-Z_][\w\-.]*?)    # local ($2)
	    $
	/x;

    $instance->{ prefix } = $1 || '';
    $instance->{ local  } = $2;

    # TODO: need to validate prefix to a namespace
    $instance->{ namespace } = '???';

    return 1;
}




#========================================================================
# Derived datatypes
#
# Based on XML Schema Part 2: Datatypes, W3C Candidate Recommendation,
# 24 October 2000, section 3.3.
#========================================================================

#------------------------------------------------------------------------
# CDATA
#   As per string but with newlines, carriage returns and tabs converted 
#   to spaces.
#------------------------------------------------------------------------

package XML::Schema::Type::CDATA;
use base qw( XML::Schema::Type::string );
use vars qw( $ERROR @FACETS );

@FACETS = (
    whiteSpace => 'replace'
);


#------------------------------------------------------------------------
# token
#   As per CDATA but with adjacent spaces collapsed to a single space
#   and leading and trailing spaces removed.  Note derivation from 
#   string rather than CDATA.
#------------------------------------------------------------------------

package XML::Schema::Type::token;
use base qw( XML::Schema::Type::string );
use vars qw( $ERROR @FACETS );

@FACETS = (
    whiteSpace => 'collapse'
);


#------------------------------------------------------------------------
# language
#   Derived from token, with a pattern constraint to represent natural 
#   language identifiers as defined by RFC 1766.
#------------------------------------------------------------------------

package XML::Schema::Type::language;
use base qw( XML::Schema::Type::token );
use vars qw( $ERROR @FACETS );

@FACETS = (
    pattern => {
	value  => '^([a-zA-Z]{2}|[iI]-[a-zA-Z]+|[xX]-[a-zA-Z]+)(-[a-zA-Z]+)*$',
	errmsg => 'value is not a language',
    }
);


#------------------------------------------------------------------------
# IDREFS
#------------------------------------------------------------------------

package XML::Schema::Type::IDREFS;
use base qw( XML::Schema::Type::Simple );
use vars qw( $ERROR @FACETS );

@FACETS = (
    sub { die "IDREFS not yet implemented\n" },
);


#------------------------------------------------------------------------
# ENTITIES
#------------------------------------------------------------------------

package XML::Schema::Type::ENTITIES;
use base qw( XML::Schema::Type::Simple );
use vars qw( $ERROR @FACETS );

@FACETS = (
    sub { die "ENTITIES not yet implemented\n" },
);


#------------------------------------------------------------------------
# NMTOKEN
#   String matching the NMTOKEN attribute type from [XML 1.0 
#   Recommendation (Second Edition)].
#------------------------------------------------------------------------

package XML::Schema::Type::NMTOKEN;
use base qw( XML::Schema::Type::token );
use vars qw( $ERROR @FACETS );

@FACETS = (
    pattern => {
	value  => '^[\w\-_.:]+$',
	errmsg => 'value is not a valid NMTOKEN',
    }
);


#------------------------------------------------------------------------
# NMTOKENS
#------------------------------------------------------------------------

package XML::Schema::Type::NMTOKENS;
use base qw( XML::Schema::Type::Simple );
use vars qw( $ERROR @FACETS );

@FACETS = (
    sub { die "NMTOKENS not yet implemented\n" },
);


#------------------------------------------------------------------------
# Name
#   String matching the 'Name' production of [XML 1.0 Recommendation
#   (Second Edition)].
#------------------------------------------------------------------------

package XML::Schema::Type::Name;
use base qw( XML::Schema::Type::token );
use vars qw( $ERROR @FACETS );

@FACETS = (
    pattern => {
	value  => '^[a-zA-Z_:][\w\-_.:]*$',
	errmsg => 'value is not a valid Name',
    }
);


#------------------------------------------------------------------------
# NCName
#   Non-colonized name, a string matching the 'NCName' production of
#   [Namespaces in XML].
#------------------------------------------------------------------------

package XML::Schema::Type::NCName;
use base qw( XML::Schema::Type::token );
use vars qw( $ERROR @FACETS );

@FACETS = (
    pattern => {
	value  => '^[a-zA-Z_][\w\-.]*$',
	errmsg => 'value is not a valid NCName',
    }
);

#------------------------------------------------------------------------
# ID
#   String matching the ID attribute type from [XML 1.0 Recommendation 
#   (Second Edition)].
#------------------------------------------------------------------------

package XML::Schema::Type::ID;
use base qw( XML::Schema::Type::Name );
use vars qw( $ERROR @FACETS );

@FACETS = (
    \&prepare,
);

sub prepare {
    my ($instance, $type) = @_;
    $instance->{ magic } = [ ID => $instance->{ value } ];
    return 1;
}


#------------------------------------------------------------------------
# IDREF
#------------------------------------------------------------------------

package XML::Schema::Type::IDREF;
use base qw( XML::Schema::Type::Name );
use vars qw( $ERROR @FACETS );

@FACETS = (
    \&prepare,
);

sub prepare {
    my ($instance, $type) = @_;
    $instance->{ magic } = [ IDREF => $instance->{ value } ];
    return 1;
}


#------------------------------------------------------------------------
# NOTATION
#------------------------------------------------------------------------

package XML::Schema::Type::NOTATION;
use base qw( XML::Schema::Type::Simple );
use vars qw( $ERROR @FACETS );

@FACETS = (
    sub { die "NOTATION not yet implemented\n" },
);


#------------------------------------------------------------------------
# integer
#------------------------------------------------------------------------

package XML::Schema::Type::integer;
use base qw( XML::Schema::Type::decimal );
use vars qw( $ERROR @FACETS );

@FACETS = (
    scale => {
	value  => 0,
	fixed  => 1,
	errmsg => 'value is not an integer',
    },
);


#------------------------------------------------------------------------
# nonPositiveInteger
#   An integer value less than or equal to 0
#------------------------------------------------------------------------

package XML::Schema::Type::nonPositiveInteger;
use base qw( XML::Schema::Type::integer );
use vars qw( $ERROR @FACETS );

@FACETS = (
    maxInclusive => { 
	value  => 0, 
	errmsg => 'value is positive',
    },
);


#------------------------------------------------------------------------
# negativeInteger
#   An integer value less than 0
#------------------------------------------------------------------------

package XML::Schema::Type::negativeInteger;
use base qw( XML::Schema::Type::integer );
use vars qw( $ERROR @FACETS );

@FACETS = (
    maxInclusive => { 
	value  => -1, 
	errmsg => 'value is not negative'
     },
);


#------------------------------------------------------------------------
# long 
#   An integer in the range -9223372036854775808 to 9223372036854775807.
#   See comments in docs/nonconform relating to failure to correctly
#   validate long numbers.
#------------------------------------------------------------------------

package XML::Schema::Type::long;
use base qw( XML::Schema::Type::integer );
use vars qw( $ERROR @FACETS );

@FACETS = (
    minInclusive => -9223372036854775808,
    maxInclusive =>  9223372036854775807,
);


#------------------------------------------------------------------------
# int
#   An integer value in the range -2147483648 to 2147483647.  Note that 
#   we derive directly from integer rather than long.
#------------------------------------------------------------------------

package XML::Schema::Type::int;
use base qw( XML::Schema::Type::integer );
use vars qw( $ERROR @FACETS );

@FACETS = (
    minInclusive => -2147483648,
    maxInclusive =>  2147483647,
);


#------------------------------------------------------------------------
# short
#   An integer value in the range -32768 to 32767.  Note that 
#   we derive directly from integer rather than int.
#------------------------------------------------------------------------

package XML::Schema::Type::short;
use base qw( XML::Schema::Type::integer );
use vars qw( $ERROR @FACETS );

@FACETS = (
    minInclusive => -32768,
    maxInclusive =>  32767,
);


#------------------------------------------------------------------------
# byte
#   An integer in the range -128 to 127.  Again, this is derived 
#   directly from integer rather than via short.
#------------------------------------------------------------------------

package XML::Schema::Type::byte;
use base qw( XML::Schema::Type::integer );
use vars qw( $ERROR @FACETS );

@FACETS = (
    minInclusive => -128,
    maxInclusive =>  127,
);


#------------------------------------------------------------------------
# nonNegativeInteger
#   An integer value greater than or equal to 0
#------------------------------------------------------------------------

package XML::Schema::Type::nonNegativeInteger;
use base qw( XML::Schema::Type::integer );
use vars qw( $ERROR @FACETS );

@FACETS = (
    minInclusive => { 
	value  => 0, 
	errmsg => 'value is negative',
     },
);


#------------------------------------------------------------------------
# unsignedLong 
#   An integer in the range 0 to 18446744073709551615
#   See comments in docs/nonconform relating to failure to correctly
#   validate long numbers.
#------------------------------------------------------------------------

package XML::Schema::Type::unsignedLong;
use base qw( XML::Schema::Type::nonNegativeInteger );
use vars qw( $ERROR @FACETS );

@FACETS = (
    maxInclusive => 18446744073709551615,
);


#------------------------------------------------------------------------
# unsignedInt 
#   An integer in the range 0 to 4294967295.  This is derived directly
#   from nonNegativeInteger rather than via unsignedLong.
#------------------------------------------------------------------------

package XML::Schema::Type::unsignedInt;
use base qw( XML::Schema::Type::nonNegativeInteger );
use vars qw( $ERROR @FACETS );

@FACETS = (
    maxInclusive => 4294967295,
);


#------------------------------------------------------------------------
# unsignedShort 
#   An integer in the range 0 to 65535.  This is derived directly
#   from nonNegativeInteger rather than via unsignedInt.
#------------------------------------------------------------------------

package XML::Schema::Type::unsignedShort;
use base qw( XML::Schema::Type::nonNegativeInteger );
use vars qw( $ERROR @FACETS );

@FACETS = (
    maxInclusive => 65535,
);


#------------------------------------------------------------------------
# unsignedByte
#   An unsigned byte in the range 0 to 255.  Again, this is derived 
#   directly from nonNegativeInteger rather than via unsignedShort.
#------------------------------------------------------------------------

package XML::Schema::Type::unsignedByte;
use base qw( XML::Schema::Type::nonNegativeInteger );
use vars qw( $ERROR @FACETS );

@FACETS = (
    maxInclusive => 255,
);


#------------------------------------------------------------------------
# positiveInteger 
#   An integer value greater than 0
#------------------------------------------------------------------------

package XML::Schema::Type::positiveInteger;
use base qw( XML::Schema::Type::integer );
use vars qw( $ERROR @FACETS );

@FACETS = (
    minInclusive => { 
	value  => 1, 
	errmsg => 'value is not positive',
    },
);


#------------------------------------------------------------------------
# timeInstant
#------------------------------------------------------------------------

package XML::Schema::Type::timeInstant;
use base qw( XML::Schema::Type::recurringDuration );
use vars qw( $ERROR @FACETS );

@FACETS = (
    period   => { value => 'P0Y', fixed => 1 },
    duration => { value => 'P0Y', fixed => 1 },
);


#------------------------------------------------------------------------
# time
#------------------------------------------------------------------------

package XML::Schema::Type::time;
use base qw( XML::Schema::Type::recurringDuration );
use vars qw( $ERROR @FACETS );

@FACETS = (
    period   => { value => 'P1D', fixed => 1 },
    duration => { value => 'P0Y', fixed => 1 },
);

sub prepare {
    my ($self, $instance) = @_;
    my $value = $instance->{ value };

    return $self->error('value is empty')
	unless length $value;

    return $self->error("value is not a valid date")
	unless $value =~ /
	    ^
	    (\d{2}) :		# hour    ($1)
            (\d{2}) :		# minute  ($2)
	    (\d{2}(?:.\d+)?)	# second  ($3)
	    (?:			# optional time zone
               (Z)		# UTC     ($4)
	     | ([-+])		# sign    ($5)
	       (\d{2}) :	# hours   ($6)
	       (\d{2})          # minutes ($7)
	    )?
	    $
	/x;

    @$instance{ qw( hour minute second ) } = ($1, $2, $3);
    $instance->{ UTC  } = $4 ? 1 : 0;
    my $zone = $instance->{ zone } = { };
    @$zone{ qw( sign hour minute ) } = ($5, $6, $7);

    return 1;
}


#------------------------------------------------------------------------
# timePeriod
#------------------------------------------------------------------------

package XML::Schema::Type::timePeriod;
use base qw( XML::Schema::Type::recurringDuration );
use vars qw( $ERROR @FACETS );

@FACETS = (
    period => { value => 'P0Y', fixed => 1 },
);


#------------------------------------------------------------------------
# date
#------------------------------------------------------------------------

package XML::Schema::Type::date;
use base qw( XML::Schema::Type::timePeriod );
use vars qw( $ERROR @FACETS );

@FACETS = (
    duration => { value => 'P1D', fixed => 1 },
);

sub prepare {
    my ($self, $instance) = @_;
    my $value = $instance->{ value };

    return $self->error('value is empty')
	unless length $value;

    return $self->error("value is not a valid date")
	unless $value =~ /
	    ^
	    ([-+]?)		# sign    ($1)
	    (\d{2,})		# century ($2)
	    (\d{2}) -		# year    ($3)
	    (\d{2}) -		# month   ($4)
	    (\d{2})		# day     ($5)
	    $
	/x;

    @$instance{ qw( sign century year month day ) } = ( $1, $2, $3, $4, $5 );

    return 1;
}


#------------------------------------------------------------------------
# month
#------------------------------------------------------------------------

package XML::Schema::Type::month;
use base qw( XML::Schema::Type::timePeriod );
use vars qw( $ERROR @FACETS );

@FACETS = (
    duration => { value => 'P1M', fixed => 1 },
);

sub prepare {
    my ($self, $instance) = @_;
    my $value = $instance->{ value };

    return $self->error('value is empty')
	unless length $value;

    return $self->error("value is not a valid month")
	unless $value =~ /
	    ^
	    ([-+]?)		# sign    ($1)
	    (\d{2,})		# century ($2)
	    (\d{2}) -		# year    ($3)
	    (\d{2}) 		# month   ($4)
	    $
	/x;

    @$instance{ qw( sign century year month ) } = ( $1, $2, $3, $4 );

    return 1;
}


#------------------------------------------------------------------------
# year
#------------------------------------------------------------------------

package XML::Schema::Type::year;
use base qw( XML::Schema::Type::timePeriod );
use vars qw( $ERROR @FACETS );

@FACETS = (
    duration => { value => 'P1Y', fixed => 1 },
);

sub prepare {
    my ($self, $instance) = @_;
    my $value = $instance->{ value };

    return $self->error('value is empty')
	unless length $value;

    return $self->error("value is not a valid year")
	unless $value =~ /
	    ^
	    ([-+]?)		# sign    ($1)
	    (\d{2,})		# century ($2)
	    (\d{2})		# year    ($3)
	    $
	/x;

    @$instance{ qw( sign century year ) } = ( $1, $2, $3 );

    return 1;
}


#------------------------------------------------------------------------
# century
#------------------------------------------------------------------------

package XML::Schema::Type::century;
use base qw( XML::Schema::Type::timePeriod );
use vars qw( $ERROR @FACETS );

@FACETS = (
    duration => { value => 'P100Y', fixed => 1 },
);

sub prepare {
    my ($self, $instance) = @_;
    my $value = $instance->{ value };

    return $self->error('value is empty')
	unless length $value;

    return $self->error("value is not a valid century")
	unless $value =~ /
	    ^
	    ([-+]?)		# sign    ($1)
	    (\d{2,})		# century ($2)
	    $
	/x;

    @$instance{ qw( sign century ) } = ( $1, $2 );

    return 1;
}


#------------------------------------------------------------------------
# recurringDate
#------------------------------------------------------------------------

package XML::Schema::Type::recurringDate;
use base qw( XML::Schema::Type::recurringDuration );
use vars qw( $ERROR @FACETS );

@FACETS = (
    duration => { value => 'P1D', fixed => 1 },
    period   => { value => 'P1Y', fixed => 1 },
);

sub prepare {
    my ($self, $instance) = @_;
    my $value = $instance->{ value };

    return $self->error('value is empty')
	unless length $value;

    return $self->error("value is not a valid recurringDate")
	unless $value =~ /
	    ^
	    --
	    (\d{2}) -		# month   ($1)
	    (\d{2})		# day     ($2)
	    $
	/x;

    @$instance{ qw( month day ) } = ( $1, $2 );

    return 1;
}


#------------------------------------------------------------------------
# recurringDay
#------------------------------------------------------------------------

package XML::Schema::Type::recurringDay;
use base qw( XML::Schema::Type::recurringDuration );
use vars qw( $ERROR @FACETS );

@FACETS = (
    duration => { value => 'P1D', fixed => 1 },
    period   => { value => 'P1M', fixed => 1 },
);

sub prepare {
    my ($self, $instance) = @_;
    my $value = $instance->{ value };

    return $self->error('value is empty')
	unless length $value;

    return $self->error("value is not a valid recurringDay")
	unless $value =~ /
	    ^
	    ---
	    (\d{2})		# day     ($1)
	    $
	/x;

    $instance->{ day } = $1;

    return 1;
}

1;

__END__

=head1 NAME

XML::Schema::Type::Builtin - built in datatypes for XML Schema

=head1 SYNOPSIS

    use XML::Schema::Type::Builtin;

=head1 DESCRIPTION

This module implements the simple datatype built in to XML Schema.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version $Revision: 1.2 $ of the XML::Schema::Type::Builtin,
distributed with version 0.1 of the XML::Schema module set.

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also L<XML::Schema> and L<XML::Schema::Type::Simple>.

