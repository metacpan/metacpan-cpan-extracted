
package WWW::Kickstarter::Data::NotificationPref;

use strict;
use warnings;
no autovivification;


use WWW::Kickstarter::Data qw( );


our @ISA = 'WWW::Kickstarter::Data';


sub id               { $_[0]{id} }
sub project_id       { $_[0]{project}{id} }
sub project_name     { $_[0]{project}{name} }
sub notify_by_email  { $_[0]{email} }
sub notify_by_mobile { $_[0]{mobile} }


1;


__END__

=head1 NAME

WWW::Kickstarter::Data::NotificationPref - Notification preferences for projects you backed


=head1 SYNOPSIS

   use WWW::Kickstarter;

   my $email    = '...';  # Your Kickstarter login credentials
   my $password = '...';

   my $ks = WWW::Kickstarter->new();
   $ks->login($email, $password);

   my @notification_prefs = $ks->my_notification_prefs();

   for my $notification_pref (@notification_prefs) {
      print("$notification_pref->project_name -- "
         ."email:".($notification_pref->by_email?"yes":"no")." "
         ."mobile:".($notification_pref->by_mobile?"yes":"no")."\n"
      );
   }


=head1 ACCESSORS

=head2 id

   my $notification_pref_id = $notification_pref->id;

Returns the numerical id of this notification preference.


=head2 project_id

   my $project_id = $notification_pref->project_id;

Returns the numerical id of the project for which this notifcation preference applies.


=head2 project_name

   my $project_name = $notification_pref->project_name;

Returns the name of the project for which this notifcation preference applies.


=head2 notify_by_email

   my $notify_by_email = $notification_pref->notify_by_email;

Returns true if the you wish to be notified of updates to the project identified by C<project_id> by email.


=head2 notify_by_mobile

   my $notify_by_mobile = $notification_pref->notify_by_mobile;

Returns true if the you wish to be notified of updates to the project identified by C<project_id> by mobile.


=head1 API CALLS

None. Notably, this object can't be refetched.


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
