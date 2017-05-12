use Test;
use Cwd;

#$ENV{RELEASE_TESTING}++;

my $chdir = 0;
if ( cwd() =~ m/t$/ ) {
    chdir "..";
    $chdir++;
}

eval { require Test::Kwalitee;};

if ($@) {
    plan tests => 1;
    skip("Test::Kwalitee not installed; skipping");
}
else {
    if ( $ENV{RELEASE_TESTING} ) {
        Test::Kwalitee->import();
    }
    else {
        plan tests => 1;
        skip( "Author only private tests" );
    }
}

chdir "t" if $chdir;  # back to t/
