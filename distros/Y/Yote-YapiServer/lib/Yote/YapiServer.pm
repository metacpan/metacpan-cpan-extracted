package Yote::YapiServer;

use strict;
use warnings;

our $VERSION = '0.02';

use IO::Socket::INET;
use File::Spec;

use Yote::SQLObjectStore;
use Yote::YapiServer::Site;
use Yote::YapiServer::Handler;

sub new {
    my ($class, %args) = @_;
    my $db = $args{db} // { type => 'SQLite', data_dir => $args{data_dir} // 'data' };
    return bless {
        port           => $args{port}           // 5001,
        db             => $db,
        root_package   => $args{root_package}   // 'Yote::YapiServer::Site',
        lib_paths      => $args{lib_paths}      // [],
        endpoint       => $args{endpoint}       // '/yapi',
        max_file_size  => $args{max_file_size}  // 5_000_000,
        webroot_dir    => $args{webroot_dir}    // 'www/webroot',
    }, $class;
}

sub _new_store {
    my ($self) = @_;
    my $db = $self->{db};
    my $type = $db->{type} // 'SQLite';

    if ($type eq 'SQLite') {
        my $data_dir = $db->{data_dir} // 'data';
        mkdir $data_dir unless -d $data_dir;
        return Yote::SQLObjectStore->new(
            'SQLite',
            BASE_DIRECTORY => $data_dir,
            root_package   => $self->{root_package},
        );
    }
    elsif ($type eq 'MariaDB') {
        return Yote::SQLObjectStore->new(
            'MariaDB',
            dbname       => $db->{dbname},
            username     => $db->{username},
            password     => $db->{password},
            root_package => $self->{root_package},
        );
    }
    else {
        die "Unknown db type: $type (expected SQLite or MariaDB)\n";
    }
}

sub run {
    my ($self) = @_;

    my $port         = $self->{port};
    my $root_package = $self->{root_package};
    my $endpoint     = $self->{endpoint};

    # Set Handler config
    $Yote::YapiServer::Handler::max_file_size = $self->{max_file_size};
    $Yote::YapiServer::Handler::webroot_dir   = $self->{webroot_dir};

    print "Initializing database ($self->{db}{type})\n";

    my $store = $self->_new_store;

    # Create/update database tables by explicitly generating tables for
    # known classes. The recursive reference following in
    # generate_table_from_module handles dependencies automatically.
    print "Creating/updating database tables...\n";
    {
        my $manager = $store->get_table_manager;
        my $name2table = {};

        # Load root package
        my $root_file = $root_package;
        $root_file =~ s/::/\//g;
        require "$root_file.pm";

        # Core infrastructure tables
        for my $mod (
            $root_package,
            'Yote::YapiServer::User',
            'Yote::YapiServer::Session',
            'Yote::YapiServer::File',
        ) {
            $manager->generate_table_from_module($name2table, $mod);
        }

        # Installed app tables (and their referenced classes)
        if ($root_package->can('installed_apps')) {
            for my $app_class (values %{$root_package->installed_apps}) {
                $manager->generate_table_from_module($name2table, $app_class);
            }
        }

        # Bootstrap: create ObjectIndex, TableDefs, TableVersions first
        # (these are always needed by SQLObjectStore infrastructure)
        my @sql = (
            [$manager->create_object_index_sql],
            [$manager->create_table_defs_sql],
            [$manager->create_table_versions_sql],
        );
        # Execute CREATE TABLE IF NOT EXISTS for all application tables
        for my $table_name (sort keys %$name2table) {
            push @sql, [$name2table->{$table_name}];
        }

        $store->start_transaction;
        for my $s (@sql) {
            my ($query, @qparams) = @$s;
            $store->query_do($query, @qparams);
        }
        $store->commit_transaction;
    }

    # Open the store
    $store->open;

    # Get or create root object
    my $root = $store->fetch_root;
    $root->init;
    $store->save;

    print "Server starting on http://localhost:$port\n";
    print "Press Ctrl+C to stop.\n\n";

    # Create server socket
    my $listener = IO::Socket::INET->new(
        LocalAddr => '0.0.0.0',
        LocalPort => $port,
        Proto     => 'tcp',
        Listen    => SOMAXCONN,
        Reuse     => 1,
    ) or die "Cannot create socket: $!";

    # Reap zombie processes
    $SIG{CHLD} = 'IGNORE';

    while (my $conn = $listener->accept) {
        my $pid = fork();

        if (!defined $pid) {
            warn "Fork failed: $!";
            $conn->close;
            next;
        }

        if ($pid == 0) {
            # Child process
            $listener->close;

            # Reconnect to database in child
            my $child_store = $self->_new_store;
            $child_store->open;

            eval {
                $self->handle_request($conn, $child_store, $endpoint);
            };

            warn "Error: $@" if $@;

            $conn->close;
            exit(0);
        }

        # Parent
        $conn->close;
    }
}

sub handle_request {
    my ($self, $conn, $store, $endpoint) = @_;

    # Read request
    my $request = '';
    $conn->recv($request, 65536);

    return unless $request;

    # Parse HTTP request
    my ($headers, $body) = split(/\r\n\r\n/, $request, 2);
    my @header_lines = split(/\r\n/, $headers);
    my $request_line = shift @header_lines;

    my ($method, $path, $version) = split(/\s+/, $request_line);

    # Parse headers
    my %headers;
    for my $line (@header_lines) {
        my ($key, $value) = split(/:\s*/, $line, 2);
        $headers{lc($key)} = $value;
    }

    # Get client IP
    my $ip = $conn->peerhost || '127.0.0.1';

    # CORS headers for all responses
    my @cors = (
        'Access-Control-Allow-Origin: *',
        'Access-Control-Allow-Methods: POST, OPTIONS',
        'Access-Control-Allow-Headers: Content-Type',
    );

    # Handle OPTIONS (CORS preflight)
    if ($method eq 'OPTIONS') {
        my $response = "HTTP/1.1 200 OK\r\n";
        $response .= join("\r\n", @cors) . "\r\n";
        $response .= "Content-Length: 0\r\n";
        $response .= "Connection: close\r\n";
        $response .= "\r\n";
        $conn->send($response);
        return;
    }

    # Only handle POST to endpoint
    unless ($method eq 'POST' && $path eq $endpoint) {
        my $not_found = '{"ok":0,"error":"Not found"}';
        my $response = "HTTP/1.1 404 Not Found\r\n";
        $response .= "Content-Type: application/json\r\n";
        $response .= "Content-Length: " . length($not_found) . "\r\n";
        $response .= join("\r\n", @cors) . "\r\n";
        $response .= "Connection: close\r\n";
        $response .= "\r\n";
        $response .= $not_found;
        $conn->send($response);
        return;
    }

    # Handle Content-Length for body — reject oversized requests
    my $content_length = $headers{'content-length'} || 0;
    my $max_body = $self->{max_file_size} * 2;
    if ($content_length > $max_body) {
        my $err = '{"ok":0,"error":"request too large"}';
        my $response = "HTTP/1.1 413 Payload Too Large\r\n";
        $response .= "Content-Type: application/json\r\n";
        $response .= "Content-Length: " . length($err) . "\r\n";
        $response .= join("\r\n", @cors) . "\r\n";
        $response .= "Connection: close\r\n";
        $response .= "\r\n";
        $response .= $err;
        $conn->send($response);
        return;
    }
    while (length($body || '') < $content_length) {
        my $more;
        $conn->recv($more, $content_length - length($body || ''));
        last unless $more;
        $body .= $more;
    }
    #print "[YAPI] $ip: $body\n";

    # Process request
    my $result = Yote::YapiServer::Handler->handle(
        store      => $store,
        body       => $body,
        ip_address => $ip,
    );

    #print "[YAPI] Response: $result\n\n";

    # Send response
    my $response = "HTTP/1.1 200 OK\r\n";
    $response .= "Content-Type: application/json; charset=utf-8\r\n";
    $response .= "Content-Length: " . length($result) . "\r\n";
    $response .= join("\r\n", @cors) . "\r\n";
    $response .= "Connection: close\r\n";
    $response .= "\r\n";
    $response .= $result;

    $conn->send($response);
}

1;

__END__

=head1 NAME

Yote::YapiServer - HTTP server for Yote API

=head1 SYNOPSIS

    use Yote::YapiServer;

    my $server = Yote::YapiServer->new(
        port         => 5001,
        db           => { type => 'SQLite', data_dir => 'data' },
        root_package => 'Yote::YapiServer::Site',
        lib_paths    => ['lib'],
        endpoint     => '/yapi',
    );
    $server->run;

=head1 DESCRIPTION

HTTP server class for the Yote API framework. Handles socket listening,
fork-per-connection request handling, and HTTP parsing. Delegates API
request processing to Yote::YapiServer::Handler.

=head1 CONSTRUCTOR

=head2 new(%args)

    port         - Port to listen on (default: 5001)
    db           - Database config hash (see below)
    root_package - Root database object class (default: 'Yote::YapiServer::Site')
    lib_paths    - Array of lib paths for table discovery
    endpoint     - API endpoint path (default: '/yapi')

    db keys:
      type     - 'SQLite' or 'MariaDB' (default: 'SQLite')
      data_dir - Directory for SQLite files (default: 'data')
      dbname   - MariaDB database name
      username - MariaDB username
      password - MariaDB password

=head1 METHODS

=head2 run()

Starts the HTTP server. Initializes the database, opens the store,
and enters the accept loop.

=head2 handle_request($conn, $store, $endpoint)

Handles a single HTTP request on the given connection.

=cut
