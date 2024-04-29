#! perl -w
use strict;

use Test::More;
use Test::NoWarnings ();

use File::Spec::Functions;
use File::Temp qw< tempdir >;
use File::Path qw< mkpath >;

use Test::Smoke::App::Options;
use Test::Smoke::App::HandleQueue;

my $commit = '9d4a846c758608a6297babf9582967e036edfa1f';
my $non_commit = '9d4a846c758608a6297babf9582967e036edfa20';
my $prefix = 'test-prefix';
my $tempdir = tempdir(CLEANUP => 1);
mkpath(my $adir = catdir($tempdir, 'log', $prefix), $ENV{TEST_VERBOSE});
my $qfile = catfile($tempdir, "${prefix}.qfile");

prepare_archive($adir, $commit);
prepare_queue($qfile, $commit, $non_commit);


{
    no warnings 'redefine';
    my $id = 42;
    local *Test::Smoke::Poster::Base::post = sub {
        my $self = shift;
        -e catfile($self->ddir, $self->jsnfile) or return;
        $id++;
    };
    local @ARGV = (
        '--qfile', $qfile,
        '--adir',  $adir,
        '--smokedb_url', 'http://localhost/report',
        '--poster' => 'HTTP::Tiny',
    );
    my $app = Test::Smoke::App::HandleQueue->new(
        Test::Smoke::App::Options->handlequeue_config
    );
    isa_ok($app, 'Test::Smoke::App::HandleQueue');

    open(my $qf, '<', $qfile) or die "Cannot open($qfile): $!";
    chomp(my @q = <$qf>);
    close($qf);
    is_deeply(\@q, [$commit, $non_commit], "Queue holds 2 items")
        or diag(explain(\@q));

    $Test::Smoke::LogMixin::USE_TIMESTAMP = 0;
    open(my $out, '>', \my $logfile);
    my $old_out = select($out);
    $app->run;
    select($old_out);

    is($logfile, <<"EOL", "Logfile ok");
Posted $commit from queue: report_id = 42
EOL

    is(-s $qfile, 0, "Queue is empty");
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();

sub prepare_archive {
    my ($adir, @commits) = @_;

    for my $commit (@commits) {
        my $report = catfile($adir, "jsn${commit}.jsn");
        open(my $fh, '>', $report) or next;
        print {$fh} qq[{"patch_level":"$commit"}];
        close($fh);
    }
}

sub prepare_queue {
    my ($qfile, @commits) = @_;
    open(my $qf, '>', $qfile) or die "Cannot create($qfile): $!";
    for my $commit (@commits) {
        print {$qf} "$commit\n";
    }
    close($qf);
}
