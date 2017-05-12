package Win32::API::Interface;

use strict;

use vars qw/$VERSION $INSTANCE %API_GENERATED/;
$VERSION  = '0.03';
$INSTANCE = Win32::API::Interface->new;

use Win32::API ();

=head1 NAME

Win32::API::Interface - Object oriented interface generation

=head1 SYNOPSIS

    package MyModule;
	use base qw/Win32::API::Interface/;

	__PACKAGE__->generate( "kernel32", "GetCurrentProcessId", "", "N" );
	__PACKAGE__->generate( "kernel32", "GetCurrentProcessId", "", "N", 'get_pid' );

	1;

	my $obj = MyModule->new );
	print "PID: " . $obj->GetCurrentProcessId . "\n";
	print "PID: " . $obj->get_pid . "\n";

=head1 DESCRIPTION

This module provides functions for generating a object oriented interface to
Win32 API functions.

=head1 METHODS

=head2 new

    my $obj = Module->new;

Win32::API::Interface provides a basic constructor. It generates a
hash-based object and can be called as either a class method or an object
method.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    return bless {}, $class;
}

=head2 self

    my $self = $obj->self;

Returns itself. Acutally useless and mainly used internally.
Can also be called as a object method.

    Win32::API::Interface->self

=cut

sub self {
    my $self = shift;
    $self = $Win32::API::Interface::INSTANCE unless ref $self;
    return $self;
}

=head2 generate

    __PACKAGE__->generate( "kernel32", "GetCurrentProcessId", "", "N" );

This generates a method called I<GetCurrentProcessId> which is exported
by I<kernel32.dll>. It does not take any input parameters but returns a value
of type I<long>.

    __PACKAGE__->generate( "kernel32", "GetCurrentProcessId", "", "N", "get_pid" );

Actually the same as above, but this will generate a method called I<get_pid>.
This is useful if you do not want to rely on the API function name.

    __PACKAGE__->generare(
        "advapi32",
        "EncryptFile",
        "P", "I", "",
        sub {
            my ( $self, $filename ) = @_;
            return $self->Call( File::Spec->canonpath($filename) );
        }
    );

As the seventh and last parameter you may provide a function reference for modifying
the input to and output from the API function.

    __PACKAGE__->generate(
        [ "kernel32", "GetTempPath",         "NP", "N" ],
        [ "kernel32", "GetCurrentProcessId", "",   "N", "get_pid" ],
        [ "advapi32" ,"EncryptFile",         "P",  "I", "",       $coderef ],
    );

You may call I<generate> passing an hash reference of array references.

    __PACKAGE__->generate( {
        "kernel32" => [
            [ "GetTempPath",         "NP", "N" ],
            [ "GetCurrentProcessId", "",   "N", "get_pid" ],
        ],
        "user32" => [
            [ "GetCursorPos",        "P",  "I"]
        ],
        "advapi32" => [
            [ "EncryptFile",         "P",  "I", "",       $coderef ],
        ].
    } );

=cut

{
    no strict 'refs';

    sub generate {
        my $self = shift;

        if ( 'ARRAY' eq ref $_[0] ) {
            foreach my $args (@_) {
                $self->generate( @{$args} );
            }
        }
        elsif ( 'HASH' eq ref $_[0] ) {
            while ( my ( $library, $params ) = each %{ $_[0] } ) {
                foreach my $args ( @{$params} ) {
                    $self->generate( $library, @{$args} );
                }
            }
        }
        else {

            my ( $library, $name, $params, $retr, $alias, $call ) = @_;
            my $class = ref $self || $self;
            $alias ||= $name;

            *{"${class}::$alias"} =
              $self->_generate( $library, $name, $params, $retr, $call )
              unless defined &{"${class}::$alias"};
        }

        return 1;
    }
}

sub _generate {
    my ( $class, $library, $name, $params, $retr, $call ) = @_;

    my $key = uc "$library-$name";
    $API_GENERATED{$name} = 1;

    return sub {
        my $self = shift->self;

        $self->{api} ||= {};

        my $api =
          defined $self->{api}->{$key}
          ? $self->{api}->{$key}
          : $self->{api}->{$key} =
          Win32::API->new( $library, $name, $params, $retr );
        die "Unable to import API $name from $library: $^E"
          unless defined $api;


        my $retval;
        if( 'CODE' eq ref $call ) {
            $retval = $call->($api, @_);
        } else {
            $retval = $api->Call(@_);
        }
        return $retval;
    };
}

#sub generate_ex {
#    my $self = shift;
#    my %args = 'HASH' eq ref $_[0] ? %{ $_[0] } : @_;
#
#    while ( my ( $library, $params ) = each %args ) {
#        foreach my $args ( @{$params} ) {
#            $self->generate( $library, @{$args} );
#        }
#    }
#
#    return 1;
#}

=head2 generated

Returns a list of all real generated API function names

    __PACKAGE__->generated( );

=cut

sub generated {
    return keys %API_GENERATED;
}

=head1 AUTHOR

Sascha Kiefer, L<esskar@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Sascha Kiefer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

