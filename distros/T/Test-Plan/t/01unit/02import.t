# $Id $

# Test::Plan::import() tests

use strict;
use warnings FATAL => qw(all);

# don't inherit Test::More::plan()
use Test::More tests  => 11,
               import => ['!plan'];


#---------------------------------------------------------------------
# compilation
#---------------------------------------------------------------------

our $class = qw(Test::Plan);

use_ok ($class);


#---------------------------------------------------------------------
# import()
#---------------------------------------------------------------------

$class->import;


#---------------------------------------------------------------------
# make sure that all our functions are properly exported
#---------------------------------------------------------------------

foreach my $function (qw(plan need need_module need_min_perl_version
                         need_min_module_version need_perl_iolayers
                         need_threads need_perl under_construction
                         skip_reason)
                     )
{

  no strict qw(refs);
  no warnings qw(uninitialized);

  my $rc = eval { &{$function}(); 1 };

  ok ($rc,
      "was able to call function '$function' directly");
}
