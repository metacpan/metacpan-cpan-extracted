package MMM::Mirror;

use strict;
use warnings;
use URI;
use POSIX qw(strftime);
use MMM::Host;

=head1 NAME

MMM::Mirror

=head1 DESCRIPTION

An object to retain per mirror information

=head1 METHODS

=head2 new

Create a MMM::Mirror object from information found in hash passed
as arguments.

    my $mirror MMM::Mirror->new( url => 'rsync://host/foo/' );

=cut

sub _rev {
    strftime( '%Y%m%d%H%M%S', gmtime(time) );
}

sub new {
    my ( $class, %infos ) = @_;
    $infos{url} or return;
    $infos{uri} ||= URI->new( $infos{url} );
    $infos{uri} && $infos{uri}->can('host') or return;
    my $path = $infos{uri}->path;
    $path =~ s://*:/:g;
    $infos{url} = sprintf( "%s://%s%s%s",
        $infos{uri}->scheme, lc( $infos{uri}->authority ),
        $path, ( $infos{uri}->query ? '?' . $infos{uri}->query : '' ) );
    $infos{host} = lc( $infos{uri}->host() );
    $infos{hostinfo} ||=
      MMM::Host->new( %infos, hostname => $infos{uri}->host );
    $infos{revision} ||= _rev();
    bless( {%infos}, $class );
}

=head2 url

Return the url of the mirror

=cut

sub url {
    my ($self) = @_;
    $self->{url};
}

=head2 host

Return the hostname of the mirror found in url

=cut

sub host {
    my ($self) = @_;
    return $self->{host};
}

=head2 level

Return the level of this mirror in mirrors hierarchy

=cut

sub level {
    my ($self) = @_;
    defined( $self->{level} ) ? $self->{level} : 3;
}

=head2 frequency

Period in minutes between sync performed by this mirror

=cut

sub frequency {
    my ($self) = @_;
    $self->{frequency} || 120;
}

=head2 source

Return the mirror source name from which this mirror is part of.

=cut

sub source {
    my ($self) = @_;
    $self->{source};
}

=head2 set_source($source)

Set the source name for this mirror.

=cut

sub set_source {
    my ( $self, $source ) = @_;
    $self->{source} = $source;
}

=head2 hostinfo

Return a MMM::Host object proper to the mirror if any

=cut

sub hostinfo {
    my ($self) = @_;
    return $self->{hostinfo};
}

=head2 get_geo

Load host geo info if any

=cut

sub get_geo {
    my ($self) = @_;
    if($self->{hostinfo}->get_geo()) {
        return 1;
    } else {
        return;
    }
}

=head2 random

Return a cached random value assigned to this mirror.

=cut

sub random {
    my ($self) = @_;
    $self->{random} ||= rand();
}

=head2 info

Return textual information about this mirror

=cut

sub info {
    my ($self) = @_;
    return
      sprintf( '%s (%d/%d)', $self->{url}, $self->level, $self->frequency );
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

=head2 same_mirror($mirror)

Compare this mirror with another and return 1 if both entries refer to same
mirror

=cut

sub same_mirror {
    my ( $self, $mirror ) = @_;
    if ( $self->host eq $mirror->host && $self->source eq $mirror->source ) {
        return 1;
    }
    return;
}

=head2 sync_mirror($mirror)

Get unknown values from $mirror if defined.

=cut

sub sync_mirror {
    my ( $self, $mirror ) = @_;
    foreach (qw(level frequency)) {
        if (
            ( !defined( $self->{$_} ) )
            || ( defined( $mirror->{$_} )
                && $mirror->revision > $self->revision )
          )
        {
            $self->{$_} = $mirror->{$_};
        }
    }
    if ( $self->{hostinfo} && $mirror->{hostinfo} ) {
        $self->{hostinfo}->sync_host( $mirror->{hostinfo} );
    }
    else {
        $self->{hostinfo} ||= $mirror->{hostinfo};
    }

    if ( $mirror->revision > $self->revision ) {
        $self->{revision} = $mirror->{revision};
    }
}

=head2 xml_output

Return a xml string describing this mirror.

See also <MMM::MirrorList::xml_output>

=cut

sub xml_output {
    my ($self) = @_;
    my $xml = "\t\t<mirror>\n";

    foreach (qw(url level frequency revision)) {
        if ( defined( $self->{$_} ) ) {
            $xml .= sprintf( "\t\t\t<%s>%s</%s>\n", $_, $self->{$_}, $_ );
        }
    }
    foreach (qw(password ssh)) {
        if ( $self->{$_} ) {
            $xml .= sprintf( "\t\t\t<%s>%s</%s>\n", $_, $self->{$_}, $_ );
        }
    }

    $xml .= "\t\t</mirror>\n";

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

