package Types::XSD::Lite;

use 5.008003;
use strict;
use warnings;
use utf8;

BEGIN {
	$Types::XSD::Lite::AUTHORITY = 'cpan:TOBYINK';
	$Types::XSD::Lite::VERSION   = '0.006';
}

use B qw(perlstring);
use Carp;
use Type::Utils;
use Type::Library -base, -declare => qw(
	AnyType AnySimpleType String NormalizedString Token Language Boolean
	Base64Binary HexBinary Float Double AnyURI Decimal
	Integer NonPositiveInteger NegativeInteger Long Int Short Byte
	NonNegativeInteger PositiveInteger UnsignedLong UnsignedInt
	UnsignedShort UnsignedByte
);
use Types::Standard;

our $T;

sub create_range_check
{
	my $class = $_[0]; eval "require $class";
	my ($lower, $upper) = map(defined($_) ? $class->new($_) : $_, @_[1,2]);
	my ($lexcl, $uexcl) = map(!!$_, @_[3,4]);
	
	my $checker =
		(defined $lower and defined $upper and $lexcl and $uexcl)
			? sub { my $n = $class->new($_); $n > $lower and $n < $upper } :
		(defined $lower and defined $upper and $lexcl)
			? sub { my $n = $class->new($_); $n > $lower and $n <= $upper } :
		(defined $lower and defined $upper and $uexcl)
			? sub { my $n = $class->new($_); $n >= $lower and $n < $upper } :
		(defined $lower and defined $upper)
			? sub { my $n = $class->new($_); $n >= $lower and $n <= $upper } :
		(defined $lower and $lexcl)
			? sub { $class->new($_) > $lower } :
		(defined $upper and $uexcl)
			? sub { $class->new($_) < $upper } :
		(defined $lower)
			? sub { $class->new($_) >= $lower } :
		(defined $upper)
			? sub { $class->new($_) <= $upper } :
		sub { !!1 };
	
	my $inlined = sub {
		my $var = $_[1];
		my @checks;
		push @checks, sprintf('$n >%s "%s"->new("%s")', $lexcl?'':'=', $class, $lower) if defined $lower;
		push @checks, sprintf('$n <%s "%s"->new("%s")', $uexcl?'':'=', $class, $upper) if defined $upper;
		my $code = sprintf(
			'%s and do { my $n = "%s"->new(%s); %s }',
			Types::Standard::Int()->inline_check($var),
			$class,
			$var,
			join(" and ", @checks),
		);
	};
	
	return (
		constraint  => $checker,
		inlined     => $inlined,
	);
}

sub quick_range_check
{
	my $class = $_[0]; eval "require $class";
	my ($lower, $upper) = map(defined($_) ? $class->new($_) : $_, @_[1,2]);
	my ($lexcl, $uexcl) = map(!!$_, @_[3,4]);
	my $var = $_[5];
	my @checks;
	push @checks, sprintf('$n >%s "%s"->new("%s")', $lexcl?'':'=', $class, $lower) if defined $lower;
	push @checks, sprintf('$n <%s "%s"->new("%s")', $uexcl?'':'=', $class, $upper) if defined $upper;
	my $code = sprintf(
		'do { my $n = "%s"->new(%s); %s }',
		$class,
		$var,
		join(" and ", @checks),
	);
}

sub hex_length
{
	my $str = shift;
	my $len = ($str =~ tr/0-9A-Fa-f//);
	$len / 2;
}

sub b64_length
{
	my $str = shift;
	$str =~ s/[^a-zA-Z0-9+\x{2f}=]//g;
	my $padding = ($str =~ tr/=//);
	(length($str) * 3 / 4) - $padding;
}

our @patterns;   my $pattern_i = -1;
our @assertions; my $assertion_i = -1;
our %facets = (
	assertions => sub {
		my ($o, $var) = @_;
		return unless exists $o->{assertions};
		my $ass = delete $o->{assertions};
		$ass = [$ass] unless ref($ass) eq q(ARRAY);
		my @r;
		for my $a (@$ass)
		{
			require Types::TypeTiny;
			if (Types::TypeTiny::CodeLike()->check($a))
			{
				$assertion_i++;
				$assertions[$assertion_i] = $a;
				push @r,
					($var eq '$_')
						? sprintf('$Types::XSD::Lite::assertions[%d]->(%s)', $assertion_i, $var)
						: sprintf('do { local $_ = %s; $Types::XSD::Lite::assertions[%d]->(%s) }', $var, $assertion_i, $var);
			}
			elsif (Types::TypeTiny::StringLike()->check($a))
			{
				push @r,
					($var eq '$_')
						? "do { $a }"
						: "do { local \$_ = $var; $a }";
			}
			else
			{
				croak "assertions should be strings or coderefs";
			}
		}
		join ' && ', map "($_)", @r;
	},
	length => sub {
		my ($o, $var) = @_;
		return unless exists $o->{length};
		sprintf('length(%s)==%d', $var, delete $o->{length});
	},
	maxLength => sub {
		my ($o, $var) = @_;
		return unless exists $o->{maxLength};
		sprintf('length(%s)<=%d', $var, delete $o->{maxLength});
	},
	minLength => sub {
		my ($o, $var) = @_;
		return unless exists $o->{minLength};
		sprintf('length(%s)>=%d', $var, delete $o->{minLength});
	},
	lengthHex => sub {
		my ($o, $var) = @_;
		return unless exists $o->{length};
		sprintf('Types::XSD::Lite::hex_length(%s)==%d', $var, delete $o->{length});
	},
	maxLengthHex => sub {
		my ($o, $var) = @_;
		return unless exists $o->{maxLength};
		sprintf('Types::XSD::Lite::hex_length(%s)<=%d', $var, delete $o->{maxLength});
	},
	minLengthHex => sub {
		my ($o, $var) = @_;
		return unless exists $o->{minLength};
		sprintf('Types::XSD::Lite::hex_length(%s)>=%d', $var, delete $o->{minLength});
	},
	lengthQName => sub {
		my ($o, $var) = @_;
		return unless exists $o->{length};
		delete $o->{length};
		"!!1"
	},
	maxLengthQName => sub {
		my ($o, $var) = @_;
		return unless exists $o->{maxLength};
		delete $o->{maxLength};
		"!!1"
	},
	minLengthQName => sub {
		my ($o, $var) = @_;
		return unless exists $o->{minLength};
		delete $o->{minLength};
		"!!1"
	},
	lengthB64 => sub {
		my ($o, $var) = @_;
		return unless exists $o->{length};
		sprintf('Types::XSD::Lite::b64_length(%s)==%d', $var, delete $o->{length});
	},
	maxLengthB64 => sub {
		my ($o, $var) = @_;
		return unless exists $o->{maxLength};
		sprintf('Types::XSD::Lite::b64_length(%s)<=%d', $var, delete $o->{maxLength});
	},
	minLengthB64 => sub {
		my ($o, $var) = @_;
		return unless exists $o->{minLength};
		sprintf('Types::XSD::Lite::b64_length(%s)>=%d', $var, delete $o->{minLength});
	},
	pattern => sub {
		my ($o, $var) = @_;
		return unless exists $o->{pattern};
		$patterns[++$pattern_i] = delete $o->{pattern};
		sprintf('%s =~ $Types::XSD::Lite::patterns[%d]', $var, $pattern_i);
	},
	enumeration => sub {
		my ($o, $var) = @_;
		return unless exists $o->{enumeration};
		my $re = join "|", map quotemeta, @{delete $o->{enumeration}};
		sprintf('%s =~ m/^(?:%s)$/sm', $var, $re);
	},
	whiteSpace => sub {
		my ($o, $var) = @_;
		return unless exists $o->{whiteSpace};
		delete($o->{whiteSpace});
		"!!1";
	},
	maxInclusive => sub {
		my ($o, $var) = @_;
		return unless exists $o->{maxInclusive};
		quick_range_check("Math::BigInt", undef, delete($o->{maxInclusive}), undef, undef, $var);
	},
	minInclusive => sub {
		my ($o, $var) = @_;
		return unless exists $o->{minInclusive};
		quick_range_check("Math::BigInt", delete($o->{minInclusive}), undef, undef, undef, $var);
	},
	maxExclusive => sub {
		my ($o, $var) = @_;
		return unless exists $o->{maxExclusive};
		quick_range_check("Math::BigInt", undef, delete($o->{maxExclusive}), undef, 1, $var);
	},
	minExclusive => sub {
		my ($o, $var) = @_;
		return unless exists $o->{minExclusive};
		quick_range_check("Math::BigInt", delete($o->{minExclusive}), undef, 1, undef, $var);
	},
	maxInclusiveFloat => sub {
		my ($o, $var) = @_;
		return unless exists $o->{maxInclusive};
		quick_range_check("Math::BigFloat", undef, delete($o->{maxInclusive}), undef, undef, $var);
	},
	minInclusiveFloat => sub {
		my ($o, $var) = @_;
		return unless exists $o->{minInclusive};
		quick_range_check("Math::BigFloat", delete($o->{minInclusive}), undef, undef, undef, $var);
	},
	maxExclusiveFloat => sub {
		my ($o, $var) = @_;
		return unless exists $o->{maxExclusive};
		quick_range_check("Math::BigFloat", undef, delete($o->{maxExclusive}), undef, 1, $var);
	},
	minExclusiveFloat => sub {
		my ($o, $var) = @_;
		return unless exists $o->{minExclusive};
		quick_range_check("Math::BigFloat", delete($o->{minExclusive}), undef, 1, undef, $var);
	},
	maxInclusiveStr => sub {
		my ($o, $var) = @_;
		return unless exists $o->{maxInclusive};
		sprintf('%s le %s', $var, perlstring delete $o->{maxInclusive});
	},
	minInclusiveStr => sub {
		my ($o, $var) = @_;
		return unless exists $o->{minInclusive};
		sprintf('%s ge %s', $var, perlstring delete $o->{minInclusive});
	},
	maxExclusiveStr => sub {
		my ($o, $var) = @_;
		return unless exists $o->{maxExclusive};
		sprintf('%s lt %s', $var, perlstring delete $o->{maxExclusive});
	},
	minExclusiveStr => sub {
		my ($o, $var) = @_;
		return unless exists $o->{minExclusive};
		sprintf('%s gt %s', $var, perlstring delete $o->{minExclusive});
	},
	totalDigits => sub {
		my ($o, $var) = @_;
		return unless exists $o->{totalDigits};
		sprintf('do { no warnings "uninitialized"; my $tmp = %s; ($tmp=~tr/0-9//) <= %d }', $var, delete $o->{totalDigits});
	},
	fractionDigits => sub {
		my ($o, $var) = @_;
		return unless exists $o->{fractionDigits};
		sprintf('do { no warnings "uninitialized"; my (undef, $tmp) = split /\\./, %s; ($tmp=~tr/0-9//) <= %d }', $var, delete $o->{fractionDigits});
	},
);

sub facet
{
	my $self   = pop;
	my @facets = ("assertions", @_);
	my $regexp = qr{^${\(join "|", map quotemeta, @facets)}$}ms;
	my $name   = "$self";
	
	my $inline_generator = sub
	{
		my %p_not_destroyed = @_;
		return sub {
			local $T = $_[0]->parent;
			my %p    = %p_not_destroyed;  # copy;
			my $var  = $_[1];
			my $r    = sprintf(
				'(%s)',
				join(
					' and ',
					$self->inline_check($var),
					map($facets{$_}->(\%p, $var), @facets),
				),
			);
			croak sprintf(
				'Attempt to parameterize type "%s" with unrecognised parameter%s %s',
				$name,
				scalar(keys %p)==1 ? '' : 's',
				join(", ", map(qq["$_"], sort keys %p)),
			) if keys %p;
			return $r;
		};
	};
	
	$self->{inline_generator} = $inline_generator;
	$self->{constraint_generator} = sub {
		my $sub = sprintf(
			'sub { %s }',
			$inline_generator->(@_)->($self, '$_[0]'),
		);
		eval($sub) or croak "could not build sub: $@\n\nCODE: $sub\n";
	};
	$self->{name_generator} = sub {
		my ($s, %a) = @_;
		sprintf('%s[%s]', $s, join q[,], map sprintf("%s=>%s", $_, perlstring $a{$_}), sort keys %a);
	};
	
	return if $self->is_anon;
	
	no strict qw( refs );
	no warnings qw( redefine prototype );
	*{$self->library . '::' . $self->name} = $self->library->_mksub($self);
}

declare AnyType, as Types::Standard::Any;

declare AnySimpleType, as Types::Standard::Value;

facet qw( length minLength maxLength pattern enumeration whiteSpace ),
declare String, as Types::Standard::Str;

facet qw( length minLength maxLength pattern enumeration whiteSpace ),
declare NormalizedString, as Types::Standard::StrMatch[qr{^[^\t\r\n]*$}sm];

facet qw( length minLength maxLength pattern enumeration whiteSpace ),
declare Token, as intersection([
	NormalizedString,
	Types::Standard::StrMatch([qr{\A\s}sm])->complementary_type,
	Types::Standard::StrMatch([qr{\s\z}sm])->complementary_type,
	Types::Standard::StrMatch([qr{\s{2}}sm])->complementary_type,
]);

facet qw( length minLength maxLength pattern enumeration whiteSpace ),
declare Language, as Types::Standard::StrMatch[qr{\A[a-zA-Z]{1,8}(?:-[a-zA-Z0-9]{1,8})*\z}sm];

facet qw( pattern whiteSpace ),
declare Boolean, as Types::Standard::StrMatch[qr{\A(?:true|false|0|1)\z}ism];

facet qw( lengthB64 minLengthB64 maxLengthB64 pattern enumeration whiteSpace ),
declare Base64Binary, as Types::Standard::StrMatch[qr{\A[a-zA-Z0-9+\x{2f}=\s]+\z}ism];

facet qw( lengthHex minLengthHex maxLengthHex pattern enumeration whiteSpace ),
declare HexBinary, as Types::Standard::StrMatch[qr{\A[a-fA-F0-9]+\z}ism];

facet qw( pattern enumeration whiteSpace maxInclusiveFloat maxExclusiveFloat minInclusiveFloat minExclusiveFloat ),
declare Float, as Types::Standard::Num;

facet qw( pattern enumeration whiteSpace maxInclusiveFloat maxExclusiveFloat minInclusiveFloat minExclusiveFloat ),
declare Double, as Types::Standard::Num;

facet qw( length minLength maxLength pattern enumeration whiteSpace ),
declare AnyURI, as Types::Standard::Str;

facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusiveFloat maxExclusiveFloat minInclusiveFloat minExclusiveFloat ),
declare Decimal, as Types::Standard::StrMatch[qr{\A(?:(?:[+-]?[0-9]+(?:\.[0-9]+)?)|(?:[+-]?\.[0-9]+))\z}ism];

facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
declare Integer, as Types::Standard::Int;

facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
declare NonPositiveInteger, as Integer, create_range_check("Math::BigInt", undef, 0);

facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
declare NegativeInteger, as NonPositiveInteger, create_range_check("Math::BigInt", undef, -1);

facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
declare NonNegativeInteger, as Integer, create_range_check("Math::BigInt", 0, undef);

facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
declare PositiveInteger, as NonNegativeInteger, create_range_check("Math::BigInt", 1, undef);

facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
declare Long, as Integer, create_range_check("Math::BigInt", q[-9223372036854775808], q[9223372036854775807]);

facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
declare Int, as Long, create_range_check("Math::BigInt", q[-2147483648], q[2147483647]);

facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
declare Short, as Int, create_range_check("Math::BigInt", q[-32768], q[32767]);

facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
declare Byte, as Short, create_range_check("Math::BigInt", q[-128], q[127]);

facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
declare UnsignedLong, as NonNegativeInteger, create_range_check("Math::BigInt", q[0], q[18446744073709551615]);

facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
declare UnsignedInt, as UnsignedLong, create_range_check("Math::BigInt", q[0], q[4294967295]);

facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
declare UnsignedShort, as UnsignedInt, create_range_check("Math::BigInt", q[0], q[65535]);

facet qw( totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive ),
declare UnsignedByte, as UnsignedShort, create_range_check("Math::BigInt", q[0], q[255]);

1;

__END__

=pod

=encoding utf-8

=begin stopwords

datatypes
datetime-related
QNames
IDRefs
whitespace
datetime/duration-related


=end stopwords

=head1 NAME

Types::XSD::Lite - type constraints based on a subset of XML schema datatypes

=head1 SYNOPSIS

   package Person;
   
   use Moo;
   use Types::XSD::Lite qw( PositiveInteger String );
   
   has name => (is => "ro", isa => String[ minLength => 1 ]);
   has age  => (is => "ro", isa => PositiveInteger);

=head1 DESCRIPTION

These are all the type constraints from XML Schema that could be
implemented without introducing extra runtime dependencies (above
L<Type::Tiny>). That's basically all of the XSD types, except
datetime-related ones, and XML-specific ones (QNames, IDRefs, etc).

If you want the full set of XML Schema types, see L<Types::XSD>.

=head2 Type Constraints

I've added some quick explanations of what each type is, but for
details, see the XML Schema specification.

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

Types::XSD::Lite won't prevent you from making ridiculous constraints such
as C<< String[ maxLength => 1, minLength => 2 ] >>.

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

=back

=head1 CAVEATS

This distribution has virtually no test suite, in the hope that Types::XSD's
test suite will shake out any bugs in this module.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Types-XSD-Lite>.

=head1 SEE ALSO

L<Type::Tiny>, L<Types::Standard>, L<Types::XSD>.

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

