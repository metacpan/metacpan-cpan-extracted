#!/usr/bin/perl

package Ym;

use warnings;
use strict;

use Ym;

sub TouchTree {
  my ($tree) = @_;
  die "TouchTree: tree reference is missing in args.\n" unless $tree;

  $tree->{'meta'}->{'tree_mod_time'} = time();
}

sub TouchConfigs {
  my ($tree) = @_;
  my $sub_name = 'TouchConfigs';

  defined($tree)
    or die "$sub_name: tree reference is missing in args.\n";

  $tree->{'meta'}->{'configs_gen_time'} = time();
}

sub SetMeta {
  my ($tree, $opts) = @_;
  my $sub_name = 'SetMeta';

  defined($tree)
    or die "$sub_name: tree reference is missing in args.\n";

  $opts = {} unless $opts;

  foreach my $k (keys %$opts) {
    $tree->{'meta'}->{$k} = $opts->{$k};
  }
}

sub GetMeta {
  my ($tree, $opt) = @_;
  my $sub_name = 'GetMeta';

  defined($tree)
    or die "$sub_name: tree reference is missing in args.\n";

  defined($opt)
    or die "$sub_name: option name is missing in args.\n";

  if (defined($tree->{'meta'}->{$opt})) {
    return $tree->{'meta'}->{$opt};
  }
  else {
    return undef;
  }
}

sub Ask_For_Change {

  # Check if it is safe to auto generate configs for Nagios.

  my ($tree) = @_;
  my $sub_name = 'Ask_For_Change';

  defined($tree)
    or die "$sub_name: tree reference is missing in args.\n";

  my $tree_mod_time    = GetMeta($tree, 'tree_mod_time');
  my $configs_gen_time = GetMeta($tree, 'configs_gen_time');

  $tree_mod_time    |= 0;
  $configs_gen_time |= 0;

  for my $c (@Ym::NAGIOS_CONFIGS) {
    my $file = "$Ym::NAGIOS_CFG_DIR/$c";

    next unless (-e $file);

    my $mtime = (stat("$Ym::NAGIOS_CFG_DIR/$c"))[9];

    if ($mtime < $tree_mod_time
      || ($configs_gen_time > 0 && $mtime > $configs_gen_time))
    {
      return 0;
    }
  }

  return 1;
}

sub GetMembers {
  my ($group, $grp_branch) = @_;

  my @members = ();

  if(!defined($grp_branch)
    || !defined($grp_branch->{$group})) 
  {
    return \@members;
  }

  foreach my $m (split (/[,:;\s]+/o, 
    $grp_branch->{$group}->{'members'})) 
  {
    push(@members, $m);
  }

  return \@members;

  # Note thar there may be hostgroup_members or contactgroup_members attribute
  # If so, we should recursively look into other groups.
  # I'll add this feature if someone need it.
}

sub read_file_macros {
  my ($f) = @_;
  my $sub_name = 'read_file_macros';
  my $file_contents = '';

  if ($f !~ /^READ_FILE=(.*)/o) {

    die "$sub_name: Error in argument: [$f]. ".
      "File name is missing.\n";
  }
  
  my $fname = $1;

  open(LIST, "<$fname") or die "Can't open [$fname]: $!\n";
  $/ = undef;

  $file_contents = <LIST>;

  close(LIST);

  return \$file_contents;
}

sub GetObjectList {
  my ($obj_ref, $grp_ref, $opts) = @_;
  my $sub_name = 'GetObjectList';

  $opts = {} unless $opts;

  my $res;
  @$res = [];

  # Check for empty input
  if(!defined($obj_ref) && !defined($grp_ref)) {
    return $res;
  }

  # Check args type
  if(defined($obj_ref) 
    && (!ref($obj_ref) || ref($obj_ref) ne 'ARRAY')) 
  {
    die "$sub_name: first argument must be an array reference\n";
  }

  if(defined($grp_ref)
    && (!ref($grp_ref) || ref($grp_ref) ne 'ARRAY'))
  {
    die "$sub_name: second argument must be an array reference\n";
  }

  # Check for mandatory options
  if(defined($obj_ref)) {
    if(defined($opts->{'allow_regexp_in_obj'})
    && !defined($opts->{'obj_branch'})) 
      {
        die "$sub_name: Programmer error - 'obj_branch' option is not set.\n";
      }
  }

  if(defined($grp_ref) 
    && !defined($opts->{'grp_branch'})) 
  {
      die "$sub_name: Programmer error - 'grp_branch' option is not set.\n";
  }

  my $split_pattern = '[,:;\n\s]+';
  my %tmp = ();
  my $verbose = $Ym::VERBOSE;

  if(defined($obj_ref)) { # Extract objects

    my $obj_raw = '';

    foreach my $item (@$obj_ref) {
      if ($item =~ /^\/(.*)\//o) {    # If item contains REGEXP
        my $regex = $1;
  
        ($verbose) && print "Found REGEXP $1\n";

        unless($opts->{'allow_regex_in_obj'}) {
          die "$sub_name: invalid argument [$item]. ".
            "No regex allowed in this command.\n";
        }

        foreach my $obj (keys %{$opts->{'obj_branch'}}) {
          if ($obj =~ /$regex/) {
            $tmp{$obj} = 1;
          }
        }
      }  
      else {
        if($item =~ /^READ_FILE/o) { # READ_FILE macros found
        
          ($verbose) && print "Found MACROS $item\n";
  
          $obj_raw = ${read_file_macros($item)};
        }  
        else {
          $obj_raw = $item;
        }

        # Split obj_raw and add objects to %tmp
        foreach my $obj (split($split_pattern, $obj_raw)) {
          $tmp{$obj} = 1;
        }
      }
    }
  } # End extract objects

  if(defined($grp_ref)) { # Extract group members
  
    my $grp_raw = '';

    foreach my $item (@$grp_ref) {

      if ($item =~ /^\/(.*)\//o) {    # If item contains REGEXP
        die "$sub_name: invalid argument [$item]. ".
          "No regexp allowed in group definition.\n";
      }

      if($item =~ /^READ_FILE/o) { # READ_FILE macros found
      
        ($verbose) && print "Found MACROS $item\n";

        $grp_raw = ${read_file_macros($item)};
      }
      else {
        $grp_raw = $item;
      }
    }

    # Split grp_raw, find members for each group and add them to %tmp
    foreach my $grp (split($split_pattern, $grp_raw)) {

      my $grp_members = GetMembers($grp, $opts->{'grp_branch'});

      foreach my $m (@$grp_members) {
        $tmp{$m} = 1;
      }
    }
  } # End extract group members

  @$res = keys %tmp;

  return $res;
}

sub VerifyDataStructure {
  my ($tree) = @_;

  foreach my $class (sort keys %$tree) {
    next if ($class eq "config" || $class eq "meta");

    foreach my $object (keys %{$tree->{$class}}) {
      my $count = scalar(keys %{$tree->{$class}->{$object}});

      if ($count eq 0) {
        print "Object: $class -> $object has too few elements $count\n";
      }

      if ($class =~ /hosts|service_dependencies/o) {

        my $k = ($class eq "hosts") ? "services" : "service_dependencies";

        my $count = scalar(keys %{$tree->{$class}->{$object}->{$k}});

        if ($count eq 0) {
          print "Object: $class -> $object -> $k has too few elements $count\n";
        }
      }
    }
  }
}

sub ShowDiff {
  # Shows difference between two (previous and current) versions of data structure

  my ($old, $new) = @_;

  sub Compare($$) {
    my ($one, $two) = @_;
    my @res;

    foreach my $class (keys %{$one}) {

      foreach my $object (keys %{$one->{$class}}) {
        if (!defined($two->{$class}->{$object})) {

          push @res, "{$class}->{$object}";
          next;
        }
        if ($class eq "hosts") {

          foreach my $srv (keys %{$one->{$class}->{$object}->{'services'}}) {

            if (!defined($two->{$class}->{$object}->{'services'}->{$srv})) {
              push @res, "{$class}->{$object}->{services}->{$srv}";
            }
          }
        }
      }
    }
    return \@res;
  }

  sub PrintDiff {
    my ($ref, $prefix) = @_;
    my $sub_name = 'PrintDiff';

    if (ref($ref) ne "ARRAY") {
      warn("$sub_name: first argument must be an ARRAY reference\n");
      return 0;
    }

    if (scalar(@$ref) > 0) {
      foreach my $l (@$ref) {
        print "$prefix $l\n";
      }
    }
  }

  my $deleted = Compare($old, $new);
  my $added   = Compare($new, $old);

  PrintDiff($deleted, "Deleted");
  PrintDiff($added,   "Added");

  return 1;
}

sub GetStruct {
  my ($file, $cfg) = @_;
  my $ref;

  if (-e $file) {
    ($Ym::VERBOSE) && print "Reading structure from file\n\n";
    $ref = Storable::retrieve($file) 
      or die "GetStruct: Can't load structure file $file : $!\n";
  }
  else {
    ($Ym::VERBOSE) && print "Ym::MakeTree\n";
    $ref = Ym::MakeTree($cfg);
  }
  return $ref;
}

sub CloneStruct {
  my ($tree) = @_;
  my $clone = Storable::dclone($tree) 
    or die "CloneStruct: Can't clone structure : $!\n";

  return $clone;
}

sub SaveStruct {
  my ($tree, $file) = @_;
  my $tmp_file = "$file.tmp";
  my $sub_name = 'SaveStruct';

  Storable::store($tree, $tmp_file) 
    or warn "$sub_name: Store fo $tmp_file failed\n";

  rename($tmp_file, $file) 
    or warn "$sub_name: Failed to rename $tmp_file to $file\n";
}

sub Backup {
  my ($opts) = @_;
  my $sub_name = 'Backup';
  
  $opts = {} unless $opts;

  my $stamp=`date +%Y-%m-%d_%H-%M-%S`;
  chomp($stamp);

  if(!defined($Ym::BACKUP_PATH)) {
    die "$sub_name: [BACKUP_PATH] variable is not defined in config.\n";
  }

  unless( -d $Ym::BACKUP_PATH && -w $Ym::BACKUP_PATH ) {
    die "$sub_name: [$Ym::BACKUP_PATH] is not a writable dir.\n";
  }

  my $bckp_dir = "$Ym::BACKUP_PATH/$stamp";

  opendir(DIR, $Ym::NAGIOS_CFG_DIR)
    or die "$sub_name: Can not open [$Ym::NAGIOS_CFG_DIR]: $!\n";

  my @contents = grep { /^[^.]/o && /\.cfg$/o && -f "$Ym::NAGIOS_CFG_DIR/$_" } readdir(DIR);

  closedir(DIR);

  mkdir($bckp_dir)
    or die "$sub_name: Can not create [$bckp_dir]: $!\n";

  foreach my $f (@contents) {
    File::Copy::copy("$Ym::NAGIOS_CFG_DIR/$f", "$bckp_dir/$f")
      or die "$sub_name: Can not copy [$Ym::NAGIOS_CFG_DIR/$f] to [$bckp_dir/$f]: $!\n";
  }

  return $bckp_dir;
}

1;
