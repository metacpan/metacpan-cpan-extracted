#!/usr/bin/perl -w

##
## This will install the latest version of the GO database onto your
## server and remove previous versions installed by this script. If
## you are going to run this script on the same machine that hosts the
## database, probably no flags or modifications are
## necessary. However, if your setup is in any way interesting, you
## can modify the behavior of this script either with command line
## flags or by changing the values in the "%local" hash at the top of
## the file.
##
##
## NOTES:
##
## Make sure that the prefix is unique--this script will try to delete
## all databases that have that prefix.
##
## Assumes that it is being run with the appropriate permissions to
## access and modify the database.
##
## Assumes that the GO mirror you are using has the same directory and
## file namaing conventions as the main site at
## "ftp.geneontology.org".
##
## Assumes that 'gzip', 'mysql', 'mysqladmin', and 'mysqlshow' exist
## on the system and behave in a fairly standard way.
##
## Assumes you have Net::FTP installed.
##
## Assumes that you can create temporary files.
##
## 'show_databases' is not a great piece of work.
##

use strict;

use Getopt::Std;
use File::Temp;
use Net::FTP;
use File::Basename;
use Cwd 'realpath';
use vars qw(
	    $opt_h
	    $opt_v
	    $opt_i
	    $opt_n
	    $opt_g
	    $opt_m
	    $opt_a
	    $opt_s
	    $opt_f
	    $opt_l
	    $opt_d
	    $opt_u
	    $opt_p
	    $opt_P
	    $opt_t
	    $opt_e
	    $opt_z
	    $opt_D
	    $opt_M
	   );

## Sane and easy to modify defaults.
my %local = (
	     FTP_ARCHIVE => 'ftp.geneontology.org',
	     FTP_PATH => '/pub/go/godatabase/archive/latest-full',
	     FTP_PATH_LITE => '/pub/go/godatabase/archive/latest-lite',
	     FTP_LOGIN => 'anonymous',
	     FTP_PASSWORD => '',
	     FTP_USE_PASSIVE_MODE => 0,

	     DB_HOST => 'localhost',
	     DB_USER => '',
	     DB_PASS => '',
	     DB_PORT => '3306',

	     EXTENSION => 'go_latest',

	     GO_DB_ARCH_PREFIX => 'go_',
	     GO_DB_ARCH_SUFFIX => '-assocdb-data',
	     GO_DB_ARCH_SUFFIX_LITE => '-seqdb-data',
	     GO_DB_ARCH_EXTENSION => '.gz',

	     FS_DOWNLOAD_DIR => '/tmp',
	     FS_MYSQL_FULL => 'mysql',
	     FS_MYSQLADMIN_FULL => 'mysqladmin',
	     FS_MYSQLSHOW_FULL => 'mysqlshow',
	     FS_GZIP_FULL => 'gzip',

	     DATE => '98765432'
	    );

getopts('hvzing:m:a:s:f:l:d:u:p:P:t:e:D:M:');

if ( $opt_h ) {

  print <<EOC;

  Usage:
     go_db_install.pl [-h] [-v] [-i] [-n]
                      [-g <arg>] [-m <arg>] [-a <arg>] [-s <arg>]
                      [-f <arg>] [-l <arg>] [-z]
                      [-d <arg>] [-u <arg>] [-p <arg>] [-P <arg>]
                      [-t <arg>]
                      [-e <arg>]
                      [-D <YYYYMMDD>]
                      [-L <label>]

  Options:
     -h               Print this message.
     -v               Enable more verbose messages. This is useful for checking
                      installation errors.
     -i               Get the lite database (without IEAs).
     -n               Do not attempt to add views and materialized views.
     -g <location>    Path and executable of gzip (or functional equivalent).
     -m <location>    Path and executable of mysql.
     -a <location>    Path and executable of mysqladmin.
     -s <location>    Path and executable of mysqlshow.
     -f <ftp server>  Fully qualified name of FTP server.
     -l <ftp path>    Path to archive on FTP server.
     -z               Use FTP passive mode (helps getting through firewalls)
     -d <db host>     Host of database.
     -u <db user>     User name on database.
     -p <db password> User password on database.
     -P <db port>     Port number for database (defaults to 3306).
     -t <tmp dir>     Location of tmp direetory (defaults to /tmp).
     -e <suffix>      Suffix to use in naming the databases.
     -D <date>        Date in YYYYMMDD format. Eclipses many other options.
                      Will load a seqdb/assocdb GO DB from the past. Can be used
                      with -e.
     -M <date>        Migrate/map the schema to the latest version (experimental). Changes after <date> are applied.

  Examples:

  ## Load the latest lite DB onto spitz, under the name go_latest_lite, views included.
  /users/sjcarbon/local/src/cvs/go-dev/go-db-perl/scripts/go_db_install.pl -i -e go_latest_lite -v -d spitz

  ## Load the latest full onto spitz, no views included.
  /users/sjcarbon/local/src/cvs/go-dev/go-db-perl/scripts/go_db_install.pl -v -n -d spitz

  ## Load historical DB onto spitz (2004-01-01), include views.
  /users/sjcarbon/local/src/cvs/go-dev/go-db-perl/scripts/go_db_install.pl -v -i -D 20040101 -d spitz

  ## Load historical DB onto spitz (2004-01-01), include views, was name ye_old_db
  /users/sjcarbon/local/src/cvs/go-dev/go-db-perl/scripts/go_db_install.pl -v -i -D 20040101 -e ye_old_db -d spitz

EOC

} else {

  ##
  ## Preparation from command line arguments.
  ##

  ## Check our options and set variables accordingly.
  if ( $opt_v ) {
    print "Will be verbose.\n"; }
  if ( $opt_i ) {
    $local{FTP_PATH} = $local{FTP_PATH_LITE};
    $local{GO_DB_ARCH_SUFFIX} = $local{GO_DB_ARCH_SUFFIX_LITE};
    print "Will get lite (!IEA) database.\n" if $opt_v; }
  if ( $opt_n ) {
    print "Will not attempt to add views and materialized views to database.\n"
      if $opt_v;
  }else{
    print "Will attempt to add views and materialized views to database.\n"
      if $opt_v;
  }
  if ( $opt_g ) {
    $local{FS_GZIP_FULL} = $opt_g;
    print "\"gzip\" is: $opt_g.\n" if $opt_v; }
  if ( $opt_m ) {
    $local{FS_MYSQL_FULL} = $opt_m;
    print "\"mysql\": $opt_m.\n" if $opt_v; }
  if ( $opt_a ) {
    $local{FS_MYSQLADMIN_FULL} = $opt_a;
    print "\"mysqladmin\": $opt_a.\n" if $opt_v; }
  if ( $opt_s ) {
    $local{FS_MYSQLSHOW_FULL} = $opt_s;
    print "\"mysqlshow\": $opt_s.\n" if $opt_v; }
  if ( $opt_f ) {
    $local{FTP_ARCHIVE} = $opt_f;
    print "FTP server will be: $opt_f.\n" if $opt_v; }
  if ( $opt_l ) {
    $local{FTP_PATH} = $opt_l;
    print "Path on the FTP server will be: $opt_l.\n" if $opt_v; }
  if ( $opt_z ) {
    $local{FTP_USE_PASSIVE_MODE} = 1;
    print "Will use FTP passive mode.\n" if $opt_v; }
  if ( $opt_d ) {
    $local{DB_HOST} = $opt_d;
    print "Database host will be: $opt_d.\n" if $opt_v; }
  if ( $opt_u ) {
    $local{DB_USER} = $opt_u;
    print "Database user will be: $opt_u.\n" if $opt_v; }
  if ( $opt_p ) {
    $local{DB_PASS} = $opt_p;
    print "Database password will be: $opt_p.\n" if $opt_v; }
  if ( $opt_P ) {
    $local{DB_PORT} = $opt_P;
    print "Database port number will be: $opt_P.\n" if $opt_v; }
  if ( $opt_t ) {
    $local{FS_DOWNLOAD_DIR} = $opt_t;
    print "Temporary directory will be: $opt_t.\n" if $opt_v; }

  ## Running in old mode.
  if ( $opt_D ) {

    if ( $opt_D =~ /^\d{8}$/ ){
      print "Will look for archived GO database from: $local{DATE}\n"
	if $opt_v;
    }else {
      die "Your date argument is not valid--it must be in YYYYMMDD format.";
    }

    $local{DATE} = $opt_D;

    $local{FTP_PATH} = '/pub/go/godatabase/archive/full';
    if ($opt_i) {
        $local{FTP_PATH} = '/pub/go/godatabase/archive/lite';
    }
    $local{EXTENSION} = 'go_old_' . $local{DATE};
    #$local{GO_DB_ARCH_SUFFIX} = '-seqdb-data';
    $local{GO_DB_ARCH_SUFFIX} = '-assocdb-data';

    print "Date will be: $local{DATE}.\n" if $opt_v;
    print "Database extension will be: $local{EXTENSION}.\n" if $opt_v;
  }

  if ( $opt_e ) {
    $local{EXTENSION} = $opt_e;
    print "Database extension will be: $opt_e.\n" if $opt_v; }

  ##
  ## Get date from FTP site.
  ##

  ## Connection.
  my $ftp = undef;
  if ( $local{FTP_USE_PASSIVE_MODE} ) {
    $ftp = Net::FTP->new($local{FTP_ARCHIVE}, Passive => 1 )
      or die "[FTP] Cannot connect (PASV) to $local{FTP_ARCHIVE}: $!";
    print "[FTP] Connected (PASV) to \"" . $local{FTP_ARCHIVE} . "\".\n" if $opt_v;
  }else {
    $ftp = Net::FTP->new($local{FTP_ARCHIVE})
      or die "[FTP] Cannot connect to $local{FTP_ARCHIVE}: $!";
    print "[FTP] Connected to \"" . $local{FTP_ARCHIVE} . "\".\n" if $opt_v;
  }

  ## Login.
  $ftp->login($local{FTP_LOGIN}, $local{FTP_PASSWORD})
    or die "[FTP] Cannot login as \"$local{FTP_LOGIN}\": $!";
  print "[FTP] Logged in as \"$local{FTP_LOGIN}\".\n" if $opt_v;

  ## Change to binary.
  $ftp->binary()
    or die "[FTP] Cannot change to binary mode: $!";
  print "[FTP] Changed to binary mode.\n" if $opt_v;

  ## Descend.
  $ftp->cwd("$local{FTP_PATH}")
    or die "[FTP] Cannot change working directory to $local{FTP_PATH}: $!";
  print "[FTP] Changed directory to \"" . $local{FTP_PATH} . "\".\n"
    if $opt_v;

  ## Get a file listing.
  my @listing = $ftp->ls()
    or die "[FTP] Cannot get a listing: $!";
  print "[FTP] Received file listing.\n" if $opt_v;


  ##
  ## Toggle between "old" mode and "most recent" mode.
  ##

  my $go_db_archive_name = '';
  my $db_stamp_name = '';
  if( $opt_D ){

    ## Match date and descend if possible.
    my $found_key_p = 0;
    my $key = '';
    foreach my $file (@listing) {

      my @columns = split /\s+/, $file;
      my $name = $columns[0];

      if ( $name =~ /(\d{4})\-(\d{2})\-(\d{2})/ ) {
	$key = $1 . $2 . $3;

	if ( $key eq $local{DATE} ) {

	  $found_key_p = 1;

	  ## Descend again.
	  $ftp->cwd($name)
	    or die "[FTP] Cannot change working directory to: $name";
	  print "[FTP] Changed directory to \"" . $name . "\".\n"
	    if $opt_v;

	  last;
	}
      }
    }

    ## Continue on found key.
    if ( $found_key_p ) {

      ## Get a -AlF listing.
      @listing = $ftp->dir()
	or die "[FTP] Cannot get an inner listing: $!";
      print "[FTP] Received inner file listing.\n" if $opt_v;
      foreach my $file (@listing) {

	my @columns = split /\s+/, $file;
	my $perms = $columns[0];
	my $name = $columns[8];

	my $beg = $local{GO_DB_ARCH_PREFIX};
	my $end = $local{GO_DB_ARCH_SUFFIX} . $local{GO_DB_ARCH_EXTENSION};
	if ( $name =~ /^$beg[a-zA-Z0-9\-\_\:\=\+]+$end$/ ) {
	  $go_db_archive_name = $name;
	  last;
	}
      }
    }else {
      die "Could not find similar date: $! [available: @listing]";
    }

    die "Could not find appropriate tarchive: $!" if ! $go_db_archive_name;

    ## Date already included...
    $db_stamp_name = $local{EXTENSION} . '_STAMP';
    #$db_stamp_name = $go_db_archive_name;

  }else {

    my $ftp_date = '_NO_FTP_DATE_';

    ## Find date of most recent database in archive.
    foreach my $file (@listing) {
      ## The check depends on how the DB names are structured.
      if( $opt_i ){
	if ( $file =~ /(\d{8})/ ) {
	  $ftp_date = $1;
	  last;
	}
      }else{
	if ( $file =~ /(\d{6})/ ) {
	  $ftp_date = $1;
	  last;
	}
      }
    }
    die "[FTP] Cannot find a date string: $!" if $ftp_date eq '_NO_FTP_DATE_';
    print "[FTP] Archive date string is \"$ftp_date\".\n" if $opt_v;


    ## Show what the full DB string we're searching for.
    $db_stamp_name = $local{EXTENSION} . $ftp_date;
    $go_db_archive_name =
      $local{GO_DB_ARCH_PREFIX} .
	$ftp_date .
	  $local{GO_DB_ARCH_SUFFIX} .
	    $local{GO_DB_ARCH_EXTENSION};
  }

  ## Check our progress.
  print "GO database name is \"$local{EXTENSION}\".\n" if $opt_v;
  print "GO database stamp name is \"$db_stamp_name\".\n" if $opt_v;
  print "FTP archive name is \"$go_db_archive_name\".\n" if $opt_v;

  ###
  ### Since we can't assume the existance of the file, we'll try and
  ### download it (and hopefully doe on error) before we drop the
  ### database.
  ###

  ## Create temp file for the FTP download.
  my $tmp_dl_file = new File::Temp(TEMPLATE => 'go_db_download_XXXXX',
				   DIR => $local{FS_DOWNLOAD_DIR},
				   SUFFIX => $local{GO_DB_ARCH_EXTENSION});
  die "[FS] Could not create temporary download file: $!" if ! $tmp_dl_file;
  print "[FS] Created temporary download file.\n" if $opt_v;

  ## Create temp file for the gunzipped database.
  my $tmp_gunzip_file = new File::Temp(TEMPLATE => 'go_db_gunzipped_XXXXX',
				       DIR => $local{FS_DOWNLOAD_DIR},
				       SUFFIX => '');
  die "[FS] Could not create temporary gunzip file: $!" if ! $tmp_gunzip_file;
  print "[FS] Created temporary gunzip file.\n" if $opt_v;

  ## Attempt to download.
  print "[FTP] Starting GO database download (this may take some time)...\n"
    if $opt_v;
  #print "<<<" . $tmp_dl_file . ">>>\n";

  $ftp->get( $go_db_archive_name, $tmp_dl_file )
    or die "[FTP] Cannot download $go_db_archive_name: $!";
  print "[FTP] Downloaded \"" . $go_db_archive_name . "\".\n"
    if $opt_v;

  ## Done FTP.
  $ftp->quit;

  ###
  ### Check DB dates and look for db match.
  ###

  ## Get listings from database.
  my @databases = show_databases($local{FS_MYSQLSHOW_FULL},
				 $local{DB_HOST},
				 $local{DB_USER},
				 $local{DB_PASS},
				 $local{DB_PORT});
  print "[DB] Got listing.\n" if $opt_v;

  my $db_exists = 0;
  my $fresh_stamp = 0;
  my @previous_stamps = ();

  ## Check database for things named like what we're looking for.
  foreach my $database ( @databases ) {
    #print "<<<" . $database . ">>>\n";
    if ( $database =~ /^$local{EXTENSION}$/ ) {
      #print "\tDB MATCH: " . $database . ">>>\n";
      $db_exists = 1;
    } elsif ( $database =~ /^$db_stamp_name$/ ) {
      #print "\tSTAMP MATCH: " . $database . ">>>\n";
      $fresh_stamp = 1;
    } elsif ( ($database =~ /^$local{EXTENSION}\d{6}$/ && !$opt_i && !$opt_D) ||
	      ($database =~ /^$local{EXTENSION}\d{8}$/ && $opt_i && !$opt_D) ){
      #print "\tSTAMP SIMILAR: " . $database . ">>>\n";
      push @previous_stamps, $database;
    }
  }

  ###
  ### Make sure that we have no database and no fresh stamp. Bail if
  ### we are up-to-date.
  ###

  ## The first case means that everything is normal and up-to-date, so
  ## we can just bail out here.
  if ( $db_exists && $fresh_stamp ) {

    print "You are already using the most current GO database.\n"
      if $opt_v;

  } else {

    ## We want to make it so no database or fresh stamp exists by the
    ## time we are done this if-else cascade.
    if ( ! $db_exists && $fresh_stamp ) {

      ## We lack a database, but not a fresh stamp--drop the stamp.
      print "No database, but a fresh stamp exists. Will try to fix.\n"
	if $opt_v;
      drop_database($local{FS_MYSQLADMIN_FULL},
		    $local{DB_HOST},
		    $local{DB_USER},
		    $local{DB_PASS},
		    $local{DB_PORT},
		    $db_stamp_name);
      print "[DB] Fixed (dropped) stamp.\n" if $opt_v;

    } elsif ( $db_exists && ! $fresh_stamp ) {

      ## We lack a fresh stamp, but have a database--drop the database.
      print "You are not using the most current GO database.\n"
	if $opt_v;
      drop_database($local{FS_MYSQLADMIN_FULL},
		    $local{DB_HOST},
		    $local{DB_USER},
		    $local{DB_PASS},
		    $local{DB_PORT},
		    $local{EXTENSION});
      print "[DB] Dropped old database.\n" if $opt_v;

    }

    ###
    ### Generate database from local file.
    ###

    ## Database creation.
    create_database($local{FS_MYSQLADMIN_FULL},
		    $local{DB_HOST},
		    $local{DB_USER},
		    $local{DB_PASS},
		    $local{DB_PORT},
		    $local{EXTENSION});
    print "[DB] Created database.\n" if $opt_v;

    ## Fresh stamp creation.
    create_database($local{FS_MYSQLADMIN_FULL},
		    $local{DB_HOST},
		    $local{DB_USER},
		    $local{DB_PASS},
		    $local{DB_PORT},
		    $db_stamp_name);
    print "[DB] Created database stamp.\n" if $opt_v;

    ## Gunzip database.
    print "[FS] Starting GO database unpacking (this may take some time)...\n"
      if $opt_v;
    gunzip_file($local{FS_GZIP_FULL}, $tmp_dl_file, $tmp_gunzip_file);
    print "[FS] Finished unpacking.\n" if $opt_v;

    ## Install database.
    print "[DB] Starting GO database install (this may take some time)...\n"
      if $opt_v;
    database_install($local{FS_MYSQL_FULL},
		     $local{DB_HOST},
		     $local{DB_USER},
		     $local{DB_PASS},
		     $local{DB_PORT},
		     $local{EXTENSION},
		     $tmp_gunzip_file);
    print "[DB] Finished installing.\n" if $opt_v;

    ## Remove other matching databases.
    foreach my $db_stamp (@previous_stamps) {
      drop_database($local{FS_MYSQLADMIN_FULL},
		    $local{DB_HOST},
		    $local{DB_USER},
		    $local{DB_PASS},
		    $local{DB_PORT},
		    $db_stamp);
      print "[DB] Removed stamp $db_stamp.\n" if $opt_v;
    }

  }

  # migration of schema forward
  if( $opt_M ){

    ##
    ## Make sure that we're in the environment that we want to be
    ## in. This is to make sure that we can add  the
    ## changes in "go-deb/go-db-perl/sql/migrate" 
    ##

    ## Hunt down the paths.
    my $exec_path = realpath($0);
    my($top_path, $remainder) =
      split 'go-db-perl/scripts/go_db_install', $exec_path;


    ## Test additional migrate path.
    my $migrate_dir_path = $top_path . 'sql/migrate/';
    die "Migrates directory not accessible."
      if ! -d  $migrate_dir_path || ! -R $migrate_dir_path;
    print "[SYSTEM] Found: \"" . $migrate_dir_path . "\".\n" if $opt_v;

    my @change_files = split(/\n/,`ls $migrate_dir_path/changes-*.{sql,sh}`);
    print "[DB] Change Files: @change_files \n" if $opt_v;


    ## Make sure that the migrates are in the DB.
    print "[DB] Starting schema migration changes to DB.\n" if $opt_v;
    foreach my $change_file (@change_files) {

        print "[DB] testing: $change_file\n" if $opt_v;

        # e.g. changes-2007-08-23.sql
	if ($change_file =~ /changes\-(\d+)\-(\d+)\-(\d+)\.(\w+)/) {
	    my $change_applied_date = "$1$2$3";
	    my $suffix = $4;
	    if ($change_applied_date < $opt_M) {
		print "[DB] skipping: $change_file\n" if $opt_v;
	    }

	    if ($suffix eq 'sql') {
		my $short_name = basename($change_file);
		print "[DB] Applying: \"" . $short_name . "\".\n" if $opt_v;
		try_to_add_to_database($local{FS_MYSQL_FULL},
				       $local{DB_HOST},
				       $local{DB_USER},
				       $local{DB_PASS},
				       $local{DB_PORT},
				       $local{EXTENSION},
				       $change_file);
	    }
	    elsif ($suffix eq 'sh') {
		my $cmd = "sh $change_file -h $local{DB_HOST}  -port $local{DB_PORT} -d $local{EXTENSION}";
		print "[MIGRATE] cmd: $cmd\n" if $opt_v;
                system($cmd);
	    }
	    else {
		print "[DB] skipping: $change_file, format=$suffix. can only handle .sql or .sh so far\n" if $opt_v;
		# TODO
	    }
	}
        else {
		print "[DB] skipping: $change_file, doesn't look like a change file\n" if $opt_v;
        }
    }
  }

  ## Shall we add the views 'n stuff?
  if( ! $opt_n ){

    ##
    ## Make sure that we're in the environment that we want to be
    ## in. This is to make sure that we can add and materialize the
    ## views in "go-deb/go-db-perl/sql/view" with utils in
    ## "go-deb/go-db-perl/sql/utils".
    ##

    ## Hunt down the paths.
    my $exec_path = realpath($0);
    my($top_path, $remainder) =
      split 'go-db-perl/scripts/go_db_install', $exec_path;

    ## Test matview procedure path.
    my $util_exec_path = $top_path . 'sql/util/materialized_views_proc.sql';
    die "Couldn\'t find materialized_views_proc.sql"
      if ! -f  $util_exec_path || ! -R $util_exec_path;
    my $short_name = basename($util_exec_path);
    print "[SYSTEM] Found: " . $short_name . ".\n" if $opt_v;

    ## Make sure that the procedure is in the DB.
    print "[DB] Starting addition of procedure to DB.\n" if $opt_v;
    add_to_database($local{FS_MYSQL_FULL},
		    $local{DB_HOST},
		    $local{DB_USER},
		    $local{DB_PASS},
		    $local{DB_PORT},
		    $local{EXTENSION},
		    $util_exec_path);
    print "[DB] Finished addition.\n" if $opt_v;

    ## Test additional view path.
    my $view_dir_path = $top_path . 'sql/view/';
    die "Views directory not accessible."
      if ! -d  $view_dir_path || ! -R $view_dir_path;
    print "[SYSTEM] Found: \"" . $view_dir_path . "\".\n" if $opt_v;

    ## Make sure that the views are in the DB.
    print "[DB] Starting addition of views to DB.\n" if $opt_v;
    open(AUTOLOAD_VIEWS, "<" . $view_dir_path . "AUTOLOAD_VIEWS")
      or die "Couldn\'t find views directory.";
    while (<AUTOLOAD_VIEWS>) {

      ## Don't need commented lines.
      if( ! /^\#/ ){

	## Check for extance.
	chomp;
	my $view_file = $view_dir_path . $_;
	if( ! -f  $view_file || ! -R $view_file ){
	  die "View file not accessible: \"" . $view_file . "\".\n";
	}else{
	  my $short_name = basename($view_file);
	  print "[DB] Adding view: \"" . $short_name . "\".\n" if $opt_v;
	  try_to_add_to_database($local{FS_MYSQL_FULL},
				 $local{DB_HOST},
				 $local{DB_USER},
				 $local{DB_PASS},
				 $local{DB_PORT},
				 $local{EXTENSION},
				 $view_file);
	}
      }
    }
    print "[DB] Finished addition of views.\n" if $opt_v;

    ## Make sure that the materialized views are in the DB.
    print "[DB] Starting addition of materialized views to DB.\n" if $opt_v;
    open(AUTOLOAD_MATVIEWS, "<" . $view_dir_path . "AUTOLOAD_MATVIEWS")
      or die "Couldn\'t find materialized views directory.";
    while (<AUTOLOAD_MATVIEWS>) {

      ## Don't need commented lines.
      if( ! /^\#/ ){

	## Check for extance.
	chomp;
	my $matview_file = $view_dir_path . $_;
	if( ! -f  $matview_file || ! -R $matview_file ){
	  die "Materialized view file not accessible: \"" .
	    $matview_file . "\".\n";
	}else{
	  my $short_name = basename($matview_file);
	  print "[DB] Adding materialized view: \"" .
	    $short_name . "\".\n" if $opt_v;
	  try_to_add_to_database($local{FS_MYSQL_FULL},
				 $local{DB_HOST},
				 $local{DB_USER},
				 $local{DB_PASS},
				 $local{DB_PORT},
				 $local{EXTENSION},
				 $matview_file);
	}
      }
    }
    print "[DB] Finished addition of materialized views.\n" if $opt_v;
  }
  print "Done.\n" if $opt_v;
}


## A simple wrapper to get an array of strings from the host that
## resemble database names (along with any other junk returned by
## mysqlshow).
## WARNING: This really is a nasty sub.
sub show_databases{

  my ($mysqlshow, $host, $user, $pass, $port) = @_;
  my @return_db = ();

  #print ">>> $mysqlshow -h $host -u $user -p$pass -P $port\n";
  my @databases = `$mysqlshow -u $user -p$pass -P $port  -h $host`
    or die "[DB] Cannot show database: $!";

  foreach my $database ( @databases ){
    $database =~ s/\s|\|//g;
    push @return_db, $database;
  }

  return @return_db;
}


## A simple wrapper to create a database.
sub create_database{

  my ($mysqladmin, $host, $user, $pass, $port, $name) = @_;

  ! system("$mysqladmin -h $host -u $user -p$pass -P $port create $name")
    or die "[DB] Cannot create database: $!";
}


## A simple wrapper to drop a database.
sub drop_database{

  my ($mysqladmin, $host, $user, $pass, $port, $name) = @_;

  ! system("$mysqladmin -f -h $host -u $user -p$pass -P $port drop $name")
    or die "[DB] Cannot create database: $!";
}


## A simple wrapper to load the database.
sub database_install{

  my ($mysql, $host, $user, $pass, $port, $name, $file) = @_;

  ! system("$mysql -h $host -u $user -p$pass -P $port $name < $file")
    or die "[DB] Cannot load database tables: $!";
}


## A simple wrapper to load stuff into database.
sub add_to_database{

  my ($mysql, $host, $user, $pass, $port, $name, $file) = @_;

  ! system("$mysql -h $host -u $user -p$pass -P $port $name < $file")
    or die "WARNING: [DB] Cannot add $file to database: $!";
}


## A simple wrapper to try and load stuff into database.
sub try_to_add_to_database{

  my ($mysql, $host, $user, $pass, $port, $name, $file) = @_;

  my $short_name = basename($file);
  ! system("$mysql -h $host -u $user -p$pass -P $port $name < $file")
    or warn "WARNING: [DB] Cannot add file to database: $short_name";
}


## A simple wrapper for gunzipping one file to another.
sub gunzip_file{

  my ($gzip, $zfile, $uzfile) = @_;

  ! system("$gzip -c -d $zfile > $uzfile")
    or die "[FS] Cannot gunzip file $!";
}
