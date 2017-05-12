#!/usr/bin/perl -w

package Ym;

use warnings;
use strict;

use Ym;

sub PlaceHost {
  my ($branch, $tree) = @_;
  my $np = "host_name";    # Name prefix
  my $tp = "name";         # Template prefix

  if (defined($branch->{$np})) {
    my $name = $branch->{$np};
    $tree->{'hosts'}->{$name} = $branch;

  }
  elsif (defined($branch->{$tp}) && defined($branch->{'register'}) && $branch->{'register'} == 0) {
    my $name = $branch->{$tp};
    $tree->{'host_templates'}->{$name} = $branch;
  }
  else {
    return 0;
  }
  return 1;
}

sub PlaceService {
  my ($branch, $tree) = @_;
  my $np = "host_name";
  my $sp = "service_description";
  my $tp = "name";                  # Template prefix

  if (defined($branch->{$np}) && defined($branch->{$sp})) {
    my $hn = $branch->{$np};
    my $sn = $branch->{$sp};
    $tree->{'hosts'}->{$hn}->{'services'}->{$sn} = $branch;

  }
  elsif (defined($branch->{$tp}) && defined($branch->{'register'}) && $branch->{'register'} == 0) {
    my $name = $branch->{$tp};
    $tree->{'service_templates'}->{$name} = $branch;
  }
  else {
    return 0;
  }
  return 1;
}

sub PlaceHostgroup {
  my ($branch, $tree) = @_;
  my $np = "hostgroup_name";

  if (defined($branch->{$np})) {
    my $name = $branch->{$np};
    $tree->{'hostgroups'}->{$name} = $branch;
  }
  else {
    return 0;
  }
  return 1;
}

sub PlaceCommand {
  my ($branch, $tree) = @_;
  my $np = "command_name";

  if (defined($branch->{$np})) {
    my $name = $branch->{$np};
    $tree->{'commands'}->{$name} = $branch;
  }
  else {
    return 0;
  }
  return 1;
}

sub PlaceContactgroup {
  my ($branch, $tree) = @_;
  my $np = "contactgroup_name";

  if (defined($branch->{$np})) {
    my $name = $branch->{$np};
    $tree->{'contactgroups'}->{$name} = $branch;
  }
  else {
    return 0;
  }
  return 1;
}

sub PlaceContact {
  my ($branch, $tree) = @_;
  my $np = "contact_name";    # Name prefix
  my $tp = "name";            # Template prefix

  if (defined($branch->{$np})) {
    my $name = $branch->{$np};
    $tree->{'contacts'}->{$name} = $branch;
  }
  elsif (defined($branch->{$tp}) 
      && defined($branch->{'register'}) 
      && $branch->{'register'} == 0) 
    {
      my $name = $branch->{$tp};
      $tree->{'contact_templates'}->{$name} = $branch;
    }
  else {
    return 0;
  }
  return 1;
}

sub PlaceTimeperiod {
  my ($branch, $tree) = @_;
  my $np = "timeperiod_name";

  if (defined($branch->{$np})) {
    my $name = $branch->{$np};
    $tree->{'timeperiods'}->{$name} = $branch;
  }
  else {
    return 0;
  }
  return 1;
}

sub PlaceServiceDependency {
  my ($branch, $tree) = @_;
  my $hp = "dependent_host_name";
  my $sp = "dependent_service_description";

  if (defined($branch->{$hp}) && defined($branch->{$sp})) {
    my $dependent_host = $branch->{$hp};
    my $service_name   = $branch->{$sp};
    my $c              = 0;
    if (defined($tree->{'service_dependencies'}->{$dependent_host}->{'service_dependencies'})) {
      foreach (keys %{$tree->{'service_dependencies'}->{$dependent_host}->{'service_dependencies'}}) {
        ++$c;
      }
    }
    $tree->{'service_dependencies'}->{$dependent_host}->{'service_dependencies'}->{$c} = $branch;
  }
  else {
    return 0;
  }
  return 1;
}

sub PlaceHostDependency {
  my ($branch, $tree) = @_;
  my $hp  = "dependent_host_name";
  my $mhp = "host_name";

  if (defined($branch->{$hp}) && defined($branch->{$mhp})) {
    my $dependent_host = $branch->{$hp};
    my $master_host    = $branch->{$mhp};
    $tree->{'host_dependencies'}->{$dependent_host}->{'host_dependencies'}->{$master_host} = $branch;
  }
  else {
    return 0;
  }
  return 1;
}

sub ParseFile {
  my $cfg = shift;
  my $lc  = 0;       # Line counter
  my @err_msg;       # Error messages
  my $verbose = $Ym::VERBOSE;
  my $debug   = $Ym::DEBUG;
  my %s;

  open(CFG, "$cfg") or die "Can't open $cfg : $!\n";
  while (<CFG>) {
    if (scalar(@err_msg) > 0) {
      print "Errors occured while reading $cfg\n@err_msg\n";
      die;
    }
    ++$lc;
    next if /^\s*[#;]/o;
    chomp;
    if (/^\s*define\s+(\w+)\s*{/o) {
      my $dn = $1;    # definition name
      my %d;          # hash to store definition
      while ((my $l = <CFG>) !~ /^\s*}/o) {
        ++$lc;
        next if ($l =~ /^\s*[#;]/o);
        next if ($l =~ /^\s*$/);
        chomp($l);
        if ($l !~ /(\w+)\s+(.+)$/o) {
          push @err_msg, "Error in line $lc: $l";
          last;
        }
        my ($k, $v) = ($1, $2);
        $v =~ s/\s*[#;].*//o;
        $v =~ s/\s+$//o;
        ($debug) && print "$k => $v\n";
        $d{$k} = $v;
      }
      ++$lc;
      ($debug) && print "\n";
      if ("$dn" eq "host") {
        unless (PlaceHost(\%d, \%s)) {
          push @err_msg, "Error in " . Dumper(\%d);
        }
      }
      elsif ("$dn" eq "service") {
        unless (PlaceService(\%d, \%s)) {
          push @err_msg, "Error in " . Dumper(\%d);
        }
      }
      elsif ("$dn" eq "hostgroup") {
        unless (PlaceHostgroup(\%d, \%s)) {
          push @err_msg, "Error in " . Dumper(\%d);
        }
      }
      elsif ("$dn" eq "command") {
        unless (PlaceCommand(\%d, \%s)) {
          push @err_msg, "Error in " . Dumper(\%d);
        }
      }
      elsif ("$dn" eq "contactgroup") {
        unless (PlaceContactgroup(\%d, \%s)) {
          push @err_msg, "Error in " . Dumper(\%d);
        }
      }
      elsif ("$dn" eq "contact") {
        unless (PlaceContact(\%d, \%s)) {
          push @err_msg, "Error in " . Dumper(\%d);
        }
      }
      elsif ("$dn" eq "timeperiod") {
        unless (PlaceTimeperiod(\%d, \%s)) {
          push @err_msg, "Error in " . Dumper(\%d);
        }
      }
      elsif ("$dn" eq "servicedependency") {
        unless (PlaceServiceDependency(\%d, \%s)) {
          push @err_msg, "Error in " . Dumper(\%d);
        }
      }
      elsif ("$dn" eq "hostdependency") {
        unless (PlaceHostDependency(\%d, \%s)) {
          push @err_msg, "Error in " . Dumper(\%d);
        }
      }
      else {
        push @err_msg, "Unknown definition type: define $dn";
      }
    }
  }
  close(CFG);

  return %s;
}

sub MakeTree {

  # Accepts path to Nagios main config file and makes list of included configs.
  # Then parses each cfg file using ParseFile.
  # After that we should merge all results from each ParseFile call and return
  # a reference to full hash.

  my ($nagios_cfg, $opts) = @_;

  die("MakeTree: requires nagios config file name")
    unless $nagios_cfg;

  $opts = {} unless $opts;
  $opts->{'nagios_cfg_base'} = $opts->{'old_base'} if $opts->{'old_base'};
  $opts->{'real_base'}       = $opts->{'new_base'} if $opts->{'new_base'};

  die("MakeTree: nagios_cfg_base and real_base must be both defined or undefined")
    if $opts->{'nagios_cfg_base'} && !$opts->{'real_base'}
      || !$opts->{'nagios_cfg_base'} && $opts->{'real_base'};

  my @refs;    # Store references on cfg parts
  my %main;    # Resulting hash
  open(NAGIOS_MAIN, "$nagios_cfg") or die "Can't open $nagios_cfg : $!\n";
  while (<NAGIOS_MAIN>) {
    chomp;
    if (/^(\w+)\s*=\s*([^;#]+)$/o) {
      if ("$1" eq "cfg_file") {
        my $include_file = $2;
        if ($opts->{'nagios_cfg_base'} && $opts->{'real_base'}) {
          $include_file =~ s/^$opts->{'nagios_cfg_base'}//;
          $include_file = $opts->{'real_base'} . "/" . $include_file;
        }
        push @{$main{'config'}->{'cfg_file'}}, $include_file;
      }
      else {
        $main{'config'}->{$1} = $2;
      }
    }
  }
  close(NAGIOS_MAIN);

  if (scalar(@{$main{'config'}->{'cfg_file'}}) < 1) {
    die "No cfg_file directive found in nagios.cfg\n";
  }
  my $max_mod_time = 0;

  foreach my $curr_cfg (@{$main{'config'}->{'cfg_file'}}) {
    chomp($curr_cfg);
    $curr_cfg =~ s/^cfg_file=//o;
    next if ($curr_cfg eq 'ndomod.cfg');

    my %h = ParseFile($curr_cfg);

    my $mtime = (stat($curr_cfg))[9];
    if ($mtime > $max_mod_time) {$max_mod_time = $mtime;}

    # Merge in resulting hash
    foreach my $k (keys %h) {
      if (!defined($main{$k})) {
        $main{$k} = $h{$k};
      }
      else {
        foreach my $sk (keys %{$h{$k}}) {
          if (!defined($main{$k}->{$sk})) {
            $main{$k}->{$sk} = $h{$k}->{$sk};
          }
          else {
            warn "Conflict entries in config!\n";
            warn Dumper($main{$k}->{$sk});
            warn Dumper($h{$k}->{$sk});
            warn "Last config was $curr_cfg\n";
            exit;
          }
        }
      }
    }
  }
  Ym::SetMeta(
    \%main,
    {
      'tree_mod_time'    => 0,
      'configs_gen_time' => $max_mod_time,
    }
  );

  return \%main;
}

1;
