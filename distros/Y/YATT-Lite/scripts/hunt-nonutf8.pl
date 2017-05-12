#!/usr/bin/perl -w
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Jcode qw(getcode);

use Getopt::Long;

GetOptions("l|list" => \ my $o_list)
  or exit 1;

my @cmd = (find => @ARGV
	   , map((-name => $_ => -prune => '-o')
		 , qw(cover_db .git *.db *.ico *.png *.gif
		      .xslate_cache
		    ))
	   , qw(-type f -print));

open my $pipe, '-|', @cmd
  or die "Can't execute find: $!";

FILE:
while (defined(my $fn = <$pipe>)) {
  chomp $fn;
  open my $fh, '<', $fn or do {
    warn "Can't open $fn: $!";
    next;
  };
  while (<$fh>) {
    my $code = getcode($_) or next;
    next if $code eq 'ascii' or $code eq 'utf8';
    if ($o_list) {
      print $fn, "\n";
    } else {
      print "$code\t$fn\n";
    }
    last;
  }
}
