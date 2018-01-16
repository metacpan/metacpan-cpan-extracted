use Test::More 0.96;
use Test::Snapshot;
use File::Temp qw/ tempfile tempdir /;
use Capture::Tiny qw(capture);
use App::Prove;

sub tempcopy {
  my ($text, $dir) = @_;
  my ($tfh, $filename) = tempfile( DIR => $dir );
  print $tfh $text;
  close $tfh;
  $filename;
}

$ENV{TEST_SNAPSHOT_UPDATE} = 0; # override to ensure known value

my $dir = tempdir( CLEANUP => 1 );
my $filename = tempcopy(<<'EOF', $dir);
use Test::More 0.96;
use Test::Snapshot;

subtest 'subtestname' => sub {
  is_deeply_snapshot 'just some text', 'subtest desc';
};

is_deeply_snapshot { message => 'output' }, 'desc';

done_testing;
EOF

sub do_test {
  my ($filename, $update, $expect, $description) = @_;
  my ($out, $err, $exit) = capture {
    local $ENV{TEST_SNAPSHOT_UPDATE} = $update;
    my $app = App::Prove->new;
    $app->process_args(qw(-b), $filename);
    $app->run ? 0 : 1;
  };
  is $exit, $expect, $description
    or diag 'Output was: ', $out, 'Error was: ', $err;
}

do_test($filename, '', 1, 'fails first time');
do_test($filename, 1, 1, 'fails second time, snapshots were not created');
do_test($filename, 1, 0, 'works third time, snapshots were created');

done_testing;
