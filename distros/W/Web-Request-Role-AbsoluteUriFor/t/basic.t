use strict;
use warnings;
use Test::More;
use HTTP::Request;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use Web::Request;
use utf8;

# Generate a temp request class based on Web::Request and W:R:Role::JSON
my $req_class = Moose::Meta::Class->create(
    'MyReq',
    superclasses => ['Web::Request'],
    roles        => ['Web::Request::Role::AbsoluteUriFor'],
    methods      => {
        default_encoding => sub {'UTF-8'},
        uri_for          => sub {
            my ( $self, $uri ) = @_;
            return join( '/', $self->script_name, $uri->{controller}, $uri->{action} );
        }
    }
);

foreach my $t (
    ['example.com',undef,'http://example.com/nice','http://example.com/controller/action'],
    ['example.com/',undef,'http://example.com/nice','http://example.com/controller/action'],
    ['example.com','foo','http://example.com/foo/nice','http://example.com/foo/controller/action'],
    ['example.com','/foo','http://example.com/foo/nice','http://example.com/foo/controller/action'],
    ['example.com','foo/','http://example.com/foo/nice','http://example.com/foo/controller/action'],
    ['example.com','/foo/','http://example.com/foo/nice','http://example.com/foo/controller/action'],
    ['example.com/','foo','http://example.com/foo/nice','http://example.com/foo/controller/action'],
    ['example.com/','/foo','http://example.com/foo/nice','http://example.com/foo/controller/action'],
    ['example.com/','foo/','http://example.com/foo/nice','http://example.com/foo/controller/action'],
    ['example.com/','/foo/','http://example.com/foo/nice','http://example.com/foo/controller/action'],

    ['example.com','foo/bar','http://example.com/foo/bar/nice','http://example.com/foo/bar/controller/action'],
    ['example.com','/foo/bar','http://example.com/foo/bar/nice','http://example.com/foo/bar/controller/action'],
    ['example.com','foo/bar/','http://example.com/foo/bar/nice','http://example.com/foo/bar/controller/action'],
    ['example.com','/foo/bar/','http://example.com/foo/bar/nice','http://example.com/foo/bar/controller/action'],

    ['example.com//','////fk///','http://example.com/fk/nice','http://example.com/fk/controller/action'],

    ['validad.net/','/auth/','http://validad.net/auth/nice','http://validad.net/auth/controller/action'],


) {
    my $host = shift(@$t);
    my $script_name = shift(@$t);

    test_psgi(
        app    => get_handler($host, $script_name),
        client => sub {
            my $cb = shift;
            is($cb->( GET "http://localhost/string" )->content,$t->[0],"string: ".$t->[0]);
            is($cb->( GET "http://localhost/string-no-slash" )->content,$t->[0],"string no slash: ".$t->[0]);
            is($cb->( GET "http://localhost/uri_for" )->content,$t->[1], "uri_for: ".$t->[1]);
        }
    );
}



sub get_handler {
    my ($host, $script_name) = @_;
    return builder {
        sub {
            my $env  = shift;

            $env->{HTTP_HOST} = $host;
            $env->{SCRIPT_NAME} = $script_name if $script_name;

            my $req  = $req_class->name->new_from_env($env);
            my $path = $env->{PATH_INFO};

            my $uri;
            if ( $path eq '/string' ) {
                $uri=$req->absolute_uri_for('/nice');
            }
            if ( $path eq '/string-no-slash' ) {
                $uri=$req->absolute_uri_for('nice');
            }
            elsif ( $path eq '/uri_for' ) {
                $uri = $req->absolute_uri_for({ controller=>'controller', action=>'action' });
            }
            return $req->new_response({
                status=>200,
                content=>$uri
            })->finalize;
        };
    };
}

done_testing;
