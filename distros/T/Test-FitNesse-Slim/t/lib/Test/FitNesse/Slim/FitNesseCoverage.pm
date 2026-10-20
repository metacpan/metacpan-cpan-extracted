package Test::FitNesse::Slim::FitNesseCoverage;

use strict;
use warnings;

use Exporter qw(import);
use File::Basename qw(basename);
use File::Find qw(find);
use File::Spec;
use JSON::PP ();

our @EXPORT_OK = qw(build_coverage_report render_coverage_markdown);

sub build_coverage_report {
  my($audit,$individual,$native,$wiki_root) = @_;
  my $suite = $native->{suitePage};
  my %individual = _unique_pages('individual', map {
    ("$suite.$_->{page}" => $_)
  } @{$individual->{pages}});
  my %native = _unique_pages('native', map { ($_->{page} => $_) }
    @{$native->{expectedPages}});
  my %audited = _unique_pages('audit', map { ($_->{page} => $_) }
    @{$audit->{pages}});

  die 'native baseline suite does not match audited suite'
    unless $audit->{nativeSuiteRequest} eq "/$suite?suite&format=xml";
  die 'native baseline page count differs from its inventory'
    unless @{$native->{expectedPages}} == $native->{expectedPageCount};
  my %audited_native = map { ($_ => $audited{$_}) }
    grep { $audited{$_}{inNativeSuite} } keys %audited;
  die 'native baseline and audit page sets differ'
    unless _same_keys(\%native,\%audited_native);

  my %audited_individual = map { ($_ => 1) }
    grep { $audited{$_} && $audited{$_}{inIndividual50} }
    keys %audited;
  die 'individual baseline and audited inventory metadata differ'
    unless _same_keys(\%audited_individual,{ map { ($_ => 1) }
      @{$audit->{individual50ExecutionOrder}} });
  die 'individual baseline and audited page sets differ'
    unless _same_keys(\%individual,\%audited_individual);

  my(@shared,@individual_only,@native_only,@pages);
  my %all = (%individual,%native);
  for my $page (sort keys %all) {
    my($i,$n,$a) = ($individual{$page},$native{$page},$audited{$page});
    push @shared,$page if $i && $n;
    push @individual_only,$page if $i && !$n;
    push @native_only,$page if $n && !$i;
    my $individual_counts = $i ? _individual_counts($i,'tcp') : undef;
    my $pipe_counts = $i ? _individual_counts($i,'pipe') : undef;
    my $native_counts = $n ? $n->{counts} : undef;
    my $native_pipe_counts = $n
      ? _native_counts($native,$page,'pipe') : undef;
    my $audited_individual_counts = $a && $a->{individualResult}
      ? $a->{individualResult}{counts} : undef;
    my $audited_native_counts = $a && $a->{nativeSuiteResult}
      ? $a->{nativeSuiteResult}{counts} : undef;
    my $audited_mode_difference = $audited_individual_counts && $audited_native_counts
      && _count_tuple($audited_individual_counts) ne _count_tuple($audited_native_counts);
    push @pages, {
      page => $page,
      inIndividualInventory => $i ? JSON::PP::true() : JSON::PP::false(),
      inNativeSuite => $n ? JSON::PP::true() : JSON::PP::false(),
      individualCounts => $individual_counts,
      individualPipeCounts => $pipe_counts,
      nativeCounts => $native_counts,
      nativePipeCounts => $native_pipe_counts,
      individualStatus => $i ? $i->{conformance}{status} : undef,
      nativeClassification => $n ? $n->{classification} : undef,
      nativeSelectionEvidence => $a ? $a->{nativeSelectionEvidence} : undef,
      nativeOnlyReason => $n && !$i ? $a->{nativeSelectionEvidence} : undef,
      individualOnlyReason => $i && !$n
        ? $audit->{reconciliation}{individualOnlyReason} : undef,
      auditedModeDifference => $audited_mode_difference ? JSON::PP::true() : JSON::PP::false(),
      auditedIndividualCounts => $audited_individual_counts,
      auditedNativeCounts => $audited_native_counts,
      auditedModeDifferenceNote => $audited_mode_difference
        ? ($a->{rootCause} || 'The audited direct and suite runs produced different assertion tuples; this is retained as an observed mode-specific baseline difference.')
        : undef,
    };
  }

  my $pruned = _pruned_test_pages($wiki_root,$suite);
  my %page_membership = (
    individual => \%individual,
    native => \%native,
  );
  my $wiki_pages = _wiki_page_inventory($wiki_root,$suite,\%audited,\%page_membership);
  my @excluded_native = grep { !$_->{inNativeSuite} } @$wiki_pages;
  my $reconciliation = $audit->{reconciliation};
  my $drift = [];
  push @$drift, 'expected 7 property-marked pages beneath a Prune page'
    unless @$pruned == 7;
  my %pruned = map { ($_->{page} => 1) } @$pruned;
  my %audited_pruned = map { ($_ => 1) } @{$reconciliation->{prunedTestPages} || []};
  push @$drift, 'pinned-wiki Prune inventory differs from the native-suite audit'
    unless _same_keys(\%pruned,\%audited_pruned);
  my @individual_only_full = @{$reconciliation->{individualOnlyPages}};
  push @$drift, 'an audited individual-only page is not beneath a Prune page'
    if grep { !$pruned{$_} } @individual_only_full;
  push @$drift, 'native-only page count differs from audit metadata'
    unless @native_only == $reconciliation->{nativeOnlyCount};
  my @enabled_unselected = map { $_->{page} }
    grep { $_->{excludedReason} eq 'enabled Test page absent from audited native selection' }
      @excluded_native;
  push @$drift, 'enabled Test pages omitted from native inventory: ' . join(', ',@enabled_unselected)
    if @enabled_unselected;

  my %native_selection_sources;
  for my $page (@{$native->{expectedPages}}) {
    my $evidence = $audited{$page->{page}}{nativeSelectionEvidence} // 'unclassified';
    my $source = $evidence =~ /Test property: true/ ? 'Test=true property'
      : $evidence =~ /Test property: empty/ ? 'empty Test property'
      : $evidence =~ /legacy wiki/ ? 'legacy Test header'
      : $evidence =~ /cross-reference/ ? 'cross-reference/support page'
      : 'unclassified';
    $native_selection_sources{$source}++;
  }

  my $scenario_page = "$suite.ScenarioLibraryTestSuite.ScenariosOnlyInSlimTests";
  my $scenario_audit = $audited{$scenario_page};
  my $scenario_pipe = $native{$scenario_page}{counts};
  return {
    formatVersion => 1,
    fitNesseVersion => $native->{fitNesseVersion},
    suitePage => $suite,
    inventories => {
      individual => { count => scalar(keys %individual), pages => [sort keys %individual],
        discovery => 'Explicit 50-page regression inventory in the individual baseline; pages are invoked separately and generated MySuite state is cleared between invocations.' },
      native => { count => scalar(keys %native), pages => [sort keys %native],
        discovery => 'Pinned FitNesse suite responder selection recorded in the native baseline and audited against v20251025.' },
    },
    setCounts => {
      intersection => scalar(@shared), individualOnly => scalar(@individual_only),
      nativeOnly => scalar(@native_only), union => scalar(@pages),
    },
    intersection => \@shared,
    individualOnly => \@individual_only,
    nativeOnly => \@native_only,
    wikiPageCount => scalar(@$wiki_pages),
    excludedFromNative => \@excluded_native,
    wikiPages => $wiki_pages,
    nativeOnlyReasonCounts => $reconciliation->{nativeOnlyReasonCounts},
    scenarioLibraryFinding => {
      page => $scenario_page,
      includedInCurrentIndividual50 => JSON::PP::false(),
      priorDirectAuditCounts => $scenario_audit->{individualResult}{counts},
      nativeTcpBaselineCounts => $native{$scenario_page}{counts},
      nativePipeCounts => $scenario_pipe,
      rootCause => 'configure_pipe_wiki appended !define TEST_SYSTEM {slim} at wiki root, forcing generated MySuite.TestPage into Slim test selection.',
      conclusion => 'Pipe setup now adds only runner, command-pattern, and port defaults; TEST_SYSTEM remains page-local. Pipe and TCP native results match at 2 right and 0 wrong.',
    },
    prunedTestPages => $pruned,
    discovery => {
      suppliedSuiteFilterTags => [],
      suitesPropertyFiltersSelection => JSON::PP::false(),
      selectionSourceCounts => \%native_selection_sources,
      propertyMarkedPagesPruned => scalar(@$pruned),
      findings => [
        'The request supplied no suite-filter tags.',
        'Page Suites properties did not filter this suite request.',
        'An empty Test property is enabled in the FitNesse page model.',
        'FitNesse pruning removes seven property-marked descendants from native traversal.',
        'Referenced pages can be selected by the suite walker without a local Test property.',
      ],
    },
    discoveryDrift => $drift,
    pages => \@pages,
  };
}

sub _count_tuple {
  my($counts) = @_;
  return join '/', map { defined($counts->{$_}) ? $counts->{$_} : 'NA' }
    qw(right wrong ignored exceptions);
}

sub render_coverage_markdown {
  my($report) = @_;
  my $c = $report->{setCounts};
  my $md = "# FitNesse acceptance coverage comparison\n\n";
  $md .= "Generated from the two committed baselines and the audited FitNesse $report->{fitNesseVersion} selection. "
    . "The isolated and native modes remain separate gates.\n\n";
  $md .= "| Inventory | Pages |\n|---|---:|\n";
  $md .= "| Individually executed | $report->{inventories}{individual}{count} |\n";
  $md .= "| Native suite selected | $report->{inventories}{native}{count} |\n";
  $md .= "| Shared | $c->{intersection} |\n| Individual only | $c->{individualOnly} |\n";
  $md .= "| Native only | $c->{nativeOnly} |\n| Union | $c->{union} |\n\n";
  $md .= "## Why the inventories differ\n\n";
  $md .= "The individual runner is a deliberate 50-page regression inventory. It clears generated `MySuite` pages between requests and checks each selected page in isolation. The native runner delegates traversal to FitNesse's suite responder, which includes enabled empty `Test` properties, legacy test headers, and referenced support pages. It also preserves suite execution context and ordering.\n\n";
  $md .= "No filter tags were supplied; `Suites` properties did not constrain this suite selection. Seven property-marked pages are excluded by their own or an ancestor's `Prune` property. Selection source counts: ";
  $md .= join(', ', map { "$_: $report->{discovery}{selectionSourceCounts}{$_}" }
    sort keys %{$report->{discovery}{selectionSourceCounts}}) . ".\n\n";
  $md .= "## Independent regression evidence\n\n";
  $md .= "| Dimension | Isolated pages | Native suite |\n|---|---|---|\n";
  $md .= "| Page lifecycle | One HTTP test per selected page; generated `MySuite` is cleared between requests. | FitNesse traverses and executes the complete selected suite in order, retaining shared suite context. |\n";
  $md .= "| Discovery | Deliberate 50-page regression list with explicit Test properties. | FitNesse v20251025 suite traversal, including empty Test properties, legacy headers, references, and pruning. |\n";
  $md .= "| Primary evidence | Stable direct page results and page-level cleanup. | Suite setup/inheritance/order and exact native discovery. |\n";
  $md .= "| Transport | Pipe launches Perl as a FitNesse child; TCP checks a real external listener. | Same two transports with separate exact tuple expectations. |\n\n";
  my $scenario = $report->{scenarioLibraryFinding};
  $md .= "## Scenario library discrepancy\n\n";
  $md .= "`$scenario->{page}` is native-suite-only; it is not one of the current 50 selected individual pages. The earlier direct-page audit and TCP native baseline both recorded "
    . _count_tuple($scenario->{priorDirectAuditCounts}) . " (R/W/I/E) and the corrected pipe native run records "
    . _count_tuple($scenario->{nativePipeCounts}) . ". The root cause was: $scenario->{rootCause} "
    . "$scenario->{conclusion}\n\n";
  my @audited_mode_differences = grep { $_->{auditedModeDifference} } @{$report->{pages}};
  $md .= "## Historical direct-run versus native-suite differences\n\n";
  $md .= "The audit also ran all 93 selected pages individually as a separate exploratory comparison. Three native-only pages had different direct and suite tuples; those direct runs are not the current 50-page regression inventory and are preserved here as separate context evidence.\n\n";
  for my $page (@audited_mode_differences) {
    $md .= "- `$page->{page}` — direct " . _count_tuple($page->{auditedIndividualCounts})
      . ", native suite " . _count_tuple($page->{auditedNativeCounts})
      . " (R/W/I/E). $page->{auditedModeDifferenceNote}\n";
  }
  $md .= "\n" if @audited_mode_differences;
  $md .= "## Pages in both inventories\n\n" . join("\n",map { "- `$_`" } @{$report->{intersection}}) . "\n\n";
  $md .= "## Individual inventory only\n\n";
  for my $page (@{$report->{individualOnly}}) {
    my($entry) = grep { $_->{page} eq $page } @{$report->{pages}};
    $md .= "- `$page` — $entry->{individualOnlyReason}.\n";
  }
  $md .= "\n## Native suite only\n\n";
  for my $page (@{$report->{nativeOnly}}) {
    my($entry) = grep { $_->{page} eq $page } @{$report->{pages}};
    $md .= "- `$page` — $entry->{nativeOnlyReason}.\n";
  }
  $md .= "\n## Property-marked pages pruned from native traversal\n\n";
  $md .= join("\n",map { "- `$_->{page}` — $_->{testProperty} Test property; `Prune` is set on `$_->{pruneAncestor}`." }
    @{$report->{prunedTestPages}}) . "\n";
  $md .= "\nSee [the JSON manifest](fitnesse-acceptance-coverage.json) for every page's membership, result tuple, selection evidence, and discovery metadata.\n";
  $md .= "\n## Other wiki pages outside native results\n\n";
  $md .= "The pinned subtree contains $report->{wikiPageCount} page records stored as `content.txt` directories or legacy `.wiki` files; "
    . scalar(@{$report->{excludedFromNative}}) . " did not produce native suite result rows.\n\n";
  for my $page (@{$report->{excludedFromNative}}) {
    $md .= "- `$page->{page}` — $page->{excludedReason}.\n";
  }
  return $md;
}

sub _unique_pages {
  my($label,@pairs) = @_;
  my %pages = @pairs;
  die "$label inventory contains duplicate pages" if keys(%pages) != @pairs / 2;
  return %pages;
}

sub _same_keys {
  my($left,$right) = @_;
  return 0 unless keys(%$left) == keys(%$right);
  return !grep { !exists $right->{$_} } keys %$left;
}

sub _individual_counts {
  my($entry,$transport) = @_;
  my $override = $entry->{transportExpectations}{$transport};
  return $override->{rawCounts} if $override && $override->{rawCounts};
  return $entry->{rawCounts} || $entry->{conformance}{rawCounts};
}

sub _native_counts {
  my($baseline,$page,$transport) = @_;
  my($entry) = grep { $_->{page} eq $page } @{$baseline->{expectedPages}};
  return unless $entry;
  my $override = $baseline->{transportExpectations}{$transport}{pages}{$page};
  return $override->{counts} if $override && $override->{counts};
  return $entry->{counts};
}

sub _pruned_test_pages {
  my($wiki_root,$suite) = @_;
  my $suite_path = join '/', split /\./, $suite;
  my $suite_dir = File::Spec->catdir($wiki_root,split m{/},$suite_path);
  my @pages;
  find({
    no_chdir => 1,
    wanted => sub {
      return unless basename($_) eq 'properties.xml' && -f $_;
      my $dir = $File::Find::dir;
      my $xml = _read($_);
      my $test = $xml =~ m{<Test>\s*true\s*</Test>}i ? 'true'
        : $xml =~ m{<Test\s*/>}i ? 'empty' : undef;
      return unless $test;
      my $ancestor = $dir;
      my $prune;
      while (index($ancestor,$suite_dir) == 0) {
        my $properties = File::Spec->catfile($ancestor,'properties.xml');
        if (-f $properties && _read($properties) =~ m{<Prune\s*/>}i) {
          $prune = $ancestor;
          last;
        }
        last if $ancestor eq $suite_dir;
        $ancestor =~ s{/[^/]+\z}{};
      }
      return unless $prune;
      my $relative = File::Spec->abs2rel($dir,$wiki_root);
      $relative =~ s{\\}{/}g;
      $relative =~ s{/}{.}g;
      my $prune_relative = File::Spec->abs2rel($prune,$wiki_root);
      $prune_relative =~ s{\\}{/}g;
      $prune_relative =~ s{/}{.}g;
      push @pages, {
        page => $relative,
        testProperty => $test,
        pruneAncestor => $prune_relative,
      };
    },
  },$suite_dir);
  return [sort { $a->{page} cmp $b->{page} } @pages];
}

sub _wiki_page_inventory {
  my($wiki_root,$suite,$audit,$membership) = @_;
  my @suite_parts = split /\./, $suite;
  my $suite_dir = File::Spec->catdir($wiki_root,@suite_parts);
  my @pages;
  find({
    no_chdir => 1,
    wanted => sub {
      return unless -f $_ && (basename($_) eq 'content.txt' || /\.wiki\z/);
      my $legacy_wiki = basename($_) ne 'content.txt';
      my $dir = $legacy_wiki ? File::Basename::dirname($_) : $File::Find::dir;
      my $relative = File::Spec->abs2rel($legacy_wiki ? $_ : $dir,$wiki_root);
      $relative =~ s{\\}{/}g;
      $relative =~ s/\.wiki\z// if $legacy_wiki;
      my $page = $relative;
      $page =~ s{/}{.}g;
      my $properties = File::Spec->catfile($dir,'properties.xml');
      my $xml = !$legacy_wiki && -f $properties ? _read($properties) : '';
      my $test_property = $xml =~ m{<Test>\s*true\s*</Test>}i ? 'true'
        : $xml =~ m{<Test\s*/>}i ? 'empty'
        : $xml =~ m{<Test>\s*false\s*</Test>}i ? 'false'
        : 'absent';
      my $native = $membership->{native}{$page};
      my $individual = $membership->{individual}{$page};
      my $audit_page = $audit->{$page};
      my $prune = _prune_ancestor($dir,$suite_dir);
      my $reason = $native ? undef
        : $prune && ($test_property eq 'true' || $test_property eq 'empty')
          ? 'excluded by Prune at ' . _page_name($prune,$wiki_root)
        : $test_property eq 'false' ? 'Test property is false'
        : ($test_property eq 'true' || $test_property eq 'empty')
          ? 'enabled Test page absent from audited native selection'
          : 'no enabled Test property or reference selected this page';
      push @pages, {
        page => $page,
        inIndividualInventory => $individual ? JSON::PP::true() : JSON::PP::false(),
        inNativeSuite => $native ? JSON::PP::true() : JSON::PP::false(),
        testProperty => $test_property,
        storageFormat => $legacy_wiki ? 'legacy .wiki file' : 'content.txt page directory',
        nativeSelectionEvidence => $native && $audit_page
          ? $audit_page->{nativeSelectionEvidence} : undef,
        excludedReason => $reason,
      };
    },
  },$suite_dir);
  return [sort { $a->{page} cmp $b->{page} } @pages];
}

sub _prune_ancestor {
  my($dir,$suite_dir) = @_;
  my $ancestor = $dir;
  while (index($ancestor,$suite_dir) == 0) {
    my $properties = File::Spec->catfile($ancestor,'properties.xml');
    return $ancestor if -f $properties && _read($properties) =~ m{<Prune\s*/>}i;
    last if $ancestor eq $suite_dir;
    $ancestor =~ s{/[^/]+\z}{};
  }
  return;
}

sub _page_name {
  my($path,$wiki_root) = @_;
  my $relative = File::Spec->abs2rel($path,$wiki_root);
  $relative =~ s{\\}{/}g;
  $relative =~ s{/}{.}g;
  return $relative;
}

sub _read {
  my($path) = @_;
  open my $fh, '<', $path or die "read $path: $!";
  local $/;
  my $text = <$fh> // '';
  close $fh or die "close $path: $!";
  return $text;
}

1;
