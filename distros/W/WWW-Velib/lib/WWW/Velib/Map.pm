# Map.pm - WWW::Velib::Map
#
# Copyright (c) 2007 David Landgren
# All rights reserved

package WWW::Velib::Map;
use strict;

use LWP::Simple 'get';
use XML::Twig;
use WWW::Velib::Station;

use vars '$VERSION';
$VERSION = '0.02';

use constant DETAILS => 'http://www.velib.paris.fr/service/carto';

sub new {
    my $class   = shift;
    my $self    = {};

    my %arg = @_;
    if ($arg{file}) {
        open IN, "< $arg{file}" or do {
            require Carp;
            Carp::croak("cannot open $arg{file} for input: $!\n");
        };
        chomp(my $header = <IN>);
        if ($header eq '# version 1.0 WWW::Velib::Map data cache') {
            my $self = bless {
                html    => '',
                station => _load_v1(\*IN),
            };
            close IN;
            return $self;
        }
        else {
            require Carp;
            Carp::croak("don't know how to handle  $arg{file}: version mis-match\n");
        }
    }
    else {
        my $station;
        my $twig = XML::Twig->new(
            twig_handlers => {
                marker => sub {
                    my $att = $_->{att};
                    $station->{$att->{number}} = WWW::Velib::Station->make(
                        map {$att->{$_}}
                            qw(number name address fullAddress lat lng open)
                    );
                },
            }
        );
        if (my $content = get(DETAILS)) {
            $twig->parse($content);
            $self->{_html} = $content;
            $self->{station} = $station;
        }
        else {
            $self->{_html} = '';
            $self->{station} = {};
        }
    }
    return bless $self, $class;
}

sub save {
    my $self = shift;
    my $file = shift or do {
        require Carp;
        Carp::croak("no filename given for save()\n");
    };
    open OUT, "> $file" or do {
        require Carp;
        Carp::croak("cannot open $file for output: $!\n");
    };
    print OUT "# version 1.0 WWW::Velib::Map data cache\n";
    my $station = $self->station;
    for my $s (keys %$station) {
        print OUT join("\t",
            @{$station->{$s}}{qw(number open lat lng theta phi name address fullAddress)}
        ), "\n";
    }
    close OUT;
}

sub _load_v1 {
    local *I = shift;
    my $s;
    while (my $rec = <I>) {
        chomp $rec;
        my @rec = split /\t/, $rec;
        $s->{$rec[0]} = WWW::Velib::Station->load_v1(@rec);
    }
    return $s;
}

sub station {
    return $_[0]->{station};
}

sub search {
    my $self = shift;
    my %arg  = @_;
    $arg{n}  = 1 unless exists $arg{n};

    my $all    = $self->station;
    my $origin = $all->{$arg{station}};
    return () unless $origin;

    my %distance;
    for my $snum (keys %$all) {
        my $station = $all->{$snum};
        my $dist = $station->distance_from($origin);
        push @{$distance{$dist}}, {dist => $dist, station => $station}
            if not exists $arg{distance}
                or (exists $arg{distance} and $dist <= $arg{distance});
    }

    my @result;
    STATION:
    for my $dist (sort { $a <=> $b } keys %distance) {
        for my $s (sort {$a->{station}->number <=> $b->{station}->number} @{$distance{$dist}}) {
            push @result, $s->{station};
            if (not exists $arg{distance}) {
                last STATION if scalar @result == $arg{n};
            }
        }
    }

    if ($arg{status}) {
        $_->refresh for @result;
    }
    return @result;
}

'The Lusty Decadent Delights of Imperial Pompeii';
__END__

=head1 NAME

WWW::Velib::Map Process the Velib' map information

=head1 VERSION

This document describes version 0.02 of WWW::Velib::Map, released
2007-11-13.

=head1 SYNOPSIS

  use WWW::Velib::Map;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item new

Download a the Velib' map information from the web. The information
may be cached locally (see the C<save> method). A previously saved
map file may be loaded by specifying it with the C<file> attribute.

  my $map = WWW::Velib::Map->new; # download from the web

  my $m2  = WWW::Velib::Map->new(file => 'map.data'); # use local file

In the latter example, the method will croak if the file does not
exist or cannot be decoded.

=item save

Save the downloaded map information into a local file. The method
will croak if the file cannot be written.

  $map->save('map.data');

=item search

Search the station list for the stations that match some criteria.
Returns an array of C<WWW::Velib::Station> objects.

Currently, one may search for stations near a given station, limited
by either number or distance (in metres). The stations may be queried
for current details (availabale bikes and slots).

Search by distance (returns all the stations within n metres):

  my @station = $m->search( station => 1234, distance => 600 );

To obtain the status of each station, use the C<status> attribute:

  my @station = $m->search(
	station  => 2345,
	distance => 500,
	status   => 1,
  );

Search by number (returns the n closest stations):

  my @station = $m->search( station => 1234, n => 4 );

I<Nota bene>: the official map contains many errors. Alternate maps
of better quality exist and will be used in a future version.

=item station

Returns a reference to a hash of all the stations in the map,
keyed by station number.

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

