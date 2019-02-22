#!/usr/bin/perl -w
use File::Basename qw(basename);

@xmlfiles = @ARGV ? @ARGV : (map {chomp; $_} grep {!m/^$/ && !m/^\s*#/} <>);

##-- usage
if (@xmlfiles && $xmlfiles[0] =~ m/^\-+h/) {
  print STDERR "Usage: $0 XMLFILE(s)... or $0 < XMLFILE_LIST\n";
  exit 1;
}

foreach $f (@xmlfiles) {
  open(XML,"<:utf8",$f) or die("$0: open failed for '$f': $!");
  $base = basename($f);
  $base =~ s/\..*$//;
  $dtaid = '-';
  while (<XML>) {
    if ( m{\<\s*idno\b[^\>]*?\btype=\"DTAID\"[^\>]*?\>\s*([^\<\s]*?)\s*\</idno\>}si ) {
      $dtaid=$1;
      last;
    }
  }
  print "$f\t$base\t$dtaid\n";
  close XML;
}
