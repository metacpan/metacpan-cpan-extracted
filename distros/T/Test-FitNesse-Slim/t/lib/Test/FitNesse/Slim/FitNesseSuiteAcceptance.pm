package Test::FitNesse::Slim::FitNesseSuiteAcceptance;

use strict;
use warnings;

use Exporter qw(import);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use Cwd qw(abs_path);
use IO::Uncompress::Unzip qw($UnzipError);
use Test::FitNesse::Slim::FitNesseAcceptance qw(perl_pipe_command_matches);

our @EXPORT_OK = qw(
  compare_suite_results
  configure_pipe_wiki
  extract_wiki_from_jar
  parse_suite_result
  pipe_query
  verify_perl_trace
  verify_suite_execution_logs
);

sub extract_wiki_from_jar {
  my($jar,$destination) = @_;
  my $zip = IO::Uncompress::Unzip->new($jar)
    or die "open FitNesse JAR $jar: $UnzipError";
  make_path($destination);
  my $status = 1;
  my $found = 0;
  for (; $status > 0; $status = $zip->nextStream()) {
    my $name = $zip->getHeaderInfo()->{Name} // '';
    my($relative) = $name =~ m{\AResources/FitNesseRoot/(.+)\z};
    next unless defined($relative) && length($relative);
    next if $relative eq 'MySuite' || $relative =~ m{\AMySuite/};
    die "unsafe path in FitNesse JAR: $name"
      if $relative =~ m{(?:\A/|(?:\A|/)\.\.(?:/|\z)|\\)};
    $found++;
    my $directory = $relative =~ s{/$}{};
    my $target = File::Spec->catfile($destination,split m{/},$relative);
    if ($directory) {
      make_path($target);
      next;
    }
    make_path(dirname($target));
    open my $output, '>:raw', $target or die "create $target: $!";
    my $read_status;
    while (($read_status = $zip->read(my $buffer)) > 0) {
      print {$output} $buffer or die "write $target: $!";
    }
    close $output or die "close $target: $!";
    die "read $name from FitNesse JAR: $UnzipError" if $read_status < 0;
  }
  die "read FitNesse JAR $jar: $UnzipError" if $status < 0;
  die "FitNesse JAR has no Resources/FitNesseRoot tree: $jar" unless $found;
  return;
}

sub configure_pipe_wiki {
  my($wiki_root,$runner) = @_;
  $runner = abs_path($runner) or die "resolve Perl runner path: $!";
  open my $fh, '>>', "$wiki_root/content.txt" or die "open FitNesse root content: $!";
  print {$fh} "\n!define TEST_RUNNER {$runner}\n",
    "!define COMMAND_PATTERN {%m}\n!define SLIM_PORT {1}\n";
  close $fh or die "close FitNesse root content: $!";
  return $runner;
}

sub pipe_query {
  my($runner) = @_;
  $runner = abs_path($runner) or die "resolve Perl runner path: $!";
  $runner =~ s/([^A-Za-z0-9_.~-])/sprintf('%%%02X',ord($1))/ge;
  return "&COMMAND_PATTERN=%25m&TEST_RUNNER=$runner&SLIM_PORT=1";
}

sub parse_suite_result {
  my($body,$http_status,$suite_page) = @_;
  return { status => 'execution_error', errors => ["HTTP $http_status"] }
    unless defined($http_status) && $http_status == 200;
  return { status => 'execution_error', errors => ['empty FitNesse response'] }
    unless defined($body) && length($body);
  return { status => 'execution_error', errors => ['malformed FitNesse XML response'] }
    unless $body =~ m{\A\s*<\?xml\b.*?</testResults>\s*\z}s;

  my($version) = $body =~ m{<FitNesseVersion>(.*?)</FitNesseVersion>}s;
  my($root) = $body =~ m{<rootPath>(.*?)</rootPath>}s;
  my(@rows) = $body =~ m{<result>(.*?)</result>}sg;
  my(@logs) = $body =~ m{<executionLog>(.*?)</executionLog>}sg;
  my($final) = $body =~ m{<finalCounts>(.*?)</finalCounts>}s;
  my @errors;
  push @errors, 'FitNesse version missing' unless defined $version;
  push @errors, 'suite root missing or incorrect'
    unless defined($root) && _xml_text($root) eq $suite_page;
  push @errors, 'suite contains no page results' unless @rows;
  push @errors, 'suite execution log missing' unless @logs;
  push @errors, 'suite final counts missing' unless defined $final;

  my(%results,@execution_order);
  for my $row (@rows) {
    my($page_link) = $row =~ m{<pageHistoryLink>(.*?)</pageHistoryLink>}s;
    my($counts_xml) = $row =~ m{<counts>(.*?)</counts>}s;
    unless (defined($page_link) && length(_xml_text($page_link)) && defined $counts_xml) {
      push @errors, 'page result is missing its path or counts';
      next;
    }
    my $page = _xml_text($page_link);
    $page =~ s/[?].*\z//;
    unless ($page =~ /^\Q$suite_page\E\./) {
      push @errors, "page result path is outside suite root: $page";
      next;
    }
    if (exists $results{$page}) {
      push @errors, "duplicate page result: $page";
      next;
    }
    my $counts = _parse_counts($counts_xml);
    unless ($counts) {
      push @errors, "invalid assertion counts for $page";
      next;
    }
    $results{$page} = { counts => $counts };
    push @execution_order,$page;
  }

  my $final_counts = defined($final) ? _parse_counts($final) : undef;
  push @errors, 'invalid suite final counts' if defined($final) && !$final_counts;
  my @execution_logs;
  for my $log (@logs) {
    my($system) = $log =~ m{<testSystem>(.*?)</testSystem>}s;
    my($command) = $log =~ m{<command>(.*?)</command>}s;
    my($exit) = $log =~ m{<exitCode>(.*?)</exitCode>}s;
    my @exceptions = map { _xml_text($_) } $log =~ m{<exception>(.*?)</exception>}sg;
    push @execution_logs, {
      testSystem => defined($system) ? _xml_text($system) : undef,
      command => defined($command) ? _xml_text($command) : undef,
      exitCode => defined($exit) ? _xml_text($exit) : undef,
      exceptions => \@exceptions,
    };
  }

  return {
    status => @errors ? 'execution_error' : 'completed',
    errors => \@errors,
    version => defined($version) ? _xml_text($version) : undef,
    rootPath => defined($root) ? _xml_text($root) : undef,
    results => \%results,
    executionOrder => \@execution_order,
    executionLogs => \@execution_logs,
    finalCounts => $final_counts,
  };
}

sub compare_suite_results {
  my($expected_pages,$observed_results,$expected_final_counts,$observed_final_counts) = @_;
  my(%expected,@missing,@unexpected,@count_changes,@final_count_changes);
  for my $entry (@$expected_pages) {
    my $page = $entry->{page};
    if (exists $expected{$page}) {
      push @missing, "duplicate page in committed baseline: $page";
    }
    $expected{$page} = $entry;
  }
  for my $page (sort keys %expected) {
    my $observed = $observed_results->{$page};
    if (!$observed) {
      push @missing, $page unless grep { $_ eq "duplicate page in committed baseline: $page" } @missing;
      next;
    }
    for my $name (qw(right wrong ignored exceptions)) {
      my $want = $expected{$page}{counts}{$name};
      my $got = $observed->{counts}{$name};
      if (!defined($want) || !defined($got) || $want != $got) {
        push @count_changes, {
          page => $page, count => $name,
          expected => $want, actual => $got,
        };
      }
    }
  }
  @unexpected = sort grep { !exists $expected{$_} } keys %$observed_results;
  if ($expected_final_counts) {
    for my $name (qw(right wrong ignores exceptions)) {
      my $want = $expected_final_counts->{$name};
      my $got = $observed_final_counts ? $observed_final_counts->{$name eq 'ignores' ? 'ignored' : $name} : undef;
      if (!defined($want) || !defined($got) || $want != $got) {
        push @final_count_changes, { count => $name, expected => $want, actual => $got };
      }
    }
  }
  return {
    missingPages => \@missing,
    unexpectedPages => \@unexpected,
    countChanges => \@count_changes,
    finalCountChanges => \@final_count_changes,
    failed => @missing || @unexpected || @count_changes || @final_count_changes ? 1 : 0,
  };
}

sub verify_suite_execution_logs {
  my($logs,$host,$port,$accepted_labels,$transport,$runner) = @_;
  my(@errors,@verified);
  my %accepted = map { $_ => 1 } @$accepted_labels;
  push @errors, 'no SLiM execution logs were returned' unless @$logs;
  for my $index (0 .. $#$logs) {
    my $log = $logs->[$index];
    my $label = $log->{testSystem} // '';
    my $expected_command = $transport && $transport eq 'pipe'
      ? undef : "Connection to running SlimService: $host:$port";
    my $is_expected_system = $transport && $transport eq 'pipe'
      ? defined($runner) && (lc($label) eq lc("slim:$runner")
          || lc($label) eq lc("slim:remote_debug:$runner"))
      : $accepted{$label};
    push @errors, "unexpected test-system label in execution log $index: $label"
      unless $is_expected_system;
    my $command_matches = $transport && $transport eq 'pipe'
      ? perl_pipe_command_matches($log->{command},$runner)
      : defined($log->{command}) && $log->{command} eq $expected_command;
    push @errors, "SLiM execution log $index did not select the expected Perl command"
      unless $command_matches;
    push @errors, "unexpected pipe test-system label in execution log $index: $label"
      if $transport && $transport eq 'pipe' && !$is_expected_system;
    push @errors, "SLiM execution log $index exited with " . ($log->{exitCode} // 'no status')
      unless defined($log->{exitCode}) && $log->{exitCode} eq '0';
    push @errors, "SLiM execution log $index contains a test-system exception"
      if @{$log->{exceptions} || []};
    push @verified, $label if $is_expected_system
      && $command_matches
      && defined($log->{exitCode}) && $log->{exitCode} eq '0'
      && !@{$log->{exceptions} || []};
  }
  return { verified => \@verified, errors => \@errors, failed => @errors ? 1 : 0 };
}

sub verify_perl_trace {
  my($trace) = @_;
  my $commands = () = ($trace // '') =~ /^command=\[/gm;
  my $responses = () = ($trace // '') =~ /^response=\[/gm;
  my @errors;
  push @errors, 'Perl listener log contains no SLiM requests' unless $commands;
  push @errors, 'Perl listener did not log a response for every request'
    if $commands != $responses;
  return { commands => $commands, responses => $responses,
    errors => \@errors, failed => @errors ? 1 : 0 };
}

sub _parse_counts {
  my($xml) = @_;
  my %counts;
  for my $name (qw(right wrong ignores exceptions)) {
    my($value) = $xml =~ m{<$name>(\d+)</$name>};
    return unless defined $value;
    $counts{$name eq 'ignores' ? 'ignored' : $name} = 0 + $value;
  }
  return \%counts;
}

sub _xml_text {
  my($text) = @_;
  $text =~ s/&lt;/</g;
  $text =~ s/&gt;/>/g;
  $text =~ s/&quot;/"/g;
  $text =~ s/&apos;/'/g;
  $text =~ s/&amp;/&/g;
  return $text;
}

1;
