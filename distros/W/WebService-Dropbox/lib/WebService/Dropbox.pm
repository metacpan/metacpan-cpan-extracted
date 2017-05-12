package WebService::Dropbox;
use strict;
use warnings;
use Carp ();
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK SEEK_SET SEEK_END);
use JSON;
use URI;
use File::Temp;
use WebService::Dropbox::Auth;
use WebService::Dropbox::Files;
use WebService::Dropbox::Files::CopyReference;
use WebService::Dropbox::Files::ListFolder;
use WebService::Dropbox::Files::UploadSession;
# use WebService::Dropbox::Sharing; comming soon...
use WebService::Dropbox::Users;

our $VERSION = '2.05';

__PACKAGE__->mk_accessors(qw/
    timeout
    key
    secret
    access_token

    error
    req
    res
/);

$WebService::Dropbox::USE_LWP = 0;
$WebService::Dropbox::DEBUG = 0;
$WebService::Dropbox::VERBOSE = 0;

my $JSON = JSON->new->ascii;
my $JSON_PRETTY = JSON->new->pretty->utf8->canonical;

sub import {
    eval {
        require Furl;
        require IO::Socket::SSL;
    };if ($@ || ($Furl::VERSION < 3.08)) {
        __PACKAGE__->use_lwp;
    }
}

sub use_lwp {
    require LWP::UserAgent;
    require HTTP::Request;
    require HTTP::Request::Common;
    $WebService::Dropbox::USE_LWP++;
}

sub debug {
    $WebService::Dropbox::DEBUG = defined $_[0] ? $_[0] : 1;
}

sub verbose {
    $WebService::Dropbox::VERBOSE = defined $_[0] ? $_[0] : 1;
}

sub new {
    my ($class, $args) = @_;

    bless {
        timeout      => $args->{timeout}        || 86400,
        key          => $args->{key}            || '',
        secret       => $args->{secret}         || '',
        access_token => $args->{access_token}   || '',
        env_proxy    => $args->{env_proxy}      || 0,
    }, $class;
}

sub api {
    my ($self, $args) = @_;

    # Content-download endpoints
    if (my $output = delete $args->{output}) {
        if (ref $output eq 'CODE') {
            $args->{write_code} = $output; # code ref
        } elsif (ref $output) {
            $args->{write_file} = $output; # file handle
            binmode $args->{write_file};
        } else {
            open $args->{write_file}, '>', $output; # file path
            Carp::croak("invalid output, output must be code ref or filehandle or filepath.")
                unless $args->{write_file};
            binmode $args->{write_file};
        }
    }

    # Always HTTP POST. https://www.dropbox.com/developers/documentation/http/documentation#formats
    $args->{method}  = 'POST';

    $args->{headers} ||= [];

    if ($self->access_token && $args->{url} ne 'https://notify.dropboxapi.com/2/files/list_folder/longpoll') {
        push @{ $args->{headers} }, 'Authorization', 'Bearer ' . $self->access_token;
    }

    # Set PARAMETERS
    my $params = delete $args->{params};

    # Token
    # * PARAMETERS in to Request Body (application/x-www-form-urlencoded)
    # * RETURNS in to Response Body (application/json)
    if ($args->{url} eq 'https://api.dropboxapi.com/oauth2/token') {
        $args->{content} = $params;
    }

    # RPC endpoints
    # * PARAMETERS in to Request Body (application/json)
    # * RETURNS in to Response Body (application/json)
    elsif ($args->{url} =~ qr{ \A https://(?:api|notify).dropboxapi.com }xms) {
        if ($params) {
            push @{ $args->{headers} }, 'Content-Type', 'application/json';
            $args->{content} = $JSON->encode($params);
        }
    }

    # Content-upload endpoints or Content-download endpoints
    # * PARAMETERS in to Dropbox-API-Arg (JSON Format)
    # * RETURNS in to Dropbox-API-Result (JSON Format)
    elsif ($args->{url} =~ qr{ \A https://content.dropboxapi.com }xms) {
        if ($params) {
            push @{ $args->{headers} }, 'Dropbox-API-Arg', $JSON->encode($params);
        }
        if ($args->{content}) {
            push @{ $args->{headers} }, 'Content-Type', 'application/octet-stream';
        }
    }

    my ($req, $res);
    if ($WebService::Dropbox::USE_LWP) {
        ($req, $res) = $self->api_lwp($args);
    } else {
        ($req, $res) = $self->api_furl($args);
    }

    $self->req($req);
    $self->res($res);

    my $is_success = $self->res->code =~ qr{ \A [23] }xms ? 1 : 0;

    my $decoded_content = $res->decoded_content;

    my $res_data;
    my $res_json = $res->header('Dropbox-Api-Result');
    if (!$res_json && $res->header('Content-Type') =~ qr{ \A (?:application/json|text/javascript) }xms) {
        $res_json = $decoded_content;
    }

    if ($res_json && $res_json ne 'null') {
        $res_data = $JSON->decode($res_json);
    }

    if ($WebService::Dropbox::DEBUG || !$is_success) {
        my $level = $is_success ? 'DEBUG': 'ERROR';
        my $color = $is_success ? "\e[32m" : "\e[31m";
        my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
        my $time = sprintf("%04d-%02d-%02dT%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
        if ($WebService::Dropbox::VERBOSE) {
            warn sprintf(qq|%s [WebService::Dropbox] [%s] %s
\e[90m%s %s %s
%s
%s\e[0m
${color}%s %s\e[0m
\e[90m%s
%s\e[0m
|,
                $time,
                $level,
                $req->uri,
                $req->method,
                $req->uri->path,
                $req->protocol || '',
                $req->headers->as_string,
                ( ref $args->{content} ? '' : $args->{content} && $params ? $JSON_PRETTY->encode($params) : '' ),
                $res->protocol,
                $res->status_line,
                $res->headers->as_string,
                ( $res_data ? $JSON_PRETTY->encode($res_data) : $decoded_content . "\n" ),
            );
        } else {
            warn sprintf("%s [WebService::Dropbox] [%s] %s %s -> [%s] %s",
                $time,
                $level,
                $req->uri,
                ( $params ? $JSON->encode($params) : '-' ),
                $res->code,
                ( $res_json || $decoded_content ),
            );
        }
    }

    unless ($is_success) {
        unless ($self->error) {
            $self->error($decoded_content);
        }
        return;
    }

    $self->error(undef);

    return $res_data || +{};
}

sub api_lwp {
    my ($self, $args) = @_;

    my @headers = @{ $args->{headers} || +[] };

    if ($args->{write_file}) {
        $args->{write_code} = sub {
            my $buf = shift;
            $args->{write_file}->print($buf);
        };
    }

    if ($args->{content} && UNIVERSAL::can($args->{content}, 'read')) {
        my $buf;
        my $content = delete $args->{content};
        $args->{content} = sub {
            read($content, $buf, 1024);
            return $buf;
        };
        my $assert = sub {
            $_[0] or Carp::croak(
                "Failed to $_[1] for Content-Length: $!",
            );
        };
        $assert->(defined(my $cur_pos = tell($content)), 'tell');
        $assert->(seek($content, 0, SEEK_END),           'seek');
        $assert->(defined(my $end_pos = tell($content)), 'tell');
        $assert->(seek($content, $cur_pos, SEEK_SET),    'seek');
        my $content_length = $end_pos - $cur_pos;
        push @headers, 'Content-Length' => $content_length;
    }

    my $req;
    if ($args->{content} && ref $args->{content} eq 'HASH') {
        # application/x-www-form-urlencoded
        $req = HTTP::Request::Common::request_type_with_data(
            $args->{method},
            $args->{url},
            @headers,
            Content => $args->{content}
        );
    } else {
        # application/json or application/octet-stream
        # $args->{content} is encodeed json or file handle
        $req = HTTP::Request->new(
            $args->{method},
            $args->{url},
            \@headers,
            $args->{content},
        );
    }

    $req->protocol('HTTP/1.1');

    my $res = $self->ua->request($req, $args->{write_code});
    ($req, $res);
}

sub api_furl {
    my ($self, $args) = @_;

    if (my $write_file = delete $args->{write_file}) {
        $args->{write_code} = sub {
            $write_file->print($_[3]);
        };
    }

    if (my $write_code = delete $args->{write_code}) {
        $args->{write_code} = sub {
            if ($_[0] =~ qr{ \A 2 }xms) {
                $write_code->(@_);
            } else {
                $self->error($_[3]);
            }
        };
    }

    my $res = $self->furl->request(%$args);
    ($res->request, $res);
}

sub ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new;
    $ua->timeout($self->timeout);
    if ($self->{env_proxy}) {
        $ua->env_proxy;
    }
    $ua;
}

sub furl {
    my $self = shift;
    unless ($self->{furl}) {
        $self->{furl} = Furl->new(
            timeout => $self->timeout,
            ssl_opts => {
                SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER(),
            },
        );
        $self->{furl}->env_proxy if $self->{env_proxy};
    }
    $self->{furl};
}

sub mk_accessors {
    my $package = shift;
    no strict 'refs';
    foreach my $field ( @_ ) {
        *{ $package . '::' . $field } = sub {
            return $_[0]->{ $field } if scalar( @_ ) == 1;
            return $_[0]->{ $field }  = scalar( @_ ) == 2 ? $_[1] : [ @_[1..$#_] ];
        };
    }
}

sub env_proxy { $_[0]->{env_proxy} = defined $_[1] ? $_[1] : 1 }

1;
__END__

=head1 NAME

WebService::Dropbox - Perl interface to Dropbox API

=head1 SYNOPSIS

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

=head1 DESCRIPTION

WebService::Dropbox is Perl interface to Dropbox API

- Support Dropbox v2 REST API

- Support Furl (Fast!!!)

- Streaming IO (Low Memory)

=head1 API v1 => v2 Migration guide

=head2 Migration API

files => download, files_put => upload ...etc

L<https://www.dropbox.com/developers/reference/migration-guide>

=head2 Migration OAuth1 Token => OAuth2 Token

    use WebService::Dropbox::TokenFromOAuth1;

    my $oauth2_access_token = WebService::Dropbox::TokenFromOAuth1->token_from_oauth1({
        consumer_key    => $dropbox->key,
        consumer_secret => $dropbox->secret,
        access_token    => $access_token,  # OAuth1 access_token
        access_secret   => $access_secret, # OAuth1 access_secret
    });

    warn $oauth2_access_token;

=head1 Use API v1

B<Dropbox will be turning off API v1 on 6/28/2017.>

L<https://blogs.dropbox.com/developers/2016/06/api-v1-deprecated/>

=head2 cpanfile

    requires 'WebService::Dropbox', '== 1.22';

=head2 cpanm

    cpanm -L local ASKADNA/WebService-Dropbox-1.22.tar.gz

=head2 curl

    mkdir lib/WebService
    curl -o lib/WebService/Dropbox.pm https://raw.githubusercontent.com/s-aska/p5-WebService-Dropbox/1.22/lib/WebService/Dropbox.pm

=head1 API

=head2 Auth

L<https://www.dropbox.com/developers/documentation/http/documentation#oauth2-authorize>

=head3 for CLI Sample

    my $url = $dropbox->authorize;

    print "Please Access URL: $url\n";
    print "Please Input Code: ";

    chomp( my $code = <STDIN> );

    unless ($dropbox->token($code)) {
        die $dropbox->error;
    }

    print "Successfully authorized.\nYour AccessToken: ", $dropbox->access_token, "\n";

=head3 for Web Sample

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

=head3 authorize(\%optional_params)

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

L<https://www.dropbox.com/developers/documentation/http/documentation#oauth2-authorize>

=head3 token($code [, $redirect_uri])

This endpoint only applies to apps using the authorization code flow. An app calls this endpoint to acquire a bearer token once the user has authorized the app.

Calls to /oauth2/token need to be authenticated using the apps's key and secret. These can either be passed as POST parameters (see parameters below) or via HTTP basic authentication. If basic authentication is used, the app key should be provided as the username, and the app secret should be provided as the password.

    # for CLI
    my $token = $dropbox->token($code);

    # for Web
    my $token = $dropbox->token($code, $redirect_uri);

L<https://www.dropbox.com/developers/documentation/http/documentation#oauth2-token>

=head3 revoke

Disables the access token used to authenticate the call.

    my $result = $dropbox->revoke;

L<https://www.dropbox.com/developers/documentation/http/documentation#auth-token-revoke>

=head2 Files

=head3 copy($from_path, $to_path)

Copy a file or folder to a different location in the user's Dropbox.
If the source path is a folder all its contents will be copied.

    my $result = $dropbox->copy($from_path, $to_path);

L<https://www.dropbox.com/developers/documentation/http/documentation#files-copy>

=head3 copy_reference_get($path)

Get a copy reference to a file or folder. This reference string can be used to save that file or folder to another user's Dropbox by passing it to copy_reference/save.

    my $result = $dropbox->copy_reference_get($path);

L<https://www.dropbox.com/developers/documentation/http/documentation#files-copy_reference-get>

=head3 copy_reference_save($copy_reference, $path)

Save a copy reference returned by copy_reference/get to the user's Dropbox.

    my $result = $dropbox->copy_reference_save($copy_reference, $path);

L<https://www.dropbox.com/developers/documentation/http/documentation#files-copy_reference-save>

=head3 create_folder($path)

Create a folder at a given path.

    my $result = $dropbox->create_folder($path);

L<https://www.dropbox.com/developers/documentation/http/documentation#files-create_folder>

=head3 delete($path)

Delete the file or folder at a given path.

If the path is a folder, all its contents will be deleted too.

A successful response indicates that the file or folder was deleted. The returned metadata will be the corresponding FileMetadata or FolderMetadata for the item at time of deletion, and not a DeletedMetadata object.

    my $result = $dropbox->delete($path);

L<https://www.dropbox.com/developers/documentation/http/documentation#files-delete>

=head3 download($path, $output [, \%opts])

Download a file from a user's Dropbox.

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

L<https://www.dropbox.com/developers/documentation/http/documentation#files-download>

=head3 get_metadata($path [, \%optional_params])

Returns the metadata for a file or folder.

Note: Metadata for the root folder is unsupported.

    my $result = $dropbox->get_metadata($path);

    my $result = $dropbox->get_metadata($path, {
        include_media_info => JSON::true,
        include_deleted => JSON::true,
        include_has_explicit_shared_members => JSON::false,
    });

L<https://www.dropbox.com/developers/documentation/http/documentation#files-get_metadata>

=head3 get_preview($path, $outout [, \%opts])

Get a preview for a file. Currently previews are only generated for the files with the following extensions: .doc, .docx, .docm, .ppt, .pps, .ppsx, .ppsm, .pptx, .pptm, .xls, .xlsx, .xlsm, .rtf

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

L<https://www.dropbox.com/developers/documentation/http/documentation#files-get_preview>

=head3 get_temporary_link($path)

Get a temporary link to stream content of a file. This link will expire in four hours and afterwards you will get 410 Gone. Content-Type of the link is determined automatically by the file's mime type.

    my $result = $dropbox->get_temporary_link($path);

    my $content_type = $dropbox->res->header('Content-Type');

L<https://www.dropbox.com/developers/documentation/http/documentation#files-get_temporary_link>

=head3 get_thumbnail($path, $output [, \%optional_params, $opts])

Get a thumbnail for an image.

This method currently supports files with the following file extensions: jpg, jpeg, png, tiff, tif, gif and bmp. Photos that are larger than 20MB in size won't be converted to a thumbnail.

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

L<https://www.dropbox.com/developers/documentation/http/documentation#files-get_thumbnail>

=head3 list_folder($path [, \%optional_params])

Returns the contents of a folder.

    my $result = $dropbox->list_folder($path);

    my $result = $dropbox->list_folder($path, {
        recursive => JSON::false,
        include_media_info => JSON::false,
        include_deleted => JSON::false,
        include_has_explicit_shared_members => JSON::false
    });

L<https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder>

=head3 list_folder_continue($cursor)

Once a cursor has been retrieved from list_folder, use this to paginate through all files and retrieve updates to the folder.

    my $result = $dropbox->list_folder_continue($cursor);

L<https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder-continue>

=head3 list_folder_get_latest_cursor($path [, \%optional_params])

A way to quickly get a cursor for the folder's state. Unlike list_folder, list_folder/get_latest_cursor doesn't return any entries. This endpoint is for app which only needs to know about new files and modifications and doesn't need to know about files that already exist in Dropbox.

    my $result = $dropbox->list_folder_get_latest_cursor($path);

    my $result = $dropbox->list_folder_get_latest_cursor($path, {
        recursive => JSON::false,
        include_media_info => JSON::false,
        include_deleted => JSON::false,
        include_has_explicit_shared_members => JSON::false
    });

L<https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder-get_latest_cursor>

=head3 list_folder_longpoll($cursor [, \%optional_params])

A longpoll endpoint to wait for changes on an account. In conjunction with list_folder/continue, this call gives you a low-latency way to monitor an account for file changes. The connection will block until there are changes available or a timeout occurs. This endpoint is useful mostly for client-side apps. If you're looking for server-side notifications, check out our webhooks documentation.

    my $result = $dropbox->list_folder_longpoll($cursor);

    my $result = $dropbox->list_folder_longpoll($cursor, {
        timeout => 30
    });

L<https://www.dropbox.com/developers/documentation/http/documentation#files-list_folder-longpoll>

=head3 list_revisions($path [, \%optional_params])

Return revisions of a file.

    my $result = $dropbox->list_revisions($path);

    my $result = $dropbox->list_revisions($path, {
        limit => 10
    });

L<https://www.dropbox.com/developers/documentation/http/documentation#files-list_revisions>

=head3 move($from_path, $to_path)

Return revisions of a file.

    my $result = $dropbox->move($from_path, $to_path);

L<https://www.dropbox.com/developers/documentation/http/documentation#files-move>

=head3 permanently_delete($path)

Permanently delete the file or folder at a given path (see https://www.dropbox.com/en/help/40).

Note: This endpoint is only available for Dropbox Business apps.

    my $result = $dropbox->permanently_delete($path);

L<https://www.dropbox.com/developers/documentation/http/documentation#files-permanently_delete>

=head3 restore($path, $rev)

Restore a file to a specific revision.

    my $result = $dropbox->restore($path, $rev);

L<https://www.dropbox.com/developers/documentation/http/documentation#files-restore>

=head3 save_url($path, $url)

Save a specified URL into a file in user's Dropbox. If the given path already exists, the file will be renamed to avoid the conflict (e.g. myfile (1).txt).

    my $result = $dropbox->save_url($path, $url);

L<https://www.dropbox.com/developers/documentation/http/documentation#files-save_url>

=head3 save_url_check_job_status($async_job_id)

Check the status of a save_url job.

    my $result = $dropbox->save_url_check_job_status($async_job_id);

L<https://www.dropbox.com/developers/documentation/http/documentation#files-save_url-check_job_status>

=head3 search($path [, \%optional_params])

Searches for files and folders.

Note: Recent changes may not immediately be reflected in search results due to a short delay in indexing.

    my $result = $dropbox->search($path);

    my $result = $dropbox->search($path, {
        query => 'prime numbers',
        start => 0,
        max_results => 100,
        mode => 'filename'
    });

L<https://www.dropbox.com/developers/documentation/http/documentation#files-search>

=head3 upload($path, $content [, \%optional_params])

Create a new file with the contents provided in the request.

Do not use this to upload a file larger than 150 MB. Instead, create an upload session with upload_session/start.

    # File Handle
    my $content = IO::File->new('./my.cnf', '<');

    my $result = $dropbox->upload($path, $content);

    my $result = $dropbox->upload($path, $content, {
        mode => 'add',
        autorename => JSON::true,
        mute => JSON::false
    });

L<https://www.dropbox.com/developers/documentation/http/documentation#files-upload>

=head3 upload_session($path, $content [, \%optional_params, $limit])

Uploads large files by upload_session API

    # File Handle
    my $content = IO::File->new('./mysql.dump', '<');

    my $result = $dropbox->upload($path, $content);

    my $result = $dropbox->upload($path, $content, {
        mode => 'add',
        autorename => JSON::true,
        mute => JSON::false
    });

=over 4

=item L<https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-start>

=item L<https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-append_v2>

=item L<https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-finish>

=back

=head3 upload_session_start($content [, \%optional_params])

Upload sessions allow you to upload a single file using multiple requests. This call starts a new upload session with the given data. You can then use upload_session/append_v2 to add more data and upload_session/finish to save all the data to a file in Dropbox.

A single request should not upload more than 150 MB of file contents.

    # File Handle
    my $content = IO::File->new('./access.log', '<');

    $dropbox->upload_session_start($content);

    $dropbox->upload_session_start($content, {
        close => JSON::true
    });

L<https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-start>

=head3 upload_session_append_v2($content, $params)

Append more data to an upload session.

When the parameter close is set, this call will close the session.

A single request should not upload more than 150 MB of file contents.

    # File Handle
    my $content = IO::File->new('./access.log.1', '<');

    my $result = $dropbox->upload_session_append_v2($content, {
        cursor => {
            session_id => $session_id,
            offset => $offset
        },
        close => JSON::true
    });

L<https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-append_v2>

=head3 upload_session_finish($content, $params)

Finish an upload session and save the uploaded data to the given file path.

A single request should not upload more than 150 MB of file contents.

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

L<https://www.dropbox.com/developers/documentation/http/documentation#files-upload_session-finish>

=head2 Users

=head3 get_account($account_id)

Get information about a user's account.

    my $result = $dropbox->get_account($account_id);

L<https://www.dropbox.com/developers/documentation/http/documentation#users-get_account>

=head3 get_account_batch(\@account_ids)

Get information about multiple user accounts. At most 300 accounts may be queried per request.

    my $result = $dropbox->get_account_batch($account_ids);

L<https://www.dropbox.com/developers/documentation/http/documentation#users-get_account_batch>

=head3 get_current_account()

Get information about the current user's account.

    my $result = $dropbox->get_current_account;

L<https://www.dropbox.com/developers/documentation/http/documentation#users-get_current_account>

=head3 get_space_usage()

Get the space usage information for the current user's account.

    my $result = $dropbox->get_space_usage;

L<https://www.dropbox.com/developers/documentation/http/documentation#users-get_space_usage>

=head2 Error Handling and Debug

=head3 error : str

    my $result = $dropbox->$some_api;
    unless ($result) {
        die $dropbox->error;
    }

=head3 req : HTTP::Request or Furl::Request

    my $result = $dropbox->$some_api;

    warn $dropbox->req->as_string;

=head3 res : HTTP::Response or Furl::Response

    my $result = $dropbox->$some_api;

    warn $dropbox->res->code;
    warn $dropbox->res->header('ETag');
    warn $dropbox->res->header('Content-Type');
    warn $dropbox->res->header('Content-Length');
    warn $dropbox->res->header('X-Dropbox-Request-Id');
    warn $dropbox->res->as_string;

=head3 env_proxy

enable HTTP_PROXY, NO_PROXY

    my $dropbox = WebService::Dropbox->new();

    $dropbox->env_proxy;

=head3 debug

enable or disable debug mode

    my $dropbox = WebService::Dropbox->new();

    $dropbox->debug; # disabled
    $dropbox->debug(0); # disabled
    $dropbox->debug(1); # enabled

=head3 verbose

more warnings.

    my $dropbox = WebService::Dropbox->new();

    $dropbox->verbose; # disabled
    $dropbox->verbose(0); # disabled
    $dropbox->verbose(1); # enabled

=head1 AUTHOR

Shinichiro Aska

=head1 SEE ALSO

=over 4

=item L<https://www.dropbox.com/developers/documentation/http/documentation>

=item L<https://www.dropbox.com/developers/reference/migration-guide>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
