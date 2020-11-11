package WWW::WTF::Test;
use Moose;
use common::sense;

use Test2::V0 '!meta';

use Plack::Test;
use Plack::App::File;
$Plack::Test::Impl = 'Server';

use URI;

use WWW::WTF::UserAgent::LWP;
use WWW::WTF::UserAgent::WebKit2;

use namespace::autoclean;

#Testserver to host the static files
has 'server' => (
    is      => 'ro',
    isa     => 'Plack::Test::Server',
    default => sub {
        my $app = Plack::App::File->new(root => "t/testsite/")->to_app;
        return Plack::Test->create($app);
    },
);

has 'base_uri' => (
    is      => 'ro',
    isa     => 'URI',
    lazy    => 1,
    default => sub {
        URI->new('http://127.0.0.1:' . shift->server->port);
    },
);


#User Agent
has 'ua_lwp' => (
    is      => 'ro',
    isa     => 'WWW::WTF::UserAgent::LWP',
    lazy    => 1,
    default => sub { WWW::WTF::UserAgent::LWP->new(); },
);

has 'ua_webkit2' => (
    is      => 'ro',
    isa     => 'WWW::WTF::UserAgent::WebKit2',
    lazy    => 1,
    default => sub { WWW::WTF::UserAgent::WebKit2->new(); },
);


#Helpers
sub uri_for {
    my ($self, $target) = @_;

    return URI->new($self->base_uri . $target);
}

sub run_test {
    my ($self, $test) = @_;

    $test->($self);
}

__PACKAGE__->meta->make_immutable;
1;





