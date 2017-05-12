package My::ModuleBuild;

use strict;
use warnings;
use FFI::CheckLib;
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;
  
  check_lib_or_exit(
    lib => 'uuid',
    symbol => [ map { "uuid_$_" } qw(
      generate_random
      generate_time
      unparse
      copy
      clear
      type
      variant
      is_null
      compare
    ) ],
  );
  
  my $self = $class->SUPER::new(%args);
  
  $self;
}

1;
