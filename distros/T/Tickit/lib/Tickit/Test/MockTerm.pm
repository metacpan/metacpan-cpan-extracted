#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2021 -- leonerd@leonerd.org.uk

package Tickit::Test::MockTerm 0.73;

use v5.14;
use warnings;

use base qw( Tickit::Term );

sub new
{
   my $class = shift;
   my %args = @_;

   return $class->_new_mocking( $args{lines} || 25, $args{cols} || 80 );
}

# TODO: this needs to live in .xs code now
# sub showlog
# {
#    my $self = shift;
# 
#    foreach my $l ( @{ $self->methodlog } ) {
#       if( $l->[0] eq "setpen" ) {
#          my $pen = $l->[1];
#          printf "# SETPEN(%s)\n", join( ", ", map { defined $pen->{$_} ? "$_ => $pen->{$_}" : () } sort keys %$pen );
#       }
#       else {
#          printf "# %s(%s)\n", uc $l->[0], join( ", ", @{$l}[1..$#$l] );
#       }
#    }
# }

0x55AA;
