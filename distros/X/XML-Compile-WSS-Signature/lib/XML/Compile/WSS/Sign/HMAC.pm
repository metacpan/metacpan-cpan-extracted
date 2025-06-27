# Copyrights 2012-2025 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution XML-Compile-WSS-Signature.
# Meta-POD processed with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::WSS::Sign::HMAC;{
our $VERSION = '2.04';
}

use base 'XML::Compile::WSS::Sign';

use warnings;
use strict;

use Log::Report 'xml-compile-wss-sig';

use Digest::HMAC_SHA1   ();
use File::Slurp         qw/read_file/;
use Scalar::Util        qw/blessed/;


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);

    my $key = $args->{key} or error __x"HMAC signer needs a key";
    $key    = $key->key if blessed $key && $key->can('key');
    $self->{XCWSH_key} = $key;

    my $h = $args->{hashing};
    $h eq 'SHA1'
        or error __x"unsupported HMAC hashing '{hash}'", hash => $h;

    $self;
}

#-----------------

sub key() {shift->{XCWSH_key}}

#-----------------

sub builder(@)
{   my ($self) = @_;
    my $key    = $self->key;

    # Digest object generally cannot be reused.
    sub {
        Digest::HMAC_SHA1->new($key)->add($_[0])->digest;
    };
}

sub checker()
{   my $self = shift;
    my $key  = $self->key;

    sub {  # ($text, $sigature)
        Digest::HMAC_SHA1->new($key)->add($_[0])->digest eq $_[1];
    };
}

#-----------------

1;
