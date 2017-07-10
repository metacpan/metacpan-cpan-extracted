use strict;
use warnings;
use Test::More;
use File::Basename ();
use File::Spec ();
use lib::relative ();

# Relative path absolutized
{
  local @INC = @INC;
  lib::relative->import('testlib');
  
  ok((grep { m!\btestlib\b! and File::Spec->file_name_is_absolute($_) } @INC),
    'absolute path to testlib in @INC');
  
  ok((eval { require MyTestModule; 1 }), 'loaded MyTestModule from testlib')
    or diag $@;
  
  is MyTestModule::foo(), 'bar', 'correct function results';
}

# Absolute path passed through
{
  local @INC = @INC;
  my $path = File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'testlib');
  lib::relative->import($path);
  
  ok((grep { $_ eq $path } @INC), 'absolute path to testlib in @INC');
  
  ok((eval { require MyTestModule2; 1 }), 'loaded MyTestModule2 from testlib')
    or diag $@;
  
  is MyTestModule2::foo(), 'baz', 'correct function results';
}

done_testing;
