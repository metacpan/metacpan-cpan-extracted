use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML;
use JSON::Syck;
use Test::More;

chdir $FindBin::RealBin;

unless ( -w $FindBin::RealBin ) {
    plan skip_all => "Can't write to $FindBin::RealBin";
    exit;
}

plan tests => 12;

*::LoadFile = *JSON::Syck::LoadFile;

# remember where *DATA begins
my $pos = tell(DATA);
die "tell(DATA) failed: $!" unless $pos != -1;

# read via a GLOB
is( LoadFile(*DATA), "a simple scalar", 'LoadFile(*DATA) works' );

# rewind *DATA
seek( DATA, $pos, 0 ) == 1 or die "rewind *DATA failed: $!";

# read via a GLOB ref
is( LoadFile( \*DATA ), "a simple scalar", 'LoadFile(\*DATA) works' );

sub write_file {
    my ( $fh, $contents ) = @_;
    local *H;
    open( H, "> $fh" ) or die $!;
    print H $contents;
    close(H);
}

# write YAML to a file
write_file( 'loadfile.json',  "---\na simple scalar" );
write_file( 'emptyfile.json', "" );

END {
    unlink 'loadfile.json'  or die "can't delete 'loadfile.json': $!"  if -e 'loadfile.json';
    unlink 'emptyfile.json' or die "can't delete 'emptyfile.json': $!" if -e 'emptyfile.json';
}

# using file names
is( LoadFile('loadfile.json'), "a simple scalar", 'LoadFile works with file names' );

# read via IO::File
{
    require IO::File;
    my $h = IO::File->new('loadfile.json');
    is( LoadFile($h), "a simple scalar", 'LoadFile works with IO::File' );
    close($h);
}

# read via indirect file handles
SKIP: {
    skip "indirect file handles require 5.6 or later", 1 unless $] >= 5.006000;

    open( my $h, 'loadfile.json' );
    is( LoadFile($h), "a simple scalar", 'LoadFile works with indirect filehandles' );
    close($h);
}

# read via ordinary filehandles
{
    local *H;
    open( H, 'loadfile.json' );
    is( LoadFile(*H), "a simple scalar", 'LoadFile works with ordinary filehandles' );
    close(H);
}

# read via ordinary filehandles (refs)
{
    local *H;
    open( H, 'loadfile.json' );
    is( LoadFile( \*H ), "a simple scalar", 'LoadFile works with glob refs' );
    close(H);
}

# load from "in memory" file
SKIP: {
    skip "in-memory files require 5.8 or later", 1 unless $] >= 5.00800;

    open( my $h, '<', \'a simple scalar' );
    is( LoadFile($h), "a simple scalar", 'LoadFile works with in-memory files' );
    close($h);
}

{    # Load empty file fails
    my $json = eval { LoadFile('emptyfile.json') };
    like( $@, qr/^'emptyfile.json' is non-existent or empty at/ms, "LoadFile dies loading an empty file" );
    is( $json, undef, "LoadFile returns undef loading an empty file" );
}

{    # Load empty file handle fails with an obscure message. See RT 70933
    open( my $fh, '<', 'emptyfile.json' ) or die;
    my $json = eval { LoadFile($fh) };
    like( $@, qr/^Usage: YAML::Syck::LoadJSON\(s\) at /ms, "LoadFile dies loading an empty file" );
    is( $json, undef, "LoadFile returns undef loading an empty file" );
}

__DATA__
"a simple scalar"
