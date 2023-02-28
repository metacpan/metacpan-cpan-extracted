package mymm;

use strict;
use warnings;
use 5.008001;
use ExtUtils::MakeMaker;
use FFI::CheckLib;

sub myWriteMakefile
{
  my %args = @_;

  my $lib = check_lib(
    lib => 'uuid',
    symbol => [
      'uuid_generate_random',
      'uuid_generate_time',
      'uuid_unparse',
      'uuid_parse',
      'uuid_copy',
      'uuid_clear',
      'uuid_type',
      'uuid_variant',
      'uuid_time',
      'uuid_is_null',
      'uuid_compare',
    ]
  );

  if($lib)
  {
    delete $args{PREREQ_PM}->{'Alien::libuuid'};
  }

  WriteMakefile(%args);
}

1;
