#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2010 -- leonerd@leonerd.org.uk

package Circle::TaggedString;

use strict;
use warnings;

use base qw( String::Tagged );

sub squash
{
   my $self = shift;

   my @output;
   $self->iter_substr_nooverlap( sub {
      my ( $str, %format ) = @_;
      push @output, %format ? [ $str, %format ] : $str;
   } );

   return $output[0] if @output == 1 and !ref $output[0];
   return \@output;
}

0x55AA;
