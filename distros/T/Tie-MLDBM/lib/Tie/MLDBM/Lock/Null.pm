package Tie::MLDBM::Lock::Null;

use strict;
use vars qw/ $VERSION /;

$VERSION = '1.04';


sub lock_exclusive { 1 }
sub lock_shared { 1 }
sub unlock { 1 }


1;


__END__

=pod

=head1 NAME

Tie::MLDBM::Lock::Null - Tie::MLDBM Locking Component Module

=head1 SYNOPSIS

 use Tie::MLDBM;

 tie %hash, 'Tie::MLDBM', {
     'Lock'      =>  'Null'
 } ... or die $!;

=head1 DESCRIPTION

This module forms a locking component of the Tie::MLDBM framework, without 
actually implementing any synchronisation or locking components.  This module 
should only be used where there are no concerns of synchronisation in the
environment where the Tie::MLDBM framework is employed.

This is locking component of the Tie::MLDBM framework is that used when no 
other locking module is defined.

=head1 AUTHOR

Rob Casey <robau@cpan.org>

=head1 COPYRIGHT

Copyright 2002 Rob Casey, robau@cpan.org

=head1 SEE ALSO

L<Tie::MLDBM>

=cut
