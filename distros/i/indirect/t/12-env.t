#!perl

use strict;
use warnings;

use Test::More tests => 3;

{
 local $ENV{PERL_INDIRECT_PM_DISABLE} = 1;
 my $err = 0;
 my $res = eval <<' TEST_ENV_VARIABLE';
  return 1;
  no indirect hook => sub { ++$err };
  my $x = new Flurbz;
 TEST_ENV_VARIABLE
 is $@,   '', 'PERL_INDIRECT_PM_DISABLE test doesn\'t croak';
 is $res, 1,  'PERL_INDIRECT_PM_DISABLE test returns the correct value';
 is $err, 0,  'PERL_INDIRECT_PM_DISABLE test didn\'t generate any error';
}
