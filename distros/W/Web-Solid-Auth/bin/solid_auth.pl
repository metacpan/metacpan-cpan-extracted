#!perl
$|++;

use lib qw(./lib);
use Getopt::Long qw(:config pass_through);
use Web::Solid::Auth;
use Web::Solid::Auth::Agent;
use Web::Solid::Auth::Util;
use HTTP::Date;
use File::LibMagic;
use File::Basename;
use MIME::Base64;
use JSON;
use Path::Tiny;
use String::Escape;
use Log::Any::Adapter;

Log::Any::Adapter->set('Log4perl');

my $webid    = $ENV{SOLID_WEBID};
my $webbase  = $ENV{SOLID_REMOTE_BASE};
my $clientid = $ENV{SOLID_CLIENT_ID};
my $opt_recursive = undef;
my $opt_skip      = undef;
my $opt_real      = undef;
my $opt_keep      = undef;
my $opt_delete    = undef;
my $opt_force     = undef;
my $opt_etag      = undef;
my $opt_log       = 'log4perl.conf';
my $opt_header    = [];

GetOptions(
    "clientid|c=s" => \$clientid ,
    "webid|w=s"    => \$webid ,
    "base|b=s"     => \$webbase ,
    "skip"         => \$opt_skip ,
    "keep"         => \$opt_keep ,
    "delete"       => \$opt_delete ,
    "etag=s"       => \$opt_etag ,
    "force|f"      => \$opt_force ,
    "r"            => \$opt_recursive ,
    "x"            => \$opt_real ,
    "H=s@"         => \$opt_header ,
    "log=s"        => \$opt_log ,
);

my $cmd = shift;

if (-e $opt_log) {
    Log::Log4perl::init($opt_log);
}

my $auth = Web::Solid::Auth->new(webid => $webid, client_id => $clientid);
my $agent = Web::Solid::Auth::Agent->new(auth => $auth);

if ($webbase) {
    # Remove the trailing slash
    $webbase =~ s{\/$}{};
}

my $ret;

if (0) {}
elsif ($cmd eq 'list') {
    $ret = cmd_list(@ARGV);
}
elsif ($cmd eq 'get') {
    $ret = cmd_get(@ARGV);
}
elsif ($cmd eq 'put') {
    $ret = cmd_put(@ARGV);
}
elsif ($cmd eq 'post') {
    $ret = cmd_post(@ARGV);
}
elsif ($cmd eq 'patch') {
    $ret = cmd_patch(@ARGV);
}
elsif ($cmd eq 'delete') {
    $ret = cmd_delete(@ARGV);
}
elsif ($cmd eq 'head') {
    $ret = cmd_head(@ARGV);
}
elsif ($cmd eq 'options') {
    $ret = cmd_options(@ARGV);
}
elsif ($cmd eq 'mirror') {
    $ret = cmd_mirror(@ARGV);
}
elsif ($cmd eq 'upload') {
    $ret = cmd_upload(@ARGV);
}
elsif ($cmd eq 'clean') {
    $ret = cmd_clean(@ARGV);
}
elsif ($cmd eq 'authenticate') {
    $ret = cmd_authenticate(@ARGV);
}
elsif ($cmd eq 'headers') {
    $ret = cmd_headers(@ARGV);
}
elsif ($cmd eq 'curl') {
    $ret = cmd_curl(@ARGV);
}
elsif ($cmd eq 'id_token') {
    $ret = cmd_id_token(@ARGV);
}
elsif ($cmd eq 'access_token') {
    $ret = cmd_access_token(@ARGV);
}
else {
    usage();
}

exit($ret);

sub usage {
    print STDERR <<EOF;
Usage
-=-=-=

# Login
usage: $0 [options] authenticate

# Curl like interaction
usage: $0 [options] headers method url
usage: $0 [options] curl -- [curl-opts] url

# Interpret LDP responses
usage: $0 [options] list /path/ | url        # folder listing
usage: $0 [options] mirror /path directory   # mirror a container/resource , use [-r] for recursive mirror
usage: $0 [options] upload directory /path   # upload the directory contents to a path, use [-r] for recursive upload
usage: $0 [options] clean /path              # delete resources/containers, use [-r] for recursive clean

# Simple HTTP interaction
usage: $0 [options] get /path | url
usage: $0 [options] put (/path/ | url)       # create a folder 
usage: $0 [options] put (/path | url) file [mimeType]
usage: $0 [options] post (/path | url) file [mimeType]
usage: $0 [options] patch (/path | url) (file | SPARQL)
usage: $0 [options] head /path | url
usage: $0 [options] options /path | url
usage: $0 [options] delete /path | url

# Check the credentials
usage: $0 access_token
usage: $0 id_token

options:
    --webid|w webid          - your webid
    --clientid|c clientid    - optional the client-id
    --base|b base            - optional the base url for all requests
    --skip                   - skip files that already exist (mirror)
    --delete                 - delete local files that are not at the remote location (mirror)
    --keep                   - keep containers (clean)
    --force|f                - force overwriting existing resources (put,patch)
    -r                       - recursive (mirror, upload, clean)
    -x                       - do it for real (upload, clean)
    -H "Header"              - add a header (get,post,put,head,delete)
EOF
    exit 1
}

sub cmd_list {
    my ($url) = @_;

    my $files = _cmd_list($url);

    return $files if $files && ref($files) eq '';

    for my $file (sort keys %$files) {
        my $type = $files->{$file};

        printf "%s $file\n" , $type eq 'container' ? "d" : "-";
    }

    return 0;
}

sub _cmd_list {
    my ($url) = @_;

    unless ($url) {
        print STDERR "Need a url\n";
        return 1;
    }

    unless ($url =~ /\/$/) {
        print STDERR "$url doesn't look like a container\n";
        return 1;
    }

    my $iri = _make_url($url);

    my $response = $agent->get($iri);

    unless ($response->is_success) {
        printf STDERR "%s - failed to $url\n" , $response->code;
        printf STDERR "%s\n" , $response->message;
        return 2;
    }

    my $util  = Web::Solid::Auth::Util->new;
    my $model = $util->parse_turtle($response->decoded_content);

    my $sparql =<<EOF;
prefix ldp: <http://www.w3.org/ns/ldp#> 

SELECT ?resource ?type {
    ?base ldp:contains ?resource .
    OPTIONAL {
        ?resource a ?type .
        FILTER (?type IN (
                      ldp:Resource,
                      ldp:RDFSource,
                      ldp:Container,
                      ldp:BasicContainer, 
                      ldp:IndirectContainer,
                      ldp:NonRDFSource
                      ) 
            )
    }
}
EOF

    my %FILES = ();

    $util->sparql($model, $sparql, sub {
        my $res = shift;
        my $name = $res->value('resource')->as_string; 

        # clean absolute urls into relative ones ...
        if ($name =~ /^http/) {
            $name = substr($name,length($iri));
        }
        $name =~ s/^\///; 

        # Read the type from type or guess ..based on the name :P
        my $type;

        if ($res->value('type')) {
            $type = $res->value('type')->as_string;
        }
        else {
            $type = ($name =~ /\/$/) ? 'Container'  : 'Resource';
        }

        my $key = $url . $name;

        if (exists $FILES{$key} && $FILES{$key} eq 'container') {
            # Containers are more interesting than resources
        }
        else {
            $FILES{$key} = $type =~ /Container/ ? "container" : "resource";
        }
    });

    return \%FILES;
}

sub cmd_get {
    my ($url) = @_; 

    my %headers = _make_headers();

    my $response = _cmd_get($url,%headers);

    return $response if $response && ref($response) eq '';

    print $response->decoded_content;

    return 0;
}

sub _cmd_get {
    my ($url,%headers) = @_;

    unless ($url) {
        print STDERR "Need a url\n";
        return 1;
    }

    my $iri = _make_url($url);

    my $response = $agent->get($iri,%headers);

    unless ($response->is_success) {
        printf STDERR "%s - failed to $url\n" , $response->code;
        printf STDERR "%s\n" , $response->message;
        return 2;
    }

    $response;
}

sub cmd_head {
    my ($url) = @_;

    unless ($url) {
        print STDERR "Need a url\n";
        return 1;
    }

    my $iri = _make_url($url);
    my %headers = _make_headers();

    my $response = $agent->head($iri,%headers);

    unless ($response->is_success) {
        printf STDERR "%s - failed to $url\n" , $response->code;
        printf STDERR "%s\n" , $response->message;
        return 2;
    }

    for my $header ($response->header_field_names) {
        printf "%s: %s\n" , $header , $response->header($header);
    }

    return 0;
}

sub cmd_options {
    my ($url) = @_;

    unless ($url) {
        print STDERR "Need a url\n";
        return 1;
    }

    my $iri = _make_url($url);
    my %headers = _make_headers();

    my $response = $agent->options($iri,%headers);

    unless ($response->is_success) {
        printf STDERR "%s - failed to $url\n" , $response->code;
        printf STDERR "%s\n" , $response->message;
        return 2;
    }

    for my $header ($response->header_field_names) {
        printf "%s: %s\n" , $header , $response->header($header);
    }

    return 0;
}

sub cmd_put {
    my ($url, $file, $mimeType) = @_;

    $mimeType //= _guess_mimetype($file) if $file;

    unless ($url) {
        print STDERR "Need a url\n";
        return 1;
    }

    if ($url =~ /\/$/ && ($file || $mimeType)) {
        print STDERR "Folder names can't have file uploads\n\n";
        return 1;
    }
    elsif ($url !~ /\/$/ && ! ($file || $mimeType)) {
        print STDERR "Need url file and mimeType\n";
        return 1;
    }

    my $data;
    
    if ($file) {
        $data = path($file)->slurp_raw;
    }

    my $iri = _make_url($url);
    my %headers = _make_headers();

    if ($mimeType) {
        $headers{'Content-Type'} = $mimeType unless $headers{'Content-Type'};
    }

    # Prevent overwriting exiting resources    
    unless ($opt_force) {
        $headers{'If-None-Match'} = '*';
    }

    # Prevent overwriting changed resources
    if ($opt_etag) {
        $headers{'If-Match'} = $opt_etag;
    }

    my $response;

    if ($file) {
        $response = $agent->put($iri, $data, %headers);
    }
    else {
        %headers = _link_header('<http://www.w3.org/ns/ldp#BasicContainer>; rel="type"', %headers);
        $response = $agent->put($iri,undef,%headers);
    }

    unless ($response->is_success) {
        printf STDERR "%s - failed to $url\n" , $response->code;
        printf STDERR "%s\n" , $response->message;
        return 2;
    }

    print STDERR $response->decoded_content , "\n";

    return 0;
}

sub cmd_post {
    my ($url, $file, $mimeType) = @_;

    $mimeType //= _guess_mimetype($file) if $file;

    unless ($url && $file && -r $file && $mimeType) {
        print STDERR "Need url file and mimeType\n";
        return 1;
    }

    my $data = path($file)->slurp_raw;

    my $iri = _make_url($url);
    my %headers = _make_headers();

    $headers{'Content-Type'} = $mimeType unless $headers{'Content-Type'}; 

    my $response = $agent->post($iri, $data, %headers);

    unless ($response->is_success) {
        printf STDERR "%s - failed to $url\n" , $response->code;
        printf STDERR "%s\n" , $response->message;
        return 2;
    }

    print STDERR $response->decoded_content , "\n";

    print $response->header('Location') , "\n";

    return 0;
}

sub cmd_patch {
    my ($url,$file_or_string) = @_;    

    unless ($url && $file_or_string) {
        print STDERR "Need a url and a file or string\n";
        return 1;
    }

    my $sparql;

    $file_or_string = '/dev/stdin' if $file_or_string eq '-';

    if (-r $file_or_string) {
        $sparql = path($file_or_string)->slurp_utf8;
    }
    else {
        $sparql = $file_or_string;
    }

    my $iri = _make_url($url);
    my %headers = _make_headers();
    $headers{'Content-Type'} = 'application/sparql-update' unless $headers{'Content-Type'}; 

    # Prevent overwriting exiting resources    
    unless ($opt_force) {
        $headers{'If-None-Match'} = '*';
    }

    # Prevent overwriting changed resources
    if ($opt_etag) {
        $headers{'If-Match'} = $opt_etag;
    }

    my $response = $agent->patch($iri, $sparql, %headers);

    unless ($response->is_success) {
        printf STDERR "%s - failed to $url\n" , $response->code;
        printf STDERR "%s\n" , $response->message;
        return 2;
    }

    print STDERR $response->decoded_content , "\n";

    return 0;
}

sub cmd_delete {
    my ($url) = @_;

    unless ($url) {
        print STDERR "Need a url\n";
        return 1;
    }

    my $iri = _make_url($url);
    my %headers = _make_headers();

    my $response = $agent->delete($iri, %headers);

    unless ($response->is_success) {
        printf STDERR "%s - failed to $url\n" , $response->code;
        printf STDERR "%s\n" , $response->message;
        return 2;
    }

    print STDERR $response->decoded_content , "\n";

    return 0;
}

sub cmd_mirror {
    my ($url,$directory) = @_;

    unless ($url) {
        print STDERR "Need a url\n";
        return 2;
    }

    unless ($directory && -d $directory) {
        print STDERR "Need a directory\n";
        return 2;
    }

    if ($url =~ /\/$/) {
        # ok we are a container
    }
    else {
        return _cmd_mirror($url,$directory);
    }

    my $files = _cmd_list($url);

    return $files if $files && ref($files) eq '';

    for my $file (sort keys %$files) {
        my $type = $files->{$file};
        my $base = substr($file,length($url));
        $base =~ s{\/$}{};
        if ($type eq 'container') {
            if ($file ne $url && $base !~ /^\./ && $opt_recursive) {
                path("$directory/$base")->mkpath;
                cmd_mirror($file,"$directory/$base");
            }
        }
        else {
            _cmd_mirror($file,$directory);
        }
    }

    _cmd_mirror_delete($url,$files,$directory) if $opt_delete;
}

sub _cmd_mirror_delete {
    my ($base,$files,$directory) = @_;
    my $path_names;
    for my $file (sort keys %$files) {
        my $path = substr($file,length($base));
        $path =~ s{^\/}{};
        $path =~ s{\/$}{};
        next unless length($path);
        $path_names->{$path} = 1;
    }

    for my $path (glob("$directory/*")) {
        my $basename = basename($path);
        next if -d $path; # we always keep directories
        next if $path =~ /^[\.~]/;

        if ($path_names->{$basename}) {
            # ok , known path
        }
        else {
            if ($opt_real) {
                print STDERR "deleting: $path\n";
                unlink $path;
            }
            else {
                print STDERR "deleting: $path [test : use -x for real delete]\n";
            }
        }
    }
}

sub _cmd_mirror {
    my ($url,$directory) = @_;

    my $path = $url;
    $path =~ s{.*\/}{};

    my %headers = ();

    if ($opt_skip && -e "$directory/$path" ) {
        print STDERR "skipping $directory/$path - already exists\n";
        return 0;
    }

    if (-e "$directory/$path") {
        my ($mtime) = ( stat("$directory/$path") )[9];
        $headers{'If-Modified-Since'} = HTTP::Date::time2str($mtime);
    }

    if ($opt_real) {
        print "$url -> $directory/$path\n";
        my $response = _cmd_get($url,%headers);

        return $response unless $response && ref($response) ne '';

        path("$directory/$path")->spew_raw($response->decoded_content);
    }
    else {
        print "$url -> $directory/$path [test : use -x for real mirror]\n";
    }

    return 0;
}

sub cmd_upload {
    my ($directory,$url) = @_;

    unless ($directory && -d $directory) {
        print STDERR "Need a directory";
        return 2;
    }

    unless ($url =~ /\/$/) {
        print STDERR "Url doesn't look like a container";
        return 2;
    }

    for my $file (glob("$directory/*")) {
        my $upload_url;
        my $upload_file = substr($file,length($directory) + 1);

        if (-d $file) {
            $upload_url = "$url$upload_file/";           
        }
        else {
            $upload_url = "$url$upload_file";
        }
     
        if ($opt_real) {
            print "$file -> $upload_url\n";

            if (-d $file) {
                cmd_put($upload_url);
            }
            else {
                cmd_put($upload_url,$file);
            }
        }
        else {
            print "$file -> $upload_url [test : use -x for real upload]\n";
        }

        if ($opt_recursive && -d $file) {
            cmd_upload($file,$upload_url);
        }
    }
}

sub _crawl_container_url {
    my ($url,$result) = @_;

    $result //= {};

    unless ($url && $url =~ /^\//) {
        print STDERR "Need a container url\n";
        return 2;
    }

    my $files = _cmd_list($url);

    # return on error
    return $files if $files && ref($files) eq '';

    for my $file (sort { $b cmp $a } keys %$files) {
        my $type = $files->{$file};

        next if $file eq $url;

        $result->{$file} = $type;

        if ($type eq 'container') {
            _crawl_container_url($file,$result);
        }
    }

    return $result;
}

sub cmd_clean {
    my ($url) = @_;

    unless ($url && $url =~ /^\//) {
        print STDERR "Need a container url\n";
        return 2;
    }

    my $files;

    if ($opt_recursive) {
        $files = _crawl_container_url($url);
    }
    else {
        $files = _cmd_list($url);

    }

    for my $file (sort { $b cmp $a } keys %$files) {
        my $type = $files->{$file};

        next if $file eq $url;

        if ($opt_keep && $type eq 'container') {
            print "skipping: $file\n";
            next;
        }

        if ($opt_real) {
            print "deleting: $file\n";
            cmd_delete($file);
        }
        else {
            print "deleting: $file [test : use -x for real upload]\n";
        }
    }
}

sub cmd_authenticate {

    unless ($webid) {
        print STDERR "Need a WebId or SOLID_WEBID environment variable\n";
        return 2;
    }

    $auth->make_clean;

    my $auth_url = $auth->make_authorization_request;

    print "Please visit this URL and login:\n\n$auth_url\n\n";

    print "Starting callback server...\n";

    $auth->listen;

    return 0;
}

sub cmd_headers {
    my ($method,$url) = @_;

    usage() unless $method && $url;

    my $headers = _authentication_headers($method,$url);

    print "$headers\n";

    return 0;
}

sub cmd_curl {
    my (@rest) = @_;

    usage() unless @rest;

    my $method = 'GET';
    my $url = $rest[-1];

    shift @rest if @rest[0] eq '--';

    if (@rest) {
        for (my $i = 0 ; $i < @rest ; $i++) {
            if ($rest[$i] eq '-X') {
                $method = $rest[$i+1];
            }
        }
        @rest = map { String::Escape::quote($_) } @rest;
    }

    my $headers = _authentication_headers($method,$url);
    my $opts    = join(" ",@rest);
    system("curl $headers $opts") == 0;
}

sub cmd_access_token {
    my $access = $auth->get_access_token;

    unless ($webid) {
        print STDERR "Need a WebId or SOLID_WEBID environment variable\n";
        return 2;
    }
    
    unless ($access && $access->{access_token}) {
        print STDERR "No access_token found. You are not logged in yet?\n";
        return 2;
    }

    my $token = $access->{access_token};

    my ($header,$payload,$signature) = split(/\./,$token,3);

    unless ($header && $payload, $signature) {
        printf STDERR "Token is not a jwt token\n";
    }

    my $json = JSON->new->pretty;

    $header  = JSON::decode_json(MIME::Base64::decode_base64url($header));
    $payload = JSON::decode_json(MIME::Base64::decode_base64url($payload));

    printf "Header: %s\n" , $json->encode($header);
    printf "Payload: %s\n" , $json->encode($payload);
    printf "Signature: (binary data)\n", MIME::Base64::decode_base64url($signature);

    return 0;
}

sub cmd_id_token {
    my $access = $auth->get_access_token;

    unless ($access && $access->{id_token}) {
        print STDERR "No access_token found. You are not logged in yet?\n";
        return 2;
    }

    my $token = $access->{id_token};

    my ($header,$payload,$signature) = split(/\./,$token,3);

    unless ($header && $payload, $signature) {
        printf STDERR "Token is not a jwt token\n";
    }

    my $json = JSON->new->pretty;

    $header  = JSON::decode_json(MIME::Base64::decode_base64url($header));
    $payload = JSON::decode_json(MIME::Base64::decode_base64url($payload));

    printf "Header: %s\n" , $json->encode($header);
    printf "Payload: %s\n" , $json->encode($payload);
    printf "Signature: (binary data)\n", MIME::Base64::decode_base64url($signature);

    return 0;
}

# Parse the optional provided headers into a hash
sub _make_headers {
    my %headers = ();
    for my $h (@$opt_header) {
        my ($n,$v) = split(/\s*:\s*/,$h,2);
        $headers{$n} = $v;
    }
    return %headers;
}

# Add a Link header 
sub _link_header {
    my ($link,%headers) = @_;

    if (exists $headers{Link}) {
        $headers{Link} .= ", $link";
    }
    else {
        $headers{Link} = $link;
    }

    %headers;
}

# Expand a relative url to a full url with SOLID_REMOTE_BASE
sub _make_url {
    my $url = shift;

    return $url if $url =~ /^http.*/;

    return $url unless defined($webbase);

    return $url unless $url =~ /^\.?(\/.*)?/;

    return "$webbase$1";
}

# Expand the CURL header with authentication and DPop headers
sub _authentication_headers {
    my ($method,$url) = @_;

    $webid //= $url;

    my $headers = $auth->make_authentication_headers($url,$method);

    unless ($headers) {
        print STDERR "No access tokens found for $webid. Maybe you need to authenticate first?\n";
    }

    my @headers = ();
    for (keys %$headers) {
        push @headers , "-H \"" . $_ . ":" . $headers->{$_} ."\"";
    }

    return join(" ",@headers);
}

# Guess the mime type of a file
sub _guess_mimetype {
    my ($path) = @_;
    
    my $magic = File::LibMagic->new;

    # My own MIME magic
    return "text/turtle" if ($path =~ /\.ttl$/);
    return "text/turtle" if ($path =~ /\.acl$/);
    return "application/ld+json" if ($path =~ /\.jsonld$/);
    return "text/n3" if ($path =~ /\.n3$/);
    return "application/rdf+xml" if ($path =~ /\.rdf$/);

    # If the file is empty 
    if (! -e $path || -s $path) {
        my $info = $magic->info_from_filename($path);
        return $info->{mime_type};
    }
    else {
        # Open the file and do magic guessing
        open my $fh, '<', $path or die $!;
        my $info = $magic->info_from_handle($fh);
        close($fh);
        return $info->{mime_type};
    }
}

__END__

=head1 NAME

solid_auth.pl - A Solid management tool

=head1 SYNOPSIS

      # Set your default webid
      export SOLID_WEBID=https://timbl.inrupt.net/profile/card#me

      # Authentication to a pod
      solid_auth.pl authenticate

      # Get the http headers for a authenticated request
      solid_auth.pl headers GET https://timbl.inrupt.net/inbox/

      # Act like a curl command and fetch authenticated content
      solid_auth.pl curl -- -X GET https://timbl.inrupt.net/inbox/

      # Add some data
      solid_auth.pl curl -- -X POST \
            -H "Content-Type: text/plain" \
            -d "abc" \
            https://timbl.inrupt.net/public/
    
      # Add a file
      solid_auth.pl curl -- -X PUT \
            -H "Content-Type: application/ld+json" \
            -d "@myfile.jsonld" \
            https://timbl.inrupt.net/public/myfile.jsonld 

      # Set a solid base url
      export SOLID_REMOTE_BASE=https://timbl.inrupt.net

      # List all resources on some Pod path
      solid_auth.pl list /public/

      # Get some data
      solid_auth.pl get /inbox/

      # Post some data
      solid_auth.pl post /inbox/ myfile.jsonld 

      # Put some data
      solid_auth.pl -f put /public/myfile.txt myfile.txt 

      # Patch data
      solid_auth.pl -f patch /public/myfile.txt.meta  - <<EOF
      INSERT DATA { <> <http://example.org> 1234 }
      EOF
      
      # Create a folder
      solid_auth.pl -f put /public/mytestfolder/

      # Delete some data
      solid_auth.pl delete /public/myfile.txt

      # Mirror a resource, container or tree
      mkdir /data/my_copy
      solid_auth.pl -r mirror /public/ /data/my_copy

      # Upload a directory to the pod
      #  Add the -x option to do it for real (only a test without this option)
      solid_auth.pl -r upload /data/my_copy /public/

      # Clean all files in a container
      #  Add the -x option to do it for real (only a test without this option)
      solid_auth.pl --keep clean /demo/

      # Clean a complete container 
      #  Add the -x option to do it for real (only a test without this option)
      solid_auth.pl -r clean /demo/

=head1 ENVIRONMENT

=over

=item SOLID_WEBID

Your WebId.

=item SOLID_REMOTE_BASE

The Base URL that is used for all delete, get, head, options post, put, patch requests.

=item SOLID_CLIENT_ID

The URL to a static client configuration. See C<etc/web-solid-auth.jsonld> for an example.
This file, edited for your own environment, needs to be published on some public accessible
webserver.

=back

=head1 CONFIGURATION

=over

=item --webid 

Your WebId.

=item --base

The Base URL that is used for all delete, get, head, options post, put, patch requests.

=item --clientid

The URL to a static client configuration. See C<etc/web-solid-auth.jsonld> for an example.
This file, edited for your own environment, needs to be published on some public accessible
webserver.

=item --skip

Skip resources that already exist (mirror).

=item --delete

Delete local files that are not in the remote container (mirror).

=item --keep

Keep containers when cleaning data (clean).

=item --etag=STRING

Only update the data when the 'Etag' header matches the given string (put,patch). E.g.
use the C<head> command to find the ETag of a resource :

    $ solid_auth.pl head /demo/LICENSE
    ...
    ETag: "189aa19989dc47eab46c9f2e8c47d0836bb08cb09f7863cbf3cd3bb9a751be27"
    ...

Now update the resource with ETag protection

    $ solid_auth.pl \
        --etag=189aa19989dc47eab46c9f2e8c47d0836bb08cb09f7863cbf3cd3bb9a751be27 \
        put /demo/LICENSE LICENSE

=item --force | -f

Force overwriting existing resources (put, patch).

=item -r

Recursive (clean, mirror, upload).

=item -x

Do it for real. The commands C<clean> and C<upload> will run by default in safe mode.

=item -H name=value

Add a header to a request (repeatable) for C<get>, C<post>, C<head>, C<options> and C<delete>.

=back

=head1 COMMAND

=over 

=item authenticate

Start an authentication process for your WebId. You will be presented with a 
URL that you need to open in a webbrowser. After a successfull login the 
command can be closed. 

The webbrowser needs to be opened on the same host as the where you where you
run the solid_auth.pl command. 

=item headers METHOD URL

Return the Authentication and DPoP headers for a HTTP C<METHOD> request to C<URL>.

=item curl CURL-OPTS

Execute a curl command with Authentication and DPoP headers added. Add a C<--> 
option to the C<CURL-OPTS> to stop solid_auth.pl from interpreting Curl options.

=item list URL

List the resources in a LDP container at URL.

=item mirror [-rx] [--skip] [--delete] URL DIRECTORY

Mirror the contents of a container to a local directory. Optional provide C<-r>
option for recursive mirror.

=item upload [-rx] DIRECTORY URL

Upload a directorty to a container. Optional provide C<-r> option for recursive
upload. With the C<-x> option, the command will run in demo mode.

=item clean [-rx] [--keep] URL

Clean all resources in a directory. Optional provide C<-r> option for recursive
clean. With the C<-x> option, the command will run in demo mode. With the
C<--keep> options all container will be kept.

=item get URL

Return the response of a HTTP GET request to URL.

=item post URL FILE [MIMETYPE]

Return the HTTP Message of a HTTP POST request of the FILE with MIMETYPE.
Uses libmagic to guess the mimetype.

=item put URL [FILE] [MIMETYPE]

Return the HTTP Message of a HTTP PUT request of the FILE with MIMETYPE.
Uses libmagic to guess the mimetype.

When the URL ends with a slash (/), then a new container will be created.

=item patch URL FILE|SPARQL

Send the contents of a SPARQL patch file or string to a URL. Return the
HTTP Message of the HTTP PATCH request to the URL.

=item head URL

Return the HTTP Header of a HTTP HEAD request to URL.

=item head OPTIONS

Return the HTTP Header of a HTTP OPTIONS request to URL.

=item delete URL

Return the HTTP Message of a HTTP DELETE request to URL.

=item id_token

Show the contents of the JWT id token.

=item access_token

Show the contents of the JWT access token.

=back

=head1 INSPIRATION

This was very much inspired by the Python solid-flask code by
Rai L<http://agentydragon.com> at L<https://gitlab.com/agentydragon/solid-flask>,
and Jeff Zucker's <https://github.com/jeff-zucker> Solid-Shell at L<https://www.npmjs.com/package/solid-shell>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Patrick Hochstenbach.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=encoding utf8

=cut
