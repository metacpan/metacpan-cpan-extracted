#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 157;
use Data::Dumper;

my $pkg;

BEGIN {
    $pkg = 'WebService::iThenticate::Client';
    use_ok( $pkg );
}

SKIP: {
    unless ( $ENV{IT_USERNAME} && $ENV{IT_PASSWORD} && $ENV{IT_API_URL} ) {
        warn( "\n\nSet IT_USERNAME, IT_PASSWORD, IT_API_URL for live testing\n\n" );
        skip 'Set environment vars IT_USERNAME, IT_PASSWORD, and IT_API_URL for testing against an iThenticate API', 156;
    }

    ############################################
    diag( 'test invalid connection' );
    my %args = (
        username => 'foo@example.com',
        password => 'bar',
        url      => 'http://localhost:1234/rpc',    # use a bogus url
    );
    my $client = $pkg->new( \%args );
    isa_ok( $client, $pkg );
    eval { $client->login };
    like( $@, qr/connection refused/i, 'connection should fail since no server at that port' );

    #################################################
    $args{'url'} = $ENV{IT_API_URL};                # use the correct url
    my $response;

    #############################################
SKIP: {
        skip 'the access handler is not working right now so skip this test for a test user without access', 4;
        diag( 'test api access' );
        $args{'username'} = 'api_test_user_no_access@test.api.ithenticate.com';
        $client = $pkg->new( \%args );
        eval { $response = $client->login };
        die "Are you sure the test server is operational?  Err: \n" . Dumper( $@ ) if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        is( $response->api_status, '401', 'should return a 401' );
        ok( !$response->errors->{password}, 'should be no password error since access is disallowed' );
        ok( !defined $response->sid,        'no sid present since access is disallowed' );
    }

    ############################################
    diag( 'test invalid username/password' );
    $args{'username'} = 'api_test_user@test.api.ithenticate.com';
    $client = $pkg->new( \%args );
    isa_ok( $client, $pkg );
    eval { $response = $client->login };

SKIP: {
        skip "Client could not login: $@" . $ENV{IT_API_URL}, 149 if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );

        ok( $response->errors,             'errors in response' );
        ok( $response->errors->{password}, 'password error' );
        is( $response->api_status, '500', '500 returned' );

        #############################################
        diag( 'try valid credentials' );
        $args{'password'} = $ENV{IT_PASSWORD};
        $args{'username'} = $ENV{IT_USERNAME};
        $client           = $pkg->new( \%args );
        isa_ok( $client, $pkg );

        $response = $client->login;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors,                                        'no errors in response' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        is( $response->api_status, '200', 'should return a 200' );
        cmp_ok( ref( \$response->sid ), 'eq', 'SCALAR', 'sid had better be a scalar ref' );

        ######################################################
        diag( 'create a folder group' );
        $response = eval { $client->add_folder_group( { name => $$ . '_test_group_' . int( rand( 1000 ) ), } ) }; ## no critic
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        like( $response->messages->[0], qr/folder group created/i, 'check created message' );
        my $folder_group_id = $response->id;
        cmp_ok( ref( \$folder_group_id ), 'eq', 'SCALAR', 'folder group id is a scalar' );

        ######################################################
        diag( 'list folder groups for the user' );
        $response = eval { $client->list_folder_groups };
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        my $folder_groups = $response->groups;
        diag( 'look for the last folder group id in this list' );
        my $last_group = grep { $_->{id} == $folder_group_id } @{$folder_groups};
        ok( $last_group, 'previously created folder group in list' );
        ok( exists $folder_groups->[0]->{$_}, "check for $_ attribute" ) for qw( id name );

        ######################################################
        diag( 'list folders for the user' );
        $response = eval { $client->list_folders };
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        my $folders = $response->folders;
        ok( $folders, 'some folders returned' );
        ok( exists $folders->[0]->{$_}, "check for $_ attribute" ) for qw( id name group);
        my $group = $folders->[0]->{group};
        ok( $group, 'first folder has a group' );
        ok( exists $group->{$_}, "check for $_ attribute" ) for qw( id name );

        ######################################################
        diag( 'create a folder' );
        $response = eval { $client->add_folder( { name => $$ . '_testfolder_' . int( rand( 1000 ) ),    ## no critic
                    folder_group   => $folder_group_id,
                    description    => 'API client test folder',
                    exclude_quotes => 1,
                    add_to_index   => 1, } ) };
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        like( $response->messages->[0], qr/folder created/i, 'check created message' );
        my $folder_id = $response->id;
        ok( $folder_id, 'folder id returned' );
        cmp_ok( ref( \$folder_id ), 'eq', 'SCALAR', 'folder id is a scalar' );

        ######################################################
        diag( 'list folders for a given group' );
        $response = eval { $client->group_folders( { id => $folder_group_id } ) };
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        $folders = $response->folders;
        ok( $folders, 'we got some folders' );
        my $last_folder = grep { $_->{id} == $folder_id } @{$folders};
        ok( $last_folder, 'previously created folder in list' );
        ok( exists $folders->[0]->{$_}, "check for $_ attribute" ) for qw( id name group );
        $group = $folders->[0]->{group};
        ok( $group, 'first folder has a group' );
        ok( exists $group->{$_}, "check for $_ attribute" ) for qw( id name );

        ######################################################
        diag( 'get a folder' );
        $response = eval { $client->get_folder( { id => $folder_id } ) };
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        my $listed_folder = $response->folder;
        my $docs          = $response->documents;
        ok( !$docs, 'no docs yet, good' );
        ok( exists $listed_folder->{$_}, "check for $_ attribute" ) for qw( id name group );
        is( $listed_folder->{id}, $folder_id, 'folder ids match' );
        $group = $listed_folder->{group};
        ok( $group, 'folder has a group' );
        ok( exists $group->{$_}, "check for $_ attribute" ) for qw( id name );


        ######################################################
        diag( 'account status' );
        $response = eval { $client->get_account() };
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        my $account_status = $response->account;
        ok( $account_status, 'account status returned' );
        cmp_ok( ref( $account_status ), 'eq', 'HASH', 'account ref is a HASH' );

        ######################################################
        diag( 'add user' );
        $response = eval { $client->add_user( {
                    first_name => 'Joe',
                    last_name  => 'User',
                    email      => 'joe@example.com',
                    password   => 'swizzlestick123',
                }
        ) };
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        my $user_id = $response->id;
        ok( $user_id, "user id returned: $user_id" );
        cmp_ok( ref( \$user_id ), 'eq', 'SCALAR', 'user id is a scalar' );

        ######################################################
        diag( 'list users' );
        $response = eval { $client->list_users() };
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        my $users = $response->users;
        cmp_ok( ref( $users->[0] ), 'eq', 'HASH', 'hash reference returned' );
        ok( exists $users->[0]->{$_}, "check for $_ attribute" ) for qw( id email first_name last_name);
        my $last_user = grep { $_->{id} == $user_id } @{$users};
        ok( $last_user, 'previously created user in list' );

        ######################################################
        diag( 'submit a document that is too small' );
        use File::Temp;
        my ( $fh, $filename ) = File::Temp::tempfile( SUFFIX => '.txt', UNLINK => 1 );
        open( $fh, '>', $filename ) or die "could not open $filename";
        print $fh 'foo bar biz';
        close( $fh ) or die $!;
        $response = eval { $client->add_document( {
                    title        => "$$ ithenticate test doc " . int( rand( 1000 ) ),
                    author_first => 'Alfred',
                    author_last  => 'Neuman',
                    submit_to    => 1,                                               # document repo and generate report
                    filename     => $filename,
                    folder       => $folder_id,                                      # folder id
                    upload       => `cat $filename`,                                 ## no critic
        } ) };
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        my $errors = $response->errors;
        like( $errors->{file_1}, qr/too small/i, 'file size too small error' );
        is( $response->api_status, '500', 'should return a 500' );

        # check for correct sized doc upload
        diag( 'submit a document that is not too small' );
        ( $fh, $filename ) = File::Temp::tempfile( SUFFIX => '.txt', UNLINK => 1 );
        open( $fh, '>', $filename ) or die "could not open $filename";
        print $fh 'foo bar biz' x 100;
        close( $fh ) or die $!;
        $response = eval { $client->add_document( {
                    title        => "$$ ithenticate test doc " . int( rand( 1000 ) ),
                    author_first => 'Alfred',
                    author_last  => 'Neuman',
                    submit_to    => 1,                                               # document repo and generate report
                    filename     => $filename,
                    folder       => $folder_id,                                      # folder id
                    upload       => `cat $filename`,                                 ## no critic
        } ) };
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        my $uploaded = $response->uploaded;
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        my $messages = $response->messages;
        cmp_ok( scalar( @{$messages} ), '==', 1, 'one message' );
        like( $messages->[0], qr/uploaded \d+ document/i, 'check for message' );
        ok( exists $uploaded->[0]->{$_}, "check for $_ attribute" ) for qw( id folder filename mime_type);

        # check the uploaded folder
        my $uploaded_folder = $uploaded->[0]->{folder};
        cmp_ok( $uploaded_folder->{id}, '==', $folder_id, 'see that the folder ids match' );
        ok( exists $uploaded_folder->{$_}, "check for $_ attribute" ) for qw( id name );

        ######################################################
        my $document_id = $uploaded->[0]->{id};
        diag( "get document status for id $document_id" );
        $response = $client->get_document( {
                id => $document_id,
        } );
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        ok( $response->folder,                                         'got a folder' );
        ok( $response->documents,                                      'got some documents' );
        ok( $response->documents->[0]->{parts},                        'got some document parts' );
        cmp_ok( $response->documents->[0]->{id}, '==', $document_id, 'ids better match up' );
        my $documents = $response->documents;
        ok( exists $documents->[0]->{$_}, "check for $_ attribute" ) for qw( author_first author_last
            is_pending percent_match processed_time title uploaded_time parts);
        my $document_part = $response->documents->[0]->{parts}->[0];
        ok( exists $document_part->{$_}, "check for $_ attribute" ) for qw( id score words doc_id);

        #############################################
        diag( 'get the similarity report' );
        $response = $client->get_report( {
                id                   => $document_part->{id},
                exclude_quotes       => 1,                      # 1 (true) or 0 (false)
                exclude_bibliography => 1,                      # 1 (true) or 0 (false)
        } );
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( $response->errors, 'errors present' );
        is( $response->api_status, '404', 'should return a 404' );
        like( $response->messages->[0], qr/report in progress/i,
            'report still in progress status message' );

        ######################################################
        diag( 'drop user' );
        $response = eval { $client->drop_user( { id => $user_id } ) };
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );

        ######################################################
        diag( 'trash a document' );    # need better tests here for permissions
        $response = eval { $client->trash_document( { id => $document_id } ) };
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        $messages = $response->messages;
        cmp_ok( scalar( @{$messages} ), '==', 1, 'one message' );
        like( $messages->[0], qr/document moved to trash/i, 'check for trash message' );

        ######################################################
        diag( 'trash a folder' );
        $response = eval { $client->trash_folder( { id => $folder_id } ) };
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        $messages = $response->messages;
        cmp_ok( scalar( @{$messages} ), '==', 1, 'one message' );
        diag( 'trash message: ' . $messages->[0] );
        like( $messages->[0], qr/moved to trash/i, 'check for deleted message' );

        ######################################################
        diag( 'drop a folder group' );
        $response = eval { $client->drop_group( { id => $folder_group_id } ) };
        die "request failed: $@" if $@;
        isa_ok( $response, 'WebService::iThenticate::Response' );
        ok( !$response->errors, 'no errors' );
        is( $response->api_status, '200', 'should return a 200' );
        ok( $response->timestamp->isa( 'RPC::XML::datetime_iso8601' ), 'check for correct timestamp' );
        $messages = $response->messages;
        cmp_ok( scalar( @{$messages} ), '==', 1, 'one message' );
        diag( 'drop message: ' . $messages->[0] );
        like( $messages->[0], qr/group \"\w+\" removed/i, 'check for deleted message' );
    } ## end SKIP:

} ## end SKIP:

__END__

