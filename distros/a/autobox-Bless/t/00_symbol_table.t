use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('autobox::Bless') };

  package purple;

  sub new {
      my $package = shift;
      bless { one => 1, two => 2, }, $package;
  }

  sub three {
      my $self = shift;
      $self->{one} + $self->{two};
  } 
    
  # 
    
  package main;
    
  use autobox::Bless;  
    
  # my $purple = purple->new;
        
  my %foo = ( one => 5, two => 17 );
  ok(%foo->three eq '22', "found method crawling the symbol table");

