use strict;
use warnings;

use Test::More;

use Test::File::Cmp qw(file_is);

use Test::Builder::Tester;

use File::Spec::Functions;

{
  my $got = catfile(qw(t data tst_1cr.raw));
  my $exp = catfile(qw(t data tst_nocr.raw));
  test_out("ok 1 - compare file '$got' with '$exp'");
  file_is($got, $exp);
  test_test("file_is: files considered to be equal");

  test_out("ok 1 - same file is not a problem");
  file_is($got, $got, "same file is not a problem");
  test_test("file_is: same file is not a problem");

}

{
  my $got = catfile(qw(t data id_1.raw));
  my $exp = catfile(qw(t data id_2.raw));
  test_out("ok 1 - files are identical");
  file_is($got, $exp, "files are identical");
  test_test("file_is: files are identical");

  $got = catfile(qw(t data not_id.raw));
  test_out("not ok 1 - my test");
  test_fail(+2);
  test_diag("    Files differ at line 1");
  file_is($got, $exp, "my test");
  test_test("Files differ");

  $got = catfile(qw(t data 2lines.raw));
  test_out("not ok 1 - another test");
  test_fail(+2);
  test_diag("    Different number of lines");
  file_is($got, $exp, "another test");
  test_test("Files differ in number of lines");
}

#-----------------------------------------------------------------------------
done_testing();

