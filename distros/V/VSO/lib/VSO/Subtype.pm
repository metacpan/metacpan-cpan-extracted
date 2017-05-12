
package
VSO::Subtype;

use strict;
use warnings 'all';
our %types = ( );
sub init
{
  my $s = shift;
  $VSO::Subtype::types{$s->name} = $s;
}# end init()
sub name;
sub as;
sub where;
sub message;

sub find { $VSO::Subtype::types{$_[1]} || $_[1] }
sub subtype_exists { $VSO::Subtype::types{$_[1]} }

1;# return true:

