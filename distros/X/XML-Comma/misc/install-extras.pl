#!/usr/bin/perl -w

use strict;
use lib "./lib";

eval { require XML::Comma; };
my $comma_installed = $@ ? 0 : 1;
die "can't load XML::Comma - are you sure you ran 'make all' ?" unless($comma_installed); 

my @dd = @{XML::Comma->defs_directories};
foreach my $d (@dd) {
  unless(-d $d) {
    print "making directory $d...\n";
    eval { _mkdir_p($d, mode => 0775); };
    die "mkdir $d failed: $@" if($@); 
  }
}
foreach my $mf (<t/defs/*/*.macro>, <t/defs/*/*.def>, <t/defs/*.def>) {
  next if($mf =~ /_test_[a-z_]*.def$/i);
  $mf =~ s/\/\/+/\//g;
  my ($base_dir, $mfm, $mfe) = ($mf =~ /\/([^\/]*)\/([^\/]*)\.(macro|def)$/); 
  my $macro_file = "$mfm.$mfe"; 
  my $installed = undef;
  foreach my $d (sort { $base_dir ? ($b =~ /$base_dir(s)?$/ ? 1 : 0) : 0  } @dd) {
    # print "d: $d, bd: $base_dir, mf: $mf, mfm: $mfm, mfe: $mfe\n";
    if(-w $d) {
      eval {
        open(IN, "<$mf") || die "open $mf failed";
        open(OUT, ">$d/$macro_file") || die "open >$d/$macro_file failed";
        print OUT join("", <IN>) || die "print failed";
        close(IN);
        close(OUT);
      }; if($@) {
        warn "wtf $! $@"; 
      } else {
        $installed = "$d/$macro_file"; 
        last;
      }
    }
  }
  if($installed) {
    print "installed $installed\n"; 
  } else {
    die "couldn't install $macro_file!\n"; 
  }
}
#FIX: really we should install 664 by default
#	or install according to the user's mask +0020
#	or, best, prompt about it in comma-create-config.pl
my $root = XML::Comma->comma_root();
chmod(0666, XML::Comma->comma_root()."/log.comma");

sub _mkdir_p {
  my ($dir, %args) = @_; 
  my $mode = $args{mode} || "0777";
  my @dirs = grep (/./, split(/\//, $dir)); 
  my $dir_so_far = '/';
  foreach my $d (@dirs) {
    $dir_so_far .= "$d/"; 
    unless(-e $dir_so_far) {
      mkdir($dir_so_far, $mode) || die "couldn't create $dir_so_far: $!";
    }
  }
}

