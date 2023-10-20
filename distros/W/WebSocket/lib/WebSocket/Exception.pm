##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Exception.pm
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/04/30
## Modified 2023/04/30
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Exception;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Exception );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

WebSocket::Exception - WebSocket Exception Class

=head1 SYNOPSIS

    use WebSocket::Exception;
    my $ex = WebSocket::Connection->new({
        code => 1011,
        message => 'Invalid property provided',
    });
    print( "Error stack trace: ", $ex->stack_trace, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is the exception class for L<WebSocket>. It inherits all is methods from L<Module::Generic::Exception>.

The error object can be stringified or compared.

When stringified, it provides the error message along with precise information about where the error occurred and a stack trace.

L<WebSocket::Exception> objects are created by L<Module::Generic/"error"> method.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2023 DEGUEST Pte., Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut

