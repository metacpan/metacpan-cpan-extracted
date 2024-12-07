#! perl -w
use strict;

# $Id$

my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0; }
use lib $findbin;
use TestLib;

use Test::More tests => 11;
BEGIN { 
    use_ok( 'Test::Smoke::Util', qw( get_regen_headers run_regen_headers ) );
}

my $ddir = File::Spec->catdir( $findbin, 'perl-current' );
-d $ddir or mkpath( $ddir, 0, 0755 ) or die "Cannot mkpath($ddir): $!";
END { -d $ddir and rmtree( $ddir ); }

{
    my $regen = get_regen_headers( $ddir );
    is( $regen, undef, "Found none" );
}

SKIP: { # Find 'regen_headers.pl'
    my $to_skip = 2;
    local *FILE;
    my $regen_headers_pl = File::Spec->catfile( $ddir, 'regen_headers.pl' );
    open( FILE, "> $regen_headers_pl" ) 
        or skip "Cannot create '$regen_headers_pl': $!", $to_skip;
    print FILE <<EO_REGEN;
#! $^X -w
print "This is '\Q$regen_headers_pl\E'"
EO_REGEN

    close FILE or skip "Cannot write '$regen_headers_pl': $!", $to_skip;

    my $regen = get_regen_headers( $ddir );

    is( $regen, qq[$^X "$regen_headers_pl"], "Found '$regen'" )
        or skip "Not found [$regen_headers_pl]", --$to_skip;

    local *REGENRUN;
    if ( ok open( REGENRUN, "$regen |" ), "Start pipe" ) {
        chomp( my $output = <REGENRUN> );
        close REGENRUN;
        is( $output, "This is '$regen_headers_pl'",
            "Run regen_headers manually" );
    } else {
        skip "Could not run regen_headers", $to_skip--;
    }
}

SKIP: { # Prefer 'regen_headers.pl' over 'regen.pl'
    my $to_skip = 2;
    local *FILE;
    my $regen_headers_pl = File::Spec->catfile( $ddir, 'regen_headers.pl' );
    my $regen_pl = File::Spec->catfile( $ddir, 'regen.pl' );
    open( FILE, "> $regen_pl" ) 
        or skip "Cannot create '$regen_pl': $!", $to_skip;
    print FILE <<EO_REGEN;
#! $^X -w
print "This is '\Q$regen_pl\E'"
EO_REGEN

    close FILE or skip "Cannot write '$regen_pl': $!", $to_skip--;

    my $regen = get_regen_headers( $ddir );

    is( $regen, qq[$^X "$regen_headers_pl"], "Found '$regen'" )
        or skip "Not found [$regen_headers_pl]", $to_skip--;

    local *REGENRUN;
    if ( ok open( REGENRUN, "$regen |" ), "Start pipe" ) {
        chomp( my $output = <REGENRUN> );
        close REGENRUN;
        is( $output, "This is '$regen_headers_pl'",
            "Run regen_headers manually" );
    } else {
        skip "Could not run regen_headers", $to_skip--;
    }
}

SKIP: { # as of 18852: 'regen_headers.pl' is now 'regen.pl'
    my $to_skip = 2;
    my $regen_headers_pl = File::Spec->catfile( $ddir, 'regen_headers.pl' );
    my $regen_pl = File::Spec->catfile( $ddir, 'regen.pl' );

    unlink $regen_headers_pl 
        or skip "Cannot unlink($regen_headers_pl): $!", $to_skip--;

    my $regen = get_regen_headers( $ddir );

    is( $regen, qq[$^X "$regen_pl"], "Found '$regen'" )
        or skip "Not found [$regen_pl]", $to_skip--;

    local *REGENRUN;
    if ( ok open( REGENRUN, "$regen |" ), "Start pipe" ) {
        chomp( my $output = <REGENRUN> );
        close REGENRUN;
        is( $output, "This is '$regen_pl'",
            "Run regen_headers manually" );
    } else {
        skip "Could not run regen_headers", $to_skip--;
    }
}
