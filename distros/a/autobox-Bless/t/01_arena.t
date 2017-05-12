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
    
  my $purple = purple->new;

  my $still_ok = 1;
  no warnings 'redefine';
  * autobox::Bless::_package_with_method = sub { $still_ok = 0; };
        
  my %foo = ( one => 5, two => 18 );
  ok($still_ok && %foo->three eq '23', "found method crawling the arena"); 

