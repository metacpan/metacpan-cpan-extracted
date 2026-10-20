use strict;
use warnings;

use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Test::More;
use lib 't/lib';
use Test::FitNesse::Slim::FitNesseCoverage qw(build_coverage_report render_coverage_markdown);

my $suite = 'FitNesse.SuiteAcceptanceTests.SuiteSlimTests';
my $tmp = tempdir(CLEANUP => 1);
my $wiki = "$tmp/FitNesseRoot";
my $pruned_parent = "$wiki/FitNesse/SuiteAcceptanceTests/SuiteSlimTests/Pruned";
my $leaf = "$pruned_parent/OnlyHere";
make_path($leaf);
open my $parent, '>', "$pruned_parent/properties.xml" or die $!;
print {$parent} '<properties><Prune/></properties>';
close $parent;
open my $props, '>', "$leaf/properties.xml" or die $!;
print {$props} '<properties><Test>true</Test></properties>';
close $props;
open my $content, '>', "$leaf/content.txt" or die $!;
print {$content} 'a test page';
close $content;

my $individual = {
  pages => [
    { page => 'Pruned.OnlyHere', rawCounts => { right => 1, wrong => 0, ignored => 0, exceptions => 0 },
      conformance => { status => 'conformant', rawCounts => { right => 1, wrong => 0, ignored => 0, exceptions => 0 } } },
    { page => 'Shared', rawCounts => { right => 2, wrong => 0, ignored => 0, exceptions => 0 },
      conformance => { status => 'conformant', rawCounts => { right => 2, wrong => 0, ignored => 0, exceptions => 0 } } },
  ],
};
my $native = {
  suitePage => $suite, fitNesseVersion => 'v20251025', expectedPageCount => 2,
  expectedPages => [
    { page => "$suite.Shared", counts => { right => 2, wrong => 0, ignored => 0, exceptions => 0 }, classification => 'conformant' },
    { page => "$suite.NativeOnly", counts => { right => 3, wrong => 1, ignored => 0, exceptions => 0 }, classification => 'known gap' },
  ],
  transportExpectations => { pipe => { pages => {} } },
};
my $audit = {
  nativeSuiteRequest => "/$suite?suite&format=xml",
  individual50ExecutionOrder => ["$suite.Pruned.OnlyHere", "$suite.Shared"],
  reconciliation => {
    individualOnlyReason => 'parent Pruned has <Prune/>',
    individualOnlyPages => ["$suite.Pruned.OnlyHere"],
    prunedTestPages => ["$suite.Pruned.OnlyHere"],
    nativeOnlyCount => 1,
    nativeOnlyReasonCounts => { 'Test property: empty' => 1 },
  },
  pages => [
    { page => "$suite.Pruned.OnlyHere", inNativeSuite => JSON::PP::false(), inIndividual50 => JSON::PP::true(), nativeSelectionEvidence => 'pruned' },
    { page => "$suite.Shared", inNativeSuite => JSON::PP::true(), inIndividual50 => JSON::PP::true(), nativeSelectionEvidence => 'Test property: true' },
    { page => "$suite.NativeOnly", inNativeSuite => JSON::PP::true(), inIndividual50 => JSON::PP::false(), nativeSelectionEvidence => 'Test property: empty/self-closing' },
  ],
};
my $report = build_coverage_report($audit,$individual,$native,$wiki);
is_deeply($report->{setCounts},
  { intersection => 1, individualOnly => 1, nativeOnly => 1, union => 3 },
  'coverage set arithmetic is explicit and reconciled');
is_deeply($report->{individualOnly}, ["$suite.Pruned.OnlyHere"],
  'relative individual paths become full suite paths');
is($report->{prunedTestPages}[0]{page},"$suite.Pruned.OnlyHere",
  'the pinned wiki Prune ancestor is discovered from properties');
is($report->{excludedFromNative}[0]{excludedReason},
  "excluded by Prune at $suite.Pruned",
  'nonselected pages retain a stable, workspace-independent exclusion reason');
like(render_coverage_markdown($report),qr/NativeOnly/,
  'human-readable report names native-only pages');

done_testing;
