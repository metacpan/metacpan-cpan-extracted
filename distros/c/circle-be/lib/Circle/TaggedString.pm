#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2010 -- leonerd@leonerd.org.uk

package Circle::TaggedString;

use strict;
use warnings;
use base qw( String::Tagged );
String::Tagged->VERSION( '0.11' );

our $VERSION = '0.173320';

sub new_from_formatting
{
   my $class = shift;
   my ( $orig ) = @_;

   return $class->clone( $orig,
      only_tags => [qw( bold under italic reverse monospace blockquote )],
      convert_tags => {
         bold       => "b",
         under      => "u",
         italic     => "i",
         reverse    => "rv",
         monospace  => "m",
         blockquote => "bq",
         # TODO: fg/bg
      },
   );
}

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
