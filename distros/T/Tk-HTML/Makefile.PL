use vars qw($VERSION);
$VERSION = sprintf '3.%03d', q$Revision: #3$ =~ /\D(\d+)\s*$/;
use Tk::MMutil;

my @missing = ();

my $pkg;
foreach $pkg (qw(URI::URL HTML::Parse))
 {
  { eval "package dummy; require $pkg"; }
  push(@missing,$pkg) if ($@);
 }

if (@missing)
 {
  print "Following modules are required but not installed:\n",
        join("\n",@missing),"\n";
 }

Tk::MMutil::TkExtMakefile(
      'NAME'      => 'Tk::HTML',
      'VERSION'   => $VERSION,
      'EXE_FILES' => ['tkweb'],
#     'PREREQ'    => { URI::URL => 0, HTML::Parse => 0 },
      'linkext' => { LINKTYPE => ''},
      'dist'     => { COMPRESS => 'gzip -f9', SUFFIX => '.gz' },
      );


