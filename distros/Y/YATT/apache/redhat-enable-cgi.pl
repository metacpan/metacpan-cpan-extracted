#!/usr/bin/perl -w
use strict;
use warnings;

our $context = "";
my ($line);
while (<>) {
  chomp;
  if (s/^(\#)?(AddHandler cgi-script \.cgi\b.*)$/$2/) {
    print STDERR $1 ? "Changed" : "Already OK", ": $2\n";
  } elsif ($line = m{^(<Directory "/var/www/cgi-bin">)} .. m{^</Directory}) {
    $context = $1 if $line == 1;
    ensure_config("Options", "ExecCGI", "FollowSymLinks");
  } elsif ($line = m{^(<Directory "/var/www/html">)} .. m{^</Directory}) {
    $context = $1 if $line == 1;
    ensure_config("AllowOverride", "All");
  }
} continue {
  print "$_\n";
}

sub ensure_config {
  my $config = shift;
  my ($indent, $value) = /^(\s*)$config\b(.*)/
    or return;
  if ($value =~ /None/) {
    $value = join " ", @;
  } else {
    my (%specified, @order);
    foreach my $item (split " ", $value) {
      my $relative = $item =~ s/^([\-\+])//;
      $specified{$item} = do {
	if (not $relative or $1 eq '+') {
	  1
	} elsif ($1 eq '-') {
	  0
	} else {
	  die "really?? $_";
	}
      };
      push @order, $item;
    }
    my $nchanges;
    foreach my $expect (@_) {
      if ($specified{$expect}) {
	print STDERR "Already OK: $context $expect\n";
	next;
      }
      push @order, $expect unless defined $specified{$expect};
      $specified{$expect} = 1;
      $nchanges++;
    }
    return unless $nchanges;
    $_ = "$indent$config ". join " ", map {$specified{$_} ? "+$_" : "-$_"} @order;
    print STDERR "Changed: $context $_\n";
  }
}

__END__

  perl -i.bak redhat-enable-cgi.pl /etc/httpd/conf/httpd.conf
