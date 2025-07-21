use Test2::V0;

use WebService::OurWorldInData::Chart;

BEGIN {
    $ENV{ LWP_UA_MOCK } ||= 'playback';
    $ENV{ LWP_UA_MOCK_FILE } ||= __FILE__.'-lwp-mock.out';
}

use Test2::Require::Module 'Archive::Extract';
use Test2::Require::Module 'LWP::UserAgent::Mockable';

my $dataset = 'sea-surface-temperature-anomaly';
my $ua    = LWP::UserAgent->new;
$ua->agent('WebService::OurWorldInData-test/0.1');

my $chart = WebService::OurWorldInData::Chart->new( chart => $dataset, ua => $ua );

subtest 'download and extract zipped package' => sub {
    ok my $result = $chart->zip, 'Get zipped package';

    my $filename = join '.', $dataset, 'zip';
    open my $fh, '>:raw', $filename
        or warn "Can't open $filename: $!\n", return;
    print $fh $result; # write the binary file
    close $fh;

    my $ae = Archive::Extract->new( archive => $filename );
    ok $ae->extract or diag $ae->error;
    my $files = $ae->files;
    is $files, [ "$dataset.metadata.json", "$dataset.csv", 'readme.md'], 'Files there';

    unlink $filename, @$files;
};

done_testing();

END {
    # END block ensures cleanup if script dies early
    LWP::UserAgent::Mockable->finished;
}
