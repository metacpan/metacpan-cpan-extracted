#!/usr/bin/perl -w
use strict;
use warnings;

our $context = "";
my ($line);
while (<>) {
  chomp;
  if ($line = m{^(\Q<IfModule mod_userdir.c>\E)} .. m{^\Q</IfModule>\E}) {
    $context = $1 if $line == 1;
    set_config(qw(UserDir public_html));
  } elsif ($line = m{^\#?(\Q<Directory /home/*/public_html>\E)}
	   .. m{^\#?</Directory}) {
    $context = $1 if $line == 1;
    s/^\#//;
    set_config("AllowOverride", "All");
    ensure_config("Options", "ExecCGI");
  }
} continue {
  print "$_\n";
}

sub set_config {
  my ($config, $expect) = @_;
  my ($indent, $got) = /^(\s*)$config\b(.*)/
    or return;
  if (trim($got) eq $expect) {
    print STDERR "Already OK: $context $expect\n";
  } else {
    $_ = "$indent$config $expect";
    print STDERR "Changed: $context $_\n";
  }
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

sub trim {
  $_[0] =~ s/^\s*|\s*$//g;
  $_[0]
}
