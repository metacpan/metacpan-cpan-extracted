use Test;
use Cwd;

my $ALSO_PRIVATE = [ ];

#$ENV{RELEASE_TESTING}++;

my $chdir = 0;  # Test::Pod::Coverage is brain dead and won't find
                # lib or blib when run from t/, nor can you tell it
                # where to look
if ( cwd() =~ m/t$/ ) {
    chdir "..";
    $chdir++;
}

eval "use Test::Pod::Coverage 1.00";

if ($@) {
    print "1..0 Skip # Test::Pod::Coverage 1.00 required for testing POD\n";
}
else {
    if ( $ENV{RELEASE_TESTING} ) {
        all_pod_coverage_ok( { also_private => $ALSO_PRIVATE } );
    }
    else {
        print "1..0 # Skip Author only pod coverage tests not required\n";
    }
}

chdir "t" if $chdir;  # back to t/