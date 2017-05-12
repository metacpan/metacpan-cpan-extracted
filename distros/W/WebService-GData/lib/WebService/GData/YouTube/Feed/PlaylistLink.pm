package WebService::GData::YouTube::Feed::PlaylistLink;

use WebService::GData 'private';
use base 'WebService::GData::Feed::Entry';
use WebService::GData::Constants qw(:all);
use WebService::GData::YouTube::Constants qw(:all);
use WebService::GData::YouTube::StagingServer ();
use WebService::GData::Node::Atom::Category();
use WebService::GData::Collection();

our $VERSION = 0.01_03;

our $PROJECTION = WebService::GData::YouTube::Constants::PROJECTION;
our $BASE       = WebService::GData::YouTube::Constants::BASE_URI;
if(WebService::GData::YouTube::StagingServer->is_on){
  $BASE         = STAGING_BASE_URI;
}
our $PLAYLISTS_URI = $BASE . $PROJECTION . '/users/default/playlists/';
#####READ##############

sub __init {
	my ( $this, $feed, $req ) = @_;

	return $this->SUPER::__init( $feed, $req ) if ref $feed eq 'HASH';

	$this->SUPER::__init( {}, $feed );

}

sub count_hint {
	my $this = shift;
	$this->{_feed}->{'yt$countHint'}->{'$t'};
}

sub playlist_id {
	my $this = shift;
	if ( @_ == 1 ) {
		$this->{_feed}->{'yt$playlistId'}->{'$t'} = $_[0];
	}
	$this->{_feed}->{'yt$playlistId'}->{'$t'};
}

sub is_private {
	my $this = shift;

	if ( exists $this->{_feed}->{'yt$private'} || ( @_ == 1 && !$this->{_private} ) ) {
		$this->{_private} = new WebService::GData::YouTube::YT::Private();
		$this->_entity->child( $this->{_private} );
		delete $this->{_feed}->{'yt$private'};
	}

	return ( exists $this->{_private} ) ? 1 : 0;
		
	
}

private urldecode => sub {
	my ($string) = shift;
	$string =~ tr/+/ /;
	$string =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	return $string;
};

sub keywords {
	my ( $this, $keywords ) = @_;

	if ($keywords) {

		#reset tags
		my $old = $this->{_category};

        $this->{_category} = new WebService::GData::Collection();

		$this->_entity->swap( $old,$this->{_category});

		my @tags = split( /,/, $keywords );

		foreach (@tags) {
			push @{ $this->category },
			  new WebService::GData::Node::Atom::Category(
				term   => $_,
				scheme => 'http://gdata.youtube.com/schemas/2007/tags.cat'
			  );
		}
	}

	my @terms;
	push @terms, urldecode( $_->term )
	  foreach ( @{ $this->category->scheme('tags.cat') } );
	return join ',', @terms;
}

#####WRITE###########

sub delete {
	my $this = shift;
	$this->{_request}->delete( $PLAYLISTS_URI . $this->playlist_id );
}

sub save {
	my $this = shift;

	my $content = XML_HEADER . $this->serialize;
	my $ret;
	if ( $this->playlist_id ) {
		$ret =
		  $this->{_request}->update( $this->get_link('edit')
			  || $PLAYLISTS_URI . $this->playlist_id, $content );
	}
	else {
		$ret = $this->{_request}->insert( $PLAYLISTS_URI, $content );
	}
	return $ret;
}

sub add_video {
	my ($this,$video_id) = @_;
	
	$this->id($video_id);
	
	my $content = XML_HEADER. $this->serialize;
	
	return $this->{_request}->insert('http://gdata.youtube.com/feeds/api/playlists/'.$this->playlist_id,$content);
}


#sub delete_video {
#	my ($this,%params) = @_;
#	if($params{videoId}) {
#		$params{playListVideoId}=$this->_find_playlist_video_id($params{videoId});
#	}
#	$this ->{_request}->delete('http://gdata.youtube.com/feeds/api/playlists/'.$this->playlistId.'/'.$params{playListVideoId},0);
#}
#	sub set_video_position {
#		my ($this,%params) = @_;
#		if($params{videoId}) {
#			$params{playListVideoId}=$this->_find_playlist_video_id($params{videoId});
#		}
#		$this->{_request}->update('http://gdata.youtube.com/feeds/api/playlists/'.$this->playlistId.'/'.$params{playListVideoId},"<yt:position>$params{position}</yt:position>");
#	}
#	sub _find_playlist_video_id {
#		my ($this,$videoid) = @_;

#		my $id="";
#		if(!$this->{videosInPlaylist}){
#			$this->get_videos;
#		}
#		foreach my $vid (@{$this->{videosInPlaylist}}){
#			if($vid->videoId eq $videoid){
#				$id= (split(':',$vid->id))[-1];
#			}
#		}
#		return $id;
#	}

"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::YouTube::Feed::PlaylistLink - playlists meta data (read/write) for data API v2.

=head1 SYNOPSIS

    use WebService::GData::YouTube;
    
    use constant KEY=>'...';
        
    my $auth; 
    eval {
        $auth = new WebService::GData::ClientLogin(
            email=>'...',
            password=>'...',
            key=>KEY
       );
    };     
    die $@->code,$@->content if $@;  
     
    my $yt = new WebService::GData::YouTube($auth);  
     
    #get logged in user playlists
    
    my $playlists;
    eval {
       $playlists = $yt->get_user_playlists; 
    };
    die $@->code,$@->content if $@;    

    #and list them:
    
    foreach my $playlist (@$playlists){
    	
      print $playlist->title;
      
      print $playlist->summary;
      
      print $playlist->keywords; 
      
      print $playlist->is_private;
      
      print $playlist->playlist_id;
      
    }


    #erase a specific playlist
    
    my $playlist = $yt->playlists;
       $playlist->playlist_id(q[9ED74863...A2B8]);
       $playlist->delete;
 

   #create a playlist

    my $playlist = $yt->playlists;    
 
    #set information about the playlist
    
    $playlist->title('testing something');
    $playlist->summary('new summary');
    $playlist->keywords("keyword1,keyword2"); 
    $playlist->is_private(1);
    
    eval {
        $playlist->save;
    };
    die $@->code,$@->content if $@;   

     



=head1 DESCRIPTION

!DEVELOPER RELEASE! API may change, program may break or be under optimized.

!WARNING! Documentation in progress.


I<inherits from L<WebService::GData::Feed::Entry>>.

This package represents a PlaylistLink which contains the meta information about playlists (title,description,keywords,etc). 

If you are logged in you can edit/erase existing playlist metadata,create a new playlist.

Most of the time you will not instantiate this class directly but use the helper in the L<WebService::GData::YouTube> class.


=head2 CONSTRUCTOR


=head3 new

=over

Create a L<WebService::GData::YouTube::Feed::PlaylistLink> instance. 

=back

B<Parameters>:

=over

=item C<jsonc_playlists_entry_feed:Object> (Optional)

=item C<authorization:Object> (Optional)

or 

=item C<authorization:Object> (Optional)

=back

If an authorization object is set (L<WebService::GData::ClientLogin>), 

it will allow you to access private contents and insert/edit/delete playlists.

=head2 GET METHODS

All the following read only methods give access to the information contained in a playlist feed.


=head3 count_hint


=head2 GENERAL SET/GET METHODS

All these methods represents the meta data of a playlist but you have read/write access on them.

It is therefore necessary to be logged in programmaticly to be able to use them in write mode 
(if not, saving the data will not work).

=head3 title

This will be the name of your playlist.

=head3 summary

This will be the explanation of the kind of content contained in this playlist.

=head3 keywords

Keywords representing the playlists. 

=head3 is_private

Only specific person can access this playlist if set to private.
      
=head3 playlist_id

The unique id of this playlist (usually required for edit/erase)


=head2 QUERY METHODS

These methods actually query the service to save your edits.

You must be logged in programmaticly to be able to use them.

=head3 delete

You must specify the playlist to erase by setting its unique id via playlist_id.

=head3 save

The save method will do an insert if there is no playlist_id or an update if there is one.

=head3 add_video
 
=over

Append an existing video into a playlist(query the API to insert the data, you must be logged in programmatically).

B<Parameters>

=over 

=item C<video_id:Scalar> - the video id to add

=back

B<Returns> 

=over 

=item void

=back

B<Throws>

=over 5

=item L<WebService::GData::Error> in case of an error

=back

Example:

   my $yt = new WebService::GData::YouTube($auth); 

   my $playlist = $yt->playlists;
   
   $playlist->playlist_id("playlist_id");
   $playlist->add_video("video_id");
   
   #or
   
   my $yt = new WebService::GData::YouTube($auth); 

   my $playlist = $yt->get_user_playlists()->[0];//example:the first playlist in the list 
      $playlist->add_video("video_id"); 
    
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
