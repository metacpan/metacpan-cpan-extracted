use Test::More tests=>3;

use File::Spec;
use WWW::Mechanize::Pluggable;

my $mech = new WWW::Mechanize::Pluggable;
$mech->agent_alias("Mac Safari");

SKIP: {
  skip "No TMPDIR/TMP environment variable set", 3
    unless $ENV{TMPDIR} || $ENV{TMP};
  my $snapshot_dir = $mech->snapshots_to();
  ok $snapshot_dir, "got a default snapshot dir";

  $mech->get($ENV{URL} || "http://perl.org");
  for (glob(File::Spec->catfile($snapshot_dir, "*.html"))) {
    unlink $_;
  }
  my @foo;
  $mech->snapshot("Home sweet home");
  is scalar (@foo = glob(File::Spec->catfile($snapshot_dir, "*-?.html"))), 3;

  $mech->snapshot("Zorch sweet zorch", "zorch");
  is scalar (@foo = glob(File::Spec->catfile($snapshot_dir, "*zorch-?.html"))), 3;
  system "rm -rf $snapshot_dir" unless $ENV{RETAIN};
}
