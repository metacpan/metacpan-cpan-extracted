package Types::Encodings;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$Types::Encodings::AUTHORITY = 'cpan:TOBYINK';
	$Types::Encodings::VERSION   = '0.002';
}

use Type::Library -base, -declare => qw( Str Bytes Chars );
use Type::Utils;
use Types::Standard;

our $SevenBitSafe = qr{^[\x00-\x7F]*$}sm;

declare Str,
	as Types::Standard::Str;

declare Bytes,
	as Str,
	where     { !utf8::is_utf8($_) },
	inline_as { "!utf8::is_utf8($_)" };

declare Chars,
	as Str,
	where     { utf8::is_utf8($_) or $_ =~ $Types::Encodings::SevenBitSafe },
	inline_as { "utf8::is_utf8($_) or $_ =~ \$Types::Encodings::SevenBitSafe" };

declare_coercion Decode => to_type Chars, {
	coercion_generator => sub {
		my ($self, $target, $encoding) = @_;
		require Encode;
		Encode::find_encoding($encoding)
			or _croak("Parameter \"$encoding\" for Decode[`a] is not an encoding supported by this version of Perl");
		require B;
		$encoding = B::perlstring($encoding);
		return (Bytes, qq{ Encode::decode($encoding, \$_) });
	},
};

declare_coercion Encode => to_type Bytes, {
	coercion_generator => sub {
		my ($self, $target, $encoding) = @_;
		require Encode;
		Encode::find_encoding($encoding)
			or _croak("Parameter \"$encoding\" for Encode[`a] is not an encoding supported by this version of Perl");
		require B;
		$encoding = B::perlstring($encoding);
		return (Chars, qq{ Encode::encode($encoding, \$_) });
	},
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::Encodings - type constraints for Bytes and Chars

=head1 DESCRIPTION

Additional type constraints and coercions to complement L<Types::Standard>.

=head2 Type constraints

=over

=item C<< Str >>

Alias for L<Types::Standard> type constraint of the same name.

=item C<< Bytes >>

Strings where C<< utf8::is_utf8() >> is false.

=item C<< Chars >>

Strings where either C<< utf8::is_utf8() >> is true, or each byte is
below C<0x7F>.

=back

=head2 Coercions

=over

=item C<< Encode[`a] >>

Coercion to encode a character string to a byte string using
C<< Encode::encode() >>. This is a parameterized type coercion, which
expects a character set:

   use Types::Standard qw( Bytes Encode );
   
   has filename => (
      is     => "ro",
      isa    => Bytes->plus_coercions( Encode["utf-8"] ),
      coerce => 1,
   );

=item C<< Decode[`a] >>

Coercion to decode a byte string to a character string using
C<< Encode::decode() >>. This is a parameterized type coercion, which
expects a character set.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Types-Encodings>.

=head1 SEE ALSO

L<Types::Standard>.

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

