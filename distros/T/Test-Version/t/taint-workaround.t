use strict;
use warnings;
use Test::More;
use File::Find;
use Test::Version;
use Cwd ();

my $untaint_pattern = $Test::Version::FILE_FIND_RULE_EXTRAS{untaint_pattern} || $File::Find::untaint_pattern;

note "untaint_pattern = $untaint_pattern";

my $cwd = Cwd::getcwd;

note "Cwd::getcwd = $cwd";

diag '';

if(defined $untaint_pattern)
{
  if($cwd =~ m|$untaint_pattern|)
  {
    note 'Looks good $cwd =~ $untaint_pattern';
  }
  else
  {
    diag "current working directory does not match untaint pattern:";
    diag "Cwd::getcwd = $cwd";
    diag "untaint_pattern = $untaint_pattern";
  }
}
else
{
  diag "unable to determine untaint pattern.";
}

# make sure this test passes. Intent is only to collect diagnostics atm.
ok 1;


done_testing;
