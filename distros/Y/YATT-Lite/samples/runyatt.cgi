#!/usr/bin/perl -T
#!/usr/bin/perl -w
package main; # For do 'runyatt.cgi'.
use strict;
use warnings qw(FATAL all NONFATAL misc);
use sigtrap die => qw(normal-signals);
use FindBin;

#----------------------------------------
# Ensure ENV, for mod_fastcgi+FCGI.pm and Taint check.
$ENV{PATH} = "/sbin:/usr/sbin:/bin:/usr/bin";

#----------------------------------------
# To allow do 'runyatt.cgi', we should avoid using FindBin.
my $untaint_any; BEGIN { $untaint_any = sub { $_[0] =~ m{.*}s; $& } }
# To avoid redefinition of sub rootname.
my ($get_rootname, $get_extname);
BEGIN {
  $get_rootname = sub { my $fn = shift; $fn =~ s/\.\w+$//; join "", $fn, @_ };
  $get_extname = sub { my $fn = shift; $fn =~ s/\.(\w+)$// and $1 };
}
use Cwd qw(realpath);
use File::Spec;
my $app_root;
my $rootname;
my @libdir;
BEGIN {
  $app_root = $untaint_any->(File::Spec->rel2abs(__FILE__));
  $app_root =~ s{/html/cgi-bin/.*}{};
  $rootname = $get_rootname->($untaint_any->(realpath(__FILE__)));
  if (-d "$app_root/lib/YATT") {
    push @libdir, "$app_root/lib";
  }
  if (defined $rootname and -d $rootname) {
    push @libdir, "$rootname.lib";
  } elsif (my ($found) = $FindBin::Bin =~ m{^(.*?)/YATT/}) {
    push @libdir, $found;
  } 
  unless (@libdir) {
    warn "Can't find libdir".(defined $app_root ? ", app_root=$app_root" : "");
  }
  if (-d (my $dn = "$app_root/extlib")) {
    push @libdir, $dn;
  }
}
use lib @libdir;

#
use YATT::Lite::Breakpoint;
use YATT::Lite::WebMVC0::SiteApp -as_base;

#----------------------------------------
my @opts;
for (; @ARGV and $ARGV[0] =~ /^--(\w+)(?:=(.*))?/s; shift @ARGV) {
  push @opts, $1, defined $2 ? $2 : 1;
}

#----------------------------------------
# To customize, edit app.psgi or app.yml.

my $dispatcher = MY->load_psgi_script("$app_root/app.psgi");

if (caller) {
  # For do 'runyatt.cgi'.
  return $dispatcher;
} else {
  $dispatcher->runas($get_extname->($0), \*STDOUT, \%ENV, \@ARGV
		     , progname => __FILE__);
}
