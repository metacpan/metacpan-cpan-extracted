#!/usr/bin/perl

package Ym;

BEGIN {
  use Cwd;
  use FindBin;

  chroot('/');

  $ENV{'YM_BIN'}  = "$FindBin::RealBin";
  $ENV{'YM_LIB'}  = Cwd::abs_path("$ENV{'YM_BIN'}/../lib");
  $ENV{'YM_ETC'}  = Cwd::abs_path("$ENV{'YM_BIN'}/../etc");
}

use 5.008008;
use warnings;
use strict;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw ( 

  AddCommand
  AddHost
  AddHostgroup
  AddService
  
  DeleteCommand
  DeleteHost
  DeleteHostgroup
  DeleteService
  
  ModifyCommand
  ModifyHost
  ModifyHostgroup
  ModifyService
  
  CopyHost
  CopyService
  
  List
  Dump
  
  VerifyDataStructure
  
  GenerateCfg
  
  GetMembers
  GetObjectList
  
  GetStruct
  SaveStruct
  
  List
  Dump

);

our $VERSION = '0.02';

my $ymcfg = "$ENV{'YM_ETC'}/ymconfig.pl";

if (-s $ymcfg) {
  do $ymcfg;
}
else {
  die "No config file [$ymcfg].\n";
}

use Data::Dumper;
use File::Copy;
use Storable qw/dclone store retrieve/;

require "Ym/ymcmd.pl";
require "Ym/ymcommon.pl";
require "Ym/ymgen.pl";
require "Ym/ymparse.pl";
require "Ym/ymdata.pl";
require "Ym/ymstat.pl";

eval {
  require "Ym/ymspecific.pl";
  YmSpecific->import();
};

1;

__END__

=head1 NAME

Ym.pm - library for parsing/modifying/generating Nagios configuration.

=head1 INSTALL

Before you will be able to use any functions from this module,
you have to give it a config file.

It is better to place config in /usr/local/etc/ymconfig.pl or make a lymlink.

All directories should be present and ym must have access and write permissions.

Sample config file looks like in example:

  {
    package Ym;
  
    $YMHOME = '/home/monitor/work/ym';
  
    # Place to keep serialized Nagios configs.
    # This is needed for running multiple ym commands before
    # building new configuration files.
    $STRUCT_FILE = "$YMHOME/store/config.struct";
  
    # Specify user and group. Ym will act and use their permissions.
    # This feature will come later.
    # $YM_USER  = 'monitor';
    # $YM_GROUP = 'monitor';
  
    # Tell ym where you keep Nagios configs.
    $NAGIOS_CFG_DIR = '/home/monitor/NAGIOS/etc';
    $NAGIOS_CFG_NAME = 'nagios.cfg';
    $NAGIOS_MAIN_CFG = "$NAGIOS_CFG_DIR/$NAGIOS_CFG_NAME";
  
    # Place to build test configuration when 'verify-cfg' command is called.
    $WORKPLACE = "$YMHOME/tmp/etc";
  
    $HOSTNAME = `hostname -f`;
    chomp($HOSTNAME);
  
    $VERBOSE = 0;
    $DEBUG   = 0;
  
    # Run ym with a '--diff' option by default.
    $SHOW_DIFF_BY_DEFAULT = 1;
  
    # Backup *.cfg files from NAGIOS_CFG_DIR defore generating 
    # new configs when 'make-cfg' is called.
    $BACKUP_CONFIG_FILES = 1;
    $BACKUP_PATH = '/var/backups/ym/nagios_cfg_backup';

    # Turn this option on if you want to add ymspecific.pl part to Ym.
    # This will call Ym::GenerateSpecific($tree, $Ym::HOSTNAME)
    # where you can put code for building host specific configuraion.
    $ENABLE_YM_SPECIFIC = 0;  
  }

=head1 SYNOPSIS

Type 'ym --help' and see all available console commands.

Now describe usage of different subroutines.

  use Ym;

  # STRUCT_FILE and NAGIOS_MAIN_CFG should be defined in ymconfig.pl
  # Will parse Nagios configs or use serialized cache if any.
  my $tree = Ym::GetStruct($Ym::STRUCT_FILE, $Ym::NAGIOS_MAIN_CFG);

  # Add a new command
  Ym::AddCommand($tree, ['new_command'], {'command_line' => 'check_ping'});

  # Add new hosts
  Ym::AddHost($tree, ['host1', 'host2', 'READ_FILE=/tmp/hostlist'], 
    {
      'use' => 'default-host',
      'contact_groups' => 'new_user_group',
      'check_command' => 'new_command',
    }
  );

  # Add new hostgroup
  Ym::AddHostgroup($tree, ['hostgroup1'], {'members' => 'host1,host2'});

  # Add new service
  Ym::AddService($tree, ['raid'], ['host1'], [], 
    {
      'use' => 'passive-service',
      'contact_groups' => 'some-admins',
      'max_check_attempts' => 1,
    }
  );

  # or add services to hostgroup.
  Ym::AddService($tree, ['raid'], [], ['hostgroup1'], {'use' => 'raid-service'});

Almost the same usage for DeleteCommand, DeleteHost, DeleteHostgroup, DeleteService and 

ModifyCommand, ModifyHost, ModifyHostgroup, ModifyService subroutines.

Save all changes in serialized file ($STRUCT_FILE variable must be defined in ymconfig.pl).

  Ym::SaveStruct($tree, $Ym::STRUCT_FILE);

Generate new config in specified dir.

  Ym::GenerateCfg($tree, $dest_dir);


=head1 AUTHOR

Andrey Grunau, E<lt>andrey-grunau@yandex.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Andrey Grunau

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
