use Modern::Perl;
use Path::Tiny;
use Test::HexDifferences;
use Text::Diff;

sub compare_p {
    my ( $exp_p, $got_p ) = @_;

    my $exp_bytes = path($exp_p)->slurp_raw;
    my $got_bytes = path($got_p)->slurp_raw;

    eq_or_dump_diff(
        $exp_bytes, $got_bytes,
        { address => 0x4009 },
        "diff $exp_p $got_p"
    );
    if ( $exp_bytes ne $got_bytes ) {
        if ( $ENV{DEVELOPER} ) {
            dump_p( $exp_p, "$exp_p.txt" );
            dump_p( $got_p, "$got_p.txt" );
            system "start \"\" WinMergeU.exe $exp_p.txt $got_p.txt";
        }
    }

    if ( Test::More->builder->is_passing ) {
        unlink "$exp_p.txt", "$got_p.txt";
    }
}

sub compare_text {
    my ( $exp_txt, $got_txt ) = @_;

    my $diff = diff( "$exp_txt", "$got_txt" );
    ok $diff eq '', "diff $exp_txt $got_txt";
    if ( $diff ne '' ) {
        warn $diff;
        if ( $ENV{DEVELOPER} ) {
            system "start \"\" WinMergeU.exe $exp_txt $got_txt";
        }
    }
}

1;
