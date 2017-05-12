package WebService::GData::YouTube::Feed::Friend;

use WebService::GData;
use base 'WebService::GData::Feed::Entry';
use WebService::GData::Constants qw(:all);
use WebService::GData::YouTube::Constants qw(:all);
use WebService::GData::YouTube::YT::Username ();
use WebService::GData::YouTube::YT::Status ();
use WebService::GData::YouTube::StagingServer ();

our $VERSION = 0.01_01;

our $BASE_URI       = BASE_URI . PROJECTION . '/users/';
our $WRITE_BASE_URI = $BASE_URI;

our $SCHEME ='http://gdata.youtube.com/schemas/2007/contact.cat';

if(WebService::GData::YouTube::StagingServer->is_on){
  $WRITE_BASE_URI  = STAGING_BASE_URI . PROJECTION . '/users/';  
}

sub __init {
    my ( $this, $feed, $req ) = @_;

    if ( ref($feed) eq 'HASH' ) {
        $this->SUPER::__init( $feed, $req );
    }
    else {
        $this->SUPER::__init( {}, $feed );#$feed ==$req here
    }
    $this->{_username}= new WebService::GData::YouTube::YT::Username($this->{_feed}->{'yt$username'});
    $this->{_status}= new WebService::GData::YouTube::YT::Status($this->{_feed}->{'yt$status'});
    $this->_entity->child($this->{_username})->child($this->{_status});
    
}

sub delete {
    my $this = shift;
        my $uri =
      @{ $this->links->rel('edit') } > 0
      ? $this->links->rel('edit')->[0]->href
      : $WRITE_BASE_URI . 'default/contacts/'.$this->username;
    $this->{_request}->delete( $uri );
}

sub update {
    my $this = shift;

    if ( $this->username ) {
        my $content= XML_HEADER . $this->serialize();
        my $ret =$this->{_request}->insert( $WRITE_BASE_URI .  'default/contacts/'.$this->username, $content );
        return $ret;
    }
}

sub save {
	my $this = shift;

	if ( $this->username ) {
		my $content= XML_HEADER . $this->serialize();
		my $ret =$this->{_request}->insert( $WRITE_BASE_URI .  'default/contacts/', $content );
		return $ret;
	}
}

"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::YouTube::Feed::Friend - a user contact list (read/write) for data API v2.

=head1 SYNOPSIS

    use WebService::GData::YouTube;
    
    use constant KEY=>'...';
        
    my $auth; 
    eval {
        $auth = new WebService::GData::ClientLogin(
           email=>...@gmail.com',
           password=>'...',
           key=>KEY
       );
    };   
    
    #adding a contact
    
    #instantiate a $contact
    my $contact = new WebService::GData::YouTube($auth)->contact;
    
    #set a friend 
    $contact->username('google');
    
    #add it as a friend
    eval {
        $contact->save();
    };
    if(my $error = $@){
        say $error->code;
    }  
    
    #deleting/updating contacts
    
    #instantiate a $contact
    my $contacts = new WebService::GData::YouTube($auth)->get_user_contacts;
    
    foreach my $contact (@$contacts){
    	if($contact->username() eq 'devil'){
    		$contact->delete;
    	}
        if($contact->username() eq 'spammy'){
            $contact->status('rejected');
            $contact->update;
        }    	
    }
     

=head1 DESCRIPTION

!WARNING! Documentation in progress.

!DEVELOPER RELEASE! API may change, program may break or be under optimized and I haven't done a full range of tests yet!


I<inherits from L<WebService::GData::Feed::Entry>.

This package represents a Youtube Friend or Contact. 

You can access this kind of information without being logged in but you will need to be authorized to edit/delete or add new contacts.


Most of the time you will not instantiate this class directly but use the contact method in the L<WebService::GData::YouTube> class.

=head2 CONSTRUCTOR


=head3 new

=over

Create a L<WebService::GData::YouTube::Feed::Contact> instance. 

B<Parameters>:

=over

=item C<jsonc_video_entry_feed:Object> (Optional)

=item C<authorization:Object> (Optional)

or 

=item C<authorization:Object> (Optional)

=back

If an authorization object is set (L<WebService::GData::ClientLogin>), 

it will allow you to insert/delete/update new contacts.

=back    

=head2 INHERITED METHODS

All the following read only methods give access to the information contained in a contact feed entry.

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


=head2 GENERAL SET/GET METHODS

=head3 username

=over

The username of the contact as in its profile.

   
=back

=head3 status

=over

Specifies if the contact is accepted,pending or requested.

See L<http://code.google.com/intl/en/apis/youtube/2.0/developers_guide_protocol_contacts.html#Retrieve_contacts>
  
=back


=head2 QUERY METHODS

This method actually query the service to save your data.
You must be logged in programmaticly to be able to use them.

=head3 save

=over

The save method requires a username to be set.

=back

=head3 update

=over

The update method requires a username to be set.
(either you set it with the username method or you get the edit link by querying the feed).

=back

=head3 delete

=over

The delete method requires a username to be set.
(either you set it with the username method or you get the edit link by querying the feed).

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
