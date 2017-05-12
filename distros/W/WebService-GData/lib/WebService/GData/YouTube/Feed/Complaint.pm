package WebService::GData::YouTube::Feed::Complaint;

use WebService::GData;
use base 'WebService::GData::Feed::Entry';
use WebService::GData::Constants qw(:all);
use WebService::GData::YouTube::Constants qw(:all);
use WebService::GData::YouTube::StagingServer ();
our $VERSION = 0.01_01;

our $BASE_URI       = BASE_URI . PROJECTION . '/videos/';
our $WRITE_BASE_URI = $BASE_URI;

if(WebService::GData::YouTube::StagingServer->is_on){
  $WRITE_BASE_URI  = STAGING_BASE_URI . PROJECTION . '/videos/';  
}

sub __init {
    my ( $this, $feed, $req ) = @_;

    if ( ref($feed) eq 'HASH' ) {
        $this->SUPER::__init( $feed, $req );
    }
    else {
        $this->SUPER::__init( {}, $feed );#$feed ==$req here
    }
    push @{$this->category},{
    	term   => 'SPAM',
    	scheme => 'http://gdata.youtube.com/schemas/2007/complaint-reasons.cat'
    };
}

sub video_id {
	my ( $this, $id ) = @_;
	if ($id) {
		$this->{_video_id} = $id;
		return $id;
	}
	return $this->{_video_id};
}

sub reason {
    my ( $this, $reason ) = @_;
    if ($reason) {
        $this->category->[0]->term($reason);
    }
    return $this->category->[0]->term;	
}

sub save {
	my $this = shift;

	if ( $this->video_id ) {
		my $content= XML_HEADER . $this->serialize();
		my $ret =$this->{_request}->insert( $WRITE_BASE_URI . $this->video_id . '/complaints/', $content );
		return $ret;
	}
}

"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::YouTube::Feed::Complaint - add a complaint about a video (read/write) for data API v2.

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
    
    #instantiate a complaint
    my $complaint = new WebService::GData::YouTube($auth)->complaint;
    
    #attach the complaint to a video
    $complaint->video_id('2lDekeCDD-J1');
       
    $complaint->reason('VIOLENCE');#default to SPAM
    $complaint->summary('This is too violent to be displayed on YouTube...');
    
    #save
    eval {
        $complaint->save();
    };
    if(my $error = $@){
        say $error->code;
    }  
     

=head1 DESCRIPTION

!WARNING! Documentation in progress.

!DEVELOPER RELEASE! API may change, program may break or be under optimized and I haven't done a full range of tests yet!


I<inherits from L<WebService::GData::Feed::Entry>.

This package represents a Youtube Complaint. 

This is only a create object so you need to be logged in to use this package.

You can not, however, edit or erase complaints as this feature is not available yet.

Most of the time you will not instantiate this class directly but use the complaint method in the L<WebService::GData::YouTube> class.

=head2 CONSTRUCTOR


=head3 new

=over

Create a L<WebService::GData::YouTube::Feed::Complaint> instance. 

B<Parameters>:

=over

=item C<jsonc_video_entry_feed:Object> (Optional)

=item C<authorization:Object> (Optional)

or 

=item C<authorization:Object> (Optional)

=back

If an authorization object is set (L<WebService::GData::ClientLogin>), 

it will allow you to insert new complaint.

=back    

=head2 GENERAL SET/GET METHODS

=head3 reason

=over

By default, it is set to SPAM but you can set it to one of the available reasons:

    PORN 
    VIOLENCE 
    HATE 
    DANGEROUS 
    RIGHTS
    SPAM

See L<http://code.google.com/intl/en/apis/youtube/2.0/developers_guide_protocol_complaints.html>
   
=back

=head3 video_id

=over

The video id to which you want to add a complaint.
  
=back

=head3 summary

=over

It should contain some explanations on the complaints reason.
  
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
