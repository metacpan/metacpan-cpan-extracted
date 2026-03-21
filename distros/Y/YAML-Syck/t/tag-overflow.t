use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML tests => 6;

$YAML::Syck::LoadBlessed = 1;

# Test that Dump handles objects with very long class names without crashing.
# This exercises the dynamic tag buffer growth added to prevent a heap overflow
# when class names exceed the initial 512-byte allocation.

my $short_class = 'A' x 100;
my $long_class  = 'B' x 600;   # exceeds initial 512-byte tag buffer
my $huge_class  = 'C' x 2000;

# Short class name (fits in initial buffer)
{
    my $obj = bless {}, $short_class;
    my $yaml = Dump($obj);
    like($yaml, qr/!!perl\/hash:\Q$short_class\E/, "dump short class name ($short_class)");

    my $rt = Load($yaml);
    is(ref($rt), $short_class, "roundtrip short class name");
}

# Long class name (exceeds 512-byte buffer)
{
    my $obj = bless {}, $long_class;
    my $yaml = Dump($obj);
    like($yaml, qr/!!perl\/hash:\Q$long_class\E/, "dump long class name (600 chars)");

    my $rt = Load($yaml);
    is(ref($rt), $long_class, "roundtrip long class name");
}

# Huge class name
{
    my $obj = bless {}, $huge_class;
    my $yaml = Dump($obj);
    like($yaml, qr/!!perl\/hash:\Q$huge_class\E/, "dump huge class name (2000 chars)");

    my $rt = Load($yaml);
    is(ref($rt), $huge_class, "roundtrip huge class name");
}
