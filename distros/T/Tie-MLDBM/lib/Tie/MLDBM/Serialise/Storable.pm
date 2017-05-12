package Tie::MLDBM::Serialise::Storable;

use Storable;

use strict;
use vars qw/ $VERSION /;

$VERSION = '1.04';


sub deserialise {
    my ( $self, $arg ) = @_;
    return Storable::thaw( $arg );
}


sub serialise {
    my ( $self, $arg ) = @_;
    return Storable::nfreeze( $arg );
}


1;


__END__

=pod

=head1 NAME

Tie::MLDBM::Serialise::Storable - Tie::MLDBM Serialisation Component Module

=head1 SYNOPSIS

 use Tie::MLDBM;

 tie %hash, 'Tie::MLDBM', {
     'Serialise' =>  'Storable'
 } ... or die $!;

=head1 DESCRIPTION

This module forms a serialisation component of the Tie::MLDBM framework, using
the Storable module to fulfill serialisation requirements.  This module uses
the C<nfreeze()> and C<thaw()> methods of Storable to serialise and
deserialise data in network order respectively.

Caveats of usage of this module for serialisation are the same as that for the
Storable module itself and are documented on L<Storable>.

=head1 AUTHOR

Rob Casey <robau@cpan.org>

=head1 COPYRIGHT

Copyright 2002 Rob Casey, robau@cpan.org

=head1 SEE ALSO

L<Tie::MLDBM>, L<Storable>

=cut
