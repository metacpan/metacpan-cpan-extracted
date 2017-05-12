[![Build Status](https://travis-ci.org/s-aska/p5-WebService-Dropbox.svg?branch=master)](https://travis-ci.org/s-aska/p5-WebService-Dropbox)
# NAME

WebService::Dropbox - Perl interface to Dropbox API

# SYNOPSIS

```perl
use WebService::Dropbox;

my $dropbox = WebService::Dropbox->new({
    key => '...', # App Key
    secret => '...' # App Secret
});

# Authorization
if ($access_token) {
    $box->access_token($access_token);
} else {
    my $url = $box->authorize;

    print "Please Access URL and press Enter: $url\n";
    print "Please Input Code: ";

    chomp( my $code = <STDIN> );

    unless ($box->token($code)) {
        die $box->error;
    }

    print "Successfully authorized.\nYour AccessToken: ", $box->access_token, "\n";
}

my $info = $dropbox->get_current_account or die $dropbox->error;

# download
# https://www.dropbox.com/developers/documentation/http/documentation#files-download
my $fh_download = IO::File->new('some file', '>');
$dropbox->download('/make_test_folder/test.txt', $fh_download) or die $dropbox->error;
$fh_get->close;

# upload
# https://www.dropbox.com/developers/documentation/http/documentation#files-upload
my $fh_upload = IO::File->new('some file');
$dropbox->upload('/make_test_folder/test.txt', $fh_upload) or die $dropbox->error;
$fh_upload->close;

# get_metadata
# https://www.dropbox.com/developers/documentation/http/documentation#files-get_metadata
my $data = $dropbox->get_metadata('/folder_a');
```

# DESCRIPTION

WebService::Dropbox is Perl interface to Dropbox API

\- Support Dropbox v2 REST API

\- Support Furl (Fast!!!)

\- Streaming IO (Low Memory)

# API v1 => v2 Migration guide

## Migration API

files => download, files\_put => upload ...etc

[https://www.dropbox.com/developers/reference/migration-guide](https://www.dropbox.com/developers/reference/migration-guide)

## Migration OAuth1 Token => OAuth2 Token

```perl
use WebService::Dropbox::TokenFromOAuth1;

my $oauth2_access_token = WebService::Dropbox::TokenFromOAuth1->token_from_oauth1({
    consumer_key    => $dropbox->key,
    consumer_secret => $dropbox->secret,
    access_token    => $access_token,  # OAuth1 access_token
    access_secret   => $access_secret, # OAuth1 access_secret
});

warn $oauth2_access_token;
```

# Use API v1

**Dropbox will be turning off API v1 on 6/28/2017.**

[https://blogs.dropbox.com/developers/2016/06/api-v1-deprecated/](https://blogs.dropbox.com/developers/2016/06/api-v1-deprecated/)

## cpanfile

```
requires 'WebService::Dropbox', '== 1.22';
```

## cpanm

```
cpanm -L local ASKADNA/WebService-Dropbox-1.22.tar.gz
```

## curl

```perl
mkdir lib/WebService
curl -o lib/WebService/Dropbox.pm https://raw.githubusercontent.com/s-aska/p5-WebService-Dropbox/1.22/lib/WebService/Dropbox.pm
```

# API

## Auth

[https://www.dropbox.com/developers/documentation/http/documentation#oauth2-authorize](https://www.dropbox.com/developers/documentation/http/documentation#oauth2-authorize)

### for CLI Sample

```perl
my $url = $dropbox->authorize;

print "Please Access URL: $url\n";
print "Please Input Code: ";

chomp( my $code = <STDIN> );

unless ($dropbox->token($code)) {
    die $dropbox->error;
}

print "Successfully authorized.\nYour AccessToken: ", $dropbox->access_token, "\n";
```

### for Web Sample

```perl
use Amon2::Lite;
use WebService::Dropbox;

__PACKAGE__->load_plugins('Web::JSON');

my $key = $ENV{DROPBOX_APP_KEY};
my $secret = $ENV{DROPBOX_APP_SECRET};
my $dropbox = WebService::Dropbox->new({ key => $key, secret => $secret });

my $redirect_uri = 'http://localhost:5000/callback';

get '/' => sub {
    my ($c) = @_;

    my $url = $dropbox->authorize({ redirect_uri => $redirect_uri });

    return $c->redirect($url);
};

get '/callback' => sub {
    my ($c) = @_;

    my $code = $c->req->param('code');

    my $token = $dropbox->token($code, $redirect_uri);

    my $account = $dropbox->get_current_account || { error => $dropbox->error };

    return $c->render_json({ token => $token, account => $account });
};

__PACKAGE__->to_app();
```

### authorize(\\%optional\_params)

```perl
# for Simple CLI
my $url = $dropbox->authorize();

# for Other
my $url = $dropbox->authorize({
    response_type => 'code', # code or token
    redirect_uri => '',
    state => '',
    require_role => '',
    force_reapprove => JSON::false,
    disable_signup => JSON::false,
});
```

[https://www.dropbox.com/developers/documentation/http/documentation#oauth2-authorize](https://www.dropbox.com/developers/documentation/http/documentation#oauth2-authorize)

### token($code \[, $redirect\_uri\])

This endpoint only applies to apps using the authorization code flow. An app calls this endpoint to acquire a bearer token once the user has authorized the app.

Calls to /oauth2/token need to be authenticated using the apps's key and secret. These can either be passed as POST parameters (see parameters below) or via HTTP basic authentication. If basic authentication is used, the app key should be provided as the username, and the app secret should be provided as the password.

```perl
# for CLI
my $token = $dropbox->token($code);

# for Web
my $token = $dropbox->token($code, $redirect_uri);
```

[https://www.dropbox.com/developers/documentation/http/documentation#oauth2-token](https://www.dropbox.com/developers/documentation/http/documentation#oauth2-token)

### revoke

Disables the access token used to authenticate the call.

```perl
my $result = $dropbox->revoke;
```

[https://www.dropbox.com/developers/documentation/http/documentation#auth-token-revoke](https://www.dropbox.com/developers/documentation/http/documentation#auth-token-revoke)

## Files

### copy($from\_path, $to\_path)

Copy a file or folder to a different location in the user's Dropbox.
If the source path is a folder all its contents will be copied.

```perl
my $result = $dropbox->copy($from_path, $to_path);
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-copy](https://www.dropbox.com/developers/documentation/http/documentation#files-copy)

### copy\_reference\_get($path)

Get a copy reference to a file or folder. This reference string can be used to save that file or folder to another user's Dropbox by passing it to copy\_reference/save.

```perl
my $result = $dropbox->copy_reference_get($path);
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-copy\_reference-get](https://www.dropbox.com/developers/documentation/http/documentation#files-copy_reference-get)

### copy\_reference\_save($copy\_reference, $path)

Save a copy reference returned by copy\_reference/get to the user's Dropbox.

```perl
my $result = $dropbox->copy_reference_save($copy_reference, $path);
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-copy\_reference-save](https://www.dropbox.com/developers/documentation/http/documentation#files-copy_reference-save)

### create\_folder($path)

Create a folder at a given path.

```perl
my $result = $dropbox->create_folder($path);
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-create\_folder](https://www.dropbox.com/developers/documentation/http/documentation#files-create_folder)

### delete($path)

Delete the file or folder at a given path.

If the path is a folder, all its contents will be deleted too.

A successful response indicates that the file or folder was deleted. The returned metadata will be the corresponding FileMetadata or FolderMetadata for the item at time of deletion, and not a DeletedMetadata object.

```perl
my $result = $dropbox->delete($path);
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-delete](https://www.dropbox.com/developers/documentation/http/documentation#files-delete)

### download($path, $output \[, \\%opts\])

Download a file from a user's Dropbox.

```perl
# File handle
my $fh = IO::File->new('some file', '>');
$dropbox->download($path, $fh);

# Code reference
my $write_code = sub {
    # compatible with LWP::UserAgent and Furl::HTTP
    my $chunk = @_ == 4 ? @_[3] : $_[0];
    print $chunk;
};
$dropbox->download($path, $write_code);

# Range
my $fh = IO::File->new('some file', '>');
$dropbox->download($path, $fh, { headers => ['Range' => 'bytes=5-6'] });

# If-None-Match / ETag
my $fh = IO::File->new('some file', '>');
$dropbox->download($path, $fh);

# $dropbox->res->code => 200

my $etag = $dropbox->res->header('ETag');

$dropbox->download($path, $fh, { headers => ['If-None-Match', $etag] });

# $dropbox->res->code => 304
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-download](https://www.dropbox.com/developers/documentation/http/documentation#files-download)

### get\_metadata($path \[, \\%optional\_params\])

Returns the metadata for a file or folder.

Note: Metadata for the root folder is unsupported.

```perl
my $result = $dropbox->get_metadata($path);

my $result = $dropbox->get_metadata($path, {
    include_media_info => JSON::true,
    include_deleted => JSON::true,
    include_has_explicit_shared_members => JSON::false,
});
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-get\_metadata](https://www.dropbox.com/developers/documentation/http/documentation#files-get_metadata)

### get\_preview($path, $outout \[, \\%opts\])

Get a preview for a file. Currently previews are only generated for the files with the following extensions: .doc, .docx, .docm, .ppt, .pps, .ppsx, .ppsm, .pptx, .pptm, .xls, .xlsx, .xlsm, .rtf

```perl
# File handle
my $fh = IO::File->new('some file', '>');
$dropbox->get_preview($path, $fh);

# Code reference
my $write_code = sub {
    # compatible with LWP::UserAgent and Furl::HTTP
    my $chunk = @_ == 4 ? @_[3] : $_[0];
    print $chunk;
};
$dropbox->get_preview($path, $write_code);

# Range
my $fh = IO::File->new('some file', '>');
$dropbox->get_preview($path, $fh, { headers => ['Range' => 'bytes=5-6'] });

# If-None-Match / ETag
my $fh = IO::File->new('some file', '>');
$dropbox->get_preview($path, $fh);

# $dropbox->res->code => 200

my $etag = $dropbox->res->header('ETag');

$dropbox->get_preview($path, $fh, { headers => ['If-None-Match', $etag] });

# $dropbox->res->code => 304
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-get\_preview](https://www.dropbox.com/developers/documentation/http/documentation#files-get_preview)

### get\_temporary\_link($path)

Get a temporary link to stream content of a file. This link will expire in four hours and afterwards you will get 410 Gone. Content-Type of the link is determined automatically by the file's mime type.

```perl
my $result = $dropbox->get_temporary_link($path);

my $content_type = $dropbox->res->header('Content-Type');
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-get\_temporary\_link](https://www.dropbox.com/developers/documentation/http/documentation#files-get_temporary_link)

### get\_thumbnail($path, $output \[, \\%optional\_params, $opts\])

Get a thumbnail for an image.

This method currently supports files with the following file extensions: jpg, jpeg, png, tiff, tif, gif and bmp. Photos that are larger than 20MB in size won't be converted to a thumbnail.

```perl
# File handle
my $fh = IO::File->new('some file', '>');
$dropbox->get_thumbnail($path, $fh);

my $optional_params = {
    format => 'jpeg',
    size => 'w64h64'
};

$dropbox->get_thumbnail($path, $fh, $optional_params);

# Code reference
my $write_code = sub {
    # compatible with LWP::UserAgent and Furl::HTTP
    my $chunk = @_ == 4 ? @_[3] : $_[0];
    print $chunk;
};
$dropbox->get_thumbnail($path, $write_code);

# Range
my $fh = IO::File->new('some file', '>');
$dropbox->get_thumbnail($path, $fh, $optional_params, { headers => ['Range' => 'bytes=5-6'] });

# If-None-Match / ETag
my $fh = IO::File->new('some file', '>');
$dropbox->get_thumbnail($path, $fh);

# $dropbox->res->code => 200

my $etag = $dropbox->res->header('ETag');

$dropbox->get_thumbnail($path, $fh, $optional_params, { headers => ['If-None-Match', $etag] });

# $dropbox->res->code => 304
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-get\_thumbnail](https://www.dropbox.com/developers/documentation/http/documentation#files-get_thumbnail)

### list\_folder($path \[, \\%optional\_params\])

Returns the contents of a folder.

```perl
my $result = $dropbox->list_folder($path);

my $result = $dropbox->list_folder($path, {
    recursive => JSON::false,
    include_media_info => JSON::false,
    include_deleted => JSON::false,
    include_has_explicit_shared_members => JSON::false
});
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-list\_folder](https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder)

### list\_folder\_continue($cursor)

Once a cursor has been retrieved from list\_folder, use this to paginate through all files and retrieve updates to the folder.

```perl
my $result = $dropbox->list_folder_continue($cursor);
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-list\_folder-continue](https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder-continue)

### list\_folder\_get\_latest\_cursor($path \[, \\%optional\_params\])

A way to quickly get a cursor for the folder's state. Unlike list\_folder, list\_folder/get\_latest\_cursor doesn't return any entries. This endpoint is for app which only needs to know about new files and modifications and doesn't need to know about files that already exist in Dropbox.

```perl
my $result = $dropbox->list_folder_get_latest_cursor($path);

my $result = $dropbox->list_folder_get_latest_cursor($path, {
    recursive => JSON::false,
    include_media_info => JSON::false,
    include_deleted => JSON::false,
    include_has_explicit_shared_members => JSON::false
});
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-list\_folder-get\_latest\_cursor](https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder-get_latest_cursor)

### list\_folder\_longpoll($cursor \[, \\%optional\_params\])

A longpoll endpoint to wait for changes on an account. In conjunction with list\_folder/continue, this call gives you a low-latency way to monitor an account for file changes. The connection will block until there are changes available or a timeout occurs. This endpoint is useful mostly for client-side apps. If you're looking for server-side notifications, check out our webhooks documentation.

```perl
my $result = $dropbox->list_folder_longpoll($cursor);

my $result = $dropbox->list_folder_longpoll($cursor, {
    timeout => 30
});
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-list\_folder-longpoll](https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder-longpoll)

### list\_revisions($path \[, \\%optional\_params\])

Return revisions of a file.

```perl
my $result = $dropbox->list_revisions($path);

my $result = $dropbox->list_revisions($path, {
    limit => 10
});
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-list\_revisions](https://www.dropbox.com/developers/documentation/http/documentation#files-list_revisions)

### move($from\_path, $to\_path)

Return revisions of a file.

```perl
my $result = $dropbox->move($from_path, $to_path);
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-move](https://www.dropbox.com/developers/documentation/http/documentation#files-move)

### permanently\_delete($path)

Permanently delete the file or folder at a given path (see https://www.dropbox.com/en/help/40).

Note: This endpoint is only available for Dropbox Business apps.

```perl
my $result = $dropbox->permanently_delete($path);
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-permanently\_delete](https://www.dropbox.com/developers/documentation/http/documentation#files-permanently_delete)

### restore($path, $rev)

Restore a file to a specific revision.

```perl
my $result = $dropbox->restore($path, $rev);
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-restore](https://www.dropbox.com/developers/documentation/http/documentation#files-restore)

### save\_url($path, $url)

Save a specified URL into a file in user's Dropbox. If the given path already exists, the file will be renamed to avoid the conflict (e.g. myfile (1).txt).

```perl
my $result = $dropbox->save_url($path, $url);
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-save\_url](https://www.dropbox.com/developers/documentation/http/documentation#files-save_url)

### save\_url\_check\_job\_status($async\_job\_id)

Check the status of a save\_url job.

```perl
my $result = $dropbox->save_url_check_job_status($async_job_id);
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-save\_url-check\_job\_status](https://www.dropbox.com/developers/documentation/http/documentation#files-save_url-check_job_status)

### search($path \[, \\%optional\_params\])

Searches for files and folders.

Note: Recent changes may not immediately be reflected in search results due to a short delay in indexing.

```perl
my $result = $dropbox->search($path);

my $result = $dropbox->search($path, {
    query => 'prime numbers',
    start => 0,
    max_results => 100,
    mode => 'filename'
});
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-search](https://www.dropbox.com/developers/documentation/http/documentation#files-search)

### upload($path, $content \[, \\%optional\_params\])

Create a new file with the contents provided in the request.

Do not use this to upload a file larger than 150 MB. Instead, create an upload session with upload\_session/start.

```perl
# File Handle
my $content = IO::File->new('./my.cnf', '<');

my $result = $dropbox->upload($path, $content);

my $result = $dropbox->upload($path, $content, {
    mode => 'add',
    autorename => JSON::true,
    mute => JSON::false
});
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-upload](https://www.dropbox.com/developers/documentation/http/documentation#files-upload)

### upload\_session($path, $content \[, \\%optional\_params, $limit\])

Uploads large files by upload\_session API

```perl
# File Handle
my $content = IO::File->new('./mysql.dump', '<');

my $result = $dropbox->upload($path, $content);

my $result = $dropbox->upload($path, $content, {
    mode => 'add',
    autorename => JSON::true,
    mute => JSON::false
});
```

- [https://www.dropbox.com/developers/documentation/http/documentation#files-upload\_session-start](https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-start)
- [https://www.dropbox.com/developers/documentation/http/documentation#files-upload\_session-append\_v2](https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-append_v2)
- [https://www.dropbox.com/developers/documentation/http/documentation#files-upload\_session-finish](https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-finish)

### upload\_session\_start($content \[, \\%optional\_params\])

Upload sessions allow you to upload a single file using multiple requests. This call starts a new upload session with the given data. You can then use upload\_session/append\_v2 to add more data and upload\_session/finish to save all the data to a file in Dropbox.

A single request should not upload more than 150 MB of file contents.

```perl
# File Handle
my $content = IO::File->new('./access.log', '<');

$dropbox->upload_session_start($content);

$dropbox->upload_session_start($content, {
    close => JSON::true
});
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-upload\_session-start](https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-start)

### upload\_session\_append\_v2($content, $params)

Append more data to an upload session.

When the parameter close is set, this call will close the session.

A single request should not upload more than 150 MB of file contents.

```perl
# File Handle
my $content = IO::File->new('./access.log.1', '<');

my $result = $dropbox->upload_session_append_v2($content, {
    cursor => {
        session_id => $session_id,
        offset => $offset
    },
    close => JSON::true
});
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-upload\_session-append\_v2](https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-append_v2)

### upload\_session\_finish($content, $params)

Finish an upload session and save the uploaded data to the given file path.

A single request should not upload more than 150 MB of file contents.

```perl
# File Handle
my $content = IO::File->new('./access.log.last', '<');

my $result = $dropbox->upload_session_finish($content, {
    cursor => {
        session_id => $session_id,
        offset => $offset
    },
    commit => {
        path => '/Homework/math/Matrices.txt',
        mode => 'add',
        autorename => JSON::true,
        mute => JSON::false
    }
});
```

[https://www.dropbox.com/developers/documentation/http/documentation#files-upload\_session-finish](https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-finish)

## Users

### get\_account($account\_id)

Get information about a user's account.

```perl
my $result = $dropbox->get_account($account_id);
```

[https://www.dropbox.com/developers/documentation/http/documentation#users-get\_account](https://www.dropbox.com/developers/documentation/http/documentation#users-get_account)

### get\_account\_batch(\\@account\_ids)

Get information about multiple user accounts. At most 300 accounts may be queried per request.

```perl
my $result = $dropbox->get_account_batch($account_ids);
```

[https://www.dropbox.com/developers/documentation/http/documentation#users-get\_account\_batch](https://www.dropbox.com/developers/documentation/http/documentation#users-get_account_batch)

### get\_current\_account()

Get information about the current user's account.

```perl
my $result = $dropbox->get_current_account;
```

[https://www.dropbox.com/developers/documentation/http/documentation#users-get\_current\_account](https://www.dropbox.com/developers/documentation/http/documentation#users-get_current_account)

### get\_space\_usage()

Get the space usage information for the current user's account.

```perl
my $result = $dropbox->get_space_usage;
```

[https://www.dropbox.com/developers/documentation/http/documentation#users-get\_space\_usage](https://www.dropbox.com/developers/documentation/http/documentation#users-get_space_usage)

## Error Handling and Debug

### error : str

```perl
my $result = $dropbox->$some_api;
unless ($result) {
    die $dropbox->error;
}
```

### req : HTTP::Request or Furl::Request

```perl
my $result = $dropbox->$some_api;

warn $dropbox->req->as_string;
```

### res : HTTP::Response or Furl::Response

```perl
my $result = $dropbox->$some_api;

warn $dropbox->res->code;
warn $dropbox->res->header('ETag');
warn $dropbox->res->header('Content-Type');
warn $dropbox->res->header('Content-Length');
warn $dropbox->res->header('X-Dropbox-Request-Id');
warn $dropbox->res->as_string;
```

### env\_proxy

enable HTTP\_PROXY, NO\_PROXY

```perl
my $dropbox = WebService::Dropbox->new();

$dropbox->env_proxy;
```

### debug

enable or disable debug mode

```perl
my $dropbox = WebService::Dropbox->new();

$dropbox->debug; # disabled
$dropbox->debug(0); # disabled
$dropbox->debug(1); # enabled
```

### verbose

more warnings.

```perl
my $dropbox = WebService::Dropbox->new();

$dropbox->verbose; # disabled
$dropbox->verbose(0); # disabled
$dropbox->verbose(1); # enabled
```

# AUTHOR

Shinichiro Aska

# SEE ALSO

- [https://www.dropbox.com/developers/documentation/http/documentation](https://www.dropbox.com/developers/documentation/http/documentation)
- [https://www.dropbox.com/developers/reference/migration-guide](https://www.dropbox.com/developers/reference/migration-guide)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
