# perl
use strict;
use warnings;
use Carp;
use Cwd;
use File::Basename;
use File::Temp qw( tempdir );
use IO::CaptureOutput qw( capture );
use Test::More qw( no_plan );
use Tie::File;
use lib qw( ./lib );
use Text::FixedWidth::Helper qw( d2fw );

my ($input, $output, $produced, $base, $tdir);
my $cwd = cwd();

{
    $input = "$cwd/t/testlib/01-sample.txt";
    $base = basename($input);
    $tdir = tempdir( CLEANUP => 1 );
    $output = "$tdir/$base.transformed";
    $produced = d2fw( $input, $output );
    ok( ( -f $produced ), "Output file produced" );

    my @lines;
    tie @lines, 'Tie::File', $produced
        or croak "Unable to tie to $produced";
    like( $lines[0], qr/^(?:1234567890)+/,
        "Got index line" );
    like( $lines[1], qr/^[\s|]+$/, "Got a spacer line" );
    like( $lines[2],
        qr/^Sylvester\s{6}JGomez\s{10}M789294592Rochester\s{11}NY14618$/,
        "Got expected fixed-width line" );
    untie @lines or croak "Cannot untie from $produced";
}

{
    $input = "$cwd/foobar";
    $base = basename($input);
    $tdir = tempdir( CLEANUP => 1 );
    $output = "$tdir/$base.transformed";
    eval {
        $produced = d2fw( $input, $output );
    };
    like( $@, qr/Could not locate input file $input/,
        "Got expected death message: input not found" );
}

{
    $input = "$cwd/t/testlib/01-sample.txt";
    $base = basename($input);
    $tdir = tempdir( CLEANUP => 1 );
    $produced = d2fw( $input );
    ok( ( -f $produced ), "Output file produced" );
    is( $produced, "$input.out",
        "Output file name defaulted to expected value" );

    my @lines;
    tie @lines, 'Tie::File', $produced
        or croak "Unable to tie to $produced";
    like( $lines[0], qr/^(?:1234567890)+/,
        "Got index line" );
    like( $lines[1], qr/^[\s|]+$/, "Got a spacer line" );
    like( $lines[2],
        qr/^Sylvester\s{6}JGomez\s{10}M789294592Rochester\s{11}NY14618$/,
        "Got expected fixed-width line" );
    untie @lines or croak "Cannot untie from $produced";
    unlink $produced;
}

{
    $input = "$cwd/t/testlib/03-toolong.txt";
    $base = basename($input);
    $tdir = tempdir( CLEANUP => 1 );
    $output = "$tdir/$base.transformed";
    eval {
        $produced = d2fw( $input, $output );
    };
    like( $@,
        qr/Text::FixedWidth::Helper restricts records to 1000 characters/,
        "Got expected death message: template too long" );
}

{
    $input = "$cwd/t/testlib/04-toomanyrecords.txt";
    $base = basename($input);
    $tdir = tempdir( CLEANUP => 1 );
    $output = "$tdir/$base.transformed";
    {
        my ($stdout, $stderr);
        capture(
            sub { $produced = d2fw( $input, $output ); },
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
        like( $lines[0], qr/^(?:1234567890)+/,
            "Got index line" );
        like( $lines[1], qr/^[\s|]+$/, "Got a spacer line" );
        like( $lines[$#lines],
            qr/^Kasimir/,
            "Got expected last fixed-width line" );
        unlike( $lines[$#lines],
            qr/^Horace/,
            "Did not get extra fixed-width line" );
        untie @lines or croak "Cannot untie from $produced";
    };
}

{
    $input = "$cwd/t/testlib/05-badmetadata.txt";
    $base = basename($input);
    $tdir = tempdir( CLEANUP => 1 );
    eval {
        $produced = d2fw( $input );
    };
    like( $@,
        qr/In metadata section, value of.*must be numeric/,
        "Got expected death message: non-numeric metadata value" );
}

__END__
12345678901234567890123456789012345678901234567890123456789012345678
|              ||              |         |                   | |    
Sylvester      JGomez          M789294592Rochester           NY14618
Arthur         XFridrikkson    M783891590Oakland             CA94601
Kasimir        EKristemanaczewsN389182992Buffalo             NY14214

