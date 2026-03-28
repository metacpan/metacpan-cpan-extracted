use strict;
use warnings;
use Test::More tests => 11;

use YAML::Syck;

ok( YAML::Syck->VERSION );
is( Dump("Hello, world"),       "--- Hello, world\n" );
is( Load("--- Hello, world\n"), "Hello, world" );

# RT 34073 / GH #35 - "--\n" is valid YAML (plain scalar), not a parse error
{
    my $out = eval { Load("--\n") };
    is( $@, '', "Load of '--' does not die" );
    is( $out, '--', "Load of '--' returns plain scalar" );
}

# Syck is a permissive YAML 1.0 parser: empty strings and unstructured
# text are not errors.  This matches YAML.pm and YAML::XS behavior.
# See GH #127 for the design discussion.
{
    my $out = eval { Load("") };
    is( $@, '', "Load('') does not die" );
    is( $out, undef, "Load('') returns undef" );
}

{
    my $out = eval { Load("feefifofum\n\n\ndkjdkdk") };
    is( $@, '', "Load of unstructured text does not die" );
    like( $out, qr/^feefifofum/, "unstructured text is a plain scalar" );
}

# RT 23850 / GH #27 - non-specific tag '!' followed by block scalar indicator
{
    my $out = eval { Load("---\n- ! >-\n") };
    is( $@, '', "Non-specific tag with block scalar does not die" );
    is_deeply( $out, [''], "Non-specific tag with block scalar parses correctly" );
}
