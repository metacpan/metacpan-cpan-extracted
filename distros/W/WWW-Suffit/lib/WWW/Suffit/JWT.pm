package WWW::Suffit::JWT;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::JWT - JSON Web Token for Suffit authorization

=head1 SYNOPSIS

    use WWW::Suffit::JWT;

    my $jwt = WWW::Suffit::JWT->new(
        secret => "MySecret",
        payload => {foo => 'bar'},
    );
    my $token = $jwt->encode->token or die $jwt->error;
    my $payload = $jwt->decode($token)->payload;
    die $jwt->error if $jwt->error;

    use WWW::Suffit::RSA;
    my $rsa = WWW::Suffit::RSA->new(key_size => 1024);
    $rsa->keygen;
    my $private_key = $rsa->private_key;
    my $public_key = $rsa->public_key;
    my $jwt = WWW::Suffit::JWT->new(
        private_key => $private_key,
        payload => {foo => 'bar'},
        algorithm => 'RS512',
    );
    my $token = $jwt->encode->token or die $jwt->error;
    my $payload = $jwt->public_key($public_key)->decode($token)->payload;
    die $jwt->error if $jwt->error;

=head1 DESCRIPTION

JSON Web Token for Suffit authorization

This module based on L<Mojo::JWT>

JSON Web Token is described in L<https://tools.ietf.org/html/rfc7519>.

=head1 ATTRIBUTES

This class implements the following attributes

=head2 algorithm

The algorithm to be used to sign a JWT during encoding or else the algorithm that was used for the most recent decoding.
Defaults to C<HS256> until a decode is performed.

    none    no integrity (NOTE: disabled for decode method)
    HS256   HMAC+SHA256 integrity
    HS384   HMAC+SHA384 integrity
    HS512   HMAC+SHA512 integrity
    RS256   RSA+PKCS1-V1_5 + SHA256 signature
    RS384   RSA+PKCS1-V1_5 + SHA384 signature
    RS512   RSA+PKCS1-V1_5 + SHA512 signature

B<NOTE!> We recommend using RS512

=head2 error

    $jwt->error($new_error);
    my $error = $jwt->error;

Sets/gets the error string

=head2 expires

The epoch time value after which the JWT value should not be considered valid.
This value (if set and not undefined) will be used as the C<exp> key in the payload
or was extracted from the payload during the most recent decoding.

=head2 header

Header - first part of JWT structure

You may set your own headers when encoding the JWT bypassing a hash reference to the L</header> attribute.
Please note that there are two default headers set.
B<alg> is set to the value of L</algorithm> or 'HS256' and B<typ> is set to 'JWT'. These cannot be overridden.

    my $header = $jwt->header;

Returns a hash reference representing the JWT header, constructed from instance attributes (see L</algorithm>).

=head2 iat

It is epoch time value that will be set as C<iat> during L</encode>.

=head2 not_before

The epoch time value before which the JWT value should not be considered valid.
This value (if set and not undefined) will be used as the C<nbf> key in the payload
or was extracted from the payload during the most recent decoding.

=head2 payload

Payload - second part of JWT structure

The payload is a user data structure to be encoded. This must be a hash reference only.

=head2 private_key

The RSA private key to be used in edcoding an asymmetrically signed JWT. See L<WWW::Suffit::RSA>

=head2 public_key

The RSA public key to be used in decoding an asymmetrically signed JWT. See L<WWW::Suffit::RSA>

=head2 secret

The symmetric secret used in encoding an symmetrically HMAC

=head2 token

The most recently encoded or decoded token.

    $jwt->token($new_token);
    my $token = $jwt->token;

Sets/gets the token

=head1 METHODS

This class inherits all of the methods from L<Mojo::Base>
and implements the following new ones

=head2 decode

    my $payload = $jwt->decode($token)->payload;

Decode and parse a JSON Web Token string and return the payload hashref (see L</payload>).

=head2 encode

    my $token = $jwt->encode->token;

Encode the data expressed in the instance attributes: L</algorithm>, L</payload>, L</expires>, L</not_before>.
Note that if the timing attributes are given, they override existing keys in the L</payload>.
Calling C<encode> immediately clears the L</token> and upon completion sets it to the result (See L</token>)

=head2 sign_hmac

    my $signature = $jwt->sign_hmac($size, $string);

Returns the HMAC SHA signature for the given size and string.
The L</secret> attribute is used as the symmetric key.
The result is base64url encoded!
This method is provided mostly for the purposes of subclassing.

=head2 sign_rsa

    my $signature = $jwt->sign_rsa($size, $string);

Returns the RSA signature for the given size and string.
The L</private_key> attribute is used as the private key.
The result is base64url encoded!
This method is provided mostly for the purposes of subclassing.

=head2 verify_hmac

    my $bool = $jwt->verify_hmac($size, $string, $signature);

Returns true if the given HMAC size algorithm validates the given string and signature.
The L</secret> attribute is used as the HMAC passphrase.
The signature is base64url encoded!
This method is provided mostly for the purposes of subclassing.

=head2 verify_rsa

    my $bool = $jwt->verify_rsa($size, $string, $signature);

Returns true if the given RSA size algorithm validates the given string and signature.
The L</public_key> attribute is used as the public key.
The signature is base64url encoded!
This method is provided mostly for the purposes of subclassing.

=head1 DEPENDENCIES

L<WWW::Suffit::RSA>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<WWW::Suffit::RSA>, L<Crypt::OpenSSL::RSA>, L<Mojo::JWT>,
L<Acme::JWT>, L<JSON::WebToken>, L<https://jwt.io/>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head2 CONTRIBUTORS

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

Christopher Raa (mishanti1)

Cameron Daniel (ccakes)

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

Copyright (C) 2023 by L</CONTRIBTORS>.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.00';

use Mojo::Base -base;

use Mojo::JSON qw/encode_json decode_json/;
use Mojo::Util qw/b64_encode b64_decode/;
use MIME::Base64 qw/encode_base64url decode_base64url/;
use Digest::SHA qw//;
use WWW::Suffit::RSA;

use constant DEFAULT_ALGORITHM => 'HS256';

has 'token'; # Result token
has 'secret' => ''; # For HMAC
has 'algorithm' => DEFAULT_ALGORITHM(); # By default
has 'expires'; # Expire time
has 'not_before'; # Time "not before"
has 'iat' => 0; # Payload iat param
has 'jti' => 0; # Payload jti param
has 'private_key'; # For RSA
has 'public_key'; # For RSA
has 'error' => ''; # Error string
has 'header' => sub { {} }; # Header (first part of JWT)
has 'payload' => sub { {} }; # Payload (second parg of JWT)

# Regexps
my $re_hs = qr/^HS(\d+)$/; # HMAC
my $re_rs = qr/^RS(\d+)$/; # RSA

sub encode {
    my $self = shift;
    $self->error(''); # Flush error string first
    $self->token(''); # Flush old token

    # Header
    my %header = %{ $self->header // {} }; # Get Header
    $header{typ} = 'JWT';
    $header{alg} = $self->algorithm;

    # Payload
    my %payload = %{ $self->payload // {} }; # Get Payload
    $payload{iat} = $self->iat if $self->iat;
    $payload{jti} = $self->jti if $self->jti;
    $payload{exp} = $self->expires if defined($self->expires);
    $payload{nbf} = $self->not_before if defined($self->not_before);

    # Concat (<Header>.<Payload>)
    my $concat = sprintf("%s.%s",
        encode_base64url(encode_json(\%header)),
        encode_base64url(encode_json(\%payload))
    );

    # Signature
    my $signature;
    my $algo = $self->algorithm;
    if ($algo eq 'none') {
        $signature = '';
    } elsif ($algo =~ $re_hs) { # HMAC
        $signature = $self->sign_hmac($1, $concat);
    } elsif ($algo =~ $re_rs) { # RSA
        $signature = $self->sign_rsa($1, $concat);
    } else {
        $self->error('Unknown algorithm');
    }
    return $self unless defined $signature;

    # Set new token
    $self->token(sprintf("%s.%s", $concat, $signature));

    # Returns OBJECT!!
    return $self;
}
sub decode {
    my $self = shift;
    my $token = shift;
    $self->error(''); # Flush error string first
    $self->token($token) if $token;

    # Reset
    $self->header({});
    $self->payload({});
    $self->algorithm(DEFAULT_ALGORITHM);
    $self->expires(undef);
    $self->not_before(undef);

    # Load parts
    return $self->error('Token not specified') unless $self->token;
    my ($hstring, $pstring, $signature) = split /\./, $self->token;
    my ($header, $payload) = ({}, {});
    if ($hstring) {
        $header = eval { decode_json(decode_base64url($hstring)) } || {};
        if ($@) {
            chomp $@;
            return $self->error(sprintf "Incorrect JWT header: %s", $@ || 'unknown parser error');
        }
    }
    if ($pstring) {
        $payload = eval { decode_json(decode_base64url($pstring)) } || {};
        if ($@) {
            chomp $@;
            return $self->error(sprintf "Incorrect JWT payload: %s", $@ || 'unknown parser error');
        }
    }
    return $self->error('Signature not found') unless $signature;
    my $concat = sprintf("%s.%s", $hstring // '', $pstring // '');

    # typ header is only recommended and is ignored
    # https://tools.ietf.org/html/rfc7519#section-5.1
    delete $header->{typ} if exists $header->{typ};

    # Get algo
    my $algo = $header->{alg};
    return $self->error('Required header field "alg" not specified') unless $algo;
    delete $header->{alg};
    $self->algorithm($algo);

    # Set Header
    $self->header($header);

    # Check signature
    my $status = 0;
    if ($algo eq 'none') {
        $self->error('Algorithm "none" is prohibited, which means that token has no signature');
    } elsif ($algo =~ $re_hs) { # HMAC
        $status = $self->verify_hmac($1, $concat, $signature);
        if ($self->error) {
            $self->error(sprintf('Failed HS validation: %s', $self->error))
        } elsif (!$status) {
            $self->error('Failed HS validation');
        }
    } elsif ($algo =~ $re_rs) { # RSA
        $status = $self->verify_rsa($1, $concat, $signature);
        if ($self->error) {
            $self->error(sprintf('Failed RS validation: %s', $self->error))
        } elsif (!$status) {
            $self->error('Failed RS validation');
        }
    } else {
        $self->error('Unsupported signing algorithm');
    }
    return $self unless $status;

    # Check timing
    my $now = time;
    my $exp = $payload->{exp};
    my $nbf = $payload->{nbf};
    if (defined($exp)) {
        return $self->error('JWT has expired') if $now > $exp;
        $self->expires($exp);
    }
    if (defined($nbf)) {
        return $self->error('JWT is not yet valid') if $now < $nbf;
        $self->not_before($nbf);
    }

    # Set Payload
    $self->payload($payload);

    # Returns OBJECT!!
    return $self;
}
sub sign_hmac {
    my ($self, $size, $concat) = @_;

    # Get Symmetric key or return
    my $secret = $self->secret;
    $self->error('Symmetric key (secret) not specified') && return unless $secret;

    # Get HMAC function
    my $f = Digest::SHA->can("hmac_sha$size");
    $self->error('Unsupported HS signing algorithm') && return unless $f;

    # Sign!
    my $sign = $f->($concat, $secret) // '';
    return '' unless length $sign;
    return encode_base64url($sign);
}
sub sign_rsa {
    my ($self, $size, $concat) = @_;

    # Get RSA private key
    my $private_key = $self->private_key;
    $self->error('Private key (private_key) not specified') && return unless $private_key;

    # Create RSA object
    my $rsa = WWW::Suffit::RSA->new(private_key => $private_key);

    # Sign!
    my $sign = $rsa->sign($concat, $size) // '';
    unless (length($sign)) {
        $self->error($rsa->error);
        return;
    }
    return _b64_to_b64url($sign);
}
sub verify_hmac {
    my ($self, $size, $concat, $signature) = @_;

    # Sign
    my $got = $self->sign_hmac($size, $concat);

    # Return status
    return 1 if $signature && $got && $signature eq $got;
    return 0;
}
sub verify_rsa {
    my ($self, $size, $concat, $signature) = @_;

    # Get RSA public key
    my $public_key = $self->public_key;
    $self->error('Public key (public_key) not specified') && return unless $public_key;

    # Create RSA object
    my $rsa = WWW::Suffit::RSA->new(public_key => $public_key);

    # Verify!
    return 1 if $rsa->verify($concat, _b64url_to_b64($signature));
    $self->error($rsa->error);
    return 0;
}

sub _b64_to_b64url {
    my $e = shift // '';
    $e =~ s/=+\z//;
    $e =~ tr[+/][-_];
    return $e;
}
sub _b64url_to_b64 {
    my $s = shift // '';
    $s =~ tr[-_][+/];
    $s .= '=' while length($s) % 4;
    return $s;
}

1;

__END__
