# Copyrights 2012-2025 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution XML-Compile-WSS-Signature.
# Meta-POD processed with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::WSS::Sign::RSA;{
our $VERSION = '2.04';
}

use base 'XML::Compile::WSS::Sign';

use warnings;
use strict;

use Log::Report 'xml-compile-wss-sig';

use Crypt::OpenSSL::RSA ();
use File::Slurp         qw/read_file/;
use Scalar::Util        qw/blessed/;


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    $self->privateKey
      ( $args->{private_key}
      , hashing => $args->{hashing}
      , padding => $args->{padding}
      );
 
    $self->publicKey
      ( $args->{public_key}
      , hashing => $args->{hashing}
      , padding => $args->{padding}
      );
    $self;
}

#-----------------


sub _setRSAflags($$%)
{   my ($self, $key, $rsa, %args) = @_;
    if(my $hashing = $args{hashing})
    {   my $use_hash = "use_\L$hashing\E_hash";
        $rsa->can($use_hash)
            or error __x"hash {type} not supported by {pkg}"
                , type => $hashing, pkg => ref $key;
        $rsa->$use_hash();
    }

    if(my $padding = $args{padding})
    {   my $use_pad = "use_\L$padding\E_padding";
        $rsa->can($use_pad)
            or error __x"padding {type} not supported by {pkg}"
                , type => $padding, pkg => ref $key;
        $rsa->$use_pad();
    }
    $rsa;
}

sub privateKey(;$%)
{   my ($self, $priv) = (shift, shift);
    defined $priv or return $self->{XCWSR_privkey};

    my ($key, $rsa) = $self->toPrivateSHA($priv);
    $self->{XCWSR_privrsa} = $self->_setRSAflags($key, $rsa, @_);
    $self->{XCWSR_privkey} = $key;
    $key;
}


sub toPrivateSHA($)
{   my ($self, $priv) = @_;

    return ($priv->get_private_key_string, $priv)
        if blessed $priv && $priv->isa('Crypt::OpenSSL::RSA');

    error __x"unsupported private key object `{object}'", object=>$priv
       if ref $priv =~ m/Crypt/;

    return ($priv, Crypt::OpenSSL::RSA->new_private_key($priv))
        if index($priv, "\n") >= 0;

    my $key = read_file $priv;
    my $rsa = eval { Crypt::OpenSSL::RSA->new_private_key($key) };
    if($@)
    {   error __x"cannot read private RSA key from {file}: {err}"
          , file => $priv, err => $@;
    }

    ($key, $rsa);
}


sub privateKeyRSA() {shift->{XCWSR_privrsa}}


sub publicKey(;$%)
{   my $self = shift;
    my $pub   = @_%2==1 ? shift : undef;

    return $self->{XCWSR_pubkey}
        if !defined $pub && $self->{XCWSR_pubkey};

    my $token = $pub || $self->privateKeyRSA
        or return;

    my ($key, $rsa) = $self->toPublicRSA($token);
    $self->{XCWSR_pubrsa} = $self->_setRSAflags($key, $rsa, @_);
    $self->{XCWSR_pubkey} = $pub;
    $pub;
}


sub toPublicRSA($)
{   my ($thing, $token) = @_;
    defined $token or return;

    blessed $token
        or panic "expects a public_key as object, not ".$token;

    return ($token->get_public_key_string, $token)
        if $token->isa('Crypt::OpenSSL::RSA');

    $token = $token->certificate
        if $token->isa('XML::Compile::WSS::SecToken::X509v3');

    my $key = $token->pubkey;
    return ($key, Crypt::OpenSSL::RSA->new_public_key($key))
        if $token->isa('Crypt::OpenSSL::X509');

    error __x"unsupported public key `{token}' for check RSA"
      , token => $token;
}


sub publicKeyString($)
{   my $rsa = shift->publicKeyRSA;
    my $how = shift || '(NONE)';

      $how eq 'PKCS1' ? $rsa->get_public_key_string
    : $how eq 'X509'  ? $rsa->get_public_key_x509_string
    : error __x"unknown public key string format `{name}'", name => $how;
}



sub publicKeyRSA() {shift->{XCWSR_pubrsa}}
 
#-----------------

# Do we need next 4?  Probably not

sub sign(@)
{   my ($self, $text) = @_;
    my $priv = $self->privateKeyRSA
        or error "signing rsa requires the private_key";

    $priv->sign($text);
}

sub encrypt(@)
{   my ($self, $text) = @_;
    my $pub = $self->publicKeyRSA
        or error "encrypting rsa requires the public_key";
    $pub->encrypt($text);
}

sub decrypt(@)
{   my ($self, $text) = @_;
    my $priv = $self->privateKeyRSA
        or error "decrypting rsa requires the private_key";
    $priv->decrypt($text);
}


#XXX Unused?  See checker()
sub check($$)
{   my ($self, $text, $signature) = @_;
    my $rsa = $self->publicKeyRSA
        or error "checking signature with rsa requires the public_key";

    $rsa->verify($text, $signature);
}

### above functions probably not needed.

sub builder()
{   my ($self) = @_;
    my $priv   = $self->privateKeyRSA
        or error "signing rsa requires the private_key";

    sub { $priv->sign($_[0]) };
}

sub checker()
{   my ($self) = @_;
    my $pub = $self->publicKeyRSA
        or error "checking signature with rsa requires the public_key";

    sub { # ($text, $signature)
        $pub->verify($_[0], $_[1]);
    };
}

#-----------------

1;
