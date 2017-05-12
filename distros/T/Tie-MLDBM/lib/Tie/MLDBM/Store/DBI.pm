package Tie::MLDBM::Store::DBI;

use Tie::DBI;

use strict;
use vars qw/ @ISA $VERSION /;

@ISA = qw/ Tie::DBI /;
$VERSION = '1.04';


1;


__END__

=pod

=head1 NAME

Tie::MLDBM::Store::DBI - Tie::MLDBM Storage Component Module

=head1 SYNOPSIS

 use Tie::MLDBM;

 tie %hash, 'Tie::MLDBM', {
     'Store'     =>  'DBI'
 } ... or die $!;

=head1 DESCRIPTION

This module forms a storage component of the Tie::MLDBM framework, using the 
Tie::DBI module to fulfill storage requirements.

Due to the structure of the Tie::MLDBM framework, there are few limits on the 
underlying storage component with all storage components simply existing as 
an inherited class of the storage module that they represent.  For example, 
this module, Tie::MLDBM::Store::DBI inherits from Tie::DBI in a simple 
IS-A relationship.

Caveats of usage of this module for storage are the same as that for the 
Tie::DBI module itself and are documented on L<Tie::DBI>.

=head1 AUTHOR

Rob Casey <robau@cpan.org>

=head1 COPYRIGHT

Copyright 2002 Rob Casey, robau@cpan.org

=head1 SEE ALSO

L<Tie::MLDBM>, L<Tie::DBI>

=cut
