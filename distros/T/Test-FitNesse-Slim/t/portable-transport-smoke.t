use strict;
use warnings;

use Cwd qw(abs_path);
use Config ();
use Encode qw(encode);
use File::Spec;
use FindBin qw($Bin);
use Getopt::Long qw(GetOptionsFromArray);
use IO::Select;
use IO::Socket::INET;
use IPC::Run qw(run start timeout binary);
use Test::More;
use Time::HiRes qw(sleep time);
use lib "$Bin/lib";
use Test::FitNesse::Slim::RunnerPath qw(validate_runner_file);

IPC::Run->VERSION('20260322.0');
for my $method (qw(finished pump_nb kill_kill)) {
  die "IPC::Run $IPC::Run::VERSION does not provide required method $method\n"
    unless IPC::Run->can($method);
}

my $root = abs_path("$Bin/..");
my %option = (
  runner => "$root/bin/perl-slim",
  module_dir => "$root/lib",
  fixture_dir => "$root/examples/lib",
  timeout => 30,
);
GetOptionsFromArray(
  \@ARGV,
  'runner=s' => \$option{runner},
  'module-dir=s' => \$option{module_dir},
  'fixture-dir=s' => \$option{fixture_dir},
  'install-prefix=s' => \$option{install_prefix},
  'timeout=i' => \$option{timeout},
) or die "invalid transport smoke-test options\n";
die "unexpected transport smoke-test arguments: @ARGV\n" if @ARGV;

$option{runner} = File::Spec->rel2abs($option{runner});
validate_runner_file($option{runner});
$option{runner} = abs_path($option{runner})
  or die "cannot resolve runner path\n";
for my $key (qw(module_dir fixture_dir)) {
  $option{$key} = abs_path($option{$key})
    or die "cannot resolve $key path\n";
}
die 'the module directory is missing' unless -d $option{module_dir};
die 'the fixture directory is missing' unless -d $option{fixture_dir};
die 'timeout must be between 1 and 120 seconds'
  unless $option{timeout} >= 1 && $option{timeout} <= 120;

my @runtime_libs = grep { $_ ne $option{module_dir} && $_ ne $option{fixture_dir} }
  runtime_include_dirs($root, $option{module_dir}, $option{fixture_dir});
local $ENV{PERL5LIB} = join $Config::Config{path_sep},
  $option{module_dir}, $option{fixture_dir}, @runtime_libs;
delete $ENV{PERL5OPT};

my @production_modules = qw(
  Test/FitNesse/Slim.pm
  Test/FitNesse/Slim/ConverterRegistry.pm
  Test/FitNesse/Slim/List.pm
  Test/FitNesse/Slim/ListExecutor.pm
  Test/FitNesse/Slim/MapResult.pm
  Test/FitNesse/Slim/Server.pm
  Test/FitNesse/Slim/SlimHelperLibrary.pm
  Test/FitNesse/Slim/Statement.pm
  Test/FitNesse/Slim/StatementExecutor.pm
);
unshift @INC, $option{module_dir};
for my $module_path (@production_modules) {
  my $expected_path = abs_path(File::Spec->catfile($option{module_dir}, split m{/}, $module_path));
  die "expected production module is missing: $module_path" unless defined $expected_path;
  (my $require_path = $module_path) =~ s{/}{/}g;
  require $require_path;
  is(abs_path($INC{$require_path}), $expected_path, "loaded $module_path from selected module directory");
}

if (defined $option{install_prefix}) {
  $option{install_prefix} = abs_path($option{install_prefix})
    or die 'cannot resolve installation prefix';
  my $expected_runner = abs_path(File::Spec->catfile($option{install_prefix}, 'bin', 'perl-slim'));
  is($option{runner}, $expected_runner, 'runner is the installed executable');
  my $expected_module_root = abs_path(File::Spec->catdir($option{install_prefix}, 'lib', 'perl5'));
  is($option{module_dir}, $expected_module_root, 'module path is the installed prefix');
}

my @instructions = (
  ['1', 'import', 'Example'],
  ['2', 'make', 'counter', 'Counter', '4'],
  ['3', 'call', 'counter', 'addAmount', '3'],
  ['4', 'call', 'counter', 'value'],
);
my @expected_results = (
  ['1', 'OK'], ['2', 'OK'], ['3', '7'], ['4', '7'],
);
my $request = Test::FitNesse::Slim::List->new(\@instructions)->serialize;
my $expected_response = outer_frame(
  encode('UTF-8', Test::FitNesse::Slim::List->new(\@expected_results)->serialize),
);

subtest 'pipe session' => sub {
  my $input = outer_frame(encode('UTF-8', $request)) . outer_frame('bye');
  my ($stdout, $stderr) = ('', '');
  my $ran;
  my $error;
  $error = eval {
    $ran = run(
      [ runner_command(1) ],
      '<', binary, \$input,
      '>', binary, \$stdout,
      '2>', binary, \$stderr,
      timeout($option{timeout}),
    );
    undef;
  };
  $error = $@ if $@;
  ok(!$error, 'pipe child completed within the timeout') or diag($error, $stderr);
  ok($ran, 'pipe child exited successfully') or diag("status=$? stderr=$stderr");
  is(substr($stdout, 0, 13), "Slim -- V0.5\n", 'pipe greeting is exact');
  is(substr($stdout, 13), $expected_response,
    'pipe response has exact SLiM framing and fixture results, with no bytes after bye');
  is($stderr, '', 'pipe session emitted no unexpected diagnostics');
};

subtest 'single TCP session' => sub {
  my ($result, $error, $stdout, $stderr) = tcp_exchange();
  ok($result, 'TCP listener accepted and completed one client session')
    or diag($error, "server stdout: $stdout", "server stderr: $stderr");
  return unless $result;
  is($result->{address}, '127.0.0.1', 'TCP listener used IPv4 loopback');
  is($result->{greeting}, "Slim -- V0.5\n", 'TCP greeting is exact');
  is($result->{response}, $expected_response,
    'TCP response has exact SLiM framing and fixture results');
  ok($result->{eof}, 'TCP session closed after bye');
  ok($result->{server_stopped}, 'TCP listener process was stopped and reaped');
  is($stderr, '', 'TCP listener emitted no unexpected diagnostics');
};

subtest 'subprocess timeout' => sub {
  my ($input, $stdout, $stderr) = ('', '', '');
  my $completed = eval {
    run(
      [$^X, '-e', '$| = 1; sleep 30'],
      '<', binary, \$input,
      '>', binary, \$stdout,
      '2>', binary, \$stderr,
      timeout(1),
    );
    1;
  };
  ok(!$completed, 'IPC::Run reports a stalled child through its timeout');
  like($@, qr/timeout/i, 'timeout error identifies the elapsed deadline');
};

done_testing;

sub runner_command {
  my ($port) = @_;
  my @command = (
    $^X,
    "-I$option{module_dir}",
    "-I$option{fixture_dir}",
    $option{runner},
    $port,
  );
  splice @command, -1, 0, '--bind-address', '127.0.0.1'
    unless $port eq '1';
  return @command;
}

sub runtime_include_dirs {
  my ($repository, $selected_modules, $selected_fixtures) = @_;
  my %seen;
  my @paths;
  for my $entry (@INC) {
    next if ref($entry) || !-d $entry;
    my $path = abs_path($entry) or next;
    next if $path eq $repository;
    next if path_is_beneath($path, File::Spec->catdir($repository, 'lib'));
    next if path_is_beneath($path, File::Spec->catdir($repository, 't', 'lib'));
    next if $path eq $selected_modules || $path eq $selected_fixtures;
    next if $seen{$path}++;
    push @paths, $path;
  }
  return @paths;
}

sub path_is_beneath {
  my ($path, $parent) = @_;
  $parent = abs_path($parent) or return;
  my $relative = File::Spec->abs2rel($path, $parent);
  my @parts = File::Spec->splitdir($relative);
  return !File::Spec->file_name_is_absolute($relative)
    && @parts && $parts[0] ne File::Spec->updir;
}

sub tcp_exchange {
  my ($harness, $socket, $stdout, $stderr);
  ($stdout, $stderr) = ('', '');
  my $result;
  my $ok = eval {
    my $port = free_port();
    my $stdin = '';
    $harness = start(
      [ runner_command($port) ],
      '<', binary, \$stdin,
      '>', binary, \$stdout,
      '2>', binary, \$stderr,
      timeout($option{timeout}),
    );

    my $deadline = time + 10;
    while (time < $deadline) {
      $harness->pump_nb;
      die "TCP listener exited during startup (stderr: $stderr)"
        if $harness->finished;
      $socket = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Timeout => 0.2,
      );
      last if $socket;
      sleep 0.05;
    }
    die "TCP connection deadline expired on port $port (stderr: $stderr)"
      unless $socket;

    binmode $socket;
    my $greeting = read_socket_exact($socket, 13, 10);
    socket_write_all($socket, outer_frame(encode('UTF-8', $request)));
    my $response = read_socket_frame($socket, 15);
    socket_write_all($socket, outer_frame('bye'));
    my $eof = read_socket_eof($socket, 10);
    close $socket or die "close TCP client: $!";
    undef $socket;

    $harness->kill_kill(grace => 1);
    $result = {
      address => '127.0.0.1',
      greeting => $greeting,
      response => $response,
      eof => $eof,
      server_stopped => $harness->finished ? 1 : 0,
    };
    1;
  };
  my $error = $@ unless $ok;
  my @cleanup_errors;
  if ($socket) {
    eval { close $socket or die "close TCP client: $!"; 1 }
      or push @cleanup_errors, "close client socket: $@";
  }
  if ($harness) {
    my $finished = eval { $harness->finished };
    if ($@) {
      push @cleanup_errors, "check listener state: $@";
      $finished = 0;
    }
    if (!$finished) {
      my $stopped = eval { $harness->kill_kill(grace => 1); 1 };
      push @cleanup_errors, "stop listener: $@" unless $stopped;
      if ($stopped) {
        $finished = eval { $harness->finished };
        push @cleanup_errors, "verify listener exit: $@" if $@;
        push @cleanup_errors, 'listener did not stop after kill_kill'
          if !$@ && !$finished;
      }
    }
  }
  if (@cleanup_errors) {
    $error = '' unless defined $error;
    $error .= "\n" if length $error;
    $error .= join "\n", @cleanup_errors;
    $result = undef;
  }
  return ($ok ? $result : undef, $error, $stdout, $stderr);
}

sub free_port {
  my $reservation = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp', Listen => 1,
    ReuseAddr => 1,
  ) or die "reserve ephemeral loopback port: $!";
  my $port = $reservation->sockport;
  close $reservation or die "release reserved loopback port: $!";
  return $port;
}

sub outer_frame {
  my ($bytes) = @_;
  return sprintf('%06d:', length($bytes)) . $bytes;
}

sub read_socket_exact {
  my ($socket, $length, $timeout_seconds) = @_;
  my $select = IO::Select->new($socket);
  my $deadline = time + $timeout_seconds;
  my $value = '';
  while (length($value) < $length) {
    my $remaining = $deadline - time;
    die 'TCP read deadline expired' if $remaining <= 0;
    die 'TCP read deadline expired' unless $select->can_read($remaining);
    my $read = sysread($socket, my $chunk, $length - length($value));
    die "TCP read failed: $!" unless defined $read;
    die 'unexpected TCP EOF inside protocol data' if $read == 0;
    $value .= $chunk;
  }
  return $value;
}

sub read_socket_frame {
  my ($socket, $timeout_seconds) = @_;
  my $deadline = time + $timeout_seconds;
  my $prefix = '';
  while (length($prefix) < 32) {
    my $remaining = $deadline - time;
    die 'TCP response frame deadline expired' if $remaining <= 0;
    my $byte = read_socket_exact($socket, 1, $remaining);
    last if $byte eq ':';
    $prefix .= $byte;
  }
  die "invalid TCP response frame length '$prefix'"
    unless $prefix =~ /\A[0-9]{6,32}\z/;
  return $prefix . ':' . read_socket_exact($socket, 0 + $prefix, $deadline - time);
}

sub socket_write_all {
  my ($socket, $bytes) = @_;
  while (length $bytes) {
    my $written = syswrite($socket, $bytes);
    die "TCP write failed: $!" unless defined($written) && $written > 0;
    substr($bytes, 0, $written, '');
  }
  return;
}

sub read_socket_eof {
  my ($socket, $timeout_seconds) = @_;
  my $select = IO::Select->new($socket);
  die 'TCP connection did not close after bye'
    unless $select->can_read($timeout_seconds);
  my $read = sysread($socket, my $extra, 1);
  die 'unexpected bytes followed the bye instruction' if defined($read) && $read > 0;
  die "TCP EOF check failed: $!" unless defined $read;
  return $read == 0 ? 1 : 0;
}
