use Test::More;
use YAML::Syck qw(DumpInto);

plan tests => 8;

{
    my $buf;
    DumpInto( \$buf, 42 );
    is( $buf, "--- 42\n" );    # 1
}

{
    my $buf;
    DumpInto( \$buf, \42 );
    is( $buf, "--- !!perl/ref \n=: 42\n" );
}

{
    my $buf;
    DumpInto( \$buf, undef );
    is( $buf, "--- ~\n" );     # 3
}

{
    my $buf;
    DumpInto( \$buf, { foo => [qw<bar baz>] } );
    is( $buf, "--- \nfoo: \n  - bar\n  - baz\n" );    # 4
}

{
    my $buf;
    DumpInto( \$buf, 1, 2, undef, 3 );
    is( $buf, "--- 1\n--- 2\n--- ~\n--- 3\n" );       # 5
}

{
    my $buf;
    DumpInto( \$buf, 1 );
    is( $buf, "--- 1\n" );                            # 6
    DumpInto( \$buf, 2 );
    is( $buf, "--- 1\n--- 2\n" );                     # 7
}

{
    my $buf = "HEWWO\n";
    DumpInto( \$buf, 42 );
    is( $buf, "HEWWO\n--- 42\n" );                    # 8
}

