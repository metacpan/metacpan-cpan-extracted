package Text::NASA_Ames::FFI2010;
use base qw(Text::NASA_Ames::FFIx010);
use Carp;

use 5.00600;
use strict;

our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf " %d." . "%02d" x $#r, @r };


=head1 NAME

Text::NASA_Ames::FFI2010 - Implementation of FFI2010 NASA_Ames format

=head1 SYNOPSIS


=head1 DESCRIPTION

This class should normally not be called directly but through the
L<Text::NASA_Ames> class indirectly. It completely inherits from
L<Text::NASA_Ames::FFIx010>.

=cut


1;
__END__

=head1 VERSION

$Id: FFI2010.pm,v 1.1 2004/02/18 09:25:04 heikok Exp $


=head1 AUTHOR

Heiko Klein, E<lt>H.Klein@gmx.netE<gt>

=head1 SEE ALSO

L<http://cloud1.arc.nasa.gov/solve/archiv/archive.tutorial.html>,
L<Text::NASA_Ames::FFIx010>, L<NASA_Ames>

=cut
