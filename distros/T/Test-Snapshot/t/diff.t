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

sub write_file {
  my ($filename, $data) = @_;
  open my $fh, '>', $filename or die "$filename: $!";
  print $fh $data;
}

$ENV{TEST_SNAPSHOT_UPDATE} = 0; # override to ensure known value

my $dir = tempdir( CLEANUP => 1 );
my $filename = tempcopy(<<'EOF', $dir);
use Test::More 0.96;
use Test::Snapshot;
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
  ($out, $err);
}

do_test($filename, 1, 1, 'fails first time, generate snapshots');
write_file($filename, <<'EOF');
use Test::More 0.96;
use Test::Snapshot;
is_deeply_snapshot { message => 'different' }, 'desc';
done_testing;
EOF
my ($out, $err) = do_test($filename, 0, 1, 'fails second time, check diffs');
isnt $out, '';
$err =~ s#^.* at .* line \d+\.$##m;
is $err, <<'EOF';

#   Failed test 'desc'

# @@ -1,3 +1,3 @@
#  {
# -  'message' => 'output'
# +  'message' => 'different'
#  }
# Looks like you failed 1 test of 1.
EOF

done_testing;
