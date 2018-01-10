use Test::More 0.96;
use Test::Snapshot;
use File::Temp qw/ tempfile tempdir /;
use Capture::Tiny qw(capture);

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

my ($exit);

(undef, undef, $exit) = capture {
  system qw(prove -b), $filename;
};
isnt $exit, 0, 'fails first time';

(undef, undef, $exit) = capture {
  local $ENV{TEST_SNAPSHOT_UPDATE} = 1;
  system $^X, qw(-S prove -b), $filename;
};
isnt $exit, 0, 'fails second time, snapshots were not created';

my ($out, $err);
($out, $err, $exit) = capture {
  local $ENV{TEST_SNAPSHOT_UPDATE} = 1;
  system qw(prove -b), $filename;
};
is $exit, 0, 'works third time, snapshots were created'
  or diag 'Output was: ', $out, 'Error was: ', $err;

done_testing;
