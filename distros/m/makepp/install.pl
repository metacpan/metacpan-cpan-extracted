#!/usr/bin/perl -w
#
# This script asks the user the necessary questions for installing
# makepp and does some heavy HTML massageing.
#
# $Id: install.pl,v 1.114 2012/07/05 21:55:13 pfeiffer Exp $
#

package Mpp;

#
# First make sure this version of Perl is recent enough:
#
eval { require 5.008; 1 } or
  die "I need Perl version 5.8 or newer.  If you have it installed somewhere
already, run this installation procedure with that perl binary, e.g.,

	perl5.14.1 install.pl ...

If you don't have a recent version of Perl installed (what kind of system are
you on?), get the latest from www.perl.com and install it.
";

use Config;
use File::Copy;
use File::Path;
use Mpp::Text ();
use Mpp::File ();		# ensure HOME is set

system $^X, 'makepp', '--version'; # make sure it got a chance to apply workarounds.

print 'Using perl in ' . PERL . ".\n";

warn "\nMakepp will be installed with DOS newlines, as you unpacked it.\n\n"
  if ($_ = <DATA>) =~ tr/\r//d;

our $eliminate = '';		# So you can say #@@eliminate

our $BASEVERSION = $Mpp::Text::BASEVERSION;

#
# Now figure out where everything goes:
#
$prefix = "/usr/local";

$bindir = shift(@ARGV) ||
  read_with_prompt("
Makepp needs to know where you want to install it and its data files.
makepp is written in Perl, but there is no particular reason to install
any part of it in the perl hierarchy; you can treat it as you would a
compiled binary which is completely independent of perl.

Where should the makepp executable be installed [$prefix/bin]? ") ||
  "$prefix/bin";

$bindir =~ m@^(.*)/bin@ and $prefix = $1;
				# See if a prefix was specified.

my $datadir = shift @ARGV || read_with_prompt("
Makepp has a number of library files that it needs to install somewhere.  Some
of these are Perl modules, but they can't be used by other Perl programs, so
there's no point in installing them in the perl modules hierarchy; they are
simply architecture-independent data that needs to be stored somewhere.

Where should the library files be installed [$prefix/share/makepp]? ") ||
  "$prefix/share/makepp";
our $setdatadir;
if ($datadir !~ /^\//) {	# Make a relative path absolute.
  use Cwd;
  my $cwd = cwd;
  chdir $datadir;
  $setdatadir = "\$datadir = '" . cwd . "';";
  chdir $cwd;
} else {
  $setdatadir = "\$datadir = '$datadir';";
}

# deprecated prior installation may not have supported .makepp/*.mk files
-r "$datadir/FileInfo_makepp.pm" and
  (stat "$datadir/FileInfo_makepp.pm")[9] < 1102710870 || # check-in time
  do {
    my $found;
    open F, "$datadir/FileInfo_makepp.pm";
    while( <F> ) {
      $found = 1, last if /build_info_subdir.+\.mk/;
    }
    !$found;
  } and
  print '
Warning: the names of the metainformation files under .makepp have changed
with regard to your old installation of makepp.  Every user must issue the
following command at the tops of their build trees, to prevent the new makepp
from rebuilding everything.  Or sysadmins installing this version can issue
the command for the whole machine from the root directory.

  find `find . -name .makepp` -type f | xargs -i mv {} {}.mk

';

$mandir = shift @ARGV || read_with_prompt("
Where should the manual pages be installed?
Enter \"none\" if you do not want the manual pages.
Man directory [$prefix/man]: ") ||
  "$prefix/man";
our $noman = $mandir eq 'none' ? 1 : '';

$htmldir = shift @ARGV || read_with_prompt("
Where should the HTML documentation be installed?
Enter \"none\" if you do not want any documentation installed.
HTML documentation directory [$prefix/share/makepp/html]: ") ||
  "$prefix/share/makepp/html";
$htmldir_val = $htmldir;

my $findbin = shift @ARGV;
defined($findbin) or $findbin = read_with_prompt("
Where should the library files be sought relative to the executable?
Enter \"none\" to seek in $datadir [none]: ") || "none";
$findbin=0 if $findbin eq "none";
if($findbin) {
  $setdatadir = "use FindBin;\n" .
    qq{\$datadir = "\$FindBin::RealBin/$findbin";};
  $htmldir = qq{\$FindBin::RealBin/$findbin/html}
    if $htmldir eq $datadir . "/html";
}

my $destdir = shift @ARGV;

if( $destdir ) {
  for( $bindir, $datadir, $mandir, $htmldir_val ) {
    s/^/$destdir/o if defined;
  }
}

mkpath "$datadir/$_" for
  qw(Mpp Mpp/ActionParser Mpp/BuildCheck Mpp/CommandParser Mpp/Fixer Mpp/Scanner Mpp/Signature);

our $useoldmodules = '';
if( $ENV{MAKEPP_INSTALL_OLD_MODULES} ) {
  warn "MAKEPP_INSTALL_OLD_MODULES is deprecated.\n";
  my %packages =		# The renamed or multipackage cases.
   (BuildCache => [qw(BuildCache BuildCache BuildCache::Entry)],
    FileInfo => ['FileInfo=File'],
    FileInfo_makepp => [qw(FileInfo_makepp=FileOpt FileInfo_makepp=File)],
    Makecmds => ['Makecmds=Cmds'],
    MakeEvent =>
      [qw(MakeEvent=Event MakeEvent=Event MakeEvent::Process=Event::Process MakeEvent::WaitingSubroutine=Event::WaitingSubroutine)],
    Makesubs => ['Makesubs=Subs'],
    Rule => [qw(Rule Rule DefaultRule DefaultRule::BuildCheck)],
    TextSubs => ['TextSubs=Text']);
  for $module ( split ' ', $ENV{MAKEPP_INSTALL_OLD_MODULES} ) {
    $useoldmodules .= "use $module ();\n"
      if $module =~ s/\+//;
    $module = $packages{$module} || [$module]; # Create simple cases on the fly.
    my( $old, $new ) = shift @$module;
    $new = ($old =~ s/=(.+)//) ? $1 : $old;
    my $file = $old;
    if( $file =~ s!(.+)::!$1/! ) {
      -d "$datadir/$1" or mkpath "$datadir/$1";
    }
    open my $fh, '>', "$datadir/$file.pm" or die "can't create $old.pm\n";
    print $fh "# generated backwards compatibility wrapper\nuse Mpp::$new;\n";
    for( @$module ? @$module : "$old=$new" ) {
      $new = (s/=(.+)//) ? $1 : $_;
      print $fh "%${_}:: = %Mpp::${new}::;\n";
    }
    print $fh '1;';
  }
}

$ENV{_MAKEPP_INSTALL} = 1;
substitute_file( $_, $bindir, 0755, 1 ) for
  qw(makepp makeppbuiltin makeppclean makeppgraph makeppinfo makepplog makeppreplay makepp_build_cache_control);

substitute_file( 'recursive_makepp', $datadir, 0755 );

substitute_file( 'Mpp/Text.pm', $datadir, 0644 );

foreach $module (qw(../Mpp

		    BuildCache BuildCacheControl Cmds Event File FileOpt Glob
		    Lexer Makefile Subs Repository Rule Utils

		    BuildCheck BuildCheck/architecture_independent
		    BuildCheck/exact_match BuildCheck/ignore_action
		    BuildCheck/only_action BuildCheck/target_newer

		    CommandParser CommandParser/Esql CommandParser/Gcc
		    CommandParser/Swig CommandParser/Vcs

		    Fixer/Automake Fixer/CMake

		    ActionParser/Legacy ActionParser/Specific

		    Scanner Scanner/C Scanner/Esqlc Scanner/Swig Scanner/Vera
		    Scanner/Verilog

		    Signature Signature/c_compilation_md5 Signature/md5
		    Signature/shared_object Signature/verilog_synthesis_md5
		    Signature/xml Signature/xml_space)) {
  copy("Mpp/$module.pm", "$datadir/Mpp/$module.pm");
  chmod 0644, "$datadir/Mpp/$module.pm";
}

our $explicit_perl = '';
{
  local $SIG{__WARN__}= sub {};
  $explicit_perl = "Mpp::PERL . ' ' ."
    if $destdir || system "$bindir/makeppinfo -qknone makepp"; # zero if executable, output nothing
}

substitute_file( 'Mpp/Recursive.pm', $datadir, 0644 );

foreach $include (qw(makepp_builtin_rules makepp_default_makefile)) {
  copy("$include.mk", "$datadir/$include.mk");
  chmod 0644, "$datadir/$include.mk";
}

#
# From here on we treat the pod files
#
chdir 'pod';

@pods = <*.pod>;

#
# Now massage and install the HTML pages.
#
if( $htmldir_val ne 'none' ) {
  {
    no warnings;
    @Mpp::html::pods = @pods;
    my $absre = is_windows ? qr/^\/|^[a-z]:/i : qr/^\//; # compensate chdir pod above
    $Mpp::html::target_dir = $htmldir_val =~ $absre ? $htmldir_val : "../$htmldir_val";
  }
  require 'html/html.pl';		# fix what Pod::Html does
  &Mpp::html::pods2html;
}

#
# Install the man pages:
#
if( $mandir ne 'none' ) {
  mkpath "$mandir/man1";
  require Pod::Man;
  my %options = qw(errors pod
		   center Makepp
		   lax 1);
  my $parser = Pod::Man->new( %options );
  for my $file (@pods) {
    next if $file eq 'makepp_index.pod'; # html only
    my $manfile = $file;
    $manfile =~ s/\.pod$/.1/;   # Get the name of the man file.
    $parser->parse_from_file( $file, "$mandir/man1/$manfile" );
    chmod 0644, "$mandir/man1/$manfile";
  }
}

print "makepp successfully installed.\n";

#
# This subroutine makes a copy of an input file, substituting all occurrences
# of @xyz@ with the Perl variable $xyz.  It also fixes up the header line
# "#!/usr/bin/perl" if it sees one.  On Win also create a .bat to call it.
#
# Arguments:
# a) The input file.
# b) The output directory.
# c) The protection to give the file when it's installed.
# d) Create an mpp* abbreviation.
#
sub substitute_file {
  my ($infile, $outdir, $prot, $abbrev) = @_;

  local *INFILE;
  open INFILE, $infile or die "$0: can't read file $infile--$!\n";
  mkpath($outdir);

  open OUTFILE, "> $outdir/$infile" or die "$0: can't write to $outdir/$infile--$!\n";

  local $_;
  my $perl = PERL;
  while( <INFILE> ) {
    s@^\#!\s*(\S+?)/perl(\s|$)@\#!$perl$2@o	# Handle #!/usr/bin/perl.
       if $. == 1;
    s/\\?\@(\w+)\@/$$1/g;		# Substitute anything containg @xyz@.
    if( /^#\@\@(\w+)/ ) {		# Substitute anything containg #@@xyz ... #@@
      1 until substr( <INFILE>, 0, 3 ) eq "#\@\@";
      $_ = $$1;
    }

    print OUTFILE $_;
    open INFILE, "$perl $infile --help |" # '-|' no good on Win AS
      if $abbrev && /__DATA__/;
  }
  close OUTFILE;
  close INFILE;

  chmod $prot, "$outdir/$infile";
  if( is_windows > 0 && $prot == 0755 ) {
    open my $outfile, "> $outdir/$infile.bat" or die "$0: can't write to $outdir/$infile.bat--$!\n";
    print $outfile '@' . PERL . " $outdir/$infile %1 %2 %3 %4 %5 %6 %7 %8 %9\n";
    close $outfile;
  }
  if( $abbrev ) {
    $_ = $infile;
    {
      no warnings 'uninitialized';
      s/makepp(?:_?(.)[^_]+(?:_(.)[^_]+(?:_(.)[^_]+)?)?)?/mpp$1$2$3/;
    }
    link "$outdir/$infile", "$outdir/$_"
      or symlink "$outdir/$infile", "$outdir/$_";
    unless( -f "$outdir/$_" ) {
      copy "$outdir/$infile", "$outdir/$_";
      chmod $prot, "$outdir/$_";
    }
    copy "$outdir/$infile.bat", "$outdir/$_.bat" if is_windows > 0;
  }
}

sub read_with_prompt {
  local $| = 1;			# Enable autoflush on STDOUT.

  print @_;			# Print the prompt.
  $_ = <STDIN>;			# Read a line.
  chomp $_;
#
# Expand environment variables and home directories.
#
  s/\$(\w+)/$ENV{$1}/g;		# Expand environment variables.
  if (s/^~(\w*)//) {		# Is there a ~ expansion to do?
    if ($1 eq '') {
      $_ = "$ENV{HOME}$_";
    } else {
      my ($name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell) = getpwnam($1);
				# Expand from the passwd file.
      if ($dir) {		# Found it?
	$_ = "$dir$_";
      } else {
	$_ = "~$1";		# Not found.  Just put the ~ back.
      }
    }
  }
  $_;
}
__DATA__
Dummy line for newline test.
