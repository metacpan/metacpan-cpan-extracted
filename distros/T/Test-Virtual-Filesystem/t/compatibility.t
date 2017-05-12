use warnings;
use strict;

{
   package Test::Virtual::Filesystem::_Compatibility;
   use warnings;
   use strict;
   use Test::More;
   use base 'Test::Virtual::Filesystem';

   sub _compatibility_test_1 : Test(1) : Introduced('0.02') {
      my ($self) = @_;
      pass('compatibility_test');
      return;
   }
   sub _compatibility_test_2 : Test(1) : Introduced('0.02') {
      my ($self) = @_;
      fail('compatibility_test');
      return;
   }
}


use File::Temp qw();
use Test::Builder::Tester tests => 1;

test_out('ok 1 - compatibility_test # TODO compatibility mode 0.01');
test_out('not ok 2 - compatibility_test # TODO compatibility mode 0.01');
test_err('#   Failed (TODO) test \'compatibility_test\'');
test_err('#   at t/compatibility.t line 18.');
test_err('#   (in Test::Virtual::Filesystem::_Compatibility->_compatibility_test_2)');

{
   local $ENV{TEST_VERBOSE} = 0; # cargo-culted from Test-Class/t/todo.t
   local $ENV{TEST_METHOD} = '_compatibility_test.*'; # pick a special tests introduced after v0.01
   my $tmpdir = File::Temp::tempdir('filesys_test_XXXX', CLEANUP => 1, TMPDIR => 1);
   Test::Virtual::Filesystem::_Compatibility->new({mountdir => $tmpdir,
                                                   compatible => '0.01'})->runtests;
}

test_test('compatibility tests emit TODO results');

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
