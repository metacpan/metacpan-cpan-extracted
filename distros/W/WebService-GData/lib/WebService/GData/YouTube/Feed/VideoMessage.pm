package WebService::GData::YouTube::Feed::VideoMessage;

use WebService::GData;
use base 'WebService::GData::YouTube::Feed::Video';
use WebService::GData::Constants qw(:all);
use WebService::GData::YouTube::Constants qw(:all);

our $VERSION = 0.01_01;

our $BASE_URI = BASE_URI . PROJECTION . '/users/default/inbox';
if ( WebService::GData::YouTube::StagingServer->is_on ) {
	$BASE_URI = STAGING_BASE_URI . PROJECTION . '/users/default/inbox';
}

sub subject {
	my ( $this, $title ) = @_;
	$this->{_title}->text($title) if $title;
	return $this->{_title}->text;
}

#alias
sub from {
	shift()->author->[0];
}

#alias
sub sent {
	shift()->published;
}

sub send {
	my ( $this, @contacts ) = @_;

	my $ret;
	if ( $this->id ) {
		my $content = XML_HEADER . $this->serialize;
		foreach my $contact (@contacts) {
			( my $uri = $BASE_URI ) =~ s/default/$contact/;
			$ret = $this->{_request}->insert( $uri, $content );
		}
	}
	return $ret;
}

sub save {
	shift()->send(@_);
}

sub delete {
	my ( $this, $message_id ) = @_;
	my $uri;
	if ($message_id) {
		$uri =
		  ( $message_id =~ m/^http/ )
		  ? $message_id
		  : $BASE_URI . '/' . $message_id;
	}
	elsif ( @{ $this->links->rel('edit') } > 0 ) {
		$uri = $this->links->rel('edit')->[0]->href;
	}
	$this->{_request}->delete($uri) if $uri;
}

"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::YouTube::Feed::VideoMessage - a video message (read/write) for data API v2.

=head1 SYNOPSIS

    #list the video messages sent
    #you must be logged in

    use WebService::GData::YouTube;
    use WebService::GData::ClientLogin;
    
    my $auth;

    eval {
        $auth = new WebService::GData::ClientLogin(
            email    => '...',
            password => '...',
            key      => '...'
        );
    };
    if(my $error = $@){
        #$error->code,$error->content...
    }
    
    my $yt = new WebService::GData::YouTube($auth);
     
    my $messages = $yt->get_user_inbox();   
    foreach my $message (@$messages) {
        say $message->subject;  
        say $message->summary;
        say $message->sent;
        say $message->from->name;
        say $message->title;     #video title
        if($message->subject()=~m/SPAM/){
            $message->delete();
        }
    }
    
    #send a video message

    my $message = $yt->message;
    $message->summary('look at that!');
    $message->id('video_id_goes_here');
    $message->send('channel_name');
     



=head1 DESCRIPTION

!WARNING! Documentation in progress.

!DEVELOPER RELEASE! API may change, program may break or be under optimized and I haven't done a full range of tests yet!


I<inherits from L<WebService::GData::YouTube::Feed::Video>>.

This package represents a Youtube Video message than can be sent by your friends only. 
Most of the time, you will retrieve a list of messages and from there you should be able to apply a delete.

You can not access other kind of messages.

Most of the time you will not instantiate this class directly but use the message method in the L<WebService::GData::YouTube> class.

=back

=head2 CONSTRUCTOR


=head3 new

=over

Create a L<WebService::GData::YouTube::Feed::VideoMessage> instance. 

B<Parameters>:

=over

=item C<jsonc_video_entry_feed:Object> (Optional)

=item C<authorization:Object> (Optional)

or 

=item C<authorization:Object> (Optional)

=back

If an authorization object is set (L<WebService::GData::ClientLogin>), 

it will allow you to insert new messages.

=back

=head2 INHERITED METHODS

This class inherits from the Video class. 

Therefore all the video methods can be used to retrieve information about the video shared such as the ->title method.

=back
     

=head2 GENERAL GET METHODS

The following method wraps existing video methods used in the context of a video message.

=head3 subject

=over 

This returns the title tag which, in this context, is equal to the automaticly created mail title.
It contains the author name and the shared video title. 

You can not set the title when sending a message, only the content of the message.
 
=back

=head3 from

=over 

This returns the Author of the message. 
 
=back

=head3 sent

=over 

This returns the published tag which, in this context, is equal to the date the mail was sent. 
 
=back

=head2 GENERAL SET/GET METHODS

=head3 summary

=over

This is the message itself. The package does not encode,clean the data.
YouTube replaces HTML with html entities.
   
=back

=head3 video_id

=over

The video id you which to share.
  
=back


=head2 QUERY METHODS

This method actually query the service to save your data.
You must be logged in programmaticly to be able to use them.

=head3 save / send

=over

The save method will do an insert only if a video_id is set.

You must pass in the user name (several users name allowed)

    my $message = $yt->message;
       $message->summary('look at that!');
       $message->id('video_id_goes_here');
       $message->save('channel_name1','channel_name2');
       #or
       $message->send('channel_name1','channel_name2');       

=back

=head3 delete

=over

The delete method will actually erase a video message from the user inbox.

The method itself use internally the edit link found after retrieving a list of messages.

The usual flow is to get a list of all the messages

The user check the items to erase (the key should be an url:$message->links->rel('edit')->[0]->href)

You erase the message by passing the key:


    my $message = $yt->message;
       $message->delete($key); 
       
    #you can also retrieve a list of messages and erase them all, in which case,
    #you can loop other the result and call the delete() method:
       
    foreach my $message (@$messages) {
        $message->delete();
    }

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

