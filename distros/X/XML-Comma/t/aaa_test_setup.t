# aaa_test_setup.t : do any global stuff that needs to happen for
# tests to get run.

use strict;

use Test::More 'no_plan';
#TODO: more tests, convert shell to perl

my $active_configuration_pm;
#note we haven't overridden lib, so we'll get the active Configuration.pm
eval { require XML::Comma::Configuration; }; if($@) {
  $active_configuration_pm = "lib/XML/Comma/Configuration.pm";
  do "lib/XML/Comma/Configuration.pm";
} else {
  $active_configuration_pm = $INC{"XML/Comma/Configuration.pm"};
}

use File::Path;
use File::Copy;
use File::Find;
use Cwd;

rmtree(".test");
#TODO: replace this with perl
`cp -RPpf blib .test`; #like cp -a but works on *bsd, macosx too
#copy active Configuration.pm in place if it exists
if($active_configuration_pm) {
  unlink(".test/lib/XML/Comma/Configuration.pm");
  copy($active_configuration_pm, ".test/lib/XML/Comma/Configuration.pm") || die "can't install temporary copy of Configuration.pm - copy - $!";
}
chmod(0644, ".test/lib/XML/Comma/Configuration.pm");

my $build_root_dir = getcwd();

#read in the config
my $CONFIG_FILE = ".test/lib/XML/Comma/Configuration.pm";
open(F, $CONFIG_FILE) || die "can't open $CONFIG_FILE for reading: $!";
my @conf = <F>;
close(F);

#TODO: do this by eval'ing Configuration.pm or something instead...
my @t = grep(/^\s*comma_root/, grep(/^[^\#]/, @conf));
die "unable to determine your comma_root" if($#t);
my $comma_root = $t[0];
$comma_root =~ s/^.*?comma_root\s*=>\s*//;
$comma_root =~ s/^['"]//;
$comma_root =~ s/['"].*//;
chomp($comma_root);
mkpath(".test/$comma_root");
open(F, ">.test/$comma_root/log.comma") || die "can't open log.comma for writing: $!";
print F time." -- beginning test log\n";
close(F);

$CONFIG_FILE =~ s/^/$build_root_dir\//;
$CONFIG_FILE =~ s/\/\/+/\//g;
#write a dummy config file
open(F, ">$CONFIG_FILE") || die "can't open $CONFIG_FILE for writing: $!";
my $i = 0;
my $defs_directories_pos = -1;
my @defs_dirs = ();
while($i < $#conf) {
  my $line = $conf[$i];
  #change most everything to be relative to "$build_root_dir/.test"
  if($line =~ /^\s*(comma_root|log_file|document_root|sys_directory)\s+/) {
    $line =~ s/=>(\s+)([\'\"])/=>$1$2$build_root_dir\/.test\//;
    $line =~ s/\/\/+/\//g;
  }
  if($defs_directories_pos == -1) {
    if($line =~ /^\s*defs_directories/) {
      ++$defs_directories_pos;
    }
  }
  if($defs_directories_pos == 0) {
    push @defs_dirs, $line;
    if($line =~ /^\s*\]\s*\,\s*$/) {
      ++$defs_directories_pos;
    }
  }
  if($defs_directories_pos == 1) {
    my $code_string = join("", @defs_dirs);
    $code_string =~ s/^\s*defs_directories\s*=>//s;
    my $dh = eval $code_string;
    die "error executing defs_directories: $code_string: $@\n" if($@);
    my @dd = map { s/^/$build_root_dir\/.test\//; s/\/\/+/\//g; $_ } @$dh;
    print F "defs_directories =>\n";
    print F "\t[\n";
    print F join("\n", map { "\t\t'$_'," } @dd);
    print F "\n\t],\n";
    ++$defs_directories_pos;
    ++$i;
    @defs_dirs = @dd;
    next;
  }
  print F $line if($defs_directories_pos != 0);
  $i++;
}
close(F);
chmod(0640, $CONFIG_FILE) || warn "can't chmod $CONFIG_FILE: $!";
mkdir(".test/tmp", 0777); #comma_standard_image.t needs this

#note: just dump all defs into the first defs dir in our tmp Configuration.pm
my $d = $defs_dirs[0];
mkpath($d, 0, 0755);
#note, File::Find is in core, but it's hairy. this accomplishes the same:
#`find t/defs -type f -exec cp -f \{\} "$d" \\;`;
find( { wanted => sub { my $f = $_; ( $File::Find::dir !~ /\.svn/ ) && 
            ( -f $f ) && copy($f, $d) } }, "t/defs" );

ok("dummy");
