use Test::More tests=>5;

use File::Spec;
use WWW::Mechanize::Pluggable;

my $mech = new WWW::Mechanize::Pluggable;
$mech->agent_alias("Mac Safari");
$mech->snap_prefix("http://myserver.com/snap");

SKIP: {
  skip "No TMPDIR/TMP environment variable set", 5
    unless $ENV{TMPDIR} || $ENV{TMP};
  my $snapshot_dir = $mech->snapshots_to();
  ok $snapshot_dir, "got a default snapshot dir";

  $mech->get($ENV{URL} || "http://perl.org");
  for (glob(File::Spec->catfile($snapshot_dir, "*.html"))) {
    unlink $_;
  }
  my @foo;
  my $location = $mech->snapshot("Home sweet home");
  is scalar (@foo = glob(File::Spec->catfile($snapshot_dir, "*-?.html"))), 3;
  like $location, qr{http://myserver.com/snap/run_.*?/frame_.*?.html$}, "right name";

  $location = $mech->snapshot("Zorch sweet zorch", "zorch");
  is scalar (@foo = glob(File::Spec->catfile($snapshot_dir, "*zorch-?.html"))), 3;
  like $location, qr{http://myserver.com/snap/run_.*?/frame_.*?.html$}, "right name";
  system "rm -rf $snapshot_dir" unless $ENV{RETAIN};
}
