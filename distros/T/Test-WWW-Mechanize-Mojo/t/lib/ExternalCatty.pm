package ExternalCatty;
use strict;
use warnings;
use Catalyst qw/-Engine=HTTP/;
our $VERSION = '0.01';

__PACKAGE__->config( name => 'ExternalCatty' );
__PACKAGE__->setup;

sub default : Private {
    my ( $self, $c ) = @_;
    $c->response->content_type('text/html; charset=utf-8');
    $c->response->output( html( 'Root', 'Hello, test ☺!' ) );
}

# redirect to a redirect
sub hello: Global {
    my ( $self, $context ) = @_;
    my $where = $context->uri_for('/');
    $context->response->redirect($where);
    return;
}

sub html {
    my ( $title, $body ) = @_;
    return qq[
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>$title</title>
</head>
<body>$body</body>
</html>
];
}

# The Cat HTTP server background option is useless here :-(
# Thus we have to provide our own background method.
sub background {
    my $self  = shift;
    my $port  = shift;
    my $child = fork;
    die "Can't fork Cat HTTP server: $!" unless defined $child;
    return $child if $child;

    if ( $^O !~ /MSWin32/ ) {
        require POSIX;
        POSIX::setsid() or die "Can't start a new session: $!";
    }

    $self->run($port);
}

1;

