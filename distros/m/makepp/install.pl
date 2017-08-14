#!/usr/bin/env perl
#
# This script asks the user the necessary questions for installing
# makepp and does some heavy HTML massageing.
#
# $Id: install.pl,v 1.122 2017/08/06 21:19:08 pfeiffer Exp $
#

package Mpp;

#
# First make sure this version of Perl is recent enough:
#
BEGIN { eval { require 5.008 } or exec $^X, 'config.pl' } # Dies with nice message.

BEGIN {
#
# Find the location of our data directory that contains the auxiliary files.
# This is normally built into the program by install.pl, but if makepp hasn't
# been installed, then we look in the directory we were run from.
#
  my $datadir = $0;		# Assume it's running from the same place that
				# we're running from.
  unless( $datadir =~ s@/[^/]+$@@ ) { # No path specified?
				# See if we can find ourselves in the path.
    foreach( split(/:/, $ENV{'PATH'}), '.' ) {
				# Add '.' to the path in case the user is
				# running it with "perl install.pl" even if
				# . is not in his path.
      if( -d "$_/Mpp" ) {	# Found something we need?
	$datadir = $_;
	last;
      }
    }
  }
  $datadir or die "install.pl: can't find library files\n";

  $datadir = eval "use Cwd; cwd . '/$datadir'"
    if $datadir =~ /^\./;	# Make it absolute, if it's a relative path.
  unshift @INC, $datadir;
}

use Config;
use Mpp::Text ();
use File::Copy;
use File::Path;
use Mpp::File ();		# ensure HOME is set

system PERL, 'makepp', '--version'; # make sure it got a chance to apply workarounds.

print "\nUsing perl in " . PERL . ".\n";
print "If you want another, please set environment variable PERL to it & reinstall.\n"
  unless $ENV{PERL};

warn "\nMakepp is being installed with DOS newlines, as you unpacked it.\n\n"
  if ($_ = <DATA>) =~ tr/\r//;

our $eliminate = '';		# So you can say #@@eliminate

our $VERSION = $Mpp::Text::VERSION;
our $setVERSION = "  our \$VERSION = '$Mpp::Text::VERSION';";
our $BASEVERSION = $Mpp::Text::BASEVERSION;

#
# Now figure out where everything goes:
#
sub ARGV_or_prompt($$) {
  local $_ = shift @ARGV;
  return $_ if defined && 0 < length;

  local $| = 1;			# Enable autoflush on STDOUT.

  my $default = ref( $_[1] ) ? $_[1]() : $_[1];
  print "$_[0] [$default]? ";	# Print the prompt.
  $_ = <STDIN>;			# Read a line.
  s/^\s+//;
  s/\s+$//;
  return $default unless defined && 0 < length;
#
# Expand environment variables and home directories.
#
  my $orig = $_;
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
  print "  -> $_\n" if $orig ne $_;
  $_;
}

$prefix = '/usr/local';

$bindir = ARGV_or_prompt '
Makepp needs to know where you want to install it and its data files.
Makepp is written in Perl, but there is no particular reason to install
any part of it in the perl hierarchy; you can treat it as you would a
compiled binary which is completely independent of perl.

The questions understand environment variables like $HOME, or ~ syntax.

Where should the makepp executable be installed',
  "$prefix/bin";

$bindir =~ m@^(.*)/bin@ and $prefix = $1;
				# See if a prefix was specified.

my $datadir = ARGV_or_prompt '
Makepp has a number of library files that it needs to install somewhere.  Some
of these are Perl modules, but they can\'t be used by other Perl programs, so
there\'s no point in installing them in the perl modules hierarchy; they are
simply architecture-independent data that needs to be stored somewhere.

Where should the library files be installed',
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

$mandir = ARGV_or_prompt '
Where should the manual pages be installed?
Enter \"none\" if you do not want the manual pages.
Man directory',
  sub { my $d = "$prefix/share/man"; -d $d ? $d : "$prefix/man" };
our $noman = $mandir eq 'none' ? 1 : '';

$htmldir_val = $htmldir = ARGV_or_prompt '
Where should the HTML documentation be installed?
Enter "none" if you do not want any documentation installed.
HTML documentation directory',
  sub { my $d = "$prefix/share/doc"; -d $d ? "$d/makepp" : "$datadir/html" };

my $findbin = ARGV_or_prompt "
Where should the library files be sought relative to the executable?
Enter \"none\" to seek in $datadir",
  "none";
$findbin=0 if $findbin eq "none";
if($findbin) {
  $setdatadir = "use FindBin;\n" .
    qq{\$datadir = "\$FindBin::RealBin/$findbin";};
  $htmldir = qq{\$FindBin::RealBin/$findbin/html}
    if $htmldir eq $datadir . "/html";
}

my $destdir = shift @ARGV;

my %abbrev;			# which commands have a short form

if( $destdir ) {
  for( $bindir, $datadir, $mandir, $htmldir_val ) {
    s/^/$destdir/o if defined;
  }
}

mkpath "$datadir/$_" for
  qw(Mpp Mpp/ActionParser Mpp/BuildCheck Mpp/CommandParser Mpp/Fixer Mpp/Scanner Mpp/Signature);

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
  local $SIG{__WARN__} = sub {};
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
  require './html/html.pl';		# fix what Pod::Html does
  &Mpp::html::pods2html;
}

#
# Install the man pages:
#
if( $mandir ne 'none' ) {
  my $gzip = </usr/{,local/,gnu/}{,share/}man/**/*.[1-9]*.gz> ? '.gz' : ''; # Does this OS gzip them?
  mkpath "$mandir/man1";
  require Pod::Man;
  my %options = qw(errors pod
		   center Makepp
		   lax 1);
  my $parser = Pod::Man->new( %options );
  $abbrev{makepp_build_cache} = 'mppbcc'; # special case command documented with feature description
  for my $file (@pods) {
    next if $file eq 'makepp_index.pod'; # html only
    my $basename = substr $file, 0, -4;   # Get the name of the man file.
    my $manfile = "$mandir/man1/$basename.1";
    $parser->parse_from_file( $file, $manfile );
    chmod 0644, $manfile;
    system 'gzip', '-f9', $manfile and $gzip = '' if $gzip;
    my $abbrev = $abbrev{$basename};
    link "$mandir/man1/$basename.1$gzip", "$mandir/man1/$abbrev.1$gzip" or
      symlink "$basename.1$gzip", "$mandir/man1/$abbrev.1$gzip" if $abbrev;
  }
  link "$mandir/man1/makepp_build_cache.1$gzip", "$mandir/man1/makepp_build_cache_control.1$gzip" or
    symlink "makepp_build_cache.1$gzip", "$mandir/man1/makepp_build_cache_control.1$gzip";
}

print "makepp successfully installed.\n";

#
# This subroutine makes a copy of an input file, substituting all occurrences
# of @xyz@ with the Perl variable $xyz.  It also fixes up the header line
# "#!/usr/bin/env perl" if it sees one.  On Win also create a .bat to call it.
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
  open INFILE, '<', $infile or die "$0: can't read file $infile--$!\n";
  mkpath($outdir);

  open OUTFILE, "> $outdir/$infile" or die "$0: can't write to $outdir/$infile--$!\n";

  local $_;
  my $perl = PERL;
  while( <INFILE> ) {
    s@^#!\s*(/usr/bin/env )perl@$perl =~ tr!/!! ? "#!$perl -w" : "#!$1$perl"@oe
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
    print $outfile "\@$perl $outdir/$infile %1 %2 %3 %4 %5 %6 %7 %8 %9\n";
    close $outfile;
  }
  if( $abbrev ) {
    $_ = $infile;
    {
      no warnings 'uninitialized';
      s/makepp(?:_?(.)[^_]+(?:_(.)[^_]+(?:_(.)[^_]+)?)?)?/mpp$1$2$3/;
    }
    $abbrev{$infile} = $_;
    link "$outdir/$infile", "$outdir/$_"
      or symlink $infile, "$outdir/$_";
    unless( -f "$outdir/$_" ) {
      copy "$outdir/$infile", "$outdir/$_";
      chmod $prot, "$outdir/$_";
    }
    copy "$outdir/$infile.bat", "$outdir/$_.bat" if is_windows > 0;
  }
}

__DATA__
Dummy line for newline test.
