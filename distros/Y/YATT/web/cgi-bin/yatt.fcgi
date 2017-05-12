#!/usr/bin/perl -Tw
use 5.006;
use strict;
use warnings qw(FATAL all NONFATAL misc);

#----------------------------------------
# Path setup.

use File::Basename; # require is not ok for fileparse.
use File::Spec; # require is not ok for rel2abs

# pathname without extension.
sub rootname {
  my ($basename, $dirname, $suffix) = fileparse(@_);
  join "/", File::Spec->rel2abs($dirname), $basename;
}

sub untaint_anything {
  $1 if defined $_[0] && $_[0] =~ m{(.*)}s;
}

sub catch (&@) {
  my ($sub, $errorVar) = @_;
  eval { $sub->() };
  $$errorVar = $@;
}

sub breakpoint_run {}

sub prog_libdirs {
  my ($prog) = @_;
  my $root = rootname($prog, qr{\.\w+});
  my @libs;
  if (-d (my $d = "$root.lib")) {
    push @libs, $d;
  }
  if (-d (my $d = "$root.libs")) {
    local *DIR;
    if (opendir DIR, $d) {
      push @libs,
	map  { "$d/$$_[1]" }
	sort { $$a[0] <=> $$b[0] }
	map  { /^(\d+)/ ? [$1, $_] : () }
	  readdir(DIR);
      closedir DIR;
    }
  }
  map {untaint_anything($_)} @libs;
}

use lib prog_libdirs(__FILE__);

use YATT;

#----------------------------------------
if ($0 =~ /\.fcgi$/) {
  my $age = -M $0;
  my $load_error;
  if (catch {require FCGI} \$load_error) {
    # To avoid "massive (die -> restart) ==> restartDelay" blocking.
    print "\n\n$load_error";
    while (sleep 3) {
      last if -M $0 < $age;
    }
    exit 1;
  }
  elsif (catch {require YATT::Toplevel::FCGI} \$load_error) {
    # This too.
    my $req = FCGI::Request();
    while ($req->Accept >= 0) {
      print "\n\n$load_error";
      last if -M $0 < $age;
    }
    exit 1;
  }
  else {
    YATT::Toplevel::FCGI->run;
  }
}
elsif ($ENV{LOCAL_COOKIE}) {
  # For w3m
  die "w3m mode is not yet implemented.";
}
else {
  # For normal CGI
  my $class = 'YATT::Toplevel::CGI';
  if ($ENV{SERVER_SOFTWARE}) {
    eval "require $class";
    if (my $load_error = $@) {
      print "\n\n$load_error";
      exit 1;
    }
    else {
      breakpoint_run;
      $class->run(cgi => @ARGV);
    }
  }
  else {
    my $sub = eval qq{sub {require $class}};
    $sub->();
    ($class . "::Batch")->run(files => @ARGV);
  }
}
