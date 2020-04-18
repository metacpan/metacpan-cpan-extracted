# Unit tests for WARC::Record::Block module			# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use Test::More tests
  => 2	# loading tests
  +  4	# basic tests
  + 20	# verify READLINE
  + 17	# verify READ
  +  3	# verify GETC
  +  0  # EOF tested as part of other tests
  + 16	# verify SEEK and TELL
  +  2; # verify decompression handling
BEGIN { use_ok('WARC::Record::Block')
	  or BAIL_OUT "WARC::Record::Block failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Record::Block v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Record::Block version check')
}

use Fcntl qw/SEEK_SET SEEK_CUR SEEK_END/;
use Symbol 'geniosym';

use IO::Compress::Gzip qw/gzip $GzipError/;

{
  package WARC::Volume::_BlockTestMock;

  use Test::More;
  use IO::Uncompress::Gunzip '$GunzipError';

  sub open {
    my $self = shift;	# reference to parent object
    my $fh; my $data = $$self->{contents};
    open $fh, '<', \ $data
      or $fh = new IO::Uncompress::Gunzip (\ $data, Transparent => 1)
	or BAIL_OUT "cannot open string as file: $! $GunzipError";
    return $fh;
  }
}

{
  package WARC::Record::_BlockTestMock;

  sub _new { my $class = shift; bless {@_}, $class }

  sub volume { bless \ (shift), 'WARC::Volume::_BlockTestMock' }
  sub offset { (shift)->{offset} }

  sub field { my $self = shift; my $name = shift;
	      die "unexpected field name:  $name"
		unless $name eq 'Content-Length';
	      return $self->{length} }

  sub _get_compression_error { $IO::Uncompress::Gunzip::GunzipError }
}

sub make_test_handle (%) {
  my %opts = @_;

  my $mr = bless \%opts, 'WARC::Record::_BlockTestMock';
  my $xh = geniosym;
  tie *$xh, 'WARC::Record::Block', $mr;

  note('inner handle: ', ((tied *$xh)->[WARC::Record::Block::HANDLE]));
  return $xh;
}

sub note_handle_state ($) {
  my $xh = shift;
  note("handle state:  ", (tied *$xh)->_dbg_dump);
}

note('*' x 60);

# Basic tests
{
  my $xh = make_test_handle
    offset => 0, data_offset => 0, length => 10,
      contents => 'testdata12';

  isa_ok(tied *$xh, 'WARC::Record::Block', 'tied object behind handle');
  diag('tests run with base handle as:  ',
       ref ((tied *$xh)->[WARC::Record::Block::HANDLE]));
  ok((not eof $xh),		'tied handle initially not at eof');
  is(scalar <$xh>, 'testdata12','expected data read');
  ok((eof $xh),			'tied handle now at eof');

  close *$xh;
}

note('*' x 60);

# Verify READLINE
{
  my $xh = make_test_handle
    offset => 9, data_offset => 19, length => 10, contents => <<'EOT';
Previous
Foo: Bar

test item

Next
EOT

  ok((not eof $xh),		'tied handle initially not at eof');
  note_handle_state $xh;
  is(scalar <$xh>,"test item\n",'expected data from readline');
  note_handle_state $xh;
  ok((not defined scalar <$xh>),'next readline returns eof');
  note_handle_state $xh;
  ok((eof $xh),			'tied handle now at eof');

  # new handle, more tests
  $xh = make_test_handle
    offset => 9, data_offset => 19, length => 5, contents => <<'EOT';
Previous
Foo: Bar

test item

Next
EOT

  ok((not eof $xh),		'tied handle initially not at eof');
  note_handle_state $xh;
  is(scalar <$xh>, 'test ',	'expected data from readline');
  note_handle_state $xh;
  ok((not defined scalar <$xh>),'next readline returns eof');
  note_handle_state $xh;
  ok((eof $xh),			'tied handle now at eof');

  # new handle, more tests
  $xh = make_test_handle
    offset => 9, data_offset => 19, length => 10, contents => <<'EOT';
Previous
Foo: Bar

test
item

Next
EOT

  ok((not eof $xh),		'tied handle initially not at eof');
  note_handle_state $xh;
  is(scalar <$xh>, "test\n",	'expected data from readline (1)');
  note_handle_state $xh;
  is(scalar <$xh>, "item\n",	'expected data from readline (2)');
  note_handle_state $xh;
  ok((eof $xh),			'tied handle now at eof');

  # new handle, more tests
  $xh = make_test_handle
    offset => 9, data_offset => 19, length => 15, contents => <<'EOT';
Previous
Foo: Bar

test
long
item

Next
EOT

  ok((not eof $xh),		'tied handle initially not at eof');
  note_handle_state $xh;
  is(scalar <$xh>, "test\n",	'expected data from readline (1)');
  note_handle_state $xh;
  is_deeply([<$xh>], ["long\n", "item\n"],
				'expected data from readline (2)');
  note_handle_state $xh;
  ok((eof $xh),			'tied handle now at eof');

  # new handle, more tests
  $xh = make_test_handle
    offset => 9, data_offset => 19, length => 16, contents => <<'EOT';
Previous
Foo: Bar

off the end
EOT

  ok((not eof $xh),		'tied handle initially not at eof');
  note_handle_state $xh;
  is(scalar <$xh>, "off the end\n",
				'expected data from readline');
  note_handle_state $xh;
  ok((not defined scalar <$xh>),'next readline returns eof');
  note_handle_state $xh;
  ok((eof $xh),			'tied handle now at eof');
}

note('*' x 60);

# Verify READ
{
  my $xh = make_test_handle
    offset => 9, data_offset => 19, length => 10, contents => <<'EOT';
Previous
Foo: Bar

test item

Next
EOT

  ok((not eof $xh),		'tied handle initially not at eof');
  my $buf;
  note_handle_state $xh;
  is(read($xh, $buf, 16), 10,	'read entire block');
  is($buf, "test item\n",	'expected data from reading entire block');
  note_handle_state $xh;
  is(read($xh, $buf, 1), 0,	'next read returns eof');
  note_handle_state $xh;
  ok((eof $xh),			'tied handle now at eof');

  # new handle, more tests
  $xh = make_test_handle
    offset => 9, data_offset => 19, length => 10, contents => <<'EOT';
Previous
Foo: Bar

test item

Next
EOT

  note_handle_state $xh;
  is(read($xh, $buf, 4), 4,	'read partial');
  is($buf, 'test',		'expected data from partial read');
  note_handle_state $xh;
  is(read($xh, $buf, 12), 6,	'read hits eof');
  is($buf, " item\n",		'expected data from read to eof');
  note_handle_state $xh;
  ok((eof $xh),			'tied handle now at eof');

  # new handle, more tests
  $xh = make_test_handle
    offset => 9, data_offset => 19, length => 10, contents => <<'EOT';
Previous
Foo: Bar

test item

Next
EOT

  $buf = undef;
  note_handle_state $xh;
  is(read($xh, $buf, 4, 0), 4,	'first read with offset');
  note_handle_state $xh;
  my $ch;
  is(read($xh, $ch, 1), 1,	'read for discard');
  note_handle_state $xh;
  is(read($xh, $buf, 4, 5), 4,	'second read with offset');
  note_handle_state $xh;
  is($buf, "test\0item",	'reads produce expected buffer contents');
  is(read($xh, $buf, 1), 1,	'third read');
  note_handle_state $xh;
  is($buf, "\n",		'read trims buffer');
  ok((eof $xh),			'tied handle now at eof');
}

note('*' x 60);

# Verify GETC
{
  my $xh = make_test_handle
    offset => 9, data_offset => 19, length => 10, contents => <<'EOT';
Previous
Foo: Bar

test item

Next
EOT

  my @chars = ();
  my $ch;
  push @chars, $ch while defined ($ch = getc $xh);

  is(scalar @chars, 10,		'getc returns expected number of characters');
  is_deeply(\@chars, [qw/t e s t/, ' ', qw/i t e m/, "\n"],
				'getc returns expected data');
  ok((eof $xh),			'tied handle now at eof');
}

note('*' x 60);

# EOF tested as part of other tests

# Verify SEEK and TELL
{
  my $xh = make_test_handle
    offset => 9, data_offset => 19, length => 10, contents => <<'EOT';
Previous
Foo: Bar

test bits

Next
EOT

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

  {
    my $fail = 0;
    eval {seek($xh, 10, (SEEK_SET() + SEEK_CUR() + SEEK_END())); $fail = 1;};
    ok($fail == 0 && $@ =~ m/unknown WHENCE/,
				'invalid seek croaks');
  }
}

note('*' x 60);

# Verify decompression handling
{
  my $contents = <<'EOT';
Foo: Bar

test item

Next
EOT
  my $zcontents; gzip \$contents => \$zcontents or die "gzip $GzipError";
  $zcontents = "Previous\n".$zcontents;
  my $xh = make_test_handle offset => 9, data_offset => 10, length => 10,
    compression => 'IO::Uncompress::Gunzip', contents => $zcontents;

  my $buf;
  is(read($xh, $buf, 16), 10,	'read entire compressed block');
  is($buf, "test item\n",	'expected data from reading compressed block');
}
