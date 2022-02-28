package Valiant::HTML::Util::Collection;

use warnings;
use strict;
use Scalar::Util (); 

sub new {
  my ($class) = shift;
  my @items = map {
    Scalar::Util::blessed($_) ?
      $_ : 
      bless $_, 'Valiant::HTML::Util::Collection::Item';
    } @_;
  return bless +{ collection=>\@items, pointer=>0 }, $class;
}

sub next {
  my $self = shift;
  if(my $item = $self->{collection}->[$self->{pointer}]) {
    $self->{pointer}++;
    return $item;
  } else {
    return;
  }
}

sub build {
  my $self = shift;
  return bless \@_, 'Valiant::HTML::Util::Collection::Item';
}

sub current_index { return shift->{pointer} }

sub current_item { return $_[0]->{collection}->[$_[0]->{pointer}] }

sub size { scalar @{$_[0]->{collection}} }

sub reset { $_[0]->{pointer} = 0 }

sub all { @{$_[0]->{collection}} }

package Valiant::HTML::Util::Collection::Item;

sub label { return shift->[0] }
sub value { return shift->[1] }

1;
