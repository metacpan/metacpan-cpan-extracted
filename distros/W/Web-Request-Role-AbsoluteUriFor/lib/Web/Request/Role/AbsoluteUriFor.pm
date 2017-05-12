package Web::Request::Role::AbsoluteUriFor;

# ABSTRACT: Construct an absolute URI honoring script_name

our $VERSION = '1.001';

use 5.010;
use Moose::Role;
use Plack::Response;

sub absolute_uri_for {
    my ( $self, $uri_for ) = @_;

    my $url;
    if ( ref($uri_for) eq 'HASH' ) {
        $url = $self->uri_for($uri_for);
    }
    else {
        $url = $uri_for;
    }

    my $script_name = $self->script_name || '';
    my $base_uri = $self->base_uri;

    $base_uri=~s{/+$}{};
    $script_name=~s{/+$}{};
    $script_name=~s{^/+}{};
    $base_uri=~s{/*$script_name/*$}{}g;
    $url=~s{^/}{};
    $url=~s{^/*$script_name/*}{};

    return join( '/', grep {$_ } $base_uri, $script_name, $url );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Request::Role::AbsoluteUriFor - Construct an absolute URI honoring script_name

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  # Create a request handler
  package My::App::Request;
  use Moose;
  extends 'Web::Request';
  with 'Web::Request::Role::AbsoluteUriFor';

  # Make sure your app uses your request handler, e.g. using OX:
  package My::App::OX;
  sub request_class {'My::App::Request'}

  # in some controller action:

  # redirect
  $req->absolute_uri_for({ controller=>'foo', action=>'bar' });
  # http://yoursite.com/mountpoint/foo/bar

=head1 DESCRIPTION

C<Web::Request::Role::AbsoluteUriFor> provides a method to calculate the absolute URI of a given controller/action, including the host name and handling various issues with C<SCRIPTNAME> and reverse proxies.

=head2 METHODS

=head3 absolute_uri_for

    $req->absolute_uri_for( '/some/path' );
    $req->absolute_uri_for( $ref_uri_for );

Construct an absolute URI out of C<base_uri>, C<script_name> and the
passed in string.  You can also pass a ref, which will be resolved by
calling C<uri_for> on the request object.

=head1 THANKS

Thanks to

=over

=item *

L<validad.com|https://www.validad.com/> for supporting Open Source.

=back

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
