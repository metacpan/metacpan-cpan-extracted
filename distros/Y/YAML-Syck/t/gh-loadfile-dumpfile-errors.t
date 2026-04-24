use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML;
use Test::More;
use JSON::Syck;
use File::Temp qw(tempdir);

plan tests => 12;

my $tmpdir = tempdir( CLEANUP => 1 );

# ---------- YAML::Syck::LoadFile error paths ----------

# Non-existent file
{
    my $bogus = "$tmpdir/does-not-exist.yml";
    my $rv    = eval { YAML::Syck::LoadFile($bogus) };
    like(
        $@,
        qr/is empty or non-existent/,
        'YAML LoadFile dies on non-existent file'
    );
    is( $rv, undef, 'YAML LoadFile returns undef on non-existent file' );
}

# Unreadable file (skip on Windows and root)
SKIP: {
    skip 'chmod not effective on Windows', 2 if $^O eq 'MSWin32';
    skip 'chmod not effective when running as root', 2 if $> == 0;

    my $noread = "$tmpdir/noread.yml";
    open my $fh, '>', $noread or die "setup: $!";
    print $fh "--- hello\n";
    close $fh;
    chmod 0000, $noread;

    my $rv = eval { YAML::Syck::LoadFile($noread) };
    like(
        $@,
        qr/Cannot read from/,
        'YAML LoadFile dies on unreadable file'
    );
    is( $rv, undef, 'YAML LoadFile returns undef on unreadable file' );

    chmod 0644, $noread;    # restore for cleanup
}

# ---------- YAML::Syck::DumpFile error paths ----------

# Unwritable path (directory does not exist)
{
    my $badpath = "$tmpdir/no-such-dir/output.yml";
    my $rv      = eval { YAML::Syck::DumpFile( $badpath, 'data' ) };
    like(
        $@,
        qr/Cannot write to/,
        'YAML DumpFile dies when parent directory does not exist'
    );
    ok( !$rv, 'YAML DumpFile returns false on write failure' );
}

# ---------- JSON::Syck::LoadFile error paths ----------

# Non-existent file
{
    my $bogus = "$tmpdir/does-not-exist.json";
    my $rv    = eval { JSON::Syck::LoadFile($bogus) };
    like(
        $@,
        qr/non-existent or empty/,
        'JSON LoadFile dies on non-existent file'
    );
    is( $rv, undef, 'JSON LoadFile returns undef on non-existent file' );
}

# Unreadable file (skip on Windows and root)
SKIP: {
    skip 'chmod not effective on Windows', 2 if $^O eq 'MSWin32';
    skip 'chmod not effective when running as root', 2 if $> == 0;

    my $noread = "$tmpdir/noread.json";
    open my $fh, '>', $noread or die "setup: $!";
    print $fh '{"hello":"world"}';
    close $fh;
    chmod 0000, $noread;

    my $rv = eval { JSON::Syck::LoadFile($noread) };
    like(
        $@,
        qr/Cannot read from/,
        'JSON LoadFile dies on unreadable file'
    );
    is( $rv, undef, 'JSON LoadFile returns undef on unreadable file' );

    chmod 0644, $noread;    # restore for cleanup
}

# ---------- JSON::Syck::DumpFile error paths ----------

# Unwritable path (directory does not exist)
{
    my $badpath = "$tmpdir/no-such-dir/output.json";
    my $rv      = eval { JSON::Syck::DumpFile( $badpath, { key => 'val' } ) };
    like(
        $@,
        qr/Cannot write to/,
        'JSON DumpFile dies when parent directory does not exist'
    );
    ok( !$rv, 'JSON DumpFile returns false on write failure' );
}
