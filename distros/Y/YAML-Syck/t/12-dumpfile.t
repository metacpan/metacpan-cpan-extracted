use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML;
use Test::More;

chdir $FindBin::RealBin;

unless ( -w $FindBin::RealBin ) {
    plan skip_all => "Can't write to $FindBin::RealBin";
    exit;
}

plan tests => 9;

*::DumpFile = *YAML::Syck::DumpFile;

sub file_contents_is {
    my ( $fn, $expected, $test_name ) = @_;
    local *FH;
    open FH, $fn or die $!;
    my $contents = do { local $/; <FH> };
    is( $contents, $expected, $test_name );
    close FH;
}

my $scalar        = 'a simple scalar';
my $expected_yaml = <<YAML;
--- a simple scalar
YAML

# using file name
{
    DumpFile( 'dumpfile.yml', $scalar );
    file_contents_is( 'dumpfile.yml', $expected_yaml, 'DumpFile works with filenames' );
    unlink 'dumpfile.yml' or die $!;
}

# dump to IO::File
{
    require IO::File;
    my $h = IO::File->new('>dumpfile.yml');
    DumpFile( $h, $scalar );
    close $h;
    file_contents_is( 'dumpfile.yml', $expected_yaml, 'DumpFile works with IO::File' );
    unlink 'dumpfile.yml' or die $!;
}

# dump to indirect file handles
{
    open( my $h, '>', 'dumpfile.yml' );
    DumpFile( $h, $scalar );
    close $h;
    file_contents_is( 'dumpfile.yml', $expected_yaml, 'DumpFile works with indirect file handles' );
    unlink 'dumpfile.yml' or die $!;
}

# dump to ordinary filehandles
{
    local *H;
    open( H, '>dumpfile.yml' );
    DumpFile( *H, $scalar );
    close(H);
    file_contents_is( 'dumpfile.yml', $expected_yaml, 'DumpFile works with ordinary file handles' );
    unlink 'dumpfile.yml' or die $!;
}

# dump to ordinary filehandles (refs)
{
    local *H;
    open( H, '>dumpfile.yml' );
    DumpFile( \*H, $scalar );
    close(H);
    file_contents_is( 'dumpfile.yml', $expected_yaml, 'DumpFile works with glob refs' );
    unlink 'dumpfile.yml' or die $!;
}

# dump to IO::Handle subclass (GH #23)
{
    package MyDumpIO;
    use parent 'IO::Handle';
    1;

    package main;
    require IO::File;
    my $h = IO::File->new('>dumpfile.yml');
    bless $h, 'MyDumpIO';    # re-bless into custom subclass
    DumpFile( $h, $scalar );
    close $h;
    file_contents_is( 'dumpfile.yml', $expected_yaml, 'DumpFile works with IO::Handle subclass (GH #23)' );
    unlink 'dumpfile.yml' or die $!;
}

# dump to "in memory" file
{
    open( my $h, '>', \my $s );
    DumpFile( $h, $scalar );
    close($h);
    is( $s, $expected_yaml, 'DumpFile works with in-memory files' );
}

# dump to tied filehandle (rt.cpan.org #96882)
{
    package TiedFH;
    sub TIEHANDLE { bless { data => '' }, shift }
    sub WRITE     { $_[0]->{data} .= substr($_[1], $_[3] || 0, $_[2]); return $_[2] }
    sub PRINT     { my $self = shift; $self->{data} .= join((defined $, ? $, : ''), @_); $self->{data} .= (defined $\ ? $\ : ''); 1 }
    sub data      { $_[0]->{data} }

    package main;
    tie *TFH, 'TiedFH';
    DumpFile(\*TFH, $scalar);
    is(tied(*TFH)->data, $expected_yaml, 'DumpFile works with tied filehandles (rt#96882)');
    untie *TFH;
}

# dump to tied filehandle with hash data
{
    tie *TFH2, 'TiedFH';
    DumpFile(\*TFH2, { a => 1 });
    my $result = tied(*TFH2)->data;
    like($result, qr/^---\s*\na: 1\s*$/s, 'DumpFile works with tied filehandle and hash data');
    untie *TFH2;
}
