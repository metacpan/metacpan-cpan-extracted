package WWW::Live::Auth::Offer;

use strict;
use warnings;

use WWW::Live::Auth::Utils;
use Carp;

sub new {
  my ( $proto, %args ) = @_;
  my $class = ref $proto || $proto;
  my $self = bless {
    'offer'    => $args{'offer'},
    'action'   => $args{'action'},
    'expires'  => $args{'expires'}
  }, $class;
  $self->_process;
  return $self;
}

sub offer {
  my ( $self ) = @_;
  return $self->{'offer'};
}

sub action {
  my ( $self ) = @_;
  return $self->{'action'};
}

sub expires {
  my ( $self ) = @_;
  return $self->{'expires'};
}

sub as_string {
  my ( $self ) = @_;
  return $self->offer . '.' . $self->action;
}

sub _process {
  my ( $self ) = @_;
  if ( !$self->{'action'} ) {
    my ($offer, $action, $expires) = split /[\.:]/, $self->{'offer'};
    $self->{'offer'}   = $offer  || croak('Could not parse offer');
    $self->{'action'}  = $action || croak('Could not parse offer action');
    $self->{'expires'}; # optional
  }
}

1;
__END__

=head1 NAME

WWW::Live::Auth::Offer

=head1 VERSION

1.0.0

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