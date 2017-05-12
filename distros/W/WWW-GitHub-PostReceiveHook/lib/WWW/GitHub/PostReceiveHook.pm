#
# This file is part of WWW-GitHub-PostReceiveHook
#
# This software is copyright (c) 2011 by Matt Phillips.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use Web::Simple 'WWW::GitHub::PostReceiveHook';
package WWW::GitHub::PostReceiveHook;
# ABSTRACT: A simple means of receiving GitHub's web hooks
$WWW::GitHub::PostReceiveHook::VERSION = '0.004';
use Try::Tiny;
use JSON;
use Encode;

has routes => (
    is        => 'rw',
    predicate => 'has_routes',
    required  => 1,
    isa       => sub {
        # must be hash
        die 'Routes must be a HASH ref.' unless ref $_[0] eq 'HASH';

        # validate each route
        while (my ($key, $value) = each %{ $_[0] }) {
            # must match simple path
            die 'Routes must be of the form qr{^/\w+/?}' if $key !~ m{^/\w+/?$};
            # must map to a coderef
            die 'route must map to CODE ref.' unless ref $value eq 'CODE';
        }
    },
);

sub dispatch_request {

    sub (POST + /*) {
        my ( $self, $path ) = @_;

        # only pass along the request if it matches a given path
        return if ! $self->has_routes || ! $self->routes->{ "/$path" };

        # catch the payload
        sub (%payload=) {
            my ( $self, $payload ) = @_;
            my $response;

            try {
                # encode multibyte
                $payload = encode_utf8 $payload;

                # deserialize
                my $json = decode_json $payload;

                # callback
                $self->routes->{ "/$path" }->( $json );
            }
            catch {
                # malformed JSON string, neither array, object, number, string or atom, at character offset 0 ?
                # you are trying to POST non JSON data. don't do that.
                warn "Caught exception: /$path: attempted to trigger callback but failed:\n$_";

                # override the default 200 OK
                $response = [ 400, [ 'Content-type' => 'text/plain' ], ['Bad Request'] ];
            };

            # return catch response if set
            return $response if $response;

            $response = [ 200, [ 'Content-type' => 'text/plain' ], ['OK'] ];
        }
    },
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::GitHub::PostReceiveHook - A simple means of receiving GitHub's web hooks

=head1 SYNOPSIS

Create the listener:

    use WWW::GitHub::PostReceiveHook;

    WWW::GitHub::PostReceiveHook->new(
        routes => {
            '/myProject' => sub { my $payload = shift; },
            '/myOtherProject' => sub { run3 \@cmd ... }
        }
    )->run_if_script;

Save it. Toss it in /cgi-bin or mount it as a psgi app. Add http://your.host/myProject to github.com/myname/myproject/admin/hooks.

=head1 DESCRIPTION

WWW::GitHub::PostReceiveHook is a CGI / PSGI wrapper for GitHub that tries to be simple like a local git hook.

=head1 METHODS

=head2 new

Argument: routes => HashRef[CodeRef]

Sets up L<Web::Simple> to listen on each route. If a GitHub payload is POST'd to a given path, it will be deserialized and passed to that paths callback.

=head1 QUESTIONS

=head2 Why WWW::GitHub::PostReceiveHook?

Sometimes you just want to kick off an email, or run a small script when someone commits to github. In situations like these, busting out a full-sized framework like Dancer/Catalyst is almost always overkill to listen for GitHub's postreceive hooks. Use this module and you can be off to the races after a quick copy-paste.

=head2 Can't I do this just as easily using Web::Simple?

Yes! But most people searching cpan for 'github postreceive' probably haven't heard of Web::Simple.

=head1 SEE ALSO

L<http://help.github.com/post-receive-hooks/> for details on what gets POST'd by GitHub

WWW::GitHub::PostReceiveHook uses L<Web::Simple> to do the heaving lifting, so that would be a good start.

L<Dancer>, L<Catalyst>, L<CGI>

=head1 AUTHOR

Matt Phillips <mattp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Matt Phillips.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
