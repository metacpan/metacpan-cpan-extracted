package MMM::Host;

use strict;
use warnings;
use URI;
use POSIX qw(strftime);
use Math::Trig;
use Net::DNS;

=head1 NAME

MMM::Host

=head1 DESCRIPTION

An object to retain host information

=head1 METHODS

=head2 new

Create a MMM::Host object from information found in hash passed
as arguments.

    my $mirror MMM::Mirror->new( host => 'host.domain' );

=cut

sub _rev {
    strftime( '%Y%m%d%H%M%S', gmtime(time) );
}

sub new {
    my ( $class, %infos ) = @_;
    $infos{hostname} or return;
    $infos{hostname} = lc( $infos{hostname} );
    $infos{revision} ||= _rev();
    if ( $infos{geolocation} ) {
        ( $infos{longitude}, $infos{latitude} ) =
          $infos{geolocation} =~ /([\d\.]+),([\d\.]+)/;
    }
    bless( {%infos}, $class );
}

=head2 hostname

Return the hostname of the host

=cut

sub hostname {
    my ($self) = @_;
    $self->{hostname};
}

=head2 revision

Return the revision of the entry. The revision is an id to identify if an
entry is newer than another for same mirror.

=cut

sub revision {
    my ($self) = @_;
    $self->{revision};
}

=head2 refresh_revision

Reset revision to current timestamp

=cut

sub refresh_revision {
    my ($self) = @_;
    $self->{revision} = _rev();
}

=head2 geo

Return the latitude and the longitude for this host

=cut

sub geo {
    return ( $_[0]->{latitude}, $_[0]->{longitude} );
}

=head2 get_geo

Try to use various method to find latitude and longitude
and return them

=cut

sub get_geo {
    if ( !$_[0]->{get_geo_done} ) {
        if (
            !( defined( $_[0]->{latitude} ) && defined( $_[0]->{longitude} ) ) )
        {
            $_[0]->get_dnsloc || $_[0]->get_hostiploc;
        }
        $_[0]->{get_geo_done} = 1;
    }
    return $_[0]->geo;
}

=head2 get_hostiploc

Get and set information from hostip.info website

=cut

sub get_hostiploc {
    my ($self) = @_;

    my ( $name, $aliases, $addrtype, $length, $paddr, @addrs ) =
      gethostbyname( $self->hostname )
      or return;
    my $addr = join( '.', unpack( 'C4', $paddr ) );
    use WWW::HostipInfo;
    my $hostip = new WWW::HostipInfo;
    my $info = $hostip->get_info($addr) or return;
    $self->{latitude} = $info->latitude
      if ( defined( $info->latitude ) );
    $self->{longitude} = $info->longitude
      if ( defined( $info->longitude ) );
    $self->{country} = $info->country_name
      if ( defined( $info->country_name ) );
    $self->{city} = $info->city if ( defined( $info->city ) );
    $self->refresh_revision;

    1;
}

=head2 get_dnsloc

Try to find geolocalisation from DNS LOC record

=cut

sub get_dnsloc {
    my ($self) = @_;
    return;
    my @partname = split( /\./, $self->hostname );
    my $dnsq = Net::DNS::Resolver->new();
    do {
        my $answer = $dnsq->query( join( '.', @partname ), 'LOC' ) or return;
        foreach my $ans ( $answer->answer ) {
            if ( $ans->type eq 'LOC' ) {
                ( $self->{latitude}, $self->{longitude} ) = $ans->latlon();
                $self->refresh_revision;
                return 1;
            }
        }
    } while ( shift(@partname) );

    return;
}

=head2 set_geo($latitude, $longitude)

Set the geolocalisation for this host

=cut

sub set_geo {
    my ( $self, $lat, $lon ) = @_;
    ( $self->{latitude}, $self->{longitude} ) = ( $lat, $lon );
}

=head2 distance( $host )

Calcule the distance (angle in degrees) to another host

=cut

sub distance {
    my ( $self, $host ) = @_;
    grep { !defined($_) } ($self->geo, $host->geo) and return;
    my ( $lat1, $lon1 ) = map { deg2rad($_) } $self->geo;
    my ( $lat2, $lon2 ) = map { deg2rad($_) } $host->geo;
    rad2deg(
        acos(
            sin($lat1) * sin($lat2) + cos($lat1) * cos($lat2) *
              cos( $lon1 - $lon2 )
        )
    );
}

=head2 same_host($host)

Compare two host entry and return true if they identify the same
computer

=cut

sub same_host {
    my ( $self, $host ) = @_;
    if ( $self->hostname eq $host->hostname ) {
        return 1;
    }
    return;
}

=head2 sync_host($host)

Get unknown values from $host if defined.

=cut

sub sync_host {
    my ( $self, $host ) = @_;
    foreach (qw(city continent country latitude longiture)) {
        if (
            ( !defined( $self->{$_} ) )
            || ( defined( $host->{$_} )
                && $host->revision > $self->revision )
          )
        {
            $self->{$_} = $host->{$_};
        }
    }

    if ( $host->revision > $self->revision ) {
        $self->{revision} = $host->{revision};
    }
}

=head2 xml_output

Return a xml string describing this mirror.

See also <MMM::MirrorList::xml_output>

=cut

sub xml_output {
    my ($self) = @_;
    my $xml = "\t\t<host>\n";

    foreach (qw(hostname continent country city revision)) {
        if ( $self->{$_} ) {
            $xml .= sprintf( "\t\t\t<%s>%s</%s>\n", $_, $self->{$_}, $_ );
        }
    }

    if ( defined( $self->{latitude} ) && defined( $self->{longitude} ) ) {
        $xml .=
"\t\t\t<geolocation>$self->{longitude},$self->{latitude}</geolocation>\n";
    }

    $xml .= "\t\t</host>\n";

    $xml;
}

1;

=head1 AUTHOR

Olivier Thauvin <nanardon@nanardon.zarb.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Olivier Thauvin

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=cut

