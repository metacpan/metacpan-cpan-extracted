use strict;
use warnings;

use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML ();
use Test::More tests => 10;
use File::Temp qw(tempfile);
use YAML::Syck qw(DumpFile LoadFile);

# GH #28 / RT #25436: Wide character warning when using DumpFile with
# ImplicitUnicode and wide characters like the Euro sign (U+20AC).

my $euro = "\x{20ac}";

# --- DumpFile with filename: no warning, correct roundtrip ---
{
    local $YAML::Syck::ImplicitUnicode = 1;
    my ( $fh, $tmpfile ) = tempfile( UNLINK => 1, SUFFIX => '.yml' );
    close $fh;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    DumpFile( $tmpfile, $euro );
    is( scalar @warnings, 0, 'DumpFile(filename): no wide character warnings' );

    my $loaded = LoadFile($tmpfile);
    is( $loaded, $euro, 'DumpFile/LoadFile roundtrip via filename' );
}

# --- DumpFile with open filehandle: no warning, correct roundtrip ---
{
    local $YAML::Syck::ImplicitUnicode = 1;
    my ( $fh, $tmpfile ) = tempfile( UNLINK => 1, SUFFIX => '.yml' );
    close $fh;

    open( my $wfh, '>', $tmpfile ) or die "Cannot open $tmpfile: $!";

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    DumpFile( $wfh, $euro );
    close $wfh;
    is( scalar @warnings, 0, 'DumpFile(filehandle): no wide character warnings' );

    my $loaded = LoadFile($tmpfile);
    is( $loaded, $euro, 'DumpFile/LoadFile roundtrip via filehandle' );
}

# --- DumpFile with tied filehandle: no warning ---
{

    package TiedFH28;
    sub TIEHANDLE { bless { data => '' }, shift }
    sub WRITE     { $_[0]->{data} .= substr( $_[1], $_[3] || 0, $_[2] ); return $_[2] }
    sub PRINT     { my $self = shift; $self->{data} .= join( defined $, ? $, : '', @_ ); $self->{data} .= defined $\ ? $\ : ''; 1 }
    sub data      { $_[0]->{data} }

    package main;
    local $YAML::Syck::ImplicitUnicode = 1;

    tie *TFH28, 'TiedFH28';

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    DumpFile( \*TFH28, $euro );
    is( scalar @warnings, 0, 'DumpFile(tied fh): no wide character warnings' );

    my $yaml_data = tied(*TFH28)->data;
    like( $yaml_data, qr/\x{20ac}/, 'DumpFile(tied fh): output contains Euro sign' );
    untie *TFH28;
}

# --- DumpFile with in-memory file: no warning ---
eval q[
        local $YAML::Syck::ImplicitUnicode = 1;

        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };

        open(my $h, '>', \my $s);
        DumpFile($h, $euro);
        close($h);
        is(scalar @warnings, 0, 'DumpFile(in-memory file): no wide character warnings');
        like($s, qr/---/, 'DumpFile(in-memory file): produced valid YAML');
    ];

# --- Multi-byte characters beyond BMP ---
{
    local $YAML::Syck::ImplicitUnicode = 1;
    my ( $fh, $tmpfile ) = tempfile( UNLINK => 1, SUFFIX => '.yml' );
    close $fh;

    # Test with various wide characters: Euro, CJK, emoji-range
    my $wide_str = "\x{20ac}\x{4e16}\x{754c}";    # Euro + Chinese "world"

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    DumpFile( $tmpfile, $wide_str );
    is( scalar @warnings, 0, 'DumpFile with multiple wide chars: no warnings' );

    my $loaded = LoadFile($tmpfile);
    is( $loaded, $wide_str, 'DumpFile/LoadFile roundtrip with multiple wide chars' );
}
