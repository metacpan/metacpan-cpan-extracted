package
ApacheConfig;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Exporter qw(import);

our $context = "";

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
  my @new;
  if ($value =~ /None/) {
    @new = @_;
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
    my $nchanges = 0;
    foreach my $expect (@_) {
      if ($specified{$expect}) {
	print STDERR "Already OK: $context $config $expect\n";
	next;
      }
      push @order, $expect unless defined $specified{$expect};
      $specified{$expect} = 1;
      $nchanges++;
    }
    return unless $nchanges;
    @new = map {$specified{$_} ? "+$_" : "-$_"} @order;
  }
  $_ = "$indent$config ". join " ", @new;
  print STDERR "Changed: $context $_\n";
}

sub trim {
  $_[0] =~ s/^\s*|\s*$//g;
  $_[0]
}

our @EXPORT = grep {/_config$/} keys %ApacheConfig::;
push @EXPORT, qw($context);
our @EXPORT_OK = @EXPORT;

1;
