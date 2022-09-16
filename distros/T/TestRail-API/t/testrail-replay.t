use strict;
use warnings;

use FindBin;

use lib $FindBin::Bin.'/../bin';
require 'testrail-replay';

use Test::More 'tests' => 6;
use Capture::Tiny qw{capture_merged};
use Test::Fatal;
use Test::MockModule;

my $utilmock = Test::MockModule->new('TestRail::Utils');
$utilmock->mock('getHandle', sub { bless({},"TestRail::API") } );
$utilmock->mock('parseConfig', sub { {} });
$utilmock->mock('interrogateUser', sub {} );

my $apimock = Test::MockModule->new('TestRail::API');
$apimock->mock('new', sub{ return bless({},shift) });
$apimock->mock('getProjectByName', sub { { id => 666 } });
$apimock->mock('getRunByName', sub { { id => 333 } });
$apimock->mock('getPlanByName', sub { { id => 222, config => 'BogusConfig' } } );
$apimock->mock('getChildRuns', sub { { [{ id => 111 }] } });
$apimock->mock('statusNamesToIds', sub { shift; shift eq 'failed' ? [5] : [4] });

$apimock->mock('getTests', sub {
    my ($self,$run_id) = @_;
    return [
        {
            'id' => 666,
            'title' => 'fake.test',
            'run_id' => $run_id
        }
    ];
});

$apimock->mock('getTestResults', sub {
    return [
        {
            'elapsed' => '1s',
            'status_id'  => 5
        },
        {
            'elapsed' => '2s',
            'status_id' => 4,
            'comment'   => 'zippy'
        }
    ];
});

#check doing things over all projects/plans/runs
my @args = qw{--apiurl http://testrail.local --user test@fake.fake -password fake argument1 };
my ($out, $code);
my $captured = capture_merged { ($out,$code) = TestRail::Bin::Replay::run('args' => \@args) };
subtest "Happy path" => sub {
    like($captured, qr/fake\.test \.\.\. ok/, "Expected output stream");
    like($out, qr/Done/,"Expected termination string");
    is($code,0,"OK Exit code");
};

@args = qw{--apiurl http://testrail.local --user test@fake.fake -password fake --plan argument1 };
$captured = capture_merged { ($out,$code) = TestRail::Bin::Replay::run('args' => \@args) };
subtest "Happy path - plan mode" => sub {
    like($captured, qr/fake\.test \.\.\. ok/, "Expected output stream");
    like($out, qr/Done/,"Expected termination string");
    is($code,0,"OK Exit code");
};

$apimock->mock('getTestResults', sub {
    return [
        {
            'elapsed' => '1s',
            'status_id'  => 5
        },
        {
            'elapsed' => '2s',
            'status_id' => 1,
            'comment'   => 'zippy'
        }
    ];
});

@args = qw{--apiurl http://testrail.local --user test@fake.fake -password fake --wait --plan argument1 };
$captured = capture_merged { ($out,$code) = TestRail::Bin::Replay::run('args' => \@args) };
subtest "Happy path - wait mode" => sub {
    like($captured, qr/fake\.test \.\.\. ok/, "Expected output stream");
    like($out, qr/Done/,"Expected termination string");
    is($code,0,"OK Exit code");
};

#Check help output
@args = qw{--help};
$0 = $FindBin::Bin.'/../bin/testrail-replay';
($out,(undef,$code)) = capture_merged {TestRail::Bin::Replay::run('args' => \@args)};
is($code, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");

#Make sure that the binary itself processes args correctly
$out = `$^X $0 --help`;
like($out,qr/encoding of arguments/i,"Appears we can run binary successfully");
