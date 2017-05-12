package WebService::GData::YouTube;
use WebService::GData;
use base 'WebService::GData';

use WebService::GData::Base;
use WebService::GData::YouTube::Constants;
use WebService::GData::YouTube::Query;
use WebService::GData::YouTube::StagingServer ();

#TODO: load these packages on demand
use WebService::GData::YouTube::Feed;
use WebService::GData::YouTube::Feed::PlaylistLink;
use WebService::GData::YouTube::Feed::Video;
use WebService::GData::YouTube::Feed::Comment;
use WebService::GData::YouTube::Feed::Complaint;
use WebService::GData::YouTube::Feed::Friend;
use WebService::GData::YouTube::Feed::VideoMessage;
#end

our $PROJECTION        = WebService::GData::YouTube::Constants::PROJECTION;
our $BASE_URI          = WebService::GData::YouTube::Constants::BASE_URI;

if(WebService::GData::YouTube::StagingServer->is_on){
  $BASE_URI          = WebService::GData::YouTube::Constants::STAGING_BASE_URI;
}

our $VERSION    = 0.0206;

sub __init {
	my ( $this, $auth ) = @_;
	$this->{_baseuri} = $BASE_URI . $PROJECTION . '/';
	
	$this->{_request} = new WebService::GData::Base();
	$this->{_request}->auth($auth) if ($auth);
$this->{__cache__}={};
	#overwrite default query engine to support youtube extra feature
	my $query = new WebService::GData::YouTube::Query();
	$query->key( $auth->key ) if ($auth);
	$this->query($query);
}

sub connection {
    my ( $this ) = @_;
    return $this->{_request};
}

sub query {
	my ( $this, $query ) = @_;
	return $this->{_request}->query($query);
}

sub base_uri {
	my $this = shift;
	return $this->{_baseuri};
}

sub base_query {
	my $this = shift;
	return $this->query->to_query_string;
}

#playlist related

sub get_user_playlist_by_id {
	my ( $this, $playlistid,$preserve_start_index) = @_;
	
    return if(exists $this->{__cache__}->{$playlistid} && !$this->{__cache__}->{$playlistid});
    
	my $uri;
	if($this->{__cache__}->{$playlistid}){
		$uri = $this->{__cache__}->{$playlistid};
	}
	else {
		$this->query->start_index(1) if !$preserve_start_index;
	}

    my @request=$uri ? ($uri,1) : $this->{_baseuri} . 'playlists/' . $playlistid;
	my $res =
	  $this->{_request}->get(@request);

	my $feed =
	  new WebService::GData::YouTube::Feed( $res, $this->{_request} );

    $this->{__cache__}->{$playlistid}= $feed->next_link;

	return wantarray ? ($feed->entry,$feed):$feed->entry;
}

sub get_user_playlists {
	my ( $this, $channel,$preserve_start_index ) = @_;

	#by default, the one connected is returned
	my $uri = $this->{_baseuri} . 'users/default/playlists';
	$uri = $this->{_baseuri} . 'users/' . $channel . '/playlists' if ($channel);
	
   return if(exists $this->{__cache__}->{$uri} && !$this->{__cache__}->{$uri});
    
    my $next_url;
    if($this->{__cache__}->{$uri}){
        $next_url = $this->{__cache__}->{$uri};
    }
    else {
        $this->query->start_index(1) if !$preserve_start_index;
    }

    my @request=$next_url ? ($next_url,1) : $uri;	
	

	my $res = $this->{_request}->get(@request);

	my $feed =
	  new WebService::GData::YouTube::Feed( $res, $this->{_request} );

    $this->{__cache__}->{$uri}= $feed->next_link;

    return wantarray ? ($feed->entry,$feed):$feed->entry;
}

sub get_user_profile {
    my ( $this, $channel ) = @_;

    #by default, the one connected is returned
    my $uri = $this->{_baseuri} . 'users/default/';
    $uri = $this->{_baseuri} . 'users/' . $channel if ($channel);

    my $res = $this->{_request}->get($uri);

    my $playlists =
      new WebService::GData::YouTube::Feed( $res, $this->{_request} );

    return $playlists->entry->[0];
}

sub get_user_contacts {
    my ( $this, $channel ) = @_;

    #by default, the one connected is returned
    my $uri = $this->{_baseuri} . 'users/default/contacts';
    $uri = $this->{_baseuri} . 'users/' . $channel.'/contacts' if ($channel);

    my $res = $this->{_request}->get($uri);

    my $contacts =
      new WebService::GData::YouTube::Feed( $res, $this->{_request} );

    return $contacts->entry;
}

sub get_user_inbox {
    my ( $this ) = @_;

    #by default, the one connected is returned
    my $uri = $this->{_baseuri} . 'users/default/inbox';

    my $res = $this->{_request}->get($uri);

    return
      new WebService::GData::YouTube::Feed( $res, $this->{_request} )->entry;

}

#video related

sub like_video {
    my ($this,$id) = @_;
     my $vid = $this->video;
        $vid->video_id($id);
    	$vid->rate('like');
}

sub dislike_video {
    my ($this,$id) = @_;
     my $vid = $this->video;
        $vid->video_id($id);
        $vid->rate('dislike');
}

sub add_video_response {
    my ($this,$video_id,$response_id) = @_;	
    
    my $video = $this->video;
       $video->video_id($video_id);
    my $response = $this->video;
       $response->id($response_id);	
       $video->add_video_response($response);
}

sub delete_video_response {
    my ($this,$video_id,$response_id) = @_; 
    
    my $video = $this->video;
       $video->video_id($video_id);
       $video->delete_video_response($response_id);

}

sub add_favorite_video {
    my ($this,$video_id) = @_; 
    my $video = $this->video;
       $video->add_favorite_video($video_id);	
}

sub video {
	my $this = shift;
	return new WebService::GData::YouTube::Feed::Video( $this->{_request} );
}

sub playlists {
    my $this = shift;
    return new WebService::GData::YouTube::Feed::PlaylistLink( $this->{_request} );
}

sub comment {
	my $this = shift;
	return new WebService::GData::YouTube::Feed::Comment( $this->{_request} );
}

sub complaint {
    my $this = shift;
    return new WebService::GData::YouTube::Feed::Complaint( $this->{_request} );
}

sub contact {
    my $this = shift;
    return new WebService::GData::YouTube::Feed::Friend( $this->{_request} );
}

sub message {
    my $this = shift;
    return new WebService::GData::YouTube::Feed::VideoMessage( $this->{_request} );
}

sub search_video {
	my ( $this, $query ) = @_;
	$this->query($query) if ($query);
	my $res = $this->{_request}->get( $this->{_baseuri} . 'videos/' );
	my $playlists =
	  new WebService::GData::YouTube::Feed( $res, $this->{_request} );
	return $playlists->entry;
}

sub get_video_by_id {
	my ( $this, $id ) = @_;

	my $uri = $this->{_baseuri} . 'videos/' . $id;

	my $res = $this->{_request}->get($uri);

	my $playlists =
	  new WebService::GData::YouTube::Feed( $res, $this->{_request} );

	return $playlists->entry->[0];
}

sub get_user_video_by_id {
	my ( $this, $id, $channel ) = @_;

	my $uri = $this->{_baseuri} . 'users/default/uploads/' . $id;
	$uri = $this->{_baseuri} . 'users/' . $channel . '/uploads/' . $id
	  if ($channel);

	my $res = $this->{_request}->get($uri);

	my $playlists =
	  new WebService::GData::YouTube::Feed( $res, $this->{_request} );

	return $playlists->entry->[0];
}

sub get_user_videos {
	my ( $this, $channel ) = @_;

	my $uri = $this->{_baseuri} . 'users/default/uploads';
	$uri = $this->{_baseuri} . 'users/' . $channel . '/uploads' if ($channel);

	my $res = $this->{_request}->get($uri);

	my $playlists =
	  new WebService::GData::YouTube::Feed( $res, $this->{_request} );

	return $playlists->entry;
}

sub get_user_favorite_videos {
	my ( $this, $channel ) = @_;

	my $uri = $this->{_baseuri} . 'users/default/favorites/';
	$uri = $this->{_baseuri} . 'users/' . $channel . '/favorites/'
	  if ($channel);

	my $res = $this->{_request}->get($uri);

	my $feed =
	  new WebService::GData::YouTube::Feed( $res, $this->{_request} );

	return $feed->entry;
}

sub get_recommended_videos {
    my ( $this) = @_;

    my $uri = $this->{_baseuri} . 'users/default/recommendations';

    my $res = $this->{_request}->get($uri);

    my $feed =
      new WebService::GData::YouTube::Feed( $res, $this->{_request} );

    return $feed->entry;
}

#sub move_video {
#	my ( $this, %params ) = @_;

#	my $playlistLink =
#	  new WebService::GData::YouTube::Feed::PlaylistLink( {},
#		$this->{_request} );

	#delete old one
#	$playlistLink->playlistId( $params{'from'} );
#	$playlistLink->deleteVideo( videoId => $params{'videoid'} );

	#put in new one
#	$playlistLink->playlistId( $params{'to'} );
#	$playlistLink->addVideo( videoId => $params{'videoid'} );
#}

#standard feeds
no strict 'refs';
foreach my $stdfeed (
	qw(top_rated 
	   top_favorites 
	   most_viewed
	   most_shared 
	   most_popular 
	   most_recent 
	   most_discussed 
	   most_responded 
	   recently_featured 
	   on_the_web)
  )
{

	*{ __PACKAGE__ . '::get_' . $stdfeed . '_videos' } = sub {
		my ( $this, $region, $category, $time ) = @_;

		my $uri = $this->{_baseuri} . 'standardfeeds/';
		$uri .= $region . '/' if $region;
		$uri .= $stdfeed;
		$uri .= '_' . $category if $category;
		$this->query->time($time) if $time;
		my $res = $this->{_request}->get($uri);

		my $playlists =
		  new WebService::GData::YouTube::Feed( $res, $this->{_request} );
		return $playlists->entry;
	  }
}

foreach my $feed (qw(comments responses related)) {

	*{ __PACKAGE__ . '::get_' . $feed . '_for_video_id' } = sub {
		my ( $this, $id ) = @_;

		my $uri = $this->{_baseuri} . 'videos/' . $id . '/' . $feed;
		my $res = $this->{_request}->get($uri);

		my $playlists =
		  new WebService::GData::YouTube::Feed( $res, $this->{_request} );
		return $playlists->entry;
	  }
}

"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::YouTube - Access YouTube contents(read/write) with API v2.

=head1 SYNOPSIS

    use WebService::GData::YouTube;

    #create an object that only has read access
    my $yt = new WebService::GData::YouTube();

    #get a feed response from YouTube;
    my $videos  = $yt->get_top_rated_videos;
    #more specific:
    my $videos  = $yt->get_top_rated_videos('JP','Comedy');

    foreach my $video (@$videos) {
        say $video->video_id;
        say $video->title;
        say $video->content;
    }

    #connect to a YouTube account
    my $auth = new WebService::GData::ClientLogin(
        email   =>'...'
        password=>'...',
        key     =>'...'
    );

    #give write access
    my $yt = new WebService::GData::YouTube($auth);

    #returns all the videos from the logged in user 
    #including private ones.
    my $videos  = $yt->get_user_videos();

    #update the videos by adding the common keywords if they are public
    #delete a certain video by checking its id.
    foreach my $video (@$videos) {

        if($video->video_id eq $myid) {

            $video->delete();

        } else {

            if($video->is_listing_allowed){

                $video->keywords('music,live,guitar,'.$video->keywords);
                $video->save();
            }
        }
    }
	 

=head1 DESCRIPTION


!DEVELOPER RELEASE! API may change, program may break or be under optimized.

!DEVELOPER RELEASE! API may change, program may break or be under optimized.

!DEVELOPER RELEASE! API may change, program may break or be under optimized.

!WARNING! Documentation in progress.


I<inherits from L<WebService::GData>>

This package is a point of entry giving access to general YouTube feeds.
Passing an optional authorization object (WebService::GData::ClientLogin) will allow you to access private contents.
It also offers some helper methods to shorten up the code.
Most of the methods will return one of the following object:

=over 

=item L<WebService::GData::YouTube::Feed::Video>

This object handles the manipulation of the video data such as inserting/editing the metadata, uploading a video,etc.

=item L<WebService::GData::YouTube::Feed::Comment>

This object handles the insertion of comments on a video or in reply to an other comment.

=item L<WebService::GData::YouTube::Feed::Playlist>

This object inherits from L<WebService::GData::YouTube::Feed::Video>.
It contains a list of all the videos within this particular playlist.
The only difference with L<WebService::GData::YouTube::Feed::Video> is that it offers the position tag that specifies
the position of the video within the playlist.

=item L<WebService::GData::YouTube::Feed::PlaylistLink>

This object represents all the playlists metadata of a user.
It is not possible to get the metadata of one playlist. You need to query them all and search for the one you're interested in.

=item L<WebService::GData::YouTube::StagingServer>

use this package at the very top of your program to switch all the read/writes urls to the staging server

See also:

=over 

=item * L<WebService::GData::YouTube::Doc::BrowserBasedUpload> - overview of the browser based upload mechanism

=back

=over 

=item * L<WebService::GData::YouTube::Doc::GeneralOverview> - in progress but should allow you to learn the library easily

=back

=over 

=item * L<http://szabgab.com/blog/2011/06/fetching-data-from-youtube-using-perl.html> - a short video on the library by Gabor Szabo.

=back

=back


=head2 CONSTRUCTOR


=head3 new

=over

Create a L<WebService::GData::YouTube> instance.

B<Parameters>

=over 4

=item C<auth:Object> (optional)  - Accept an optional authorization object.

Only L<WebService::GData::ClientLogin> is available for now but OAuth should come anytime soon.
Passing an auth object allows you to access private contents and insert/edit/delete data.

=back

B<Returns> 

=over 4

=item C<WebService::GData::YouTube> instance 

=back

Example:

    use WebService::GData::ClientLogin;
    use WebService::GData::YouTube;

    #create an object that only has read access
    my $yt = new WebService::GData::YouTube();

    #connect to a YouTube account
    my $auth = new WebService::GData::ClientLogin(
        email=>'...'
        password=>'...',
        key        =>'...'
    );

    #give write access with a $auth object that you created
    my $yt = new WebService::GData::YouTube($auth);

=back


=head2 GENERAL METHODS

=head3 query

=over

Set/get a query object that handles the creation of the query string sent to the service.
The query object will build the query string required to access the data.
All queries contain some default parameters like the alt,v,strict parameters.
You can add other parameters in order to do a search.

B<Parameters>

=over 4

=item C<none> - getter context

=item C<query:Object> - setter context accept a query string builder instance. Default to L<WebService::GData::YouTube::Query>

=back

B<Returns>

=over 4

=item C<query:Object> in both setter/getter context the query object. Default to L<WebService::GData::YouTube::Query>

=back

Example:

	use WebService::GData::YouTube;

   	my $yt = new WebService::GData::YouTube();

	$yt->query()->q("ski")->limit(10,0);

	#or set your own query object
	$yt->query($myquery);

	my $videos = $yt->search_video();

=over


=head3 base_uri

=over

Get the base uri used to query the data.

B<Parameters>

=over 4

=item C<none>

=back

B<Returns>

=over 4

=item  C<url:Scalar> the root uri

=back

=back

=head3 base_query

=over

Get the base query string used to get the data.

B<Parameters>

=over 4

=item C<none>

=back

B<Returns>

=over

=item C<url:Scalar> - default to ?alt=json&prettyprint=false&strict=true

=back

=back

=head3 connection

=over

Get the connection handler (WebService::GData::Base by default).
Mostly usefull to set connector settings.

B<Parameters>

=over 4

=item C<none>

=back

B<Returns>

=over 4

=item  C<object:Object> the connector instance,by default L<WebService::GData::Base>.

=back

Example:

    use WebService::GData::YouTube;
    
    my $yt   = new WebService::GData::YouTube();
       $yt->connection->timeout(100)->env_proxy;

=back


=head2 STANDARD FEED METHODS

YouTube offers some feeds regarding videos like the most discussed videos or the most viewed videos.
All the standard feed methods are implemented:

B<methods>

=head3 get_top_rated_videos

=head3 get_top_favorites_videos

=head3 get_most_viewed_videos

=head3 get_most_shared_videos

=head3 get_most_popular_videos

=head3 get_most_recent_videos

=head3 get_most_discussed_videos

=head3 get_most_responded_videos 

=head3 get_recently_featured_videos

=head3 get_on_the_web_videos

See http://code.google.com/intl/en/apis/youtube/2.0/developers_guide_protocol_video_feeds.html#Standard_feeds

=over

All the above standard feed methods accept the following optional parameters:

B<Parameters>

=over 4

=item C<region_zone:Scalar> - a country code - ie:JP,US.

=item C<category:Scalar> - a video category - ie:Comedy,Sports.

=item C<time:Scalar> - a time  - ie:today,this_week,this_month,all_time

=back

B<Returns>

=over 4

=item L<WebService::GData::Youtube::Feed::Video> objects

=back

B<Throws>

=over 5

=item L<WebService::GData::Error>

=back

Example:

    use WebService::GData::YouTube;
	
    my $yt   = new WebService::GData::YouTube();
    my $videos = $yt->get_top_rated_videos();
    my $videos = $yt->get_top_rated_videos('JP');#top rated videos in Japan
    my $videos = $yt->get_top_rated_videos('JP','Comedy');#top rated videos in Japanese Comedy 
    my $videos = $yt->get_top_rated_videos('JP','Comedy','today');#top rated videos of the day in Japanese Comedy 


B<See also>:

Explanation of the different standard feeds:

L<http://code.google.com/intl/en/apis/youtube/2.0/reference.html#Standard_feeds>

=back


=head2 VIDEO FEED METHODS

These methods allow you to access videos.
You do not need to be logged in to use these methods.

=head3 get_video_by_id

=over

Get a video by its id.

B<Parameters>

=over 4

=item C<video_id:Scalar> - the unique id of the video- ie:Displayed in the url when watching a video. Looks like:Xzek3skD

=back

B<Returns>

=over 4

=item L<WebService::GData::YouTube::Feed::Video>

=back

B<Throws>

=over 4

=item L<WebService::GData::Error>

=back


Example:

    use WebService::GData::YouTube;
	
    my $yt   = new WebService::GData::YouTube();

    my $video = $yt->get_video_by_id('Xzek3skD');

=back


=head3 search_video

=over

Send a request to search for videos.
You create the query by calling $yt->query and by setting the available parameters.

B<Parameters>

=over

=item C<query:Object> (optional) - a query builder instance

=back

B<Returns>

=over 4

=item L<WebService::GData::YouTube::Feed::Video>

=back

B<Throws>

=over 4

=item L<WebService::GData::Error>

=back

Example:

    use WebService::GData::YouTube;
    
    my $yt   = new WebService::GData::YouTube();

       $yt->query->q("ski")->limit(10,0);

    my $videos = $yt->search_video();

    #or

    my $yt     = new WebService::GData::YouTube();
    my $query  = $yt->query;
       $query -> q("ski")->limit(10,0);
    my $videos = $yt->search_video();

    #or set a new query object
    #it could be a sub class that has predefined value

    my $query  = new WebService::GData::YouTube::Query();

       $query -> q("ski")->limit(10,0);

    my $videos = $yt->search_video($query);#this is a helper the same as doing: $yt->query($query); $yt->search_video();

B<See also>:

A list of all the query parameters and related methods you can use with the default query object:

L<WebService::GData::YouTube::Query>

=back

=head3 get_related_for_video_id

=over 

Get the related videos for a video.
These videos are returned by following YouTube's own algorithm.

B<Parameters>

=over 4

=item C<video_id:Scalar> - the unique identifier of the video.

=back

B<Returns>

=over 4

=item L<WebService::GData::YouTube::Feed::Video> objects 

=back

B<Throws>

=over 4

=item L<WebService::GData::Error> 

=back

Example:
    
    my $yt   = new WebService::GData::YouTube();
    
    my $videos = $yt->get_related_for_video_id('Xz2eFFexA');

=back

=head3 get_comments_for_video_id

=over 

Get the comments of a video.

B<Parameters>

=over 4

=item C<video_id:Scalar> - the unique identifier of the video.

=back

B<Returns>

=over 4

=item L<WebService::GData::Collection> instances of L<WebService::GData::YouTube::Feed::Comment>

=back

B<Throws>

=over 4

=item L<WebService::GData::Error> 

=back

Example:

    use WebService::GData::YouTube; 
    my $yt   = new WebService::GData::YouTube();
    
    my $comments = $yt->get_comments_for_video_id('Xz2eFFexA');
    
    foreach my $comment (@$comments){
    	say $comment->content;
    }

=back


=head2 USER VIDEO FEED METHODS

All these methods allow you to access the videos of the programmaticly logged in user.
Being logged in allow you to access private contents or contents that have been uploaded but is not public yet.
The responses will also have a read/write access so you will be able to edit the videos.

It does not mean that you need to be logged in to use these methods.
By setting the name of the user (channel name),you will only get a read access to the public data.

=head3 get_user_video_by_id

=over

Get a video for the logged in user or for the user name you specified.
It queries the uploads feed which can be more up to date than the feed used with C<get_video_by_id()>.

B<Parameters>

=over

=item C<video_id:Scalar> - the id of the video

=item C<user_name:Scalar> (optional) - the name of the user (channel name)

=back

B<Returns>

=over

=item L<WebService::GData::YouTube::Feed::Video> objects 

=back

B<Throws>

=over

=item L<WebService::GData::Error> 

=back

Example:

    my $auth = new WebService::GData::ClientLogin(email=>...);
    
    my $yt   = new WebService::GData::YouTube($auth);
    
    my $videos = $yt->get_user_video_by_id('Xz2eFFexA');

    #if not logged in.
    my $videos = $yt->get_user_video_by_id('Xz2eFFexA','live');#you must specify the user if not logged in!

=back

=head3 get_user_videos

=over

Get the videos for the logged in user or for the user name you specified.

B<Parameters>

=over 4

=item C<user_name:Scalar> (optional) - the user name/channel name

=back

B<Returns>

=over 4 

=item L<WebService::GData::YouTube::Feed::Video> objects 

=back

B<Throws>

=over 4

=item L<WebService::GData::Error> 

=back

Example:

    my $auth = new WebService::GData::ClientLogin(email=>...);
    
    my $yt   = new WebService::GData::YouTube($auth);
    
    my $videos = $yt->get_user_videos();

    #if not logged in, pass the user name as the first parameter
    my $videos = $yt->get_user_videos('live');

=back


=head3 get_user_favorite_videos

=over

Get the videos that user specificly set a favorites (meaning that you may not have write access to the content even if you are logged in!).

B<Parameters>

=over 4

=item C<user_name:Scalar> (optional) - the user name/channel name

=back

B<Returns>

=over

=item L<WebService::GData::YouTube::Feed::Video> objects 

=back

B<Throws>

=over 4

=item L<WebService::GData::Error> 

=back

Example:

    my $auth = new WebService::GData::ClientLogin(email=>...);
    
    my $yt   = new WebService::GData::YouTube($auth);
    
    my $videos = $yt->get_user_favorite_videos();

    #if not logged in, pass the user name as the first parameter
    my $videos = $yt->get_user_favorite_videos('live');

=back

=head3 add_favorite_video

=over
    
B<Parameters>

=over 4

=item C<video_id:Scalar> the video id you want to add as a favorite


=back

B<Returns>

=over

=item L<void> 

=back

B<Throws>

=over 4

=item L<WebService::GData::Error> 

=back

Example:


    my $auth = new WebService::GData::ClientLogin(email=>...);
    
    my $yt   = new WebService::GData::YouTube($auth);
    
       $yt->add_favorite_video('video_id');

=back

=head3 get_recommended_videos

=over

Get the videos that a user may be interested in (defined by the YouTube algorithm).

You must be logged in to use this feature.

B<Parameters>

=over 4

none

=back

B<Returns>

=over

=item L<WebService::GData::YouTube::Feed::Video> objects 

=back

B<Throws>

=over 4

=item L<WebService::GData::Error> 

=back

Example:

    my $auth = new WebService::GData::ClientLogin(email=>...);
    
    my $yt   = new WebService::GData::YouTube($auth);
    
    my $videos = $yt->get_recommended_videos();



=back

=head2 RATING METHODS

=over

These methods allows you to rate,like or dislike, a video.
They are helper methods that instantiate a video instance for you.

You must be logged in to use these methods.

=head3 like_video

=head3 dislike_video

B<Parameters>

=over 4

=item C<video_id:Scalar> the video id to rate

=back

B<Returns>

=over

=item L<void> 

=back

B<Throws>

=over 4

=item L<WebService::GData::Error> 

=back

Example:


    my $auth = new WebService::GData::ClientLogin(email=>...);
    
    my $yt   = new WebService::GData::YouTube($auth);
    
       $yt->like_video('video_id');
       $yt->dislike_video('video_id');
       
   #in the background it simply does:
   
   my $vid = $yt->video;
      $vid->video_id('video_id');
      $vid->rate('like');

=back

=head2 VIDEO RESPONSE METHODS

=over

These methods allow you to add a video as a response to an other video.
You can also erase a video response.

They are helper methods that instantiate a video instance for you.
You must be logged in to use these methods.
    
=head3 add_video_response
    
B<Parameters>

=over 4

=item C<video_id:Scalar> the video id you want to response to

=item C<video_response_id:Scalar> the video id of the response

=back

B<Returns>

=over

=item L<void> 

=back

B<Throws>

=over 4

=item L<WebService::GData::Error> 

=back

Example:


    my $auth = new WebService::GData::ClientLogin(email=>...);
    
    my $yt   = new WebService::GData::YouTube($auth);
    
       $yt->add_video_response('video_id','video_response_id');


=head3 delete_video_response

B<Parameters>

=over 4

=item C<video_id:Scalar> the video id that was responsed to

=item C<video_response_id:Scalar> the video id of the response

=back

B<Returns>

=over

=item L<void> 

=back

B<Throws>

=over 4

=item L<WebService::GData::Error> 

=back

Example:


    my $auth = new WebService::GData::ClientLogin(email=>...);
    
    my $yt   = new WebService::GData::YouTube($auth);
    
       $yt->delete_video_response('video_id','video_response_id');
       

=back


=head2 FACTORY METHODS

=over

These methods instantiate YouTube::Feed::* packages. It just saves some typing.

=head3 video

Return a L<WebService::GData::YouTube::Feed::Video> instance
 
=head3 comment

Return a L<WebService::GData::YouTube::Feed::Comment> instance

=head3 playlists
 
Return a L<WebService::GData::YouTube::Feed::PlaylistLink> instance

=head3 complaint
 
Return a L<WebService::GData::YouTube::Feed::Complaint> instance

=head3 contact
 
Return a L<WebService::GData::YouTube::Feed::Friend> instance

=head3 message
 
Return a L<WebService::GData::YouTube::Feed::VideoMessage> instance

Example:
    
    use constant KEY=>'...';
        
    my $auth; 
    eval {
        $auth = new WebService::GData::ClientLogin(
           email=>'...@gmail.com',
           password=>'...',
           key=>KEY
       );
    };     
    
    my $yt = new WebService::GData::YouTube($auth);
    
    #instantiate a comment
    my $comment = $yt->comment;

       $comment->content('thank you all for watching!');
       $comment->video_id('2lDekeCDD-J1');#attach the comment to a video
       $comment->save;
       
    #instantiate a video
    my $video = $yt->video;  
     
       $video->title('Live at Shibuya tonight');
       $video->description('Live performance by 6 local bands.');
       $video->keywords('music','live','shibuya','tokyo');
       $video->category('Music');
    #etc
         
=back


=head2 USER PROFILE RELATED METHODS

=head3 get_user_profile

=over

Get the user profile info for the logged in user or the user set as a parameter.

B<Parameters>

=over 4

=item C<user_name:Scalar> (optional) - the user name/channel name

=back

B<Returns>

=over 4

=item L<WebService::GData::YouTube::Feed::UserProfile> instance


=back

B<Throws>

=over 4 

=item L<WebService::GData::Error> 

=back

Example:

    use WebService::GData::ClientLogin;
    use WebService::GData::YouTube;

    my $auth = new WebService::GData::ClientLogin(email=>...);
    
    my $yt   = new WebService::GData::YouTube($auth);
    
    my $profile = $yt->get_user_profile;
    
    #or if you did not pass a $auth object:
    my $profile = $yt->get_user_profile('profile_name_here');    

=back

=head3 get_user_contacts

=over

Get the user contact info for the logged in user or the user set as a parameter.
A maximum of 100 contacts can be retrieved.

B<Parameters>

=over 4

=item C<user_name:Scalar> (optional) - the user name/channel name

=back

B<Returns>

=over 4

=item L<WebService::GData::Collection> instance containing L<WebService::GData::YouTube::Feed::Friend> instances


=back

B<Throws>

=over 4 

=item L<WebService::GData::Error> 

=back

Example:

    use WebService::GData::ClientLogin;
    use WebService::GData::YouTube;

    my $auth = new WebService::GData::ClientLogin(email=>...);
    
    my $yt   = new WebService::GData::YouTube($auth);
    
    my $contacts = $yt->get_user_contacts;
    
    #or if you did not pass a $auth object:
    my $contacts = $yt->get_user_contacts('profile_name_here');    

=back

=head3 get_user_inbox

=over

Get the user inbox for the logged in user.

B<Parameters>

=over 4

=item C<none>

=back

B<Returns>

=over 4

=item L<WebService::GData::Collection> instance containing L<WebService::GData::YouTube::Feed::VideoMessage> instances


=back

B<Throws>

=over 4 

=item L<WebService::GData::Error> 

=back

Example:

    use WebService::GData::ClientLogin;
    use WebService::GData::YouTube;

    my $auth = new WebService::GData::ClientLogin(email=>...);
    
    my $yt   = new WebService::GData::YouTube($auth);
    
    my $messages = $yt->get_user_inbox;
    
    foreach my $message (@$messages){
    	say $message->subject;
    	say $message->content;
    	say $message->from->name;
    	say $message->sent;
    } 

=back

=head2 USER PLAYLIST METHODS

=over

!WARNING! Playlits related methods does not work perfectly yet!!

These methods allow you to access the videos in a playlist or a list of playlists created by a user.
If you are logged in, you will be able to modify the data.
If you are not logged in,you will only have a read access and you must set the user name.

=back

=head3 get_user_playlist_by_id

=over

Retrieve the videos in a playlist by passing the playlist id.

B<Parameters>

=over 4

=item C<playlist_id:Scalar> - the id of the playlist, looks like 'CFESE01KESEQE'

=back

B<Returns>

=over 4

=item L<WebService::GData::YouTube::Feed::Playlist>

A L<WebService::GData::YouTube::Feed::Playlist> contains the same information as a L<WebService::GData::YouTube::Feed::Video> instance

but adds the position information of the video within the playlist.

=back

B<Throws>

=over 4

=item L<WebService::GData::Error> 

=back

Example:


    my $auth = new WebService::GData::ClientLogin(email=>...);#not compulsory
    
    my $yt   = new WebService::GData::YouTube($auth);
    
    my $videos_in_playlist = $yt->get_user_playlist_by_id('CFESE01KESEQE');
    
    #a feed returns by default up to 25 videos. 
    #you can loop over the entire playlist (if you have more than 25 videos)
    #if your playlist contains more than 50 videos, you can set the query limit to be 50
    #it will result in less calls to the server.
    
    while(my $videos = $yt->get_user_playlist_by_id('CFESE01KESEQE')){
    	
    	foreach my $video (@$videos) {
    		say $video->title;
    	}
    }
	
=back


=head3 get_user_playlists

=over

Get the playlists metadata for the logged in user or the user set as a parameter.

B<Parameters>

=over 4

=item C<user_name:Scalar> (optional) - the user name/channel name

=back

B<Returns>

=over 4

=item L<WebService::GData::YouTube::Feed::PlaylistLink> objects

If you are logged in, you can access private playlists.

L<WebService::GData::YouTube::Feed::PlaylistLink> is a list of playlists. 
If you want to modify one playlist metadata, you must get them all, loop until you find the one you want and then edit.

=back

B<Throws>

=over 4 

=item L<WebService::GData::Error> 

=back

Example:

    use WebService::GData::Base;

    my $auth = new WebService::GData::ClientLogin(email=>...);
    
    my $yt   = new WebService::GData::YouTube($auth);
    
    my $playlists = $yt->get_user_playlists;
	
    #or if you did not pass a $auth object:
    my $playlists = $yt->get_user_playlists('live');	
    
    #a feed returns by default up to 25 entries/playlists. 
    #you can loop over the channel playlists (if you have more than 25 playlists)
    #if your channels contains more than 50 playlists, you can set the query limit to be 50
    #it will result in less calls to the server.    
    
    #this is a working example 
    #list all the programming related tutorials from thenewboston channel:
    my $yt = new WebService::GData::YouTube(); 
       $yt->query->max_results(50);
       
    my $playlist_counter=1;
    while(my $playlists = $yt->get_user_playlists("thenewboston")) {

        foreach my $playlist (@$playlists) {
            say($playlist_counter.':'.$playlist->title);
            
            my $video_counter=1;
            while(my $videos = $yt->get_user_playlist_by_id($playlist->playlist_id)) {
            	foreach my $vid (@$videos){
                say(" ".$video_counter.':'.$vid->title);
                $video_counter++;
            	}
            }
        }
        $playlist_counter++;
    }

=back


=head2  HANDLING ERRORS

Google data APIs relies on querying remote urls on particular services.
Some of these services limits the number of request with quotas and may return an error code in such a case.
All queries that fail will throw (die) a L<WebService::GData::Error> object. 
You should enclose all code that requires connecting to a service within eval blocks in order to handle it.


Example:

    use WebService::GData::Base;

    my ($auth,$videos);

    eval {
        $auth = new WebService::GData::ClientLogin(email=>...);
    };
    
    my $yt   = new WebService::GData::YouTube($auth);
    
    #the server is dead or the url is not available anymore or you've reach your quota of the day.
    #boom the application dies and your program fails...

    my $videos = $yt->get_user_videos;

    #with error handling...

    #enclose your code in a eval block...
    eval {
        $videos = $yt->get_user_videos;
    }; 

    #if something went wrong, you will get a WebService::GData::Error object back:

    if(my $error = $@){

        #do whatever you think is necessary to recover (or not)
        #print/log: $error->content,$error->code
    }	


=head2  TODO

Many things are left to be implemented!

The YouTube API is very thorough and it will take some time but by priority:

=over 4

=item * OAuth authorization system

=item * Channel search

=item * Playlist search

=item * know the status of a video

=item * Partial Upload

=item * Partial feed read/write

=back

Certainly missing many other stuffs...

=head1  DEPENDENCIES

=over

=item L<JSON>

=item L<LWP>

=back

=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

shiriru E<lt>shirirulestheworld[arobas]gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
