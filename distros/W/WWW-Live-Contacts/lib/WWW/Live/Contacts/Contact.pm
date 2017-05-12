package WWW::Live::Contacts::Contact;

use strict;
use warnings;

use WWW::Live::Contacts::Email;
use WWW::Live::Contacts::PhoneNumber;
use WWW::Live::Contacts::Address;

our $VERSION = '1.0.1';

sub new {
  my ( $proto, %args ) = @_;
  my $class = ref $proto || $proto;
  my $self = bless {}, $class;
  return $self;
}

sub new_from_hashref {
  my ( $proto, $self ) = @_;
  my $class = ref $proto || $proto;
  bless $self, $class;
  
  if ( exists $self->{'Emails'} && exists $self->{'Emails'}->{'Email'} ) {
    for ( @{ $self->{'Emails'}->{'Email'} || [] } ) {
      bless $_, 'WWW::Live::Contacts::Email';
    }
  }
  
  if ( exists $self->{'Phones'} && exists $self->{'Phones'}->{'Phone'} ) {
    for ( @{ $self->{'Phones'}->{'Phone'} || [] } ) {
      bless $_, 'WWW::Live::Contacts::PhoneNumber';
    }
  }
  
  if ( exists $self->{'Locations'} && exists $self->{'Locations'}->{'Location'} ) {
    for ( @{ $self->{'Locations'}->{'Location'} || [] } ) {
      bless $_, 'WWW::Live::Contacts::Address';
    }
  }
  
  return $self;
}

sub id {
  my $self = shift;
  if ( @_ ) {
    $self->{'ID'} = shift;
  }
  return $self->{'ID'};
}

sub full_name {
  my ( $self, $sep ) = @_;
  if ( !defined $sep ) {
    $sep = ' ';
  }
  my $s = join $sep, grep { defined } $self->title, $self->first, $self->middle,
                                      $self->last, $self->suffix;
  return $s;
}

sub display_name {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Personal'}->{'DisplayName'} = shift;
  }
  return $self->{'Profiles'}->{'Personal'}->{'DisplayName'};
}

sub sort_name {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Personal'}->{'SortName'} = shift;
  }
  return $self->{'Profiles'}->{'Personal'}->{'SortName'};
}

sub nick_name {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Personal'}->{'NickName'} = shift;
  }
  return $self->{'Profiles'}->{'Personal'}->{'NickName'};
}

sub title {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Personal'}->{'NameTitle'} = shift;
  }
  return $self->{'Profiles'}->{'Personal'}->{'NameTitle'};
}

sub first {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Personal'}->{'FirstName'} = shift;
  }
  return $self->{'Profiles'}->{'Personal'}->{'FirstName'};
}

sub middle {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Personal'}->{'MiddleName'} = shift;
  }
  return $self->{'Profiles'}->{'Personal'}->{'MiddleName'};
}

sub last {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Personal'}->{'LastName'} = shift;
  }
  return $self->{'Profiles'}->{'Personal'}->{'LastName'};
}

sub suffix {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Personal'}->{'Suffix'} = shift;
  }
  return $self->{'Profiles'}->{'Personal'}->{'Suffix'};
}

sub birthday {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Personal'}->{'Birthdate'} = shift;
  }
  return $self->{'Profiles'}->{'Personal'}->{'Birthdate'};
}

sub anniversary {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Personal'}->{'Anniversary'} = shift;
  }
  return $self->{'Profiles'}->{'Personal'}->{'Anniversary'};
}

sub gender {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Personal'}->{'Gender'} = shift;
  }
  return $self->{'Profiles'}->{'Personal'}->{'Gender'};
}

sub timezone {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Personal'}->{'TimeZone'} = shift;
  }
  return $self->{'Profiles'}->{'Personal'}->{'TimeZone'};
}

sub spouse {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Personal'}->{'SpouseName'} = shift;
  }
  return $self->{'Profiles'}->{'Personal'}->{'SpouseName'};
}

sub job {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Professional'}->{'JobTitle'} = shift;
  }
  return $self->{'Profiles'}->{'Professional'}->{'JobTitle'};
}

sub profession {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Professional'}->{'Profession'} = shift;
  }
  return $self->{'Profiles'}->{'Professional'}->{'Profession'};
}

sub manager {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Professional'}->{'Manager'} = shift;
  }
  return $self->{'Profiles'}->{'Professional'}->{'Manager'};
}

sub assistant {
  my $self = shift;
  if ( @_ ) {
    $self->{'Profiles'}->{'Professional'}->{'Assistant'} = shift;
  }
  return $self->{'Profiles'}->{'Professional'}->{'Assistant'};
}

sub emails {
  my $self = shift;
  if ( @_ ) {
    $self->{'Emails'} = { 'Email' => \@_ };
  }
  my @arr = sort _sort_by_default @{ $self->{'Emails'}->{'Email'} || [] };
  return wantarray ? @arr : \@arr;
}

sub personal_email {
  my $self = shift;
  my @arr = grep { $_->type eq 'Personal' } @{ $self->emails };
  return $arr[0];
}

sub business_email {
  my $self = shift;
  my @arr = grep { $_->type eq 'Business' } @{ $self->emails };
  return $arr[0];
}

sub add_email {
  my $self = shift;
  $self->{'Emails'}->{'Email'} ||= [];
  push @{ $self->{'Emails'}->{'Email'} }, @_;
  return;
}

sub phones {
  my $self = shift;
  if ( @_ ) {
    $self->{'Phones'} = { 'Phone' => \@_ };
  }
  my @arr = sort _sort_by_default @{ $self->{'Phones'}->{'Phone'} || [] };
  return wantarray ? @arr : \@arr;
}

sub personal_phone {
  my $self = shift;
  my @arr = grep { $_->type eq 'Personal' } @{ $self->phones };
  return $arr[0];
}

sub personal_mobile {
  my $self = shift;
  my @arr = grep { $_->type eq 'Mobile' } @{ $self->phones };
  return $arr[0];
}

sub personal_fax {
  my $self = shift;
  my @arr = grep { $_->type eq 'Fax' } @{ $self->phones };
  return $arr[0];
}

sub business_phone {
  my $self = shift;
  my @arr = grep { $_->type eq 'Business' } @{ $self->phones };
  return $arr[0];
}

sub business_mobile {
  my $self = shift;
  my @arr = grep { $_->type eq 'BusinessMobile' } @{ $self->phones };
  return $arr[0];
}

sub business_fax {
  my $self = shift;
  my @arr = grep { $_->type eq 'BusinessFax' } @{ $self->phones };
  return $arr[0];
}

sub add_phone {
  my $self = shift;
  $self->{'Phones'}->{'Phone'} ||= [];
  push @{ $self->{'Phones'}->{'Phone'} }, @_;
  return;
}

sub addresses {
  my $self = shift;
  if ( @_ ) {
    $self->{'Locations'} = { 'Location' => \@_ };
  }
  my @arr = sort _sort_by_default @{ $self->{'Locations'}->{'Location'} || [] };
  return wantarray ? @arr : \@arr;
}

sub personal_address {
  my $self = shift;
  my @arr = grep { $_->type eq 'Personal' } @{ $self->addresses };
  return $arr[0];
}

sub business_address {
  my $self = shift;
  my @arr = grep { $_->type eq 'Business' } @{ $self->addresses };
  return $arr[0];
}

sub add_address {
  my $self = shift;
  $self->{'Locations'}->{'Location'} ||= [];
  push @{ $self->{'Locations'}->{'Location'} }, @_;
  return;
}

sub live_id {
  my $self = shift;
  if ( @_ ) {
    $self->{'WindowsLiveID'} = shift;
  }
  return $self->{'WindowsLiveID'};
}

sub last_modified {
  my $self = shift;
  return $self->{'LastChanged'};
}

sub _sort_by_default {
  if ( $a->is_default ) {
    return $b->is_default ? 0 : -1;
  } elsif ( $b->is_default ) {
    return 1;
  }
  return 0;
}

sub createable_copy {
  my $self = shift;
  my $copy = WWW::Live::Contacts::Contact->new();
  for my $key (qw(title first middle last suffix nick_name birthday
                  anniversary gender timezone spouse job profession manager
                  assistant)) {
    $copy->$key( $self->$key );
  }
  return $copy;
}

sub updateable_copy {
  return createable_copy(@_);
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

WWW::Live::Contacts::Contact

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
