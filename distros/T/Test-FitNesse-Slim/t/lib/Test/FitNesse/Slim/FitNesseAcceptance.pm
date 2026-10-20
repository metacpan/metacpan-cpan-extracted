package Test::FitNesse::Slim::FitNesseAcceptance;

use strict;
use warnings;

use Exporter qw(import);
use File::Basename qw(basename);
use File::Find qw(find);
use File::Spec;
use IO::Select;
use IO::Socket::INET;
use POSIX qw(WNOHANG setpgid);
use Time::HiRes qw(alarm sleep time);

our @EXPORT_OK = qw(
  bounded_request
  compare_page_counts
  compare_inventory
  free_port
  missing_wiki_pages
  parse_page_result
  perl_pipe_command_matches
  probe_slim
  preserve_exit_status
  start_owned_process
  owned_process_exited
  stop_owned_processes
  true_property_pages_in_wiki
  wait_until
);

my (@OWNED_PROCESSES, %REAPED_PROCESSES);

sub preserve_exit_status {
  my($cleanup) = @_;
  my $status = $?;
  $cleanup->();
  $? = $status;
  return;
}

sub free_port {
  my($host) = @_;
  my $socket = IO::Socket::INET->new(LocalAddr => $host, LocalPort => 0,
    Proto => 'tcp', Listen => 1, ReuseAddr => 1) or die "allocate local port: $!";
  my $port = $socket->sockport;
  close $socket;
  return $port;
}

sub wait_until {
  my($description,$seconds,$check) = @_;
  my $deadline = time + $seconds;
  while (time < $deadline) {
    return if $check->();
    sleep 0.2;
  }
  die "$description failed to become ready within ${seconds}s";
}

sub start_owned_process {
  my($program,@args) = @_;
  my %options = @args && ref($args[-1]) eq 'HASH' ? %{pop @args} : ();
  die "start $program: log_file is required" unless $options{log_file};
  my $pid = fork();
  die "fork $program: $!" unless defined $pid;
  if (!$pid) {
    setpgid(0,0) == 0 or die "set process group for $program: $!";
    chdir($options{cwd}) if $options{cwd};
    open STDIN, '<', '/dev/null' or die "open /dev/null: $!";
    open STDOUT, '>>', $options{log_file} or die "open $options{log_file}: $!";
    open STDERR, '>&', STDOUT or die "redirect stderr: $!";
    exec {$program} $program, @args;
    die "exec $program: $!";
  }
  push @OWNED_PROCESSES, $pid;
  return $pid;
}

sub owned_process_exited {
  for my $pid (@OWNED_PROCESSES) {
    next if $REAPED_PROCESSES{$pid};
    my $result = waitpid($pid,WNOHANG);
    if ($result == $pid || $result == -1) {
      $REAPED_PROCESSES{$pid} = 1;
      return 1;
    }
  }
  return 0;
}

sub stop_owned_processes {
  for my $pid (reverse @OWNED_PROCESSES) {
    next if $REAPED_PROCESSES{$pid};
    my $alive = 1;
    kill 'TERM', -$pid or kill 'TERM', $pid;
    my $deadline = time + 5;
    while (time < $deadline) {
      my $result = waitpid($pid,WNOHANG);
      if ($result == $pid || $result == -1) {
        $REAPED_PROCESSES{$pid} = 1;
        $alive = 0;
        last;
      }
      sleep 0.1;
    }
    if ($alive) {
      kill 'KILL', -$pid or kill 'KILL', $pid;
      waitpid($pid,0);
      $REAPED_PROCESSES{$pid} = 1;
    }
  }
  @OWNED_PROCESSES = ();
  %REAPED_PROCESSES = ();
  return;
}

sub bounded_request {
  my($seconds,$request) = @_;
  my($response,$error);
  my $ok = eval {
    local $SIG{ALRM} = sub { die "request timed out after ${seconds}s\n" };
    alarm($seconds);
    $response = $request->();
    alarm(0);
    1;
  };
  alarm(0);
  unless ($ok) {
    $error = $@ || 'request failed';
    $error =~ s/\s+\z//;
  }
  return ($response,$error);
}

sub parse_page_result {
  my($body,$http_status,$host,$port,$transport,$perl_runner) = @_;
  $transport ||= 'tcp';
  return { status => 'execution_error', error => "HTTP $http_status" }
    unless defined($http_status) && $http_status == 200;
  return { status => 'execution_error', error => 'empty FitNesse response' }
    unless defined($body) && length($body);

  my($result) = $body =~ m{<result>(.*?)</result>}s;
  my($counts) = defined($result) ? $result =~ m{<counts>(.*?)</counts>}s : ();
  return { status => 'execution_error', error => 'primary result counts missing' }
    unless defined $counts;

  my %counts;
  for my $name (qw(right wrong ignores exceptions)) {
    my($value) = $counts =~ m{<$name>(\d+)</$name>};
    return { status => 'execution_error', error => "invalid or missing $name count" }
      unless defined $value;
    $counts{$name eq 'ignores' ? 'ignored' : $name} = 0 + $value;
  }

  my($log) = $body =~ m{<executionLog>(.*?)</executionLog>}s;
  my($system) = defined($log) ? $log =~ m{<testSystem>(.*?)</testSystem>}s : ();
  my($command) = defined($log) ? $log =~ m{<command>(.*?)</command>}s : ();
  my($exit_code) = defined($log) ? $log =~ m{<exitCode>(-?\d+)</exitCode>}s : ();

  my $perl_confirmed = $transport eq 'pipe'
    ? defined($system) && defined($perl_runner) && lc($system) eq lc("slim:$perl_runner")
      && perl_pipe_command_matches($command,$perl_runner)
      && defined($exit_code) && $exit_code eq '0'
    : defined($system) && lc($system) eq lc('slim:fitnesse.slim.SlimService')
      && defined($command) && $command eq "Connection to running SlimService: $host:$port"
      && defined($exit_code) && $exit_code eq '0';
  return {
    status => 'completed',
    counts => \%counts,
    conformance => $counts{wrong} == 0 && $counts{exceptions} == 0 ? 'conformant' : 'nonconformant',
    testSystem => $system,
    command => $command,
    exitCode => defined($exit_code) ? 0 + $exit_code : undef,
    perlExecutionConfirmed => $perl_confirmed ? 1 : 0,
    externalPerlConfirmed => $transport eq 'tcp' && $perl_confirmed ? 1 : 0,
  };
}

sub perl_pipe_command_matches {
  my($command,$runner) = @_;
  return unless defined($command) && defined($runner);
  my @arguments = split /\s+/, $command;
  return unless shift(@arguments) eq $runner;
  return unless pop(@arguments) eq '1';

  my %seen;
  while (@arguments) {
    my $flag = shift @arguments;
    return if $seen{$flag}++;
    if ($flag eq '-v') {
      next;
    }
    elsif ($flag eq '-s') {
      return unless @arguments && shift(@arguments) =~ /\A[1-9][0-9]*\z/;
    }
    else {
      return;
    }
  }
  return 1;
}

sub compare_page_counts {
  my($baseline,$observed,$transport) = @_;
  my(@changes,@missing);
  for my $entry (@$baseline) {
    my $page = $entry->{page};
    my $specific = $transport && $entry->{transportExpectations}{$transport};
    my $counts = $specific && $specific->{rawCounts}
      || $entry->{rawCounts} || $entry->{conformance}{rawCounts};
    unless ($counts) {
      push @changes, { page => $page, error => 'baseline assertion counts missing' };
      next;
    }
    my $actual = $observed->{$page} && $observed->{$page}{counts};
    unless ($actual) {
      push @missing, $page;
      next;
    }
    for my $name (qw(right wrong ignored exceptions)) {
      push @changes, { page => $page, count => $name,
        expected => $counts->{$name}, actual => $actual->{$name} }
        if !defined($counts->{$name}) || !defined($actual->{$name})
          || $counts->{$name} != $actual->{$name};
    }
  }
  my %expected = map { $_->{page} => 1 } @$baseline;
  my @unexpected = sort grep { !$expected{$_} } keys %$observed;
  return { changes => \@changes, missing => \@missing, unexpected => \@unexpected,
    failed => @changes || @missing || @unexpected ? 1 : 0 };
}

sub compare_inventory {
  my($baseline,$observed,$transport) = @_;
  my(@missing,@unexecuted,@regressions,@newly_conformant,@known_failures,@service_failures);
  my %expected = map { $_->{page} => $_ } @$baseline;

  for my $page (sort keys %expected) {
    my $result = $observed->{$page};
    if (!$result) {
      push @missing, $page;
      push @unexecuted, $page;
      push @regressions, $page if $expected{$page}{conformance}{status} eq 'conformant';
      next;
    }

    if (($result->{status} // '') ne 'completed') {
      push @unexecuted, $page;
      push @regressions, $page if $expected{$page}{conformance}{status} eq 'conformant';
      next;
    }
    my $perl_confirmed = exists($result->{perlExecutionConfirmed})
      ? $result->{perlExecutionConfirmed} : $result->{externalPerlConfirmed};
    if (!$perl_confirmed) {
      push @service_failures, $page;
      push @regressions, $page if $expected{$page}{conformance}{status} eq 'conformant';
      next;
    }

    my $specific = $transport && $expected{$page}{transportExpectations}{$transport};
    my $expected_status = $specific && $specific->{status}
      || $expected{$page}{conformance}{status};
    my $expected_conformant = $expected_status eq 'conformant';
    my $is_conformant = $result->{conformance} eq 'conformant';
    push @regressions, $page if $expected_conformant && !$is_conformant;
    push @newly_conformant, $page if !$expected_conformant && $is_conformant;
    push @known_failures, $page if !$expected_conformant && !$is_conformant;
  }

  my @unexpected = sort grep { !$expected{$_} } keys %$observed;
  return {
    missing => \@missing,
    unexecuted => \@unexecuted,
    regressions => \@regressions,
    newlyConformant => \@newly_conformant,
    knownFailures => \@known_failures,
    serviceFailures => \@service_failures,
    unexpectedPages => \@unexpected,
    failed => @missing || @unexecuted || @regressions || @service_failures || @unexpected ? 1 : 0,
  };
}

sub missing_wiki_pages {
  my($wiki_root,$baseline) = @_;
  my @missing;
  for my $entry (@$baseline) {
    my $path = join '/', $wiki_root, split /\./, $entry->{page};
    my $properties = "$path/properties.xml";
    unless (-f $properties) {
      push @missing, $entry->{page};
      next;
    }
    open my $fh, '<', $properties or do { push @missing, $entry->{page}; next };
    local $/;
    my $xml = <$fh> // '';
    close $fh;
    push @missing, $entry->{page}
      unless $xml =~ m{<Test>\s*true\s*</Test>}i;
  }
  return \@missing;
}

sub true_property_pages_in_wiki {
  my($wiki_root) = @_;
  my @pages;
  find({
    no_chdir => 1,
    wanted => sub {
      return unless basename($_) eq 'properties.xml' && -f $_;
      open my $fh, '<', $_ or return;
      local $/;
      my $xml = <$fh> // '';
      close $fh;
      return unless $xml =~ m{<Test>\s*true\s*</Test>}i;
      my $relative = File::Spec->abs2rel($File::Find::dir, $wiki_root);
      $relative =~ s{\\}{/}g;
      push @pages, join '.', split m{/}, $relative;
    },
  }, $wiki_root);
  return [ sort @pages ];
}

sub probe_slim {
  my($host,$port,$timeout) = @_;
  $timeout = 1 unless defined $timeout;
  my $socket = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Proto => 'tcp',
    Timeout => $timeout,
  );
  return { reachable => 0, ready => 0, error => "connect: $!" } unless $socket;

  my $select = IO::Select->new($socket);
  my $line = '';
  my $deadline = time + $timeout;
  while (length($line) < 80) {
    my $remaining = $deadline - time;
    last if $remaining <= 0 || !$select->can_read($remaining);
    my $count = sysread($socket, my $chunk, 80 - length($line));
    last unless defined($count) && $count > 0;
    $line .= $chunk;
    last if $line =~ /\n/;
  }
  close $socket;
  my $ready = $line eq "Slim -- V0.5\n";
  return {
    reachable => 1,
    ready => $ready ? 1 : 0,
    greeting => $line,
    error => $ready ? undef : (length($line) ? "unexpected SLiM greeting: $line" : 'no SLiM greeting'),
  };
}

1;
