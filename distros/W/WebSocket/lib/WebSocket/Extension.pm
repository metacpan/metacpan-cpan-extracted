##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Extension.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/30
## Modified 2021/09/30
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Extension;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( WebSocket::HeaderValue );
    use vars qw( $VERSION );
    use Nice::Try;
    our $VERSION = 'v0.1.0';
};

sub extension { return( shift->_set_get_scalar_as_object( 'value', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

WebSocket::Extension - WebSocket Client & Server

=head1 SYNOPSIS

    use WebSocket::Extension;
    my $ext = WebSocket::Extension->new( 'permessage-deflate' ) ||
        die( WebSocket::Extension->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents a WebSocket extension with its name and optional parameters. This class inherits from L<WebSocket::HeaderValue>, which is used to parse and handle HTTP header values with parameters.

Examples:

    Sec-WebSocket-Extensions: deflate-stream
    Sec-WebSocket-Extensions: mux; max-channels=4; flow-control, deflate-stream
    Sec-WebSocket-Extensions: private-extension

=head1 METHODS

See inherited methods from L<WebSocket::HeaderValue>. Additionally this class implements the following methods:

=head2 extension

Set or get the name of the extension.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<rfc6455|https://datatracker.ietf.org/doc/html/rfc6455#section-9.1>

L<rfc7692 for WebSocket compression|https://datatracker.ietf.org/doc/html/rfc7692>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
