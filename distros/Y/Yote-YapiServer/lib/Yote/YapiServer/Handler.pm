package Yote::YapiServer::Handler;

use strict;
use warnings;

use JSON::PP;
use B ();
use Time::HiRes qw(time);
use Data::Dumper;

# Detect whether a scalar's SV holds a numeric (not a numeric-looking
# string). Declared literals `0` / `1.5` have IOK/NOK set without POK;
# `'0'` / `'1.5'` have POK set. This is what JSON encoders use too.
sub _is_numeric_sv {
    my ($v) = @_;
    my $flags = B::svref_2object(\$v)->FLAGS;
    return (($flags & (B::SVf_IOK | B::SVf_NOK)) && !($flags & B::SVf_POK));
}
use Yote::YapiServer::Site;
use Yote::YapiServer::Session;
use Yote::YapiServer::File;

# Config vars — set by YapiServer during startup
our $max_file_size = 5_000_000;   # 5MB default
our $webroot_dir   = 'www/webroot';
our $debug_mode    = 1;

# Rate limit tracking (in-memory, resets on server restart)
our %rate_limits;  # { ip => { endpoint => { count => N, window_start => T } } }

#----------------------------------------------------------------------
# Main request handler
#----------------------------------------------------------------------

sub handle {
    my ($class, %args) = @_;

    my $store      = $args{store};
    my $json_body  = $args{body};
    my $ip_address = $args{ip_address} // '127.0.0.1';

    # Parse JSON request
    my $request;
    eval {
        $request = decode_json($json_body);
    };
    if ($@) {
        return $class->error_response("invalid JSON: $@");
    }

    # Extract request fields
    my $action = $request->{action};  # connect, call, login, createUser, logout
    my $token  = $request->{token};
    my $app    = $request->{app};
    my $target = $request->{target};  # app name or _obj_ID
    my $method = $request->{method};
    my $args_  = $request->{args} // {};

    # Build context
    my $context = {
        ip_address => $ip_address,
        request    => $request,
    };

    # Wrap entire request handling so uncaught errors return JSON, not HTTP 500
    my ($succ, $res, $extra);
    my ($root, $session, $user);
    eval {
        # Validate token if provided
        $root = $store->fetch_root // $store->new_obj('Yote::YapiServer::Site');
        $root->init;
        if ($token) {
            $session = $root->validateToken($token);
            if ($session) {
                $user = $session->get_user;
                $context->{session} = $session;
                $context->{user} = $user;
            }
        }

        # Create anonymous session if none exists so exposed objects can be tracked
        if (!$session) {
            my $new_token = Yote::YapiServer::Session->generate_token();
            my $expires = Yote::YapiServer::Session->calculate_expiry();
            $session = $store->new_obj('Yote::YapiServer::Session',
                token      => $new_token,
                expires    => $expires,
                ip_address => $ip_address,
            );
            $session->touch;
            $store->set_path('sessions', $new_token, $session);
            $context->{session} = $session;
        }

        # Handle actions
        if ($action eq 'connect') {
            ($succ, $res, $extra) = $class->handle_connect($root, $app, $session, $user);
        }
        elsif ($action eq 'login') {
            ($succ, $res, $extra) = $class->check_rate_limit('login', $ip_address, undef)
                   // $root->login($args_, $context);
        }
        elsif ($action eq 'createUser') {
            ($succ, $res, $extra) = $class->check_rate_limit('createUser', $ip_address, undef)
                   // $root->createUser($args_, $context);
        }
        elsif ($action eq 'logout') {
            ($succ, $res, $extra) = $root->logout($args_, $context);
        }
        elsif ($action eq 'call') {
            ($succ, $res, $extra) = $class->check_rate_limit('default', $ip_address, $session)
                   // $class->handle_call($root, $target, $method, $args_, $session, $user, $store);
        }
        else {
            ($succ, $res) = (0, "unknown action: $action");
        }

        $store->save;
    };

    if ($@) {
        chomp(my $error = $@);
        $class->log_error($context, $error);
        my $msg = $debug_mode ? $error : "server error";
        return $class->error_response($msg);
    }

    if (!$succ) {
        return $class->error_response($res);
    }

    # For login/createUser/logout, serialize the result through serialize_value
    # (handle_connect and handle_call already do their own serialization)
    if ($action =~ /^(login|createUser|logout)$/ && defined $res) {
        my $ctx = { objects => {}, classes => {} };
        $res = $class->serialize_value($res, $ctx, $session, $user);
        $extra //= {};
        $extra->{objects} = $ctx->{objects} if %{$ctx->{objects}};
        $extra->{classes} = $ctx->{classes} if %{$ctx->{classes}};
    }

    # Use session from extra token if login/createUser created a new one
    if ($extra && $extra->{token}) {
        my $new_session = $root->validateToken($extra->{token});
        $session = $new_session if $new_session;
    }

    return $class->success_response($res, $extra, $session);
}

#----------------------------------------------------------------------
# Action handlers
#----------------------------------------------------------------------

sub handle_connect {
    my ($class, $root, $app_name, $session, $user) = @_;

    return 0, "app name required" unless $app_name;

    my $app = $root->get_app($app_name);
    return 0, "unknown app: $app_name" unless $app;

    # Expose app to session
    $session->expose_object($app);

    my $app_id = "_app_$app_name";
    my $methods = $app->connect_info_methods($session, $user);
    my $public_vars = $app->public_vars;

    my $ctx = { objects => {}, classes => {} };

    # Build app object data from publicVars (serialize values for v/r prefixing)
    my %serialized_vars;
    for my $key (keys %$public_vars) {
        $serialized_vars{$key} = $class->serialize_value($public_vars->{$key}, $ctx, $session, $user);
    }
    $ctx->{objects}{$app_id} = {
        _class => $app->_client_class_name,
        data   => \%serialized_vars,
    };

    # Add app methods to apps section
    my %apps = ( $app_id => $methods );

    # Serialize user into objects/classes if present
    if ($user) {
        $class->serialize_value($user, $ctx, $session, $user);
    }

    return 1, "r$app_id", { objects => $ctx->{objects}, classes => $ctx->{classes}, apps => \%apps };
}

sub handle_call {
    my ($class, $root, $target, $method, $args, $session, $user, $store) = @_;

    return 0, "target required" unless $target;
    return 0, "method required" unless $method;

    my $target_obj;

    # Determine target object
    if ($target =~ /^_obj_(\d+)$/) {
        # Object reference
        my $obj_id = $1;

        # Security: verify object is in session's exposed set
        unless ($session && $session->can_access($obj_id)) {
            return 0, "access denied";
        }

        $target_obj = $store->fetch($obj_id);
        return 0, "object not found" unless $target_obj;
    }
    elsif ($target =~ /^_app_(.+)$/) {
        # App reference via _app_ ID
        my $app_name = $1;
        $target_obj = $root->get_app($app_name);
        return 0, "unknown app: $app_name" unless $target_obj;
    }
    else {
        # App name (legacy)
        $target_obj = $root->get_app($target);
        return 0, "unknown app: $target" unless $target_obj;
    }

    # Look up method definition for files flag
    my $method_def = {};
    if ($target_obj->can('method_defs')) {
        my $methods = $target_obj->method_defs;
        $method_def = $methods->{$method} // {};
    }

    # Validate arguments with v/r/f prefix dispatch
    my $opts = {
        session       => $session,
        store         => $store,
        allow_files   => $method_def->{files},
        max_file_size => $max_file_size,
        webroot_dir   => $webroot_dir,
        user          => $user,
    };
    my ($args_ok, $validated_args) = $class->validate_args($args, $opts);
    return 0, $validated_args unless $args_ok;

    # Authorize method call
    my ($auth_ok, $auth_error);
    if ($target =~ /^_obj_/) {
        # Object method - use object-level authorization
        ($auth_ok, $auth_error) = Yote::YapiServer::App::Base->authorize_object_method(
            $target_obj, $method, $session, $user
        );
    } else {
        # App method
        ($auth_ok, $auth_error) = $target_obj->authorize_method($method, $session, $user);
    }

    return 0, $auth_error unless $auth_ok;

    # Call the method — methods return (1, $result) or (0, $error)
    unless ($target_obj->can($method)) {
        return 0, "method not implemented: $method";
    }

    my ($ok, $result) = $target_obj->$method($validated_args, $session);
    return 0, $result unless $ok;

    # Serialize result with context accumulation
    my $ctx = { objects => {}, classes => {} };
    my $resp = $class->serialize_value($result, $ctx, $session, $user);

    my %extra;
    $extra{objects} = $ctx->{objects} if %{$ctx->{objects}};
    $extra{classes} = $ctx->{classes} if %{$ctx->{classes}};

    return 1, $resp, \%extra;
}

#----------------------------------------------------------------------
# Argument validation
#----------------------------------------------------------------------

sub validate_args {
    my ($class, $args, $opts) = @_;

    # Array — recurse into each element
    if (ref $args eq 'ARRAY') {
        my @validated;
        for my $item (@$args) {
            my ($ok, $result) = $class->validate_args($item, $opts);
            return (0, $result) unless $ok;
            push @validated, $result;
        }
        return (1, \@validated);
    }

    # Hash — recurse into values
    if (ref $args eq 'HASH') {
        my %validated;
        for my $key (keys %$args) {
            my ($ok, $result) = $class->validate_args($args->{$key}, $opts);
            return (0, $result) unless $ok;
            $validated{$key} = $result;
        }
        return (1, \%validated);
    }

    # Leaf value — dispatch on v/r/f prefix
    return (1, undef) unless defined $args;

    # v prefix — scalar value
    if ($args =~ /^v(.*)$/s) {
        return (1, $1);
    }

    # r prefix — object reference
    if ($args =~ /^r_obj_(\d+)$/) {
        my $obj_id = $1;
        my $session = $opts->{session};
        my $store   = $opts->{store};

        unless ($session && $session->can_access($obj_id)) {
            return (0, "access denied to object: _obj_$obj_id");
        }

        my $obj = $store->fetch($obj_id);
        return (0, "object not found: _obj_$obj_id") unless $obj;

        return (1, $obj);
    }

    # f prefix — file upload
    if ($args =~ /^f/) {
        unless ($opts->{allow_files}) {
            return (0, "file uploads not allowed for this method");
        }
        return $class->process_file_arg($args, $opts);
    }

    # No valid prefix
    return (0, "invalid argument encoding: missing v/r/f prefix");
}

#----------------------------------------------------------------------
# File upload processing
#----------------------------------------------------------------------

sub process_file_arg {
    my ($class, $value, $opts) = @_;

    # Parse: f<original_name>|data:<mime_type>;base64,<encoded_data>
    unless ($value =~ /^f([^|]*)\|data:([^;]+);base64,(.+)$/s) {
        return (0, "invalid file format");
    }

    my $original_name = $1;
    my $mime_type     = $2;
    my $encoded_data  = $3;

    # Validate MIME type
    my $ext = _mime_to_ext($mime_type);
    return (0, "unsupported file type: $mime_type") unless $ext;

    # Decode base64
    require MIME::Base64;
    my $data = MIME::Base64::decode_base64($encoded_data);

    # Check file size
    my $max_size = $opts->{max_file_size} // 5_000_000;
    if (length($data) > $max_size) {
        return (0, "file too large (max " . int($max_size / 1_000_000) . "MB)");
    }

    # Hash content for filename
    require Digest::SHA;
    my $hash   = Digest::SHA::sha256_hex($data);
    my $prefix = substr($hash, 0, 2);
    my $filename = "$hash.$ext";

    # Save to webroot/img/<prefix>/
    my $webroot = $opts->{webroot_dir} // 'www/webroot';
    my $dir = "$webroot/img/$prefix";

    require File::Path;
    File::Path::make_path($dir) unless -d $dir;

    my $file_path = "$dir/$filename";

    # Content-addressed dedup — only write if not already present
    unless (-f $file_path) {
        open my $fh, '>', $file_path or return (0, "failed to save file");
        binmode $fh;
        print $fh $data;
        close $fh;
    }

    # Create File object in store
    my $store = $opts->{store};
    my $url   = "/img/$prefix/$filename";

    my $file_obj = $store->new_obj('Yote::YapiServer::File',
        url           => $url,
        type          => $mime_type,
        size          => length($data),
        original_name => $original_name,
        file_path     => $file_path,
    );
    $file_obj->set_owner($opts->{user}) if $opts->{user};

    return (1, $file_obj);
}

sub _mime_to_ext {
    my ($mime) = @_;
    my %map = (
        'image/jpeg'       => 'jpg',
        'image/png'        => 'png',
        'image/gif'        => 'gif',
        'image/webp'       => 'webp',
        'image/svg+xml'    => 'svg',
        'application/pdf'  => 'pdf',
        'text/plain'       => 'txt',
        'text/csv'         => 'csv',
        'application/json' => 'json',
    );
    return $map{$mime};
}

#----------------------------------------------------------------------
# Serialization
#----------------------------------------------------------------------

sub serialize_value {
    my ($class, $value, $ctx, $session, $viewer) = @_;

    return undef unless defined $value;

    # Array
    if (ref($value) eq 'ARRAY') {
        return [ map { $class->serialize_value($_, $ctx, $session, $viewer) } @$value ];
    }

    # Plain hash (unblessed)
    if (ref($value) eq 'HASH') {
        my %result;
        for my $key (keys %$value) {
            $result{$key} = $class->serialize_value($value->{$key}, $ctx, $session, $viewer);
        }
        return \%result;
    }

    # Object with to_client_hash (blessed ref)
    if (ref($value) && $value->can('to_client_hash')) {
        my $obj_id = "_obj_" . $value->id;

        # Dedup: skip objects already in ctx (or being serialized)
        unless ($ctx->{objects}{$obj_id}) {
            # Reserve slot to break circular references (e.g. User->File->User)
            $ctx->{objects}{$obj_id} = 1;

            # Get the class name
            my $client_class;
            if ($value->can('_client_class_name')) {
                $client_class = $value->_client_class_name;
            } else {
                $client_class = ref($value);
                $client_class =~ s/^Yote::YapiServer::App:://;
                $client_class =~ s/^Yote::YapiServer:://;
            }

            # Get data fields from to_client_hash
            my $data = $value->to_client_hash($session, $viewer);

            # Recursively serialize values within data
            my %serialized_data;
            for my $key (keys %$data) {
                $serialized_data{$key} = $class->serialize_value($data->{$key}, $ctx, $session, $viewer);
            }

            $ctx->{objects}{$obj_id} = {
                _class => $client_class,
                data   => \%serialized_data,
            };

            # Add methods to classes (once per class)
            if (!$ctx->{classes}{$client_class} && $value->can('method_defs')) {
                my $methods = $value->method_defs;
                $ctx->{classes}{$client_class} = [ sort keys %$methods ];
            }

            # Expose object to session
            $session->expose_object($value) if $session;
        }

        return "r$obj_id";
    }

    # Numeric scalar (declared as a number) — emit as JSON number so it
    # round-trips as a number, not a truthy string like "0". Strings
    # (including numeric-looking strings like version '1.0') get the
    # 'v' prefix to disambiguate from 'r'-prefixed references.
    if (_is_numeric_sv($value)) {
        return $value + 0;
    }
    return "v$value";
}

#----------------------------------------------------------------------
# Rate limiting
#----------------------------------------------------------------------

sub check_rate_limit {
    my ($class, $endpoint, $ip, $session) = @_;

    my $config = $Yote::YapiServer::Site::RATE_LIMITS{$endpoint}
              // $Yote::YapiServer::Site::RATE_LIMITS{default};

    return undef unless $config;

    my $now = time();
    my $key;
    my $limit;

    if ($config->{per_ip}) {
        $key = "ip:$ip:$endpoint";
        $limit = $config->{per_ip};
    }
    elsif ($config->{per_session} && $session) {
        $key = "session:" . $session->get_token . ":$endpoint";
        $limit = $config->{per_session};
    }
    else {
        return undef;  # No applicable limit
    }

    my $window = $config->{window} // 60;

    # Initialize or reset window
    $rate_limits{$key} //= { count => 0, window_start => $now };

    if ($now - $rate_limits{$key}{window_start} > $window) {
        $rate_limits{$key} = { count => 0, window_start => $now };
    }

    # Check limit
    if ($rate_limits{$key}{count} >= $limit) {
        return 0, "rate limit exceeded, try again later";
    }

    # Increment
    $rate_limits{$key}{count}++;

    return undef;  # OK to proceed
}

#----------------------------------------------------------------------
# Response formatting
#----------------------------------------------------------------------

sub success_response {
    my ($class, $resp, $extra, $session) = @_;
    $extra //= {};

    my %envelope = ( ok => 1, resp => $resp );

    # Always include token when there's a session
    if ($session && $session->can('get_token')) {
        $envelope{token} = $session->get_token;
    }

    # Token from extra (login/createUser) overrides session token
    if ($extra->{token}) {
        $envelope{token} = $extra->{token};
    }

    # Merge extra fields (objects, classes, apps)
    for my $key (qw(objects classes apps)) {
        $envelope{$key} = $extra->{$key} if $extra->{$key};
    }

    return encode_json(\%envelope);
}

sub error_response {
    my ($class, $error) = @_;
    return encode_json({ ok => 0, error => $error });
}

#----------------------------------------------------------------------
# Logging
#----------------------------------------------------------------------

sub log_error {
    my ($class, $context, $error) = @_;
    my $ip = $context->{ip_address} // 'unknown';
    my $action = $context->{request}{action} // 'unknown';
    warn "[Yote::YapiServer::Site] ERROR ip=$ip action=$action error=$error\n";
}

sub log_call {
    my ($class, $context, $target, $method, $success) = @_;
    # Implement audit logging here if needed
}

1;

__END__

=head1 NAME

Yote::YapiServer::Handler - JSON API request handler

=head1 DESCRIPTION

Handles incoming JSON requests for the Spiderpup server. Provides:

  - Request parsing and validation
  - Token-based authentication
  - Method dispatch with authorization
  - Object capability enforcement
  - Rate limiting
  - Response serialization

=head1 REQUEST FORMAT

    {
        "action": "connect" | "call" | "login" | "createUser" | "logout",
        "token": "session_token",        // optional
        "app": "appName",                // for connect
        "target": "appName" | "_obj_ID", // for call
        "method": "methodName",          // for call
        "args": { ... }                  // method arguments (v/r/f prefixed)
    }

=head1 RESPONSE FORMAT

    {
        "ok": 1,
        "token": "session_token",
        "resp": "<value>",
        "classes": { "ClassName": ["method1", "method2"] },
        "objects": { "_obj_42": { "_class": "ClassName", "data": { ... } } },
        "apps":    { "_app_example": ["hello", "getStats"] }
    }

Error response:

    {
        "ok": 0,
        "error": "error message"
    }

=cut
