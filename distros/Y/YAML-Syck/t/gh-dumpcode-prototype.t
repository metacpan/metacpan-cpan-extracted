#!/usr/bin/perl -w

use strict;
use Test::More;

# Skip if Perl < 5.8 (no B::Deparse support in emitter)
BEGIN {
    plan skip_all => "B::Deparse code serialization requires Perl >= 5.8"
        if $] < 5.008;
    plan tests => 12;
}

use YAML::Syck;

# GH: DumpCode on subs with prototypes emitted the prototype string
# instead of the code body, because CVs with prototypes have SvPOK set
# in Perl internals, causing the emitter to take the string path
# instead of the SVt_PVCV code-serialization path.

$YAML::Syck::DumpCode = 1;
$YAML::Syck::LoadCode = 1;

# 1. Sub without prototype (baseline)
{
    my $code = sub { 42 };
    my $yaml = Dump($code);
    like( $yaml, qr/!!perl\/code/, "no-proto sub has !!perl/code tag" );
    like( $yaml, qr/42/, "no-proto sub body contains '42'" );
}

# 2. Sub with ($$) prototype
{
    my $code = sub ($$) { $_[0] + $_[1] };
    my $yaml = Dump($code);
    like( $yaml, qr/!!perl\/code/, '($$) proto sub has !!perl/code tag' );
    like( $yaml, qr/\$_\[0\]/, '($$) proto sub body is serialized, not just prototype' );

    # Round-trip
    my $loaded = Load($yaml);
    is( ref($loaded), 'CODE', '($$) proto sub round-trips to CODE ref' );
    is( $loaded->(3, 4), 7, '($$) proto sub round-trip produces working code' );
}

# 3. Sub with empty () prototype
{
    my $code = eval 'sub () { 99 }';
    my $yaml = Dump($code);
    like( $yaml, qr/!!perl\/code/, '() proto sub has !!perl/code tag' );
    like( $yaml, qr/99/, '() proto sub body contains return value' );
}

# 4. Sub with ($) prototype
{
    my $code = sub ($) { $_[0] * 2 };
    my $yaml = Dump($code);
    like( $yaml, qr/!!perl\/code/, '($) proto sub has !!perl/code tag' );

    my $loaded = Load($yaml);
    is( ref($loaded), 'CODE', '($) proto sub round-trips to CODE ref' );
}

# 5. Sub with (\@) prototype
{
    my $code = sub (\@) { scalar @{$_[0]} };
    my $yaml = Dump($code);
    like( $yaml, qr/!!perl\/code/, '(\@) proto sub has !!perl/code tag' );

    my $loaded = Load($yaml);
    is( ref($loaded), 'CODE', '(\@) proto sub round-trips to CODE ref' );
}
