#! perl -w
use strict;

use Test::More;
use Test::NoWarnings ();

use Test::Smoke::App::Archiver;
use Test::Smoke::App::Options;

{
    local @ARGV = ('--archive', '-v' => 2);
    my $app = Test::Smoke::App::Archiver->new(
        Test::Smoke::App::Options->archiver_config(),
    );
    isa_ok($app, 'Test::Smoke::App::Archiver');

    no warnings 'redefine';
    my $files = [qw/mktest.json mktest.out mktest.rpt blead.log/];
    local *Test::Smoke::Archiver::archive_files = sub {
        return $files;
    };
    my $result = $app->run;
    is_deeply($result, $files, "List of files archived");
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();
