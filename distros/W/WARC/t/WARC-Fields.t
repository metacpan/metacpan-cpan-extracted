# Unit tests for WARC::Fields module				# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use Test::More tests
  => 2	# loading tests
  + 13	# basic tests, invalid/empty
  + 22	# basic tests, useful
  + 14	# multiple values per key tests
  + 4	# constructor key merge tests
  + 14	# parsing tests
  + 37	# tied array tests
  + 56	# tied hash tests
  + 42	# array and hash dereference and interaction tests
  + 45	# read-only objects and clone method
  + 2	# internal dereference bug prevention tests
  + 1;	# cleanup test

# Note that the WARC record headers constructed during testing are not
#  necessarily valid and are merely chosen for convenience.

BEGIN { use_ok('WARC::Fields')
	  or BAIL_OUT("WARC::Fields failed to load") }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Fields v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Fields version check')
}

my $Have_MemFiles = 0;

eval { my $test = 'test';
       open my $fh, '<', \$test or die;
       die unless <$fh> eq 'test';
       $Have_MemFiles = 1;};

note('*' x 60);

# Basic tests on invalid and empty objects
{
  {
    my $fail = 0;
    eval {new WARC::Fields (WARC_Type => 'warcinfo',
			    BOGUS => undef); $fail = 1;};
    ok($fail == 0 && $@ =~ m/key without value/,
       'reject construction with missing value');

    $fail = 0;
    eval {new WARC::Fields (WARC_Type => 'warcinfo',
			    '::Bogus' => 1); $fail = 1;};
    ok($fail == 0 && $@ =~ m/invalid field name/,
       'reject construction with field name with actual leading colon');

    $fail = 0;
    eval {new WARC::Fields (WARC_Type => 'warcinfo',
			    ':Bogus:Field' => 1); $fail = 1;};
    ok($fail == 0 && $@ =~ m/invalid field name/,
       'reject construction with field name with embedded colon');

    $fail = 0;
    eval {new WARC::Fields (WARC_Type => 'warcinfo',
			    ':' => 1); $fail = 1;};
    ok($fail == 0 && $@ =~ m/field with no name/,
       'reject construction with empty exact field name');

    $fail = 0;
    eval {new WARC::Fields (WARC_Type => 'warcinfo',
			    '' => 1); $fail = 1;};
    ok($fail == 0 && $@ =~ m/field with no name/,
       'reject construction with empty field name');
  }

  my $f = WARC::Fields->new;

  isa_ok($f, 'WARC::Fields', 'an empty WARC::Fields object');

  is($f->as_string, '', 'dump empty WARC::Fields object');

  $f->field(Foo => 'bar');
  is($f->field('Foo'), 'bar', 'add simple field');

  {
    my $fail = 0;

    eval { $f->field('::Bogus'); $fail = 1;};
    ok($fail == 0 && $@ =~ m/invalid field name/,
       'reject field name with actual leading colon');

    $fail = 0;
    eval { $f->field(':Bogus:Field'); $fail = 1;};
    ok($fail == 0 && $@ =~ m/invalid field name/,
       'reject field name with embedded colon');

    $fail = 0;
    eval { $f->field(':'); $fail = 1;};
    ok($fail == 0 && $@ =~ m/field with no name/,
       'reject empty exact field name');

    $fail = 0;
    eval { $f->field(''); $fail = 1;};
    ok($fail == 0 && $@ =~ m/field with no name/,
       'reject empty field name');
  }

  is($f->as_string, <<'EOT', 'dump simple WARC::Fields object');
Foo: bar
EOT
}

note('*' x 60);

# Basic tests on useful objects
{
  my $f = new WARC::Fields (WARC_Type => 'warcinfo',
			    WARC_Record_ID => '<urn:test:record:1>',
			    Content_Type => 'application/warc-fields');

  isa_ok($f, 'WARC::Fields', 'a WARC::Fields object');

  my $e = <<'EOT';
WARC-Type: warcinfo
WARC-Record-ID: <urn:test:record:1>
Content-Type: application/warc-fields
EOT

  is($f->as_string, $e, 'construct and dump a WARC::Fields object');

  {
    my $o = $f->as_block;
    my $r = $e; $r =~ s/\n/\015\012/g;
    is($o, $r, 'verify standard form with network CRLF');
  }

  note("debugging table dump:\n", $f->_dbg_dump);

  ok((not defined $f->field('BOGUS-Not-There')),
     'non-existent field "has" undefined value');
  is($f->field('WARC-Type'), 'warcinfo', 'simple lookup');
  is($f->field('WaRc-TyPe'), 'warcinfo', 'case folding during lookup');
  is($f->field('WARC_Type'), 'warcinfo', 'convenience s/_/-/g during lookup');
  is($f->field('warc_TYPE'), 'warcinfo', 'both during lookup');

  $f->field(WARC_Filename => 'test-file.warc');

  is($f->field('WARC_Filename'), 'test-file.warc', 'add field');
  is($f->field(':WARC-Filename'), 'test-file.warc',
     'convenience s/_/-/g during add');
  ok((not defined $f->field(':WARC_Filename')),
     'original key not used with s/_/-/g');

  $f->field(':X-Crazy_Header' => 'what?');

  is($f->field(':X-Crazy_Header'), 'what?', 'add strange field');
  is($f->field('X-Crazy_Header'), 'what?',
     'exact match overrides convenience');

  $f->field('X-Crazy-Header' => 'this!');

  is($f->field(':X-Crazy-Header'), 'this!', 'add another field');
  is($f->field('X_Crazy_Header'), 'this!', 'convenience still works');
  is($f->field(':X-Crazy_Header'), 'what?', 'strange field still there');
  is($f->field('X-Crazy_Header'), 'what?',
     'exact match still overrides convenience');

  $f->field(X_Crazy_Header => undef);

  ok((not defined $f->field(':X-Crazy-Header')),
     'convenience works for undefining too');
  ok((not defined $f->field('X_Crazy_Header')),
     'convenience is all or nothing and ignores strange field');
  is($f->field('X-Crazy_Header'), 'what?', 'strange field not also removed');

  $f->field('X-Crazy_Header' => undef);

  ok((not defined $f->field(':X-Crazy_Header')),
     'exact match works for undefining strange field');

  $e = <<'EOT';
WARC-Type: warcinfo
WARC-Record-ID: <urn:test:record:1>
Content-Type: application/warc-fields
WARC-Filename: test-file.warc
EOT

  is($f->as_string, $e, 'dump modified WARC::Fields object');

  note("debugging table dump:\n", $f->_dbg_dump);
}

note('*' x 60);

# Multiple values for same key
{
  my $f = new WARC::Fields (Foo => [1, 2, 3],
			    Bar => 4,
			    Baz => 'quux',
			    Bar => [5, 6]);

  isa_ok($f, 'WARC::Fields', 'a WARC::Fields object with multiple values');

  my $e = <<'EOT';
Foo: 1
Foo: 2
Foo: 3
Bar: 4
Baz: quux
Bar: 5
Bar: 6
EOT

  is($f->as_string, $e, 'dump with multiple values for same key');

  note("debugging table dump:\n", $f->_dbg_dump);

  is_deeply($f->field('Foo'), [1, 2, 3], 'read field "Foo"');
  is_deeply($f->field('Bar'), [4, 5, 6], 'read field "Bar"');
  is($f->field('Baz'), 'quux', 'read field "Baz"');

  $f->field(Bar => [7, 8, 9]);
  is_deeply($f->field('Bar'), [7, 8, 9], 'replace value list (same length)');

  $f->field(Bar => 'baz');
  is($f->field('Bar'), 'baz', 'replace multiple values with single value');

  $f->field(bar => ['baz1', 'baz2']);	# note case-insensitive key match
  is_deeply($f->field('Bar'), ['baz1', 'baz2'],
	    'replace single value with multiple values');

  $f->field(foo => [1, 2, 3, 4, 5, 6]);	# note case-insensitive key match
  is_deeply($f->field('Foo'), [1 .. 6], 'extend value list');

  is($f->as_string, <<'EOT', 'dump after adjusting multiple values');
Foo: 1
Foo: 2
Foo: 3
Foo: 4
Foo: 5
Foo: 6
Bar: baz1
Bar: baz2
Baz: quux
EOT

  note("debugging table dump:\n", $f->_dbg_dump);

  $f->field(Foo => []);
  ok((not defined $f->field('Foo')), 'assigning empty array removes field');

  is($f->as_string, <<'EOT', 'dump after removing "Foo" entirely');
Bar: baz1
Bar: baz2
Baz: quux
EOT

  note("debugging table dump:\n", $f->_dbg_dump);

  $f->field(Quux => [10, 13]);
  is_deeply($f->field('Quux'), [10, 13], 'add field with multiple values');

  is($f->as_string, <<'EOT', 'dump after adding multiple value field');
Bar: baz1
Bar: baz2
Baz: quux
Quux: 10
Quux: 13
EOT

  note("debugging table dump:\n", $f->_dbg_dump);
}

# Merging keys during object construction
{
  my $f = new WARC::Fields (  Foo_Bar  => 1, Foo_Bar => 2,
			    ':Foo_Bar' => 3, Foo_Bar => 4,
			    ':foo_bar' => 5, foo_bar => 6);

  isa_ok($f, 'WARC::Fields', 'the object');

  is($f->as_string, <<'EOT', 'dump a WARC::Fields object with merged keys');
Foo-Bar: 1
Foo-Bar: 2
Foo_Bar: 3
Foo-Bar: 4
foo_bar: 5
foo-bar: 6
EOT

  note("debugging table dump:\n", $f->_dbg_dump);

  is_deeply($f->field('Foo-Bar'), [1, 2, 4, 6],	'read "Foo-Bar" values');
  is_deeply($f->field('Foo_Bar'), [3, 5],	'read "Foo_Bar" values');
}

note('*' x 60);

# Parsing tests
SKIP:
{
  unless ($Have_MemFiles) {
    diag "Could not use in-memory file; skipping parsing tests";
    skip "Parsing tests require support for in-memory files", 14;
  }

  {
    my $pass = 0;
    local $SIG{__WARN__} = sub { $pass = 1 if shift =~ m/before end marker/ };

    my $f = parse WARC::Fields <<'EOT';
EOT

    isa_ok($f, 'WARC::Fields', 'parsed empty WARC::Fields object');
    ok($pass, 'warning about lack of clear end');
    is($f->as_string, '', 'dump empty parsed object');
  }

  {
    my $fail = 0;
    eval {parse WARC::Fields "bogus line\n"; $fail = 1;};
    ok($fail == 0 && $@ =~ m/bogus line/, 'reject bad input (1)');

    $fail = 0;
    eval {parse WARC::Fields ":bogus line\n"; $fail = 1;};
    ok($fail == 0 && $@ =~ m/:bogus line/, 'reject bad input (2)');
  }

  my $f;
  {
    my $d = <<'EOT';
format: WARC File Format 1.0
conformsTo: http://bibnum.bnf.fr/WARC/WARC_ISO_28500_version1_latestdraft.pdf

following data line
EOT
    $d =~ s/\n/\015\012/g;
    open my $dfh, '<', \$d or die "open: $!";
    $f = parse WARC::Fields from => $dfh;

    my $tail = <$dfh>; $tail =~ s/[\015\012]+$//;
    is($tail, 'following data line',
       'stream correctly positioned after parse');
  }

  isa_ok($f, 'WARC::Fields', 'parsed sample WARC::Fields object');

  is($f->as_string, <<'EOT', 'dump sample object');
format: WARC File Format 1.0
conformsTo: http://bibnum.bnf.fr/WARC/WARC_ISO_28500_version1_latestdraft.pdf
EOT

  note("debugging table dump:\n", $f->_dbg_dump);

  is($f->field('format'), 'WARC File Format 1.0', 'read "format" field');
  is($f->field('conformsTo'),
     'http://bibnum.bnf.fr/WARC/WARC_ISO_28500_version1_latestdraft.pdf',
     'read "conformsTo" field');

  $f = parse WARC::Fields <<'EOT';
fooBar: baz
	    quux
Quux: 1

EOT

  isa_ok($f, 'WARC::Fields', 'parsed sample object with wrapped lines');

  is($f->as_string, <<'EOT', 'dump sample object with lines collected');
fooBar: baz quux
Quux: 1
EOT

  note("debugging table dump:\n", $f->_dbg_dump);

  $f = parse WARC::Fields <<'EOT';
Foo: 1
:bar: 2
Baz:   3

EOT

  isa_ok($f, 'WARC::Fields', 'parsed sample object with oddities');

  is($f->as_string, <<'EOT', 'dump sample object normalized');
Foo: 1
bar: 2
Baz: 3
EOT

  note("debugging table dump:\n", $f->_dbg_dump);
}

note('*' x 60);

# Tied array interface
{
  my $f = new WARC::Fields (WARC_Type => 'warcinfo',
			    WARC_Record_ID => '<urn:test:record:2>',
			    Content_Type => 'application/warc-fields',
			    WARC_Filename => 'test-file.warc',
			    ':X-Crazy_Header' => 'what?',
			    ':X-Crazy-Header' => 'this!');

  my @f_a; tie @f_a, ref $f, $f;

  isa_ok($f, 'WARC::Fields', 'test object for tied array');
  isa_ok(tied @f_a, 'WARC::Fields::TiedArray', 'tied array object');

  is(scalar @f_a, 6,	'tied array length');
  is($#f_a, 5,		'tied array highest index');

  subtest 'tied array contents' => sub {
    plan tests => 30;

    ok((exists $f_a[0]),		'row 0 exists');
    is($f_a[0], 'WARC-Type',		'row 0 implicit name');
    is($f_a[0]->name, 'WARC-Type',	'row 0 explicit name');
    is($f_a[0]->value, 'warcinfo',	'row 0 value');
    ok((not defined $f_a[0]->offset),	'row 0 offset');

    ok((exists $f_a[1]),		'row 1 exists');
    is($f_a[1], 'WARC-Record-ID',	'row 1 implicit name');
    is($f_a[1]->name, 'WARC-Record-ID',	'row 1 explicit name');
    is($f_a[1]->value,
       '<urn:test:record:2>',		'row 1 value');
    ok((not defined $f_a[1]->offset),	'row 1 offset');

    ok((exists $f_a[2]),		'row 2 exists');
    is($f_a[2], 'Content-Type',		'row 2 implicit name');
    is($f_a[2]->name, 'Content-Type',	'row 2 explicit name');
    is($f_a[2]->value,
       'application/warc-fields',	'row 2 value');
    ok((not defined $f_a[2]->offset),	'row 2 offset');

    ok((exists $f_a[3]),		'row 3 exists');
    is($f_a[3], 'WARC-Filename',	'row 3 implicit name');
    is($f_a[3]->name, 'WARC-Filename',	'row 3 explicit name');
    is($f_a[3]->value, 'test-file.warc','row 3 value');
    ok((not defined $f_a[3]->offset),	'row 3 offset');

    ok((exists $f_a[4]),		'row 4 exists');
    is($f_a[4], 'X-Crazy_Header',	'row 4 implicit name');
    is($f_a[4]->name, 'X-Crazy_Header',	'row 4 explicit name');
    is($f_a[4]->value, 'what?',		'row 4 value');
    ok((not defined $f_a[4]->offset),	'row 4 offset');

    ok((exists $f_a[5]),		'row 5 exists');
    is($f_a[5], 'X-Crazy-Header',	'row 5 implicit name');
    is($f_a[5]->name, 'X-Crazy-Header',	'row 5 explicit name');
    is($f_a[5]->value, 'this!',		'row 5 value');
    ok((not defined $f_a[5]->offset),	'row 5 offset');
  };

  note("debugging table dump:\n", $f->_dbg_dump);

  delete $f_a[4];
  ok((not exists $f_a[4]),	'delete row from tied array');

  note("debugging table dump:\n", $f->_dbg_dump);

  $#f_a = 3;
  is(scalar @f_a, 4,		'reduce size of tied array');

  note("debugging table dump:\n", $f->_dbg_dump);

  $#f_a = 4;
  is(scalar @f_a, 5,		'extend tied array');
  ok((not exists $f_a[4]),	'empty new element does not exist');

  note("debugging table dump:\n", $f->_dbg_dump);

  $f_a[4] = 'X_Foo';
  subtest 'setting name on empty slot does not create a value' => sub {
    plan tests => 2;

    is($f_a[4], 'X_Foo',	'empty slot name was set');
    ok((not exists $f_a[4]),	'empty slot still does not exist');
  };

  note("debugging table dump:\n", $f->_dbg_dump);

  $f->field(X_Foo => 'test');
  is($f_a[4]->value, 'test',	'set value for new slot');
  ok((exists $f_a[4]),		'slot now exists');

  note("debugging table dump:\n", $f->_dbg_dump);

  $f->field(X_Foo => ['test-1', 'test-2']);

  note("debugging table dump:\n", $f->_dbg_dump);

  subtest 'setting multiple values extends table' => sub {
    plan tests => 6;

    is($f_a[4], 'X_Foo',	'row 4 with new field');
    is($f_a[5], 'X_Foo',	'row 5 with new field');
    is($f_a[4]->value, 'test-1','row 4 value');
    is($f_a[5]->value, 'test-2','row 5 value');
    is($f_a[4]->offset, 0,	'row 4 offset');
    is($f_a[5]->offset, 1,	'row 5 offset');
  };

  $f_a[4]->value('test-a');
  $f_a[5]->value('test-b');

  is_deeply($f->field('X_Foo'), ['test-a', 'test-b'],
	    'update values via tied array');

  $f_a[6] = 'X_Foo';
  $f_a[6]->value('test-c');

  is_deeply($f->field('X_Foo'), ['test-a', 'test-b', 'test-c'],
	    'add value via tied array');

  note("debugging table dump:\n", $f->_dbg_dump);

  $f_a[4] = $f_a[5];
  is($f_a[4]->value, 'test-b',	'copy entry');

  {
    my $fail = 0;

    eval {$f_a[5] = []; $fail = 1;};
    ok($fail == 0 && $@ =~ m/set invalid name/,	'reject setting bogus name');

    $fail = 0;
    eval {$f_a[5] = ':Bogus-Here'; $fail = 1;};
    ok($fail == 0 && $@ =~ m/set invalid name/,
       'reject leading colon in tied array');

    my $fake_entry =
      WARC::Fields::TiedArray::LooseEntry->_new(':Bogus-Name', 'value');

    $fail = 0;
    eval {$f_a[5] = $fake_entry; $fail = 1;};
    ok($fail == 0 && $@ =~ m/set invalid name/,
       'catch attempt to smuggle invalid name in entry object');

    $fail = 0;
    eval {push @f_a, ':Bogus-Here'; $fail = 1;};
    ok($fail == 0 && $@ =~ m/set invalid name/,
       'reject pushing invalid name onto tied array (direct)');
    $fail = 0;
    eval {push @f_a, $fake_entry; $fail = 1;};
    ok($fail == 0 && $@ =~ m/set invalid name/,
       'reject pushing invalid name onto tied array (entry object)');

    $fail = 0;
    eval {unshift @f_a, ':Bogus-Here'; $fail = 1;};
    ok($fail == 0 && $@ =~ m/set invalid name/,
       'reject unshifting invalid name into tied array (direct)');
    $fail = 0;
    eval {unshift @f_a, $fake_entry; $fail = 1;};
    ok($fail == 0 && $@ =~ m/set invalid name/,
       'reject unshifting invalid name into tied array (entry object)');

    $fail = 0;
    eval {splice @f_a, 3, 0, ':Bogus-Here'; $fail = 1;};
    ok($fail == 0 && $@ =~ m/set invalid name/,
       'reject splicing invalid name into tied array (direct)');
    $fail = 0;
    eval {splice @f_a, 3, 0, $fake_entry; $fail = 1;};
    ok($fail == 0 && $@ =~ m/set invalid name/,
       'reject splicing invalid name into tied array (entry object)');

  }

  note("debugging table dump:\n", $f->_dbg_dump);

  subtest 'pop row' => sub {
    plan tests => 6;

    is(scalar @f_a, 7,	'check length before pop');
    my $item = pop @f_a;

    isa_ok($item, 'WARC::Fields::TiedArray::LooseEntry', 'popped row');

    is($item->name, 'X_Foo',		'popped row name');
    is($item->value, 'test-c',		'popped row value');
    ok((not defined $item->offset),	'popped row has no offset');

    is(scalar @f_a, 6,	'check length after pop');
  };

  {
    is($f_a[5]->offset, 1,		'expected offset in remaining rows');

    my $item = pop @f_a;

    my $fail = 0;
    eval {$item->value('bogus'); $fail = 1;};
    ok($fail == 0 && $@ =~ m/read-only/,'loose entries are read-only');
  }

  note("debugging table dump:\n", $f->_dbg_dump);

  subtest 'roll down' => sub {
    plan tests => 8;

    is(scalar @f_a, 5,	'check length before roll');

    is($f_a[0], 'WARC-Type',	'row 0 name before roll');
    is($f_a[3], 'WARC-Filename','row 3 name before roll');
    is($f_a[4], 'X_Foo',	'row 4 name before roll');

    unshift @f_a, pop @f_a;	# roll

    is(scalar @f_a, 5,	'check length after roll');

    is($f_a[0], 'X_Foo',	'row 0 name after roll');
    is($f_a[1], 'WARC-Type',	'row 1 name after roll');
    is($f_a[4], 'WARC-Filename','row 4 name after roll');
  };

  note("debugging table dump:\n", $f->_dbg_dump);

  subtest 'roll up' => sub {
    plan tests => 8;

    is(scalar @f_a, 5,	'check length before roll');

    is($f_a[0], 'X_Foo',	'row 0 name before roll');
    is($f_a[1], 'WARC-Type',	'row 3 name before roll');
    is($f_a[4], 'WARC-Filename','row 4 name before roll');

    push @f_a, shift @f_a;	# roll

    is(scalar @f_a, 5,	'check length after roll');

    is($f_a[0], 'WARC-Type',	'row 0 name after roll');
    is($f_a[3], 'WARC-Filename','row 1 name after roll');
    is($f_a[4], 'X_Foo',	'row 4 name after roll');
  };

  note("debugging table dump:\n", $f->_dbg_dump);

  is(pop @f_a, 'X_Foo',	'pop remaining "X_Foo"');
  is(scalar @f_a, 4,	'check length after pop');

  push @f_a, 'X-Bar'; $f_a[$#f_a]->value('test-bar');
  unshift @f_a, 'X-Baz'; $f_a[0]->value('test-baz');

  subtest 'added rows' => sub {
    plan tests => 8;

    is($f_a[0], 'X-Baz',	'row 0 name');
    is($f_a[1], 'WARC-Type',	'row 1 name');
    is($f_a[4], 'WARC-Filename','row 4 name');
    is($f_a[5], 'X-Bar',	'row 5 name');

    is($f_a[0]->value, 'test-baz',	'row 0 value');
    is($f_a[1]->value, 'warcinfo',	'row 1 value');
    is($f_a[4]->value, 'test-file.warc','row 4 value');
    is($f_a[5]->value, 'test-bar',	'row 5 value');
  };

  note("debugging table dump:\n", $f->_dbg_dump);

  splice @f_a, 0, undef, ('X-Quux', (splice @f_a, 1, 4), 'X-Quux');

  subtest 'tied array contents after splice' => sub {
    plan tests => 12;

    is($f_a[0], 'X-Quux',				'row 0 name');
    ok((not defined $f_a[0]->value),			'row 0 value');

    is($f_a[1], 'WARC-Type',				'row 1 name');
    is($f_a[1]->value, 'warcinfo',			'row 1 value');

    is($f_a[2], 'WARC-Record-ID',			'row 2 name');
    is($f_a[2]->value, '<urn:test:record:2>',		'row 2 value');

    is($f_a[3], 'Content-Type',				'row 3 name');
    is($f_a[3]->value, 'application/warc-fields',	'row 3 value');

    is($f_a[4], 'WARC-Filename',			'row 4 name');
    is($f_a[4]->value, 'test-file.warc',		'row 4 value');

    is($f_a[5], 'X-Quux',				'row 5 name');
    ok((not defined $f_a[5]->value),			'row 5 value');
  };

  note("debugging table dump:\n", $f->_dbg_dump);

  $f_a[0]->value('One'); $f_a[5]->value('Two');

  splice @f_a, 0, (scalar @f_a), splice @f_a;

  note("debugging table dump:\n", $f->_dbg_dump);

  is($f->as_string, <<'EOT', 'dump record after setting values and no-op splice');
X-Quux: One
WARC-Type: warcinfo
WARC-Record-ID: <urn:test:record:2>
Content-Type: application/warc-fields
WARC-Filename: test-file.warc
X-Quux: Two
EOT

  is(scalar @f_a, 6,	'tied array has 6 elements again');
  @f_a = ();
  is(scalar @f_a, 0,	'tied array now empty');

  untie @f_a;
}

note('*' x 60);

# Tied hash interface
{
  my $f = new WARC::Fields (Foo_Bar => [qw/Baz-1 Baz-2 Baz-3/]);

  my %f_h; tie %f_h, ref $f, $f;

  isa_ok($f, 'WARC::Fields', 'test object for tied hash');
  isa_ok(tied %f_h, 'WARC::Fields::TiedHash', 'tied hash object');

  note("debugging table dump:\n", $f->_dbg_dump);

  ok((not exists $f_h{':Foo_Bar'}),	'exact key "Foo_Bar" does not exist');
  ok((exists $f_h{':Foo-Bar'}),		'exact key "Foo-Bar" exists');

  is_deeply([@{$f_h{Foo_Bar}}], [qw/Baz-1 Baz-2 Baz-3/],
	    'read "Foo-Bar" key as "Foo_Bar"');

  is($#{$f_h{Foo_Bar}}, 2,	'length of value array for key "Foo-Bar"');
  is(scalar @{$f_h{Foo_Bar}}, 3,'element count of same value array');

  ok((exists $f_h{Foo_Bar}[0]),	'value 0 for key "Foo-Bar" exists');
  ok((exists $f_h{Foo_Bar}[1]),	'value 1 for key "Foo-Bar" exists');
  ok((exists $f_h{Foo_Bar}[2]),	'value 2 for key "Foo-Bar" exists');
  ok((not exists $f_h{Foo_Bar}[3]),
     'value 3 for key "Foo-Bar" does not exist');

  is($f_h{'Foo-Bar'}[0], 'Baz-1', 'value 0 for key "Foo-Bar"');
  is($f_h{'Foo-Bar'}[1], 'Baz-2', 'value 1 for key "Foo-Bar"');
  is($f_h{'Foo-Bar'}[2], 'Baz-3', 'value 2 for key "Foo-Bar"');

  like($f_h{'Foo-Bar'}, qr/ARRAY/, 'multiple value array acts as array');

  $f_h{Baz} = $f_h{Foo_Bar};

  note("debugging table dump:\n", $f->_dbg_dump);

  is_deeply([@{$f_h{Baz}}], [qw/Baz-1 Baz-2 Baz-3/],
	    'values copied from "Foo-Bar" key to "Baz" key');

  $f_h{Foo_Bar} = [qw/foo bar/];
  is_deeply([@{$f_h{Foo_Bar}}], [qw/foo bar/],
	    'values replaced for "Foo-Bar" key');

  $#{$f_h{Foo_Bar}} = 0;
  is_deeply([@{$f_h{Foo_Bar}}], [qw/foo/],
	    'value list length reduced for "Foo-Bar" key');

  note("debugging table dump:\n", $f->_dbg_dump);

  $f_h{Baz} = 'Quux';
  is($f_h{Baz}, 'Quux', 'value replaced for "Baz" key');

  {
    my $fail = 0;

    eval {defined $f_h{':Bogus:Key'} or $fail = 1; $fail = 1;};
    ok($fail == 0 && $@ =~ m/invalid field name/,
       'reject attempt to read an invalid field name');

    $fail = 0;
    eval {$f_h{':Bogus:Key'} = 1; $fail = 1;};
    ok($fail == 0 && $@ =~ m/invalid field name/,
      'reject attempt to set value for invalid field name');

    $fail = 0;
    eval {push @{$f_h{':Bogus:Key'}}, 1; $fail = 1;};
    ok($fail == 0 && $@ =~ m/invalid field name/,
      'reject attempt to push value for invalid field name');

    $fail = 0;
    eval {unshift @{$f_h{':Bogus:Key'}}, 1; $fail = 1;};
    ok($fail == 0 && $@ =~ m/invalid field name/,
      'reject attempt to unshift value for invalid field name');
  }

  note("debugging table dump:\n", $f->_dbg_dump);

  is_deeply([keys %f_h], [qw/Foo-Bar Baz/], 'check key list');

  ok((exists $f_h{Baz}),	'key "Baz" exists');
  delete $f_h{Baz};
  ok((not exists $f_h{Baz}),	'key "Baz" deleted');

  note("debugging table dump:\n", $f->_dbg_dump);

  ok((scalar %f_h),	'tied hash has contents');
  %f_h = ();
  ok((not scalar %f_h),	'tied hash now empty');

  $f_h{Foo}[1] = 'One';
  $f_h{Foo}[3] = 'Three';
  $f_h{Foo}[2] = 'Two';
  $f_h{Foo}[0] = 'Zero';

  note("debugging table dump:\n", $f->_dbg_dump);

  is_deeply($f->field('Foo'), [qw/Zero One Two Three/],
	    'set "Foo" values shuffled');

  delete $f_h{Foo}[3]; delete $f_h{Foo}[1];

  note("debugging table dump:\n", $f->_dbg_dump);

  is_deeply($f->field('Foo'), [qw/Zero Two/],
	    'delete some "Foo" values');

  push @{$f_h{Bar}}, qw/A B C/;

  is_deeply($f->field('Bar'), [qw/A B C/], 'push new field values');

  push @{$f_h{Foo}}, 'Five';

  is_deeply($f->field('Foo'), [qw/Zero Two Five/], 'push new value');

  note("debugging table dump:\n", $f->_dbg_dump);

  is($f->as_string, <<'EOT', 'dump table');
Foo: Zero
Foo: Two
Foo: Five
Bar: A
Bar: B
Bar: C
EOT

  $f_h{$_} = $f->field($_) for keys %f_h;

  is($f->as_string, <<'EOT', 'dump table after tidying');
Foo: Zero
Foo: Two
Foo: Five
Bar: A
Bar: B
Bar: C
EOT

  note("debugging table dump:\n", $f->_dbg_dump);

  @{$f_h{Foo}} = ();

  is($f->as_string, <<'EOT', 'dump table after clearing "Foo" values');
Bar: A
Bar: B
Bar: C
EOT

  note("debugging table dump:\n", $f->_dbg_dump);

  is(pop @{$f_h{Bar}}, 'C',	'pop value from "Bar" field');
  is(shift @{$f_h{Bar}}, 'A',	'shift value from "Bar" field');

  note("debugging table dump:\n", $f->_dbg_dump);

  is($f->field('Bar'), 'B',	'remaining value of "Bar" field');

  unshift @{$f_h{Quux}}, 0 .. 3;
  is_deeply($f->field('Quux'), [0 .. 3], 'unshift value into "Quux" field');

  push @{$f_h{Bar}}, 'D';
  is_deeply($f->field('Bar'), [qw/B D/], 'push value onto "Bar" field');

  unshift @{$f_h{Bar}}, 'E';
  is_deeply($f->field('Bar'), [qw/E B D/], 'unshift value onto "Bar" field');

  push @{$f_h{Baz}}, qw/pop shift/; shift @{$f_h{Baz}};
  is(shift @{$f_h{Baz}}, 'shift', 'shift "Baz" away');

  push @{$f_h{Baz}}, qw/pop shift/; pop @{$f_h{Baz}};
  is(pop @{$f_h{Baz}}, 'pop', 'pop "Baz" away');

  note("debugging table dump:\n", $f->_dbg_dump);

  ok((not defined pop @{$f_h{Baz}}),
     'pop returns undef on non-existent key');
  ok((not defined shift @{$f_h{Baz}}),
     'shift returns undef on non-existent key');

  is($f->as_string, <<'EOT', 'dump table after pop/shift/push/unshift');
Bar: E
Bar: B
Bar: D
Quux: 0
Quux: 1
Quux: 2
Quux: 3
EOT

  is_deeply([splice @{$f_h{Bar}}, 1], [qw/B D/],
	    'splice suffix from "Bar" value');
  is($f->field('Bar'), 'E', 'check "Bar" value after splice');

  is_deeply([splice @{$f_h{Quux}}, 1, 2, 4, 5], [1, 2],
	    'splice middle entries on "Quux" value');
  is_deeply($f->field('Quux'), [0, 4, 5, 3],
	    'check "Quux" value after splice');

  is_deeply([splice @{$f_h{Quux}}, 0, 3], [0, 4, 5],
	    'splice prefix from "Quux" value');
  is($f->field('Quux'), 3, 'check "Quux" value after splice');

  note("debugging table dump:\n", $f->_dbg_dump);

  is_deeply([splice @{$f_h{Quux}}], [3], 'splice "Quux" away entirely');

  $#{$f_h{Bar}}++;
  note("debugging table dump:\n", $f->_dbg_dump);
  $f_h{Bar}[-1] = 'F';

  is_deeply($f->field('Bar'), [qw/E F/],
	    'add value after extending "Bar" field');

  is_deeply([splice @{$f_h{Quux}}, 0, 0, 6], [], 'splice "Quux" back');

  note("debugging table dump:\n", $f->_dbg_dump);

  is($f->as_string, <<'EOT', 'dump table after adding value');
Bar: E
Bar: F
Quux: 6
EOT

  untie %f_h;
}

note('*' x 60);

# Overloaded array and hash dereferences and interactions between them
{
  my $f = new WARC::Fields (WARC_Type => 'warcinfo',
			    WARC_Record_ID => '<urn:test:record:3>',
			    Content_Type => 'application/warc-fields',
			    WARC_Filename => 'test-file.warc');

  note("debugging table dump:\n", $f->_dbg_dump);

  is(scalar @{$f}, 4,	'number of rows in implicit array');
  is($#{$f}, 3,		'highest index in implicit array');

  subtest 'implicit array contents' => sub {
    plan tests => 20;

    ok((exists $f->[0]),		'row 0 exists');
    is($f->[0], 'WARC-Type',		'row 0 implicit name');
    is($f->[0]->name, 'WARC-Type',	'row 0 explicit name');
    is($f->[0]->value, 'warcinfo',	'row 0 value');
    ok((not defined $f->[0]->offset),	'row 0 offset');

    ok((exists $f->[1]),		'row 1 exists');
    is($f->[1], 'WARC-Record-ID',	'row 1 implicit name');
    is($f->[1]->name, 'WARC-Record-ID',	'row 1 explicit name');
    is($f->[1]->value,
       '<urn:test:record:3>',		'row 1 value');
    ok((not defined $f->[1]->offset),	'row 1 offset');

    ok((exists $f->[2]),		'row 2 exists');
    is($f->[2], 'Content-Type',		'row 2 implicit name');
    is($f->[2]->name, 'Content-Type',	'row 2 explicit name');
    is($f->[2]->value,
       'application/warc-fields',	'row 2 value');
    ok((not defined $f->[2]->offset),	'row 2 offset');

    ok((exists $f->[3]),		'row 3 exists');
    is($f->[3], 'WARC-Filename',	'row 3 implicit name');
    is($f->[3]->name, 'WARC-Filename',	'row 3 explicit name');
    is($f->[3]->value, 'test-file.warc','row 3 value');
    ok((not defined $f->[3]->offset),	'row 3 offset');
  };

  is_deeply([keys %{$f}],
	    [qw/WARC-Type WARC-Record-ID Content-Type WARC-Filename/],
	    'implicit hash keys in order');

  subtest 'implicit hash contents' => sub {
    plan tests => 16;

    ok((exists $f->{'WARC-Type'}),
       'key "WARC-Type" exists');
    ok((exists $f->{WARC_Type}),
       'key "WARC-Type" exists via convenience');
    is(scalar @{$f->{'WARC-Type'}}, 1,
       'key "WARC-Type" has 1 value');
    is($f->{'WARC-Type'}, 'warcinfo',
       'key "WARC-Type" has correct value');

    ok((exists $f->{'WARC-Record-ID'}),
       'key "WARC-Record-ID" exists');
    ok((exists $f->{WARC_Record_ID}),
       'key "WARC-Record-ID" exists via convenience');
    is(scalar @{$f->{'WARC-Record-ID'}}, 1,
       'key "WARC-Record-ID" has 1 value');
    is($f->{'WARC-Record-ID'}, '<urn:test:record:3>',
       'key "WARC-Record-ID" has correct value');

    ok((exists $f->{'Content-Type'}),
       'key "Content-Type" exists');
    ok((exists $f->{Content_Type}),
       'key "Content-Type" exists via convenience');
    is(scalar @{$f->{'Content-Type'}}, 1,
       'key "Content-Type" has 1 value');
    is($f->{'Content-Type'}, 'application/warc-fields',
       'key "Content-Type" has correct value');

    ok((exists $f->{'WARC-Filename'}),
       'key "WARC-Filename" exists');
    ok((exists $f->{WARC_Filename}),
       'key "WARC-Filename" exists via convenience');
    is(scalar @{$f->{'WARC-Filename'}}, 1,
       'key "WARC-Filename" has 1 value');
    is($f->{'WARC-Filename'}, 'test-file.warc',
       'key "WARC-Filename" has correct value');
  };

  push @{$f->{WARC_Concurrent_To}},
    '<urn:test:record:1>', '<urn:test:record:2>';

  note("debugging table dump:\n", $f->_dbg_dump);

  is(scalar @{$f}, 6,	'two rows added');
  is_deeply($f->field('WARC-Concurrent-To'),
	    ['<urn:test:record:1>', '<urn:test:record:2>'],
	    'new key added with two values');
  is_deeply([keys %{$f}],
	    [qw/WARC-Type WARC-Record-ID Content-Type
		WARC-Filename WARC-Concurrent-To/],
	    'implicit hash keys in order with new key');
  note("debugging table dump:\n", $f->_dbg_dump);

  @{$f->{WARC_Concurrent_To}}[1,0] = @{$f->{WARC_Concurrent_To}};
  note("debugging table dump:\n", $f->_dbg_dump);
  is_deeply($f->field('WARC-Concurrent-To'),
	    ['<urn:test:record:2>', '<urn:test:record:1>'],
	    'exchange values for new key');

  @{$f}[5,4] = @{$f}[4,5];
  note("debugging table dump:\n", $f->_dbg_dump);
  is_deeply($f->field('WARC-Concurrent-To'),
	    ['<urn:test:record:1>', '<urn:test:record:2>'],
	    'exchange values for new key again');

  @{$f}[2,3,4,5] = @{$f}[4,5,3,2];
  note("debugging table dump:\n", $f->_dbg_dump);
  is_deeply([keys %{$f}],
	    [qw/WARC-Type WARC-Record-ID WARC-Concurrent-To
		WARC-Filename Content-Type/],
	    'rearrange keys');

  push @{$f->{WARC_Concurrent_To}}, '<urn:test:record:4>';
  # need at least 3 values for code coverage rebuilding offset column

  note("debugging table dump:\n", $f->_dbg_dump);

  is_deeply([@{$f}[2,3,4]], [('WARC-Concurrent-To') x 3],
	    'three rows for key "WARC-Concurrent-To" in expected location');
  is_deeply($f->field('WARC-Concurrent-To'),
	    [map {"<urn:test:record:$_>"} 1,2,4],
	    'three values for key "WARC-Concurrent-To"');
  is_deeply([map {$_->value} @{$f}[2,3,4]],
	    [map {"<urn:test:record:$_>"} 1,2,4],
	    'three values for key "WARC-Concurrent-To" in expected location');
  is_deeply([map {$_->offset} @{$f}[2,3,4]], [0,1,2],
	    'offsets for values for key "WARC-Concurrent-To" as expected');
  is((grep {defined $_->offset} @{$f}[0,1,5,6]), 0, 'other keys are unique');

  note("debugging table dump:\n", $f->_dbg_dump);

  is(pop @{$f->{WARC_Concurrent_To}}, '<urn:test:record:4>',
     'pop value from implicit hash value array');

  splice @{$f}, 0, undef, qw/Foo Bar Baz/;
  is($f->as_string, '',		'object logically empty with no values');

  $f->[0]->value('1'); $f->[1]->value('2'); $f->[2]->value('3');
  is($f->as_string, <<'EOT',	'object now has data');
Foo: 1
Bar: 2
Baz: 3
EOT

  # This violates encapsulation, but is likely to be more reliable than
  #  depending on side-effects from other operations that could be later
  #  improved to update the cached INDEX rather than destroying it.
  my $kill_INDEX = sub { ${+shift}->[WARC::Fields::INDEX] = undef };

  &$kill_INDEX($f);
  is($f->field('Foo'), 1,	'read "Foo" with no index');
  &$kill_INDEX($f);
  is($f->{Bar}, 2,		'read "Bar" with no index');
  &$kill_INDEX($f);
  ok((exists $f->{Baz}),	'check existence with no index');
  &$kill_INDEX($f);
  $f->{Foo} = 4;
  is($f->field('Foo'), 4,	'update "Foo" with no index');
  &$kill_INDEX($f);
  is_deeply([keys %{$f}], [qw/Foo Bar Baz/],
				'enumerate keys with no index');
  &$kill_INDEX($f);
  delete $f->{Foo};
  ok((not exists $f->{Foo}),	'remove "Foo" with no index');
  &$kill_INDEX($f);
  ok(scalar %{$f},		'hash still has contents with no index');

  { # These tests involve holding an entry while manipulating the table,
    #  which is not guranteed to produce expected results in general.
    my $item = $f->{Baz};

    &$kill_INDEX($f);
    is($item, 3,		'read "Baz" from value with no index');
    &$kill_INDEX($f);
    is($item->[0], 3,		'read value 0 of "Baz" with no index');
    &$kill_INDEX($f);
    $item->[0] = 5;
    is($f->field('Baz'), 5,	'update "Baz" via value with no index');
    &$kill_INDEX($f);
    is($#{$item}, 0,		'read value count via value with no index');
    &$kill_INDEX($f);
    $#{$item} = 1;
    is($#{$item}, 1,		'extend value array with no index');
    &$kill_INDEX($f);
    $item->[$#{$item}] = 6;
    is($item->[1], 6,		'add value via value array with no index');
    &$kill_INDEX($f);
    is(delete $item->[1], 6,	'remove value via value array with no index');
    &$kill_INDEX($f);
    $#{$item} = 0;
    is($#{$item}, 0,		'reduce value array with no index');

    &$kill_INDEX($f);
    ok((exists $item->[0]),	'value still exists with no index');
    &$kill_INDEX($f);
    ok((not defined $item->[1]),
       'value beyond array still undefined with no index');

    &$kill_INDEX($f);
    push @{$item}, 7;
    is($item->[1], 7,		'push value onto value array with no index');
    &$kill_INDEX($f);
    is(pop @{$item}, 7,		'pop value from value array with no index');

    &$kill_INDEX($f);
    unshift @{$item}, 8;
    is($item->[0], 8,		'unshift value into value array with no index');
    &$kill_INDEX($f);
    is(shift @{$item}, 8,	'shift value from value array with no index');

    &$kill_INDEX($f);
    is_deeply([splice @{$item}, 0, 1], [5],
	      'splice remaining value from value array with no index');
  }

  ok((not exists $f->{Baz}),	'key "Baz" removed along with last value');

  note("debugging table dump:\n", $f->_dbg_dump);
}

note('*' x 60);

# Read-only and cloned objects
{
  my $f = new WARC::Fields (WARC_Type => 'warcinfo',
			    WARC_Record_ID => '<urn:test:record:4>',
			    Content_Type => 'application/warc-fields',
			    WARC_Filename => 'test-file.warc');

  $f->set_readonly;

  my $fail = 0;
  eval {$f->field(WARC_Type => 'metadata'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'updating field fails on read-only object');

  $fail = 0;
  eval {$f->field(Foo => [qw/bar baz/]); $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'adding multiple value field fails on read-only object');

  $fail = 0;
  eval {$f->field(WARC_Filename => []); $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'removing field fails on read-only object');

  # tied array elements

  $fail = 0;
  eval {$f->[0]->value('metadata'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'updating value in tied array fails on read-only object');

  $fail = 0;
  eval {$f->[0] = 'Bogus'; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'changing field name in tied array fails on read-only object');

  is($#{$f}, 3,			'size of tied array as expected');
  $#{$f} = 3;			# set to known value for test coverage

  $fail = 0;
  eval {$#{$f} = 0; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'changing size of tied array fails on read-only object');

  $fail = 0;
  eval {delete $f->[2]; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'deleting row in tied array fails on read-only object');

  $fail = 0;
  eval {@{$f} = (); $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'clearing tied array fails on read-only object');

  $fail = 0;
  eval {push @{$f}, 'Foo'; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'pushing new row onto tied array fails on read-only object');

  is(push(@{$f}, ()), scalar @{$f},
     'pushing nothing onto tied array returns number of rows');

  $fail = 0;
  eval {pop @{$f}; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'popping from tied array fails on read-only object');

  $fail = 0;
  eval {unshift @{$f}, 'Foo'; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'unshifting into tied array fails on read-only object');

  is(unshift(@{$f}, ()), scalar @{$f},
     'unshifting nothing into tied array returns number of rows');

  $fail = 0;
  eval {shift @{$f}; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'shifting from tied array fails on read-only object');

  $fail = 0;
  eval {splice @{$f}, 1, 2; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'splicing rows from tied array fails on read-only object');

  $fail = 0;
  eval {splice @{$f}, 1, 0, 'Foo', 'Bar'; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'splicing rows into tied array fails on read-only object');

  is_deeply([splice @{$f}, 0, 0, ()], [],
	    'splicing nothing on tied array returns empty list');

  # tied hash elements

  $fail = 0;
  eval {$f->{WARC_Type} = 'metadata'; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'changing value in tied hash fails on read-only object');

  $fail = 0;
  eval {$f->{Foo} = 'new key'; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'adding key to tied hash fails on read-only object');

  is(scalar @{$f->{Foo}}, 0,
     'reading non-existent key returns empty value array on read-only object');

  $fail = 0;
  eval {delete $f->{WARC_Type}; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'deleting key from tied hash fails on read-only object');

  $fail = 0;
  eval {%{$f} = (); $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'clearing tied hash fails on read-only object');

  # tied hash value array

  $fail = 0;
  eval {$f->{WARC_Type}->[0] = 'metadata'; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'updating value in tied hash value array fails on read-only object');

  is($#{$f->{WARC_Type}}, 0,	'size of tied hash value array as expected');
  $#{$f->{WARC_Type}} = 0;	# set to known value for test coverage

  $fail = 0;
  eval {$#{$f->{WARC_Type}} = 2; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'changing size of tied hash value array fails on read-only object');

  $fail = 0;
  eval {delete $f->{WARC_Type}->[2]; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'deleting row in tied hash value array fails on read-only object');

  $fail = 0;
  eval {@{$f->{WARC_Type}} = (); $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'clearing tied hash value array fails on read-only object');

  $fail = 0;
  eval {push @{$f->{WARC_Type}}, 'Foo'; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'pushing new row onto tied hash value array fails on read-only object');

  is(push(@{$f->{WARC_Type}}, ()), scalar @{$f->{WARC_Type}},
     'pushing nothing onto tied hash value array returns number of rows');

  $fail = 0;
  eval {pop @{$f->{WARC_Type}}; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'popping from tied hash value array fails on read-only object');

  $fail = 0;
  eval {unshift @{$f->{WARC_Type}}, 'Foo'; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'unshifting into tied hash value array fails on read-only object');

  is(unshift(@{$f->{WARC_Type}}, ()), scalar @{$f->{WARC_Type}},
     'unshifting nothing into tied hash value array returns number of rows');

  $fail = 0;
  eval {shift @{$f->{WARC_Type}}; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'shifting from tied hash value array fails on read-only object');

  $fail = 0;
  eval {splice @{$f->{WARC_Type}}, 1, 2; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'splicing rows from tied hash value array fails on read-only object');

  $fail = 0;
  eval {splice @{$f->{WARC_Type}}, 1, 0, 'Foo', 'Bar'; $fail = 1;};
  ok($fail == 0 && $@ =~ m/read-only/,
     'splicing rows into tied hash value array fails on read-only object');

  is_deeply([splice @{$f->{WARC_Type}}, 0, 0, ()], [],
	    'splicing nothing on tied hash value array returns empty list');

  my $g = $f->clone;

  isa_ok($g, 'WARC::Fields', 'cloned object');

  is($g->as_string, $f->as_string,	'cloned object has same data');
  $g->field(WARC_Type => 'metadata');
  is($g->field('WARC-Type'), 'metadata','cloned object is not read-only');
  is($f->field('WARC-Type'), 'warcinfo',
     'original object not affected by change to cloned object');

  $g->field(WARC_Filename => []);
  ok((not defined $g->field('WARC-Filename')),
     'cloned object deletes field');
  is($f->field('WARC-Filename'), 'test-file.warc',
     'original object not affected by deletion on cloned object');

  # create very large object to tie up some code coverage loose ends
  @{$g} = ();
  push @{$g->{'Bottle-of-Beer-on-the-Wall'}}, 0 .. 9899;
  push @{$g}, ('Bottle-of-Beer-on-the-Wall') x 99;
  $g->[$_]->value(1+$_) for 9890 .. $#{$g};
  is($g->[$#{$g}]->offset, 9998,	'place 9999 bottles of beer');

  $f = $g->clone;
  # another code coverage loose end...
  is($f->_dbg_dump, $g->_dbg_dump,	'large cloned object has same data');
}

note('*' x 60);

# Check that internal attempts to use overloaded dereference operators fail
{
  {
    package WARC::Fields::BogusTestClass;

    our @ISA = qw(WARC::Fields);

    sub bogus_array_fetch {
      my $self = shift;
      my $row = shift;
      return $self->[$row];
    }

    sub bogus_hash_fetch {
      my $self = shift;
      my $key = shift;
      return $self->{$key};
    }
  }
  #
  my $f = new WARC::Fields::BogusTestClass ();

  my $fail = 0;
  eval {$f->bogus_array_fetch(0); $fail = 1;};
  ok($fail == 0 && $@ =~ m/overloaded array dereference in internal code/,
     'overloaded array dereference inside WARC::Fields* fails');

  $fail = 0;
  eval {$f->bogus_hash_fetch('Foo'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/overloaded hash dereference in internal code/,
     'overloaded hash dereference inside WARC::Fields* fails');
}

# Verify construction/destruction balances
subtest 'no memory leaks from circular references' => sub {
  plan tests => 7;

  is($WARC::Fields::TiedArray::_total_untied,
     $WARC::Fields::TiedArray::_total_tied,
     'all WARC::Fields::TiedArray objects untied');
  is($WARC::Fields::TiedArray::_total_destroyed,
     $WARC::Fields::TiedArray::_total_tied,
     'all WARC::Fields::TiedArray objects released');

  is($WARC::Fields::TiedHash::_total_untied,
     $WARC::Fields::TiedHash::_total_tied,
     'all WARC::Fields::TiedHash objects untied');
  is($WARC::Fields::TiedHash::_total_destroyed,
     $WARC::Fields::TiedHash::_total_tied,
     'all WARC::Fields::TiedHash objects released');

  is($WARC::Fields::TiedHash::ValueArray::_total_untied,
     $WARC::Fields::TiedHash::ValueArray::_total_tied,
     'all WARC::Fields::TiedHash::ValueArray objects untied');
  is($WARC::Fields::TiedHash::ValueArray::_total_destroyed,
     $WARC::Fields::TiedHash::ValueArray::_total_tied,
     'all WARC::Fields::TiedHash::ValueArray objects released');

  is($WARC::Fields::_total_destroyed,
     ($WARC::Fields::_total_newly_constructed
      +$WARC::Fields::_total_newly_cloned
      +$WARC::Fields::_total_newly_parsed),
     'all WARC::Fields objects released');
};

note(<<"EOR")
objects constructed/destroyed during test:
  WARC::Fields                          $WARC::Fields::_total_destroyed
  WARC::Fields::TiedArray               $WARC::Fields::TiedArray::_total_tied
  WARC::Fields::TiedHash                $WARC::Fields::TiedHash::_total_tied
  WARC::Fields::TiedHash::ValueArray    $WARC::Fields::TiedHash::ValueArray::_total_tied
EOR
