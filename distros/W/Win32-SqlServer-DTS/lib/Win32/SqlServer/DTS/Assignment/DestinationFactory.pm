package Win32::SqlServer::DTS::Assignment::DestinationFactory;

=head1 NAME

Win32::SqlServer::DTS::Assignment::DestinationFactory - abstract class to generate Win32::SqlServer::DTS::Assignment::Destination subclasses depending on
the Destination string.

=head1 SYNOPSIS

sub get_destination {

    my $self = shift;

    return Win32::SqlServer::DTS::Assignment::DestinationFactory->create( $self->{destination} );

}

=head1 DESCRIPTION

C<Win32::SqlServer::DTS::Assignment::DestinationFactory> instantiates and return new C<Win32::SqlServer::DTS::Assigment::Destination> subclasses 
depending on the Destination string passed as a reference.

=head2 EXPORT

Nothing.

=cut 

use strict;
use warnings;
use Carp qw(cluck confess);
our $VERSION = '0.13'; # VERSION

=head2 METHODS

=head3 create

Expects a destination string as a parameter. Such string is usually obtained from the C<destination> attribute in a 
C<Win32::SqlServer::DTS::Assignment> object. Considering that there is no method to invoke such attribute value directly (although one 
could use the method C<get_properties> to fetch that), such use is recomended to be left only internally by a 
C<Win32::SqlServer::DTS::Assignment> object.

Returns a C<Win32::SqlServer::DTS::Assignment::Destination> subclass depending on the string passed as a parameter. If it fails to 
identify the subclass, it generates a warning and returns C<undef>.

=cut

sub create {

    my $dest_string = $_[1];

    confess "Must received a valid destination string as a parameter\n"
      unless ( defined($dest_string) );

    my $original_string = $dest_string;
    $dest_string =~ tr/'//d;

    my $value = ( split( /;/, $dest_string ) )[0];

    my $type;

  CASE: {

        if ( $value eq 'Global Variables' ) {

            $type = 'GlobalVar';
            last CASE;

        }

        if ( $value eq 'Properties' ) {

            $type = 'Package';
            last CASE;

        }

        if ( $value eq 'Tasks' ) {

            $type = 'Task';
            last CASE;

        }

        if ( $value eq 'Connections' ) {

            $type = 'Connection';
            last CASE;

        }

        if ( $value eq 'Steps' ) {

            $type = 'Step';
            last CASE;
        }
        else {

            cluck "Cannot identify the type of '$original_string'\n";

        }

    }

    if ( defined($type) ) {

 # :WORKAROUND:3/10/2007:ARFJr: using DOS directory separator, but this API will
 # only work in Microsoft OS's anyway
        my $location  = 'Win32\\SqlServer\\DTS\\Assignment\\Destination\\' . $type . '.pm';
        my $new_class = 'Win32::SqlServer::DTS::Assignment::Destination::' . $type;

        require $location;

        return $new_class->new($original_string);

    }

    # cannot identify to which Destination type the string is part of
    else {

        return undef;

    }

}

1;

__END__

=head1 SEE ALSO

=over

=item *
L<Win32::SqlServer::DTS::Assignment::Destination> at C<perldoc>, as well it's subclasses.

=item *
MSDN on Microsoft website and MS SQL Server 2000 Books Online are a reference about using DTS'
object hierarchy, but one will need to convert examples written in VBScript to Perl code.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
