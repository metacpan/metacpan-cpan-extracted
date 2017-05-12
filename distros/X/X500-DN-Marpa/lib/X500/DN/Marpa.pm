package X500::DN::Marpa;

use strict;
use warnings;

use Const::Exporter constants =>
[
	nothing_is_fatal    =>  0, # The default.
	print_errors        =>  1,
	print_warnings      =>  2,
	print_debugs        =>  4,
	ambiguity_is_fatal  =>  8,
	exhaustion_is_fatal => 16,
	long_descriptors    => 32,
	return_hex_as_chars => 64,
];

use Marpa::R2;

use Moo;

use Set::Array;

use Types::Standard qw/Any Int Str/;

use Try::Tiny;

use X500::DN::Marpa::Actions;

has bnf =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has error_message =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has error_number =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has grammar =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has options =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has recce =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

# The default value of $self -> stack is set to Set::Array -> new, so that if anyone
# accesses $self -> stack before calling $self -> parse, gets a meaningful result.
# This is despite the fact the parser() resets the stack at the start of each call.

has stack =>
(
	default  => sub{return Set::Array -> new},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has text =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

my(%descriptors) =
(
	cn     => 'commonName',
	c      => 'countryName',
	dc     => 'domainComponent',
	l      => 'localityName',
	ou     => 'organizationalUnitName',
	o      => 'organizationName',
	st     => 'stateOrProvinceName',
	street => 'streetAddress',
	uid    => 'userId',
);

our $VERSION = '1.00';

# ------------------------------------------------

sub BUILD
{
	my($self) = @_;

	# Policy: Event names are always the same as the name of the corresponding lexeme.
	#
	# References:
	# o https://www.ietf.org/rfc/rfc4512.txt (secondary)
	#	- Lightweight Directory Access Protocol (LDAP): Directory Information Models
	# o https://www.ietf.org/rfc/rfc4514.txt (primary)
	#   - Lightweight Directory Access Protocol (LDAP): String Representation of Distinguished Names
	# o https://www.ietf.org/rfc/rfc4517.txt
	#	- Lightweight Directory Access Protocol (LDAP): Syntaxes and Matching Rules
	# o https://www.ietf.org/rfc/rfc4234.txt
	#	- Augmented BNF for Syntax Specifications: ABNF
	# o https://www.ietf.org/rfc/rfc3629.txt
	#	- UTF-8, a transformation format of ISO 10646

	my($bnf) = <<'END_OF_GRAMMAR';

:default			::= action => [values]

lexeme default		= latm => 1

:start				::= dn

# dn.

dn					::=
dn					::= rdn
						| rdn separators dn

separators			::= separator+

separator			::= comma
						| space

rdn					::= attribute_pair								rank => 1
						| attribute_pair spacer plus spacer rdn		rank => 2

attribute_pair		::= attribute_type spacer equals spacer attribute_value

spacer				::= space*

# attribute_type.

attribute_type		::= description				action => attribute_type
						| numeric_oid			action => attribute_type

description			::= description_prefix description_suffix

description_prefix	::= alpha

description_suffix	::= description_tail*

description_tail	::= alpha
						| digit
						| hyphen

numeric_oid			::= number oid_suffix

number				::= digit
						| digit_sequence

digit_sequence		::= non_zero_digit digit_suffix

digit_suffix		::= digit+

oid_suffix			::= oid_sequence+

oid_sequence		::= dot number

# attribute_value.

attribute_value		::= string					action => attribute_value
						| hex_string			action => attribute_value

string				::=
string				::= string_prefix string_suffix

string_prefix		::= lutf1
						| utfmb
						| pair

utfmb				::= utf2
						| utf3
						| utf4

utf2				::= utf2_prefix utf2_suffix

utf3				::= utf3_prefix_1 utf3_suffix_1
						| utf3_prefix_2 utf3_suffix_2
						| utf3_prefix_3 utf3_suffix_3
						| utf3_prefix_4 utf3_suffix_4

utf4				::= utf4_prefix_1 utf4_suffix_1
						| utf4_prefix_2 utf4_suffix_2
						| utf4_prefix_3 utf4_suffix_3

pair				::= escape_char escaped_char

escaped_char		::= escape_char
						| special_char
						| hex_pair

string_suffix		::=
string_suffix		::= string_suffix_1 string_suffix_2

string_suffix_1		::= string_suffix_1_1*

string_suffix_1_1	::= sutf1
						| utfmb
						| pair

string_suffix_2		::= tutf1
						| utfmb
						| pair

hex_string			::= sharp hex_suffix

hex_suffix			::= hex_pair+

hex_pair			::= hex_digit hex_digit

# Lexemes in alphabetical order.

alpha				~ [A-Za-z]		# [\x41-\x5a\x61-\x7a].

comma				~ ','			# [\x2c].

digit				~ [0-9]			# [\x30-\x39].

dot					~ '.'			# [\x2e].

equals				~ '='			# [\x3d].

escape_char			~ '\'			# [\x5c]. Use ' in comment for UltraEdit syntax hiliter.

hex_digit			~ [0-9A-Fa-f]	# [\x30-\x39\x41-\x46\x61-\x66].

hyphen				~ '-'

# \x01-\x1f: All control chars except the first (^@). Skip [ ] = [\x20].
# \x21:      !. Skip ["#] = [\x22\x23].
# \x24-\x2a: $%&'()*. Skip: [+,] = [\x2b\x2c].
# \x2d-\x3a: -./0123456789:. Skip [;<] = [\x3b\x3c].
# \x3d:      =.
# \x3f-\x5b: ?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[.
# \x5d-\x7f: ]^_`abcdefghijklmnopqrstuvwxyz{|}~ and DEL.

lutf1				~ [\x01-\x1f\x21\x24-\x2a\x2d-\x3a\x3d\x3f-\x5b\x5d-\x7f]

non_zero_digit		~ [1-9]			# [\x31-\x39].

plus				~ '+'			# [\x2b].

sharp				~ '#'			# [\x23].

space				~ ' '			# [\x20].

special_char		~ ["+,;<> #=]	# Use " in comment for UltraEdit syntax hiliter.

sutf1				~ [\x01-\x21\x23-\x2a\x2d-\x3a\x3d\x3f-\x5b\x5d-\x7f]

tutf1				~ [\x01-\x1f\x21\x23-\x2a\x2d-\x3a\x3d\x3f-\x5b\x5d-\x7f]

utf0				~ [\x80-\xbf]

utf2_prefix			~ [\xc2-\xdf]

utf2_suffix			~ utf0

utf3_prefix_1		~ [\xe0\xa0-\xbf]

utf3_suffix_1		~ utf0

utf3_prefix_2		~ [\xe1-\xec]

utf3_suffix_2		~ utf0 utf0

utf3_prefix_3		~ [\xed\x80-\x9f]

utf3_suffix_3		~ utf0

utf3_prefix_4		~ [\xee-\xef]

utf3_suffix_4		~ utf0 utf0

utf4_prefix_1		~ [\xf0\x90-\xbf]

utf4_suffix_1		~ utf0 utf0

utf4_prefix_2		~ [\xf1-\xf3]

utf4_suffix_2		~ utf0 utf0 utf0

utf4_prefix_3		~ [\xf4\x80-\x8f]

utf4_suffix_3		~ utf0 utf0

END_OF_GRAMMAR

	$self -> bnf($bnf);
	$self -> grammar
	(
		Marpa::R2::Scanless::G -> new
		({
			source => \$self -> bnf
		})
	);

} # End of BUILD.

# ------------------------------------------------

sub decode_result
{
	my($self, $result) = @_;
	my(@worklist) = $result;

	my($obj);
	my($ref_type);
	my(@stack);

	do
	{
		$obj      = shift @worklist;
		$ref_type = ref $obj;

		if ($ref_type eq 'ARRAY')
		{
			unshift @worklist, @$obj;
		}
		elsif ($ref_type eq 'HASH')
		{
			push @stack, {%$obj};
		}
		elsif ($ref_type)
		{
			die "Unsupported object type $ref_type\n";
		}
		else
		{
			push @stack, $obj;
		}

	} while (@worklist);

	return [@stack];

} # End of decode_result.

# ------------------------------------------------

sub _combine
{
	my($self)        = @_;
	my(@temp)        = $self -> stack -> print;
	my($multivalued) = 0;

	my(@dn);

	for (my $i = 0; $i <= $#temp; $i++)
	{
		# The 'multivalued' key is use for temporary storage. See parse().
		# 'count' holds the count of RDNs within this stack element.

		if ($temp[$i]{multivalued})
		{
			$multivalued = 1;
		}
		elsif ($multivalued)
		{
			$multivalued     =  0;
			$dn[$#dn]{count} += 1;
			$dn[$#dn]{value} .= "+$temp[$i]{type}=$temp[$i]{value}";
		}
		else
		{
			# Zap 'multivalued' so it does not end up in the stack.

			undef $temp[$i]{multivalued};

			push @dn, $temp[$i];
		}
	}

	$self -> stack(Set::Array -> new(@dn) );

} # End of _combine.

# ------------------------------------------------

sub dn
{
	my($self) = @_;

	return join(',', map{"$$_{type}=$$_{value}"} reverse @{$self -> stack});

} # End of dn.

# ------------------------------------------------

sub openssl_dn
{
	my($self) = @_;

	return join('+', map{"$$_{type}=$$_{value}"} @{$self -> stack});

} # End of openssl_dn.

# ------------------------------------------------

sub parse
{
	my($self, $string) = @_;
	$self -> text($string) if (defined $string);

	$self -> recce
	(
		Marpa::R2::Scanless::R -> new
		({
			exhaustion        => 'event',
			grammar           => $self -> grammar,
			ranking_method    => 'high_rule_only',
			semantics_package => 'X500::DN::Marpa::Actions',
		})
	);

	# Return 0 for success and 1 for failure.

	my($result) = 0;

	my($message);

	try
	{
		my($text)        = $self -> text;
		my($text_length) = length($text);
		my($read_length) = $self -> recce -> read(\$text);

		if ($text_length != $read_length)
		{
			die "Text is $text_length characters, but read() only read $read_length characters. \n";
		}

		if ($self -> recce -> exhausted)
		{
			$message = 'Parse exhausted';

			$self -> error_message($message);
			$self -> error_number(1);

			if ($self -> options & exhaustion_is_fatal)
			{
				# This 'die' is inside try{}catch{}, which adds the prefix 'Error: '.

				die "$message\n";
			}
			else
			{
				$self -> error_number(-1);

				print "Warning: $message\n" if ($self -> options & print_warnings);
			}
		}
		elsif (my $status = $self -> recce -> ambiguous)
		{
			my($terminals) = $self -> recce -> terminals_expected;
			$terminals     = ['(None)'] if ($#$terminals < 0);
			$message       = "Ambiguous parse. Status: $status. Terminals expected: " . join(', ', @$terminals);

			$self -> error_message($message);
			$self -> error_number(2);

			if ($self -> options & ambiguity_is_fatal)
			{
				# This 'die' is inside try{}catch{}, which adds the prefix 'Error: '.

				die "$message\n";
			}
			elsif ($self -> options & print_warnings)
			{
				$self -> error_number(-2);

				print "Warning: $message\n";
			}
		}

		my($hex_as_char) = $self -> options & return_hex_as_chars;
		my($long_form)   = $self -> options & long_descriptors;
		my($value_ref)   = $self -> recce -> value;

		my(@hex);

		if (defined $value_ref)
		{
			$self -> stack(Set::Array -> new);

			my($count) = 0;

			my($type);
			my($value);

			for my $item (@{$self -> decode_result($$value_ref)})
			{
				next if (! defined($item) );
				next if ($item =~ /^[=,; ]$/);

				if ($item eq '+')
				{
					# The 'multivalued' key is use for temporary storage. See _combine().
					# 'count' holds the count of RDNs within this stack element.

					$self -> stack -> push({multivalued => 1});

					next;
				}

				$count++;

				# This line uses $$item{value}, not $$item{type}!
				# $$item{type} takes these values:
				# Count  Type
				#     1  type
				#     2  value
				#     3  type
				#     4  value
				#   ...

				$value = $$item{value};

				if ( ($count % 2) == 1)
				{
					$type = $long_form && $descriptors{$value} ? $descriptors{$value} : $value;
				}
				else
				{
					if ($hex_as_char && (substr($value, 0, 1) eq '#') )
					{
						@hex   = ();
						$value = substr($value, 1);

						while ($value =~ /(..)/g)
						{
							push @hex, $1;
						}

						$value = join('', map{chr hex} @hex);
					}

					# The 'multivalued' key is use for temporary storage. See _combine().
					# 'count' holds the count of RDNs within this stack element.

					$self -> stack -> push({count => 1, multivalued => 0, type => $type, value => $value});
				}
			}

			$self -> _combine;
		}
		else
		{
			$result = 1;

			print "Error: Parse failed\n" if ($self -> options & print_errors);
		}
	}
	catch
	{
		$result = 1;

		print "Error: Parse failed. ${_}" if ($self -> options & print_errors);
	};

	# Return 0 for success and 1 for failure.

	return $result;

} # End of parse.

# ------------------------------------------------

sub rdn
{
	my($self, $n) = @_;
	$n        -= 1;
	my(@rdn)  = $self -> stack -> print;

	return ( ($n < 0) || ($n > $#rdn) ) ? '' : "${$rdn[$n]}{type}=${$rdn[$n]}{value}";

} # End of rdn.

# ------------------------------------------------

sub rdn_count
{
	my($self, $n) = @_;
	$n        -= 1;
	my(@rdn)  = $self -> stack -> print;

	return ( ($n < 0) || ($n > $#rdn) ) ? 0 : ${$rdn[$n]}{count};

} # End of rdn_count.

# ------------------------------------------------

sub rdn_number
{
	my($self) = @_;

	return $self -> stack -> length;

} # End of rdn_number.

# ------------------------------------------------

sub rdn_type
{
	my($self, $n) = @_;
	$n       -= 1;
	my(@rdn) = $self -> stack -> print;

	return ( ($n < 0) || ($n > $#rdn) ) ? '' : ${$rdn[$n]}{type};

} # End of rdn_type.

# ------------------------------------------------

sub rdn_types
{
	my($self, $n) = @_;
	$n       -= 1;
	my(@rdn) = $self -> stack -> print;

	my(@result);

	return @result if ( ($n < 0) || ($n > $#rdn) );

	my(@bits)  = split(/\+/, "${$rdn[$n]}{type}=${$rdn[$n]}{value}");
	my(@parts) = map{split(/=/, $_)} @bits;

	for my $i (0 .. $#parts)
	{
		push @result, $parts[$i] if ( ($i % 2) == 0);
	}

	return @result;

} # End of rdn_types.

# ------------------------------------------------

sub rdn_value
{
	my($self, $n) = @_;
	$n            -= 1;
	my(@rdn)      = $self -> stack -> print;
	my($result)   = '';

	if ( ($n >= 0) && ($n <= $#rdn) )
	{
		# This returns '' for an RDN of 'x='. See *::Actions.attribute_value().

		$result = ${$rdn[$n]}{value};
	}

	return $result;

} # End of rdn_value.

# ------------------------------------------------

sub rdn_values
{
	my($self, $type) = @_;
	$type = lc $type;

	my(@result);

	for my $rdn ($self -> stack -> print)
	{
		push @result, $$rdn{value} if ($$rdn{type} eq $type);
	}

	return @result;

} # End of rdn_values.

# ------------------------------------------------

1;

=pod

=encoding utf8

=head1 NAME

C<X500::DN::Marpa> - Parse X.500 DNs

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use X500::DN::Marpa ':constants';

	# -----------

	my(%count)  = (fail => 0, success => 0, total => 0);
	my($parser) = X500::DN::Marpa -> new
	(
		options => long_descriptors,
	);
	my(@text) =
	(
		q||,
		q|1.4.9=2001|,
		q|cn=Nemo,c=US|,
		q|cn=Nemo, c=US|,
		q|cn = Nemo, c = US|,
		q|cn=John Doe, o=Acme, c=US|,
		q|cn=John Doe, o=Acme\\, Inc., c=US|,
		q|x= |,
		q|x=\\ |,
		q|x = \\ |,
		q|x=\\ \\ |,
		q|x=\\#\"\\41|,
		q|x=#616263|,
		q|SN=Lu\C4\8Di\C4\87|,		# 'Lučić'.
		q|foo=FOO + bar=BAR + frob=FROB, baz=BAZ|,
		q|UID=jsmith,DC=example,DC=net|,
		q|OU=Sales+CN=J.  Smith,DC=example,DC=net|,
		q|CN=James \"Jim\" Smith\, III,DC=example,DC=net|,
		q|CN=Before\0dAfter,DC=example,DC=net|,
		q|1.3.6.1.4.1.1466.0=#04024869|,
		q|UID=nobody@example.com,DC=example,DC=com|,
		q|CN=John Smith,OU=Sales,O=ACME Limited,L=Moab,ST=Utah,C=US|,
	);

	my($result);

	for my $text (@text)
	{
		$count{total}++;

		print "# $count{total}. Parsing |$text|. \n";

		$result = $parser -> parse($text);

		print "Parse result: $result (0 is success)\n";

		if ($result == 0)
		{
			$count{success}++;

			for my $item ($parser -> stack -> print)
			{
				print "$$item{type} = $$item{value}. count = $$item{count}. \n";
			}

			print 'DN:         ', $parser -> dn, ". \n";
			print 'OpenSSL DN: ', $parser -> openssl_dn, ". \n";
		}

		print '-' x 50, "\n";
	}

	$count{fail} = $count{total} - $count{success};

	print "\n";
	print 'Statistics: ', join(', ', map{"$_ => $count{$_}"} sort keys %count), ". \n";

See scripts/synopsis.pl.

This is part of the printout of synopsis.pl:

	# 3. Parsing |cn=Nemo,c=US|.
	Parse result: 0 (0 is success)
	commonName = Nemo. count = 1.
	countryName = US. count = 1.
	DN:         countryName=US,commonName=Nemo.
	OpenSSL DN: commonName=Nemo+countryName=US.
	--------------------------------------------------
	...
	--------------------------------------------------
	# 13. Parsing |x=#616263|.
	Parse result: 0 (0 is success)
	x = #616263. count = 1.
	DN:         x=#616263.
	OpenSSL DN: x=#616263.
	--------------------------------------------------
	...
	--------------------------------------------------
	# 15. Parsing |foo=FOO + bar=BAR + frob=FROB, baz=BAZ|.
	Parse result: 0 (0 is success)
	foo = FOO+bar=BAR+frob=FROB. count = 3.
	baz = BAZ. count = 1.
	DN:         baz=BAZ,foo=FOO+bar=BAR+frob=FROB.
	OpenSSL DN: foo=FOO+bar=BAR+frob=FROB+baz=BAZ.

If you set the option C<return_hex_as_chars>, as discussed in the L</FAQ>, then case 13 will print:

	# 13. Parsing |x=#616263|.
	Parse result: 0 (0 is success)
	x = abc. count = 1.
	DN:         x=abc.
	OpenSSL DN: x=abc.

=head1 Description

C<X500::DN::Marpa> provides a L<Marpa::R2>-based parser for parsing X.500 Distinguished Names.

It is based on L<RFC4514|https://www.ietf.org/rfc/rfc4514.txt>:
Lightweight Directory Access Protocol (LDAP): String Representation of Distinguished Names.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install C<X500::DN::Marpa> as you would any C<Perl> module:

Run:

	cpanm X500::DN::Marpa

or run:

	sudo cpan X500::DN::Marpa

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = X500::DN::Marpa -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<X500::DN::Marpa>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</options([$bit_string])>]):

=over 4

=item o options => $bit_string

This allows you to turn on various options.

Default: 0 (nothing is fatal).

See the L</FAQ> for details.

=item o text => $a_string_to_be_parsed

Default: ''.

=back

=head1 Methods

=head2 bnf()

Returns a string containing the grammar used by this module.

=head2 dn()

Returns the RDNs, separated by commas, as a single string in the reverse order compared with the
order of the RNDs in the input text.

The order reversal is discussed in section 2.1 of L<RFC4514|https://www.ietf.org/rfc/rfc4514.txt>.

Hence 'cn=Nemo, c=US' is returned as 'countryName=US,commonName=Nemo' (when the
C<long_descriptors> option is used), and as 'c=US,cn=Nemo' by default.

See also L</openssl_dn()>.

=head2 error_message()

Returns the last error or warning message set.

Error messages always start with 'Error: '. Messages never end with "\n".

Parsing error strings is not a good idea, ever though this module's format for them is fixed.

See L</error_number()>.

=head2 error_number()

Returns the last error or warning number set.

Warnings have values < 0, and errors have values > 0.

If the value is > 0, the message has the prefix 'Error: ', and if the value is < 0, it has the
prefix 'Warning: '. If this is not the case, it's a reportable bug.

Possible values for error_number() and error_message():

=over 4

=item o 0 => ""

This is the default value.

=item o 1/-1 => "Parse exhausted"

If L</error_number()> returns 1, it's an error, and if it returns -1 it's a warning.

You can set the option C<exhaustion_is_fatal> to make it fatal.

=item o 2/-2 => "Ambiguous parse. Status: $status. Terminals expected: a, b, ..."

This message is only produced when the parse is ambiguous.

If L</error_number()> returns 2, it's an error, and if it returns -2 it's a warning.

You can set the option C<ambiguity_is_fatal> to make it fatal.

=back

See L</error_message()>.

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

=head2 openssl_dn()

Returns the RDNs, separated by pluses, as a single string in the same order compared with the
order of the RNDs in the input text.

Hence 'cn=Nemo, c=US' is returned as 'commonName=Nemo+countryName=US' (when the
C<long_descriptors> option is used), and as 'cn=Nemo+c=US' by default.

See also L</dn()>.

=head2 options([$bit_string])

Here, the [] indicate an optional parameter.

Get or set the option flags.

For typical usage, see scripts/synopsis.pl.

See the L</FAQ> for details.

'options' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 parse([$string])

Here, the [] indicate an optional parameter.

This is the only method the user needs to call. All data can be supplied when calling L</new()>.

You can of course call other methods (e.g. L</text([$string])> ) after calling L</new()> but
before calling C<parse()>.

Note: If a string is passed to C<parse()>, it takes precedence over any string passed to
C<< new(text => $string) >>, and over any string passed to L</text([$string])>. Further,
the string passed to C<parse()> is passed to L</text([$string)>, meaning any subsequent
call to C<text()> returns the string passed to C<parse()>.

See scripts/synopsis.pl.

Returns 0 for success and 1 for failure.

If the value is 1, you should call L</error_number()> to find out what happened.

=head2 rdn($n)

Returns a string containing the $n-th RDN, or returns '' if $n is out of range.

$n counts from 1.

If the input is 'UID=nobody@example.com,DC=example,DC=com', C<rdn(1)> returns
'uid=nobody@example.com'. Note the lower-case 'uid'.

See t/dn.t.

=head2 rdn_count($n)

Returns a string containing the $n-th RDN's count (multivalue indicator), or returns 0 if $n is out
of range.

$n counts from 1.

If the input is 'UID=nobody@example.com,DC=example,DC=com', C<rdn_count(1)> returns 1.

If the input is 'foo=FOO+bar=BAR+frob=FROB, baz=BAZ', C<rdn_count(1)> returns 3.

Not to be confused with L</rdn_number()>.

See t/dn.t.

=head2 rdn_number()

Returns the number of RDNs, which may be 0.

If the input is 'UID=nobody@example.com,DC=example,DC=com', C<rdn_number()> returns 3.

Not to be confused with L</rdn_count($n)>.

See t/dn.t.

=head2 rdn_type($n)

Returns a string containing the $n-th RDN's attribute type, or returns '' if $n is out of range.

$n counts from 1.

If the input is 'UID=nobody@example.com,DC=example,DC=com', C<rdn_type(1)> returns 'uid'.

See t/dn.t.

=head2 rdn_types($n)

Returns an array containing all the types of all the RDNs for the given RDN, or returns () if $n is
out of range.

$n counts from 1.

If the DN is 'foo=FOO+bar=BAR+frob=FROB, baz=BAZ', C<rdn_types(1)> returns ('foo', 'bar', frob').

See t/dn.t.

=head2 rdn_value($n)

Returns a string containing the $n-th RDN's attribute value, or returns '' if $n is out of
range.

$n counts from 1.

If the input is 'UID=nobody@example.com,DC=example,DC=com', C<rdn_type(1)> returns
'nobody@example.com'.

See t/dn.t.

=head2 rdn_values($type)

Returns an array containing the RDN attribute values for the attribute type $type, or ().

If the input is 'UID=nobody@example.com,DC=example,DC=com', C<rdn_values('DC')> returns
('example', 'com').

See t/dn.t.

=head2 stack()

Returns an object of type L<Set::Array>, which holds the parsed data.

Obviously, it only makes sense to call C<stack()> after calling L</parse([$string])>.

The structure of elements in this stack is documented in the L</FAQ>.

See scripts/tiny.pl for sample code.

=head2 text([$string])

Here, the [] indicate an optional parameter.

Get or set a string to be parsed.

'text' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head1 FAQ

=head2 Where are the error messages and numbers described?

See L</error_message()> and L</error_number()>.

See also L</What are the possible values for the 'options' parameter to new()?> below.

=head2 What is the structure in RAM of the parsed data?

The module outputs a stack, which is an object of type L<Set::Array>. See L</stack()>.

Elements in this stack are in the same order as the RDNs are in the input string.

The L</dn()> method returns the RDNs, separated by commas, as a single string in the reverse order,
whereas L</openssl_dn()> separates them by pluses and uses the original order.

Each element of this stack is a hashref, with these (key => value) pairs:

=over 4

=item o count => $number

The number of attribute types and values in a (possibly multivalued) RDN.

$number counts from 1.

=item o type => $type

The attribute type.

=item o value => $value

The attribute value.

=back

Sample DNs:

Note: These examples assume the default case of the option C<long_descriptors> (discussed below)
I<not> being used.

If the input is 'UID=nobody@example.com,DC=example,DC=com', the stack will contain:

=over 4

=item o [0]: {count => 1, type => 'uid', value => 'nobody@example.com'}

=item o [1]: {count => 1, type => 'dc', value => 'example'}

=item o [2]: {count => 1, type => 'dc', value => 'com'}

=back

If the input is 'foo=FOO+bar=BAR+frob=FROB, baz=BAZ', the stack will contain:

=over 4

=item o [0]: {count => 3, type => 'foo', value => 'FOO+bar=BAR+frob=FROB'}

=item o [1]: {count => 1, type => 'baz', value => 'BAZ'}

=back

Sample Code:

A typical script uses code like this (copied from scripts/tiny.pl):

	$result = $parser -> parse($text);

	print "Parse result: $result (0 is success)\n";

	if ($result == 0)
	{
		for my $item ($parser -> stack -> print)
		{
			print "$$item{type} = $$item{value}. count = $$item{count}. \n";
		}
	}

If the option C<long_descriptors> is I<not> used in the call to L</new()>, then $$item{type}
defaults to lower-case. L<RFC4512|https://www.ietf.org/rfc/rfc4512.txt> says 'Short names are case
insensitive....'. I've chosen to use lower-case as the canonical form output by my code.

If that option I<is> used, then some types are output in mixed case. The list of such types is given
in section 3 (at the top of page 6) in L<RFC4514|https://www.ietf.org/rfc/rfc4514.txt>. This
document is one of those listed in L</References>, below.

For a discussion of the mixed-case descriptors, see
L</What are the possible values for the 'options' parameter to new()?> below.

An extended list of such long descriptors is given in section 4 (page 25) in
L<RFC4519|https://www.ietf.org/rfc/rfc4519.txt>. Note that 'streetAddress' is missing from this
list.

=head2 What are the possible values for the 'options' parameter to new()?

Firstly, to make these constants available, you must say:

	use X500::DN::Marpa ':constants';

Secondly, more detail on errors and warnings can be found at L</error_number()>.

Thirdly, for usage of these option flags, see scripts/synopsis.pl and scripts/tiny.pl.

Now the flags themselves:

=over 4

=item o nothing_is_fatal

This is the default.

C<nothing_is_fatal> has the value of 0.

=item o print_errors

Print error messages if this flag is set.

C<print_errors> has the value of 1.

=item o print_warnings

Print various warnings if this flag is set:

=over 4

=item o The ambiguity status and terminals expected, if the parse is ambiguous

=item o See L</error_number()> for other warnings which might be printed

Ambiguity is not, in and of itself, an error. But see the C<ambiguity_is_fatal> option, below.

=back

It's tempting to call this option C<warnings>, but Perl already has C<use warnings>, so I didn't.

C<print_warnings> has the value of 2.

=item o print_debugs

Print extra stuff if this flag is set.

C<print_debugs> has the value of 4.

=item o ambiguity_is_fatal

This makes L</error_number()> return 2 rather than -2.

C<ambiguity_is_fatal> has the value of 8.

=item o exhaustion_is_fatal

This makes L</error_number()> return 1 rather than -1.

C<exhaustion_is_fatal> has the value of 16.

=item o long_descriptors

This makes the C<type> key in the output stack's elements contain long descriptor names rather than
abbreviations.

For example, if the input was 'cn=Nemo,c=US', the output stack would contain, I<by default>, i.e.
without setting this option:

=over 4

=item o [0]: {count => 1, type => 'cn', value => 'Nemo'}

=item o [1]: {count => 1, type => 'c', value => 'US'}

=back

However, if this option is set, the output will contain:

=over 4

=item o [0]: {count => 1, type => 'commonName', value => 'Nemo'}

=item o [1]: {count => 1, type => 'countryName', value => 'US'}

=back

C<long_descriptors> has the value of 32.

=item o return_hex_as_chars

This triggers extra processing of attribute values which start with '#':

=over 4

=item o The value is assumed to consist entirely of hex digits (after the '#' is discarded)

=item o The digits are converted 2 at-a-time into a string of (presumably ASCII) characters

=item o These characters are concatenated into a single string, which becomes the new value

=back

So, if this option is I<not> used, 'x=#616263' is parsed as {type => 'x', value => '#616263'},
but if the option I<is> used, you get {type => 'x', value => 'abc'}.

C<return_hex_as_chars> has the value of 64.

=back

=head2 Does this package support Unicode/UTF8?

Handling of UTF8 is discussed in one of the RFCs listed in L</References>, below.

=head2 What is the homepage of Marpa?

L<http://savage.net.au/Marpa.html>.

That page has a long list of links.

=head2 How do I run author tests?

This runs both standard and author tests:

	shell> perl Build.PL; ./Build; ./Build authortest

=head1 References

I found RFCs 4514 and 4512 to be the most directly relevant ones.

L<RFC Index|https://www.ietf.org/rfc/rfc-index.txt>: The Index. Just search for 'LDAP'.

L<RFC4514|https://www.ietf.org/rfc/rfc4514.txt>:
Lightweight Directory Access Protocol (LDAP): String Representation of Distinguished Names.

L<RFC4512|https://www.ietf.org/rfc/rfc4512.txt>:
Lightweight Directory Access Protocol (LDAP): Directory Information Models.

L<RFC4517|https://www.ietf.org/rfc/rfc4517.txt>:
Lightweight Directory Access Protocol (LDAP): Syntaxes and Matching Rules.

L<RFC5234|https://www.ietf.org/rfc/rfc5234.txt>:
Augmented BNF for Syntax Specifications: ABNF.

L<RFC3629|https://www.ietf.org/rfc/rfc3629.txt>: UTF-8, a transformation format of ISO 10646.

RFC4514 also discusses UTF8. Search it using the string 'UTF-8'.

=head1 See Also

L<X500::DN>. Note: This module is based on the obsolete
L<RFC2253|https://www.ietf.org/rfc/rfc2253.txt>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/X500-DN-Marpa>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=X500::DN::Marpa>.

=head1 Author

L<X500::DN::Marpa> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2015.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2015, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut
