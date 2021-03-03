package Web::Solid::Auth::Listener;

use Moo;
use Log::Any ();
use Plack::Request;
use Plack::Response;
use HTTP::Server::PSGI;

our $VERSION = "0.3";

has host => (
    is => 'ro' ,
    default => sub { 'localhost' }
);
has port => (
    is => 'ro' ,
    default => sub { '3000' }
);
has scheme => (
    is => 'ro' ,
    default => sub { 'http' }
);
has path => (
    is => 'ro',
    default => sub { '/callback' }
);
has log => (
    is => 'ro',
    default => sub { Log::Any->get_logger },
);

sub redirect_uri {
    my $self = shift;

    return sprintf "%s://%s:%s%s"
                    , $self->scheme
                    , $self->host
                    , $self->port
                    , $self->path;
}

sub run {
    my ($self,$auth) = @_;
    $auth //= $self->auth;

    my $host = $self->host;
    my $port = $self->port;
    my $path = $self->path;

    $self->log->info("starting callback server on $host:$port$path");

    my $server = HTTP::Server::PSGI->new(
        host => $host,
        port => $port,
        timeout => 120,
    );

    $server->run(
      sub {
        my $env = shift;

        my $req    = Plack::Request->new($env);
        my $param  = $req->parameters;
        my $state  = $auth->{state};

        $self->log->debugf("received: %s (%s) -> %s", $req->method, $req->path, $req->query_string);

        # Check if we got the correct path
        unless ($req->path eq $path) {
            my $res = Plack::Response->new(404);
            $res->content_type("text/plain");
            $res->body("No such path");
            return $res->finalize;
        }

        # Check if we got the correct state
        unless ($req->method eq 'GET' && $param->{code} && $param->{state} eq $state ) {
            my $res = Plack::Response->new(404);
            $res->content_type("text/plain");
            $res->body("Failed to get an access_token");
            return $res->finalize;
        }

        my $data = $auth->make_access_token($param->{code});

        if ($data) {
            print "Ok stored you can close this program\n";
            my $res = Plack::Response->new(200);
            $res->content_type("text/plain");
            $res->body("You are logged in :)");
            return $res->finalize;
        }
        else {
            my $res = Plack::Response->new(404);
            $res->content_type("text/plain");
            $res->body("Failed to get an access_token");
            return $res->finalize;
        }
      }
    );
}

1;
