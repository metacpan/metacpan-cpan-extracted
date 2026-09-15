##----------------------------------------------------------------------------
## WebAuthn - ~/lib/Web/Authn/NullObject.pm
## Version v0.2.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/09/10
## Modified 2026/09/11
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Web::Authn::NullObject;
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $VERSION $AUTOLOAD );
    use overload (
        '""'     => sub{ '' },
        bool     => sub{ 0 },
        fallback => 1,
    );
    use Wanted;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub new
{
    my $this = shift( @_ );
    my $ref = @_ ? { @_ } : {};
    return( bless( $ref => ( ref( $this ) || $this ) ) );
}

sub AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    my $self = shift( @_ );
    if( want( 'OBJECT' ) )
    {
        rreturn( $self );
    }
    # Otherwise, we return undef; Empty return returns undef in scalar context and empty list in list context
    return;
};

sub DESTROY { }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Web::Authn::NullObject - Chain-safe placeholder returned on error

=head1 DESCRIPTION

When L<Web::Authn/error> or L<Web::Authn/pass_error> is invoked in object context, it returns a C<Web::Authn::NullObject> instead of C<undef> so that method chains do not raise "Can't call method on an undefined value".

The object is boolean-false and stringifies to the empty string, so:

    my $opts = $authn->generate_registration_options( %bad ) ||
        die( $authn->error );

still works.

Any method called on it returns the same object.

=head1 METHODS

=head2 new

    my $null = Web::Authn::NullObject->new;

Builds the placeholder. No arguments. Application code does not call this; L<Web::Authn/error> does when the caller is in object context.

=head1 THREAD & PROCESS SAFETY

This module is designed to be fully thread-safe and process-safe, ensuring data integrity across Perl ithreads and mod_perl’s threaded Multi-Processing Modules (MPMs) such as Worker or Event.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
