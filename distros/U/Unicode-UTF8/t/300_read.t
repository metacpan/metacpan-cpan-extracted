#!perl

use strict;
use warnings;
use lib 't';

use Test::More;
use Unicode::UTF8 qw[ read_utf8 encode_utf8 ];
use Util          qw[ throws_ok warns_ok pack_utf8 ];

sub bytes_fh {
  my ($bytes) = @_;
  open my $fh, '<', \$bytes
    or die qq/Couldn't open in-memory handle: '$!'/;
  binmode $fh
    or die qq/Couldn't binmode in-memory handle: '$!'/;
  return $fh;
}

my $aao = "\x{E5}\x{E4}\x{F6}";        # å ä ö, three 2-byte sequences
my $aao_bytes = encode_utf8($aao);

# basic reads

{
  my $fh = bytes_fh("hello");
  my $n  = read_utf8($fh, my $buf, 5);
  is($n,   5,       'ASCII: returns code-point count');
  is($buf, "hello", 'ASCII: buffer content');
  ok(utf8::is_utf8($buf), 'ASCII: buffer decoded as characters');
}

{
  my $fh = bytes_fh($aao_bytes);
  my $n  = read_utf8($fh, my $buf, 3);
  is($n,   3,    'multibyte: returns 3 code points');
  is($buf, $aao, 'multibyte: buffer content');
  is(length($buf), 3, 'multibyte: length is in characters, not bytes');
}


# length limit: request fewer code points than available, then drain

{
  my $fh = bytes_fh($aao_bytes);

  my $n1 = read_utf8($fh, my $buf1, 2);
  is($n1,   2,              'length limit: first read returns 2');
  is($buf1, "\x{E5}\x{E4}", 'length limit: first read content');

  my $n2 = read_utf8($fh, my $buf2, 2);
  is($n2,   1,        'length limit: second read returns remaining 1');
  is($buf2, "\x{F6}", 'length limit: second read content');

  my $n3 = read_utf8($fh, my $buf3, 2);
  is($n3,   0,  'length limit: third read at EOF returns 0');
  is($buf3, '', 'length limit: third read buffer empty');
}


# forced tiny reads across sequence boundaries

{
  my $fh  = bytes_fh($aao_bytes);
  my $out = '';
  my $sum = 0;
  while ((my $n = read_utf8($fh, my $buf, 1)) > 0) {
    $sum += $n;
    $out .= $buf;
  }
  is($sum, 3,    'tiny reads: total code points');
  is($out, $aao, 'tiny reads: reassembled content ends on char boundaries');
}


# offset: append into existing content at a byte offset

{
  my $fh  = bytes_fh($aao_bytes);
  my $buf = 'AB';
  my $n   = read_utf8($fh, $buf, 3, length $buf);
  is($n,   3,        'offset: returns count of newly read code points');
  is($buf, "AB$aao", 'offset: pre-offset content preserved, new appended');
}

{
  # offset past end zero-fills the gap
  my $fh  = bytes_fh("X");
  my $buf = 'AB';
  my $n   = read_utf8($fh, $buf, 1, 4);
  is($n,   1,             'offset past end: returns 1');
  is($buf, "AB\x00\x00X", 'offset past end: gap zero-filled');
}


# ill-formed input: warns in utf8 category, replaces maximal subpart w/ U+FFFD

{
  my $fh = bytes_fh("a\x80b");
  my $buf;
  warns_ok {
    use warnings 'utf8';
    read_utf8($fh, $buf, 10);
  } qr/Can't decode ill-formed UTF-8 octet sequence <80>/,
    'ill-formed: warns in utf8 category';
  is($buf, "a\x{FFFD}b", 'ill-formed: subpart replaced with U+FFFD');
}

{
  # warning suppressed when utf8 warnings are off
  my $fh = bytes_fh("a\x80b");
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };
  no warnings 'utf8';
  my $buf;
  read_utf8($fh, $buf, 10);
  is(scalar @w, 0,       'ill-formed: silent without utf8 warnings');
  is($buf, "a\x{FFFD}b", 'ill-formed: still replaced when silent');
}

{
  # count includes each U+FFFD substitution
  my $fh = bytes_fh("\x80\x80");
  my $buf;
  no warnings 'utf8';
  my $n = read_utf8($fh, $buf, 10);
  is($n,   2,                  'count includes substitutions');
  is($buf, "\x{FFFD}\x{FFFD}", 'two lone bytes -> two U+FFFD');
}

# truncated multibyte lead at EOF: warns with the end-of-file variant

{
  my $fh = bytes_fh("a\xC3");   # å lead byte with no continuation
  my $buf;
  warns_ok {
    use warnings 'utf8';
    read_utf8($fh, $buf, 10);
  } qr/Can't decode ill-formed UTF-8 octet sequence <C3> at end of file/,
    'truncated: warns with end-of-file variant';
  is($buf, "a\x{FFFD}", 'truncated: lead byte replaced with U+FFFD');
}

# error handling

{
  my $fh = bytes_fh("abc");
  throws_ok {
    read_utf8($fh, my $buf, -1);
  } qr/Negative length/, 'negative length croaks';
}

done_testing();
