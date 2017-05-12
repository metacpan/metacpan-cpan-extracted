# ========================================================================== #
# WWW::Google::Drive
#            - Used to modify Google Drive data using service account (server to server) operations
# ========================================================================== #

package WWW::Google::Drive;

use Moose;
use Log::Log4perl qw(:easy);

use URI;
use HTTP::Request;
use HTTP::Headers;
use HTTP::Request::Common;
use HTML::Entities;
use LWP::UserAgent;

use JSON qw( from_json to_json decode_json);
use JSON::WebToken;
use Config::JSON;

use Sysadm::Install qw( slurp );
use File::Basename;
use File::MimeInfo;

our $VERSION = "0.05";

=head1 NAME

WWW::Google::Drive - Used to modify Google Drive data for service account (server-to-server)

=head1 SYNOPSIS

    use WWW::Google::Drive;

    my $gd = WWW::Google::Drive->new( 
        secret_json => 'YourProject.json',

         # Set the Google user to impersonate. 
         # Your Google Business Administrator must have already set up 
         # your Client ID as a trusted app in order to use this successfully.
        user_as => 'name@domain.com' #(optional)
    );
    my $children = $gd->children('/MyDocs');

    foreach my $item (@{$children}){
        print "File name: $item->{name}\n";
    }

=head1 DESCRIPTION

WWW::Google::Drive authenticates with a Google Drive service account (server-to-server) and offers several convenient methods to list, retrieve and modify the data stored in the google drive. 

Refer: https://developers.google.com/identity/protocols/OAuth2ServiceAccount for creating a service account and the client_secret json file.

Refer: https://developers.google.com/drive/v3/reference/ for list of file properties, response values, query_params and body_params.

=head1 METHODS

=over 4

=cut

has secret_json         => (is => "ro");
has user_as             => (is => 'ro');
has http_retry_no       => (is => "ro", default => 0);
has http_retry_interval => (is => "ro", default => 5);
has show_trash_items    => (is => 'rw', default => 0);
has scope               => (is => "ro", default => 'https://www.googleapis.com/auth/drive');
has token_uri           => (is => "ro", default => 'https://www.googleapis.com/oauth2/v4/token');
has api_file_url        => (is => "ro", default => 'https://www.googleapis.com/drive/v3/files');
has api_upload_url      => (is => "ro", default => 'https://www.googleapis.com/upload/drive/v3/files');
has file_fields         => (is => "rw", default => sub { return ['trashed', 'id', 'name', 'kind', 'mimeType'] });
has file_fields_changed => (is => "rw", default => 0);
has file_fields_str     => (is => "rw", default => 'trashed,id,name,kind,mimeType');

has export_options_mime => (
    is      => "ro",
    default => sub {
        return {
            'application/vnd.google-apps.document' => {
                'HTML'             => 'text/html',
                'Plain text'       => 'text/plain',
                'Rich text'        => 'application/rtf',
                'Open Office doc'  => 'application/vnd.oasis.opendocument.text',
                'PDF'              => 'application/pdf',
                'MS Word document' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            },
            'application/vnd.google-apps.spreadsheet' => {
                'MS Excel'               => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                'Open Office sheet'      => 'application/x-vnd.oasis.opendocument.spreadsheet',
                'PDF'                    => 'application/pdf',
                'CSV (first sheet only)' => 'text/csv',
            },
            'application/vnd.google-apps.drawing' => {
                'JPEG' => 'image/jpeg',
                'PNG'  => 'image/png',
                'SVG'  => 'image/svg+xml',
                'PDF'  => 'application/pdf',
            },

            'application/vnd.google-apps.presentation' => {
                'MS PowerPoint' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
                'PDF'           => 'application/pdf',
                'Plain text'    => 'text/plain',
            }
        };
    }
);

has error => (
    is      => "rw",
    trigger => sub {
        my ($self, $set) = @_;
        if (defined $set) {
            $self->{error} = $set;
        }
        return $self->{error};
    }
);

has lwp_opts => (
    is      => "ro",
    isa     => "HashRef",
    trigger => sub {
        my ($self, $new_val, $old_val) = @_;
        if($new_val and ref $new_val eq "HASH"){
            my $proxy_conf = delete $new_val->{proxy_conf};
            $self->{user_agent} = LWP::UserAgent->new(%{$new_val});
            if($proxy_conf){
                if(ref $proxy_conf eq 'ARRAY'){
                    $self->{user_agent}->proxy(@{$proxy_conf});
                }
                else {
                    LOGDIE "Expected type of proxy_conf in lwp_opts is ARRAY ref";
                }
            }
            return $new_val;
        }
        else{
            LOGDIE "Expected type of lwp_opts is hash ref";
        }
        return $old_val;
    },
    default => sub {
        return {};
    }
);

has user_agent => (
    is      => "ro",
    isa     => "LWP::UserAgent",
    default => sub {
        my $self     = shift;
        if($self->{user_agent}){
            return $self->{user_agent};
        }
        else {
            $self->{user_agent} = LWP::UserAgent->new();
            return $self->{user_agent};
        }
    }
);

=item B<new>

    my $gd = WWW::Google::Drive->new(
            secret_json => "./YourProject.json"
        );

Parameters can be
    
    user_as (optional)
        - email id of the account, if set, then all operations will be done in that respective user's space. Respective account should be authenticated using OAuth2.0 mechanism. See Net::Google::Drive::Simple eg/ directory for an example script to do authentication using OAuth2.0

    http_retry_no (default 0)
        - number of time each http requests should be retried if the request is failed

    http_retry_interval (default 5)
        - time interval in seconds after which another attempt will be made for the previously failed http request, this setting is useless when http_retry_no is set to 0

    show_trash_items (default 0)
        - when this value is set, trash files filter will be disabled

    lwp_opts (default {})
        - This will be passed to LWP::UserAgent constructor
        - additionally you can pass an array ref with key as proxy_conf in lwp_opts 
            which will be passed to $user_agent->proxy(@{$proxy_conf});

=cut

# ============================================= BUILD ======================================== #

sub BUILD
{
    my $self = shift;
}

# ========================================= files ============================================= #

=item B<files>

Params  : $query_params (optional)
            For list of query_params refer https://developers.google.com/drive/v3/reference/files/list

Returns : List of files

Desc    : Get all files from your drive

Usage   :
    
    my $files_at_drive = $gd->files();

=cut

sub files
{
    my ($self, $query_params) = @_;

    if (!defined $query_params) {
        $query_params = {};
    }

    my @docs = ();

    my $more_pages = 1;

    while ($more_pages) {

        $more_pages = 0;

        my $url = $self->_file_uri($query_params, undef, 1);
        my $data = $self->_get_http_json_response($url);

        return undef unless ($data);

        my $items = $data->{files};

        if (!$self->show_trash_items) {
            $items = $self->remove_trashed($items);
        }

        foreach my $item (@{$items}) {
            if ($item->{kind} eq "drive#file") {
                my $file = $item->{name};
                if (!defined $file) {
                    DEBUG "Skipping $item->{id} (no originalFilename)";
                    next;
                }

                push @docs, $item;
            }
            else {
                DEBUG "Skipping $item->{name} ($item->{kind})";
            }
        }

        if ($data->{nextPageToken}) {
            $query_params->{pageToken} = $data->{nextPageToken};
            $more_pages = 1;
        }
    }

    return \@docs;
}

# ========================================= children ========================================= #

=item B<children>

Params  : $path, $query_params (optional), $body_params (optional)

Returns : All items under the given path as an array ref

Desc    : Get children of given directory. Since the directory path is iteratively found for optimization $parent_id is returned as second argument when calling in array context.

Usage   :

    my $children = $gd->children('/my_docs' $query_params, $body_params);

    or 

    my ($children, $parent_id) = $gd->children('/my_docs', $query_params, $body_params);

=cut

sub children
{
    my ($self, $path, $query_params, $body_params) = @_;

    if (!defined $path) {
        LOGDIE "No path given";
    }

    DEBUG "Determine children of $path";

    my ($folder_id, $parent) = $self->_path_to_folderid($path, $query_params, $body_params);

    unless ($folder_id) {
        DEBUG "Unable to resolve path $path";
        return undef;
    }

    DEBUG "Getting content of folder $folder_id, Path: $path";

    my $children = $self->children_by_folder_id($folder_id, $query_params, $body_params);

    if (!defined $children) {
        return undef;
    }

    if (wantarray) {
        return ($children, $parent);
    }
    else {
        return $children;
    }
}

# =================================== children_by_folder_id ===================================== #

=item B<children_by_folder_id>

Params  : $folder_id, $query_params (optional), $body_params (optional)

Returns : Arrayref of items (files)

Desc    : Get all the items which has $folder_id as parent

Usage   : 
    
    my $items = $gd->children_by_folder_id($parent_id, { orderBy => 'modifiedTime' });

=cut

sub children_by_folder_id
{
    my ($self, $folder_id, $query_params, $body_params) = @_;

    if (!defined $body_params) {
        $body_params = {};
    }

    $body_params = {
        page => 1,
        %$body_params,
    };

    if (!defined $query_params) {
        $query_params = {};
    }

    $query_params->{q} = "'$folder_id' in parents";
    my $url = $self->_file_uri($query_params, undef, 1);

    if ($body_params->{name}) {
        $query_params->{q} .= " AND name = '$body_params->{name}'";
    }

    my $result = $self->_get_items_from_result($url, $query_params);

    return $result;
}

# ====================================== new_file =========================================== #

=item B<new_file>

Params  : $local_file_path, $folder_id, $options (optional key value pairs), $query_params (optional)

Returns : new file id, ( and second argument as response data hashref when called in array context )

Desc    : Uploads a new file ( file at $local_file_path ) to the drive in the given folder ( given folder_id )

Usage   : 

    my $file_id = $gd->new_file('./testfile', $parent_id, { description => "This is a test file upload" });

=cut

sub new_file
{
    my ($self, $file, $parent_id, $options, $query_params) = @_;

    my $title = basename $file;

    # First, POST the new file metadata to the Drive endpoint
    # http://stackoverflow.com/questions/10317638/inserting-file-to-google-drive-through-api
    my $url       = $self->_file_uri();
    my $mime_type = $self->file_mime_type($file);

    my $data = $self->_get_http_json_response(
        $url,
        {
            mimeType => $mime_type,
            parents  => [$parent_id],
            name     => $title,
            %{$options}
        }
    );

    return undef unless ($data);

    my $file_id = $data->{id};

    $data = $self->_file_upload($file_id, $file, $mime_type, $query_params);

    if (wantarray) {
        return ($file_id, $data);
    }
    else {
        return $file_id;
    }
}

# ===================================== update_file ========================================= #

=item B<update_file>

Params  : $old_file_id, $updated_local_file_path, $body_params (optional), $query_params (optional)

Returns : $file_id on Successful upload

Desc    : This will replace the existing file in the drive with new file.

Usage   : 

    my $file_id = $gd->update_file($old_file_id, "./updated_file");

NOTE    : If you only want to update file metadata, then send file_path as undef and $body_params should have properties.

=cut

sub update_file
{
    my ($self, $file_id, $file_path, $options, $query_params) = @_;

    my $title = basename $file_path;

    my $url = $self->_file_uri($query_params, $file_id);
    my $mime_type = $self->file_mime_type($file_path);

    my $data;

    if (defined $options) {
        $data = $self->_patch_http_json_response($url, $options);
    }

    if ($file_path and -f $file_path) {
        $data = $self->_file_upload($file_id, $file_path, $mime_type, $query_params);
    }

    return undef unless ($data);

    if (wantarray) {
        return ($file_id, $data);
    }
    else {
        return $file_id;
    }
}

# ====================================== delete ======================================== #

=item B<delete>

Params  : $item_id (It can be a file_id or folder_id), $no_trash (optional)

Returns : deleted file id on successful deletion

Desc    : Deletes an item from google drive.

Usage   :
    
    my $deleted_file_id = $gd->delete($file_id);

NOTE    : If $no_trash option is set, file will be deleted from google drive permanently.

=cut

sub delete
{
    my ($self, $item_id, $no_trash) = @_;

    LOGDIE 'Deletion requires file_id' if (!defined $item_id);

    my $req;

    if ($no_trash) {
        my $url = $self->_file_uri({}, $item_id);
        $req = &HTTP::Request::Common::DELETE($url->as_string, $self->_authorization_headers());
    }
    else {
        my $url = $self->_file_uri({}, $item_id);
        $req = $self->_http_req_data($url, {'trashed' => JSON::true}, 1);
    }

    my $resp = $self->_http_rsp_data($req);

    DEBUG "Request: ", $req->as_string;

    DEBUG "Response: ", $resp->as_string;

    if ($resp->is_error) {
        $self->error($resp->message());
        ERROR $resp->content;
        return undef;
    }

    return $item_id;
}

# ===================================== create_folder ======================================== #

=item B<create_folder>

Params  : $folder_name, $parent_folder_id

Returns : $folder_id (newly created folder Id)
    If called in an array context then second argument will be the http response data

Desc    : Used to create a new directory in your drive

Usage   : 
    
    my $new_folder_id = $gd->create_folder("Test",$parent_id);

=cut

sub create_folder
{
    my ($self, $title, $parent) = @_;

    LOGDIE "create_folder need 2 arguments (title and parent_id)" unless ($title or $parent);

    my $url = $self->_file_uri();

    my $data = $self->_get_http_json_response(
        $url,
        {
            name     => $title,
            parents  => [$parent],
            mimeType => "application/vnd.google-apps.folder",
        }
    );

    if (!defined $data) {
        return undef;
    }

    if (wantarray) {
        return ($data->{id}, $data);
    }
    else {
        return $data->{id};
    }
}

# ========================================= search ========================================= #

=item B<search>

Params  : $query string, $query_params (optional)

Returns : Result items (files) for the given query

Desc    : Do search on the google drive using the syntax mentioned in google drive, refer https://developers.google.com/drive/v3/web/search-parameters for list of search parameters and examples

Usage   :

    my $items = $gd->search("mimeType contains 'image/'",{ corpus => 'user' });

=cut

sub search
{
    my ($self, $query, $query_params) = @_;

    if (!defined $query_params) {
        $query_params = {};
    }

    $query_params->{q} = $query;

    my $url = $self->_file_uri($query_params, undef, 1);

    my $items = $self->_get_items_from_result($url, $query_params);

    return $items;
}

# ========================================= download ========================================= #

=item B<download>

Params  : $file_id, $local_file_path, $acknowledgeAbuse

Returns : 0/1 when $file_path is given, otherwise returns the file content

Desc    : Download file from the drive, when you pass file_id as a ref this method will try to find the $file_id->{id} and tries to download that file. When local file name with path is not given, this method will return the content of the file on success download.

Usage   :

    $gd->download($file_id, $local_file);

    or

    my $file_content = $gd->download($file_id);

=cut

sub download
{
    my ($self, $file_id, $local_file, $acknowledgeAbuse) = @_;

    if (ref $file_id eq 'HASH') {
        $file_id = $file_id->{id};
    }

    if (not $file_id) {
        my $msg = "Can't download, file id required as 1st argument";
        ERROR $msg;
        $self->error($msg);
        return undef;
    }

    my $url = $self->_file_uri({alt => "media"}, $file_id);

    my $req = HTTP::Request->new(GET => $url);
    $req->header($self->_authorization_headers());

    my $ua = $self->user_agent;
    my $resp = $ua->request($req, $local_file);

    if ($resp->is_error()) {
        my $msg = "Can't download file id $file_id (" . $resp->message() . ")";
        ERROR $msg;
        $self->error($msg);
        return undef;
    }

    if ($local_file) {
        return 1;
    }

    return $resp->decoded_content();
}

# ========================================= export ========================================= #

=item B<export_options>

Params  : $mimeType or { mimeType => $mime_type }

Return  : hashref with key as mimeType name and value as mimeType

Desc    : Return available export options with its mimeType for the given google docs mimeType

=cut

sub export_options
{
    my ($self, $mime_type) = @_;

    my $mime;
    if (ref $mime_type) {
        $mime = $mime_type->{mimeType};
    }
    else {
        $mime = $mime_type;
    }

    return undef unless ($mime);

    return $self->{export_options_mime}->{$mime};
}

# ========================================= export ========================================= #

=item B<export>

Params  : $file_id, $mime_type, $local_file_path

Returns : 0/1 when $local_file_path is given, otherwise returns the file content

Desc    : Download exported file from the drive, when you pass file_id as a ref, this method will try to find the $file_id->{id} and tries to download that file. When local file name with path is not given, this method will return the content of the file on success download.

Usage   :

    $gd->export($file_id, 'application/pdf', $local_file_path);

    or

    my $file_content = $gd->export($file_id, 'application/pdf');

=cut

sub export
{
    my ($self, $file_id, $mime_type, $local_file) = @_;

    if (ref $file_id eq 'HASH') {
        $file_id = $file_id->{id};
    }

    if (not $file_id) {
        my $msg = "Can't download/export, file id required as 1st argument";
        ERROR $msg;
        $self->error($msg);
        return undef;
    }

    my $uri = $self->{api_file_url} . "/$file_id/export";

    my $url = URI->new($uri);
    $url->query_form({mimeType => $mime_type});

    my $req = HTTP::Request->new(GET => $url);
    $req->header($self->_authorization_headers());

    my $ua = $self->user_agent;
    my $resp = $ua->request($req, $local_file);

    if ($resp->is_error()) {
        my $msg = "Can't download file id $file_id (" . $resp->message() . ")";
        ERROR $msg;
        $self->error($msg);
        return undef;
    }

    if ($local_file) {
        return 1;
    }

    return $resp->decoded_content();
}

# ========================================= metadata ========================================= #

=item B<metadata>

Params  : $file_id, $query_params

Returns : hashref of properties on success

Desc    : Used to get the file metadata. (files.get)

Usage   :

    my $properties = $gd->metadata($file_id);

=cut

sub metadata
{
    my ($self, $file_id, $query_params) = @_;

    if (ref $file_id eq 'HASH') {
        $file_id = $file_id->{id};
    }

    if (not $file_id) {
        my $msg = "Can't get properties, file id required as 1st argument";
        ERROR $msg;
        $self->error($msg);
        return undef;
    }

    my $url = $self->_file_uri($query_params, $file_id);

    return $self->_get_http_json_response($url);
}

# ====================================== file_mime_type ====================================== #

=item B<file_mime_type>

Params  : $local_file_path

Returns : mime type of the given file

Desc    : Find the MimeType of a file using File::MimeInfo

Usage   : 
    
    my $mime_type = $gd->file_mime_type("./testfile");

=cut

sub file_mime_type
{
    my ($self, $file) = @_;

    return mimetype($file);
}

# ====================================== remove_trashed ====================================== #

=item B<remove_trashed>

Params  : $items_arrayref ( return value of files() or children() )

Returns : $items arrayref

Desc    : This method will filter out all the files marked as trashed

Usage   :

    my $items = $gd->children('./MyDocs');

    # do something with the data

    my $live_items = $gd->remove_trashed($items);

=cut

sub remove_trashed
{
    my ($self, $data) = @_;

    return unless (defined $data);

    if (ref $data ne 'ARRAY') {
        LOGDIE "remove_trashed expects an array ref argument, but called with " . ref $data;
    }

    my @new_data = ();

    foreach my $item (@{$data}) {
        if ($item->{trashed}) {
            DEBUG "Skipping trashed item '$item->{name}'";
            next;
        }
        push(@new_data, $item);
    }

    return \@new_data;
}

# ====================================== show_trash_items ===================================== #

=item B<show_trash_items>

Params  : 0/1

Returns : NONE

Desc    : Disable/Enable listing deleted data from your drive

Usage   :
    $gd->show_trash_items(1);
    my $all_files = $gd->children('/'); # will return all the files including files in trash

NOTE    : This module will consider an item as trashed if the file's metadata 'trashed' is set to true.

=cut

# Moose property

# ====================================== add_req_file_fields ================================= #

=item B<add_req_file_fields>

Params  : file_properties as list
            Refer: https://developers.google.com/drive/v3/reference/files#resource for list of properties
            Refer: https://developers.google.com/drive/v3/web/performance for fields syntax

Returns : NONE

Desc    : Add file fields parameter that will be used in $query_params 'fields'.

Usage   :

        $gd->add_req_file_fields('appProperties','spaces','owners/kind');
        $gd->children('/');

Note    : By Default fields such as 'kind','trashed','id','name' are added.

=cut

sub add_req_file_fields
{
    my ($self, @fields) = @_;

    push(@{$self->{file_fields}}, @fields);

    my %hash;

    @hash{@{$self->{file_fields}}} = ();

    @{$self->{file_fields}} = keys %hash;

    $self->{file_fields_changed} = 1;
}

# ====================================== _file_upload ======================================== #

sub _file_upload
{
    my ($self, $file_id, $file, $mime_type, $query_params) = @_;

    # Since a file upload can take a long time, refresh the token
    # just in case.
    $self->_token_expire();

    unless (-f $file) {
        LOGDIE "$file does not exist in your local machine";
        return undef;
    }

    my $file_data = slurp $file;
    my $file_size = -s $file;
    $mime_type = $self->file_mime_type($file) unless ($mime_type);

    $query_params = {} unless (defined $query_params);
    $query_params = {uploadType => "media", %{$query_params}};

    my $url = URI->new($self->{api_upload_url} . "/$file_id");
    $url->query_form($query_params);

    #my $req = &HTTP::Request::Common::PUT(
    #    $url->as_string,
    #    $self->_authorization_headers(),
    #    "Content-Type" => $mime_type,
    #    "Content-Length" => $file_size,
    #    "Content"      => $file_data,
    #);
    my $req = HTTP::Request->new('PATCH', $url->as_string);
    $req->header($self->_authorization_headers());
    $req->header("Content-Type"   => $mime_type);
    $req->header("Content-Length" => $file_size);
    $req->content($file_data);

    my $resp = $self->_http_rsp_data($req);

    if ($resp->is_error()) {
        $self->error($resp->message());
        return undef;
    }

    DEBUG $resp->as_string;

    my $json_data = from_json($resp->decoded_content());

    return $json_data;
}

# =================================== _get_items_from_result ============================== #

sub _get_items_from_result
{
    my ($self, $url, $query_params) = @_;

    my @items;

    my $more_pages = 0;

    do {
        $url->query_form($query_params);

        my $data = $self->_get_http_json_response($url);

        return undef if (!defined $data);

        my $page_items = $data->{files};

        if (!$self->show_trash_items) {
            $page_items = $self->remove_trashed($page_items);
        }

        push(@items, @{$page_items});

        $more_pages = 0;

        if ($data->{nextPageToken}) {
            $query_params->{pageToken} = $data->{nextPageToken};
            $more_pages = 1;
        }
    } while ($more_pages);

    return \@items;
}

# =================================== _path_to_folderid ==================================== #

sub _path_to_folderid
{
    my ($self, $path, $query_params, $body_params) = @_;

    my @parts = split '/', $path;

    if (!defined $body_params) {
        $body_params = {};
    }

    my $parent = $parts[0] = "root";

    DEBUG "Parent: $parent";

    my $folder_id = shift @parts;

  PART: for my $part (@parts) {

        DEBUG "Looking up part $part (folder_id=$folder_id)";

        my $children = $self->children_by_folder_id($folder_id, $query_params, {%$body_params, name => $part},);

        if (!defined $children) {
            DEBUG "Part $part not found in path $path";
            return undef;
        }

        for my $child (@$children) {
            DEBUG "Found child ", $child->{name};
            if ($child->{name} eq $part) {
                $folder_id = $child->{id};
                $parent    = $folder_id;
                DEBUG "Parent: $parent";
                next PART;
            }
        }

        my $msg = "Child $part not found";
        $self->error($msg);
        ERROR $msg;
        return undef;
    }

    return ($folder_id, $parent);
}

# =================================== _get_http_json_response ============================= #

sub _get_http_json_response
{
    my ($self, $url, $post_data) = @_;

    my $req = $self->_http_req_data($url, $post_data);

    my $resp = $self->_http_rsp_data($req);

    if ($resp->is_error()) {
        $self->error($resp->message());
        return undef;
    }

    my $json_data = from_json($resp->decoded_content());

    return $json_data;
}

# =================================== _patch_http_json_response ============================= #

sub _patch_http_json_response
{
    my ($self, $url, $post_data) = @_;

    my $req = $self->_http_req_data($url, $post_data, 1);

    my $resp = $self->_http_rsp_data($req);

    if ($resp->is_error()) {
        $self->error($resp->message());
        ERROR $resp->decoded_content();
        return undef;
    }

    my $json_data = from_json($resp->decoded_content());

    return $json_data;
}

# ======================================== _http_req_data ================================= #

sub _http_req_data
{
    my ($self, $url, $post_data, $patch) = @_;

    my $req;

    if ($post_data) {

        my $json_post_data = to_json($post_data);

        DEBUG "Post Data: ", $json_post_data;

        if ($patch) {
            $req = HTTP::Request->new('PATCH', $url->as_string);
            $req->header($self->_authorization_headers());
            $req->header("Content-Type"   => "application/json");
            $req->header("Content-Length" => length $json_post_data);
            $req->content($json_post_data);
        }
        else {
            $req = &HTTP::Request::Common::POST(
                $url->as_string,
                $self->_authorization_headers(),
                "Content-Type" => "application/json",
                Content        => $json_post_data,
            );
        }
    }
    else {
        $req = HTTP::Request->new(GET => $url->as_string,);
        $req->header($self->_authorization_headers());
    }

    return $req;
}

# ====================================== _http_rsp_data ==================================== #

sub _http_rsp_data
{
    my ($self, $req, $noinit) = @_;

    my $ua = $self->user_agent;
    my $resp;

    my $RETRIES        = $self->http_retry_no;
    my $SLEEP_INTERVAL = $self->http_retry_interval;
    my $retry_count    = 0;

    {
        DEBUG "====> HTTP(" . $req->method . ") ", $req->url->as_string();

        $resp = $ua->request($req);

        if (!$resp->is_success()) {
            $self->error($resp->message());
            ERROR "Failed with ", $resp->code(), ": ", $resp->message();
            if (--$RETRIES >= 0) {
                ERROR "Retry (" . ++$retry_count . ") in $SLEEP_INTERVAL seconds";
                sleep $SLEEP_INTERVAL;
                redo;
            }
            else {
                return $resp;
            }
        }

        DEBUG "Successfully fetched ", length($resp->content()), " bytes.";
        DEBUG "Response", $resp->decoded_content();
    }

    return $resp;
}

# ================================= _file_uri ==================================== #

sub _file_uri
{
    my ($self, $query_params, $file_id, $for_list) = @_;

    $query_params = {} if !defined $query_params;

    my $file_fields = $self->_get_fields();

    if ($file_id or !$for_list) {
        $query_params->{fields} = $file_fields;
    }
    else {
        $query_params->{fields} = "kind,nextPageToken,files($file_fields)";
    }

    my $uri = $self->{api_file_url};

    $uri .= "/$file_id" if ($file_id);

    my $url = URI->new($uri);
    $url->query_form($query_params);

    return $url;
}

# =========================================== _get_fields ========================================= #

sub _get_fields
{
    my $self = shift;

    if ($self->{file_fields_changed}) {
        $self->{file_fields_str} = join(',', @{$self->{file_fields}});
        $self->{file_fields_changed} = 0;
    }

    return $self->{file_fields_str};
}

# =========================================== OAuth ========================================= #

# =================================== _authorization_headers ================================ #

sub _authorization_headers
{
    my ($self) = @_;

    return ('Authorization' => 'Bearer ' . $self->_get_oauth_token);
}

# ====================================== _get_oauth_token =================================== #

sub _get_oauth_token
{
    my ($self) = @_;

    if (not exists $self->{oauth}) {
        $self->_authenticate or LOGDIE "Google drive authentication failed";
        return $self->{oauth}->{_access_token};
    }

    my $time_remaining = $self->{oauth}->{_expires} - time();

    # checking if the token is still valid for more than 5 minutes
    # why 5 minutes? simply :-).
    if ($time_remaining < 300) {
        $self->_authenticate() or LOGDIE "Google drive token refresh failed";
    }

    return $self->{oauth}->{_access_token};
}

# ========================================== _authenticate =================================== #

sub _authenticate
{
    my ($self) = @_;

    LOGDIE "Config JSON file " . $self->secret_json . " not exist!" unless (-f $self->secret_json);

    my $config = Config::JSON->new($self->secret_json);

    my $time = time;

    my $service_acc_id     = $config->get("client_email");
    my $private_key_string = $config->get("private_key");

    my $jwt = JSON::WebToken->encode(
        {
            iss   => $service_acc_id,
            scope => $self->scope,
            aud   => $self->token_uri,
            exp   => $time + 3600,
            iat   => $time,

            # Access files from this users drive/ impersonate user
            prn => $self->user_as,
        },
        $private_key_string,
        'RS256',
        {typ => 'JWT'}
    );

    # Authenticate via post, and get a token
    my $ua       = $self->user_agent;
    my $response = $ua->post(
        $self->token_uri,
        {
            grant_type => encode_entities('urn:ietf:params:oauth:grant-type:jwt-bearer'),
            assertion  => $jwt
        }
    );

    unless ($response->is_success()) {
        LOGDIE $response->code, $response->content;
    }

    my $data = decode_json($response->content);

    if(!$data->{access_token}){
        LOGDIE "Authentication failed with error code: ", $response->code, $response->content;
        return 0;
    }

    $self->{oauth}->{_access_token} = $data->{access_token};

    # expires_in is number of seconds the token is valid, storing the validity epoch
    $self->{oauth}->{_expires} = $data->{expires_in} + time;
    return 1;
}

# ========================================== _token_expire ==================================== #

sub _token_expire
{
    my ($self) = @_;
    $self->{oauth}->{_expires} = time - 1;
}

1;

__END__

=back

=head1 Error handling
 
In case of an error while retrieving information from the Google Drive
API, the methods above will return C<undef> and a more detailed error
message can be obtained by calling the C<error()> method:
  
    print "An error occurred: ", $gd->error();
       
=head1 LOGGING/DEBUGGING
 
WWW::Google::Drive is Log4perl-enabled.
To find out what's going on under the hood, turn on Log4perl:
  
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);

=head1 REPOSITORY

L<https://github.com/dinesh-it/www-google-drive>
           
=head1 SEE ALSO

Net::Google::Drive::Simple
Net::GoogleDrive

=head1 LICENSE

Copyright 2016 by Dinesh Dharmalingam, all rights reserved. This program is free software, you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHORS

Dinesh D, <dinesh@exceleron.com>

=cut

