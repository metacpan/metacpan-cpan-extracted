use Test::More tests=>8;

use File::Spec;
use WWW::Mechanize::Pluggable;

my $mech = new WWW::Mechanize::Pluggable;
$mech->agent_alias("Mac Safari");

SKIP: {
  skip "No TMPDIR/TMP environment variable set", 8
    unless $ENV{TMPDIR} || $ENV{TMP};
  my $snapshot_dir = $mech->snapshots_to();
  ok $snapshot_dir, "got a default snapshot dir";
  my ($suffix) = ($snapshot_dir =~ /run_(.*)/);

  $mech->get($ENV{URL} || "http://xml.com");

  for (glob(File::Spec->catfile($snapshot_dir, "*.html"))) {
    unlink $_;
  }
  my @foo;
  my $location = $mech->snapshot("Home sweet home");
  is scalar (@foo = glob(File::Spec->catfile($snapshot_dir, "*.html"))), 2;
  is scalar (@foo = glob(File::Spec->catfile($snapshot_dir, "*.xml"))), 1;
  my $frame_filename_regex = File::Spec->catfile($ENV{TMP}, 'run_'.$suffix, 'frame_.*?.html');
  my $debug_filename = "debug_$suffix-1.html";
  my $content_filename = "content_$suffix-1.xml";

  like $location, qr{$frame_filename_regex}, "right frame name";

  open $frame, "<$location" or die "Can't open $location: $!";
  my @frame = <$frame>; 
  close $frame;

  my ($debug)   = grep { /debug_.*?\.html/ } @frame;
  my ($content) = grep { /content_.*?\.xml/ } @frame;

  is $debug, qq(<frame src="$debug_filename">\n), "good debug name";
  is $content, qq(<frame src="$content_filename">\n), "good content name";

  chdir $snapshot_dir;
  ($debug) = ($debug =~ /(debug.*?\.html)/);
  ($content) = ($content =~ /(content.*?\.xml)/);

  diag $debug unless ok -e $debug, "debug file matches link";
  diag $content unless ok -e $content, "content file matches link";
  system "rm -rf $snapshot_dir" unless $ENV{RETAIN};
}
