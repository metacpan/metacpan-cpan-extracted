use Test::More;
use JSON::Syck qw(DumpInto Dump);

plan tests => 7;

sub same {
    my ($data) = @_;
    my $buf;
    DumpInto( \$buf, $data );
    is( $buf, Dump($data) );
}

same(42);    # 1

same( \42 ); # 2

same(undef); # 3

same( { foo => [qw<bar baz>] } );    # 4

{
    my $buf;
    DumpInto( \$buf, 1 );
    is( $buf, Dump(1) );             # 5
    DumpInto( \$buf, 2 );
    is( $buf, ( Dump(1) . Dump(2) ) );    # 6
}

{
    my $buf = "HEWWO ";
    DumpInto( \$buf, 42 );
    is( $buf, ( "HEWWO " . Dump(42) ) );    # 7
}

