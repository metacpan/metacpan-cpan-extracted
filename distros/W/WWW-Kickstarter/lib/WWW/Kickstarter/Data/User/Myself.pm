
package WWW::Kickstarter::Data::User::Myself;

use strict;
use warnings;
no autovivification;


use WWW::Kickstarter::Data::User qw( );


our @ISA = 'WWW::Kickstarter::Data::User';


sub notification_prefs { my $self = shift;  return $self->ks->my_notification_prefs(@_); }
sub projects_created   { my $self = shift;  return $self->ks->my_projects_created(@_); }
sub projects_backed    { my $self = shift;  return $self->ks->my_projects_backed(@_); }
sub projects_starred   { my $self = shift;  return $self->ks->my_projects_starred(@_); }


1;


__END__

=head1 NAME

WWW::Kickstarter::Data::User::Myself - Kickstarter user data for the logged-in user


=head1 SYNOPSIS

   use WWW::Kickstarter;

   my $email    = '...';  # Your Kickstarter login credentials
   my $password = '...';

   my $ks = WWW::Kickstarter->new();
   my $myself = $ks->login($email, $password);

   my $iter = $myself->projects_backed();
   while (my ($project) = $iter->get()) {
      print($project->name, "\n");
   }


=head1 DESCRIPTION

Kickstarter provides more information on the logged-in user than other users.
This class extends L<WWW::Kickstarter::Data::User> to provide that information.


=head1 API CALLS

This class provides the following API calls in addition to those provided by L<WWW::Kickstarter::Data::User>.

=head2 notification_prefs

   my @notification_prefs = $myself->notification_prefs();

Fetches and returns the the logged-in user's notification preferences of backed projects as L<WWW::Kickstarter::Data::NotificationPref> objects.
The notification preferences for the project created last is returned first.


=head2 projects_created

   my @projects = $myself->projects_created();

Fetches and returns the projects created by the logged-in user as L<WWW::Kickstarter::Data::Project> objects.
The project created last is returned first.


=head2 projects_backed

   my $projects_iter = $myself->projects_backed(%opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns the projects backed by the logged-in user as L<WWW::Kickstarter::Data::Project> objects.
The most recently backed project is returned first.

Note that some projects may be returned twice. This happens when the data being queried changes while the results are being traversed.

Options:

=over

=item * C<< page => $page_num >>

If provided, the pages of results before the specified page number are skipped.

=back


=head2 projects_starred

   my $projects_iter = $myself->projects_starred(%opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns the projects starred by the logged-in user as L<WWW::Kickstarter::Data::Project> objects.
The most recently starred project is returned first.

Note that some projects may be returned twice. This happens when the data being queried changes while the results are being traversed.

Options:

=over

=item * C<< page => $page_num >>

If provided, the pages of results before the specified page number are skipped.

=back


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
