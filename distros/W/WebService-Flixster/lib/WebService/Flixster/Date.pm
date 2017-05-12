# $Id: Date.pm 7373 2012-04-09 18:00:33Z chris $

package WebService::Flixster::Date;

use strict;
use warnings;

our $VERSION = '0.02';

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Movie);

use DateTime::Incomplete;


sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    if (exists $data->{'year'} && exists $data->{'month'} && exists $data->{'day'}) {
	return DateTime::Incomplete->new('year' => $data->{'year'}, 'month' => $data->{'month'}, 'day' => $data->{'day'});
    } elsif (scalar keys %$data == 0) {
	return DateTime::Incomplete->new();
	return undef;
    } else {
	croak "Unable to parse date";
    }
}

1;
