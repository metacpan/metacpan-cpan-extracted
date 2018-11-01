
package WWW::Kickstarter::Data::User;

use strict;
use warnings;
no autovivification;


use WWW::Kickstarter::Data qw( );


our @ISA = 'WWW::Kickstarter::Data';


sub _new {
   my_croak(400, "Incorrect usage") if @_ < 3;
   my ($class, $ks, $data, %opts) = @_;

   if (my @unrecognized = keys(%opts)) {
      my_croak(400, "Unrecognized parameters @unrecognized");
   }

   my $self = $class->SUPER::_new($ks, $data);
   $self->{location} = WWW::Kickstarter::Data::Location->_new($ks, $self->{location}) if defined($self->{location});

   return $self;
}


sub id       { $_[0]{id} }
sub slug     { $_[0]{slug} }
sub name     { $_[0]{name} }
sub location { $_[0]{location} }


sub refetch          { my $self = shift;  return $self->ks->user($self->id, @_); }
sub projects_created { my $self = shift;  return $self->ks->user_projects_created($self->id, @_); }


1;


__END__

=head1 NAME

WWW::Kickstarter::Data::User - Kickstarter user data


=head1 SYNOPSIS

   use WWW::Kickstarter;

   my $email    = '...';  # Your Kickstarter login credentials
   my $password = '...';

   my $ks = WWW::Kickstarter->new();
   $ks->login($email, $password);

   my $iter = $ks->projects_ending_soon();
   while (my ($project) = $iter->get()) {
      print($project->creator->name, "\n");
   }


=head1 ACCESSORS

=head2 id

   my $user_id = $user->id;

Returns the numerical id of the user.


=head2 slug

   my $user_slug = $user->slug;

Returns self-selected keyword id of the user, or undef if it's not available or if it doesn't have one.


=head2 name

   my $user_name = $user->name;

Returns the user's name.


=head2 location

   my $location = $user->location;

Returns the location of the user as an L<WWW::Kickstarter::Data::Location> object.


=head1 API CALLS

=head2 refetch

   $user = $user->refetch();

Refetches this user from Kickstarter.

This ensures the data is up to date, and it will populate fields that may not be provided by objects created by some API calls.


=head2 projects_created

   my @projects = $user->projects_created();

Fetches and returns the projects created by the specified user as L<WWW::Kickstarter::Data::Project> objects. The project created last is returned first.


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
