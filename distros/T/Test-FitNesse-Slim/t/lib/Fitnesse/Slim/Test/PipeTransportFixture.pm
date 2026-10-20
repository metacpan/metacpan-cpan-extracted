package Fitnesse::Slim::Test::PipeTransportFixture;

use strict;
use warnings;
use Encode qw(encode_utf8);

sub new { bless { value => undef }, shift }
sub echo { $_[1] }
sub remember { $_[0]{value} = $_[1] }
sub remembered { $_[0]{value} }
sub empty_string { '' }
sub empty_list { [] }
sub null { undef }

sub write_stdout {
  print encode_utf8($_[1]), "\n";
  return $_[1];
}

sub write_stderr {
  print STDERR encode_utf8($_[1]), "\n";
  return $_[1];
}

sub write_stdout_bytes {
  my($self,$value) = @_;
  _write_all(*STDOUT, encode_utf8($value));
  return $value;
}

sub write_stderr_bytes {
  my($self,$value) = @_;
  _write_all(*STDERR, encode_utf8($value));
  return $value;
}

sub write_explicit_stdout {
  my($self,$value) = @_;
  print STDOUT encode_utf8($value);
  return $value;
}

sub write_explicit_stderr {
  my($self,$value) = @_;
  print STDERR encode_utf8($value);
  return $value;
}

sub write_large_stdout {
  my($self,$size) = @_;
  my $chunk = 'x' x 8192;
  my $remaining = $size;
  while ($remaining > 0) {
    my $part = $remaining > length($chunk) ? $chunk : substr($chunk, 0, $remaining);
    _write_all(*STDOUT, $part);
    $remaining -= length($part);
  }
  return $size;
}

sub write_alternating {
  my($self) = @_;
  _write_all(*STDOUT, "first-out\n");
  _write_all(*STDERR, "middle-err\n");
  _write_all(*STDOUT, "last-out\n");
  return 'alternated';
}

sub write_child_output {
  my($self) = @_;
  my $code = 'binmode STDOUT; binmode STDERR; print "child-out\\n"; print STDERR "child-err\\n";';
  system($^X, '-e', $code) == 0 or die "output child failed: $?";
  return 'child complete';
}

sub write_stdout_then_die {
  my($self) = @_;
  _write_all(*STDOUT, "before-exception\n");
  die "expected fixture exception\n";
}

sub write_marker {
  my($self,$path) = @_;
  open my $marker, '>', $path or die "create execution marker: $!";
  print {$marker} "executed\n" or die "write execution marker: $!";
  close $marker or die "close execution marker: $!";
  return 'written';
}

sub _write_all {
  my($fh,$bytes) = @_;
  while (length $bytes) {
    my $written = syswrite($fh,$bytes);
    die "fixture output failed: $!" unless defined($written) && $written > 0;
    substr($bytes, 0, $written) = '';
  }
  return;
}

1;
