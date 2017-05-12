package Tie::MLDBM::Store::DB_File;

use DB_File;

use strict;
use vars qw/ @ISA $VERSION /;

@ISA = qw/ DB_File /;
$VERSION = '1.04';


1;


__END__

=pod

=head1 NAME

Tie::MLDBM::Store::DB_File - Tie::MLDBM Storage Component Module

=head1 SYNOPSIS

 use Tie::MLDBM;

 tie %hash, 'Tie::MLDBM', {
     'Store'     =>  'DB_File'
 } ... or die $!;

=head1 DESCRIPTION

This module forms a storage component of the Tie::MLDBM framework, using the 
DB_File module to fulfill storage requirements.

Due to the structure of the Tie::MLDBM framework, there are few limits on the 
underlying storage component with all storage components simply existing as 
an inherited class of the storage module that they represent.  For example, 
this module, Tie::MLDBM::Store::DB_File inherits from DB_File in a simple 
IS-A relationship.

Caveats of usage of this module for storage are the same as that for the 
DB_File module itself and are documented on L<DB_File>.

=head1 AUTHOR

Rob Casey <robau@cpan.org>

=head1 COPYRIGHT

Copyright 2002 Rob Casey, robau@cpan.org

=head1 SEE ALSO

L<Tie::MLDBM>, L<DB_File>

=cut
