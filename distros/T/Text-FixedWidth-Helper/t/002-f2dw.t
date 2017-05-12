# perl
use strict;
use warnings;
use Carp;
use Cwd;
use Data::Dumper;$Data::Dumper::Indent=1;
use File::Basename;
use File::Temp qw( tempdir );
use IO::CaptureOutput qw( capture );
use Test::More qw( no_plan );
use Tie::File;
use lib qw( ./lib );
use Text::FixedWidth::Helper qw( fw2d );

my ($input, $output, $produced, $base, $tdir);
my $cwd = cwd();

{
    $input = "$cwd/t/testlib/02-sample.txt";
    $base = basename($input);
    $tdir = tempdir( CLEANUP => 1 );
    $output = "$tdir/$base.transformed";
    $produced = fw2d( $input, $output );
    ok( ( -f $produced ), "Output file produced" );

    my @lines;
    tie @lines, 'Tie::File', $produced
        or croak "Unable to tie to $produced";
    like( $lines[0], qr/^fname\|Sylvester$/,
        "Got expected first line" );
    like( $lines[6], qr/^zip\|14618$/,
        "Got expected last line in first block" );
    like( $lines[7], qr/^/,
        "Got expected empty line between blocks" );
    untie @lines or croak "Cannot untie from $produced";
}

{
    $input = "$cwd/foobar";
    $base = basename($input);
    $tdir = tempdir( CLEANUP => 1 );
    $output = "$tdir/$base.transformed";
    eval {
        $produced = fw2d( $input, $output );
    };
    like( $@, qr/Could not locate input file $input/,
        "Got expected death message: input not found" );
}

{
    $input = "$cwd/t/testlib/02-sample.txt";
    $base = basename($input);
    $tdir = tempdir( CLEANUP => 1 );
    $produced = fw2d( $input );
    ok( ( -f $produced ), "Output file produced" );
    is( $produced, "$input.out",
        "Output file name defaulted to expected value" );

    my @lines;
    tie @lines, 'Tie::File', $produced
        or croak "Unable to tie to $produced";
    like( $lines[0], qr/^fname\|Sylvester$/,
        "Got expected first line" );
    like( $lines[6], qr/^zip\|14618$/,
        "Got expected last line in first block" );
    like( $lines[7], qr/^/,
        "Got expected empty line between blocks" );
    untie @lines or croak "Cannot untie from $produced";
    unlink $produced;
}

{
    $input = "$cwd/t/testlib/06-toolong.txt";
    $base = basename($input);
    $tdir = tempdir( CLEANUP => 1 );
    $output = "$tdir/$base.transformed";
    eval {
        $produced = fw2d( $input, $output );
    };
    like( $@,
        qr/Text::FixedWidth::Helper restricts records to 1000 characters/,
        "Got expected death message: template too long" );
}

{
    $input = "$cwd/t/testlib/07-toomanyrecords.txt";
    $base = basename($input);
    $tdir = tempdir( CLEANUP => 1 );
    $output = "$tdir/$base.transformed";
    {
        my ($stdout, $stderr);
        capture(
            sub { $produced = fw2d( $input, $output ); },
            \$stdout,
            \$stderr,
        );
        like( $stderr,
            qr/Text::FixedWidth::Helper restricts you to 3 input records/,
            "Got expected warning: too many sample records" );
        ok( ( -f $produced ), "Output file produced" );
    
        my @lines;
        tie @lines, 'Tie::File', $produced
            or croak "Unable to tie to $produced";
        like( $lines[0], qr/^fname\|Sylvester$/,
            "Got expected first line" );
        like( $lines[6], qr/^zip\|14618$/,
            "Got expected last line in first block" );
        like( $lines[7], qr/^/,
            "Got expected empty line between blocks" );
        untie @lines or croak "Cannot untie from $produced";
    };
}

{
    $input = "$cwd/t/testlib/08-badmetadata.txt";
    $base = basename($input);
    $tdir = tempdir( CLEANUP => 1 );
    eval {
        $produced = fw2d( $input );
    };
    like( $@,
        qr/In metadata section, value of.*must be numeric/,
        "Got expected death message: non-numeric metadata value" );
}

