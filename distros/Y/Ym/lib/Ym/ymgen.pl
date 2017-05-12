#!/usr/bin/perl -w

package Ym;

use warnings;
use strict;

use Ym;

sub GenDefs {
  my ($def_type, $leaf) = @_;
  my %basket;
  my $i = 0;    # Count if there were true definitions not only references.
  my $definition = "define $def_type {\n";

  while (my ($k, $v) = each %$leaf) {
    if (ref($leaf->{$k})) {
      $basket{$k} = $leaf->{$k};
      next;
    }
    $definition .= "\t$k\t$v\n";
    ++$i;
  }
  $definition .= "}\n\n";

  if ($i == 0) {
    $definition = "";
  }
  foreach my $el (keys %basket) {
    $definition .= ProcessNode($basket{$el}, $el);
  }

  return $definition;
}

sub ProcessNode {
  my ($node, $nodename) = @_;
  my $definition = '';

  foreach my $obj (sort keys %{$node}) {
    my $block = GenDefs($Ym::BRANCHES{$nodename}[0], $node->{$obj});
    $definition .= "$block";
  }
  return $definition;
}

sub GenerateCfg {
  my ($tree, $dst_dir, $opts) = @_;
  my $pid = $$;

  die("GenerateCfg: at least 2 parameters expected")
    unless $tree && $dst_dir;

  $opts = {} unless $opts;

  my $verbose = 0;

  unless (defined($tree->{'config'})) {
    die "nagios.cfg definitions are missing in \$hash{config}\n";
  }
  $tree->{'config'}->{'cfg_file'} = undef;

  foreach my $m (values %Ym::BRANCHES) {
    next unless defined($m->[1]);
    push @{$tree->{'config'}{'cfg_file'}}, $m->[1];
  }

  # Generate nagios.cfg
  my $nagios_main = $Ym::NAGIOS_CFG_NAME;
  open(NAGIOS_MAIN, ">$dst_dir/$nagios_main.$pid")
    or die "Can't open $dst_dir/$nagios_main.$pid : $!\n";

  foreach my $def (sort keys %{$tree->{'config'}}) {
    if ("$def" eq "cfg_file") {
      foreach my $c (@{$tree->{'config'}->{'cfg_file'}}) {
        printf NAGIOS_MAIN "cfg_file=%s\n",
          ($opts->{'target_base'} ? $opts->{'target_base'} : $dst_dir) . "/$c";
      }
    }
    else {
      printf NAGIOS_MAIN "%s=%s\n", $def, $tree->{'config'}{$def};
    }
  }
  close(NAGIOS_MAIN);

  # Generate object config files
  foreach my $def (keys %Ym::BRANCHES) {

    next unless (defined($Ym::BRANCHES{$def}[0]) 
              && defined($Ym::BRANCHES{$def}[1]));

    my $cfg_out = "$dst_dir/$Ym::BRANCHES{$def}[1]";
    open(OUT, ">$cfg_out.$pid") or die "Can't open $cfg_out.$pid : $!\n";

    my $block = ProcessNode($tree->{$def}, $def);
    print OUT "$block";
    ($verbose) and print "$block\n";

    close(OUT);
  }

  # Rename tmp files to regular. Save modification times.

  rename("$dst_dir/$nagios_main.$pid", "$dst_dir/$nagios_main") 
    or die "Can not rename cfg file : $!\n";

  foreach my $def (keys %Ym::BRANCHES) {
    next unless (defined($Ym::BRANCHES{$def}[0]) 
              && defined($Ym::BRANCHES{$def}[1]));

    my $cfg_out = "$dst_dir/$Ym::BRANCHES{$def}[1]";

    rename("$cfg_out.$pid", $cfg_out) 
      or die "Can not rename cfg file : $!\n";
  }
}

1;
