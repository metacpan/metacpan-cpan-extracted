#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use RPC::XML qw/ RPC_STRING /;
use RPC::XML::Client;
$RPC::XML::ENCODING = 'UTF-8';    # report data encoded as UTF-8
use Getopt::Long;
use Time::HiRes qw/ gettimeofday tv_interval /;

=head1 DESCRIPTION

This is a simple Perl script that shows an example usage of the
Turnitin for Admissions XML-RPC interface.


iParadigms provides this example code to help developers
integrate applications with Turnitin for Admissions.
Not every API method is included, and very few non-standard
return values are examined.  Developers should develop more
robust code than provided in the simple examples below.  This is
just intended as a primer for new users.

The account credentials and one or more files are passed to
the script and response output is shown if the --verbose flag is included.

See API documentation for more information.


Script Usage:

    ./tiifa_api_example.pl \
        --email $USERNAME \
        --password $PASSWORD  \
        --file test.txt test.pdf \
        --folder_id 1234 \
        --group_name 'api_test_group' \
        --folder_name 'api_test_folder' \
        --endpoint $URL \
        --notify_url $CALLBACK_URL \
        --title 'some title' \
        --author_first 'First' \
        --author_last 'Lastname' \
        --author_email 'author@example.com' \
        --owner_id '123-abc-456' \
        --sample_text \
        --add_to_index \
        --queue_report \
        --verbose


    email (required)
        email address used to log into the account. 

    password (required)
        password used with email that make up credentials
        for accessing the account.

        Note: Passing the password on the command line is considered
        insecure on a shared server.

    folder_id
        ID of folder where to upload.
        This takes precedence over specifying group_name and folder_name.

    group_name (default "api_test_group")
        "Folder group" name used when uploading.
        Each account has one or more folder groups and each
        folder group holds zero or more folders.
        The folder group is created is a folder group of
        the same name is not found.

    folder_name (default "api_test_folder"
        The folder name used when uploading the document.
        The folder is created if a folder of the same name
        is not found.  It is created within the specified
        folder group.

    file
        Specifies one or more files to upload.

    queue_report
        Queue document for report generation.

    add_to_index
        Request document is added to the index.


    sample_text
        If this flag is specified will upload some simple
        text that is hard-coded into this program.  This
        shows how to upload text directly.

        Any files specified with --files will be included.

    poll
        Specifies a document id to poll until ready until
        exceeds the poll_timeout seconds.  Using this method
        will skip uploading of any files.

    poll_timeout (default 120)
        This integer value is the number of seconds to wait
        while polling for a document to be complete.


    endpoint
        Specify the URL of the XMLRPC server endpoint.
        Defauls to: https://api.turnitinadmissions.com/rpc

    notify_url
        This is a URL that will called with a GET request when
        each report is completed and ready to view.

        For example:
            --notify_url 'http://example.com/notify?my_id=1234

        Might result with a GET request to example.com with the request
            /notify?my_id=1234&document_id=154007&report_id=154198&word_count=217&part=1&total_parts=1&percent_match=20

        where:
            document_id
                ID assigned to the uploaded document.

            word_count
                total words found in the document.

            part
                This should always be 1 unless the document is
                very large and must be split into parts.
                Large is about 75,000 words, but subject to change.

            total_parts
                Total parts for the document.

            percent_match
                The Originality Score.

        The response from this URL is ignored.
        (This is the "callback_url" request parameter.)

    verbose
        When specified this flag will cause every response
        to be printed.




Dependency Modules:

    RPC::XML
    Getopt::Long
    LWP::UserAgent
    Crypt::SSLeay (and OpenSSL)


    RPC::XML provides automatic conversion between Perl data types and
    XML-RPC data types.



THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut



# Set defaults and read command line arguments


my ( $email, $password, $verbose, @upload_file_paths, $poll, $sample_text, $notify_url );
my ( $author_first, $author_last, $author_email, $title, $owner_id );
my ( $add_to_index, $queue_report );


my $endpoint    = 'https://api.turnitinadmissions.com/rpc';
my $group_name  = 'api_test_group';
my $folder_name = 'api_test_folder';
my $folder_id;

my $poll_timeout = 120;


GetOptions(
    'endpoint=s'     => \$endpoint,
    'email=s'        => \$email,
    'password=s'     => \$password,
    'file=s'         => \@upload_file_paths,
    'poll_timeout=i' => \$poll_timeout,
    'poll=i'         => \$poll,
    verbose          => \$verbose,
    'folder_id=i'    => \$folder_id,
    sample_text      => \$sample_text,
    'group_name=s'   => \$group_name,
    'folder_name=s'  => \$folder_name,
    'notify_url=s'   => \$notify_url,
    'author_first=s' => \$author_first,
    'author_last=s'  => \$author_last,
    'author_email=s' => \$author_email,
    'title=s'        => \$title,
    'owner_id=s'     => \$owner_id,
    queue_report     => \$queue_report,
    add_to_index     => \$add_to_index,

) || die "invalid arguments\n";


# Files exist?
for ( @upload_file_paths ) {
    die "File [$_] not found or not readable\n" unless -r;
}


# Create the RPC::XML object specifying the endpoint

my $client = RPC::XML::Client->new(
    $endpoint,
    error_handler => sub { die "Transport error: $@"; },
);



# Run script.

my $sid = login_user();
unless ( $poll ) {

    my $doc_id = upload_files( @upload_file_paths );

    poll_upload( $doc_id );
}

else {
    poll_upload( $poll );
}


exit;





=head2 login_user

Log in.  Every request (except the login method) must
include a session id.  Logging in provides that session id.

=cut


sub login_user {


    send_request(
        'Example of failed login (missing required parameters)',
        'login',
        {

            # missing username and password
        },
    );




    my $response = send_request(
        'Log in: should have "sid" in response',
        'login',
        {
            username => $email,
            password => $password,
        },
    );


    # Grab session ID from response

    my $sid = $response->{sid} || die 'failed to find "sid" in response';

    return $sid;
}





=head2 upload_files

Pass in folder id and one or more files to upload.

Now that we have a folder id we are ready to upload one or more
documents.

Uploads are simply XMLRPC base64-encoded elements.  Most client
libraries provide a way to supply a file handle for the upload.
This avoids the need to bring the entire file into memory.

=cut

sub upload_files {
    my ( @files ) = @_;


    # First, create our upload structures.  The first one will be a plain
    # text file.

    my @uploads;

    my $plain_text = << 'EOF';

    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
    tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
    veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
    commodo consequat. Duis aute irure dolor in reprehenderit in voluptate
    velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat
    cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id
    est laborum.

    Sed ut perspiciatis, unde omnis iste natus error sit voluptatem accusantium
    doloremque laudantium, totam rem aperiam eaque ipsa, quae ab illo inventore
    veritatis et quasi architecto beatae vitae dicta sunt, explicabo. Nemo enim
    ipsam voluptatem, quia voluptas sit, aspernatur aut odit aut fugit, sed quia
    consequuntur magni dolores eos, qui ratione voluptatem sequi nesciunt, neque
    porro quisquam est, qui dolorem ipsum, quia dolor sit amet, consectetur,
    adipisci[ng] velit, sed quia non numquam [do] eius modi tempora inci[di]dunt,
    ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima
    veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut
    aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit, qui
    in ea voluptate velit esse, quam nihil molestiae consequatur, vel illum, qui
    dolorem eum fugiat, quo voluptas nulla pariatur?

EOF


    my %meta_data = (
        title        => RPC_STRING( $title ),
        author_first => RPC_STRING( $author_first ),
        author_last  => RPC_STRING( $author_last ),
        author_email => RPC_STRING( $author_email ),
        owner_id     => RPC_STRING( $owner_id ),
        callback_url => RPC_STRING( $notify_url ),
    );

    push @uploads, {
        %meta_data,
        filename => 'upload.txt',
        upload   => RPC::XML::base64->new( $plain_text ),
    } if $sample_text;



    # And any provided files on the command line.
    for my $path ( @files ) {

        open( my $fh, '<', $path ) || die "Failed to open file '$path':$!";
        binmode( $fh );

        my $url = 'http://foo.com' . $path;

        push @uploads, {
            %meta_data,
            filename => $path,
            upload   => RPC::XML::base64->new( $fh ),
        };
    }


    die "Nothing to upload\n" unless @uploads;


    my $submit_to = 0;
    $submit_to = $submit_to | 1 if $queue_report;
    $submit_to = $submit_to | 2 if $add_to_index;

    $submit_to = 1 unless $submit_to;


    # Send documents
    my $response = send_request(
        'Adding document(s)',
        'document.add',
        {
            sid        => $sid,
            submit_to  => $submit_to,
            uploads    => \@uploads,
            folder_id  => $folder_id,
            group_data => {
                name => $group_name,
            },
            folder_data => {
                name => $folder_name,
            },
        },
    );


    # Get data on uploaded files.
    my $uploaded = $response->{uploaded};

    die 'Failed to upload any documents'
        unless ref $uploaded eq 'ARRAY' && @{$uploaded};


    # Grab first uploaded document id:
    my $document_id = $uploaded->[0]->{id} || die 'Failed to find document id';


    return $document_id;
}



=head2 poll_upload


Now we poll until the document has been processed.
When finished we will have a report id that can be used
to access the report URL.

=cut

sub poll_upload {
    my $document_id = shift;


    my $timeout = time + $poll_timeout;


    my $document;

    while ( 1 ) {
        my $response = send_request(
            "Checking document ($document_id) status...",
            'document.get',
            {
                sid => $sid,
                id  => $document_id,
            },
        );


        # Document is returned as a list of one document
        $document = $response->{documents}->[0] || die 'Failed to find first document';

        last unless $document->{is_pending};


        print "Document is not ready\n";
        die "Timed out - giving up\n" if time > $timeout;

        print "Waiting...\n";
        sleep 10;
    }


    # Report is ready
    my $percent_match = $document->{percent_match};


    # A report is made up of one or more parts.  Typically one part,
    # but the API provides for multiple parts.
    my $parts = $document->{parts};

    my $first_part = $parts->[0];

    my $report_id = $first_part->{id} || die 'Failed to find report id';

    # Each part has its own score, wich would be different from
    # "percent_match" above only if there are more than one parts.
    # The "percent_match" is simply a weighted average of all the part
    # scores.

    my $part_score = $first_part->{score};
    my $word_count = $first_part->{word_count};


    # Now we request the URL for the report based on the report id.


    my $response = send_request(
        'Fetch report URL',
        'report.get',
        {
            sid => $sid,
            id  => $report_id,
        },
    );


    my $view_only_url = $response->{view_only_url} || die 'Failed to find "view_only_url"';


    # The timestamp (ISO-8601 timestamp) when the URL is no longer valid.
    my $expires_time = $response->{view_only_expires};

    print << "EOF";

==========================================================================
Report ID:
    $report_id

Similarity Score:
    $percent_match%

Report URL:
    $view_only_url

URL Valid Until:
    $expires_time

==========================================================================
done!
EOF


    return;

}



sub send_request {
    my ( $message, $method, $data ) = @_;

    my $t0       = [gettimeofday];
    my $response = $client->send_request( $method, $data );
    my $td       = sprintf( '%2.4f', tv_interval( $t0 ) );

    if ( $verbose ) {
        my $res = Dumper $response->value;
        my $req = Dumper $data;
        print << "EOF";
======================== Request: [$method] ===============================
$message in $td seconds

Request:
Method = [$method]
$req

---------------------------------------------------------------------------
Response
$res

EOF
    }

    else {

        print "Executed: '$message' in $td seconds.\n";

    }

    return $response->value;
}



=head1 COPYRIGHT

Copyright (C) (2011) iParadigms, LLC.  All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have available.

