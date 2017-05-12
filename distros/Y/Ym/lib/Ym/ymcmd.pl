#!/usr/bin/perl -w

package Ym;

use strict;
use warnings;

use Ym;

sub Lookup;    # Function prototype definition for recursion calls.

# Determine value of definition ($opt) for specified object.
# If there is no clear definition, than we recursively look in templates.
sub Lookup {
  my ($tree, $leaf, $opt) = @_;
  my $ret = 0;
  if (defined($leaf->{$opt})) {
    $ret = $leaf->{$opt};
  }
  else {
    if (defined($leaf->{'use'})) {
      my $template = $leaf->{'use'};
      if (!defined($tree->{'service_templates'}->{$template})) {
        return $ret;
      }
      my $template_ref = $tree->{'service_templates'}->{$template};
      $ret = Lookup($tree, $template_ref, $opt);
    }
  }
  return $ret;
}

###########################################################
### O B J E C T  D E F I N I T I O N  F U N C T I O N S ###
###########################################################

### H O S T  C O M M A N D S ###

sub AddHost {
  my ($tree, $object, $opts) = @_;
  my $verbose = $Ym::VERBOSE;
  my ($processed, $skipped) = (0, 0);
  my $sub_name = 'AddHost';

  if (!ref($opts) || ref($opts) ne "HASH") {
    die "$sub_name: third argument must be a hash reference\n";
  }

  my $obj_ref = Ym::GetObjectList($object);

  foreach my $h (@$obj_ref) {
    if (defined($tree->{'hosts'}->{$h})) {
      $skipped++;
      warn "$sub_name: host \"$h\" exists. Skipping.\n";
      next;
    }
    ($verbose) && print "Adding host \"$h\"\n" . Dumper($opts);

    %{$tree->{'hosts'}->{$h}} = %$opts;
    my $href = $tree->{'hosts'}->{$h};

    foreach my $k (qw/host_name address alias/) {
      $href->{$k} = $h unless defined($href->{$k});
    }
    $processed++;
  }
  Ym::TouchTree($tree) if ($processed > 0);
  print "$sub_name: added: $processed; skipped: $skipped\n";
}

sub DeleteHost {
  my ($tree, $object, $group_list) = @_;
  my $verbose = $Ym::VERBOSE;
  my ($processed, $skipped) = (0, 0);
  my $sub_name = 'DeleteHost';

  my $obj_ref = Ym::GetObjectList($object, $group_list, 
    {
      'obj_branch' => $tree->{'hosts'},
      'grp_branch' => $tree->{'hostgroups'},
      'allow_regex_in_obj' => 1,
    }
  );

  # Delete hosts from their hostgroups
  my $membership = ShowMembership($tree, $obj_ref, "hosts");
  my %uniq_groups;

  foreach my $g (@$membership) {
    $uniq_groups{$g} = 1;
  }

  foreach my $g (keys %uniq_groups) {
    DeleteItem($tree, $tree->{'hostgroups'}->{$g}, $obj_ref, "members");
  }

  foreach my $h (@$obj_ref) {
    if (!defined($tree->{'hosts'}->{$h})) {
      $skipped++;
      warn "$sub_name: host \"$h\" does not exist. Skipping.\n";
      next;
    }
    ($verbose) && print "Deleting host \"$h\"\n";

    delete($tree->{'hosts'}->{$h});
    $processed++;
  }

  # Delete empty hostgroups
  foreach my $hg (@$group_list) {
    DeleteHostgroup($tree, [$hg]);
  }

  Ym::TouchTree($tree) if ($processed > 0);
  print "$sub_name: deleted: $processed; skipped: $skipped\n";
}

sub ModifyHost {
  my ($tree, $object, $group_list, $opts, $remove) = @_;
  my $verbose = $Ym::VERBOSE;
  my ($processed, $skipped) = (0, 0);
  my $sub_name = 'ModifyHost';

  if (!ref($opts) || ref($opts) ne "HASH") {
    die "$sub_name: fouth argument must be a hash reference\n";
  }

  my $obj_ref = Ym::GetObjectList($object, $group_list,
    {
      'obj_branch' => $tree->{'hosts'},
      'grp_branch' => $tree->{'hostgroups'},
      'allow_regex_in_obj' => 1,
    }
  );

  foreach my $h (@$obj_ref) {
    if (!defined($tree->{'hosts'}->{$h})) {
      $skipped++;
      warn "$sub_name: host \"$h\" does not exist. Skipping.\n";
      next;
    }
    ($verbose) && print "Modifying host \"$h\"\n";

    while (my ($k, $v) = each %$opts) {
      $tree->{'hosts'}->{$h}->{$k} = $v;
    }

    my $attrs = Ym::GetObjectList($remove, undef,
      {
        'obj_branch' => $tree->{'hosts'}->{$h},
      }
    );

    foreach my $k (@$attrs) {
      next if (ref($tree->{'hosts'}->{$h}->{$k}));
      delete($tree->{'hosts'}->{$h}->{$k});
    }
    $processed++;
  }
  Ym::TouchTree($tree) if ($processed > 0);
  print "$sub_name: modified: $processed; skipped: $skipped\n";
}

sub CopyHost {
  my ($tree, $object, $dest) = @_;
  my ($processed, $skipped) = (0, 0);
  my $verbose = $Ym::VERBOSE;
  my $sub_name = 'CopyHost';

  if ($object =~ /\/(.*)\//o) {   # If item contains regexp
    die "$sub_name: invalid argument \"$object\". No regexp allowed in this function.\n";
  }

  my $clones = Ym::GetObjectList($dest);

  if (!defined($tree->{'hosts'}->{$object})) {
    die "$sub_name: source host \"$object\" is not defined.\n";
  }

  foreach my $h (@$clones) {
    if (defined($tree->{'hosts'}->{$h})) {
      $skipped++;
      warn "$sub_name: host \"$h\" exists. Skipping.\n";
      next;
    }
    ($verbose) && print "Copying host \"$h\"\n";

    %{$tree->{'hosts'}->{$h}} = %{Storable::dclone($tree->{'hosts'}->{$object})};

    my $href = $tree->{'hosts'}->{$h};

    foreach my $k (qw/host_name address alias/) {
      $href->{$k} = $h;
    }
    foreach my $srv (keys %{$href->{'services'}}) {
      $href->{'services'}->{$srv}->{'host_name'} = $h;
    }

    # Add clone to same hostgroups as a master host
    my @mh         = ($object);
    my @new_m      = ($h);
    my $membership = ShowMembership($tree, \@mh, "hosts");

    foreach my $g (@$membership) {
      AddItem($tree, $tree->{'hostgroups'}->{$g}, \@new_m, "members");
    }
    $processed++;
  }
  Ym::TouchTree($tree) if ($processed > 0);
  print "$sub_name: copied: $processed; skipped: $skipped\n";
}

### S E R V I C E  C O M M A N D S ###
sub AddService {

  my ($tree, $srv_list, $host_list, $group_list, $opts) = @_;

  my $verbose = $Ym::VERBOSE;
  my ($processed, $skipped) = (0, 0);
  my $sub_name = 'AddService';

  $opts = {} unless $opts;

  my $srv_ref      = Ym::GetObjectList($srv_list);

  my $hosts_ref    = Ym::GetObjectList($host_list, $group_list, 
    {
      'obj_branch' => $tree->{'hosts'},
      'grp_branch' => $tree->{'hostgroups'},
      'allow_regex_in_obj' => 1,
    }
  );

  foreach my $h (@$hosts_ref) {
    my $href = $tree->{'hosts'}->{$h};
    if (!defined($tree->{'hosts'}->{$h})) {
      warn "$sub_name: host \"$h\" does not exist. Skipping.\n";
      ++$skipped;
      next;
    }
    foreach my $srv (@$srv_ref) {
      if ( defined($href->{'services'})
        && defined($href->{'services'}->{$srv}))
      {
        $skipped++;
        warn "$sub_name: service \"$srv\" on host \"$h\" exists. Skipping.\n";
        next;
      }
      ($verbose) && print "Adding service \"$srv\" to host \"$h\"\n" . Dumper($opts);

      if (!defined($opts->{'use'})) {
        $opts->{'use'} = "default-service";
      }
      %{$href->{'services'}->{$srv}} = %$opts;
      my $srvref = $href->{'services'};
      $srvref->{$srv}{'host_name'}           = $h;
      $srvref->{$srv}{'service_description'} = $srv;
      $srvref->{$srv}{'contact_groups'}      = Lookup($tree, $href, "contact_groups");
      $processed++;
    }
    ($verbose) && print "HOST:$h\n" . Dumper $tree->{'hosts'}->{$h};
  }
  Ym::TouchTree($tree) if ($processed > 0);
  print "$sub_name: added: $processed; skipped: $skipped\n";

}

sub DeleteService {
  my ($tree, $srv_list, $host_list, $group_list) = @_;
  my $verbose = $Ym::VERBOSE;
  my ($processed, $skipped) = (0, 0);
  my $sub_name = 'DeleteService';

  my $hosts_ref = Ym::GetObjectList($host_list, $group_list,
    {
      'obj_branch' => $tree->{'hosts'},
      'grp_branch' => $tree->{'hostgroups'},
      'allow_regex_in_obj' => 1,
    }
  );

  foreach my $h (@$hosts_ref) {
    if (!defined($tree->{'hosts'}->{$h})) {
      $skipped++;
      warn "$sub_name: host \"$h\" does not exist. Skipping.\n";
      next;
    }
    my $href = $tree->{'hosts'}->{$h};
    my $srv_ref = Ym::GetObjectList($srv_list, undef,
      {
        'obj_branch' => $href->{'services'},
        'allow_regex_in_obj' => 1,
      }
    );

    foreach my $srv (@$srv_ref) {
      if (!defined($href->{'services'}->{$srv})) {
        $skipped++;
        warn "$sub_name: service \"$srv\" on host \"$h\" does not exist. Skipping.\n";
        next;
      }
      ($verbose) && print "Deleting service \"$srv\" oh host \"$h\"\n";
      delete($href->{'services'}->{$srv});
      $processed++;
    }
  }
  Ym::TouchTree($tree) if ($processed > 0);
  print "$sub_name: deleted: $processed; skipped: $skipped\n";
}

sub ModifyService {
  my ($tree, $srv_list, $host_list, $group_list, $opts, $remove) = @_;
  my $verbose = $Ym::VERBOSE;
  my ($processed, $skipped) = (0, 0);
  my $sub_name = 'ModifyService';

  my $hosts_ref = Ym::GetObjectList($host_list, $group_list,
    {
      'obj_branch' => $tree->{'hosts'},
      'grp_branch' => $tree->{'hostgroups'},
      'allow_regex_in_obj' => 1,
    }
  );

  foreach my $h (@$hosts_ref) {
    if (!defined($tree->{'hosts'}->{$h})) {
      $skipped++;
      warn "$sub_name: host \"$h\" does not exist. Skipping.\n";
      next;
    }
    my $href = $tree->{'hosts'}->{$h};
    my $srv_ref = Ym::GetObjectList($srv_list, undef,
      {
        'obj_branch' => $href->{'services'},
        'allow_regex_in_obj' => 1,
      }
    );

    foreach my $srv (@$srv_ref) {
      my $srvref = $href->{'services'};

      if (!defined($srvref->{$srv})) {
        $skipped++;
        warn "$sub_name: service \"$srv\" on host \"$h\" does not exist. Skipping.\n";
        next;
      }
      ($verbose) && print "Modifying service \"$srv\" oh host \"$h\"\n";

      while (my ($k, $v) = each %$opts) {
        $srvref->{$srv}->{$k} = $v;
      }
      my $attrs = Ym::GetObjectList($remove, undef,
        {
          'obj_branch' => $href->{'services'}->{$srv},
        }
      );

      foreach my $k (@$attrs) {
        delete($href->{'services'}{$srv}->{$k});
      }
      $processed++;
    }
  }
  Ym::TouchTree($tree) if ($processed > 0);
  print "$sub_name: modified: $processed; skipped: $skipped\n";
}

sub CopyService {
  # Clone service in terms of one particular host.

  my ($tree, $service, $dest, $host) = @_;
  my $verbose = $Ym::VERBOSE;
  my ($processed, $skipped) = (0, 0);
  my $sub_name = 'CopyService';

  # Verify list. No regexp allowed in this function
  if ($service =~ /\/(.*)\//o)    # If item contains regexp
  {
    die "$sub_name: invalid argument \"$service\". No regexp allowed in this function.\n";
  }

  foreach my $obj (@$dest) {
    if ($obj =~ /\/(.*)\//o && $obj !~ /^READ_FILE/o)    # If item contains regexp
    {
      die "$sub_name: invalid argument \"$obj\". No regexp allowed in this function.\n";
    }
  }

  if (!defined($tree->{'hosts'}->{$host})) {
    die "$sub_name: source host \"$host\" does not exist.\n";
  }
  if (!defined($tree->{'hosts'}->{$host}->{'services'}->{$service})) {
    die "$sub_name: service \"$service\" on host \"$host\" does not exist.\n";
  }

  my $href = $tree->{'hosts'}->{$host};
  my $clones = Ym::GetObjectList($dest);

  foreach my $srv (@$clones) {
    if (defined($href->{'services'}->{$srv})) {
      $skipped++;
      warn "$sub_name: service \"$srv\" on host \"$host\" exists. Skipping.\n";
      next;
    }
    %{$href->{'services'}->{$srv}} = %{$href->{'services'}->{$service}};
    $href->{'services'}->{$srv}->{'service_description'} = $srv;

    ($verbose) && print "Copying service \"$service\" to \"$srv\" on host \"$host\".\n";
    $processed++;
  }
  Ym::TouchTree($tree) if ($processed > 0);
  print "$sub_name: copied: $processed; skipped: $skipped\n";
}

### C O M M A N D S  D E F I N I T I O N  F U N C T I O N S ###
sub AddCommand {
  my ($tree, $object, $opts) = @_;
  my $verbose = $Ym::VERBOSE;
  my ($processed, $skipped) = (0, 0);
  my $sub_name = 'AddCommand';

  if (!ref($opts) || ref($opts) ne "HASH") {
    die "$sub_name: third argument must be a hash reference\n";
  }

  # Verify object list. No regexp allowed in this function
  foreach my $obj (@$object) {
    if ($obj =~ /\/(.*)\//o && $obj !~ /^READ_FILE/o)    # If item contains regexp
    {
      die "$sub_name: invalid argument \"$obj\". No regexp allowed in this function.\n";
    }
  }

  my $obj_ref = Ym::GetObjectList($object);
  foreach my $cmd (@$obj_ref) {
    if (defined($tree->{'commands'}->{$cmd})) {
      $skipped++;
      warn "$sub_name: command \"$cmd\" exists. Skipping.\n";
      next;
    }
    ($verbose) && print "Adding command \"$cmd\"\n";

    %{$tree->{'commands'}->{$cmd}} = %$opts;
    $tree->{'commands'}->{$cmd}->{'command_name'} = $cmd;
    $processed++;
  }
  Ym::TouchTree($tree) if ($processed > 0);
  print "$sub_name: added: $processed; skipped: $skipped\n";
}

sub DeleteCommand {
  my ($tree, $object) = @_;
  my $verbose = $Ym::VERBOSE;
  my ($processed, $skipped) = (0, 0);
  my $sub_name = 'DeleteCommand';

  my $obj_ref = Ym::GetObjectList($object, undef,
    {
      'obj_branch' => $tree->{'commands'},
      'allow_regex_in_obj' => 1,
    }
  );

  foreach my $cmd (@$obj_ref) {
    if (!defined($tree->{'commands'}->{$cmd})) {
      $skipped++;
      warn "$sub_name: command \"$cmd\" does not exist. Skipping.\n";
      next;
    }
    ($verbose) && print "Deleting command \"$cmd\"\n";

    delete($tree->{'commands'}->{$cmd});
    $processed++;
  }
  Ym::TouchTree($tree) if ($processed > 0);
  print "$sub_name: deleted: $processed; skipped: $skipped\n";
}

sub ModifyCommand {
  my ($tree, $object, $opts) = @_;
  my $verbose = $Ym::VERBOSE;
  my ($processed, $skipped) = (0, 0);
  my $sub_name = 'ModifyCommand';

  if (!ref($opts) || ref($opts) ne "HASH") {
    die "$sub_name: third argument must be a hash reference\n";
  }

  my $obj_ref = Ym::GetObjectList($object, undef,
    {
      'obj_branch' => $tree->{'commands'},
      'allow_regex_in_obj' => 1,
    }
  );

  foreach my $cmd (@$obj_ref) {
    if (!defined($tree->{'commands'}->{$cmd})) {
      $skipped++;
      warn "$sub_name: command \"$cmd\" does not exist. Skipping.\n";
      next;
    }
    ($verbose) && print "Modifying command \"$cmd\"\n";

    while (my ($k, $v) = each %$opts) {
      $tree->{'commands'}->{$cmd}->{$k} = $v;
    }
    $processed++;
  }
  Ym::TouchTree($tree) if ($processed > 0);
  print "$sub_name: modified: $processed; skipped: $skipped\n";
}

### H O S T G R O U P S  D E F I N I T I O N  F U N C T I O N S ###
sub AddHostgroup {
  my ($tree, $object, $opts) = @_;
  my $verbose = $Ym::VERBOSE;
  my ($processed, $skipped) = (0, 0);
  my $sub_name = 'AddHostgroup';

  $opts = {} unless $opts;

  if (!ref($opts) || ref($opts) ne "HASH") {
    die "$sub_name: third argument must be a hash reference\n";
  }

  # Verify object list. No regexp allowed in this function
  foreach my $obj (@$object) {
    if ($obj =~ /\/(.*)\//o && $obj !~ /^READ_FILE/o)    # If item contains regexp
    {
      die "$sub_name: invalid argument \"$obj\". No regexp allowed in this function.\n";
    }
  }

  my $obj_ref = Ym::GetObjectList($object);

  foreach my $hg (@$obj_ref) {
    if (defined($tree->{'hostgroups'}->{$hg})) {
      $skipped++;
      warn "$sub_name: hostgroup \"$hg\" exists. Skipping.\n";
      next;
    }
    ($verbose) && print "Adding hostgroup \"$hg\"\n";

    %{$tree->{'hostgroups'}->{$hg}} = %$opts;

    $tree->{'hostgroups'}->{$hg}->{'hostgroup_name'} = $hg;

    unless(defined($tree->{'hostgroups'}->{$hg}->{'alias'})) {
      $tree->{'hostgroups'}->{$hg}->{'alias'} = $hg;
    }
    ++$processed;
  }
  Ym::TouchTree($tree) if ($processed > 0);
  print "$sub_name: added: $processed; skipped: $skipped\n";
}

sub DeleteHostgroup {
  my ($tree, $object) = @_;
  my $verbose = $Ym::VERBOSE;
  my ($processed, $skipped) = (0, 0);
  my $sub_name = 'DeleteHostgroup';

  my $obj_ref = Ym::GetObjectList($object, undef,
    {
      'obj_branch' => $tree->{'hostgroups'},
      'allow_regex_in_obj' => 1,
    }
  );

  foreach my $hg (@$obj_ref) {
    if (!defined($tree->{'hostgroups'}->{$hg})) {
      $skipped++;
      warn "$sub_name: hostgroup \"$hg\" does not exist. Skipping.\n";
      next;
    }
    ($verbose) && print "Deleting hostgroup \"$hg\"\n";

    delete($tree->{'hostgroups'}->{$hg});
    $processed++;
  }
  Ym::TouchTree($tree) if ($processed > 0);
  print "$sub_name: deleted: $processed; skipped: $skipped\n";
}

sub ModifyHostgroup {
  my ($tree, $object, $opts) = @_;
  my $verbose = $Ym::VERBOSE;
  my ($processed, $skipped) = (0, 0);
  my $sub_name = 'ModifyHostgroup';

  $opts = {} unless $opts;

  my $obj_ref = Ym::GetObjectList($object, undef,
    {
      'obj_branch' => $tree->{'hostgroups'},
      'allow_regex_in_obj' => 1,
    }
  );

  foreach my $hg (@$obj_ref) {
    if (!defined($tree->{'hostgroups'}->{$hg})) {
      $skipped++;
      warn "$sub_name: hostgroup \"$hg\" does not exist. Skipping.\n";
      next;
    }
    ($verbose) && print "Modifying hostgroup \"$hg\"\n";

    while (my ($k, $v) = each %$opts) {
      $tree->{'hostgroups'}->{$hg}->{$k} = $v;
    }
    $processed++;
  }
  Ym::TouchTree($tree) if ($processed > 0);
  print "$sub_name: modified: $processed; skipped: $skipped\n";
}

sub ShowMembers {
  my ($tree, $object, $opts) = @_;
  my %members = ();
  my $sub_name = 'ShowMembers';

  $opts = {} unless $opts;

  if(!defined($opts->{'type'})) {
    die "$sub_name: Programmer error - 'type' option is not specified.\n";
  }

  if($opts->{'type'} !~ /^(hostgroups|contactgroups)$/o) {
    die "$sub_name: Programmer error - unknown 'type' option value.\n";
  }
   
  my $t = $opts->{'type'};

  my $obj_ref = Ym::GetObjectList($object, undef,
    {
      'obj_branch' => $tree->{$t},
      'allow_regex_in_obj' => 1,
    }
  );

  foreach my $o (@$obj_ref) {
    next unless (defined($tree->{$t}->{$o}));
    next unless (defined($tree->{$t}->{$o}->{'members'}));

    my $hg_ref = $tree->{$t}->{$o};
    my $split_pattern = '[,:;\s]+';

    foreach my $m (split(/$split_pattern/o, $hg_ref->{'members'})) {
      $members{$m} = 1;
    }
  }

  foreach my $m (sort keys %members) {
    print "$m\n";
  }
}

### G E N E R A L  C O M M A N D S ###
sub AddItem {
  # Like add some member(s) to contactgroup, or add member(s) to hostgroup

  my ($tree, $dest, $object, $attr) = @_;
  my $verbose = $Ym::VERBOSE;
  my $sub_name = 'AddItem';

  if (!defined($dest->{$attr})) {
    die "$sub_name: attribute $attr is not defined for given object.\n";
  }

  # Verify object list. No regexp allowed in this function
  foreach my $obj (@$object) {
    if ($obj =~ /\/(.*)\//o && $obj !~ /^READ_FILE/o)    # If item contains regexp
    {
      die "$sub_name: invalid argument \"$obj\". No regexp allowed in this function.\n";
    }
  }
  my $obj_ref = Ym::GetObjectList($object);
  push @$obj_ref, (split ",", $dest->{$attr});
  my %items;                                             # key - item name; value - fake value

  foreach my $o (@$obj_ref) {
    $items{$o} = 1;
  }
  $dest->{$attr} = join ",", (sort keys %items);

  Ym::TouchTree($tree);
}

sub DeleteItem {
  # Like delete some member(s) from contactgroup, or from member(s) from hostgroup

  my ($tree, $dest, $object, $attr) = @_;
  my $verbose = $Ym::VERBOSE;
  my $sub_name = 'DeleteItem';

  if (!defined($dest) || !ref($dest)) {
    die "$sub_name: first argument must be defined reference to data structure.\n";
  }
  if (!defined($dest->{$attr})) {
    die "$sub_name: attribute $attr is not defined for given object.\n";
  }

  my $obj_ref = Ym::GetObjectList($object, undef,
    {
      'obj_branch' => $dest->{$attr},
      'allow_regex_in_obj' => 1,
    }
  );
  my %items;    # key - item name; value - fake value

  foreach my $o (split ",", $dest->{$attr}) {
    $items{$o} = 1;
  }
  foreach my $d (@$obj_ref) {
    if (defined($items{$d})) {
      delete($items{$d});
    }
  }
  $dest->{$attr} = join ",", (sort keys %items);

  Ym::TouchTree($tree);
}

sub List {
  my ($branch, $object) = @_;
  my $sub_name = 'List';

  if (!defined($branch) || !ref($branch)) {
    die "$sub_name: first argument must be defined reference to data structure.\n";
  }

  my $obj_ref = Ym::GetObjectList($object, undef,
    {
      'obj_branch' => $branch,
      'allow_regex_in_obj' => 1,
    }
  );

  foreach my $obj (@$obj_ref) {
    next unless defined($branch->{$obj});
    print "$obj\n";
  }
}

sub Dump {
  my ($branch, $object) = @_;
  my $sub_name = 'Dump';

  if (!defined($branch) || !ref($branch)) {
    die "$sub_name: first argument must be defined reference to data structure.\n";
  }

  my $obj_ref = Ym::GetObjectList($object, undef,
    {
      'obj_branch' => $branch,
      'allow_regex_in_obj' => 1,
    }
  );

  foreach my $obj (@$obj_ref) {
    next unless defined($branch->{$obj});
    print "$obj " . Dumper($branch->{$obj});
  }
}

sub ShowMembership {
  my ($tree, $object, $type) = @_;
  my ($processed, $skipped) = (0, 0);
  my $sub_name = 'ShowMembership';

  if ($type ne "hosts" && $type ne "contacts") {
    die "$sub_name: don't know how to process type \"$type\"\n";
  }
  my $obj_ref = Ym::GetObjectList($object);

  my %groups; # key - contact or hostgroup names; 
              # value - hash (key - contact or host name; 
              # value = 1 fake value. group members)
  my $ref;

  if ($type eq "hosts") {
    $ref = $tree->{'hostgroups'};
  }
  elsif ($type eq "contacts") {
    $ref = $tree->{'contactgroups'};
  }

  foreach my $g (keys %$ref) {
    next unless defined($ref->{$g}->{'members'});
    foreach my $member (split ",", $ref->{$g}->{'members'}) {
      $groups{$g}->{$member} = 1;
    }
  }
  my @membership;

  foreach my $obj (@$obj_ref) {
    if (!defined($tree->{$type}->{$obj})) {
      $skipped++;
      warn "$sub_name: object \"$obj\" is not defined in $type. Skipping.\n";
      next;
    }
    foreach my $g (keys %groups) {
      if (defined($groups{$g}->{$obj})) {
        push @membership, $g;
      }
    }
    $processed++;
  }
  return \@membership;
}

sub Lookup_deep;    # Function prototype definition for recursion calls.

# Determine value of definition ($opt) for specified object.
# If there is no clear definition, than we recursively look in templates.
sub Lookup_deep {
  my ($branch, $leaf, $opts, $key) = @_;
  my $res;
  my $res2;

  foreach my $opt (@$opts) {
    if (defined($leaf->{$opt})) {
      $res->{$opt}->{$leaf->{$opt}} = 1;
    }
  }
  if (defined($leaf->{$key})) {
    my $include = $leaf->{$key};
    if (defined($branch->{$include})) {
      my $include_ref = $branch->{$include};
      $res2 = Lookup_deep($branch, $include_ref, $opts, $key);
    }
  }
  if (defined($res2)) {
    foreach my $o (@$opts) {
      next unless (defined($res2->{$o}));
      foreach (keys %{$res2->{$o}}) {
        $res->{$o}->{$_} = 1;
      }
    }
  }
  return $res;
}

sub Cleanup {
  my ($tree, $params) = @_;
  my $sub_name = 'Cleanup';

  my $ask  = $params->{'ask'}  if defined $params->{'ask'};
  my $diff = $params->{'diff'} if defined $params->{'diff'};
  my $dump = $params->{'dump'} if defined $params->{'dump'};
  my $type = $params->{'type'} if defined $params->{'type'};

  # Store used objects
  my %used_host_templates    = ();
  my %used_service_templates = ();
  my %used_contactgroups     = ();
  my %used_contacts          = ();
  my %used_contact_templates = ();
  my %used_commands          = ();
  my %used_timeperiods       = ();

  my %used_obj = (
    'host_templates'    => \%used_host_templates,
    'service_templates' => \%used_service_templates,
    'contactgroups'     => \%used_contactgroups,
    'contacts'          => \%used_contacts,
    'contact_templates' => \%used_contact_templates,
    'commands'          => \%used_commands,
    'timeperiods'       => \%used_timeperiods,
  );

  if ($type) {
    unless ($type =~ /^(host_templates|service_templates|contacts|contact_templates|timeperiods)$/o)
    {
      die "$sub_name: wrong type of object in '--type' directive.\n";
    }
  }

  # Walk through all hosts, find all usable host_templates, contactgroups, contacts,
  # commands, timeperiods. Mark all of them as 'used'.
  foreach my $h (keys %{$tree->{'hosts'}}) {
    if (defined($tree->{'hosts'}->{$h}->{'use'})) {
      $used_host_templates{$tree->{'hosts'}->{$h}->{'use'}} = 1;
    }
    if (defined($tree->{'hosts'}->{$h}->{'contact_groups'})) {
      foreach my $cg (split(',', $tree->{'hosts'}->{$h}->{'contact_groups'})) {
        $used_contactgroups{$cg} = 1;
      }
    }
    if (defined($tree->{'hosts'}->{$h}->{'contacts'})) {
      foreach my $c (split(',', $tree->{'hosts'}->{$h}->{'contacts'}))    # Might be several contacts
      {
        $used_contacts{$c} = 1;
      }
    }
    if (defined($tree->{'hosts'}->{$h}->{'check_command'})) {
      my @cmd_args =
        split('!', $tree->{'hosts'}->{$h}->{'check_command'});      # Might be a command with args
      $used_commands{$cmd_args[0]} = 1;
    }
    if (defined($tree->{'hosts'}->{$h}->{'event_handler'})) {
      $used_commands{$tree->{'hosts'}->{$h}->{'event_handler'}} = 1;
    }
    if (defined($tree->{'hosts'}->{$h}->{'check_period'})) {
      $used_timeperiods{$tree->{'hosts'}->{$h}->{'check_period'}} = 1;
    }
    if (defined($tree->{'hosts'}->{$h}->{'notification_period'})) {
      $used_timeperiods{$tree->{'hosts'}->{$h}->{'notification_period'}} = 1;
    }

    # Now do all the same things with host's services
    foreach my $s (keys %{$tree->{'hosts'}->{$h}->{'services'}}) {
      my $srv = $tree->{'hosts'}->{$h}->{'services'}->{$s};

      if (defined($srv->{'use'})) {
        $used_service_templates{$srv->{'use'}} = 1;
      }
      if (defined($srv->{'contact_groups'})) {
        foreach my $c (split(',', $srv->{'contact_groups'}))    # For multiple contactgroups
        {
          $used_contactgroups{$c} = 1;
        }
      }
      if (defined($srv->{'contacts'})) {
        foreach my $c (split(',', $srv->{'contacts'}))          # For multiple contacts
        {
          $used_contacts{$c} = 1;
        }
      }
      if (defined($srv->{'check_command'})) {
        my @cmd_args = split('!', $srv->{'check_command'});    # Might be a command with args
        $used_commands{$cmd_args[0]} = 1;
      }
      if (defined($srv->{'event_handler'})) {
        $used_commands{$srv->{'event_handler'}} = 1;
      }
      if (defined($srv->{'check_period'})) {
        $used_timeperiods{$srv->{'check_period'}} = 1;
      }
      if (defined($srv->{'notification_period'})) {
        $used_timeperiods{$srv->{'notification_period'}} = 1;
      }
    }
  }

  # Recursively look through host templates to find various objects
  foreach my $t (keys %used_host_templates) {

    # What fields to find in templates
    my @opts =
      qw/use contact_groups contacts check_command event_handler check_period notification_period/;
    my $res =
      Lookup_deep($tree->{'host_templates'}, $tree->{'host_templates'}->{$t}, \@opts, 'use');

    foreach my $opt (@opts) {
      next unless (defined($res->{$opt}));
      foreach my $k (keys %{$res->{$opt}}) {
        if ($opt eq 'contacts') {
          foreach my $c (split(',', $res->{$opt}->{$k})) {
            $used_obj{'contacts'}->{$c} = 1;
          }
        }
        elsif ($opt eq 'contact_groups') {
          foreach my $cg (split(',', $res->{$opt}->{$k})) {
            $used_obj{'contactgroups'}->{$cg} = 1;
          }
        }
        elsif ($opt eq 'use') {
          $used_obj{'host_templates'}->{$k} = 1;
        }
        elsif ($opt eq 'check_command' || $opt eq 'event_handler') {
          $used_obj{'commands'}->{$k} = 1;
        }
        elsif ($opt eq 'check_period' || $opt eq 'notification_period') {
          $used_obj{'timeperiods'}->{$k} = 1;
        }
      }
    }
  }

  # Recursively look through service templates to find various objects
  foreach my $t (keys %used_service_templates) {
    my @opts =
      qw/use contact_groups contacts check_command event_handler check_period notification_period/;
    my $res =
      Lookup_deep($tree->{'service_templates'}, $tree->{'service_templates'}->{$t}, \@opts, 'use');

    foreach my $opt (@opts) {
      next unless (defined($res->{$opt}));
      foreach my $k (keys %{$res->{$opt}}) {
        if ($opt eq 'contacts') {
          foreach my $c (split(',', $k)) {
            $used_obj{$opt}->{$c} = 1;
          }
        }
        elsif ($opt eq 'contact_groups') {
          foreach my $cg (split(',', $k)) {
            $used_obj{'contactgroups'}->{$cg} = 1;
          }
        }
        elsif ($opt eq 'use') {
          $used_obj{'service_templates'}->{$k} = 1;
        }
        elsif ($opt eq 'check_command' || $opt eq 'event_handler') {
          my @cmd_args = (split('!', $k));
          $used_obj{'commands'}->{$cmd_args[0]} = 1;
        }
        elsif ($opt eq 'check_period' || $opt eq 'notification_period') {
          $used_obj{'timeperiods'}->{$k} = 1;
        }
      }
    }
  }

  # Recursively look through contactgroups to find various objects
  foreach my $t (keys %used_contactgroups) {
    my @opts = qw/members contactgroup_members/;
    my $res  = Lookup_deep(
      $tree->{'contactgroups'},
      $tree->{'contactgroups'}->{$t},
      \@opts, 'contactgroup_members'
    );

    foreach my $opt (@opts) {
      next unless (defined($res->{$opt}));
      foreach my $k (keys %{$res->{$opt}}) {
        if ($opt eq 'members') {
          foreach my $c (split(',', $k)) {
            $used_obj{'contacts'}->{$c} = 1;
          }
        }
        elsif ($opt eq 'contactgroup_members') {
          foreach my $cg (split(',', $k)) {
            $used_obj{'contactgroups'}->{$cg} = 1;
          }
        }
      }
    }
  }

  # Recursively look through contacts to find various objects
  foreach my $t (keys %used_contacts) {
    my @opts = qw/
      contactgroups use
      host_notification_commands service_notification_commands
      host_notification_period service_notification_period
      /;
    my $res = Lookup_deep($tree->{'contacts'}, $tree->{'contacts'}->{$t}, \@opts, 'use');

    foreach my $opt (@opts) {
      next unless (defined($res->{$opt}));
      foreach my $k (keys %{$res->{$opt}}) {
        if ($opt eq 'host_notification_commands' || $opt eq 'service_notification_commands') {
          foreach my $c (split(',', $k)) {
            $used_obj{'commands'}->{$c} = 1;
          }
        }
        elsif ($opt eq 'contactgroups') {
          foreach my $cg (split(',', $k)) {
            $used_obj{'contactgroups'}->{$cg} = 1;
          }
        }
        elsif ($opt eq 'use') {
          $used_obj{'contact_templates'}->{$k} = 1;
        }
        elsif ($opt eq 'host_notification_period' || $opt eq 'service_notification_period') {
          $used_obj{'timeperiods'}->{$k} = 1;
        }
      }
    }
  }

  # Recursively look through contact_templates to find various objects
  foreach my $t (keys %used_contact_templates) {
    my @opts = qw/
      contactgroups use
      host_notification_commands service_notification_commands
      host_notification_period service_notification_period
      /;
    my $res =
      Lookup_deep($tree->{'contact_templates'}, $tree->{'contact_templates'}->{$t}, \@opts, 'use');

    foreach my $opt (@opts) {
      next unless (defined($res->{$opt}));
      foreach my $k (keys %{$res->{$opt}}) {
        if ($opt eq 'host_notification_commands' || $opt eq 'service_notification_commands') {
          foreach my $c (split(',', $k)) {
            my @cmd_args = split('!', $c);
            $used_obj{'commands'}->{$cmd_args[0]} = 1;
          }
        }
        elsif ($opt eq 'contactgroups') {
          foreach my $cg (split(',', $k)) {
            $used_obj{'contactgroups'}->{$cg} = 1;
          }
        }
        elsif ($opt eq 'use') {
          $used_obj{'contact_templates'}->{$k} = 1;
        }
        elsif ($opt eq 'host_notification_period' || $opt eq 'service_notification_period') {
          $used_obj{'timeperiods'}->{$k} = 1;
        }
      }
    }
  }

  # Find some usable commands in Nagios main config
  foreach my $opt (
    qw/
    global_host_event_handler global_service_event_handler
    ocsp_command ochp_command
    host_perfdata_command service_perfdata_command
    host_perfdata_file_processing_command service_perfdata_file_processing_command/
    )
  {
    next unless (defined($tree->{'config'}->{$opt}));
    my @cmd_args = split('!', $tree->{'config'}->{$opt});
    $used_obj{'commands'}->{$cmd_args[0]} = 1;
  }

  # Also we need to check host/service escalations and dependencies,
  # but I know that we do not use escalations at all and timeperiods in dependencies.

  # After all we've got actual list of object definitions.
  # Now check all defined objects and verify their presence in %used_obj
  # Make list of candidates to delete.

  my $unused;
  foreach my $k (keys %used_obj) {
    foreach my $obj (keys %{$tree->{$k}}) {
      unless (defined($used_obj{$k}->{$obj})) {
        $unused->{$k}->{$obj} = 1;
      }
    }
  }

  # Remove unused objects
  foreach my $k (keys %$unused) {
    next if ($type && $k ne $type);
    ($diff) && print "Removing unused $k\n";
    foreach my $obj (keys %{$unused->{$k}}) {
      ($dump) && print Dumper $tree->{$k}->{$obj};
      if ($ask) {
        print "Going to remove {$k}->{$obj}. Remove? y/n: ";
        chomp(my $ans = <STDIN>);
        until ($ans =~ /[yn]/io) {
          print "Going to remove {$k}->{$obj}. Remove? y/n: ";
          chomp($ans = <STDIN>);
        }
        next if ($ans eq 'n');
      }
      ($diff) && print "Removing {$k}->{$obj}\n\n";
      delete($tree->{$k}->{$obj});
    }
  }
}

1;
