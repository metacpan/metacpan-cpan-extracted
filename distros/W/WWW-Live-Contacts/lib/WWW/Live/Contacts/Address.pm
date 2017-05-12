package WWW::Live::Contacts::Address;

use strict;
use warnings;

our $VERSION = '1.0.1';

sub new {
  my ( $proto, $type ) = @_;
  my $class = ref $proto || $proto;
  my $self = bless {}, $class;
  $self->{'LocationType'} = $type if $type;
  return $self;
}

sub full {
  my ( $self, $sep ) = @_;
  if ( !defined $sep ) {
    $sep = "\n";
  }
  my $s = join $sep, grep { defined } $self->office, $self->department,
                                      $self->company, $self->street1,
                                      $self->street2, $self->city1,
                                      $self->city2, $self->state, $self->zip,
                                      $self->country;
  return $s;
}

sub id {
  my $self = shift;
  if ( @_ ) {
    $self->{'ID'} = shift;
  }
  return $self->{'ID'};
}

sub type {
  my $self = shift;
  if ( @_ ) {
    $self->{'LocationType'} = shift;
  }
  return $self->{'LocationType'};
}

sub office {
  my $self = shift;
  if ( @_ ) {
    $self->{'Office'} = shift;
  }
  return $self->{'Office'};
}

sub department {
  my $self = shift;
  if ( @_ ) {
    $self->{'Department'} = shift;
  }
  return $self->{'Department'};
}

sub company {
  my $self = shift;
  if ( @_ ) {
    $self->{'CompanyName'} = shift;
  }
  return $self->{'CompanyName'};
}

sub street1 {
  my $self = shift;
  if ( @_ ) {
    $self->{'StreetLine'} = shift;
  }
  return $self->{'StreetLine'};
}

sub street2 {
  my $self = shift;
  if ( @_ ) {
    $self->{'StreetLine2'} = shift;
  }
  return $self->{'StreetLine2'};
}

sub city1 {
  my $self = shift;
  if ( @_ ) {
    $self->{'PrimaryCity'} = shift;
  }
  return $self->{'PrimaryCity'};
}

sub city2 {
  my $self = shift;
  if ( @_ ) {
    $self->{'SecondaryCity'} = shift;
  }
  return $self->{'SecondaryCity'};
}

sub state {
  my $self = shift;
  if ( @_ ) {
    $self->{'Subdivision'} = shift;
  }
  return $self->{'Subdivision'};
}

sub province {
  return &state(@_);
}

sub zip {
  my $self = shift;
  if ( @_ ) {
    $self->{'PostalCode'} = shift;
  }
  return $self->{'PostalCode'};
}

sub postcode {
  return zip(@_);
}

sub country {
  my $self = shift;
  if ( @_ ) {
    $self->{'CountryRegion'} = shift;
  }
  return $self->{'CountryRegion'};
}

sub latitude {
  my $self = shift;
  if ( @_ ) {
    $self->{'Latitude'} = shift;
  }
  return $self->{'Latitude'};
}

sub longitude {
  my $self = shift;
  if ( @_ ) {
    $self->{'Longitude'} = shift;
  }
  return $self->{'Longitude'};
}

sub is_default {
  my $self = shift;
  if ( @_ ) {
    my $txt = ($_[0] && $_[0] =~ m/1|true/i) ? 'true' : 'false';
    $self->{'IsDefault'} = $txt;
  }
  return $self->{'IsDefault'} eq 'true' ? 1 : 0;
}

sub updateable_copy {
  my $self = shift;
  my $copy = WWW::Live::Contacts::Address->new();
  for my $key (qw(office department company street1 street2 city1 city2
                  state zip country latitude longitude is_default)) {
    $copy->$key( $self->$key );
  }
  return $copy;
}

sub createable_copy {
  my $self = shift;
  my $copy = WWW::Live::Contacts::Address->new();
  for my $key (qw(type office department company street1 street2 city1 city2
                  state zip country latitude longitude is_default)) {
    $copy->$key( $self->$key );
  }
  return $copy;
}

sub mark_deleted {
  my ( $self, $mark ) = @_;
  if (!defined $mark) {
    $mark = 1;
  }
  $self->{'_deleted'} = $mark;
  return;
}

sub is_deleted {
  my $self = shift;
  return $self->{'_deleted'};
}

1;
__END__

=head1 NAME

WWW::Live::Contacts::Address

=head1 VERSION

1.0.1

=head1 AUTHOR

Andrew M. Jenkinson <jenkinson@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2008-2011 Andrew M. Jenkinson.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
