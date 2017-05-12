#
# Class to manage a dictionnary of objects
#

package Tk::SlideShow::Dict;

use strict;

my %sprite_dict;
my @sprite_tab;
sub Exists {my ($class,$cle) = @_; return $sprite_dict{$cle};}

sub Get {
  my ($class,$cle) = @_;
  warn "$class('$cle') unknown\n" unless exists $sprite_dict{$cle};
  return $sprite_dict{$cle} || Tk::SlideShow::Sprite->null;
}

sub Each {my $class = shift; return (each %sprite_dict)[1];}
sub All {my $class = shift; return @sprite_tab;}
sub Set {
  my ($class,$cle,$val) = @_; $sprite_dict{$cle} = $val;
  push @sprite_tab, $cle;
}
# sub Del {my ($class,$cle) = @_; delete $sprite_dict{$cle};}

sub Clean {
  %sprite_dict = ();
  @sprite_tab = ();
}

sub var_getset{
  my ($s,$k,$v) = @_;
  if (defined $v) {$s->{$k} = $v; return $s;}
  else            {               return $s->{$k} ;}
};

1;
