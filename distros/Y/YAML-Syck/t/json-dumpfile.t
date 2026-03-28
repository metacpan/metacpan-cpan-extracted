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

plan tests => 8;

*::DumpFile = *JSON::Syck::DumpFile;

sub file_contents_is {
    my ( $fn, $expected, $test_name ) = @_;
    local *FH;
    open FH, $fn or die $!;
    my $contents = do { local $/; <FH> };
    is( $contents, $expected, $test_name );
    close FH;
}

my $data          = { hello => 1 };
# DumpFile output must now match Dump output (postprocessed: no extra spaces, no trailing newline)
my $expected_json = JSON::Syck::Dump($data);

# using file name
{
    DumpFile( 'dumpfile.json', $data );
    file_contents_is( 'dumpfile.json', $expected_json, 'DumpFile works with filenames' );
    unlink 'dumpfile.json' or die $!;
}

# dump to IO::File
{
    require IO::File;
    my $h = IO::File->new('>dumpfile.json');
    DumpFile( $h, $data );
    close $h;
    file_contents_is( 'dumpfile.json', $expected_json, 'DumpFile works with IO::File' );
    unlink 'dumpfile.json' or die $!;
}

# dump to indirect file handles
{
    open( my $h, '>', 'dumpfile.json' );
    DumpFile( $h, $data );
    close $h;
    file_contents_is( 'dumpfile.json', $expected_json, 'DumpFile works with indirect file handles' );
    unlink 'dumpfile.json' or die $!;
}

# dump to ordinary filehandles
{
    local *H;
    open( H, '>dumpfile.json' );
    DumpFile( *H, $data );
    close(H);
    file_contents_is( 'dumpfile.json', $expected_json, 'DumpFile works with ordinary file handles' );
    unlink 'dumpfile.json' or die $!;
}

# dump to ordinary filehandles (refs)
{
    local *H;
    open( H, '>dumpfile.json' );
    DumpFile( \*H, $data );
    close(H);
    file_contents_is( 'dumpfile.json', $expected_json, 'DumpFile works with glob refs' );
    unlink 'dumpfile.json' or die $!;
}

# dump to "in memory" file
{
    open( my $h, '>', \my $s );
    DumpFile( $h, $data );
    close($h);
    is( $s, $expected_json, 'DumpFile works with in-memory files' );
}

# dump to tied filehandle
{
    package TiedFH;
    sub TIEHANDLE { bless { data => '' }, shift }
    sub WRITE     { $_[0]->{data} .= substr($_[1], $_[3] || 0, $_[2]); return $_[2] }
    sub PRINT     { my $self = shift; $self->{data} .= join(defined $, ? $, : '', @_); $self->{data} .= defined $\ ? $\ : '' ; 1 }
    sub data      { $_[0]->{data} }

    package main;
    tie *TFH, 'TiedFH';
    DumpFile(\*TFH, $data);
    is(tied(*TFH)->data, $expected_json, 'DumpFile works with tied filehandles');
    untie *TFH;
}

# dump to tied filehandle with scalar data
{
    tie *TFH2, 'TiedFH';
    DumpFile(\*TFH2, "simple string");
    is(tied(*TFH2)->data, '"simple string"', 'DumpFile works with tied filehandle and scalar data');
    untie *TFH2;
}
