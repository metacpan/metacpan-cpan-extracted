use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML tests => 25;

ok( YAML::Syck->VERSION );

# These tests assume object creation.
$YAML::Syck::LoadBlessed = 1;

# perl 5.13.5+ uses (?^:...) syntax for regex stringification
use constant REGEX_CARET => qr// =~ /\Q(?^\E/;

# This file is based on pyyaml wiki entry for PerlTagScheme, and Ingy's
# guidance.

# http://pyyaml.org/wiki/PerlTagScheme says:
#
# !!perl/hash     # hash reference
# !!perl/array    # array reference
# !!perl/scalar   # scalar reference
# !!perl/code     # code reference
# !!perl/io       # io reference
# !!perl/glob     # a glob (not a ref)
# !!perl/regexp   # a regexp (not a ref)
# !!perl/ref      # a container ref to any of the above
#
# All of the above types can be blessed:
#
# !!perl/hash:Foo::Bar   # hash ref blessed with 'Foo::Bar'
# !!perl/glob:Foo::Bar   # glob blessed with 'Foo::Bar'
#

sub yaml_is {
    my ( $yaml, $expected, @args ) = @_;
    $yaml =~ s/\s+\n/\n/gs;
    @_ = ( $yaml, $expected, @args );
    goto &is;
}

{
    my $hash = { foo => "bar" };
    yaml_is( Dump($hash), "---\nfoo: bar\n" );
    bless $hash, "Foo::Bar";
    yaml_is( Dump($hash), "--- !!perl/hash:Foo::Bar\nfoo: bar\n" );
}

{
    my $scalar = "foo";
    yaml_is( Dump($scalar), "--- foo\n" );
    my $ref = \$scalar;
    yaml_is( Dump($ref), "--- !!perl/ref\n=: foo\n" );
    bless $ref, "Foo::Bar";
    yaml_is( Dump($ref), "--- !!perl/scalar:Foo::Bar foo\n" );
}

{
    my $hash        = { foo => "bar" };
    my $deep_scalar = \$hash;
    yaml_is( Dump($deep_scalar), "--- !!perl/ref\n=:\n  foo: bar\n" );
    bless $deep_scalar, "Foo::Bar";
    yaml_is( Dump($deep_scalar), "--- !!perl/ref:Foo::Bar\n=:\n  foo: bar\n" );
}

{
    my $array = [ 23, 42 ];
    yaml_is( Dump($array), "---\n- 23\n- 42\n" );
    bless $array, "Foo::Bar";
    yaml_is( Dump($array), "--- !!perl/array:Foo::Bar\n- 23\n- 42\n" );
}

{
    # Dump: unblessed regex
    my $regex = qr/a(b|c)d/;
    if (REGEX_CARET) {
        yaml_is( Dump($regex), "--- !!perl/regexp (?^:a(b|c)d)\n" );
    }
    else {
        yaml_is( Dump($regex), "--- !!perl/regexp (?-xism:a(b|c)d)\n" );
    }

    # Dump: blessed regex
    bless $regex, "Foo::bar";
    if (REGEX_CARET) {
        yaml_is( Dump($regex), "--- !!perl/regexp:Foo::bar (?^:a(b|c)d)\n" );
    }
    else {
        yaml_is( Dump($regex), "--- !!perl/regexp:Foo::bar (?-xism:a(b|c)d)\n" );
    }
}

{
    # Load: unblessed regex
    my $yaml_re = REGEX_CARET ? "(?^:a(b|c)d)" : "(?-xism:a(b|c)d)";
    my $re = Load("--- !!perl/regexp $yaml_re\n");
    is( ref($re), "Regexp" );
    ok( "abd" =~ $re, "loaded regexp matches" );
}

{
    # Load: blessed regex
    my $yaml_re = REGEX_CARET ? "(?^:a(b|c)d)" : "(?-xism:a(b|c)d)";
    my $re = Load("--- !!perl/regexp:Foo::bar $yaml_re\n");
    is( ref($re), "Foo::bar" );
    ok( "acd" =~ $re, "loaded blessed regexp matches" );
}

{
    # Round-trip
    my $re = qr/hello\s+world/i;
    my $loaded = Load( Dump($re) );
    is( "$loaded", "$re", "regexp round-trips" );
}

{
    my $hash = Load("--- !!perl/hash\nfoo: bar\n");
    is( ref($hash),   "HASH" );
    is( $hash->{foo}, "bar" );
}

{
    my $hash = Load("--- !!perl/hash:Foo::Bar\nfoo: bar\n");
    is( ref($hash),   "Foo::Bar" );
    is( $hash->{foo}, "bar" );
}

{
    my $array = Load("--- !!perl/array\n- 42\n- 3\n");
    is( ref($array), "ARRAY" );
    is( $array->[0], 42 );
}

{
    my $array = Load("--- !!perl/array:Foo::Bar\n- 42\n- 3\n");
    is( ref($array), "Foo::Bar" );
    is( $array->[0], 42 );
}

