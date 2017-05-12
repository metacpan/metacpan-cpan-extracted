# perl
use strict;
use warnings;
use Carp;
use File::Basename;
use File::Temp qw( tempdir );
use lib qw( ./lib ../lib );
use Text::FixedWidth::Helper qw( fw2d );

my ($input, $output, $base, $tdir);

{
    $input = "./t/testlib/02-sample.txt";
    $base = basename($input);
    $tdir = tempdir( CLEANUP => 1 );
    $output = "$tdir/$base.out";
    fw2d( $input, $output );

    open my $OUT, '<', $output
        or croak "Unable to open $output for reading";
    print while (<$OUT>);
    close $OUT or croak "Unable to close $output after reading";
}
