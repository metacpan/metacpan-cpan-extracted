#! perl

use strict;
use utf8;
use warnings;

use Encode qw(encode decode FB_CROAK);
use POSIX qw(WNOHANG);
use IO::Select;
use IPC::Open3;
use lib 'lib', 't/lib';
use Symbol qw(gensym);
use Test::More;
use Test::FitNesse::Slim::List;

my @children;
END { stop_child($_) for @children }

sub start_child {
  my @arguments = @_ ? @_ : ('1');
  my $error = gensym;
  my $pid = open3(my $input, my $output, $error,
    $^X, '-Ilib', '-It/lib', 'bin/perl-slim', @arguments);
  binmode $_ for ($input, $output, $error);
  my $child = { pid => $pid, input => $input, output => $output, error => $error,
    error_open => 1, diagnostics => '' };
  push @children, $child;
  return $child;
}

sub stop_child {
  my($child) = @_;
  return unless $child->{pid};
  close $child->{input} if $child->{input};
  my $deadline = time + 2;
  while (time < $deadline) {
    my $result = waitpid($child->{pid}, WNOHANG);
    if ($result == $child->{pid} || $result == -1) {
      $child->{status} = $?
        if $result == $child->{pid};
      $child->{pid} = undef;
      return;
    }
    select undef, undef, undef, 0.02;
  }
  kill 'TERM', $child->{pid};
  waitpid($child->{pid}, 0);
  $child->{status} = $?;
  $child->{pid} = undef;
}

sub read_exact {
  my($fh,$length,$timeout,$child) = @_;
  my $select = IO::Select->new($fh);
  $select->add($child->{error}) if $child && $child->{error_open};
  my $deadline = time + $timeout;
  my $result = '';
  while (length($result) < $length) {
    my $remaining = $deadline - time;
    die "timed out reading $length bytes" if $remaining <= 0;
    my @ready = $select->can_read($remaining);
    die "timed out reading $length bytes" unless @ready;
    for my $ready (@ready) {
      my $is_output = fileno($ready) == fileno($fh);
      my $got = sysread($ready, my $buffer,
        $is_output ? $length - length($result) : 16_384);
      die "read failed: $!" unless defined $got;
      if ($got == 0) {
        die "unexpected EOF after " . length($result) . " of $length bytes" if $is_output;
        $select->remove($ready);
        $child->{error_open} = 0 if $child;
        next;
      }
      if ($is_output) { $result .= $buffer }
      else { $child->{diagnostics} .= $buffer }
    }
  }
  return $result;
}

sub read_line {
  my($fh,$child) = @_;
  my $line = '';
  my $deadline = time + 5;
  while (length($line) < 64) {
    $line .= read_exact($fh,1,$deadline - time,$child);
    return $line if $line =~ /\n\z/;
  }
  die 'oversized handshake';
}

sub read_frame {
  my($fh,$child) = @_;
  my $header = '';
  my $deadline = time + 5;
  while (length($header) < 33) {
    $header .= read_exact($fh,1,$deadline - time,$child);
    last if $header =~ /:\z/;
  }
  die "invalid frame prefix: $header" unless $header =~ /\A([0-9]{6,}):\z/;
  return read_exact($fh,0 + $1,5,$child);
}

sub write_all {
  my($fh,$bytes) = @_;
  local $SIG{PIPE} = 'IGNORE';
  while (length $bytes) {
    my $written = syswrite($fh,$bytes);
    die "write failed: $!" unless defined($written) && $written > 0;
    substr($bytes,0,$written) = '';
  }
}

sub send_frame {
  my($child,$payload) = @_;
  my $bytes = encode('UTF-8',$payload);
  write_all($child->{input},sprintf('%06d:',length($bytes)) . $bytes);
}

sub request {
  my($child,$instructions) = @_;
  send_frame($child,Test::FitNesse::Slim::List->new($instructions)->serialize);
  my $wire = decode('UTF-8',read_frame($child->{output},$child),FB_CROAK);
  return [Test::FitNesse::Slim::List->new($wire)->list];
}

sub tunnel_records {
  my($child,$offset) = @_;
  if ($child->{error_open}) {
    my $select = IO::Select->new($child->{error});
    my $deadline = time + 0.05;
    while (time < $deadline && $select->can_read(0.01)) {
      my $got = sysread($child->{error},my $buffer,16_384);
      if (!defined($got) || $got == 0) {
        $child->{error_open} = 0;
        last;
      }
      $child->{diagnostics} .= $buffer;
    }
  }
  my $text = substr($child->{diagnostics},$offset);
  return [grep { /\A(?:SOUT :|SOUT\.:|SERR :|SERR\.:)/ }
    split /(?<=\n)/, $text];
}

my $child = start_child();
is(read_line($child->{output},$child),"Slim -- V0.5\n",'port 1 selects the v0.5 stdin/stdout handshake');

my $unicode = 'München / Tartu õun / Mae govannen / 😀 é';
my $first = request($child,[
  [i => import => 'fitnesse.slim.test'],
  [m => make => actor => 'PipeTransportFixture'],
  [remember => call => actor => 'remember' => $unicode],
  [saved => callAndAssign => saved => actor => 'echo' => $unicode],
  [empty => call => actor => 'empty_string'],
  [null => call => actor => 'null'],
  [list => call => actor => 'empty_list'],
]);
is_deeply($first,[
  [i => 'OK'], [m => 'OK'], [remember => $unicode], [saved => $unicode], [empty => ''], [null => 'null'],
  [list => []],
],'one framed batch preserves Unicode, empty string, null, and empty list values');

my $second = request($child,[
  [echo => call => actor => 'echo' => '$saved'],
  [previous => call => actor => 'remembered'],
]);
is_deeply($second,[[echo => $unicode],[previous => $unicode]],
  'the fixture and symbol state persist across pipe request batches');

my $diagnostic_offset = length $child->{diagnostics};
my $output_test = request($child,[[out => call => actor => 'writeStdout' => 'fixture-stdout-marker']]);
is_deeply($output_test,[[out => 'fixture-stdout-marker']],
  'fixture stdout does not corrupt the next framed protocol response');
is_deeply(tunnel_records($child,$diagnostic_offset),["SOUT.:fixture-stdout-marker\n"],
  'a complete stdout line uses the pinned FitNesse first-line prefix');

$diagnostic_offset = length $child->{diagnostics};
request($child,[[explicit => call => actor => 'writeExplicitStdout' => 'explicit-stdout']]);
is_deeply(tunnel_records($child,$diagnostic_offset),["SOUT.:explicit-stdout\n"],
  'explicit print STDOUT is tunneled');

$diagnostic_offset = length $child->{diagnostics};
request($child,[
  [first => call => actor => 'writeStdout' => 'first-print'],
  [second => call => actor => 'writeStdout' => 'second-print'],
]);
is_deeply(tunnel_records($child,$diagnostic_offset),
  ["SOUT.:first-print\n","SOUT.:second-print\n"],
  'each fixture call is a separate output message within one instruction batch');

$diagnostic_offset = length $child->{diagnostics};
my $stderr_test = request($child,[[err => call => actor => 'writeStderr' => 'fixture-stderr-marker']]);
is_deeply($stderr_test,[[err => 'fixture-stderr-marker']],
  'fixture stderr does not corrupt protocol responses');
is_deeply(tunnel_records($child,$diagnostic_offset),["SERR.:fixture-stderr-marker\n"],
  'a complete stderr line uses the pinned FitNesse first-line prefix');

$diagnostic_offset = length $child->{diagnostics};
request($child,[[explicit => call => actor => 'writeExplicitStderr' => 'explicit-stderr']]);
is_deeply(tunnel_records($child,$diagnostic_offset),["SERR.:explicit-stderr\n"],
  'explicit print STDERR is tunneled separately');

$diagnostic_offset = length $child->{diagnostics};
request($child,[[multi => call => actor => 'writeStdoutBytes' => "line one\nline two"]]);
is_deeply(tunnel_records($child,$diagnostic_offset),
  ["SOUT.:line one\n","SOUT :line two\n"],
  'multiline output uses continuation prefixes and terminates a partial final line');

$diagnostic_offset = length $child->{diagnostics};
request($child,[[partial => call => actor => 'writeStdoutBytes' => 'partial-line']]);
is_deeply(tunnel_records($child,$diagnostic_offset),["SOUT.:partial-line\n"],
  'a partial line is terminated as one tunnel record');

$diagnostic_offset = length $child->{diagnostics};
request($child,[[blank => call => actor => 'writeStdoutBytes' => "\n"]]);
is_deeply(tunnel_records($child,$diagnostic_offset),[],
  'a one-line empty message follows the pinned logger and does not create a blank record');

$diagnostic_offset = length $child->{diagnostics};
request($child,[[blank => call => actor => 'writeStdoutBytes' => "before\n\nafter\n"]]);
is_deeply(tunnel_records($child,$diagnostic_offset),
  ["SOUT.:before\n","SOUT :\n","SOUT :after\n"],
  'an empty line inside a multi-line message is preserved');

my $unicode_output = 'Grüße / Tartu õun / Mae govannen 😀';
$diagnostic_offset = length $child->{diagnostics};
request($child,[[unicode => call => actor => 'writeStdoutBytes' => $unicode_output]]);
is_deeply(tunnel_records($child,$diagnostic_offset),
  ["SOUT.:" . encode('UTF-8', $unicode_output) . "\n"],
  'Unicode output stays UTF-8 across tunnel framing');

$diagnostic_offset = length $child->{diagnostics};
request($child,[[alternating => call => actor => 'writeAlternating']]);
my $alternating_records = tunnel_records($child,$diagnostic_offset);
is_deeply([grep { /^SOUT/ } @$alternating_records],
  ["SOUT.:first-out\n","SOUT :last-out\n"],
  'stdout retains its independent channel and line sequence');
is_deeply([grep { /^SERR/ } @$alternating_records],
  ["SERR.:middle-err\n"],
  'stderr retains its independent channel');

$diagnostic_offset = length $child->{diagnostics};
my $large_result = request($child,[[large => call => actor => 'writeLargeStdout' => 1_048_576]]);
is_deeply($large_result,[[large => 1_048_576]],'large fixture output does not block the protocol session');
my $large_records = tunnel_records($child,$diagnostic_offset);
is(scalar(@$large_records),1,'a large one-line diagnostic remains one valid record');
is(length($large_records->[0]),1_048_583,'large diagnostics are streamed without truncation');
like($large_records->[0],qr/\ASOUT\.:x+\n\z/,'large record retains its prefix and terminator');

$diagnostic_offset = length $child->{diagnostics};
my $child_result = request($child,[[child => call => actor => 'writeChildOutput']]);
is_deeply($child_result,[[child => 'child complete']],
  'a synchronous fixture subprocess inherits safe output capture descriptors');
is_deeply(tunnel_records($child,$diagnostic_offset),
  ["SOUT.:child-out\n","SERR.:child-err\n"],
  'subprocess stdout and stderr are tunneled to their independent channels');

$diagnostic_offset = length $child->{diagnostics};
my $exception_result = request($child,[[exception => call => actor => 'writeStdoutThenDie']]);
like($exception_result->[0][1],qr/^__EXCEPTION__:/,'fixture exception remains a SLiM exception');
is_deeply(tunnel_records($child,$diagnostic_offset),["SOUT.:before-exception\n"],
  'output immediately before a fixture exception is tunneled before its response');

send_frame($child,'bye');
my $readable = IO::Select->new($child->{output})->can_read(5);
ok($readable,'child closes its protocol output after bye');
my $eof = sysread($child->{output},my $extra,1);
is($eof,0,'bye produces no extra response frame');
close $child->{input};
stop_child($child);
is($child->{status} >> 8,0,'bye terminates the pipe child successfully');

my $closed_diagnostics = start_child();
read_line($closed_diagnostics->{output},$closed_diagnostics);
close $closed_diagnostics->{error};
$closed_diagnostics->{error_open} = 0;
my $after_closed_diagnostics = request($closed_diagnostics,
  [[i => import => 'fitnesse.slim.test'],[m => make => actor => 'PipeTransportFixture'],
   [write => call => actor => 'writeStdout' => 'diagnostics closed']]);
is($after_closed_diagnostics->[-1][1],'diagnostics closed',
  'a closed diagnostic stream does not prevent a valid protocol response');
send_frame($closed_diagnostics,'bye');
close $closed_diagnostics->{input};
stop_child($closed_diagnostics);
is($closed_diagnostics->{status} >> 8,0,
  'a closed diagnostic stream is nonfatal to pipe session cleanup');

my $eof_child = start_child();
is(read_line($eof_child->{output},$eof_child),"Slim -- V0.5\n",'a second child starts a separate pipe session');
close $eof_child->{input};
stop_child($eof_child);
is($eof_child->{status} >> 8,0,'clean EOF terminates the pipe child successfully');

my $truncated = start_child();
read_line($truncated->{output},$truncated);
write_all($truncated->{input},'000020:[');
close $truncated->{input};
stop_child($truncated);
 isnt($truncated->{status} >> 8,0,'truncated frame fails the pipe child without a response');

my $malformed = start_child();
read_line($malformed->{output});
write_all($malformed->{input},'not-a-frame');
close $malformed->{input};
stop_child($malformed);
isnt($malformed->{status} >> 8,0,'invalid frame prefix fails the pipe child');

my $marker_path = "/tmp/test-slim-pipe-atomic-$$";
unlink $marker_path;
my $bad_list = start_child();
read_line($bad_list->{output},$bad_list);
my $serialized = Test::FitNesse::Slim::List->new([
  [i => import => 'fitnesse.slim.test'],
  [m => make => actor => 'PipeTransportFixture'],
  [mark => call => actor => 'writeMarker' => $marker_path],
])->serialize;
chop $serialized;
$serialized .= 'x';
send_frame($bad_list,$serialized);
close $bad_list->{input};
stop_child($bad_list);
ok(!-e $marker_path,'a structurally corrupt batch executes none of its valid leading instructions');
isnt($bad_list->{status} >> 8,0,'corrupt serialized payload terminates only its pipe child');
unlink $marker_path;

my $bad_instruction = start_child();
read_line($bad_instruction->{output},$bad_instruction);
my $bad_response = request($bad_instruction,[['bad','unknownOperation']]);
like($bad_response->[0][1],qr/^__EXCEPTION__:message:<<MALFORMED_INSTRUCTION/,
  'valid framing with malformed instruction returns the protocol exception');
my $after_bad = request($bad_instruction,[[ok => import => 'fitnesse.slim.test']]);
is_deeply($after_bad,[[ok => 'OK']],
  'pipe session continues after a validly framed malformed instruction');
send_frame($bad_instruction,'bye');
close $bad_instruction->{input};
stop_child($bad_instruction);
is($bad_instruction->{status} >> 8,0,'malformed instruction does not poison session shutdown');

my $broken_output = start_child();
read_line($broken_output->{output},$broken_output);
close $broken_output->{output};
send_frame($broken_output,Test::FitNesse::Slim::List->new([[ok => import => 'fitnesse.slim.test']])->serialize);
close $broken_output->{input};
stop_child($broken_output);
isnt($broken_output->{status} >> 8,0,'broken protocol output pipe fails the child without SIGPIPE termination');

my $flag_child = start_child('-v','-s','1','1');
is(read_line($flag_child->{output},$flag_child),"Slim -- V0.5\n",
  'FitNesse -v -s 1 port command form starts a pipe child');
my $flag_response = request($flag_child,[
  [i => import => 'fitnesse.slim.test'],
  [m => make => sleeper => 'fitnesse.slim.test.Sleep'],
  [set => call => sleeper => 'setTimer' => 2000],
  [timeout => call => sleeper => 'doSleep'],
]);
is($flag_response->[0][1],'OK','flagged pipe child executes setup instructions');
is($flag_response->[3][1],'__EXCEPTION__:message:<<TIMED_OUT 1>>',
  '-s applies the Java-compatible timeout response to an overlong fixture method');
like($flag_child->{diagnostics},qr/SLiM request:/,
  '-v writes verbose diagnostics to stderr, outside the protocol stream');
my $after_timeout = request($flag_child,[
  [set => call => sleeper => 'setTimer' => 10],
  [wake => call => sleeper => 'doSleep'],
]);
is_deeply($after_timeout,[[set => 'null'],[wake => 'WakeUp 10']],
  'a timed-out call does not poison later statements or batches');
send_frame($flag_child,'bye');
stop_child($flag_child);
is($flag_child->{status} >> 8,0,'flagged pipe child exits cleanly after bye');

done_testing;
