#!/usr/local/bin/perl -w
use vpopmail;

foreach my $domain (vlistdomains()) {

  print "$domain:\n";

  foreach my $u (vlistusers($domain)) {

    print "\t$u->{pw_name} ($u->{pw_gecos})\n";

  }
  print "\n\n";
}
