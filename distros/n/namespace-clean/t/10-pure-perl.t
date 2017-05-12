use strict;
use warnings;
use Test::More;

BEGIN {
  plan skip_all => "PP tests already executed"
    if $ENV{NAMESPACE_CLEAN_USE_PP};

  plan skip_all => "B::Hooks::EndOfScope ($INC{'B/Hooks/EndOfScope.pm'}) loaded before the test even started >.<"
    if $INC{'B/Hooks/EndOfScope.pm'};

  plan skip_all => "Package::Stash ($INC{'Package/Stash.pm'}) loaded before the test even started >.<"
    if $INC{'Package/Stash.pm'};

  eval { require Variable::Magic }
    or plan skip_all => "PP tests already executed";

  $ENV{B_HOOKS_ENDOFSCOPE_IMPLEMENTATION} = 'PP';
  $ENV{PACKAGE_STASH_IMPLEMENTATION} = 'PP';
  plan tests => 15;
}

use B::Hooks::EndOfScope 0.12;
use Package::Stash;

ok(
  ($INC{'B/Hooks/EndOfScope/PP.pm'} && ! $INC{'B/Hooks/EndOfScope/XS.pm'}),
  'PP BHEOS loaded properly'
) || diag join "\n",
  map { sprintf '%s => %s', $_, $INC{"B/Hooks/$_"} || 'undef' }
  qw|EndOfScope.pm EndOfScope/XS.pm EndOfScope/PP.pm|
;

ok(
  ($INC{'Package/Stash/PP.pm'} && ! $INC{'Package/Stash/XS.pm'}),
  'PP Package::Stash loaded properly'
) || diag join "\n",
  map { sprintf '%s => %s', $_, $INC{"Package/$_"} || 'undef' }
  qw|Stash.pm Stash/XS.pm Stash/PP.pm|
;

use Config;
use IPC::Open2 qw(open2);
use File::Glob 'bsd_glob';
use Cwd 'abs_path';

# for the $^X-es
$ENV{PERL5LIB} = join ($Config{path_sep}, @INC);
$ENV{PATH} = '';


# rerun the tests under the assumption of pure-perl
my $this_file = abs_path(__FILE__);

for my $fn ( bsd_glob("t/*.t") ) {

  next if abs_path($fn) eq $this_file;

  my @cmd = map { $_ =~ /(.+)/ } ($^X, $fn);

  # this is cheating, and may even hang here and there (testing on windows passed fine)
  # if it does - will have to fix it somehow (really *REALLY* don't want to pull
  # in IPC::Cmd just for a fucking test)
  # the alternative would be to have an ENV check in each test to force a subtest
  open2(my $out, my $in, @cmd);
  while (my $ln = <$out>) {
    print "   $ln";
  }

  wait;
  ok (! $?, "Exit $? from: @cmd");
}
