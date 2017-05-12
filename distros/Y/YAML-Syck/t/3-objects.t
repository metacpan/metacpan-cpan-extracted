use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML tests => 51,
  (
      ( $] < 5.008 )
    ? ( todo => [ 19 .. 20, 26 .. 29 ] )
    : ()
  );

ok( YAML::Syck->VERSION );

is( Dump( bless( {}, 'foo' ) ), "--- !!perl/hash:foo {}\n\n" );

sub ref_ok {
    my $x = Load("--- $_[0] {a: b}\n");
    is( ref($x), $_[1], "ref - $_[0]" );
    is( $x->{a}, 'b',   "data - $_[0]" );
}

sub run_ref_ok {
    ref_ok( splice( @_, 0, 2 ) ) while @_;
}

run_ref_ok(
    qw(
      !!perl/hash:foo     foo
      !perl/foo           foo
      !hs/Foo             hs::Foo
      !haskell.org/Foo    haskell.org::Foo
      !haskell.org/^Foo   haskell.org::Foo
      !!perl              HASH
      !!moose             moose
      !ruby/object:Test::Bear ruby::object:Test::Bear
      )
);

# perl 5.13.5 and later has fb85c04, which changed the regex
# stringification syntax. This is also valid.
use constant REGEX_CARET => qr// =~ /\Q(?^\E/;

my $rx = qr/123/;
if (REGEX_CARET) {
    ok( 1, "Testing regexes with the >=5.13.5 caret syntax" );
    is( Dump($rx),                 "--- !!perl/regexp (?^:123)\n" );
    is( Dump( Load( Dump($rx) ) ), "--- !!perl/regexp (?^:(?^:123))\n" );
}
else {
    ok( 1, "Testing regexes with the old <5.13.5 syntax" );
    is( Dump($rx),                 "--- !!perl/regexp (?-xism:123)\n" );
    is( Dump( Load( Dump($rx) ) ), "--- !!perl/regexp (?-xism:123)\n" );
}

SKIP: {
    Test::More::skip "5.6 doesn't support printing regexes", 2 if ( $] < 5.007 );
    my $rx_obj = bless qr/123/i => 'Foo';
    if (REGEX_CARET) {
        is( Dump($rx_obj),                 "--- !!perl/regexp:Foo (?^i:123)\n" );
        is( Dump( Load( Dump($rx_obj) ) ), "--- !!perl/regexp:Foo (?^:(?^i:123))\n" );
    }
    else {
        is( Dump($rx_obj),                 "--- !!perl/regexp:Foo (?i-xsm:123)\n" );
        is( Dump( Load( Dump($rx_obj) ) ), "--- !!perl/regexp:Foo (?i-xsm:123)\n" );
    }
}

my $obj = bless( \( my $undef ) => 'Foo' );
is( Dump($obj),                 "--- !!perl/scalar:Foo ~\n" );
is( Dump( Load( Dump($obj) ) ), "--- !!perl/scalar:Foo ~\n" );

is( Dump( bless( { 1 .. 10 }, 'foo' ) ), "--- !!perl/hash:foo \n1: 2\n3: 4\n5: 6\n7: 8\n9: 10\n" );

$YAML::Syck::UseCode = 1;

{
    my $hash = Load( Dump( bless( { 1 .. 4 }, "code" ) ) );
    is( ref($hash), "code", "blessed to code" );
    is( eval { $hash->{1} }, 2, "it's a hash" );
}

TODO: {
    my $sub = eval {
        Load( Dump( bless( sub { 42 }, "foobar" ) ) );
    };
    is( ref($sub), "foobar", "blessed to foobar" );
    local $TODO = "5.6 can't do code references in Syck right now" if ( $] < 5.007 );
    is( eval { $sub->() }, 42, "it's a CODE" );
}

TODO: {
    my $sub = eval {
        Load( Dump( bless( sub { 42 }, "code" ) ) );
    };
    is( ref($sub), "code", "blessed to code" );
    local $TODO = "5.6 can't do code references in Syck right now" if ( $] < 5.007 );
    is( eval { $sub->() }, 42, "it's a CODE" );
}

$YAML::Syck::LoadBlessed = 0;

run_ref_ok(
    qw(
      !!perl/hash:foo     HASH
      !perl/foo           HASH
      !hs/Foo             HASH
      !haskell.org/Foo    HASH
      !haskell.org/^Foo   HASH
      !!perl              HASH
      !!moose             HASH
      !ruby/object:Test::Bear HASH
      )
);

my $hash = { a => [ 42, [], {} ], h => { 53, 12 } };
my $loaded = Load( Dump($hash) );
is_deeply $loaded => $hash, "Deep hash round trips";

my $blesshash = bless { a => [ 42, [], bless( {}, 'foo' ) ], h => { 53, 12 } }, 'bar';
my $stripped = Load( Dump($blesshash) );
is_deeply $stripped => $hash, "Deep hash round trips and strip blessings";

$YAML::Syck::LoadBlessed = 1;

my $not_stripped = Load( Dump($blesshash) );
is_deeply $not_stripped => $blesshash, "Deep hash round trips and doesn't strips blessings";

exit;
