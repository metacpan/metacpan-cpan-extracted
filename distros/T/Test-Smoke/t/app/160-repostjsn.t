#! perl -w
use strict;

use Test::More;
use Test::NoWarnings ();

use File::Temp 'tempfile';
use Test::Smoke::App::RepostFromArchive;
use Test::Smoke::App::Options;
use Test::Smoke::Util::FindHelpers 'get_avail_posters';

my @reports = qw(
    jsn7a29e8d2c80588346422b4b6b936e6f8b56a3af4.jsn
    jsn69bc7167fa24b1e8d3f810ce465d84bdddf413f6.jsn
    jsn71ce8c74528f69acac1ccbb56b5cc3d20ddba7dd.jsn
    jsncbc5b6f1526f9eb657d61241e54b383c2d053b44.jsn
    jsn8a4b911d06671a03e21054142ab2c27b15d5fd3e.jsn
    jsne91a97a6c44e190cf576e37ff52bd8bd7005cf73.jsn
    jsn30a06d3ba862b55a05a8f9aba8e03e81e1823235.jsn
    jsne7d4e29a2b93523d790643d965e3e1c233af71b7.jsn
    jsnbded974f30650c2002b7abfdf8555531ecbfac81.jsn
    jsnbf2a3dae9f4f828fd1f2f8aaf4769f96520c9552.jsn
    jsn29b290ccaa79f40de7d941c9a79810119f5c6363.jsn
);

my $poster = (get_avail_posters())[0] || 'HTTP::Tiny';
note("using poster: $poster");

{
    my $last_report = $#reports;

    no warnings 'redefine';
    my $counter = 42;
    local *Test::Smoke::Poster::Base::post = sub {
        return $counter++;
    };
    local *Test::Smoke::App::RepostFromArchive::pick_reports = sub {
        return @reports[0..$last_report];
    };
    local @ARGV = (
        '--adir'        => 't/perl',
        '--smokedb_url' => 'http://localhost:3030/report',
        '--poster'      => $poster,
        '--verbose'     => 1,
    );
    my $app = Test::Smoke::App::RepostFromArchive->new(
        Test::Smoke::App::Options::reposter_config(),
    );
    isa_ok($app, 'Test::Smoke::App::RepostFromArchive');

    my $smokedb_url = $app->option('smokedb_url');
    is($smokedb_url, 'http://localhost:3030/report', "Got the url from command line");

    local $Test::Smoke::LogMixin::USE_TIMESTAMP = 0;
    my $buffer;
    {
        local *STDOUT;
        open STDOUT, '>>', \$buffer;
        $last_report = 0;
        $app->run;
    }
    like(
        $buffer,
        qr{^Reposting '$reports[0]' to $smokedb_url\nReport posted with id: 42},
        "logfile looks ok"
    );

    $buffer = "";
    {
        local *STDOUT;
        open STDOUT, '>>', \$buffer;
        $last_report = $#reports;
        $app->run;
    }
    my @log_lines = split(/\n/, $buffer);
    is(scalar(@log_lines), 2 * @reports, "Correct number of loglines");
    like(
        $buffer,
        qr{Reposting '$reports[-1]' to $smokedb_url\nReport posted with id: 53$},
        "big logfile tail looks ok"
    );
}

{
    my $last_report = $#reports;

    no warnings 'redefine';
    my $counter = 42;
    local *Test::Smoke::Poster::Base::post = sub {
        return $counter++;
    };
    local *Test::Smoke::App::RepostFromArchive::fetch_jsn_from_archive = sub {
        my %entries;
        my $i = 0;
        for my $report (@reports) {
            $entries{ $report } = {
                mtime    => time() - 3600 * $i++,
                fullname => "t/perl/$report",
            };
        }
        return \%entries;
    };

    my @commits = map {
        (my $sha = $_) =~ s{^jsn ([0-9a-f]+) \.jsn $}{$1}x;
        $sha
    } @reports[3..7];
    local @ARGV = (
        '--adir'        => 't/perl',
        '--smokedb_url' => 'http://localhost:3030/report',
        '--poster'      => $poster,
        '--verbose'     => 1,
        map { ('--sha', $_) } @commits,
    );
    my $app = Test::Smoke::App::RepostFromArchive->new(
        Test::Smoke::App::Options::reposter_config(),
    );
    isa_ok($app, 'Test::Smoke::App::RepostFromArchive');

    my @selected = $app->pick_reports();
    is(scalar(@selected), 5, "Passed reports via command line");
}

{
    my ($fh, $single_json) = tempfile();
    note("testing --jsonreport $single_json");
    print {$fh} "{}";
    close($fh);

    no warnings 'redefine';
    my $counter = 42;
    local *Test::Smoke::Poster::Base::post = sub {
        return $counter++;
    };
    local @ARGV = (
        '--smokedb_url' => 'http://localhost:3030/report',
        '--poster'      => $poster,
        '--jsonreport'  => $single_json,
        '--verbose'     => 1,
    );
    my $app = Test::Smoke::App::RepostFromArchive->new(
        Test::Smoke::App::Options::reposter_config(),
    );
    isa_ok($app, 'Test::Smoke::App::RepostFromArchive');

    my @selected = $app->pick_reports();
    is(scalar(@selected), 1, "Passed reports via command line");
    is($selected[0], $single_json, "Correct file-name");

    local $Test::Smoke::LogMixin::USE_TIMESTAMP = 0;
    my $buffer = '';
    {
        local *STDOUT;
        open STDOUT, '>>', \$buffer;
        $app->run;
    }
    my $remote = $app->option('smokedb_url');
    like(
        $buffer,
        qr{^Reposting '\Q$single_json\E' to \Q$remote\E}m,
        "Log: Reposter line"
    );
    like(
        $buffer,
        qr{^Report posted with id: 42}m,
        "Log: Report id ok"
    );

    is($counter, 43, "Posted a single json");
    unlink($single_json);
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();
