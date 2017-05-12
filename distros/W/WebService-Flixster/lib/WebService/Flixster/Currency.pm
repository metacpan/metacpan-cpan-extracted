# $Id: Currency.pm 7373 2012-04-09 18:00:33Z chris $

package WebService::Flixster::Currency;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Class::Accessor);

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Movie);

use HTML::Entities;
use Math::Currency;

sub _new {
    my $class = shift;
    my $ws = shift;
    my $amount = shift;
    my $currencySymbol = shift;

    if ($amount eq "") { return undef; }

    my $self = Math::Currency->new($amount);
    $self->format('CURRENCY_SYMBOL',decode_entities($currencySymbol));

    return $self;
}

1;
