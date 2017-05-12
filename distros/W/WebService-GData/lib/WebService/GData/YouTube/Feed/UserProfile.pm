package WebService::GData::YouTube::Feed::UserProfile;

use WebService::GData;
use base 'WebService::GData::Feed::Entry';
use WebService::GData::Constants qw(:all);
use WebService::GData::YouTube::Constants qw(:all);

use WebService::GData::YouTube::YT::Statistics ();
use WebService::GData::Node::GD::FeedLink ();
use WebService::GData::Collection;

our $VERSION = 0.01_01;

sub __init {
    my ( $this, $feed, $req ) = @_;

    if ( ref($feed) eq 'HASH' ) {
        $this->SUPER::__init( $feed, $req );
    }
    else {
        $this->SUPER::__init( {}, $feed );#$feed ==$req here
    }
    
    $this->{_statistics}= new WebService::GData::YouTube::YT::Statistics($this->{_feed}->{'yt$statistics'});
    $this->{_feed_links}= new WebService::GData::Collection($this->{_feed}->{'gd$feedLink'}||[],undef,sub { 
            my $elm=shift; 
            $elm= WebService::GData::Node::GD::FeedLink->new($elm) if ref $elm ne 'WebService::GData::Node::GD::FeedLink'; 
            return $elm; 
        });
    $this->_entity->child($this->{_statistics})
                  ->child($this->{_feed_links});
}

sub about_me {
    my $this = shift;
    return $this->{_feed}->{'yt$aboutMe'}->{'$t'};	
}
sub first_name {
    my $this = shift;
    return $this->{_feed}->{'yt$firstName'}->{'$t'};	
}
sub last_name {
    my $this = shift;
    return $this->{_feed}->{'yt$lastName'}->{'$t'};    
}
sub thumbnail {
    my $this = shift;
    return $this->{_feed}->{'media$thumbnail'}->{'url'};    
}
no strict 'refs';
foreach my $node (qw(age username books gender company hobbies hometown location movies
                     music relationship occupation school)) {

    *{ __PACKAGE__ . '::' . $node . '' } = sub {
        my $this = shift;
         return $this->{_feed}->{'yt$'.$node}->{'$t'}; 
      }
}




"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::YouTube::Feed::UserProfile - a youtube user profile for data API v2.

=head1 SYNOPSIS


    use WebService::GData::YouTube;
    
    my $yt = new WebService::GData::YouTube();    
    
    my $profile = $yt->get_user_profile('profile_name_here');
    
    say $profile->about_me;
    say $profile->first_name;
    say $profile->last_name;
    say $profile->age;
    say $profile->username; 
    say $profile->statistics->last_web_access;
    #etc...

    
  
     



=head1 DESCRIPTION

!WARNING! Documentation in progress.

!DEVELOPER RELEASE! API may change, program may break or be under optimized and I haven't done a full range of tests yet!


I<inherits from L<WebService::GData::Feed::Entry>.

This package represents a Youtube User Profile. 

It's a read only data so you can not edit the profile information.

Most of the time you will not instantiate this class directly but use the get_user_profile method in the L<WebService::GData::YouTube> class.

=back

=head2 CONSTRUCTOR


=head3 new

=over

Create a L<WebService::GData::YouTube::Feed::UserProfile> instance. 

B<Parameters>:

=over

=item C<jsonc_video_entry_feed:Object> (Optional)

=item C<authorization:Object> (Optional)

or 

=item C<authorization:Object> (Optional)

=back

=back

=head2 INHERITED METHODS

All the following read only methods give access to the information contained in a user profile feed entry.

=over 

=head3 etag

=head3 updated

=head3 published

=head3 category

=head3 id

=head3 link

=head3 title 

=head3 author
  
=back     

=head2 GETTERS

Below are getters sending back raw text about the user profile information.

Most of them are self explanotory but read 

L<http://code.google.com/intl/en/apis/youtube/2.0/developers_guide_protocol_profiles.html>

for further information.

=head3 about_me

=head3 first_name

=head3 last_name

=head3 age

=head3 username

=head3 books

=head3 gender

=head3 company

=head3 hobbies

=head3 hometown

=head3 location

=head3 movies

=head3 music

=head3 relationship

=head3 occupation

=head3 school

=head3 thumbnail

=head3 feed_links

Returns a L<WebService::GData::Collection> of L<WebService::GData::Node::GD::FeedLink>.

=head3 statistics

Returns a L<WebService::GData::YouTube::YT::Statistics> instance.

You can call the following methods on this object:

    my $stats = $profile->statistics;
   say $stats-> last_web_access;
   say $stats-> view_count;
   say $stats-> subscriber_count;
   say $stats-> video_watch_count;
   say $stats-> total_upload_views;


=head1  CONFIGURATION AND ENVIRONMENT

none


=head1  INCOMPATIBILITIES

none

=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

shiriru E<lt>shirirulestheworld[arobas]gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
