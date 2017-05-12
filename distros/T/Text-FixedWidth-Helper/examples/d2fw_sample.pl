# perl
use strict;
use warnings;
use Carp;
use File::Basename;
use File::Temp qw( tempdir );
use lib qw( ./lib ../lib );
use Text::FixedWidth::Helper qw( d2fw );

my ($input, $output, $base, $tdir);

{
    $input = "./t/testlib/01-sample.txt";
    $base = basename($input);
    $tdir = tempdir( CLEANUP => 1 );
    $output = "$tdir/$base.out";
    d2fw( $input, $output );

    open my $OUT, '<', $output
        or croak "Unable to open $output for reading";
    print while (<$OUT>);
    close $OUT or croak "Unable to close $output after reading";
}
