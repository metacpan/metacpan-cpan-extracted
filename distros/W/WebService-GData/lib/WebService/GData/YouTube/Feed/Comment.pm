package WebService::GData::YouTube::Feed::Comment;

use WebService::GData;
use base 'WebService::GData::Feed::Entry';
use WebService::GData::Constants qw(:all);
use WebService::GData::YouTube::Constants qw(:all);
use WebService::GData::Node::Atom::Link();
use WebService::GData::YouTube::StagingServer ();
our $VERSION = 0.01_04;

our $BASE_URI = BASE_URI . PROJECTION . '/videos/';
our $WRITE_BASE_URI = $BASE_URI;
our $RESPONSE_REL  = API_DOMAIN_URI . q[schemas/2007#in-reply-to];

if(WebService::GData::YouTube::StagingServer->is_on){
  $WRITE_BASE_URI        = STAGING_BASE_URI . PROJECTION . '/videos/';  
}


our $RESPONSE_TYPE = q[application/atom+xml];

sub __init {
    my ( $this, $feed, $req ) = @_;

    if ( ref($feed) eq 'HASH' ) {
        $this->SUPER::__init( $feed, $req );
    }
    else {
        $this->SUPER::__init( {}, $feed );#$feed ==$req here
    }
}

sub content {
	my ( $this, $comment ) = @_;
	$this->{_content}->text($comment) if $comment;
	$this->{_content}->text;
}

sub comment_id {
	my ($this) = @_;
	if ( $this->id ) {
		return ( split ':', $this->id )[-1];
	}
}

sub video_id {
	my ( $this, $id ) = @_;
	if ($id) {
		$this->{_video_id} = $id;
		return $id;
	}
	if ( ! ref $this->id) {
		$this->{_video_id} = ( split ':', $this->id )[-3];
	}
	return $this->{_video_id};
}

sub in_reply_to {
	my ( $this, $comment_id ) = @_;

	if ($comment_id) {
		$this->{_is_in_reply_to} = $comment_id;
		return $comment_id;
	}
	my $is_in_reply_to = $this->links->rel('#in-reply-to')->[0];
	if ($is_in_reply_to) {
		$this->{_is_in_reply_to} = ( split '/', $is_in_reply_to->href )[-1];
	}
	$this->{_is_in_reply_to};
}

sub save {
	my $this = shift;

	if ( $this->video_id ) {
		if ( $this->in_reply_to ) {
			$this->swap($this->{_link}, new WebService::GData::Node::Atom::Link(
				
				rel  => $RESPONSE_REL,
				type => $RESPONSE_TYPE,
				href => $BASE_URI.$this->video_id.'/comments/'.$this->in_reply_to
			  ));
		}
		my $content= XML_HEADER . $this->serialize();
		my $ret =$this->{_request}->insert( $WRITE_BASE_URI . $this->video_id . '/comments/', $content );
	}
}

"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::YouTube::Feed::Comment - a comment for a video (read/write) for data API v2.

=head1 SYNOPSIS

    #READ COMMENTS
    #query the comments for a video and loop other the results

    use WebService::GData::YouTube;
    
    my $yt = new WebService::GData::YouTube();    
    
    my $comments = $yt->get_comments_for_video_id('2lDekeCDD-J1');
    
    foreach my $comment (@$comments){
        say('-'x50);
        say($comment->content);#the comment
        say($comment->author->[0]->name);#the author name
        say($comment->comment_id);#the comment id
        say($comment->in_reply_to);#is this a comment in reply to an other comment?
    }
    
    #WRITE COMMENTS
    
    use constant KEY=>'...';
        
    my $auth; 
    eval {
        $auth = new WebService::GData::ClientLogin(
           email=>...@gmail.com',
           password=>'...',
           key=>KEY
       );
    };     
    
    #instantiate a comment
    my $comment = new WebService::GData::YouTube($auth)->comment;

       $comment->content('thank you all for watching!');
       $comment->video_id('2lDekeCDD-J1');#attach the comment to a video
       
       #you can set this to be a response to an other comment
       #you must however always set the video_id
       #$comment->in_reply_to('oHekdlwelkjgaQ');
       
    eval {
        $comment->save();
    };
    if(my $error = $@){
        print Dumper($error);
    }  
     



=head1 DESCRIPTION

!WARNING! Documentation in progress.

!DEVELOPER RELEASE! API may change, program may break or be under optimized and I haven't done a full range of tests yet!


I<inherits from L<WebService::GData::Feed::Entry>>.

This package represents a Youtube Comment. If you are logged in you can save new comments, create new comments in response to other ones.

You can not, however, edit or erase comments as it is not include in the YouTube API yet.

Most of the time you will not instantiate this class directly but use the comment method in the L<WebService::GData::YouTube> class.

=back

=head2 CONSTRUCTOR


=head3 new

=over

Create a L<WebService::GData::YouTube::Feed::Comment> instance. 

B<Parameters>:

=over

=item C<jsonc_video_entry_feed:Object> (Optional)

=item C<authorization:Object> (Optional)

or 

=item C<authorization:Object> (Optional)

=back

If an authorization object is set (L<WebService::GData::ClientLogin>), 

it will allow you to insert new comments.

=back

=head2 INHERITED METHODS

All the following read only methods give access to the information contained in a comment feed entry.

=over 

=head3 etag

=head3 updated

=head3 published

=head3 category

=head3 id

=head3 link

=head3 title 

=over 

The title is a small part of the content.

=back
  
=back     

=head2 GENERAL GET METHODS

The following method is an helper.

=head3 comment_id

=over 

It looks into the id to retrieve the comment id.
 
=back

=head2 GENERAL SET/GET METHODS

=head3 content

=over

This is the comment itself. The package does not encode,clean the data.
YouTube replaces HTML with html entities.
   
=back

=head3 video_id

=over

The video id to which you want to add a comment.
  
=back

=head3 in_reply_to

=over

It should be set to the comment id you want to reply to.
You can use this method to see if a comment is a response to an other comment.
  
=back


=head2 QUERY METHODS

This method actually query the service to save your data.
You must be logged in programmaticly to be able to use them.

=head3 save

=over

The save method will do an insert only if a video_id is set.

=back


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
