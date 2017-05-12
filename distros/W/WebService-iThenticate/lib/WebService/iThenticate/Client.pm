package WebService::iThenticate::Client;

use strict;
use warnings;

our $VERSION = 0.16;

use constant DEFAULT_URL => 'https://test.api.ithenticate.com/rpc';    ## no critic

use URI;
use RPC::XML::Client;
use WebService::iThenticate::Request;
use WebService::iThenticate::Response;

=head1 NAME

WebService::iThenticate::Client - a client class to access the iThenticate service

=head1 SYNOPSIS

 # construct a new client
 $client = WebService::iThenticate::Client->new({
     username => $username,
     password => $password,
     url     => 'https://api.ithenticate.com:443/rpc', # default https://test.api.ithenticate.com:443/rpc
 });

 # authenticate the client, returns an WebService::iThenticate::Response object
 $response = $client->login;

 # access the session id from the response object
 $sid = $response->sid;

 # submit a document
 $response = $client->add_document({
     title               => 'Moby Dick',
     author_first        => 'Herman',
     author_last         => 'Melville',
     filename            => 'moby_dick.doc',
     folder              => 72,    # folder id
     submit_to           => 1,     # 1 => 'Generate Report Only'
     upload              => `cat moby_dick.doc`, # binary content of document
                                             # the client module will base64 and chunk it
     non_blocking_upload => 1,
 });

 # get the newly created document id
 $document_id = $response->id;
 $document    = $response->document;

 # get the document parts (note use of hash reference instead of object method)
 $parts = $document->{parts};

=head1 DESCRIPTION

This module provides a client library interface to the iThenticate API web
services.  It encapsulates different transport engines to provide a set
of methods through which the user can access the iThenticate API programmatically.

See the iThenticate API reference web page at http://www.ithenticate.com/faq.html
for more details.

=head1 METHODS

=head2 CONSTRUCTORS AND AUTHENTICATION

=over 4

=item new()

 # construct a new client
 $client = WebService::iThenticate::Client->new({
     username => $username,
     password => $password,
     host     => 'api.ithenticate.com', # default test.api.ithenticate.com
     path     => 'rpc',                 # default rpc
     port     => 3000,                  # default 3000
 });

 Returns an WebService::iThenticate::Response object

=cut

sub new {
    my ( $class, $args_ref ) = @_;

    # need some auth credentials to proceed
    die 'username needed to create new client object' unless $args_ref->{username};
    die 'password needed to create new client object' unless $args_ref->{password};

    # don't allow RPC::XML::Client to make use of Compress::Zlib
    # Bill Moseley: related to https://rt.cpan.org/Public/Bug/Display.html?id=53448
    local $RPC::XML::Client::COMPRESSION_AVAILABLE = q{};

    # set defaults
    my $url = $args_ref->{url} || DEFAULT_URL;

    # canonicalize the url
    $url = URI->new( $url )->canonical;
    die "invalid url $url\n" unless $url;

    # create a new rpc client
    my $rpc_client = RPC::XML::Client->new( $url );
    die "unable to create rpc client from url $url" unless $rpc_client;

    # make an object
    my %self;
    bless \%self, $class;

    # stash the auth object
    $self{auth} = {
        username => $args_ref->{username},
        password => $args_ref->{password},
    };

    # stash the rpc object
    $self{rpc_client} = $rpc_client;

    return \%self;
} ## end sub new


=item credentials()

 # pass basic auth credentials to the client
 $client->credentials({
     realm    => 'My Authenticated Realm',
     username => 'foo@example.com',
     password => 'zimzamfoo123',
 });

=cut

sub credentials {
    my ( $self, $args ) = @_;

    my $realm    = $args->{realm}    || die 'no realm';
    my $username = $args->{username} || die 'no username';
    my $password = $args->{password} || die 'no password';

    return $self->{rpc_client}->credentials( $realm, $username, $password );
}


=item login()

 # authenticate the client, returns an WebService::iThenticate::Response object
 $response = $client->login;

 # access the session id from the response object
 $sid = $response->sid;

The session id (sid) is stored internally in the client for future 
authentication so there is no need to pass it explicitly

=cut

sub login {
    my $self = shift;

    # we don't use _dispatch_request here because we set the sid as the authentication token

    my $request = WebService::iThenticate::Request->new( {
            method => 'login',
            auth   => $self->{auth},
    } );

    die 'unable to create login request' unless $request;

    my $response = $self->_make_request( $request );

    # check for errors
    return $response if $response->errors;

    if ( my $sid = $response->sid ) {

        # successful login, stash the sid for future auth
        $self->{auth} = $sid;
    }

    return $response;
} ## end sub login

=back

=head2 FOLDER GROUPS

=over 4

=item add_folder_group()

 # add a folder group
 $response = $client->add_folder_group({
     name => 'iThenticate',
 });

 $folder_group_id = $response->id;

=cut

sub add_folder_group {
    my ( $self, $args ) = @_;

    return $self->_dispatch_request( 'group.add', $args );
}

=item list_folder_groups()

 # list folder groups
 $response = $client->list_folder_groups;

 # returns an array reference of hash references holding the folder group data owned by the api user
 $folder_groups = $response->groups;

 # Example response data:
 # $folder_groups->[0] = { id => 1, name => 'First Folder Group' };

=cut

sub list_folder_groups {
    return shift->_dispatch_request( 'group.list' );
}


=item group_folders()

 # returns all the folders in a group
 $response = $client->group_folders({ id => $folder_group_id });

 # returns an array reference of folder hashes
 $folders = $response->folders;

 # Example response data:
 # $folders->[0] = { id => 1, 
 #                   name => 'First Folder',
 #                   group => { 
 #                       id    => 1, 
 #                       name  => 'First Folder Group', }, };

=cut

sub group_folders {
    my ( $self, $args ) = @_;

    return $self->_dispatch_request( 'group.folders', $args );
}


=item drop_group()

 # remove a folder group
 $response = $client->drop_group({ id => $folder_group_id });

 # Returns a message on successful response, with no errors
 if (!$response->errors && 
     $response->messages->[0] eq "Group \"$folder_group_id\" removed") {
     print "Group $folder_group_id dropped successfully\n";
 }


=cut

sub drop_group {
    my ( $self, $args ) = @_;

    return $self->_dispatch_request( 'group.drop', $args );
}


=back

=head2 FOLDERS

=over 4

=item add_folder()

 # add a folder
 $response = $client->add_folder({
     name           => 'API Specification',
     description    => 'Holds documentation referencing the iThenticate API',
     folder_group   => 79, # id of the folder group
     exclude_quotes => 1,  # 1 (true), or 0 (false)
     add_to_index   => 1,  # 1 (true), or 0 (false), needed if account has
	                       # a private storage node
 });

 # returns the id of the newly created folder
 $folder_id = $response->id;

=cut

sub add_folder {
    my ( $self, $args ) = @_;

    return $self->_dispatch_request( 'folder.add', $args );
}

=item get_folder()

 # get a folder and related documents
 $response = $client->get_folder({ id => $folder_id });

 # see group_folders() for folder response data format
 $folder = $response->folder;

 # get the documents for this folder
 $documents = $response->documents;

 # Example document data
 # $documents->[0] = { author_first   => 'Jules', author_last   => 'Varne',
 #                     is_pending     => 1,       percent_match => '83.2',
 #                     processed_time => '94.3',  title         => '10,000 Leagues Over The Sea',
 #                     parts          => $parts,  uploaded_time  => '2008-03-13 07:35:35 PST',
 #                     id    => 1, };

 # Example document parts data
 # $parts->[0] = { part_id => 1, doc_id => 1, score => '95.2', word => 456, };

=cut

sub get_folder {
    my ( $self, $args ) = @_;

    return $self->_dispatch_request( 'folder.get', $args );
}

=item list_folders()

 # returns all the folders for a user
 $response = $client->list_folders();

 # returns an array reference of folder hashes
 $folders = $response->folders;

 # see get_folder() for the response folder data example

=cut

sub list_folders {
    my ( $self, $args ) = @_;

    return $self->_dispatch_request( 'folder.list', $args );
}



=item trash_folder()

 # move a folder to the trash
 $response = $client->trash_folder({ id => $folder_id });

 print "Folder trashed ok!" if ( !$response->errors && 
                                 $response->messages->[0] eq 'Moved to Trash' );

=cut

sub trash_folder {
    my ( $self, $args ) = @_;

    return $self->_dispatch_request( 'folder.trash', $args );
}

=back

=head2 DOCUMENTS

=over 4

=item add_document()

 # submit a document
 $response = $client->add_document({
     title           => 'Moby Dick',
     author_first    => 'Herman',
     author_last     => 'Melville',
     filename        => 'moby_dick.doc',

     # binary content of document
     # the client module will base64 and chunk it
     # note - don't actually use backticks like shown here :)
     upload          => `cat moby_dick.doc`,

     folder          => 72,    # folder id

     # options 2 and 3 only available for accounts with private nodes
     submit_to       => 1,     # 1 => 'Generate Report Only'
                               # 2 => 'to Document Repository Only'
                               # 3 => 'to Document Repository & Generate Report'

     # use the non-blocking upload option (this method returns faster)
     non_blocking_upload => 1,
 });

 # get the newly created document id
 $document_id = $response->id;
 $document = $response->document;

 # see get_folder() for the response data format for the document

=cut

sub add_document {
    my ( $self, $args ) = @_;

    $args->{uploads}->[0] = RPC::XML::struct->new( {
            title        => RPC::XML::string->new( delete $args->{title} ),
            author_first => RPC::XML::string->new( delete $args->{author_first} ),
            author_last  => RPC::XML::string->new( delete $args->{author_last} ),
            filename     => RPC::XML::string->new( delete $args->{filename} ),
            upload       => RPC::XML::base64->new( delete $args->{upload} ), } );

    return $self->_dispatch_request( 'document.add', $args, 1 );
}


=item get_document()

 # check the status of a document submission
 $response = $client->get_document({
    id => $document_id,
 });

 # access the document attributes from the response
 $document_id   = $response->id;

 # returns an array reference of document part hash references
 $document_parts = $document->{parts};

 # see get_folder() for the document and document parts data formats

=cut

sub get_document {
    my ( $self, $args ) = @_;

    return $self->_dispatch_request( 'document.get', $args );
}

=item trash_document()

 # move a document to the trash
 $response = $client->trash_document({ id => $document_id });

=cut

sub trash_document {
    my ( $self, $args ) = @_;

    return $self->_dispatch_request( 'document.trash', $args );
}

=back

=head2 REPORTING

=over 4

=item get_report()

 # get an get report
 $response = $client->get_report({
     id                   => $document_part_id,
 });

 # see if the report is ready
 if ( $response->errors && ( $response->status == 404 ) ) {

    # the report may still be in progress
    if ( $response->messages->[0] =~ m/report in progress/i ) {
        print "Report is still being prepared, please try later\n";
    } else {
        print STDERR "Report not found found document part $document_part_id\n";
    }

 } else {

    # report is ready, see WebService::iThenticate::Response for report object details
    $report = $response->report;

    $report_url = $report->{view_only_url};

    # save the report content to disk
    $grab_report = `wget --output-document=$HOME/reports/new.html $report_url`;
 }

=cut

sub get_report {
    my ( $self, $args ) = @_;

    return $self->_dispatch_request( 'report.get', $args );
}

=back

=head2 ACCOUNTS

=over 4

=item get_account()

 # get the account status
 $response = $client->get_account;

 $account_status = $response->account_status;

=cut

sub get_account {
    return shift->_dispatch_request( 'account.get' );
}

=back

=head2 USERS

=over 4

=item add_user()

 # add a user
 $response = $client->add_user({
     first_name => 'Joe',
     last_name  => 'User',
     email      => 'joe@user.com',
     password   => 'swizzlestick123',
 });

 $user_id = $response->id;

=cut

sub add_user {
    my ( $self, $args ) = @_;

    return $self->_dispatch_request( 'user.add', $args );
}

=item put_user()

  # update a user's information
  $response = $client->put_user({
      email => 'joeuser@gmail.com',
  });

  if ( $response->messages->[1] eq 'Email updated for user joeuser@gmail.com' ) {
      print 'got the right message';
  }

=cut

sub put_user {
    my ( $self, $args ) = @_;

    return $self->_dispatch_request( 'user.put', $args );
}

=item drop_user()

 # delete a user from the account
 $response = $client->drop_user({ id => $user_id });

 print 'some errors occurred' if $response->errors;

=cut

sub drop_user {
    my ( $self, $args ) = @_;

    return $self->_dispatch_request( 'user.drop', $args );
}

=item list_users()

 # users listing
 $response = $client->list_users;

 # returns a an array reference of user data in hashes
 $users = $response->users;

 # Example user data format
 # $users->[0] = { id => 1,               email => 'jules@varne.com',
 #                 first_name => 'Jules', last_name => 'Varne', };

=cut

sub list_users {
    return shift->_dispatch_request( 'user.list' );
}



# internal dispatch method to dispatch common requests

sub _dispatch_request {
    my ( $self, $method, $args, $novalidate ) = @_;

    my $request = WebService::iThenticate::Request->new( {
            method     => $method,
            auth       => { sid => $self->{auth} },
            req_args   => $args,
            novalidate => $novalidate,
    } );

    die "unable to create $method request" unless $request;

    my $response = $self->_make_request( $request );

    return $response;
}

# internal dispatch method which makes the request based
# on what transport mechanism we are using, rpc, soap, etc.

sub _make_request {
    my ( $self, $request ) = @_;

    die 'need a request object' unless $request;

    my $response = $self->{rpc_client}->send_request( $request->{rpc_request} );

    # When no connection can be made RPC::XML returns a string (error)
    if ( ref( \$response ) eq 'SCALAR' ) {
        die "Error: $response\n";
    }

    # else check for RPC::XML::fault
    elsif ( $response->isa( 'RPC::XML::fault' ) ) {
        require Data::Dumper;
        die sprintf( "Error code:  %s\nError string:  %s\nRequest object:  %s\n",
            $response->{faultCode}->value, $response->{faultString}->value,
            Data::Dumper::Dumper( $request ), );

        # if it isn't a fault and not a struct it is an unknown error
    } elsif ( ref( $response ) ne 'RPC::XML::struct' ) {

        # unknown response
        require Data::Dumper;
        die 'unknown response returned, unable to handle: ' . Data::Dumper::Dumper( $response );
    }

    # at this point we have a valid response
    # transform the response to an object
    my $ithenticate_response = WebService::iThenticate::Response->_new( $response );    ## no critic

    return $ithenticate_response;
} ## end sub _make_request


=back



=head1 TESTING

To enable testing against the iThenticate live test API, set the following
environment variables before running 'make test'.

IT_USERNAME
IT_PASSWORD
IT_API_URL

See your iThenticate account representative to obtain these credentials
to the API testing environment.

=head1 BUGS

=over 4

=item IT_API_URL

If you receive an error back from the server that looks like 'mismatched tag'
then you likely have an invalid url specified for IT_API_URL instead of an
actual mismatched tag in the request xml.

=back

=head1 FAQ

Q:  Why doesn't this code do X?

A:  Because that feature hasn't been requested yet :)

Q:  How is this module related to iThenticate::API::Client?

A:  This module takes the place of iThenticate::API::Client in a more
    generally accepted namespace

=head1 SEE ALSO

WebService::iThenticate::Request, WebService::iThenticate::Response, RPC::XML, SOAP::Lite

=head1 AUTHOR

Fred Moyer <fred@iparadigms.com>

=head1 COPYRIGHT


Copyright (C) (2011) iParadigms, LLC.  All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have available.

=cut

1;
