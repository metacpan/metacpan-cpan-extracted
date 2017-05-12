use warnings;
use strict;

{
   package Test::Virtual::Filesystem::_Features;
   use warnings;
   use strict;
   use Test::More;
   use base 'Test::Virtual::Filesystem';

   sub _feature_test_1 : Test(1) : Features('features_test') {
      my ($self) = @_;
      pass('features_test');
      return;
   }

   sub _feature_test_2 : Test(1) : Features('features_test') {
      my ($self) = @_;
      fail('features_test');
      return;
   }
}

use File::Temp qw();
use Test::Builder::Tester tests => 1;
use Test::More;

test_out('ok 1 # skip features_test');
test_out('ok 2 # skip features_test');

{
   local $ENV{TEST_VERBOSE} = 0; # cargo-culted from Test-Class/t/todo.t
   local $ENV{TEST_METHOD} = '_feature_test_.';
   my $tmpdir = File::Temp::tempdir('filesys_test_XXXX', CLEANUP => 1, TMPDIR => 1);
   Test::Virtual::Filesystem::_Features->new({mountdir => $tmpdir})->runtests;
}

test_test('unsupported feature reports as skipped test');

__END__

# Local Variables:
#   mode: perl
#   cperl-indent-level: 3
#   perl-indent-level: 3
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
