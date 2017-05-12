package Tickit::Test::MockTerm;

use strict;
use warnings;

our $VERSION = '0.62';

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
