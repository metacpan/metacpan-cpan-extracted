#!perl

# Exercises read_utf8() over both PerlIO paths that PerlIO_read_utf8() takes:
#
#   * the fast-gets path  -- in-memory scalar handles and :raw/:perlio files,
#     whose layers expose PerlIO_get_cnt()/PerlIO_get_ptr(); validation, the
#     U+FFFD replacement and the code-point count all run straight out of the
#     layer buffer in a single pass;
#   * the non-buffered path -- a :unix file handle, which has no fast-gets
#     buffer and falls back to PerlIO_read().
#
# The invariant checked across every layer and every read schedule is that the
# bytes accumulated up to EOF, and the number of utf8 warnings emitted, are
# identical to decode_utf8() over the same octets (the reference decoder).

use strict;
use warnings;
use lib 't';

use Test::More;
use Unicode::UTF8 qw[ read_utf8 decode_utf8 encode_utf8 ];
use Util          qw[ throws_ok warns_ok pack_utf8 ];

use File::Temp qw[ tempfile ];

# ---- handle constructors -------------------------------------------------

sub scalar_fh {                       # in-memory scalar (fast-gets path)
  my ($bytes) = @_;
  open my $fh, '<', \$bytes
    or die qq/Couldn't open in-memory handle: '$!'/;
  binmode $fh or die qq/binmode: '$!'/;
  return $fh;
}

sub file_fh {                         # real file under an explicit layer
  my ($layer, $bytes) = @_;
  my ($tfh, $path) = tempfile(UNLINK => 1);
  binmode $tfh; print {$tfh} $bytes; close $tfh;
  open my $fh, "<$layer", $path
    or die qq/Couldn't open $layer handle: '$!'/;
  return $fh;
}

sub raw_fh    { file_fh(':raw',    $_[0]) }   # buffered  -> fast-gets path
sub unix_fh   { file_fh(':unix',   $_[0]) }   # unbuffered-> PerlIO_read path
sub perlio_fh { file_fh(':perlio', $_[0]) }   # buffered  -> fast-gets path

my %MAKERS = (
  'scalar' => \&scalar_fh,
  ':raw'   => \&raw_fh,
  ':unix'  => \&unix_fh,
  ':perlio'=> \&perlio_fh,
);
my @LAYERS = sort keys %MAKERS;

# Drain a handle to EOF using a fixed request size, collecting the decoded
# characters and the number of utf8 warnings emitted along the way.
sub drain {
  my ($fh, $req) = @_;
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };
  use warnings 'utf8';
  my $out = '';
  while ((my $n = read_utf8($fh, my $buf, $req)) > 0) {
    $out .= $buf;
  }
  return ($out, scalar @w);
}

# Reference: decode_utf8() decodes the whole octet string with the same
# maximal-subpart -> U+FFFD substitution and one warning per subpart.
sub oracle {
  my ($bytes) = @_;
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };
  use warnings 'utf8';
  my $chars = decode_utf8($bytes);
  return ($chars, scalar @w);
}

# ---- the edge-case corpus ------------------------------------------------

my $euro  = "\xE2\x82\xAC";           # U+20AC, 3-byte
my $grin  = "\xF0\x9F\x98\x80";       # U+1F600, 4-byte
my $aao   = encode_utf8("\x{E5}\x{E4}\x{F6}");   # three 2-byte sequences

my %CORPUS = (
  'empty'                 => "",
  'ascii'                 => "hello world",
  'two-byte run'          => $aao,
  'three-byte'            => "x${euro}y",
  'four-byte'             => "x${grin}y",
  'mixed widths'          => "a${euro}b${grin}c\x{E5}",
  'lone continuation'     => "a\x80b",
  'two lone continuations'=> "\x80\x80",
  'C0 overlong + trail'   => "\xC0\x80",
  'surrogate D800'        => "\xED\xA0\x80",
  'above 10FFFF'          => "\xF4\x90\x80\x80",
  'truncated 2-byte @EOF' => "a\xC3",
  'truncated 3-byte @EOF' => "x\xE2\x82",
  'truncated 4-byte @EOF' => "x\xF0\x9F\x98",
  'ill lead then ascii'   => "\xD4\x42",            # D4 lead, 42 not a cont
  'ill lead then multi'   => "\xC3${euro}",         # C3 lead, then U+20AC
  'valid then lone'       => "${euro}\x80${grin}",
  'many subparts'         => "\x80\xC3\x80\xE2\x28\xA1",
);

# A few larger inputs that span several fast-gets fills and force sequences
# to be split across buffer/read boundaries.
$CORPUS{'long ascii'}       = "abcd" x 5000;
$CORPUS{'long multibyte'}   = ($euro x 3000);
$CORPUS{'long mixed + ill'} = ("z${grin}${euro}\x80" x 2000);

# Read schedules: sizes that land the code-point budget on boundaries,
# mid-sequence, and well past EOF.
my @REQ = (1, 2, 3, 4, 5, 7, 64, 100_000);

# ---- cross-layer equivalence --------------------------------------------

for my $name (sort keys %CORPUS) {
  my $bytes = $CORPUS{$name};
  my ($want, $wwarn) = oracle($bytes);

  for my $layer (@LAYERS) {
    for my $req (@REQ) {
      my $fh = $MAKERS{$layer}->($bytes);
      my ($got, $gwarn) = drain($fh, $req);
      is($got, $want,    "[$layer req=$req] '$name': decoded chars match decode_utf8");
      is($gwarn, $wwarn, "[$layer req=$req] '$name': utf8 warning count matches decode_utf8");
    }
  }
}

# ---- deterministic random fuzz (fixed seed) -----------------------------

{
  srand(20240607);
  for my $i (1 .. 200) {
    my $len   = int(rand(40));
    my $bytes = join '', map { chr int rand 256 } 1 .. $len;
    my ($want, $wwarn) = oracle($bytes);

    for my $layer (@LAYERS) {
      my $req = (1, 2, 3, 5, 64)[int rand 5];
      my $fh  = $MAKERS{$layer}->($bytes);
      my ($got, $gwarn) = drain($fh, $req);
      is($got, $want,   "[fuzz $i $layer req=$req] chars match decode_utf8");
      is($gwarn, $wwarn,"[fuzz $i $layer req=$req] warn count matches decode_utf8");
    }
  }
}

# ---- "at least length" code-point semantics -----------------------------
#
# read_utf8() returns at least the requested number of code points. At a
# budget boundary the exact count is path-dependent (the fast-gets path may
# stop early and leave surplus octets in the layer; the non-buffered path may
# over-read a byte needed to classify a subpart) and which path a layer takes
# varies by perl version, so only the path-independent invariant is asserted:
# reading in two steps yields the same characters and total count as one read.

{
  no warnings 'utf8';
  for my $layer (@LAYERS) {
    my $fh = $MAKERS{$layer}->("A\xD4B");   # 'A', ill lead D4, 'B'
    my $n1 = read_utf8($fh, my $b1, 2);
    ok($n1 >= 2, "[$layer] returns at least the requested 2 code points");
    my $n2 = read_utf8($fh, my $b2, 10);
    is($b1 . $b2, "A\x{FFFD}B", "[$layer] A + U+FFFD(D4) + B reassembled across reads");
    is($n1 + $n2, 3, "[$layer] total code points across reads");
  }
}

# ---- offset handling (shared prologue, both paths) ----------------------

for my $layer (@LAYERS) {
  { # append at a byte offset, existing content preserved
    my $fh  = $MAKERS{$layer}->($aao);
    my $buf = 'AB';
    my $n   = read_utf8($fh, $buf, 3, length $buf);
    is($n, 3, "[$layer] offset: count of newly read code points");
    is($buf, "AB" . decode_utf8($aao), "[$layer] offset: prefix preserved, characters appended");
  }
  { # offset past end zero-fills the gap
    my $fh  = $MAKERS{$layer}->("X");
    my $buf = 'AB';
    my $n   = read_utf8($fh, $buf, 1, 4);
    is($n, 1, "[$layer] offset past end: returns 1");
    is($buf, "AB\x00\x00X", "[$layer] offset past end: gap zero-filled");
  }
  { # negative offset rewrites from an earlier character boundary
    my $fh  = $MAKERS{$layer}->($aao);
    my $buf = decode_utf8($aao);          # three characters already present
    my $n   = read_utf8($fh, $buf, 3, -3);
    is($n, 3, "[$layer] negative offset: returns 3");
    is($buf, decode_utf8($aao), "[$layer] negative offset: three trailing characters overwritten");
  }
}

# ---- explicit warning text (both paths) ---------------------------------

for my $layer (@LAYERS) {
  { # ill-formed mid-stream: warns in the utf8 category
    my $fh = $MAKERS{$layer}->("a\x80b");
    warns_ok {
      use warnings 'utf8';
      read_utf8($fh, my $buf, 10);
    } qr/Can't decode ill-formed UTF-8 octet sequence <80>/,
      "[$layer] ill-formed: warns in utf8 category";
  }
  { # truncated lead at EOF: end-of-file warning variant
    my $fh = $MAKERS{$layer}->("a\xC3");
    warns_ok {
      use warnings 'utf8';
      read_utf8($fh, my $buf, 10);
    } qr/Can't decode ill-formed UTF-8 octet sequence <C3> at end of file/,
      "[$layer] truncated: end-of-file warning variant";
  }
  { # suppressed under 'no warnings utf8', still replaced
    my $fh = $MAKERS{$layer}->("a\x80b");
    my @w; local $SIG{__WARN__} = sub { push @w, @_ };
    no warnings 'utf8';
    read_utf8($fh, my $buf, 10);
    is(scalar @w, 0, "[$layer] ill-formed: silent without utf8 warnings");
    is($buf, "a\x{FFFD}b", "[$layer] ill-formed: still replaced when silent");
  }
}

# ---- errors -------------------------------------------------------------

for my $layer (@LAYERS) {
  my $fh = $MAKERS{$layer}->("abc");
  throws_ok {
    read_utf8($fh, my $buf, -1);
  } qr/Negative length/, "[$layer] negative length croaks";
}

done_testing();
