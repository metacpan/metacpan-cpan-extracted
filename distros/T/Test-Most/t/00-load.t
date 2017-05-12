#!perl -T

use Test::More tests => 9;

BEGIN {
    local $^W;
    use_ok('Test::Most')
      or BAIL_OUT("Cannot load Test::Most");
    use_ok('Test::Most::Exception')
      or BAIL_OUT("Cannot load Test::Most::Exception");

    diag("Testing Test::Most $Test::Most::VERSION, Perl $], $^X");
    my @dependencies = qw(
      Exception::Class
      Test::Deep
      Test::Differences
      Test::Exception
      Test::Harness
      Test::More
      Test::Warn
    );
    foreach my $module (@dependencies) {
        use_ok $module or BAIL_OUT("Cannot load $module");
        my $version = $module->VERSION;
        diag("    $module version is $version");
    }
}
