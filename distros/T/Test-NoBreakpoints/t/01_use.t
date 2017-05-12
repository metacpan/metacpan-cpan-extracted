use strict;
use warnings;

use File::Find;

# find the number of .pm files in the lib directory
my $pms = 0;
File::Find::find( sub { /\.pm$/ && $pms++ }, 'lib');

my %expected;
BEGIN {

    %expected = (
        'Test::NoBreakpoints' => '0.15',
    );

    use Test::More;
    our $tests = ((keys %expected) * 2) + 1;
    eval "use Test::NoWarnings";
    $tests++ unless( $@ );
    plan tests => $tests;
}

# make sure that we are testing the number of .pm files in lib
is keys %expected, $pms, "$pms version tests planned";

# check each package
for my $package( keys %expected ) {

    # pull in the package
    use_ok($package);

    # make sure the package version is correct
    my $version_var;
    {
        no strict 'refs';
        $version_var = ${$package . '::VERSION'};
    }
    is($version_var, $expected{$package},
        "$package is at version $expected{$package}");
}
