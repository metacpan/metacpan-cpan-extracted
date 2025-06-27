# Copyrights 2012-2025 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution XML-Compile-WSS-Signature.
# Meta-POD processed with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::WSS::SecToken::X509v3;{
our $VERSION = '2.04';
}

use base 'XML::Compile::WSS::SecToken';

use warnings;
use strict;

use Log::Report 'xml-compile-wss-sig';

use XML::Compile::WSS::Util qw/XTP10_X509v3/;

use Scalar::Util         qw/blessed/;
use Crypt::OpenSSL::X509 qw/FORMAT_ASN1 FORMAT_PEM/;


sub init($)
{   my ($self, $args) = @_;
    $args->{cert_file} and panic "removed in 1.07, use fromFile()";

    $args->{type} ||= XTP10_X509v3;

    my $cert;
    if($cert = $args->{certificate}) {}
    elsif(my $bin = $args->{binary})
         { $cert = Crypt::OpenSSL::X509->new_from_string($bin, FORMAT_ASN1) }
    else { error __x"certificate or binary required for X509 token" }

    blessed $cert && $cert->isa('Crypt::OpenSSL::X509')
        or error __x"X509 certificate object not supported (yet)";

    $args->{name}        ||= $cert->subject;
    $args->{fingerprint} ||= $cert->fingerprint_sha1;
    $self->SUPER::init($args);

    $self->{XCWSX_cert}    = $cert;
    $self;
}


sub fromFile($%)
{   my ($class, $fn, %args) = @_;

    # openssl's error message are a poor
    -f $fn or error __x"key file {fn} does not exist", fn => $fn;

    my $format = delete $args{format} || FORMAT_PEM;
    my $cert   = eval { Crypt::OpenSSL::X509->new_from_file($fn, $format) };
    if($@)
    {   my $err = $@;
        $err    =~ s/\. at.*//;
        error __x"in file {file}: {err}" , file => $fn, err => $err;
    }

    $class->new(certificate => $cert, %args);
}

#------------------------

sub certificate() {shift->{XCWSX_cert}}

#------------------------

sub asBinary() {shift->certificate->as_string(FORMAT_ASN1)}

1;
