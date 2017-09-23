
package WWW::Kickstarter::Data::Project;

use strict;
use warnings;
no autovivification;


use WWW::Kickstarter::Data       qw( );
use WWW::Kickstarter::Data::User qw( );


our @ISA = 'WWW::Kickstarter::Data';


sub _new {
   my_croak(400, "Incorrect usage") if @_ < 3;
   my ($class, $ks, $data, %opts) = @_;

   if (my @unrecognized = keys(%opts)) {
      my_croak(400, "Unrecognized parameters @unrecognized");
   }

   my $self = $class->SUPER::_new($ks, $data);
   $self->{creator } = WWW::Kickstarter::Data::User    ->_new($ks, $self->{creator }) if exists($self->{creator });
   $self->{category} = WWW::Kickstarter::Data::Category->_new($ks, $self->{category}) if exists($self->{category});
   $self->{location} = WWW::Kickstarter::Data::Location->_new($ks, $self->{location}) if exists($self->{location});

   if (exists($self->{rewards})) {
      for my $reward (@{ $self->{rewards} }) {
         $reward = WWW::Kickstarter::Data::Reward->_new($ks, $reward);
      }
   }

   return $self;
}


sub id            { $_[0]{id} }
sub slug          { $_[0]{slug} }
sub name          { $_[0]{name} }
sub url           { $_[0]{urls}{web}{project} }
sub blurb         { $_[0]{blurb} }
sub launched_at   { $_[0]{launched_at} }    # When project started
sub deadline      { $_[0]{deadline} }       # When project ends
sub backers_count { $_[0]{backers_count} }
sub currency      { $_[0]{currency} }
sub goal          { $_[0]{goal} }
sub pledged       { $_[0]{pledged} }
sub progress      { $_[0]{pledged} / $_[0]{goal} }
sub progress_pct  { int( $_[0]{pledged} / $_[0]{goal} * 100 ) }
sub creator       { $_[0]{creator} }
sub location      { $_[0]{location} }
sub category      { $_[0]{category} }
sub category_id   { $_[0]{category}{id} }
sub category_name { $_[0]{category}{name} }


sub refetch { my $self = shift;  return $self->ks->project($self->id, @_); }

sub rewards {
   my ($self, %opts) = @_;
   my $force = delete($opts{force});
   return @{ $self->{rewards} } if !$force && $self->{rewards};
   return $self->ks->project_rewards($self->id, %opts);
}


1;


__END__

=head1 NAME

WWW::Kickstarter::Data::Project - Kickstarter project data


=head1 SYNOPSIS

   use WWW::Kickstarter;

   my $email    = '...';  # Your Kickstarter login credentials
   my $password = '...';

   my $ks = WWW::Kickstarter->new();
   $ks->login($email, $password);

   my $iter = $ks->projects_ending_soon();
   while (my ($project) = $iter->get()) {
      print($project->name, "\n");
   }


=head1 ACCESSORS

=head2 id

   my $project_id = $project->id;

Returns the numerical id of the project.


=head2 slug

   my $project_slug = $project->slug;

Returns creator-selected keyword id of the project, or undef if it doesn't have one.


=head2 name

   my $project_name = $project->name;

Returns the project's name.


=head2 url

   my $project_url = $project->url;

Returns the web address of the project's main page.


=head2 blurb

   my $project_blurb = $project->blurb;

Returns a short plain-text description of the project.


=head2 launched_at

   my $project_launched_at = $project->launched_at;

Returns the epoch timestamp (as returned by L<C<time>|perlfunc/time>) of the project's launch.


=head2 deadline

   my $project_deadline = $project->deadline;

Returns the epoch timestamp (as returned by L<C<time>|perlfunc/time>) of the project's deadline.


=head2 backers_count

   my $project_backers_count = $project->backers_count;

Returns the number of backers the project has.


=head2 currency

   my $currency = $project->currency;

Returns the currency used for this project's goal, its pledges and its rewards.


=head2 goal

   my $project_goal = $project->goal;

Returns the amount the project is attempting to raise. The amount is in the currency returned by L<C<currency>|/currency>.


=head2 pledged

   my $project_pledged = $project->pledged;

Returns the amount that has been pledged to the project. The amount is in the currency returned by L<C<currency>|/currency>.


=head2 progress

   my $project_progress = $project->progress;

Returns the progress towards the project's goal. For example, a value greater than or equal to 1.00 indicates the goal was reached.


=head2 progress_pct

   my $project_progress_pct = $project->progress_pct;

Returns the progress towards the project's goal as a percent. For example, a value greater than or equal to 100 indicates the goal was reached


=head2 creator

   my $user = $project->creator;

Returns the creator of the project as an L<WWW::Kickstarter::Data::User> object.

Some data will not available without a refetch.


=head2 location

   my $location = $project->location;

Returns the location of the project as an L<WWW::Kickstarter::Data::Location> object.


=head2 category

   my $category = $project->category;

Returns the category of the project as an L<WWW::Kickstarter::Data::Category> object.


=head2 category_id (Deprecated)

   my $category_id = $project->category_id;

Returns the id of the category of the project.

B<Deprecated>: Use C<< $project->category->id >> instead.


=head2 category_name (Deprecated)

   my $category_name = $project->category_name;

Returns the name of the category of the project.

B<Deprecated>: Use C<< $project->category->name >> instead.


=head1 API CALLS

=head2 refetch

   $project = $project->refetch();

Refetches this project from Kickstarter.

This ensures the data is up to date, and it will populate fields that may not be provided by objects created by some API calls.


=head2 rewards

   my @rewards = $project->rewards();
   my @rewards = $project->rewards( force => 1 );

Returns the rewards of the specified project as L<WWW::Kickstarter::Data::Reward> objects.

When fetching an individual project, Kickstarter includes "light" reward objects in its response.
By default, these are the objects returned by this method.

If these rewards objects are not available, or if C<< force => 1 >> is specified,
the "full" reward objects will be fetched and returned.


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
