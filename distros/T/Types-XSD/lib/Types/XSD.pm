package Types::XSD;

use 5.008003;
use strict;
use warnings;
use utf8;

BEGIN {
	$Types::XSD::AUTHORITY = 'cpan:TOBYINK';
	$Types::XSD::VERSION   = '0.005';
}

use B qw(perlstring);
use Carp;
use DateTimeX::Auto qw( dt dur );
use DateTime::Incomplete ();
use Type::Utils;
use Type::Library -base, -declare => qw(
	Name NmToken NmTokens NCName Id IdRef IdRefs Entity Entities
	QName Notation Duration DateTime Time Date GYearMonth
	GYear GMonthDay GDay GMonth
	DateTimeStamp YearMonthDuration DayTimeDuration
);
use Types::Standard;
use Types::XSD::Lite 0.003 ();
use XML::RegExp;

our @EXPORT_OK = qw( dt_cmp dur_cmp dt_parse dur_parse );

BEGIN {
	Type::Utils::extends('Types::XSD::Lite');
	
	*create_range_check = \&Types::XSD::Lite::create_range_check;
	*quick_range_check  = \&Types::XSD::Lite::quick_range_check;
	*hex_length         = \&Types::XSD::Lite::hex_length;
	*b64_length         = \&Types::XSD::Lite::b64_length;
	*facet              = \&Types::XSD::Lite::facet;
};

use constant MAGIC_DATES => map dt($_), qw( 1696-09-01 1697-02-01 1903-03-01 1903-07-01 );
use constant MAGIC_TABLE => +{ "-1-1-1-1" => -1, "0000" => 0, "1111" => 1 };
sub dur_cmp
{
	my @durations = map ref($_) ? $_ : dur($_), @_[0,1];
	my $result    = join q[], map "DateTime::Duration"->compare(@durations, $_), MAGIC_DATES;
	return MAGIC_TABLE->{$result} if exists MAGIC_TABLE->{$result};
	return undef;
}

our @patterns;   my $pattern_i = -1;
our @assertions; my $assertion_i = -1;
my %facets = (
	explicitTimezone => sub {
		my ($o, $var) = @_;
		return unless exists $o->{explicitTimezone};
		my $etz = delete $o->{explicitTimezone};
		return sprintf('%s =~ m/(?:Z|(?:[+-]\d{2}:?\d{2}))$/xism', $var)
			if lc($etz) eq 'required';
		return sprintf('%s !~ m/(?:Z|(?:[+-]\d{2}:?\d{2}))$/xism', $var)
			if lc($etz) eq 'prohibited';
		return '!!1'
			if lc($etz) eq 'optional';
		croak "explicitTimezone facet expected to be 'required', 'prohibited' or 'optional'"
	},
	maxInclusiveDuration => sub {
		my ($o, $var) = @_;
		return unless exists $o->{maxInclusive};
		sprintf('(Types::XSD::dur_cmp(%s, %s)||0) <= 0', $var, perlstring delete $o->{maxInclusive});
	},
	minInclusiveDuration => sub {
		my ($o, $var) = @_;
		return unless exists $o->{minInclusive};
		sprintf('(Types::XSD::dur_cmp(%s, %s)||0) >= 0', $var, perlstring delete $o->{minInclusive});
	},
	maxExclusiveDuration => sub {
		my ($o, $var) = @_;
		return unless exists $o->{maxExclusive};
		sprintf('(Types::XSD::dur_cmp(%s, %s)||0) < 0', $var, perlstring delete $o->{maxExclusive});
	},
	minExclusiveDuration => sub {
		my ($o, $var) = @_;
		return unless exists $o->{minExclusive};
		sprintf('(Types::XSD::dur_cmp(%s, %s)||0) > 0', $var, perlstring delete $o->{minExclusive});
	},
	maxInclusiveDT => sub {
		my ($o, $var) = @_;
		return unless exists $o->{maxInclusive};
		sprintf('(Types::XSD::dt_cmp(%s, %s, %s)||0) <= 0', perlstring($Types::XSD::Lite::T), $var, perlstring delete $o->{maxInclusive});
	},
	minInclusiveDT => sub {
		my ($o, $var) = @_;
		return unless exists $o->{minInclusive};
		sprintf('(Types::XSD::dt_cmp(%s, %s, %s)||0) >= 0', perlstring($Types::XSD::Lite::T), $var, perlstring delete $o->{minInclusive});
	},
	maxExclusiveDT => sub {
		my ($o, $var) = @_;
		return unless exists $o->{maxExclusive};
		sprintf('(Types::XSD::dt_cmp(%s, %s, %s)||0) < 0', perlstring($Types::XSD::Lite::T), $var, perlstring delete $o->{maxExclusive});
	},
	minExclusiveDT => sub {
		my ($o, $var) = @_;
		return unless exists $o->{minExclusive};
		sprintf('(Types::XSD::dt_cmp(%s, %s, %s)||0) > 0', perlstring($Types::XSD::Lite::T), $var, perlstring delete $o->{minExclusive});
	},
);

$Types::XSD::Lite::facets{$_} = $facets{$_} for keys %facets;

our @dtarr;
my $i = -1;
our $base_datetime = "DateTime"->new(year => 2000, month => 1, day => 1); # leap year, 31 day month
our %dt_regexps;
sub dt_maker
{
	my ($name, $regexp, @fields) = @_;
	my $j = ++$i; $dtarr[$j] = $regexp;
	
	my $inlined = sub
	{
		my $var = $_[1];
		my @code;
		push @code, "do { my \$ok = 1;";
		push @code, sprintf(
			'my (%s) = (%s =~ $Types::XSD::dtarr[%d]) or --$ok;',
			join(', ', map "\$$_", @fields),
			$var,
			$j,
		);
		push @code, sprintf(
			'$ok and eval { "DateTime::Incomplete"->new(%s)->to_datetime(base => $Types::XSD::base_datetime) };',
			join(', ', map "$_ => \$$_", @fields),
		);
		push @code, "}";
		"@code";
	};
	
	my $type = "Type::Tiny"->new(
		name       => $name,
		library    => __PACKAGE__,
		constraint => eval sprintf('sub { %s }', $inlined->(undef, '$_')),
		inlined    => $inlined,
	);
	__PACKAGE__->add_type($type);
	
	facet(
		qw( pattern whiteSpace enumeration maxInclusiveDT maxExclusiveDT minInclusiveDT minExclusiveDT explicitTimezone ),
		$type,
	);
	
	$dt_regexps{$type} = [$regexp, @fields];
}

sub dt_parse
{
	my ($type, $a) = @_;
	my ($re, @fields) = @{ $dt_regexps{$type} };
	my %d;
	@d{@fields} = ($a =~ $re);
	!defined($d{$_}) && delete($d{$_}) for @fields;
	"DateTime::Incomplete"->new(%d);
}

sub dur_parse
{
	goto \&DateTimeX::Auto::dur;
}

{
	my %cache;
	sub _detect_type
	{
		my ($lib, $v) = @_;
		for my $type (qw(DateTime Time Date GYearMonth GYear GMonthDay GDay GMonth)) {
			return $type if $lib->get_type($type)->check($v);
		}
		return $lib->get_type('DateTime');
	}
	sub dt_cmp
	{
		my ($type, $a, $b) = @_;
		$type = __PACKAGE__->_detect_type($a) unless $type;
		$type = __PACKAGE__->get_type($type) unless ref $type;
		my $A = eval($cache{"$type;a"} ||= $type->inline_check('$a'));
		my $B = eval($cache{"$type;b"} ||= $type->inline_check('$b'));
		$A <=> $B;
	}
}

facet qw( length minLength maxLength pattern enumeration whiteSpace ),
declare Name, as Types::Standard::StrMatch[qr{^(?:$XML::RegExp::Name)$}sm];

facet qw( length minLength maxLength pattern enumeration whiteSpace ),
declare NmToken, as Types::Standard::StrMatch[qr{^(?:$XML::RegExp::NmToken)$}sm];

facet qw( length minLength maxLength pattern enumeration whiteSpace ),
declare NmTokens, as Types::Standard::StrMatch[qr{^(?:$XML::RegExp::NmToken)(?:\s+$XML::RegExp::NmToken)*$}sm];

facet qw( length minLength maxLength pattern enumeration whiteSpace ),
declare NCName, as Types::Standard::StrMatch[qr{^(?:$XML::RegExp::NCName)$}sm];

facet qw( length minLength maxLength pattern enumeration whiteSpace ),
declare Id, as NCName;

facet qw( length minLength maxLength pattern enumeration whiteSpace ),
declare IdRef, as NCName;

facet qw( length minLength maxLength pattern enumeration whiteSpace ),
declare IdRefs, as Types::Standard::StrMatch[qr{^(?:$XML::RegExp::NCName)(?:\s+$XML::RegExp::NCName)*$}sm];

facet qw( length minLength maxLength pattern enumeration whiteSpace ),
declare Entity, as NCName;

facet qw( length minLength maxLength pattern enumeration whiteSpace ),
declare Entities, as Types::Standard::StrMatch[qr{^(?:$XML::RegExp::NCName)(?:\s+$XML::RegExp::NCName)*$}sm];

facet qw( lengthQName minLengthQName maxLengthQName pattern enumeration whiteSpace ),
declare QName, as Types::Standard::StrMatch[qr{^(?:$XML::RegExp::QName)$}sm];

facet qw( lengthQName minLengthQName maxLengthQName pattern enumeration whiteSpace ),
declare Notation, as QName;

facet qw( pattern whiteSpace enumeration maxInclusiveDuration maxExclusiveDuration minInclusiveDuration minExclusiveDuration ),
declare Duration, as Types::Standard::StrMatch[
	qr{^-?P
		(?:[0-9]+Y)?
		(?:[0-9]+M)?
		(?:[0-9]+D)?
		(?:T
			(?:[0-9]+H)?
			(?:[0-9]+M)?
			(?:[0-9]+(?:\.[0-9]+)?S)?
		)?
	$}xism
];

facet qw( pattern whiteSpace enumeration maxInclusiveDuration maxExclusiveDuration minInclusiveDuration minExclusiveDuration ),
declare YearMonthDuration, as Duration->parameterize(pattern => qr{^[^DT]*$}i);

facet qw( pattern whiteSpace enumeration maxInclusiveDuration maxExclusiveDuration minInclusiveDuration minExclusiveDuration ),
declare DayTimeDuration, as Duration->parameterize(pattern => qr{^[^YM]*[DT].*$}i);

dt_maker(
	DateTime => qr{^
		(-?[0-9]{4,})
		-
		([0-9]{2})
		-
		([0-9]{2})
		T
		([0-9]{2})
		:
		([0-9]{2})
		:
		([0-9]{2}(?:\.[0-9]+)?)
		(Z | (?: [+-]\d{2}:?\d{2} ))?
	$}xism,
	qw( year month day hour minute second time_zone ),
);

dt_maker(
	DateTimeStamp => qr{^
		(-?[0-9]{4,})
		-
		([0-9]{2})
		-
		([0-9]{2})
		T
		([0-9]{2})
		:
		([0-9]{2})
		:
		([0-9]{2}(?:\.[0-9]+)?)
		(Z | (?: [+-]\d{2}:?\d{2} ))
	$}xism,
	qw( year month day hour minute second time_zone ),
);

dt_maker(
	Time => qr{^
		([0-9]{2})
		:
		([0-9]{2})
		:
		([0-9]{2}(?:\.[0-9]+)?)
		(Z | (?: [+-]\d{2}:?\d{2} ))?
	$}xism,
	qw( hour minute second time_zone ),
);

dt_maker(
	Date => qr{^
		(-?[0-9]{4,})
		-
		([0-9]{2})
		-
		([0-9]{2})
		(Z | (?: [+-]\d{2}:?\d{2} ))?
	$}xism,
	qw( year month day time_zone ),
);

dt_maker(
	GYearMonth => qr{^
		(-?[0-9]{4,})
		-
		([0-9]{2})
		(Z | (?: [+-]\d{2}:?\d{2} ))?
	$}xism,
	qw( year month time_zone ),
);

dt_maker(
	GYear => qr{^
		(-?[0-9]{4,})
		(Z | (?: [+-]\d{2}:?\d{2} ))?
	$}xism,
	qw( year time_zone ),
);

dt_maker(
	GMonthDay => qr{^
		-
		-
		([0-9]{2})
		-
		([0-9]{2})
		(Z | (?: [+-]\d{2}:?\d{2} ))?
	$}xism,
	qw( month day time_zone ),
);

dt_maker(
	GDay => qr{^
		-
		-
		-
		([0-9]{2})
		(Z | (?: [+-]\d{2}:?\d{2} ))?
	$}xism,
	qw( day time_zone ),
);

dt_maker(
	GMonth => qr{^
		-
		-
		([0-9]{2})
		(Z | (?: [+-]\d{2}:?\d{2} ))?
	$}xism,
	qw( month time_zone ),
);

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::XSD - type constraints based on XML schema datatypes

=head1 SYNOPSIS

   package Person;
   
   use Moo;
   use Types::XSD::Lite qw( PositiveInteger String );
   
   has name => (is => "ro", isa => String[ minLength => 1 ]);
   has age  => (is => "ro", isa => PositiveInteger);

=head1 DESCRIPTION

Types::XSD is a type constraint library inspired by XML Schema, and built
with L<Type::Library>. It can be used as a type constraint library for
L<Moo>, L<Mouse> or L<Moose>, or used completely independently of any OO
framework.

This module is an extension of L<Types::XSD::Lite> which has fewer type
constraints, but fewer dependencies. For completeness, the type constraints
and other features inherited from Types::XSD::Lite are documented below
too.

=head2 Type Constraints

This module defines the following type constraints based on the data types
defined in L<XML Schema|http://www.w3.org/TR/xmlschema-2/>. (The names of
the type constraints are the same as the XML Schema data types, but
capitalization often differs.)

I've added some quick explainations of what each type is, but for details,
see the XML Schema specification.

=over

=item C<< AnyType >>

As per C<Any> from L<Types::Standard>.

=item C<< AnySimpleType >>

As per C<Value> from L<Types::Standard>.

=item C<< String >>

As per C<Str> from L<Types::Standard>.

=item C<< NormalizedString >>

A string containing no line breaks, carriage returns or tabs.

=item C<< Token >>

Like C<NormalizedString>, but also no leading or trailing space, and no
doubled spaces (i.e. not C<< /\s{2,}/ >>).

=item C<< Language >>

An RFC 3066 language code.

=item C<< Name >>

Something that could be a valid XML element or attribute name. These roughly
correspond to Perl identifiers but may also contain colons, hyphens and stops.
(Digits, hyphens and stops are not allowed as the first character.)

=item C<< NmToken >>

Slightly looser version of C<Name>; allows digits, hyphens and stops in the
first character.

=item C<< NmTokens >>

Space-separated list of C<NmToken>.

=item C<< NCName >>

Slightly tighter vesion of C<Name>; disallows colons.

=item C<< Id >>

Effectively the same as C<NCName>.

=item C<< IdRef >>

Effectively the same as C<NCName>.

=item C<< IdRefs >>

Space-separated list of C<IdRef>.

=item C<< Entity >>

Effectively the same as C<NCName>.

=item C<< Entities >>

Space-separated list of C<Entity>.

=item C<< Boolean >>

Allows C<< "true" >>, C<< "false" >>, C<< "1" >> and C<< "0" >>
(case-insensitively).

Gotcha: The string C<< "false" >> evaluates to true in Perl. You probably
want to use C<< Bool >> from L<Types::Standard> instead.

=item C<< Base64Binary >>

Strings which are valid Base64 data. Allows whitespace.

Gotcha: If you parameterize this with C<length>, C<maxLength> or C<minLength>,
it is the length of the I<decoded> string which will be checked.

=item C<< HexBinary >>

Strings which are valid hexadecimal data. Disallows whitespace; disallows
leading C<< 0x >>.

Gotcha: If you parameterize this with C<length>, C<maxLength> or C<minLength>,
it is the length of the I<decoded> string which will be checked.

=item C<< Float >>

As per C<Num> from L<Types::Standard>.

=item C<< Double >>

As per C<Num> from L<Types::Standard>.

=item C<< AnyURI >>

Any absolute I<< or relative >> URI. Effectively, any string at all!

=item C<< QName >>

An XML QName; something that could be used as a valid element name in a
namespaced XML document.

Gotcha: while C<length>, C<maxLength> and C<minLength> are allowed facets for
parameterization, they are silently ignored, as per the specification!

=item C<< Notation >>

Effectively the same as C<QName>. According to XML Schema, this is I<always>
supposed to be parameterized with an enumeration. But we don't enforce that.

Gotcha: while C<length>, C<maxLength> and C<minLength> are allowed facets for
parameterization, they are silently ignored, as per the specification!

=item C<< Decimal >>

Numbers possibly including a decimal point, but not allowing exponential
notation (e.g. C<< "3.14e-3" >>).

=item C<< Integer >>

As per C<Int> from L<Types::Standard>.

=item C<< NonPositiveInteger >>

An C<Integer> 0 or below.

=item C<< NegativeInteger >>

An C<Integer> -1 or below.

=item C<< Long >>

An C<Integer> between -9223372036854775808 and 9223372036854775807 (inclusive).

=item C<< Int >>

An C<Integer> between -2147483648 and 2147483647 (inclusive).

=item C<< Short >>

An C<Integer> between -32768 and 32767 (inclusive).

=item C<< Byte >>

An C<Integer> between -128 and 127 (inclusive).

=item C<< NonNegativeInteger >>

An C<Integer> 0 or above.

=item C<< PositiveInteger >>

An C<Integer> 1 or above.

=item C<< UnsignedLong >>

A C<NonNegativeInteger> between 0 and 18446744073709551615 (inclusive).

=item C<< UnsignedInt >>

A C<NonNegativeInteger> between 0 and 4294967295 (inclusive).

=item C<< UnsignedShort >>

A C<NonNegativeInteger> between 0 and 65535 (inclusive).

=item C<< UnsignedByte >>

A C<NonNegativeInteger> between 0 and 255 (inclusive).

=item C<< Duration >>

An ISO 8601 duration.

=item C<< YearMonthDuration >>

An ISO 8601 duration restricted to cover only years and months.

=item C<< DayTimeDuration >>

An ISO 8601 duration restricted to cover only days, hours, minutes and
seconds. (Note that this still permits durations of many years, as the
days component is an arbitrary non-negative integer.)

=item C<< DateTime >>

An ISO 8601 datetime with optional timezone.

=item C<< DateTimeStamp >>

An ISO 8601 datetime with required timezone.

=item C<< Time >>

An ISO 8601 time with optional timezone.

=item C<< Date >>

An ISO 8601 date with optional timezone.

=item C<< GYearMonth >>

An year-month pair with optional timezone.

=item C<< GYear >>

An year with optional timezone.

=item C<< GMonthDay >>

An month-day pair with optional timezone.

=item C<< GDay >>

An day with optional timezone.

=item C<< GMonth >>

An month with optional timezone.

=back

=head2 Parameters

Datatypes can be parameterized using the facets defined by XML Schema. For
example:

   use Types::XSD::Lite qw( String Decimal PositiveInteger Token );
   
   my @sizes = qw( XS S M L XL XXL );
   
   has name   => (is => "ro", isa => String[ minLength => 1 ]);
   has price  => (is => "ro", isa => Decimal[ fractionDigits => 2 ]);
   has rating => (is => "ro", isa => PositiveInteger[ maxInclusive => 5 ]);
   has size   => (is => "ro", isa => Token[ enumeration => \@sizes ]);

The following facets exist, but not all facets are supported for all
datatypes. (The module will croak if you try to use an unsupported facet.)

=over

=item C<< enumeration >>

An arrayref of allowable values. You should probably use L<Type::Tiny::Enum>
instead.

=item C<< pattern >>

A regular expression that the value is expected to conform to. Use a normal
Perl quoted regexp:

   Token[ pattern => qr{^[a-z]+$} ]

=item C<< whiteSpace >>

The C<whiteSpace> facet is ignored as I'm not entirely sure what it should
do. It perhaps makes sense for coercions, but this module doesn't define any
coercions.

=item C<< assertions >>

An arrayref of arbitrary additional restrictions, expressed as strings of
Perl code or coderefs operating on C<< $_ >>.

For example:

   Integer[
      assertions => [
         '$_ % 3 == 0',            # multiple of three, and...
         sub { is_nice($_) },      # is nice (whatever that means)
      ],
   ],

Strings of Perl code will result in faster-running type constraints.

=item C<< length >>, C<< maxLength >>, C<< minLength >>

Restrict the length of a value. For example C<< Integer[length=>2] >> allows
C<10>, C<99> and C<-1>, but not C<100>, C<9> or C<-10>.

Types::XSD won't prevent you from making ridiculous constraints such as
C<< String[ maxLength => 1, minLength => 2 ] >>.

Note that on C<HexBinary> and C<Base64Binary> types, the lengths apply to
the decoded string. Length restrictions are silently ignored for C<QName>
and C<Notation> because the W3C doesn't think you should care what length
these datatypes are.

=item C<< maxInclusive >>, C<< minInclusive >>, C<< maxExclusive >>, C<< minExclusive >>

Supported for numeric types and datetime/duration-related types.

Note that to be super-correct, the C<< {max,min}{Inclusive,Exclusive} >>
facets for numeric types are performed by passing the numbers through
L<Math::BigInt> or L<Math::BigFloat>, so may be a little slow.

=item C<< totalDigits >>

For a decimal (or type derived from decimals) specifies that the total number
of digits for the value must be at most this number. Given
C<< Decimal[ totalDigits => 3 ] >>, C<1.23>, C<12.3>, C<123>, C<1.2> and C<1>
are all allowable; C<1.234> is not. C<1.230> is also not, but this may change
in a future version.

=item C<< fractionDigits >>

Like C<totalDigits> but ignores digits before the decimal point.

=item C<< explicitTimezone >>

May be C<< "optional" >>, C<< "prohibited" >> or C<< "required" >>. For
example:

   Time[ explicitTimezone => "prohibited" ]

=back

=head2 Functions

This module also exports some convenience functions:

=over

=item C<< dur_parse($str) >>

Parse an xsd:duration string, returning a L<DateTime::Duration>.

=item C<< dur_cmp($a, $b) >>

Compare two strings conforming to the xsd:duration datatype to indicate
which is the longer duration.

Returns -1 if $a is shorter. Returns 1 if $b is shorter. Returns 0 if the
durations are identical. Returns undef if the comparison is indeterminate;
for example, "P1Y" (one year) and "P365D" (365 days) are not necessarily
identical - in leap years "P365D" is shorter.

=item C<< dt_cmp($type, $a, $b) >>

Compare two datetime-like strings. For example, two C<gYearMonth> strings
can be compared using:

   dt_cmp(GYearMonth, "2009-02", "2010-10");

Both strings are expected to conform to the same datatype. It doesn't make
much sense to compare them otherwise.

=item C<< dt_parse($type, $str) >>

Parse a datetime-like string, returning a L<DateTime::Incomplete> object.
Note that L<DateTime::Incomplete> objects are always returned, even if the
datetime is potentially complete.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Types-XSD>.

=head1 SEE ALSO

L<Type::Tiny>, L<Types::XSD::Lite>, L<Types::Standard>.

=over

=item *

L<http://www.w3.org/TR/xmlschema-2/> Datatypes in XML Schema 1.0

=item *

L<http://www.w3.org/TR/xmlschema11-2/> Datatypes in XML Schema 1.1

=back

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

