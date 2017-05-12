package UR::Service::UrlRouter;

use strict;
use warnings;
use UR;

use Sub::Install;

use overload '&{}' => \&__call__,  # To support being called as a code ref
             'bool' => sub { 1 };  # Required due to an unless() test in UR::Context

class UR::Service::UrlRouter {
    has_optional => [
        verbose => { is => 'Boolean' },
    ]
};

foreach my $method ( qw( GET POST PUT DELETE ) ) {
    my $code = sub {
        my($self, $path, $sub) = @_;

        my $list = $self->{$method} ||= [];
        push @$list, [ $path, $sub ];
    };
    Sub::Install::install_sub({
        as => $method,
        code => $code,
    });
}

sub _log {
    my $self = shift;
    return unless $self->verbose;
    print STDERR join("\t", @_),"\n";
}

sub __call__ {
    my $self = shift;

    return sub {
        my $env = shift;

        my $req_method = $env->{REQUEST_METHOD};
        my $matchlist = $self->{$req_method} || [];

        foreach my $route ( @$matchlist ) {
            my($path,$cb) = @$route;
            my $call = sub {    my $rv = $cb->($env, @_);
                                $self->_log(200, $req_method, $env->{PATH_INFO}, $path);
                                return ref($rv) ? $rv : [ 200, [], [$rv] ];
                            };

            if (my $ref = ref($path)) {
                if ($ref eq 'Regexp' and (my @matches = $env->{PATH_INFO} =~ $path)) {
                    return $call->(@matches);
                } elsif ($ref eq 'CODE' and $path->($env)) {
                    return $call->();
                }
            } elsif ($env->{PATH_INFO} eq $path) {
                return $call->();
            }
        }
        $self->_log(404, $req_method, $env->{PATH_INFO});
        return [ 404, [ 'Content-Type' => 'text/plain' ], [ 'Not Found' ] ];
    }
}

1;

=pod

=head1 NAME

UR::Service::UrlRouter - PSGI-aware router for incoming requests

=head1 SYNOPSIS

  my $r = UR::Service::UrlRouter->create();
  $r->GET('/index.html', \&handle_index);
  $r->POST(qr(update/(.*?).html, \&handle_update);

  my $s = UR::Service::WebServer->create();
  $s->run( $r );

=head1 DESCRIPTION

This class acts as a middleman, routing requests from a PSGI server to the
appropriate function to handle the requests.

=head2 Properties

=over 4

=item verbose

If verbose is true, the object will print details about the handled requests
to STDOUT.

=back

=head2 Methods

=over 4

=item $r->GET($URLish, $handler)

=item $r->POST($URLish, $handler)

=item $r->PUT($URLish, $handler)

=item $r->DELETE($URLisn, $handler)

These four methods register a handler for the given request method + URL pair.
The first argument specifies the URL to match against,  It can be specified
in one of the following ways

=over 4

=item $string

A simple string matches the incoming request if the request's path is eq to
the $string

=item qr(some regex (with) captures)

A regex matches the incoming request if the path matches the regex.  If the
regex contains captures, these are passed as additional arguments to the
$handler.

=item $coderef

A coderef matches the incoming request if $coderef returns true.  $coderef
is given one acgument: the PSGI env hashref.

$handler is a CODE ref.  When called, the first argument is the standard PSGI
env hashref.

=back

=item $r->__call__

__call__ is not intended to be called directly.

This class overloads the function dereference (call) operator so that the
object may be used as a callable object (ie. $obj->(arg, arg)).  As overload
expects, __call__ returns a code ref that handles the PSGI request by finding
an appropriate match with the incoming request and a previously registered
handler.  If no matching handler is found, it returns a 404 error code.

If multiple handlers match the incoming request, then only the earliest
registered handler will be called.

=back

=head1 SEE ALSO

L<UR::Service::WebServer>, L<HTTP::Server::PSGI>, L<Plack>

=cut
