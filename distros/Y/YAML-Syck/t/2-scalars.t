use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML tests => 134;

ok( YAML::Syck->VERSION, "YAML::Syck has a version and is loaded" );

is( Dump(42),         "--- 42\n", 'Dump a simple number' );
is( Load("--- 42\n"), 42, "Load a simple number");

is( Dump( \42 ),                           "--- !!perl/ref \n=: 42\n", "A pointer to 42 dumps" );
is( ${ Load("--- !!perl/ref \n=: 42\n") }, 42, "A pointer to 42 loads" );

my $x;
$x = \$x;
is( Dump($x),                        "--- &1 !!perl/ref \n=: *1\n", "A Circular Reference Loads." );
is( Dump( scalar Load( Dump($x) ) ), "--- &1 !!perl/ref \n=: *1\n", "A Circular Reference Round Trips." );

$YAML::Syck::DumpCode = 0;
is( Dump( sub { 42 } ), "--- !!perl/code: '{ \"DUMMY\" }'\n" );
$YAML::Syck::DumpCode = 1;

TODO: {
    local $TODO = "5.6 can't do code references in Syck right now" if ( $] < 5.007 );
    Test::More::like( Dump( sub { 42 } ), qr#--- !!perl/code.*?{.*?42.*?}$#s );
}

$YAML::Syck::LoadCode = 0;
{
    my $not_sub = Load("--- !!perl/code:Some::Class '{ \"foo\" . shift }'\n");
    is( ref $not_sub,      "Some::Class" );
    is( $not_sub->("bar"), undef );
}

{
    my $sub = Load("--- !!perl/code '{ \"foo\" . shift }'\n");
    is( ref $sub,      "CODE" );
    is( $sub->("bar"), undef );
}

my $like_yaml_pm = 0;
$YAML::Syck::LoadCode = 0;
ok( my $not_sub = Load("--- !!perl/Class '{ \"foo\" . shift }'\n") );

if ($like_yaml_pm) {
    is( ref($not_sub), "code" );
    is( eval { $$not_sub }, '{ "foo" . shift }' );
}
else {
    is( $not_sub, '{ "foo" . shift }' );
    ok(1);    # stick with the plan
}

$YAML::Syck::LoadCode = 1;
my $sub = Load("--- !!perl/code: '{ \"foo\" . \$_[0] }'\n");

ok( defined $sub );

is( ref($sub), "CODE" );
is( eval { $sub->("bar") }, "foobar" );
is( $@, "", "no error" );

$YAML::Syck::LoadCode = $YAML::Syck::DumpCode = 0;

$YAML::Syck::UseCode = $YAML::Syck::UseCode = 1;

TODO: {
    local $TODO;
    $TODO = "5.6 can't do code references in Syck right now" if ( $] < 5.007 );
    is(
        eval {
            Load( Dump( sub { "foo" . shift } ) )->("bar");
        },
        "foobar"
    );
    $TODO = '';
    is( $@, "", "no error" );
    $TODO = "5.6 can't do code references in Syck right now" if ( $] < 5.007 );
    is(
        eval {
            Load( Dump( sub { shift()**3 } ) )->(3);
        },
        27
    );
}

is( Dump(undef),      "--- ~\n" );
is( Dump('~'),        "--- \'~\'\n" );
is( Dump('a:'),       "--- \"a:\"\n" );
is( Dump('a: '),      "--- \"a: \"\n" );
is( Dump('a '),       "--- \"a \"\n" );
is( Dump('a: b'),     "--- \"a: b\"\n" );
is( Dump('a:b'),      "--- a:b\n" );
is( Load("--- ~\n"),  undef );
is( Load("---\n"),    undef );
is( Load("--- ''\n"), '' );

my $h = { bar => [qw<baz troz>] };
$h->{foo} = $h->{bar};
is( Dump($h), << '.');
--- 
bar: &1 
  - baz
  - troz
foo: *1
.

my $r;
$r = \$r;
is( Dump($r), << '.');
--- &1 !!perl/ref 
=: *1
.
is( Dump( scalar Load( Dump($r) ) ), << '.');
--- &1 !!perl/ref 
=: *1
.

# RT #17223
my $y = YAML::Syck::Load("SID:\n type: fixed\n default: ~\n");
eval { $y->{SID}{default} = 'abc' };
is( $y->{SID}{default}, 'abc' );

is( Load("--- true\n"),  "true" );
is( Load("--- false\n"), "false" );

$YAML::Syck::ImplicitTyping = $YAML::Syck::ImplicitTyping = 1;

is( Load("--- true\n"),  1 );
is( Load("--- false\n"), '' );

# Various edge cases at grok_number boundary
is( Load("--- 42949672\n"),    42949672 );
is( Load("--- -42949672\n"),   -42949672 );
is( Load("--- 429496729\n"),   429496729 );
is( Load("--- -429496729\n"),  -429496729 );
is( Load("--- 4294967296\n"),  4294967296 );
is( Load("--- -4294967296\n"), -4294967296 );

# RT #18752
my $recurse1 = << '.';
--- &1 
Foo: 
  parent: *1
Troz: 
  parent: *1
.

is( Dump( scalar Load($recurse1) ), $recurse1, 'recurse 1' );

# We wanna verify the circular ref but we can't garuntuee numbering after 5.18.0 changed the hash algorithm
my $recurse2 = << '.';
--- &1 
Bar: 
  parent: *1
Baz: 
  parent: *1
Foo: 
  parent: *1
Troz: 
  parent: *1
Zort: &2 
  Poit: 
    parent: *2
  parent: *1
.

my $recurse2want = qr{^---\s\&(\d+)\s*\n
Bar:\s*\n
\s\sparent:\s*\*\1\n
Baz:\s*\n
\s\sparent:\s*\*\1\n
Foo:\s*\n
\s\sparent:\s*\*\1\n
Troz:\s*\n
\s\sparent:\s*\*\1\n
Zort:\s&(?!\1)(\d+)\s*\n
\s\sPoit:\s\n
\s\s\s\sparent:\s+\*\2\n
\s\sparent:\s+\*\1
}xms;

like( Dump( scalar Load($recurse2) ), $recurse2want, 'recurse 2' );

is( Dump( 1, 2, 3 ), "--- 1\n--- 2\n--- 3\n" );
is( "@{[Load(Dump(1, 2, 3))]}", "1 2 3" );

$YAML::Syck::ImplicitBinary = $YAML::Syck::ImplicitBinary = 1;

is( Dump("\xff\xff"),           "--- !binary //8=\n" );
is( Load("--- !binary //8=\n"), "\xff\xff" );
is( Dump("ascii"),              "--- ascii\n" );

is( Dump("This is Perl 6 User's Golfing System\n"), q[--- "This is Perl 6 User's Golfing System\n"] . "\n" );

$YAML::Syck::SingleQuote = $YAML::Syck::SingleQuote = 1;

is( Dump("This is Perl 6 User's Golfing System\n"), qq[--- 'This is Perl 6 User''s Golfing System\n\n'\n] );
is( Dump('042'),                                    "--- '042'\n" );

roundtrip('042');
roundtrip("This\nis\na\ntest");
roundtrip("Newline\n");
roundtrip(" ");
roundtrip("\n");
roundtrip("S p a c e");
roundtrip("Space \n Around");

roundtrip("042");
roundtrip("0x42");
roundtrip("0.42");
roundtrip(".42");
roundtrip("1,000,000");
roundtrip("1e+6");
roundtrip("10e+6");

# If implicit typing is on, quote strings corresponding to implicit boolean and null values
$YAML::Syck::SingleQuote = 0;

is( Dump('N'),     "--- 'N'\n" );
is( Dump('NO'),    "--- 'NO'\n" );
is( Dump('No'),    "--- 'No'\n" );
is( Dump('no'),    "--- 'no'\n" );
is( Dump('y'),     "--- 'y'\n" );
is( Dump('YES'),   "--- 'YES'\n" );
is( Dump('Yes'),   "--- 'Yes'\n" );
is( Dump('yes'),   "--- 'yes'\n" );
is( Dump('TRUE'),  "--- 'TRUE'\n" );
is( Dump('false'), "--- 'false'\n" );
is( Dump('off'),   "--- 'off'\n" );

is( Dump('null'), "--- 'null'\n" );
is( Dump('Null'), "--- 'Null'\n" );
is( Dump('NULL'), "--- 'NULL'\n" );

is( Dump('oN'),   "--- oN\n" );      # invalid case
is( Dump('oFF'),  "--- oFF\n" );     # invalid case
is( Dump('nULL'), "--- nULL\n" );    # invalid case

# RT 52432 - '... X'
my $bad_hash = { '... X' => '' };
my $bad_hash_should = "--- \n... X: ''\n";
TODO: {
    local $TODO;
    $TODO = "roundtrip is breaking for this right now: '$bad_hash_should'";
    roundtrip($bad_hash);
}

is( Dump( { foo => "`bar" } ), qq{--- \nfoo: "`bar"\n}, 'RT 47944 - back quote is a reserved character' );

# quoted number corner cases:
foreach (qw/1 2 3 1.0 1.0000 1.00004 2.2 3.7 42.0 0.123 0.0042 0...02 98765432109123 987654321091234 -98765432109123/) {
    roundtrip($_);
}

# Un-quoted number corner cases:
foreach ( 1, 2, 3, 1.0, 1.0000, 1.00004, 2.2, 3.7, 42.0, 0.123, 0.0042, 0, 1, 98765432109123, 987654321091234 - 98765432109123 ) {
    roundtrip($_);
}

# Simple integers dump without quotes
foreach ( 1, 2, 3, 0, -1, -2, -3 ) {
    is( Dump($_), "--- $_\n", "Dumped version of file is unquoted" );
}

is( Dump('0x10'),         "--- 0x10\n", "hex Dump preserves as string" );
is( Load("--- '0x10'\n"), "0x10",       "hex Load preserves as string" );

is( Dump('080'),         "--- '080'\n", "oct Dump preserves by quoting" );
is( Load("--- '080'\n"), "080",         "oct Load preserves by quoting" );

is( Dump('00'),         "--- '00'\n", "00 Dump preserves by quoting" );
is( Load("--- '00'\n"), "00",         "00 Load preserves by quoting" );

# RT 54780 - double quoted loading style

TODO: {
    my $input = q{--- "<tag>content\
  \ string</tag>\n\
  <anothertag>other\
  \ content</anothertag>\n\
  \  \n<i>new</i>\n"};
    my $expected = q{<tag>content string</tag>
<anothertag>other content</anothertag>
  
<i>new</i>
};
    local $TODO = "not handling double quoted style right";
    is( Load($input), $expected, "RT 54780 - Wrong loading of YAML with double quoted style" );
}
