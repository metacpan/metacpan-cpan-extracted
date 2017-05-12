package WebService::CloudPT;
use strict;
use warnings;
use Carp ();
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK SEEK_SET SEEK_END);
use JSON;
use Net::OAuth;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
use URI;
use URI::Escape;

our $VERSION = '1.00';
my $request_token_url = 'https://cloudpt.pt/oauth/request_token';
my $access_token_url = 'https://cloudpt.pt/oauth/access_token';
my $authorize_url = 'https://cloudpt.pt/oauth/authorize';


__PACKAGE__->mk_accessors(qw/
    key
    secret
    request_token
    request_secret
    access_token
    access_secret
    root

    no_decode_json
    error
    code
    request_url
    request_method
    timeout
	oauth_callback
	callback
	oauth_verifier
/);

$WebService::CloudPT::USE_LWP = 0;

sub import {
    eval {
        require Furl::HTTP;
        require IO::Socket::SSL;
    };if ($@) {
        __PACKAGE__->use_lwp;
    }
}

sub use_lwp {
    require LWP::UserAgent;
    require HTTP::Request;
    $WebService::CloudPT::USE_LWP++;
}

sub new {
    my ($class, $args) = @_;

    bless {
        key            => $args->{key}            || '',
        secret         => $args->{secret}         || '',
        request_token  => $args->{request_token}  || '',
        request_secret => $args->{request_secret} || '',
        access_token   => $args->{access_token}   || '',
        access_secret  => $args->{access_secret}  || '',
        root           => $args->{root}           || 'cloudpt',
        timeout        => $args->{timeout}        || (60 * 60 * 24),
        no_decode_json => $args->{no_decode_json} || 0,
        no_uri_escape  => $args->{no_uri_escape}  || 0,
        env_proxy      => $args->{lwp_env_proxy}  || $args->{env_proxy} || 0,
    }, $class;
}

sub login {
    my ($self, $callback_url) = @_;

    my $body = $self->api({
        method => 'POST',
        url  => $request_token_url, 
		'callback' => $callback_url,
    }) or return;

    my $response = Net::OAuth->response('request token')->from_post_body($body);
    $self->request_token($response->token);
    $self->request_secret($response->token_secret);

    my $url = URI->new($authorize_url);
    $url->query_form(
        oauth_token => $response->token,
        #oauth_callback => $callback_url
    );
    $url->as_string;
}

sub auth {
    my ($self, $args)  = @_;

    my $body = $self->api({
        method => 'POST',
        url  => $access_token_url,
		'verifier' => $args->{'verifier'},
		
    }) or return;

    my $response = Net::OAuth->response('access token')->from_post_body($body);
    $self->access_token($response->token);
    $self->access_secret($response->token_secret);
}

sub share_folder {
	my ($self, $path, $to) = @_;
	$self->api_json({
		method => 'POST',
		url    => 'https://publicapi.cloudpt.pt/1/ShareFolder/' . $self->root . $path,
		content => 'to_email=' . $to
	});
}
	
sub list_shared_folders {
	my ($self) = @_;
	$self->api_json({
		url => 'https://publicapi.cloudpt.pt/1/ListSharedFolders',
	});
}

sub list_links {
	my ($self) = @_;
	$self->api_json({
		url => 'https://publicapi.cloudpt.pt/1/ListLinks',
	});
}

sub _delete_link {
	my ($self, $share_id) = @_;
	
	$self->api_json({
		method => 'POST',
		url => 'https://publicapi.cloudpt.pt/1/DeleteLink',
		content => 'shareid=' . $share_id
	});
}

sub list {
	my ($self, $path, $params) = @_;
	$self->api_json({
		url => 'https://publicapi.cloudpt.pt/1/List/' . $self->root . $path,
		extra_params => $params
	});
}

sub account_info {
    my $self = shift;

    $self->api_json({
        url => 'https://publicapi.cloudpt.pt/1/Account/Info'
    });
}

sub files {
    my ($self, $path, $output, $params, $opts) = @_;

    $opts ||= {};
    if (ref $output eq 'CODE') {
        $opts->{write_code} = $output; # code ref
    } elsif (ref $output) {
        $opts->{write_file} = $output; # file handle
        binmode $opts->{write_file};
    } else {
        open $opts->{write_file}, '>', $output; # file path
        Carp::croak("invalid output, output must be code ref or filehandle or filepath.")
            unless $opts->{write_file};
        binmode $opts->{write_file};
    }
    $self->api({
        url => $self->url('https://api-content.cloudpt.pt/1/Files/' . $self->root, $path),
        extra_params => $params,
        %$opts
    });

    return if $self->error;
    return 1;
}

sub files_post {
    my ($self, $path, $content, $params, $opts) = @_;
	if ((exists $params->{'overwrite'}) and ($params->{'overwrite'})){
		### XXX RETURN ERRROR IF NO parent_rev ?
		$params->{'overwrite'} = 'true';
	}

    $opts ||= {};
     $self->api_json({
        extra_params => $params,
        method => 'POST',
        url => $self->url('https://api-content.cloudpt.pt/1/Files/' . $self->root, $path),
        content => $content,
        %$opts
    });
}

sub files_put {
    my ($self, $path, $content, $params, $opts) = @_;

	if ((exists $params->{'overwrite'}) and ($params->{'overwrite'})){
		### XXX RETURN ERRROR IF NO parent_rev ?
		$params->{'overwrite'} = 'true';
	}
    $opts ||= {};
    $self->api_json({
        extra_params => $params,
        method => 'PUT',
        url => $self->url('https://api-content.cloudpt.pt/1/Files/' . $self->root, $path),
        content => $content,
        %$opts
    });
}

sub _metadata_share {
	### NOT WORKING YET
	my ($self, $share_id, $path) = @_;

	$self->api_json({
		url => $self->url('https://publicapi.cloudpt.pt/1/MetadataShare/'. $share_id . $path),
	});
}

sub metadata {
    my ($self, $path, $params) = @_;

    $self->api_json({
        url => $self->url('https://publicapi.cloudpt.pt/1/Metadata/' . $self->root, $path),
        extra_params => $params
    });
}

sub delta {
    my ($self, $params) = @_;

    $self->api_json({
        method => 'POST',
        url => $self->url('https://publicapi.cloudpt.pt/1/Delta', ''),
        extra_params => $params
    });
}

sub revisions {
    my ($self, $path, $params) = @_;

    $self->api_json({
        url => $self->url('https://publicapi.cloudpt.pt/1/Revisions/' . $self->root, $path),
        extra_params => $params
    });
}

sub restore {
    my ($self, $path, $params) = @_;

    $self->api_json({
        method => 'POST',
        url => $self->url('https://publicapi.cloudpt.pt/1/Restore/' . $self->root, $path),
        extra_params => $params,
		content => 'rev=' . $params->{'rev'},
    });
}

sub search {
    my ($self, $path, $params) = @_;

    $self->api_json({
        url => $self->url('https://publicapi.cloudpt.pt/1/Search/' . $self->root, $path),
        extra_params => $params
    });
}

sub shares {
    my ($self, $path, $params) = @_;

    $self->api_json({
        method => 'POST',
        url => $self->url('https://publicapi.cloudpt.pt/1/Shares/' . $self->root, $path),
        extra_params => $params
    });
}

sub media {
    my ($self, $path, $params) = @_;

    $self->api_json({
        method => 'POST',
        url => $self->url('https://publicapi.cloudpt.pt/1/Media/' . $self->root, $path),
        extra_params => $params
    });
}

sub copy_ref {
    my ($self, $path, $params) = @_;

    $self->api_json({
        method => 'GET',
        url => $self->url('https://publicapi.cloudpt.pt/1/CopyRef/' . $self->root, $path),
        extra_params => $params
    });
}

sub thumbnails {
    my ($self, $path, $output, $params, $opts) = @_;

    $opts ||= {};
    if (ref $output eq 'CODE') {
        $opts->{write_code} = $output; # code ref
    } elsif (ref $output) {
        $opts->{write_file} = $output; # file handle
        binmode $opts->{write_file};
    } else {
        open $opts->{write_file}, '>', $output; # file path
        Carp::croak("invalid output, output must be code ref or filehandle or filepath.")
            unless $opts->{write_file};
        binmode $opts->{write_file};
    }
    $opts->{extra_params} = $params if $params;
    $self->api({
        url => $self->url('https://api-content.cloudpt.pt/1/Thumbnails/' . $self->root, $path),
        extra_params => $params,
        %$opts,
    });
    return if $self->error;
    return 1;
}

sub create_folder {
    my ($self, $path, $params) = @_;

    $params ||= {};
    $params->{root} ||= $self->root;
    $params->{path} = $self->path($path);

    $self->api_json({
        method => 'POST',
        url => $self->url('https://publicapi.cloudpt.pt/1/Fileops/CreateFolder', ''),
        extra_params => $params,
		content => 'path='. $path . '&root=' . $self->root,
    });
}

sub copy {
    my ($self, $from, $to_path, $params) = @_;

    $params ||= {};
    $params->{root} ||= $self->root;
    $params->{to_path} = $self->path($to_path);
	my $content;
    if (ref $from) {
        $params->{from_copy_ref} = $from->{copy_ref};
		$content = 'from_copy_ref=' . $from->{'copy_ref'};
    } else {
        $params->{from_path} = $self->path($from);
		$content = 'from_path=' . $from;
    }
	$content.='&to_path=' .$to_path . '&root=' . $self->root;

    $self->api_json({
        method => 'POST',
        url => $self->url('https://publicapi.cloudpt.pt/1/Fileops/Copy', ''),
        extra_params => $params,
		content => $content,
		
    });
}

sub move {
    my ($self, $from_path, $to_path, $params) = @_;

    $params ||= {};
    $params->{root} ||= $self->root;
    $params->{from_path} = $self->path($from_path);
    $params->{to_path}   = $self->path($to_path);

    $self->api_json({
        method => 'POST',
        url => $self->url('https://publicapi.cloudpt.pt/1/Fileops/Move', ''),
        #extra_params => $params,
        extra_params => {},
		content => 'from_path=' . $from_path . '&to_path=' . $to_path .'&root=' . $self->root,
    });
}

sub delete {
    my ($self, $path, $params) = @_;

    $params ||= {};
    $params->{root} ||= $self->root;
    $params->{path} ||= $self->path($path);
    $self->api_json({
        method => 'POST',
        url => $self->url('https://publicapi.cloudpt.pt/1/Fileops/Delete', ''),
        extra_params => $params,
		content => 'path=' . $path .'&root=' . $self->root,
    });
}

# private

sub api {
    my ($self, $args) = @_;

    $args->{method} ||= 'GET';
    $args->{url} = $self->oauth_request_url($args);

    $self->request_url($args->{url});
    $self->request_method($args->{method});

    return $self->api_lwp($args) if $WebService::CloudPT::USE_LWP;

    my ($minor_version, $code, $msg, $headers, $body) = $self->furl->request(%$args);

    $self->code($code);
    if ($code != 200) {
        $self->error($body);
        return;
    } else {
        $self->error(undef);
    }

    return $body;
}

sub api_lwp {
    my ($self, $args) = @_;

    my $headers = [];
    if ($args->{write_file}) {
        $args->{write_code} = sub {
            my $buf = shift;
            $args->{write_file}->print($buf);
        };
    }
    if ($args->{content}) {
        my $buf;
        my $content = delete $args->{content};
		if (($content !~/^path=/) and ($content !~/^rev=/) and ($content !~/^from_/) and ($content !~/^to_email/) and ($content !~/^shareid=/)){
	        $args->{content} = sub {
    	        read($content, $buf, 1024);
        	    return $buf;
		
        	};
		} else {
			$args->{'content'} = $content;
		}
        my $assert = sub {
            $_[0] or Carp::croak(
                "Failed to $_[1] for Content-Length: $!",
            );
        };
		if (($content !~/^path\=/) and ($content !~/^rev=/) and ($content !~/^from_/) and ($content !~/^to_email/) and ($content !~/^shareid=/)){
	        $assert->(defined(my $cur_pos = tell($content)), 'tell');
   	    	$assert->(seek($content, 0, SEEK_END),           'seek');
	        $assert->(defined(my $end_pos = tell($content)), 'tell');
    	    $assert->(seek($content, $cur_pos, SEEK_SET),    'seek');
        	my $content_length = $end_pos - $cur_pos;
	        push @$headers, 'Content-Length' => $content_length;
		} else {
			push @$headers, 'Content-Legnth' => length($content);
		}
    } else {
		push @$headers, 'Content-Length' => 0;
	}
	
    if ($args->{headers}) {
        push @$headers, @{ $args->{headers} };
    }
    my $req = HTTP::Request->new($args->{method}, $args->{url}, $headers, $args->{content});
    my $ua = LWP::UserAgent->new;
    $ua->timeout($self->timeout);
    $ua->env_proxy if $self->{env_proxy};
    my $res = $ua->request($req, $args->{write_code});
    $self->code($res->code);
    if ($res->is_success) {
        $self->error(undef);
    } else {
        $self->error($res->decoded_content);
    }
    return $res->decoded_content;
}

sub api_json {
    my ($self, $args) = @_;

    my $body = $self->api($args) or return;
	if ($self->error) {
		print $self->error ."\n";
		print $body ."\n";
	}
    return if $self->error;
    return $body if $self->no_decode_json;
    return decode_json($body);
}

sub oauth_request_url {
    my ($self, $args) = @_;

    Carp::croak("missing url.") unless $args->{url};
    Carp::croak("missing method.") unless $args->{method};

    my ($type, $token, $token_secret);
    if ($args->{url} eq $request_token_url) {
        $type = 'request token';
    } elsif ($args->{url} eq $access_token_url) {
        Carp::croak("missing request_token.") unless $self->request_token;
        Carp::croak("missing request_secret.") unless $self->request_secret;
        $type = 'access token';
        $token = $self->request_token;
        $token_secret = $self->request_secret;
    } else {
        Carp::croak("missing access_token, please `\$cloudpt->auth;`.") unless $self->access_token;
        Carp::croak("missing access_secret, please `\$cloudpt->auth;`.") unless $self->access_secret;
        $type = 'protected resource';
        $token = $self->access_token;
        $token_secret = $self->access_secret;
    }

    my $request = Net::OAuth->request($type)->new(
        extra_params => $args->{extra_params},
        consumer_key => $self->key,
        consumer_secret => $self->secret,
        request_url => $args->{url},
        request_method => uc($args->{method}),
        signature_method => 'PLAINTEXT', # HMAC-SHA1 can't delete %20.txt bug...
        timestamp => time,
        nonce => $self->nonce,
        token => $token,
        token_secret => $token_secret,
		callback => $args->{'callback'},
		verifier => $args->{'verifier'},
    );
    $request->sign;
    $request->to_url;
}

sub furl {
    my $self = shift;
    unless ($self->{furl}) {
        $self->{furl} = Furl::HTTP->new(
            timeout => $self->timeout,
            ssl_opts => {
                SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER(),
            },
        );
        $self->{furl}->env_proxy if $self->{env_proxy};
    }
    $self->{furl};
}

sub url {
    my ($self, $base, $path, $params) = @_;
    my $url = URI->new($base . uri_escape_utf8($self->path($path), q{^a-zA-Z0-9_.~/-}));
    $url->query_form($params) if $params;
    $url->as_string;
}

sub path {
    my ($self, $path) = @_;
    return '' unless defined $path;
    return '' unless length $path;
    $path =~ s|^/||;
    return '/' . $path;
}

sub nonce {
    my $length = 16;
    my @chars = ( 'A'..'Z', 'a'..'z', '0'..'9' );
    my $ret;
    for (1..$length) {
        $ret .= $chars[int rand @chars];
    }
    return $ret;
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

# Backward Compatibility
sub lwp_env_proxy { shift->env_proxy(@_) }

1;
__END__

=head1 NAME

WebService::CloudPT - Perl interface to CloudPT API

=head1 SYNOPSIS

    use WebService::CloudPT;

    my $cloudpt = WebService::CloudPT->new({
        key => '...', # App Key
        secret => '...' # App Secret
    });

    # get access token
    if (!$access_token or !$access_secret) {
        my $url = $cloudpt->login($url_callback) or die $cloudpt->error;
        warn "Please Access URL and press Enter: $url";
        my $verifier = <STDIN>;
		chomp $verifier;
        $cloudpt->auth({'verifier' = $verifier ]) or die $cloudt->error;
        warn "access_token: " . $cloudpt->access_token;
        warn "access_secret: " . $cloudpt->access_secret;
    } else {
        $cloudpt->access_token($access_token);
        $cloudpt->access_secret($access_secret);
    }

    my $info = $cloudpt->account_info or die $cloudpt->error;

    # download
    # https://cloudpt.pt/documentation#files
    my $fh_get = IO::File->new('some file', '>');
    $cloudpt->files('make_test_folder/test.txt', $fh_get) or die $cloudpt->error;
    $fh_get->close;

    # upload
	# https://cloudpt.pt/documentation#files
    my $fh_put = IO::File->new('some file');
    $cloudpt->files_put('make_test_folder/test.txt', $fh_put) or die $cloudpt->error;
    $fh_put->close;

    # filelist(metadata)
    # https://cloudpt.pt/documentation#metadata
    my $data = $cloudpt->metadata('folder_a');

=head1 DESCRIPTION

WebService::CloudPT is Perl interface to CloudPT API L<https://cloudpt.pt>

- Support CloudPT v1 REST API

- Support Furl (Fast!!!)

- Streaming IO (Low Memory)

- Default URI Escape (The specified path is utf8 decoded string)


=head1 API

=head2 login(callback_url) - get request token and request secret

    my $callback_url = '...'; # optional
    my $url = $cloudpt->login($callback_url) or die $cloudpt->error;
    warn "Please Access URL and press Enter: $url";

=head2 auth - get access token and access secret

    $cloudpt->auth or die $cloudpt->error;
    warn "access_token: " . $cloudpt->access_token;
    warn "access_secret: " . $cloudpt->access_secret;

=head2 root - set access type

    # Access Type is App folder
    # Your app only needs access to a single folder within the user's CloudPT
    $cloudpt->root('sandbox');

    # Access Type is Full CloudPT (default)
    # Your app needs access to the user's entire CloudPT
    $cloudpt->root('cloudpt');

=head2 account_info

    my $info = $cloudpt->account_info or die $cloudpt->error;

L<https://cloudpt.pt/documentation#accountinfo>

=head2 files(path, output, [params, opts]) - download (no file list, file list is metadata)

    my $fh_get = IO::File->new('some file', '>');
    $cloudpt->files('folder/file.txt', $fh_get) or die $cloudpt->error;
    $fh_get->close;

L<https://cloudpt.pt/documentation#files>

=head2 files_put(path, input) - Uploads a files

    my $fh_put = IO::File->new('some file');
    $cloudpt->files_put('folder/test.txt', $fh_put) or die $cloudpt->error;
    $fh_put->close;

    # To overwrite a file, you need to specifie Parent Rev
    $cloudpt->files_put('folder/test.txt', $fh_put, { overwrite => 1, parent_rev => ... }) or die $cloudpt->error;
    # conflict prevention

L<https://cloudpt.pt/documentation#files>

=head2 copy(from_path or from_copy_ref, to_path)

    # from_path
    $cloudpt->copy('folder/test.txt', 'folder/test_copy.txt') or die $cloudpt->error;

    # from_copy_ref
    my $copy_ref = $cloudpt->copy_ref('folder/test.txt') or die $cloudpt->error;

    $cloudpt->copy($copy_ref, 'folder/test_copy.txt') or die $cloudpt->error;

L<https://cloudpt.pt/documentation#copy>

=head2 move(from_path, to_path)

    $cloudpt->move('folder/test.txt', 'folder/test_move.txt') or die $cloudpt->error;

L<https://cloudpt.pt/documentation#move>

=head2 delete(path)

    # folder delete
    $cloudpt->delete('folder') or die $cloudpt->error;

    # file delete
    $cloudpt->delete('folder/test.txt') or die $cloudpt->error;

L<https://cloudpt.pt/documentation#delete>

=head2 create_folder(path)

    $cloudpt->create_folder('some_folder') or die $cloudpt->error;

L<https://cloudpt.pt/documentation#createfolder>

=head2 metadata(path, [params]) - get file list

    my $data = $cloudpt->metadata('some_folder') or die $cloudpt->error;

    my $data = $cloudpt->metadata('some_file') or die $cloudpt->error;

    # 304
    my $data = $cloudpt->metadata('some_folder', { hash => ... });
    return if $cloudpt->code == 304; # not modified
    die $cloudpt->error if $cloudpt->error;
    return $data;

L<https://cloudpt.pt/documentation#metadata>

=head2 delta([params]) - get file list

    my $data = $cloudpt->delta() or die $cloudpt->error;

L<https://cloudpt.pt/documentation#delta>

=head2 revisions(path, [params])

    my $data = $cloudpt->revisions('some_file') or die $cloudpt->error;

L<https://cloudpt.pt/documentation#revisions>

=head2 restore(path, [params])

    # params rev is Required
    my $data = $cloudpt->restore('some_file', { rev => $rev }) or die $cloudpt->error;

L<https://cloudpt.pt/documentation#restore>

=head2 search(path, [params])

    my $data = $cloudpt->search('/path', { query => $query }) or die $cloudpt->error;

L<https://cloudpt.pt/documentation#search>

=head2 shares(path, [params])

    my $data = $cloudpt->shares('some_file') or die $cloudpt->error;

L<https://cloudpt.pt/documentation#shares>

=head2 media(path, [params])

    my $data = $cloudpt->media('some_file') or die $cloudpt->error;

L<https://cloudpt.pt/documentation#media>

=head2 copy_ref(path)

    my $copy_ref = $cloudpt->copy_ref('folder/test.txt') or die $cloudpt->error;

    $cloudpt->copy($copy_ref, 'folder/test_copy.txt') or die $cloudpt->error;

L<https://cloudpt.pt/documentation#copyref>

=head2 thumbnails(path, output)

    my $fh_get = File::Temp->new;
    $cloudpt->thumbnails('folder/file.txt', $fh_get) or die $cloudpt->error;
    $fh_get->flush;
    $fh_get->seek(0, 0);

L<https://cloudpt.pt/documentation#thumbnails>

=head2 list($path, {'param1' => 'value1', 'param2' => 'value2'....})

	my $data = $cloudpt->list('/test', {'file_limit' => 10});

L<https://cloudpt.pt/documentation#list>

=head2 list_links

	my $data = $cloudpt->list_links();
	
L<https://cloudpt.pt/documentation#listlinks>

=head2 share_folder
	
	my $data = $cloudpt->share_folder('/some_folder', 'my_friend@somewhere.at');
	print $data->{'req_id'}

L<https://cloudpt.pt/documentation#sharefolder>


=head2 list_shared_folders

	my $data = $cloudpt->list_shared_folders();
	
L<https://cloudpt.pt/documentation#listsharedfolders>


=head2 env_proxy

enable HTTP_PROXY, NO_PROXY

    $cloudpt->env_proxy;

=head1 AUTHOR

Bruno Martins C<< <bruno-martins at telecom.pt> >>, based on WebService::Dropbox by Shinichiro Aska

=head1 SEE ALSO

- L<https://cloudpt.pt/documentation>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
