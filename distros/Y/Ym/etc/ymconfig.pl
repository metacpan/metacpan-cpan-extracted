{
  package Ym;

  $YMHOME = '/home/monitor/work/ym';

  # Place to keep serialized Nagios configs.
  # This is needed for running multiple ym commands before
  # building new configuration files.
  $STRUCT_FILE = "$YMHOME/store/config.struct";

  # Specify user and group. Ym will act and use their permissions.
  $YM_USER  = 'monitor';
  $YM_GROUP = 'monitor';

  # Tell ym where are your Nagios configs.
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

  $ENABLE_YM_SPECIFIC = 0;
}

