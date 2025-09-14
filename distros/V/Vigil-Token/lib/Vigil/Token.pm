package Vigil::Token;

use strict;
use warnings;
use 5.010;
use MIME::Base64 qw(encode_base64);
use Bytes::Random::Secure qw(random_bytes);
use Math::BigInt;

our $VERSION = '2.0.0';

sub new { bless {}, shift }

#Token of digits only
sub otp {
    my ($self) = @_;

    my $min = 100_000;
    my $max = 999_999;
    my $range = $max - $min + 1;

    my $num;
    do {
        my $bytes = random_bytes(4);          # 32-bit random
        $num = unpack("N", $bytes);           # big-endian 32-bit integer
    } while ($num >= int(2**32 / $range) * $range);  # rejection sampling

    return $num % $range + $min;
}

sub custom_token {
    my ($self, $length) = @_;
    die "custom_token requires a positive length" unless $length > 0;
    # Compute bytes needed to get at least $length Base64 chars
    my $num_bytes = int(($length * 6 + 7) / 8);  # ceil(length*6/8)
    my $bytes = random_bytes($num_bytes);
    my $token = encode_base64($bytes, '');
    $token =~ tr[+/][-_];  # Base64URL
    $token =~ s/=+$//;     # remove padding
    return substr($token, 0, $length);  # exact length
}

use overload
    '&{}' => \&as_coderef,
    fallback => 1;

sub as_coderef {
    my ($self) = @_;
    return sub {
        my @args = @_;
        return $self->custom_token(@args);
    };
}

1;

__END__

=head1 NAME

Vigil::Token - Cryptographically secure, URL-safe token generator for OTPs, sessions, and custom codes.

=head1 SYNOPSIS

=over 4

    EXAMPLE 1.
    #!/user/bin/perl
	
    use Vigil::Token;
    my $token = Vigil::Token->new;
	
    my $session_token = $token->custom_token(256);
	
    my $short_token = $token->custom_token(12);
	
    my $some_token = $token->(16);    #An alias for $token->custom_token(16);
	
    my $digits_be_6_for_otp = $token->otp(6);

=back

=head1 DESCRIPTION

Vigil::Token is a sleek, high-octane token generator that effortlessly handles both human-friendly codes and 
machine-to-machine secrets. Need a short, 6-digit OTP that users can type without mistaking a 0 for an O? 
Done. Looking for a massive, 256-character session token to lock down API calls or web sessions? Done. 
Every token is backed by cryptographically strong randomness using Bytes::Random::Secure, ensuring each 
byte of entropy is truly unpredictable. All strings are automatically URL-safe via Base64URL encoding, 
so they slide seamlessly into cookies, query strings, or HTML forms without worrying about escaping. With 
its flexible custom_token() function, Vigil::Token balances readability and security perfectly: short codes 
are human-friendly, long codes maximize entropy, and all tokens are guaranteed to be the exact length you 
request. Lightweight, reliable, and unrelentingly secure, Vigil::Token is the ultimate Swiss Army knife for 
modern web authentication and cryptographic token needs.

=head2 OBJECT METHODS

=over 4

=item my $one_time_password = $obj-E<gt>otp( LENGTH )

Returns a string of digits only. Will return up to 12 digits as specified by LENGTH.

=item $obj->custom_token( LENGTH );

Returns a string that is automatically URL-safe via Base64URL encoding. The number of characters in the string is determined by LENGTH.

=back

=head2 Local Installation

If your host does not allow you to install from CPAN, then you can install this module locally two ways:

=over 4

=item * Same Directory

In the same directory as your script, create a subdirectory called "Vigil". Then add these two lines, in this order, to your script:

	use lib '.';           # Add current directory to @INC
	use Vigil::Token;      # Now Perl can find the module in the same dir
	
	#Then call it as normal:
	my $token = Vigil::Token->new;

=item * In a different directory

First, create a subdirectory called "Vigil" then add it to C<@INC> array through a C<BEGIN{}> block in your script:

	#!/usr/bin/perl
	BEGIN {
		push(@INC, '/path/on/server/to/Vigil');
	}
	
	use Vigil::Token;
	
	#Then call it as normal:
	my $token = Vigil::Token->new;

=back

=head1 AUTHOR

Jim Melanson (jmelanson1965@gmail.com).

Created: July, 2017.

Last Update: August 2025.

=head1 LICENSE

This module is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

=cut







