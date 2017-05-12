#!/usr/bin/perl

# propagate version numbers

use Cwd;
BEGIN {
  unshift @INC, "./lib";
  eval { require VOMS::Lite; };
}
use File::Find;
my $dir=getcwd;

print "About to change Version to $VOMS::Lite::VERSION\n";

find(\&wanted, "$dir/lib/VOMS/Lite");

sub wanted { 
  if (/\.pm$/) { 
    print "$File::Find::name"; 
    open (OLD,"<$File::Find::name")        or die "couldn't open $File::Find::name for reading";
    open (NEW,">$File::Find::name".".new")  or die "couldn't open $File::Find::name for writing";
    my $OK=0;
    while (<OLD>) {
      s/^\s*\$VERSION\s*=\s*'[^']*';\s*$/\$VERSION = '$VOMS::Lite::VERSION';\n/;
      if ( m/VERSION = '$VOMS::Lite::VERSION'/ ) { $OK=1; }
      print NEW $_;
    }
    close OLD;
    close NEW;
    print (($OK==1)?" [  OK  ]\n":" [ FAIL ]\n");
    rename "$File::Find::name".".new", "$File::Find::name";
  }
}

print "$dir/misc/perl-VOMS-Lite.spec";
open (OLD,"<$dir/misc/perl-VOMS-Lite.spec")        or die "couldn't open perl-VOMS-Lite.spec for reading";
open (NEW,">$dir/misc/perl-VOMS-Lite.spec.new")    or die "couldn't open perl-VOMS-Lite.spec.new for reading";

my $OK=0;
while (<OLD>) {
  s/^\s*Version:\s*\d[\d.]*\s*$/Version:        $VOMS::Lite::VERSION\n/;
  if ( m/Version:        $VOMS::Lite::VERSION/ ) { $OK=1; }
  print NEW $_;
}
close OLD;
close NEW;
print (($OK==1)?" [  OK  ]\n":" [ FAIL ]\n");
rename "$dir/misc/perl-VOMS-Lite.spec.new", "$dir/misc/perl-VOMS-Lite.spec";


