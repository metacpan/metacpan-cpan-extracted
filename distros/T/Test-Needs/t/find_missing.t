use strict;
use warnings;
use Test::More tests => 3*5 + 9;
use Test::Needs ();
use lib 't/lib';

*_find_missing = \&Test::Needs::_find_missing;

my $have_vpm = eval { require version };

for my $v ($] - 0.001, $], $] + 0.001) {
  my $fail = $v > $];
  my @parts = sprintf('%.6f', $v) =~ /^(\d+)\.(\d{3})(\d{3})/;
  my $str_v = join '.', map $_+0, @parts;
  for my $c (
    $v,
    qq["$str_v"],
    qq["v$str_v"],
    qq[v$str_v],
    qq[version->new("$str_v")]
  ) {
    SKIP: {
      skip "version.pm not available", 1
        if !$have_vpm && $c =~ /version->/;
      my $check = eval $c or die $@;
      my $message = _find_missing({ perl => $check });
      if ($fail) {
        is $message, sprintf("Need perl %.6f (have %.6f)", $v, $]),
          "perl prereq of $c failed";
      }
      else {
        is $message, undef,
          "perl prereq of $c passed";
      }
    }
  }
}

my $missing = "Module::Does::Not::Exist::".time;

is _find_missing('ModuleWithVersion'), undef,
  'existing module accepted';

is _find_missing({ 'ModuleWithVersion' => 1 }), undef,
  'existing module with version accepted';

is _find_missing($missing), "Need $missing",
  'missing module rejected';

is _find_missing({ $missing => 1 }), "Need $missing 1",
  'missing module with version rejected';

is _find_missing({ 'ModuleWithVersion' => 2 }), "Need ModuleWithVersion 2 (have 1)",
  'existing module with old version rejected';

is _find_missing([ $missing ]), "Need $missing",
  'missing module rejected (arrayref)';

is _find_missing([ $missing => 1 ]), "Need $missing 1",
  'missing module with version rejected (arrayref)';

eval { _find_missing('BrokenModule') };
like $@, qr/Compilation failed/,
  'broken module dies';

eval { _find_missing('BrokenModule') };
like $@, qr/Compilation failed/,
  'broken module dies again';
