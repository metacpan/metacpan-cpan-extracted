use strict;
use warnings;
use utf8;

use if $^O eq 'MSWin32' && "$]" < 5.022, 'Test::More',
  skip_all => 'Perl 5.22 required for pipe open tests on Windows';

use Test::More;
use File::Temp;
use open::layers;

sub _in_fork (&) {
  my $code = shift;
  my $tempfh = File::Temp->new;
  my $pid = fork;
  die "fork failed: $!" unless defined $pid;
  if ($pid) {
    waitpid $pid, 0;
    seek $tempfh, 0, 0;
    local $/;
    return scalar readline $tempfh;
  } else {
    my $output = $code->();
    print $tempfh $output;
    exit;
  }
}

sub _capture_stdout (&) {
  my $code = shift;
  my $pid = open my $fh, '-|';
  die "fork failed: $!" unless defined $pid;
  if ($pid) {
    binmode $fh or die "binmode failed: $!";
    local $/;
    return scalar readline $fh;
  } else {
    $code->();
    exit;
  }
}

sub _print_stdin (&$) {
  my ($code, $input) = @_;
  my $tempfh = File::Temp->new;
  my $pid = open my $fh, '|-';
  die "fork failed: $!" unless defined $pid;
  if ($pid) {
    binmode $fh or die "binmode failed: $!";;
    print $fh $input;
    close $fh;
    seek $tempfh, 0, 0;
    local $/;
    return scalar readline $tempfh;
  } else {
    my $output = $code->();
    print $tempfh $output;
    exit;
  }
}

my $result = _in_fork {
  open::layers->import(STDIN => ':utf8');
  my $stdin_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDIN;
  my $stdout_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDOUT;
  my $stderr_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDERR;
  return join ':', $stdin_layer, $stdout_layer, $stderr_layer;
};
is $result, '1:0:0', 'layer set on STDIN';

$result = _in_fork {
  open::layers->import(STDOUT => ':utf8');
  my $stdin_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDIN;
  my $stdout_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDOUT;
  my $stderr_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDERR;
  return join ':', $stdin_layer, $stdout_layer, $stderr_layer;
};
is $result, '0:1:0', 'layer set on STDOUT';

$result = _in_fork {
  open::layers->import(STDERR => ':utf8');
  my $stdin_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDIN;
  my $stdout_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDOUT;
  my $stderr_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDERR;
  return join ':', $stdin_layer, $stdout_layer, $stderr_layer;
};
is $result, '0:0:1', 'layer set on STDERR';

$result = _in_fork {
  open::layers->import(STDOUT => ':utf8', STDERR => ':utf8');
  my $stdin_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDIN;
  my $stdout_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDOUT;
  my $stderr_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDERR;
  return join ':', $stdin_layer, $stdout_layer, $stderr_layer;
};
is $result, '0:1:1', 'layer set on STDOUT and STDERR';

$result = _in_fork {
  open::layers->import(STDIO => ':utf8');
  my $stdin_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDIN;
  my $stdout_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDOUT;
  my $stderr_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDERR;
  return join ':', $stdin_layer, $stdout_layer, $stderr_layer;
};
is $result, '1:1:1', 'layer set on all STD handles';

$result = _in_fork {
  open::layers->import(rw => ':utf8');
  my $stdin_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDIN;
  my $stdout_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDOUT;
  my $stderr_layer = 0+!!grep { $_ eq 'utf8' } PerlIO::get_layers *STDERR;
  return join ':', $stdin_layer, $stdout_layer, $stderr_layer;
};
is $result, '0:0:0', 'layer set on no STD handles';

my $stdout = _capture_stdout {
  open::layers->import(STDOUT => ':raw');
  print "\xE2\n";
};
is $stdout, "\xE2\x0A", 'STDOUT not encoded (no CRLF)';

$stdout = _capture_stdout {
  open::layers->import(STDOUT => ':encoding(UTF-8)');
  print '☃';
};
is $stdout, "\xE2\x98\x83", 'STDOUT encoded to UTF-8';

$stdout = _capture_stdout {
  open::layers->import(STDIO => ':encoding(UTF-8)');
  print '☃';
};
is $stdout, "\xE2\x98\x83", 'STDIO encoded to UTF-8';

$stdout = _capture_stdout {
  open::layers->import(STDERR => ':encoding(UTF-8)');
  print "\xE2";
};
is $stdout, "\xE2", 'STDOUT not affected by STDERR';

$stdout = _capture_stdout {
  open::layers->import(STDIN => ':encoding(UTF-8)');
  print "\xE2";
};
is $stdout, "\xE2", 'STDOUT not affected by STDIN';

$stdout = _capture_stdout {
  open::layers->import(rw => ':encoding(UTF-8)');
  print "\xE2";
};
is $stdout, "\xE2", 'STDOUT not affected by rw';

my $ords = _print_stdin {
  open::layers->import(STDIN => ':raw');
  local $/;
  return sprintf '%vX', scalar readline *STDIN;
} "\xE2\n";
is $ords, 'E2.A', 'STDIN not decoded (no CRLF)';

$ords = _print_stdin {
  open::layers->import(STDIN => ':encoding(UTF-8)');
  local $/;
  return sprintf '%vX', scalar readline *STDIN;
} "\xE2\x98\x83";
is $ords, '2603', 'STDIN decoded from UTF-8';

$ords = _print_stdin {
  open::layers->import(STDIO => ':encoding(UTF-8)');
  local $/;
  return sprintf '%vX', scalar readline *STDIN;
} "\xE2\x98\x83";
is $ords, '2603', 'STDIO decoded from UTF-8';

$ords = _print_stdin {
  open::layers->import(STDOUT => ':encoding(UTF-8)');
  local $/;
  return sprintf '%vX', scalar readline *STDIN;
} "\xE2\x98\x83";
is $ords, 'E2.98.83', 'STDIN not affected by STDOUT';

$ords = _print_stdin {
  open::layers->import(STDERR => ':encoding(UTF-8)');
  local $/;
  return sprintf '%vX', scalar readline *STDIN;
} "\xE2\x98\x83";
is $ords, 'E2.98.83', 'STDIN not affected by STDERR';

$ords = _print_stdin {
  open::layers->import(rw => ':encoding(UTF-8)');
  local $/;
  return sprintf '%vX', scalar readline *STDIN;
} "\xE2\x98\x83";
is $ords, 'E2.98.83', 'STDIN not affected by rw';

done_testing;
