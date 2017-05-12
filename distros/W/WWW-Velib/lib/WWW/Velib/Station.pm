# Station.pm - WWW::Velib::Station
#
# Copyright (c) 2007 David Landgren
# All rights reserved

package WWW::Velib::Station;
use strict;

use LWP::Simple;
use Math::Trig qw(deg2rad great_circle_distance);
use XML::Twig;

use vars '$VERSION';
$VERSION = '0.01';

use constant DETAILS => 'http://www.velib.paris.fr/service/stationdetails/';

sub new {
    my $class = shift;
    my $self  = bless {number => shift}, $class;
    $self->refresh;
    return $self;
}

sub make {
    my $class = shift;
    my $self  = {};
    @{$self}{qw(number name address fullAddress lat lng open)} = @_;
    @{$self}{qw(theta phi)} = _theta_phi(@{$self}{qw(lat lng)});
    return bless $self, $class;
}

sub _theta_phi { deg2rad($_[0]), deg2rad(90 - $_[1]) }

sub load_v1 {
    my $class = shift;
    my $self  = {};
    @{$self}{qw(number open lat lng theta phi name address fullAddress)} = @_;
    return bless $self, $class;
}

sub coords {
    my $self = shift;
    return @{$self}{qw(theta phi)};
}

sub distance_from {
    my $self  = shift;
    my $there = shift;
    my $scale = shift || 5;
    $self->{dist} = $scale * sprintf( '%0.0f',
            great_circle_distance( $there->coords, $self->coords, 6378249)
        / $scale);
    return $self->{dist};
}

sub refresh {
    my $self = shift;
    if (my $content = get(DETAILS . $self->number)) {
        $self->{_html} = $content;
        my $twig = XML::Twig->new(
            twig_handlers => {
                available => sub {$self->{available} = $_[1]->text},
                free      => sub {$self->{free     } = $_[1]->text},
                total     => sub {$self->{total    } = $_[1]->text},
                ticket    => sub {$self->{ticket   } = $_[1]->text},
            },
        );
        $twig->parse($content);
    }
    else {
        @{$self}{qw(available free total ticket)} = (-1) x 4;
    };
    return $self;
}

sub number       {return $_[0]->{number     }}
sub open         {return $_[0]->{open       }}
sub name         {return $_[0]->{name       }}
sub latitude     {return $_[0]->{lat        }}
sub longitude    {return $_[0]->{lng        }}
sub address      {return $_[0]->{address    }}
sub full_address {return $_[0]->{fullAddress}}
sub available    {return $_[0]->{available  }}
sub free         {return $_[0]->{free       }}
sub total        {return $_[0]->{total      }}
sub disabled  {
    return $_[0]->total == -1
        ? -1
        : $_[0]->total - ($_[0]->free + $_[0]->available)
    ;
}

'The Lusty Decadent Delights of Imperial Pompeii';
__END__

=head1 NAME

WWW::Velib::Station - Details of Velib' station bicycle and parking availability

=head1 VERSION

This document describes version 0.01 of WWW::Velib::Station, released
2007-11-13.

=head1 SYNOPSIS

  use WWW::Velib::Station;

  my $s = WWW::Velib::Station->new(2007);
  print $s->available, $/; # hopefully a positive number

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item new

Create a WWW::Velib::Station object. A single input parameter
is given, representing the station number.

=item make

Create a WWW::Velib::Station object, based on the geographic
information provided by WWW::Velib::Map. Not expected to be called
from client code.

=item load_v1

Create a WWW::Velib::Station object, based on locally-cached contents
of the geographic information provided by WWW::Velib::Map. Not
expected to be called from client code.

=item coords

Returns a two-element list containing the theta and phi coordinates
of the station.

=item distance_from

Returns the distance in metres of a station from the current station.
The result is rounded by default to the nearest 5 metres.

    my $depart; # two WWW::Velib::Station objects
    my $arrive;
    my $distance = $depart->distance_from($arrive);

To round off to another interval, specify the rounding as a second
parameter:

    my $dist_km = $depart->distance_from($arrive, 1000);

=item number

Returns the number (indentifier) of the station.

=item open

Indicates whether the station is open for business or not.

=item name

Returns the name of the station.

=item latitude

Returns the station's latitude, in degrees.

=item longitude

Returns the station's longitude, in degrees.

=item address

Returns the short address of the station.

=item full_address

Returns the full address of the station.

=item refresh

If a station has been built by loading a map, the following details
will not be loaded (it takes time to fetch a couple of thousand web
pages). This method will fetch the current status of the station
(bikes available, slots available). On a long-running process, may
be called repeatedly (at a suitable interval) to update the status.

=item available

Returns the number of bicycles available at the specified station.

=item total

Returns the total number of bicycle posts installed at the station.

=item free

Returns the number of bicycle posts that are able to receive a
bicycle.

=item disabled

Returns the number of bicycle posts that are locked or have a
locked bicycle attached.

=back

=head1 AUTHOR

David Landgren, copyright (C) 2007. All rights reserved.

http://www.landgren.net/perl/

If you (find a) use this module, I'd love to hear about it. If you
want to be informed of updates, send me a note. You know my first
name, you know my domain. Can you guess my e-mail address?

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

