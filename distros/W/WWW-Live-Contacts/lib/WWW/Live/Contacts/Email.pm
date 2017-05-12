package WWW::Live::Contacts::Email;

use strict;
use warnings;

our $VERSION = '1.0.1';

sub new {
  my ( $proto, $type ) = @_;
  my $class = ref $proto || $proto;
  my $self = bless {}, $class;
  $self->{'EmailType'} = $type if $type;
  return $self;
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
    $self->{'EmailType'} = shift;
  }
  return $self->{'EmailType'};
}

sub address {
  my $self = shift;
  if ( @_ ) {
    $self->{'Address'} = shift;
  }
  return $self->{'Address'};
}

sub is_default {
  my $self = shift;
  if ( @_ ) {
    my $txt = ($_[0] && $_[0] =~ m/1|true/i) ? 'true' : 'false';
    $self->{'IsDefault'} = $txt;
  }
  return $self->{'IsDefault'} eq 'true' ? 1 : 0;
}

sub is_IM {
  my $self = shift;
  if ( @_ ) {
    my $txt = ($_[0] && $_[0] =~ m/1|true/i) ? 'true' : 'false';
    $self->{'IsIMEnabled'} = $txt;
  }
  return $self->{'IsIMEnabled'} eq 'true' ? 1 : 0;
}

sub createable_copy {
  my $self = shift;
  my $copy = WWW::Live::Contacts::Email->new();
  for my $key (qw(type address is_default)) {
    $copy->$key( $self->$key );
  }
  return $copy;
}

sub updateable_copy {
  my $self = shift;
  my $copy = WWW::Live::Contacts::Email->new();
  for my $key (qw(address is_default)) {
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

WWW::Live::Contacts::Email

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
