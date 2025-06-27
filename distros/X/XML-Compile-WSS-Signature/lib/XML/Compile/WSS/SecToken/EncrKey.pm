# Copyrights 2012-2025 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution XML-Compile-WSS-Signature.
# Meta-POD processed with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::WSS::SecToken::EncrKey;{
our $VERSION = '2.04';
}

use base 'XML::Compile::WSS::SecToken';

use warnings;
use strict;

use Log::Report 'xml-compile-wss-sig';

use XML::Compile::WSS::Util    qw/:xenc :wsm10/;
use XML::Compile::WSS::Sign    ();
use XML::Compile::WSS::KeyInfo ();


sub init($)
{   my ($self, $args) = @_;
    $args->{type} ||= XENC_RSA_OAEP;

    $self->SUPER::init($args);

    my $type  = $self->type;
    $type eq XENC_RSA_OAEP
        or error __x"unsupported encrypted key type {type}", type => $type;

    # This can be made cleaner, via SecToken::fromConfig
    my $signer = $args->{signer}
        or error __x"EncryptedKey needs info about its signer";

    if(ref $signer eq 'HASH')
    {   $signer->{padding} ||= 'PKCS1_OAEP';
        $signer = XML::Compile::WSS::Sign->fromConfig($signer);
    }
    $self->{XCWSE_signer} = $signer;
    $self->{XCWSE_key}    = $args->{key} or panic "no key";

    my $ki      = $args->{key_info} || {};
    $ki->{publish_token} ||= 'SECTOKREF_KEYID';
    $self->{XCWSE_keyinfo} = XML::Compile::WSS::KeyInfo->fromConfig($ki);

    $self;
}

#-----------------

sub signer() {shift->{XCWSE_signer}}
sub key()    {shift->{XCWSE_key}}
sub keyInfo(){shift->{XCWSE_keyinfo}}

#-----------------

# See http://en.wikibooks.org/wiki/XML_-_Managing_Data_Exchange/XML_Encryption

sub _get_encr($$)
{   my ($class, $wss, $args) = @_;
    my $keyinfo      = $wss->keyInfo;
    my $gettokens    = $keyinfo->getTokens($wss);
    my $type_default = $args->{encrtype_default};

    sub {
        my ($h, $sec) = @_;
        my $id     = $h->{Id};
        my @tokens = $gettokens->($h->{ds_KeyInfo}, $sec, $id);
        my $token  = $tokens[0]
            or error __x"no token for encryption key {id}", id => $id;

        my $type   = $h->{xenc_EncryptionMethod}{Algorithm} || $type_default;
        $type eq XENC_RSA_OAEP
            or error __x"unsupported encryption type {type}", type => $type;

        $class->new
          ( id       => $id
          , type     => $type
          , key      => $h->{xenc_CipherData}{xenc_CipherValue}
          , key_info =>
              { key_size => $h->{xenc_KeySize}      # not used
              }
          , signer   =>
              { padding    => 'PKCS1_OAEP'
              , public_key => $tokens[0]
                # OAEP parameters are only used by old PKCS and not supported
                # by openssl
              , params     => $h->{xenc_OAEPparams}
              }
          );
    };
}

# The key may differ per message, not the certificate
# Do not reinstate existing encrypters


my %encrs;
sub getEncrypter($%)
{   my ($class, $wss, %args) = @_;
    my $get_encr = $class->_get_encr($wss, \%args);

    sub {
        my ($h, $sec) = @_;
        my $id   = $h->{Id};
        $encrs{$id} ||= $get_encr->($h, $sec);
    };
}


sub getKey($%)
{   my ($class, $wss, %args) = @_;
    my $get_encr = $class->getEncrypter($wss, %args);

    sub {
        my ($h, $sec) = @_;
        my $encr = $get_encr->($h, $sec);

        # xenc_CipherReference not (yet) supported
        $h->{xenc_CipherData}{xenc_CipherValue}
            or error __x"cipher data not understood for {id}", id => $encr->id;
    };
}

sub builder($%)
{   my ($self, $wss, %args) = @_;

    my $keylink    = $self->keyInfo->builder($wss, %args);
    my $signer     = $self->signer;
    my $encr_type  = $self->type;
    my $key        = $self->key;
    my $seckeyw    = $wss->schema->writer('xenc:EncryptedKey');

    sub {
        my ($doc, $sec_node) = @_;
        my $ki = undef; # $keylink->($doc, $signer->privateKey, $sec_node)

        # see dump/encrkey/template
        my %data =
          ( xenc_EncryptionMethod => { Algorithm => $encr_type }
          , ds_KeyInfo => $ki
          , xenc_CipherData => { xenc_CipherValue => $signer->encrypt($key) }
          );

        my $node = $seckeyw->($doc, \%data);
#warn $node->toString(1);
        $sec_node->appendChild($node);
        $node;
    };
}

1;
