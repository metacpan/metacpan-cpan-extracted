# Unit tests for WARC::Record::Logical::Block module		# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use Test::More tests =>
     2	# loading tests
  +  4	# basic tests
  +  8	# verify READLINE (slurp mode)
  + 10	# verify READLINE (record mode)
  + 16	# verify READLINE (paragraph mode)
  + 28	# verify READLINE (line mode)
  +  6	# verify READLINE (mixed modes)
  + 18	# verify READ
  +  2	# verify GETC
  +  0	# EOF tested as part of other tests
  + 16;	# verify SEEL and TELL

BEGIN { use_ok('WARC::Record::Logical::Block')
	  or BAIL_OUT "WARC::Record::Logical::Block failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Record::Logical::Block v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/ version v9999.*required--this is only version/,
     'WARC::Record::Logical::Block version check')
}

# Get SEG_REC, SEG_BASE, SEG_LENGTH
BEGIN { $::{$_} = $WARC::Record::Logical::{$_}
	  for WARC::Record::Logical::SEGMENT_INDEX }

use Fcntl qw/SEEK_SET SEEK_CUR SEEK_END/;
use Symbol 'geniosym';
use Math::BigInt;

{
  package WARC::Record::_BlockTestMock;

  # The object is a blessed reference to a string, which is opened as a
  # filehandle by the ->open_block instance method.

  use Test::More;
  use IO::Uncompress::Gunzip '$GunzipError';

  sub open_block {
    my $self = shift;	# reference to string contents
    my $fh; my $data = $$self;
    # work around bug in old perls:  paragraph reads from in-memory files fail
    ((not defined $/ or $/ ne '') and open $fh, '<', \ $data)
      # IO::Uncompress::Gunzip does not have the same problem
      or $fh = new IO::Uncompress::Gunzip (\ $data, Transparent => 1)
	or BAIL_OUT "cannot open string as file: $! $GunzipError";
    return $fh;
  }
}

my $BigInt_Threshold = 32768;
sub make_test_handle (@) {
  my $running_base = 0;
  my @segments = map {
    my $seg = []; my $data = $_;
    $seg->[SEG_REC] = bless \$data, 'WARC::Record::_BlockTestMock';
    $seg->[SEG_LENGTH] = length $data;
    $running_base = Math::BigInt->new($running_base)
      if (not ref $running_base) && ($running_base > $BigInt_Threshold);
    $seg->[SEG_BASE] = $running_base;
    $running_base += $seg->[SEG_LENGTH];
    $seg;
  } @_;
  my $mr = { segments => \@segments };

  my $xh = geniosym;
  tie *$xh, 'WARC::Record::Logical::Block', $mr;

  note('inner handle: ',
       ((tied *$xh)->[WARC::Record::Logical::Block::HANDLE]));
  return $xh;
}

sub note_handle_state ($) {
  my $xh = shift;
  note("handle state:  ", (tied *$xh)->_dbg_dump);
}

note('*' x 60);

# Basic tests
{
  my $xh = make_test_handle 'test', 'data12';

  isa_ok(tied *$xh, 'WARC::Record::Logical::Block', 'tied object behind handle');
  diag('tests run with base handle as:  ',
       ref ((tied *$xh)->[WARC::Record::Logical::Block::HANDLE]));
  note_handle_state $xh;
  ok((not eof $xh),		'tied handle initially not at eof');
  is(scalar <$xh>, 'testdata12','expected data read');
  note_handle_state $xh;
  ok((eof $xh),			'tied handle now at eof');

  close *$xh;
}

note('*' x 60);

# Verify READLINE (slurp)
{
  local $/ = undef;	# select slurp mode

  ## slurp:  one segment
  my $xh = make_test_handle "testdata12\ntestdata34\n";
  is(scalar <$xh>, "testdata12\ntestdata34\n",
				'expected read in slurp from one segment');
  ok((eof $xh),			'handle at eof after slurp');

  ## slurp:  from segment boundary
  $xh = make_test_handle "testdata12\n", "test34\ndata56\n";
  { local $/ = "\n"; <$xh> } # advance one line
  is(scalar <$xh>, "test34\ndata56\n",
				'expected read in slurp from boundary');
  ok((eof $xh),			'handle at eof after slurp');

  ## slurp:  spanning segments
  $xh = make_test_handle "test12\n", "data34\nabcd\nefgh\n", "ijkl56\nmnop78\n";
  is(scalar <$xh>, "test12\ndata34\nabcd\nefgh\nijkl56\nmnop78\n",
				'expected read in slurp spanning segments');
  ok((eof $xh),			'handle at eof after slurp');

  ## slurp:  at EOF
  ok((not defined scalar <$xh>),'slurp when at eof after slurp');
  ok((eof $xh),			'handle still at eof after slurp at eof');
}

note('*' x 60);

# Verify READLINE (record)
{
  local $/ = \4;	# select record mode

  my $xh = make_test_handle
    '0123456789AB','CDEFGH','IJK','L','M','NOP','Q','R','STUV';
  note_handle_state $xh;
  is(scalar <$xh>, '0123',	'read first record');
  note_handle_state $xh;
  ## record:  within segment
  is(scalar <$xh>, '4567',	'read record within segment');
  note_handle_state $xh;
  ## record:  to segment boundary
  is(scalar <$xh>, '89AB',	'read record to segment boundary');
  note_handle_state $xh;
  ## record:  from segment boundary
  is(scalar <$xh>, 'CDEF',	'read record from segment boundary');
  note_handle_state $xh;
  ## record:  straddling segment boundary
  is(scalar <$xh>, 'GHIJ',	'read record straddling segment boundary');
  note_handle_state $xh;
  ## record:  spanning segments
  is(scalar <$xh>, 'KLMN',	'read record spanning segments');
  note_handle_state $xh;
  ## record:  spanning segments to boundary
  is(scalar <$xh>, 'OPQR',	'read record spanning segments to boundary');
  note_handle_state $xh;
  ## record:  to EOF
  is(scalar <$xh>, 'STUV',	'read record to eof');
  note_handle_state $xh;
  ## record:  at EOF
  ok((not defined scalar <$xh>),'read record at eof');
  ok((eof $xh),			'handle still at eof after read at eof');
  note_handle_state $xh;
}

note('*' x 60);

# Verify READLINE (paragraph)
{
  local $/ = '';	# select paragraph mode

  my $xh = make_test_handle
    "abc\ndef\n\n\n\nghi\njkl\n\n", "mno\npqr\nstu\n\nvwx\nyz", "0\n\n123\n456";
  note_handle_state $xh;
  ## paragraph:  within segment
  is(scalar <$xh>, "abc\ndef\n\n\n\n",
				'read paragraph within segment');
  note_handle_state $xh;
  ## paragraph:  to segment boundary
  is(scalar <$xh>, "ghi\njkl\n\n",
				'read paragraph to segment boundary');
  note_handle_state $xh;
  ## paragraph:  from segment boundary
  is(scalar <$xh>, "mno\npqr\nstu\n\n",
				'read paragraph from segment boundary');
  note_handle_state $xh;
  ## paragraph:  straddling segment boundary
  is(scalar <$xh>, "vwx\nyz0\n\n",
				'read paragraph straddling segment boundary');
  note_handle_state $xh;
  ## paragraph:  to EOF without delimiter
  is(scalar <$xh>, "123\n456",	'read paragraph to eof without delimiter');
  ok((eof $xh),			'filehandle now at eof');
  note_handle_state $xh;
  ## paragraph:  at EOF without delimiter
  ok((not defined scalar <$xh>),'read paragraph at eof');
  ok((eof $xh),			'handle still at eof after read at eof');
  note_handle_state $xh;

  $xh = make_test_handle
    "abc\ndef\n", "ghi\n\njkl","\nmno\n", "pqr\n\nstu\n", "vwx\n", "yz0\n\n",
      "123\n456\n\n", "\n\n789\n\n";
  note_handle_state $xh;
  ## paragraph:  straddling segment boundary with inner end-of-line at boundary
  is(scalar <$xh>, "abc\ndef\nghi\n\n",
     'read paragraph straddling segment boundary with end-of-line at same');
  note_handle_state $xh;
  ## paragraph:  spanning segments
  is(scalar <$xh>, "jkl\nmno\npqr\n\n",
				'read paragraph spanning segments');
  note_handle_state $xh;
  ## paragraph:  spanning segments to boundary
  is(scalar <$xh>, "stu\nvwx\nyz0\n\n",
     'read paragraph spanning segments to boundary');
  note_handle_state $xh;
  ## paragraph:  delimiter straddling segment boundary
  is(scalar <$xh>, "123\n456\n\n\n\n",
     'read paragraph with delimiter straddling segment boundary');
  note_handle_state $xh;
  ## paragraph:  to EOF with delimiter
  ok((not eof $xh),		'not at eof yet');
  is(scalar <$xh>, "789\n\n",	'read paragraph to eof with delimiter');
  note_handle_state $xh;
  ## paragraph:  at EOF after delimiter
  ok((not defined scalar <$xh>),'read paragraph at eof');
  ok((eof $xh),			'handle still at eof after read at eof');
  note_handle_state $xh;
}

note('*' x 60);

# Verify READLINE (line)
{
  # start with the default end-of-line

  my $xh = make_test_handle "abc\ndef\n", "ghi\njk", "l mn", "o\npq", "r s",
    "tu\n","vw", "x y", "z0\n", "123"," 45","6 789\n";
  note_handle_state $xh;
  ## line:  within segment
  is(scalar <$xh>, "abc\n",	'read line within segment');
  note_handle_state $xh;
  ## line:  to segment boundary
  is(scalar <$xh>, "def\n",	'read line to segment boundary');
  note_handle_state $xh;
  ## line:  from segment boundary
  is(scalar <$xh>, "ghi\n",	'read line from segment boundary');
  note_handle_state $xh;
  ## line:  straddling segment boundary
  is(scalar <$xh>, "jkl mno\n",	'read line straddling segment boundary');
  note_handle_state $xh;
  ## line:  spanning segments
  is(scalar <$xh>, "pqr stu\n",	'read line spanning segments');
  note_handle_state $xh;
  ## line:  spanning segments to boundary
  is(scalar <$xh>, "vwx yz0\n",	'read line spanning segments to boundary');
  note_handle_state $xh;
  ## line:  to EOF with delimiter
  is(scalar <$xh>, "123 456 789\n",
				'read line to eof with delimiter');
  note_handle_state $xh;

  $xh = make_test_handle "abc\ndef", "\nghi\njkl\n";
  ## line:  read all
  note_handle_state $xh;
  is_deeply([<$xh>], ["abc\n", "def\n", "ghi\n", "jkl\n"],
				'read all lines');
  note_handle_state $xh;
  ok((eof $xh),			'handle at eof after list read');

  $xh = make_test_handle "123"," 45","6 789";
  note_handle_state $xh;
  ## line:  to EOF without delimiter
  is(scalar <$xh>, "123 456 789",
				'read line to eof without delimiter');
  note_handle_state $xh;
  ## line:  at EOF
  ok((not defined scalar <$xh>),'read line at eof');
  note_handle_state $xh;
  ok((eof $xh),			'handle still at eof after read at eof');
  note_handle_state $xh;

  local $/ = "ABCD";

  $xh = make_test_handle '1234ABCD5678ABCD', '09baABCDdcfe', 'ghijABCDklmn',
    'ABCDopqrAB', 'CDstuvAB', 'ABCABCDwxy', 'zAB', 'CA', 'BEA', 'BA', 'BCD01',
      '234AB';
  note_handle_state $xh;
  ## line:  multi-char delimiter within segment
  is(scalar <$xh>, '1234ABCD',	'read mcd line within segment');
  note_handle_state $xh;
  ## line:  multi-char delimiter to segment boundary
  is(scalar <$xh>, '5678ABCD',	'read mcd line to segment boundary');
  note_handle_state $xh;
  ## line:  multi-char delimiter from segment boundary
  is(scalar <$xh>, '09baABCD',	'read mcd line from segment boundary');
  note_handle_state $xh;
  ## line:  multi-char delimiter straddling boundary
  is(scalar <$xh>, 'dcfeghijABCD',
				'read mcd line straddling boundary');
  note_handle_state $xh;
  ## line:  multi-char delimiter at segment boundary
  is(scalar <$xh>, 'klmnABCD',	'read mcd line at segment boundary');
  note_handle_state $xh;
  ## line:  split multi-char delimiter straddling boundary
  is(scalar <$xh>, 'opqrABCD',
     'read mcd line with delimiter straddling boundary');
  note_handle_state $xh;
  ## line:  split multi-char delimiter with prefixes
  is(scalar <$xh>, 'stuvABABCABCD',
				'read mcd line split with prefixes');
  note_handle_state $xh;
  ## line:  split multi-char delimiter with false prefixes across segments
  is(scalar <$xh>, 'wxyzABCABEABABCD',
     'read mcd line split with false prefixes across segments');
  note_handle_state $xh;

  ## line:  multi-char delimiter to EOF without delimiter
  is(scalar <$xh>, '01234AB',	'read mcd line to eof without delimiter');
  note_handle_state $xh;
  ok((not defined scalar <$xh>),'read mcd line at eof');
  note_handle_state $xh;

  ## line:  multi-char delimiter containing own prefix
  $/ = '12a12a123';
  $xh = make_test_handle '012312a12a1234567', '89ab12a', '12a123',
    'cdefghij12a', '12aklmn12a12a123', 'opqr12a12a12a',
    '12a12a12astuv12a12a123wxyz';
  ##		... at start
  is(scalar <$xh>, '012312a12a123',
     'read mcdcop line at start');
  ##		... spanning segments with split delimiter
  is(scalar <$xh>, '456789ab12a12a123',
     'read mcdcop line spanning segments with split delimiter');
  ##		... with false prefix straddling segment boundary
  is(scalar <$xh>, 'cdefghij12a12aklmn12a12a123',
     'read mcdcop line with false prefix straddling segment boundary');
  ##		... with false prefix and data to delimiter
  is(scalar <$xh>, 'opqr12a12a12a12a12a12astuv12a12a123',
     'read mcdcop line with false prefix and data to delimiter');
  ##		... to EOF without delimiter
  is(scalar <$xh>, 'wxyz',	'read mcdcop line to eof without delimiter');
  ok((eof $xh),			'filehandle now at eof');
}

# Verify READLINE (mixed modes)
{
  my $xh;
  {
    local $/ = '';	# ensure that handle is usable in paragraph mode
    $xh = make_test_handle "abc\n";
  }
  is(scalar <$xh>, "abc\n",	'read line to eof');
  local $/ = '';	# select paragraph mode
  ok((not defined scalar <$xh>),'read paragraph at eof');

  $/ = \4;		# select record mode
  $xh = make_test_handle '1234';
  is(scalar <$xh>, '1234',	'read record to eof');
  $/ = "\n";		# select line mode
  ok((not defined scalar <$xh>),'read line at eof');

  $xh = make_test_handle "1234\n";
  is(scalar <$xh>, "1234\n",	'read line to eof for slurp');
  {
    local $/ = undef;	# select slurp mode
    ok((not defined scalar <$xh>),
				'slurp while at eof');
  }
}

note('*' x 60);

# Verify READ
{
  my $buf;

  my $xh = make_test_handle '01234567', '89abcde', 'fg', 'hi', 'jk', 'l',
    'mn', 'op', 'q', 'rst', 'uv';

  note_handle_state $xh;
  ## within segment
  is(read($xh, $buf, 4), 4,	'read within segment completes');
  is($buf, '0123',		'... and yields expected data');
  note_handle_state $xh;
  ## to segment boundary
  is(read($xh, $buf, 4), 4,	'read to segment boundary completes');
  is($buf, '4567',		'... and yields expected data');
  note_handle_state $xh;
  ## from segment boundary
  is(read($xh, $buf, 4), 4,	'read from segment boundary completes');
  is($buf, '89ab',		'... and yields expected data');
  note_handle_state $xh;
  ## straddling segment boundary
  is(read($xh, $buf, 4), 4,	'read straddling segment boundary completes');
  is($buf, 'cdef',		'... and yields expected data');
  note_handle_state $xh;
  ## spanning segments
  is(read($xh, $buf, 4), 4,	'read spanning segments completes');
  is($buf, 'ghij',		'... and yields expected data');
  note_handle_state $xh;
  ## spanning segments to segment boundary
  is(read($xh, $buf, 4), 4,
     'read spanning segments to segment boundary completes');
  is($buf, 'klmn',		'... and yields expected data');
  note_handle_state $xh;
  ## spanning segments from segment boundary
  is(read($xh, $buf, 4), 4,
     'read spanning segments from segment boundary completes');
  is($buf, 'opqr',		'... and yields expected data');
  note_handle_state $xh;
  ## to EOF
  is(read($xh, $buf, 4, 6), 4,	'read to eof completes');
  is($buf, "opqr\0\0stuv",	'... and yields expected data');
  note_handle_state $xh;
  ## at EOF
  is(read($xh, $buf, 4), 0,	'read at eof reads nothing');
  ok((eof $xh),			'handle still at eof after read at eof');
  note_handle_state $xh;
}

note('*' x 60);

# Verify GETC
{
  my $xh = make_test_handle "test ", "item\n";

  my @chars = ();
  my $ch;
  push @chars, $ch while defined ($ch = getc $xh);

  is(scalar @chars, 10,		'getc returns expected number of characters');
  is_deeply(\@chars, [qw/t e s t/, ' ', qw/i t e m/, "\n"],
				'getc returns expected data');
}

# EOF tested as part of other tests

note('*' x 60);

# Verify SEEK and TELL
{
  my $xh = make_test_handle "test ", "bits\n";

  is(tell $xh,  0,		'initial position');
  is(seek($xh, -2, SEEK_SET), 0,'seek to bogus position fails');
  is(tell $xh,  0,		'initial position unchanged');
  is(seek($xh,  2, SEEK_SET), 1,'seek to absolute position');
  is(tell $xh,  2,		'check absolute position');
  is(getc $xh, 's',		'verify data at absolute position');
  is(seek($xh,  1, SEEK_CUR), 1,'seek from current position');
  is(tell $xh,  4,		'confirm relative seek');
  is(getc $xh, ' ',		'verify data after relative seek');
  is(seek($xh, -4, SEEK_END), 1,'seek from end');
  is(tell $xh,  6,		'confirm seek from end');
  is(getc $xh, 'i',		'verify data after seek from end');
  is(seek($xh,  0, SEEK_END), 1,'seek to end');
  is(tell $xh, 10,		'confirm seek to end');
  ok((eof $xh),			'seek to end sets eof');
  note_handle_state $xh;

  {
    my $fail = 0;
    eval {seek($xh, 10, (SEEK_SET() + SEEK_CUR() + SEEK_END())); $fail = 1;};
    ok($fail == 0 && $@ =~ m/unknown WHENCE/,
				'invalid seek croaks');
  }
}
