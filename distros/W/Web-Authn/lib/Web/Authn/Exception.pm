##----------------------------------------------------------------------------
## WebAuthn - ~/lib/Web/Authn/Exception.pm
## Version v0.2.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/09/09
## Modified 2026/09/11
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Web::Authn::Exception;
BEGIN
{
    use v5.16.0;
    use strict;
    use warnings;
    warnings::register_categories( 'Web::Authn' );
    use vars qw( $VERSION );
    use overload (
        '""'     => \&as_string,
        bool     => sub{1},
        fallback => 1
    );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub new
{
    my $this  = shift( @_ );
    my $class = ref( $this ) || $this;
    my %args;
    if( @_ == 1 && ref( $_[0] ) eq 'HASH' )
    {
        %args = %{$_[0]};
    }
    elsif( @_ % 2 == 0 )
    {
        %args = @_;
    }
    else
    {
        $args{message} = shift( @_ );
    }

    my $self = bless(
    {
        code        => $args{code},
        message     => $args{message}     // '',
        package     => $args{package}     // '',
        file        => $args{file}        // '',
        line        => $args{line}        // '',
        skip_frames => $args{skip_frames} // 0,
    }, $class );

    # Auto-populate call location unless provided
    unless( $self->{file} && $self->{line} )
    {
        my $skip = $self->{skip_frames} + 1;
        my @info = caller( $skip );
        if( @info )
        {
            $self->{package} ||= $info[0];
            $self->{file}    ||= $info[1];
            $self->{line}    ||= $info[2];
        }
    }
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $msg  = $self->{message} // '';
    if( $self->{file} && $self->{line} )
    {
        $msg .= sprintf( " at %s line %d.\n", $self->{file}, $self->{line} )
            unless( $msg =~ /\n\z/ );
    }
    return( $msg );
}

sub code
{
    my $self = shift( @_ );
    $self->{code} = shift( @_ ) if( @_ );
    return( $self->{code} );
}

sub file    { return( $_[0]->{file} ); }

sub line    { return( $_[0]->{line} ); }

sub message { return( $_[0]->{message} ); }

sub package { return( $_[0]->{package} ); }

sub rethrow 
{
    my $self = shift( @_ );
    return if( !ref( $self ) );
    die( $self );
}

sub throw
{
    my $self = shift( @_ );
    my $e;
    if( @_ )
    {
        $e = $self->new( @_ );
    }
    else
    {
        $e = $self;
    }
    die( $e );
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

# From perlfunc docmentation on "die":
# "If LIST was empty or made an empty string, and $@ contains an
# object reference that has a "PROPAGATE" method, that method will
# be called with additional file and line number parameters. The
# return value replaces the value in $@; i.e., as if "$@ = eval {
# $@->PROPAGATE(__FILE__, __LINE__) };" were called."
sub PROPAGATE
{
    my( $self, $file, $line ) = @_;
    if( defined( $file ) && defined( $line ) )
    {
        my $clone = $self->clone;
        $clone->file( $file );
        $clone->line( $line );
        return( $clone );
    }
    return( $self );
}

sub STORABLE_freeze { return( shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { return( shift->THAW( @_ ) ); }

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls it with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze
sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $new;
    # Storable pattern requires to modify the object it created rather than returning a new one
    if( CORE::ref( $self ) )
    {
        foreach( CORE::keys( %$hash ) )
        {
            $self->{ $_ } = CORE::delete( $hash->{ $_ } );
        }
        $new = $self;
    }
    else
    {
        $new = CORE::bless( $hash => $class );
    }
    CORE::return( $new );
}

sub TO_JSON { return( shift->as_string ); }

# NOTE: Web::Authn::Exception::InvalidAuthentication class
package Web::Authn::Exception::InvalidAuthentication;
BEGIN { use parent -norequire, qw( Web::Authn::Exception ); };

# NOTE: Web::Authn::Exception::InvalidCertificateChain class
package Web::Authn::Exception::InvalidCertificateChain;
BEGIN { use parent -norequire, qw( Web::Authn::Exception ); };

# NOTE: Web::Authn::Exception::InvalidRegistration class
package Web::Authn::Exception::InvalidRegistration;
BEGIN { use parent -norequire, qw( Web::Authn::Exception ); };

# NOTE: Web::Authn::Exception::InvalidStructure class
package Web::Authn::Exception::InvalidStructure;
BEGIN { use parent -norequire, qw( Web::Authn::Exception ); };

# NOTE: Web::Authn::Exception::UnsupportedAlgorithm class
package Web::Authn::Exception::UnsupportedAlgorithm;
BEGIN { use parent -norequire, qw( Web::Authn::Exception ); };

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Web::Authn::Exception - Exception object for Web::Authn

=head1 SYNOPSIS

    use Web::Authn;

    # Exceptions are created automatically by the error() method in various modules
    my $authn = Web::Authn->new;
    if( !defined( $authn ) )
    {
        my $err = Web::Authn->error;  # Web::Authn::Exception object

        # Stringify (overloaded):
        warn "$err";

        printf( "Error: %s\n", $err->message );
        printf( "  at %s line %d\n", $err->file, $err->line );

        # Individual fields:
        printf "Message : %s", $err->message;  # some error message
        printf "File    : %s", $err->file;     # "Foo.pm"
        printf "Line    : %d", $err->line;     # 5
        printf "Code    : %s", $err->code // 'n/a';  # optional error code
    }

    # Exception object propagates through method chains
    # When a method fails, it returns a NullObject in chaining (object) context
    # so the chain does not die with "Can't call method on undef":
    my $result = Web::Authn->new( %bad_args )->other_method ||
        die( Web::Authn->error );

    # pass_error: forwarding an existing exception
    sub my_helper
    {
        my $self = shift( @_ );
        my $authn = Web::Authn->new ||
            return( $self->pass_error( Web::Authn->error ) );  # re-raise exception
        return( $authn );
    }

    my $obj = My::Class->new->my_helper ||
        die( My::Class->error );

    # Fatal mode: turn warnings into exceptions
    my $authn2 = Web::Authn->new;
    $authn2->fatal(1);  # any subsequent error will die() instead of warn()

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

C<Web::Authn::Exception> is a lightweight exception class used internally by L<Web::Authn>. It is created automatically by the C<error()> method and stored both on the object and in a package-level C<$ERROR> variable.

Unlike regular modules, C<Web::Authn> never calls C<die> directly (except via C<throw()>). Instead, error conditions set the exception and return C<undef> in scalar context, or an empty list in list context.

=head1 CONSTRUCTOR

=head2 new

    my $ex = Web::Authn::Exception->new( 'something went wrong' );
    my $ex = Web::Authn::Exception->new({
        message     => 'something went wrong',
        code        => 400,
        skip_frames => 1,
    });
    my $ex = Web::Authn::Exception->new(
        message => 'something went wrong',
        code    => 400,
    );

Accepts a plain string (used as C<message>) or named parameters as a flat list or a single hash reference with the following keys:

=over 4

=item * C<code>

This argument is optional. It is a string or an integer: an application error code. It defaults to C<undef>.

=item * C<file>

This argument is optional. It is a string: the source file where the error originated. It is filled in from C<caller> if you omit it.

=item * C<line>

This argument is optional. It is an integer: the line number. It is filled in from C<caller> if you omit it.

=item * C<message>

This argument is optional. It is a string: the human-readable error text. It defaults to the empty string. When C<new> is called with a single non-hash argument, that argument is used as C<message>.

=item * C<package>

This argument is optional. It is a string: the package name. It is filled in from C<caller> if you omit it.

=item * C<skip_frames>

This argument is optional. It is an integer: how many extra C<caller> frames to skip when auto-detecting location. It defaults to C<0>.

=back

=head1 METHODS

=head2 as_string

    print $ex->as_string;

Returns the stringified form of the exception, including file and line information. This method is also invoked by the C<""> overload. It takes no arguments.

=head2 code

    $ex->code(400);
    my $code = $ex->code;

Set or get the error code. It returns the current value.

=head2 file

    my $file = $ex->file;

Returns the source file associated with the exception.

=head2 line

    my $line = $ex->line;

Returns the line number associated with the exception.

=head2 message

    my $text = $ex->message;
    $ex->messsage( "I found some error:", $some_data );

Set or get the error message. It returns the current value.

It takes a string, or a list of strings which will be concatenated.

=head2 package

    my $pkg = $ex->package;

Returns the package name associated with the exception.

=head2 rethrow

    $ex->rethrow;

Calls L<perlfunc/"die"> with the exception object. It must be invoked on an instance; C<< Web::Authn::Exception->rethrow >> returns C<undef>. It takes no arguments.

This is ok :

    $ex->rethrow;

But this is not :

    Web::Authn::Exception->rethrow;

=head2 throw

    Web::Authn::Exception->throw( 'something went wrong' );
    Web::Authn::Exception->throw({ message => 'bad', code => 400 });
    $ex->throw;

Creates a new exception (same arguments as L</new>) and immediately calls L<perlfunc/"die"> with it. Called on an instance with no arguments, dies with that instance.

=head2 PROPAGATE

This method is called by perl when you call L<perlfunc/die> with no parameters and C<$@> is set to a L<Web::Authn::Exception> object.

This returns a new exception object that perl will use to replace the value in C<$@>

=head2 TO_JSON

    my $json = encode_json({ error => $ex });

Special method called by L<JSON> to transform this object into a string suitable to be added in a json data.

=head1 SERIALISATION

=for Pod::Coverage FREEZE

=for Pod::Coverage STORABLE_freeze

=for Pod::Coverage STORABLE_thaw

=for Pod::Coverage THAW

=for Pod::Coverage TO_JSON

Serialisation by L<CBOR|CBOR::XS>, L<Sereal> and L<Storable::Improved> (or the legacy L<Storable>) is supported by this package. To that effect, the following subroutines are implemented: C<FREEZE>, C<THAW>, C<STORABLE_freeze> and C<STORABLE_thaw>

=head1 SUBCLASSES

=over

=item C<Web::Authn::Exception::InvalidRegistration>

=item C<Web::Authn::Exception::InvalidAuthentication>

=item C<Web::Authn::Exception::InvalidStructure>

=item C<Web::Authn::Exception::UnsupportedAlgorithm>

=item C<Web::Authn::Exception::InvalidCertificateChain>

=back

=head1 THREAD & PROCESS SAFETY

This module is designed to be fully thread-safe and process-safe, ensuring data integrity across Perl ithreads and mod_perl’s threaded Multi-Processing Modules (MPMs) such as Worker or Event.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Web::Authn>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
