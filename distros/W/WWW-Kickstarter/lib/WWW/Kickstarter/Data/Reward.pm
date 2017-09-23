
package WWW::Kickstarter::Data::Reward;

use strict;
use warnings;
no autovivification;


use WWW::Kickstarter::Data  qw( );
use WWW::Kickstarter::Error qw( my_croak );


our @ISA = 'WWW::Kickstarter::Data';


sub id            { $_[0]{id} }
sub project_id    { $_[0]{project_id} }
sub text          { $_[0]{reward} }
sub min_pledge    { $_[0]{minimum} }
sub max_backers   { $_[0]{limit} }
sub backers_count { $_[0]{backers_count} }


#sub refetch { my $self = shift;  return $self->ks->reward($self->id, @_); }
sub project { my $self = shift;  return $self->ks->project($self->project_id, @_); }


1;


__END__

=head1 NAME

WWW::Kickstarter::Data::Reward - Kickstarter reward data


=head1 SYNOPSIS

   use WWW::Kickstarter;

   my $email    = '...';  # Your Kickstarter login credentials
   my $password = '...';

   my $ks = WWW::Kickstarter->new();
   $ks->login($email, $password);

   my $iter = $ks->projects_ending_soon();
   while (my ($project) = $iter->get()) {
      my @rewards = $project->rewards;
      ...
   }


=head1 ACCESSORS

=head2 id

   my $reward_id = $reward->id;

Returns the numerical id of the reward. The special id C<0> refers to the special "No Reward" reward.


=head2 project_id

   my $project_id = $reward->project_id;

Returns the numerical id of the project associated with this reward. This returns C<undef> for the special "No Reward" reward (id C<0>).


=head2 text

   my $reward_text = $reward->text;

Returns the reward's text.


=head2 min_pledge

   my $min_pledge = $reward->min_pledge;

Returns the minimum pledge required to obtain this reward. The amount is in the currency returned by the associated projects L<C<currency>|WWW::Kickstarter::Data::Project/currency>.


=head2 max_backers

   my $max_backers = $reward->max_backers;

Returns the maximum number of backers which can select this reward, or C<undef> if there is no maximum.


=head2 backers_count

   my $backers_count = $reward->backers_count;

Returns the number of backers that have selected this reward. This returns C<undef> for the special "No Reward" reward (id C<0>).


=head1 API CALLS

Notably, this object can't be refetched.


=head2 project

   my $project = $reward->project();

Fetches and returns the project associated with this reward as a L<WWW::Kickstarter::Data::Project> object.


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
