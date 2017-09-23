
package WWW::Kickstarter::Data::Location;

use strict;
use warnings;
no autovivification;


use WWW::Kickstarter::Data  qw( );
use WWW::Kickstarter::Error qw( my_croak );


our @ISA = 'WWW::Kickstarter::Data';


sub id         { $_[0]{id} }
sub slug       { $_[0]{slug} }
sub type       { $_[0]{type} }
sub country    { $_[0]{country} }
sub state      { $_[0]{state} }
sub name       { $_[0]{name} }
sub full_name  { $_[0]{displayable_name} }
sub short_name { $_[0]{short_name} }
sub longitude  { $_[0]{longitude} }
sub latitude   { $_[0]{latitude} }


sub refetch         { my $self = shift;  return $self->ks->location($self->id, @_); }
sub nearby_projects { my $self = shift;  return $self->ks->projects_near_location($self->id, @_); }


1;


__END__

=head1 NAME

WWW::Kickstarter::Data::Location - Kickstarter location data


=head1 SYNOPSIS

   use WWW::Kickstarter;

   my $email    = '...';  # Your Kickstarter login credentials
   my $password = '...';

   my $ks = WWW::Kickstarter->new();
   $ks->login($email, $password);

   my $iter = $ks->projects_ending_soon();
   while (my ($project) = $iter->get()) {
      printf "%s: %s\n", $project->name, $project->location->displayable_name;
   }


=head1 ACCESSORS

=head2 id

   my $location_id = $location->id;

Returns the numerical id of the location.


=head2 slug

   my $location_slug = $location->slug;

Returns the keyword id of the location.


=head2 type

   my $location_type = $location->type;

Returns the location's type (e.g. "Town").


=head2 country

   my $location_country = $location->country;

Returns the location's country


=head2 state

   my $location_state = $location->state;

Returns the location's state.


=head2 name

   my $location_name = $location->name;

Returns the location's name.


=head2 full_name

   my $location_name = $location->full_name;

Returns the location's full ("displayable") name.


=head2 short_name

   my $location_name = $location->short_name;

Returns the location's short name.


=head2 longitude

   my $longitude = $location->longitude;

Returns the location's longitude.


=head2 latitude

   my $latitude = $location->latitude;

Returns the location's latitude.


=head1 API CALLS

=head2 refetch

   $location = $location->refetch();

Refetches this location from Kickstarter.

This ensures the data is up to date, and it will populate fields that may not be provided by objects created by some API calls.


=head2 nearby_projects

   my $projects_iter = $location->nearby_projects(%opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns as L<WWW::Kickstarter::Data::Project> objects the projects near this location.

It accepts the same options as L<<WWW::Kickstarter's C<projects>|WWW::Kickstarter/projects>.


=head2 project

   my $project = $reward->project();

Fetches and returns the project associated with this reward as a L<WWW::Kickstarter::Data::Project> object.


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
