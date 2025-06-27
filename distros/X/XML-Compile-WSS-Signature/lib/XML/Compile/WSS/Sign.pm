# Copyrights 2012-2025 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution XML-Compile-WSS-Signature.
# Meta-POD processed with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::WSS::Sign;{
our $VERSION = '2.04';
}


use warnings;
use strict;

use Log::Report 'xml-compile-wss-sig';

use XML::Compile::WSS::Util   qw/:wss11 :dsig/;
use Scalar::Util              qw/blessed/;

my ($signs, $sigmns) = (DSIG_NS, DSIG_MORE_NS);


sub new(@)
{   my $class = shift;
    my $args  = @_==1 ? shift : {@_};

    $args->{sign_method} ||= delete $args->{type};      # pre 2.00
    my $algo = $args->{sign_method} ||= DSIG_RSA_SHA1;

    if($class eq __PACKAGE__)
    {   if($algo =~ qr/^(?:\Q$signs\E|\Q$sigmns\E)([a-z0-9]+)\-([a-z0-9]+)$/)
        {   my $algo = uc $1;;
            $args->{hashing} ||= uc $2;
            $class .= '::'.$algo;
        }
        else
        {    error __x"unsupported sign algorithm `{algo}'", algo => $algo;
        }
        eval "require $class"; panic $@ if $@;
    }

    (bless {}, $class)->init($args);
}

sub init($)
{   my ($self, $args) = @_;
    $self->{XCWS_sign_method} = $args->{sign_method};
    $self;
}


sub fromConfig($)
{   my $class = shift;
    $class->new(@_==1 ? %{$_[0]} : @_);
}

#-----------------

sub signMethod() {shift->{XCWS_sign_method}}

#-----------------

#-----------------

1;
