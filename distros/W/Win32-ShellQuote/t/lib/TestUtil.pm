package TestUtil;
use strict;
use warnings;

use Data::Dumper qw(Dumper);
use File::Temp qw(tempfile);
use Exporter; *import = \&Exporter::import;

our @EXPORT = qw(capture dd guard make_random_strings make_random_string);

sub TestGuard::DESTROY { $_[0][0]->(); }

sub guard (&) {
  bless [ $_[0] ], 'TestGuard';
}

sub dd ($) {
  my $params = shift;;
  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Useqq = 1;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Useqq = 1;

  my $out = Dumper($params);
  chomp $out;
  return $out;
}

sub capture (&) {
  my ($sub) = @_;
  open my $oldout, '>&', \*STDOUT or die "can't dup STDOUT: $!";
  open my $olderr, '>&', \*STDERR or die "can't dup STDERR: $!";
  my ($fh, $filename) = tempfile( 'win32-shellquote-XXXXXX', TMPDIR => 1 );
  my $file_guard = guard { unlink $filename };
  open STDOUT, '>&', $fh or die "can't dup temp fh: $!";;
  open STDERR, '>&', $fh or die "can't dup temp fh: $!";;
  my ($e, $fail);
  if (!eval { $sub->(); 1 }) {
    ($e, $fail) = ($@, 1);
  }
  open STDOUT, '>&', $oldout or die "can't restore STDOUT: $!";
  open STDERR, '>&', $olderr or die "can't restore STDERR: $!";
  die $e
    if $fail;
  seek $fh, 0, 0;
  my $content = do { local $/; <$fh> };
  return $content;
}

sub make_random_strings {
  my ($string_count) = @_;

  my @charsets = map [ map chr, @{$_} ],
    [ 32 .. 126 ],
    [ 10, 13, 32 .. 126 ],
    [ 1 .. 127 ],
    [ 1 .. 255 ],
  ;

  map make_random_string($charsets[ rand @charsets ]), 1 .. $string_count;
}

sub make_random_string {
  my ($chars, $count) = @_;
  $count ||= 70;

  join '', map $chars->[ rand @$chars ], 1 .. int rand $count;
}

1;
