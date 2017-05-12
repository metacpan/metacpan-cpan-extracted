package Test::WWW::Mechanize::HSS;
use strict;
use parent 'Test::WWW::Mechanize';
use vars qw($VERSION);
$VERSION = '0.02';

=head1 NAME

Test::WWW::Mechanize::HSS - Test HTTP::Server::Simple programs using WWW::Mechanize

=head1 SYNOPSIS

    use Test::WWW::Mechanize::HSS;
    use MyApp::Server; # A descendant from HTTP::Server::Simple

    # Construct your server
    my $s = MyApp::Server->new(
        ...
    );

    my $mech = Test::WWW::Mechanize::HSS->new(
        server => $s
    );
    
    $mech->get_ok('/');

=head1 ABSTRACT

This module implements the necessary glue to run code written for
L<HTTP::Server::Simple> and L<HTTP::Server::Simple::CGI>
using L<Test::WWW::Mechanize> without needing
to fire up an actual webserver.

=head1 STATUS

This is an early release, hacked together to test
one of my applications. So far it has worked well
for me, but there sure are some corners that
I haven't tested well. Tests and patches
are welcome.

=cut

use URI;
use HTTP::Request;
use HTTP::Response;

sub server { $_[0]->{server} };
sub host { $_[1] ? $_[0]->{host} = $_[1] : $_[0] };
sub has_host { exists $_[0]->{host} };

sub new {
    my ($class,%args) = @_;

    my $s = delete $args{server};
    my $self = $class->SUPER::new(%args);
    $self->{server} = $s;
 
    $s->after_setup_listener if $s->can('after_setup_listener');
    
    # Save our known good environment
    HTTP::Server::Simple::CGI::Environment->setup_environment;

    $self
};

sub _make_request {
    my ($self,$request) = @_;

    my $response = $self->_do_hssimple_request($request);
    
    $response->header( 'Content-Base', $request->uri );
    $response->request($request);
    if ( $request->uri->as_string =~ m{^/} ) {
        $request->uri(
            URI->new( 'http://localhost:80/' . $request->uri->as_string ) );
    }
    $self->cookie_jar->extract_cookies($response) if $self->cookie_jar;

    # check if that was a redirect
    if (   $response->header('Location')
        && $self->redirect_ok( $request, $response ) )
    {
        my $old_response = $response;

        # *where* do they want us to redirect to?
        my $location = $old_response->header('Location');

        # no-one *should* be returning relative URLs, but if they
        # are then we'd better cope with it.  Let's create a new URI, using
        # our request as the base.
        my $uri = URI->new_abs( $location, $request->uri )->as_string;

        # make a new response, and save the old response in it
        $response = $self->_make_request( HTTP::Request->new( GET => $uri ) );
        my $end_of_chain = $response;
        while ( $end_of_chain->previous )    # keep going till the end
        {
            $end_of_chain = $end_of_chain->previous;
        }                                          #   of the chain...
        $end_of_chain->previous($old_response);    # ...and add us to it
    } else {
        $response->{_raw_content} = $response->content;
    }

    return $response;
}

sub _do_hssimple_request {
    my ($self,$request) = @_;
    my $uri = $request->uri;
    
    $uri->scheme('http') unless defined $uri->scheme;
    $uri->host('localhost') unless defined $uri->host;
    $self->cookie_jar->add_cookie_header($request)
        if $self->cookie_jar;

    unless ($request->header('Host')) {
      my $host = $self->has_host
               ? $self->host
               : $uri->host;

      $request->header('Host', $host);
    }

    my @creds = $self->get_basic_credentials( "Basic", $uri );
    $request->authorization_basic( @creds ) if @creds;

    # Run a HTTP::Server::Simple::CGI request
    # Currently neglects all the fancy features
    my $rs = $request->content;
    open my $rsh, '<', \$rs
        or die "Couldn't create read-only memory file? $!";
    binmode $rsh;
    local *STDIN = *$rsh;
    
    open my $STDOUT, '>', \my $stdout
        or die "Open failed? $!";
    local *STDOUT = $STDOUT;
    
    #warn "<<<$rs>>>";
    
    my $s = $self->server;
    
    $s->stdio_handle($STDOUT);

    $self->accept_hook() if $self->can("accept_hook");

    my ( $method, $request_uri, $proto ) = (
        $request->method,
        $request->uri->query
            ? $request->uri->path . '?' . $request->uri->query
            : $request->uri->path,
        "HTTP/1.1"
    );
        
    # cut-n-paste from HTTP::Server::Simple::_process_request
    unless ($s->valid_http_method($method) ) {
        $s->bad_request;
        goto REQUEST_DONE;
    }

    #$proto ||= "HTTP/0.9";

    my ( $file, $query_string )
            = ( $request_uri =~ /([^?]*)(?:\?(.*))?/s );    # split at ?

    $s->setup(
            method       => $method,
            protocol     => $proto,
            query_string => ( defined($query_string) ? $query_string : '' ),
            request_uri  => $request_uri,
            path         => $file,
            localname    => $s->host,
            localport    => $s->port,
            peername     => 'testing',
            peeraddr     => '127.0.0.1',
    );

    # HTTP/0.9 didn't have any headers (I think)
    if ( $proto =~ m{HTTP/(\d(\.\d)?)$} and $1 >= 1 ) {
        my $headers = [];
        $request->headers->scan( sub { push @$headers, @_ });

        $s->headers($headers);
    }

    $s->post_setup_hook if $s->can("post_setup_hook");
    
    my $ok = eval {
        $s->handler;
        1
    };
    my $err = $@;
REQUEST_DONE:
    
    #warn "[[[$stdout]]]";
    my $response;
    if ($ok) {
        $response = HTTP::Response->parse($stdout);
    } else {
        $response = HTTP::Response->new(500, $err, ['X-Internal','Internal error'], $err);
    };
    return $response
};

1;

__END__

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2009 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.
