# Copyrights 2012-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::WSS::Sign::HMAC;
use vars '$VERSION';
$VERSION = '2.02';

use base 'XML::Compile::WSS::Sign';

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

sub checker($$)
{   my ($self) = @_;
    my $key    = $self->key;

    sub {  # ($text, $sigature)
        Digest::HMAC_SHA1->new($key)->add($_[0])->digest eq $_[1];
    };
}

#-----------------

1;
