package WWW::Live::Contacts::Collection;

use strict;
use warnings;

our $VERSION = '1.0.1';

use HTTP::Date qw(str2time time2isoz);

sub new {
  my ( $proto, %args ) = @_;
  my $class = ref $proto || $proto;
  my $self = bless {
    'entries'  => $args{'entries'},
    'response' => $args{'response'},
  }, $class;
  return $self;
}

sub entries {
  my $self = shift;
  return wantarray ? @{ $self->{'entries'} } : $self->{'entries'};
}

sub is_modified {
  my $self = shift;
  return $self->{'response'}->code != 304;
}

sub last_modified {
  my $self = shift;
  if (! exists $self->{'last_modified'} ) {
    my $modified = $self->{'response'}->header('Last-Modified');
    if ( $modified ) {
      $modified = time2isoz( str2time( $modified ) );
    }
    $self->{'last_modified'} = $modified;
  }
  return $self->{'last_modified'};
}

1;
__END__

=head1 NAME

WWW::Live::Contacts::Collection

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
