use Test::More tests=>3;

use File::Spec;
use WWW::Mechanize::Pluggable;
no warnings 'once';

my $mech = new WWW::Mechanize::Pluggable;
$mech->agent_alias("Mac Safari");

SKIP: {
  skip "No TMP/TMPDIR emnviroment variable", 3
    unless $ENV{TMP} || $ENV{TMPDIR};
  my $snapshot_dir = $mech->snapshots_to();
  ok $snapshot_dir, "got a default snapshot dir";

  $mech->get($ENV{URL} || "http://perl.org");
  for (glob(File::Spec->catfile($snapshot_dir, "*.html"))) {
    unlink $_;
  }
  my @foo;
  $mech->snapshot_comment("FOO BAR BAZ UNLIKELY");
  $mech->snapshot(undef,"foo");
  is scalar (@foo = glob(File::Spec->catfile($snapshot_dir, "*.html"))), 3;
  open GREP, File::Spec->catfile($snapshot_dir,"debug_foo-1.html")
    or die "can't open debug HTML file";
  my $hits;
  while (defined($_ = <GREP>)) { 
    $hits++ if /FOO BAR BAZ UNLIKELY/;
  }
  close GREP;
  is $hits, 1, "found expected comment";
  system "rm -rf $snapshot_dir" unless $ENV{RETAIN};
}
