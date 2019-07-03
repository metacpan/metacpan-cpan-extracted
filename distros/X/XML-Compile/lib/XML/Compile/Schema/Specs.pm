# Copyrights 2006-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::Schema::Specs;
use vars '$VERSION';
$VERSION = '1.63';


use warnings;
use strict;

use Log::Report       'xml-compile';

use XML::Compile::Schema::BuiltInTypes   qw/%builtin_types/;
use XML::Compile::Util qw/SCHEMA1999 SCHEMA2000 SCHEMA2001 unpack_type/;


### Who will extend this?
# everything which is not caught by a special will need to pass through
# the official meta-scheme: the scheme of the scheme.  These lists are
# used to restrict the namespace to the specified, hiding all helper
# types.

my @builtin_common = qw/
 boolean
 byte
 date
 decimal
 double
 duration
 ENTITIES
 ENTITY
 float
 ID
 IDREF
 IDREFS
 int
 integer
 language
 long
 Name
 NCName
 negativeInteger
 NMTOKEN
 NMTOKENS
 nonNegativeInteger
 nonPositiveInteger
 NOTATION
 pattern
 positiveInteger
 QName
 short
 string
 time
 token
 unsignedByte
 unsignedInt
 unsignedLong
 unsignedShort
 yearMonthDuration
 /;

my @builtin_extra_1999 = qw/
 binary
 recurringDate
 recurringDay
 recurringDuration
 timeDuration
 timeInstant
 timePeriod
 uriReference
 year
 /;

my @builtin_extra_2000 = (@builtin_extra_1999, qw/
 anyType
 CDATA
 / );

my @builtin_extra_2001  = qw/
 anySimpleType
 anyType
 anyURI
 base64Binary
 dateTime
 dayTimeDuration
 error
 gDay
 gMonth
 gMonthDay
 gYear
 gYearMonth
 hexBinary
 normalizedString
 precisionDecimal
 /;

my %builtin_public_1999 = map { ($_ => $_) }
   @builtin_common, @builtin_extra_1999;

my %builtin_public_2000 = map { ($_ => $_) }
   @builtin_common, @builtin_extra_2000;

my %builtin_public_2001 = map { ($_ => $_) }
   @builtin_common, @builtin_extra_2001;

my %sloppy_int_version =
 ( integer            => 'int'
 , long               => 'int'
 , nonNegativeInteger => 'unsigned_int'
 , nonPositiveInteger => 'non_pos_int'
 , positiveInteger    => 'positive_int'
 , negativeInteger    => 'negative_int'
 , unsignedLong       => 'unsigned_int'
 , unsignedInt        => 'unsigned_int'
 );

my %sloppy_float_version = map +($_ => 'sloppy_float'),
   qw/decimal precisionDecimal float double/;

my %schema_1999 =
 ( uri_xsd => SCHEMA1999
 , uri_xsi => SCHEMA1999.'-instance'

 , builtin_public => \%builtin_public_1999
 );

my %schema_2000 =
 ( uri_xsd => SCHEMA2000
 , uri_xsi => SCHEMA2000.'-instance'

 , builtin_public => \%builtin_public_2000
 );

my %schema_2001 =
 ( uri_xsd  => SCHEMA2001
 , uri_xsi  => SCHEMA2001 .'-instance'

 , builtin_public => \%builtin_public_2001
 );

my %schemas = map { ($_->{uri_xsd} => $_) }
 \%schema_1999, \%schema_2000, \%schema_2001;


sub predefinedSchemas() { keys %schemas }


sub predefinedSchema($) { defined $_[1] ? $schemas{$_[1]} : () }


sub builtInType($$;$@)
{   my ($class, $node, $ns) = (shift, shift, shift);
    my $name = @_ % 1 ? shift : undef;
    ($ns, $name) = unpack_type $ns
        unless defined $name;

    my $schema = $schemas{$ns}
        or return ();

    my %args = @_;

    return $builtin_types{boolean_with_Types_Serialiser}
		if $args{json_friendly} && $name eq 'boolean';

    return $builtin_types{$sloppy_int_version{$name}}
        if $args{sloppy_integers} && exists $sloppy_int_version{$name};

    if($args{sloppy_floats} && (my $maptype = $sloppy_float_version{$name}))
    {   return $builtin_types{sloppy_float_force_NV}
            if $args{json_friendly} && $maptype eq 'sloppy_float';

        return $builtin_types{$maptype};
    }

    # only official names are exported this way
    my $public = $schema->{builtin_public}{$name};
    defined $public ? $builtin_types{$public} : ();
}

1;
