package WebService::Strava::Club;

use v5.010;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use Carp qw(croak);
use Scalar::Util::Reftype;
use Data::Dumper;
use Method::Signatures 20140224;
use Moo;
use namespace::clean;

# ABSTRACT: A Strava Club Object

our $VERSION = '0.06'; # VERSION: Generated by DZP::OurPkg:Version


# Validation functions

my $Ref = sub {
  croak "auth isn't a 'WebService::Strava::Auth' object!" unless reftype( $_[0] )->class eq "WebService::Strava::Auth";
};

my $Bool = sub {
  croak "$_[0] must be 0|1" unless $_[0] =~ /^[01]$/;
};

my $Num = sub {
  croak "$_[0] isn't a valid id" unless looks_like_number $_[0];
};

# Debugging hooks in case things go weird. (Thanks @pjf)

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;
  
  if ($WebService::Strava::DEBUG) {
    warn "Building task with:\n";
    warn Dumper(\@_), "\n";
  }
  
  return $class->$orig(@_);
};

# Authentication Object
has 'auth'            => ( is => 'ro', required => 1, isa => $Ref );

# Defaults + Required
has 'id'                      => ( is => 'ro', required => 1, isa => $Num);
has '_build'                  => ( is => 'ro', default => sub { 1 }, isa => $Bool );

has 'profile'         => ( is => 'ro', lazy => 1, builder => '_build_club' ); 
has 'name'            => ( is => 'ro', lazy => 1, builder => '_build_club' );
has 'state'           => ( is => 'ro', lazy => 1, builder => '_build_club' );
has 'city'            => ( is => 'ro', lazy => 1, builder => '_build_club' );
has 'sport_type'      => ( is => 'ro', lazy => 1, builder => '_build_club' );
has 'description'     => ( is => 'ro', lazy => 1, builder => '_build_club' );
has 'member_count'    => ( is => 'ro', lazy => 1, builder => '_build_club' );
has 'country'         => ( is => 'ro', lazy => 1, builder => '_build_club' );
has 'club_type'       => ( is => 'ro', lazy => 1, builder => '_build_club' );

sub BUILD {
  my $self = shift;

  if ($self->{_build}) {
    $self->_build_club();
  }
  return;
}

method _build_club() {
  my $club = $self->auth->get_api("/clubs/$self->{id}");
 
  foreach my $key (keys %{ $club }) {
    $self->{$key} = $club->{$key};
  }

  return;
}


method retrieve() {
  $self->_build_club();
}


method list_members(:$members = 25, :$page = 1) {
  # TODO: Handle pagination better use #4's solution when found.
  my $data = $self->auth->get_api("/clubs/$self->{id}/members?per_page=$members&page=$page");
  my $index = 0;
  foreach my $member (@{$data}) {
    @{$data}[$index] = WebService::Strava::Athlete->new(id => $member->{id}, auth => $self->auth, _build => 0);
    $index++;
  }
  return $data;
};


method list_activities(:$activities = 25, :$page = 1) {
  # TODO: Handle pagination better use #4's solution when found.
  my $data = $self->auth->get_api("/clubs/$self->{id}/activities?per_page=$activities&page=$page");
  my $index = 0;
  foreach my $activity (@{$data}) {
    @{$data}[$index] = WebService::Strava::Athlete::Activity->new(id => $activity->{id}, auth => $self->auth, _build => 0);
    $index++;
  }
  return $data;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Strava::Club - A Strava Club Object

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  This will return a Club Gear Object.

=head1 DESCRIPTION

  An Athlete can be a member of one or many clubs.

=head1 METHODS

=head2 retrieve()

  $club->retrieve();

When a Club object is lazy loaded, you can call retrieve it by calling
this method.

=head2 list_members

  $club->list_members([page => 2], [activities => 100]);

Returns an arrayRef of L<WebService::Strava::Athlete> objects for the Club. Takes 2 optional
parameters of 'page' and 'members' (per page).

The results are paginated and a maximum of 200 results can be returned
per page.

=head2 list_activities

  $club->list_activities([page => 2], [activities => 100]);

Returns an arrayRef of L<WebService::Strava::Athlete::Activity> objects for the club. Takes 2 optional
parameters of 'page' and 'activities' (per page).

The results are paginated and a maximum of 200 results can be returned
per page.

=head1 AUTHOR

Leon Wright < techman@cpan.org >

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Leon Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
