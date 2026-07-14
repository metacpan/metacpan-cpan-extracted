#!perl

# Exercises slurp_utf8($filename): it opens the file with unbuffered (:unix)
# IO and returns the whole content decoded to characters, with the same
# maximal-subpart -> U+FFFD substitution and utf8 warnings as decode_utf8().

use strict;
use warnings;
use lib 't';

use Test::More;
use Unicode::UTF8 qw[ slurp_utf8 decode_utf8 encode_utf8 ];
use Util          qw[ throws_ok warns_ok ];

use File::Temp qw[ tempfile tempdir ];
use Config;

sub file_of {
  my ($bytes) = @_;
  my ($fh, $path) = tempfile(UNLINK => 1);
  binmode $fh;
  print {$fh} $bytes;
  close $fh;
  return $path;
}

sub oracle {
  my ($bytes) = @_;
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };
  use warnings 'utf8';
  my $chars = decode_utf8($bytes);
  return ($chars, scalar @w);
}

sub slurp_quiet {
  my ($path) = @_;
  no warnings 'utf8';
  return slurp_utf8($path);
}

my $euro = "\xE2\x82\xAC";       # U+20AC, 3-byte
my $grin = "\xF0\x9F\x98\x80";   # U+1F600, 4-byte
my $aao  = encode_utf8("\x{E5}\x{E4}\x{F6}");

my %CORPUS = (
  'empty'                 => "",
  'ascii'                 => "hello world",
  'two-byte run'          => $aao,
  'mixed widths'          => "a${euro}b${grin}c\x{E5}",
  'lone continuation'     => "a\x80b",
  'C0 overlong'           => "\xC0\x80",
  'surrogate D800'        => "\xED\xA0\x80",
  'above 10FFFF'          => "\xF4\x90\x80\x80",
  'truncated 2-byte @EOF' => "a\xC3",
  'truncated 3-byte @EOF' => "x\xE2\x82",
  'ill lead then ascii'   => "\xD4\x42",
  'many subparts'         => "\x80\xC3\x80\xE2\x28\xA1",
  # spans several 64 KiB read chunks, splitting sequences across boundaries
  'large mixed + ill'     => ("z${grin}${euro}\x80abc" x 20000),
);

# ---- content and warning count match decode_utf8() ----------------------

for my $name (sort keys %CORPUS) {
  my $bytes = $CORPUS{$name};
  my ($want, $wwarn) = oracle($bytes);

  my @w;
  my $got;
  {
    local $SIG{__WARN__} = sub { push @w, @_ };
    use warnings 'utf8';
    $got = slurp_utf8(file_of($bytes));
  }

  is($got, $want,        "'$name': characters match decode_utf8");
  is(scalar @w, $wwarn,  "'$name': utf8 warning count matches decode_utf8");
  ok(utf8::is_utf8($got) || $got eq '', "'$name': result has the UTF8 flag");
}

# ---- explicit warning text ----------------------------------------------

warns_ok {
  use warnings 'utf8';
  slurp_utf8(file_of("a\x80b"));
} qr/Can't decode ill-formed UTF-8 octet sequence <80>/,
  'ill-formed: warns in the utf8 category';

warns_ok {
  use warnings 'utf8';
  slurp_utf8(file_of("a\xC3"));
} qr/Can't decode ill-formed UTF-8 octet sequence <C3> at end of file/,
  'truncated at EOF: end-of-file warning variant';

{ # suppressed under 'no warnings utf8', still replaced
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };
  my $got = slurp_quiet(file_of("a\x80b"));
  is(scalar @w, 0,          'ill-formed: silent without utf8 warnings');
  is($got, "a\x{FFFD}b",    'ill-formed: still replaced when silent');
}

# ---- non-regular file (FIFO): no size hint ------------------------------

SKIP: {
  skip 'no fork/mkfifo on this platform', 2
    unless eval { require POSIX; POSIX->import('mkfifo'); 1 }
        && $Config::Config{d_fork};

  my $dir  = tempdir(CLEANUP => 1);
  my $fifo = "$dir/pipe";
  POSIX::mkfifo($fifo, 0600) or skip "mkfifo failed: $!", 2;

  my $bytes = "pipe:${euro}\x80${grin}tail\xE2\x82";
  my ($want, $wwarn) = oracle($bytes);

  my $pid = fork;
  skip 'fork failed', 2 unless defined $pid;
  if ($pid == 0) {
    open my $w, '>', $fifo or POSIX::_exit(1);
    binmode $w;
    print {$w} $bytes;
    close $w;
    POSIX::_exit(0);
  }

  my @w;
  my $got;
  {
    local $SIG{__WARN__} = sub { push @w, @_ };
    use warnings 'utf8';
    $got = slurp_utf8($fifo);
  }
  waitpid($pid, 0);

  is($got, $want,       'FIFO: characters match decode_utf8');
  is(scalar @w, $wwarn, 'FIFO: utf8 warning count matches decode_utf8');
}

# ---- errors --------------------------------------------------------------

throws_ok {
  slurp_utf8("this/file/does/not/exist.$$");
} qr!^Couldn't open 'this/file/does/not/exist\.$$': !,
  'missing file croaks with "Couldn\'t open ..."';

done_testing;
