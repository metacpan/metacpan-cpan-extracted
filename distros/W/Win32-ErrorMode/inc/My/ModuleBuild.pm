package My::ModuleBuild;

use strict;
use warnings;
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;
  if($^O !~ /^(cygwin|MSWin32|msys)$/)
  {
    print STDERR "platform not supported\n";
    exit;
  }
  
  $args{include_dirs} = 'include';
  
  my $self = $class->SUPER::new(%args);
  $self;
}

1;
