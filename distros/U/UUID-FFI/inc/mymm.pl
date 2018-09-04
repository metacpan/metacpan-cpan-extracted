package mymm;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use FFI::CheckLib;

sub myWriteMakefile
{
  my %args = @_;

  my $lib = check_lib(
    lib => 'uuid',
    symbol => [ 'uuid_generate_random' ]
  );

  unless($lib)
  {
    $args{PREREQ_PM}->{'Alien::libuuid'} = 0;
  }
  
  WriteMakefile(%args);
}

1;
