package Catty::Controller::Root;
use Moose;

BEGIN { extends 'Catalyst::Controller' };

__PACKAGE__->config( namespace => '' );

has 'counter' => (
    traits  => ['Counter'],
    is      => 'ro',
    isa     => 'Num',
    default => 0,
    handles => {
        inc_counter   => 'inc',
    },
);


sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    my $html = html( "Root", "This is the root page" );

    $c->stash->{foo} = $self->counter;
    $self->inc_counter;

    $c->response->content_type("text/html");
    $c->response->output($html);
}

sub set_session : Local : Args(2) {
    my ( $self, $c, $key, $value ) = @_;

    $c->session($key => $value);

    $c->response->content_type("text/plain");
    $c->response->output("ok");
}

# borrowed from Test::WWW::Catalyst::Mechanize
sub html {
    my ( $title, $body ) = @_;
    return qq{
<html>
<head><title>$title</title></head>
<body>
$body
<a href="/hello/">Hello</a>.
</body></html>
};
}

1;

