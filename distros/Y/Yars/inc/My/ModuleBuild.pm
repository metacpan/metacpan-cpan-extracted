package My::ModuleBuild;

use strict;
use warnings;
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;
  $args{requires}->{$^O eq 'MSWin32' ? 'Filesys::DfPortable' : 'Filesys::Df'} = 0;
  $class->SUPER::new(%args);
}

1;
