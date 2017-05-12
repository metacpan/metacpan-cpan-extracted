use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);

use XML::Pastor::SimpleType;
use XML::Pastor::Builtin::List;
use XML::Pastor::Builtin::Scalar;
use XML::Pastor::Builtin::Numeric;
use XML::Pastor::Builtin::Union;

use XML::Pastor::Builtin::base64Binary;
use XML::Pastor::Builtin::boolean;
use XML::Pastor::Builtin::date;
use XML::Pastor::Builtin::dateTime;
use XML::Pastor::Builtin::hexBinary;

#======================================================================
package XML::Pastor::Builtin::string;
our @ISA = qw(XML::Pastor::Builtin::Scalar);


XML::Pastor::Builtin::string->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::string',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'string|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );

#======================================================================
package XML::Pastor::Builtin::token;
our @ISA = qw(XML::Pastor::Builtin::string);

XML::Pastor::Builtin::token->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::token',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'token|http://www.w3.org/2001/XMLSchema',
                 'whiteSpace' => 'collapse',
               }, 'XML::Pastor::Schema::SimpleType' ) );


#======================================================================
package XML::Pastor::Builtin::integer;
our @ISA = qw(XML::Pastor::Builtin::Numeric);

XML::Pastor::Builtin::integer->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::integer',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'integer|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );


#======================================================================
package XML::Pastor::Builtin::nonNegativeInteger;
our @ISA = qw(XML::Pastor::Builtin::integer);

XML::Pastor::Builtin::nonNegativeInteger->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::nonNegativeInteger',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'minInclusive' => 0,
                 'name' => 'nonNegativeInteger|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );


#======================================================================
package XML::Pastor::Builtin::nonPositiveInteger;
our @ISA = qw(XML::Pastor::Builtin::integer);

XML::Pastor::Builtin::nonPositiveInteger->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::nonPositiveInteger',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'maxInclusive' => 0,
                 'name' => 'nonPositiveInteger|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );


#======================================================================
package XML::Pastor::Builtin::anySimpleType;
our @ISA = qw(XML::Pastor::Builtin::SimpleType);

XML::Pastor::Builtin::anySimpleType->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::anySimpleType',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'anySimpleType|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::anyURI;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::anyURI->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::anyURI',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'anyURI|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );


#======================================================================
package XML::Pastor::Builtin::byte;
our @ISA = qw(XML::Pastor::Builtin::integer);

XML::Pastor::Builtin::byte->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::byte',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'maxInclusive' => 127,                 
				 'minInclusive' => -128,
                 'name' => 'byte|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );





#======================================================================
package XML::Pastor::Builtin::decimal;
our @ISA = qw(XML::Pastor::Builtin::Numeric);

XML::Pastor::Builtin::decimal->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::decimal',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'decimal|http://www.w3.org/2001/XMLSchema',                 
                 'regex'=> qr/^[+-]?\d+(?:\.\d+)?$/,          # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::double;
our @ISA = qw(XML::Pastor::Builtin::Numeric);

XML::Pastor::Builtin::double->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::double',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'double|http://www.w3.org/2001/XMLSchema',
                 
                 # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar                 
                 'regex' => qr/^[+-]?(?:(?:INF)|(?:NaN)|(?:\d+(?:\.\d+)?)(?:[eE][+-]?\d+)?)$/,
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::duration;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::duration->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::duration',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'duration|http://www.w3.org/2001/XMLSchema',
                 
                  # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar who thanks to perlmonk Abigail-II
                 'regex' => qr /^-? 				  # Optional leading minus.
					            P                     # Required.
					            (?=[T\d])             # Duration cannot be empty.
						        (?:(?!-) \d+ Y)?      # Non-negative integer, Y (optional)
           						(?:(?!-) \d+ M)?      # Non-negative integer, M (optional)
           						(?:(?!-) \d+ D)?      # Non-negative integer, D (optional)
								(
           						(?:T (?=\d)           # T, must be followed by a digit.
           						(?:(?!-) \d+ H)?      # Non-negative integer, H (optional)
           						(?:(?!-) \d+ M)?      # Non-negative integer, M (optional)
           						(?:(?!-) \d+\.\d+ S)? # Non-negative decimal, S (optional)
           						)?                    # Entire T part is optional
								)$/x,
               }, 'XML::Pastor::Schema::SimpleType' ) );




#======================================================================
package XML::Pastor::Builtin::ENTITIES;
our @ISA = qw(XML::Pastor::Builtin::List);

XML::Pastor::Builtin::ENTITIES->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::ENTITIES',
                 'contentType' => 'simple',
                 'derivedBy' => 'list',
                 'name' => 'ENTITIES|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::ENTITY;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::ENTITY->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::ENTITY',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'ENTITY|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );


#======================================================================
package XML::Pastor::Builtin::float;
our @ISA = qw(XML::Pastor::Builtin::Numeric);

XML::Pastor::Builtin::float->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::float',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'float|http://www.w3.org/2001/XMLSchema',
                 'regex' => qr/^[+-]?(?:(?:INF)|(?:NaN)|(?:\d+(?:\.\d+)?)(?:[eE][+-]?\d+)?)$/,   # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar
               }, 'XML::Pastor::Schema::SimpleType' ) );


#======================================================================
package XML::Pastor::Builtin::gDay;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::gDay->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::gDay',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'gDay|http://www.w3.org/2001/XMLSchema',
                 'regex' => qr /^---([0-2]\d{1}|3[0|1])(Z?|([+|-]([0-1]\d|2[0-4])\:([0-5]\d))?)$/,   # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::gMonth;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::gMonth->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::gMonth',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'gMonth|http://www.w3.org/2001/XMLSchema',
                 'regex' => qr /^--(0\d|1[0-2])(Z?|([+|-]([0-1]\d|2[0-4])\:([0-5]\d))?)$/,    # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::gMonthDay;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::gMonthDay->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::gMonthDay',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'gMonthDay|http://www.w3.org/2001/XMLSchema',
                 'regex' => qr /^--(\d{2,})-(\d\d)(Z?|([+|-]([0-1]\d|2[0-4])\:([0-5]\d))?)$/,  # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::gYear;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::gYear->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::gYear',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'gYear|http://www.w3.org/2001/XMLSchema',
                 'regex' => qr /^[-]?(\d{4,})(Z?|([+|-]([0-1]\d|2[0-4])\:([0-5]\d))?)$/,   # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar
               }, 'XML::Pastor::Schema::SimpleType' ) );




#======================================================================
package XML::Pastor::Builtin::gYearMonth;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::gYearMonth->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::gYearMonth',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'gYearMonth|http://www.w3.org/2001/XMLSchema',
                 'regex' => qr /^[-]?(\d{4,})-(1[0-2]{1}|0\d{1})(Z?|([+|-]([0-1]\d|2[0-4])\:([0-5]\d))?)$/,   # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar
               }, 'XML::Pastor::Schema::SimpleType' ) );





#======================================================================
package XML::Pastor::Builtin::ID;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::ID->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::ID',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'ID|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );


#======================================================================
package XML::Pastor::Builtin::IDREF;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::IDREF->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::IDREF',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'IDREF|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );




#======================================================================
package XML::Pastor::Builtin::IDREFS;
our @ISA = qw(XML::Pastor::Builtin::List);

XML::Pastor::Builtin::IDREFS->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::IDREFS',
                 'contentType' => 'simple',
                 'derivedBy' => 'list',
                 'name' => 'IDREFS|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );




#======================================================================
package XML::Pastor::Builtin::int;
our @ISA = qw(XML::Pastor::Builtin::integer);

XML::Pastor::Builtin::int->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::int',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'maxInclusive' => 2147483647,                 
				 'minInclusive' => -2147483648, 
                 'name' => 'int|http://www.w3.org/2001/XMLSchema',
                 'regex' => qr/^[+-]?\d+$/,    # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar
               }, 'XML::Pastor::Schema::SimpleType' ) );




#======================================================================
package XML::Pastor::Builtin::language;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::language->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::language',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'language|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::long;
our @ISA = qw(XML::Pastor::Builtin::integer);

XML::Pastor::Builtin::long->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::long',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'long|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );


#======================================================================
package XML::Pastor::Builtin::Name;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::Name->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::Name',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'Name|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::NCName;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::NCName->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::NCName',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'NCName|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::negativeInteger;
our @ISA = qw(XML::Pastor::Builtin::nonPositiveInteger);

XML::Pastor::Builtin::negativeInteger->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::negativeInteger',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'maxInclusive' => -1,
                 'name' => 'negativeInteger|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );




#======================================================================
package XML::Pastor::Builtin::NMTOKEN;
our @ISA = qw(XML::Pastor::Builtin::token);

XML::Pastor::Builtin::NMTOKEN->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::NMTOKEN',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'NMTOKEN|http://www.w3.org/2001/XMLSchema',
                 'regex' => qr/^[-.:\w\d]*$/,    # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar
               }, 'XML::Pastor::Schema::SimpleType' ) );




#======================================================================
package XML::Pastor::Builtin::NMTOKENS;
our @ISA = qw(XML::Pastor::Builtin::List);

XML::Pastor::Builtin::NMTOKENS->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::NMTOKENS',
                 'contentType' => 'simple',
                 'derivedBy' => 'list',
                 'name' => 'NMTOKENS|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );





#======================================================================
package XML::Pastor::Builtin::normalizedString;
our @ISA = qw(XML::Pastor::Builtin::string);

XML::Pastor::Builtin::normalizedString->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::normalizedString',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'normalizedString|http://www.w3.org/2001/XMLSchema',
                 'whiteSpace' => 'replace',
               }, 'XML::Pastor::Schema::SimpleType' ) );


#======================================================================
package XML::Pastor::Builtin::NOTATION;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::NOTATION->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::NOTATION',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'NOTATION|http://www.w3.org/2001/XMLSchema',
                 'regex' => qr /^([A-z][A-z0-9]+:)?([A-z][A-z0-9]+)$/,   # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar
               }, 'XML::Pastor::Schema::SimpleType' ) );




#======================================================================
package XML::Pastor::Builtin::positiveInteger;
our @ISA = qw(XML::Pastor::Builtin::nonNegativeInteger);

XML::Pastor::Builtin::positiveInteger->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::positiveInteger',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'minInclusive' => 1,
                 'name' => 'positiveInteger|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );




#======================================================================
package XML::Pastor::Builtin::QName;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::QName->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::QName',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'QName|http://www.w3.org/2001/XMLSchema',
                 'regex' => qr /^([A-z][A-z0-9]+:)?([A-z][A-z0-9]+)$/,    # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::short;
our @ISA = qw(XML::Pastor::Builtin::integer);

XML::Pastor::Builtin::short->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::short',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'maxInclusive' => 32767,                 
				 'minInclusive' => -32768,
                 'name' => 'short|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );




#======================================================================
package XML::Pastor::Builtin::time;
our @ISA = qw(XML::Pastor::Builtin::Scalar);

XML::Pastor::Builtin::time->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::time',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'time|http://www.w3.org/2001/XMLSchema',
                 'regex' => qr /^[0-2]\d:[0-5]\d:[0-5]\d(\.\d+)?(Z?|([+|-]([0-1]\d|2[0-4])\:([0-5]\d))?)$/,   # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::unsignedByte;
our @ISA = qw(XML::Pastor::Builtin::nonNegativeInteger);

XML::Pastor::Builtin::unsignedByte->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::unsignedByte',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'maxInclusive' => 255,
				 'minInclusive' => 0,                 
                 'name' => 'unsignedByte|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::unsignedInt;
our @ISA = qw(XML::Pastor::Builtin::nonNegativeInteger);

XML::Pastor::Builtin::unsignedInt->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::unsignedInt',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'maxInclusive' => 4294967295,
				 'minInclusive' => 0,
                 'name' => 'unsignedInt|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::unsignedLong;
our @ISA = qw(XML::Pastor::Builtin::nonNegativeInteger);

XML::Pastor::Builtin::unsignedLong->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::unsignedLong',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'unsignedLong|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );



#======================================================================
package XML::Pastor::Builtin::unsignedShort;
our @ISA = qw(XML::Pastor::Builtin::nonNegativeInteger);

XML::Pastor::Builtin::unsignedShort->XmlSchemaType( bless( {
                 'class' => 'XML::Pastor::Builtin::unsignedShort',
                 'contentType' => 'simple',
                 'derivedBy' => 'restriction',
				 'maxInclusive' => 65535,
				 'minInclusive' => 0,                 				 
                 'name' => 'unsignedShort|http://www.w3.org/2001/XMLSchema',
               }, 'XML::Pastor::Schema::SimpleType' ) );



1;

__END__

=head1 NAME

B<XML::Pastor::Builtin> - Module that includes definitions of all L<XML::Pastor> B<W3C builtin> type classes .

=head1 WARNING

This module is used internally by L<XML::Pastor>. You do not normally know much about this module to actually use L<XML::Pastor>.  It is 
documented here for completeness and for L<XML::Pastor> developers. Do not count on the interface of this module. It may change in 
any of the subsequent releases. You have been warned. 

=head1 SYNOPSIS

  use XML::Pastor::Builtin;

=head1 DESCRIPTION

B<XML::Pastor::Builtin> is a module that includes the definitions of the classes that represent 
the W3C B<builtin> simple types. These builtin packages are either directly defined here in this
module or otherwise they are I<use>d by this module so that you don't have to I<use> them in 
your program once you I<use> this module. 

Each builtin type corresponds to a package. So this module defines multiple packages at once. 
In each of the packages, the B<XmlSchemaType> class data accessor is set with an object of
type L<XML::Pastor::Schema::SimpleType>. This object contains the W3C facets that are used during xml validation,
such as pattern, minInclusive, and so on. An internal I<facet> called I<regex> (not defined by W3C) is used to give
the regex patterns that correspond to the B<builtin> types. The I<regex> facet will be guaranteed to be a Perl regex
while the I<pattern> facet (W3C) may divert from Perl regular expressions although they seem identical to me at this time.

All B<builtin> classes descend from L<XML::Pastor::Builtin::SimpleType> which itself descends from
L<XML::Pastor::SimpleType>.

There exist some ancestors for groupings of B<builtin> types. For example, all numeric builtin types descend directly or
indirecly from L<XML::Pastor::Builtin::Numeric>. 

Such groupings are listed below:

=over

=item * L<XML::Pastor::Builtin::List> : List types such as B<NMTOKENS>

=item * L<XML::Pastor::Builtin::Numeric> : Numeric types such as B<integer>

=item * L<XML::Pastor::Builtin::Scalar> : All scalar and numeric types including such as B<string>

=item * L<XML::Pastor::Builtin::Union> : Union types

=back


=head1 EXAMPLE

Below is an example of how the B<double> type is defined in the B<XML::Pastor::Builtin::double> package.

  package XML::Pastor::Builtin::double;
  our @ISA = qw(XML::Pastor::Builtin::Numeric);

  XML::Pastor::Builtin::double->XmlSchemaType( bless( {
                'class' => 'XML::Pastor::Builtin::double',
                'contentType' => 'simple',
                 'derivedBy' => 'restriction',
                 'name' => 'double|http://www.w3.org/2001/XMLSchema',
                 
                 # Regex shamelessly copied from XML::Validator::Schema by Sam Tregar                 
                 'regex' => qr/^[+-]?(?:(?:INF)|(?:NaN)|(?:\d+(?:\.\d+)?)(?:[eE][+-]?\d+)?)$/,
               }, 'XML::Pastor::Schema::SimpleType' ) );



=head1 BUILTIN TYPES

Below is a list of W3C B<builtin> types defined either directly in this module, or I<use>d by it (and so
made available through it). 

=over

=item * B<anySimpleType> defined here in package XML::Pastor::Builtin::anySimpleType;

=item * B<anyURI> defined here in package XML::Pastor::Builtin::anyURI;

=item * B<base64Binary> defined in L<XML::Pastor::Builtin::base64Binary>

=item * B<boolean> defined in L<XML::Pastor::Builtin::boolean>

=item * B<byte> defined here in package XML::Pastor::Builtin::byte;

=item * B<date> defined in L<XML::Pastor::Builtin::date>

=item * B<dateTime> defined in L<XML::Pastor::Builtin::dateTime>

=item * B<decimal> defined here in package XML::Pastor::Builtin::decimal;

=item * B<double> defined here in package XML::Pastor::Builtin::double;

=item * B<duration> defined here in package XML::Pastor::Builtin::duration;

=item * B<ENTITIES> defined here in package XML::Pastor::Builtin::ENTITIES;

=item * B<ENTITY> defined here in package XML::Pastor::Builtin::ENTITY;

=item * B<float> defined here in package XML::Pastor::Builtin::float;

=item * B<gDay> defined here in package XML::Pastor::Builtin::gDay;

=item * B<gMonth> defined here in package XML::Pastor::Builtin::gMonth;

=item * B<gMonthDay> defined here in package XML::Pastor::Builtin::gMonthDay;

=item * B<gYear> defined here in package XML::Pastor::Builtin::gYear;

=item * B<gYearMonth> defined here in package XML::Pastor::Builtin::gYearMonth;

=item * B<hexBinary> defined in L<XML::Pastor::Builtin::hexBinary>

=item * B<ID> defined here in package XML::Pastor::Builtin::ID;

=item * B<IDREF> defined here in package XML::Pastor::Builtin::IDREF;

=item * B<IDREFS> defined here in package XML::Pastor::Builtin::IDREFS;

=item * B<int> defined here in package XML::Pastor::Builtin::int;

=item * B<integer> defined here in package XML::Pastor::Builtin::integer;

=item * B<language> defined here in package XML::Pastor::Builtin::language;

=item * B<long> defined here in package XML::Pastor::Builtin::long;

=item * B<Name> defined here in package XML::Pastor::Builtin::Name;

=item * B<NCName> defined here in package XML::Pastor::Builtin::NCName;

=item * B<negativeInteger> defined here in package XML::Pastor::Builtin::negativeInteger;

=item * B<NMTOKEN> defined here in package XML::Pastor::Builtin::NMTOKEN;

=item * B<NMTOKENS> defined here in package XML::Pastor::Builtin::NMTOKENS;

=item * B<nonNegativeInteger> defined here in package XML::Pastor::Builtin::nonNegativeInteger;

=item * B<nonPositiveInteger> defined here in package XML::Pastor::Builtin::nonPositiveInteger;

=item * B<normalizedString> defined here in package XML::Pastor::Builtin::normalizedString;

=item * B<NOTATION> defined here in package XML::Pastor::Builtin::NOTATION;

=item * B<positiveInteger> defined here in package XML::Pastor::Builtin::positiveInteger;

=item * B<QName> defined here in package XML::Pastor::Builtin::QName;

=item * B<short> defined here in package XML::Pastor::Builtin::short;

=item * B<string> defined here in package XML::Pastor::Builtin::string;

=item * B<time> defined here in package XML::Pastor::Builtin::time;

=item * B<token> defined here in package XML::Pastor::Builtin::token;

=item * B<unsignedByte> defined here in package XML::Pastor::Builtin::unsignedByte;

=item * B<unsignedInt> defined here in package XML::Pastor::Builtin::unsignedInt;

=item * B<unsignedLong> defined here in package XML::Pastor::Builtin::unsignedLong;

=item * B<unsignedShort> defined here in package XML::Pastor::Builtin::unsignedShort;


=back




=head1 BUGS & CAVEATS

There no known bugs at this time, but this doesn't mean there are aren't any. 
Note that, although some testing was done prior to releasing the module, this should still be considered alpha code. 
So use it at your own risk.

Note that there may be other bugs or limitations that the author is not aware of.

=head1 AUTHOR

Ayhan Ulusoy <dev(at)ulusoy(dot)name>



=head1 COPYRIGHT

  Copyright (C) 2006-2007 Ayhan Ulusoy. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 SEE ALSO

See also L<XML::Pastor>, L<XML::Pastor::ComplexType>, L<XML::Pastor::SimpleType>

If you are curious about the implementation, see L<XML::Pastor::Schema::Parser>,
L<XML::Pastor::Schema::Model>, L<XML::Pastor::Generator>.

If you really want to dig in, see L<XML::Pastor::Schema::Attribute>, L<XML::Pastor::Schema::AttributeGroup>,
L<XML::Pastor::Schema::ComplexType>, L<XML::Pastor::Schema::Element>, L<XML::Pastor::Schema::Group>,
L<XML::Pastor::Schema::List>, L<XML::Pastor::Schema::SimpleType>, L<XML::Pastor::Schema::Type>, 
L<XML::Pastor::Schema::Object>

=cut
