use strict;
use warnings;

use Test::More tests => 1;

use ExtUtils::MakeMaker ();

diag 'Versions of related modules:';
diag '';
diag '    Module                   Have';
diag '    -------------------- --------';

for my $module (qw(
  builtin
  builtin::Backport
  namespace::clean
  Scalar::Util
)) {
  (my $file = $module) =~ s{::}{/}g;
  $file .= '.pm';
  (my $path) = grep -f, map "$_/$file", grep !ref, @INC;
  my $version = defined $path ? MM->parse_version($path) : 'missing';
  if (!defined $version) {
    $version = 'undef';
  }
  diag sprintf '    %-20s %8s', $module, $version;
}
diag '';

ok 1, 'Reported prereqs';
