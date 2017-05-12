#!/usr/bin/perl -w
use strict;
use warnings;
$|++; 

#if we run with the force arg or we can't find Configuration.pm, continue
#TODO: THINK: why do we shell out to do this test? it's in Makefile.PL too
my $config_exists = `$^X -e 'eval { require XML::Comma::Configuration }; print "ok" unless \$@;'` eq 'ok';
$config_exists ||= -e "blib/lib/XML/Comma/Configuration.pm";
my $force = defined($ARGV[0]) && ($ARGV[0] =~ /force/);
if($config_exists and !$force) {
	warn "warning: Configuration.pm exists, skipping $0\n"; 
	exit 0;
}
shift(@ARGV); 

print <<'END';

We need to do a bit of configuration. First, where will
XML::Comma's "root" directory be? A common choice for
production installs is '/usr/local/comma', although you'll
need to make sure you have permission to create
directories under '/usr/local' if you want the tests we'll
run in a minute to pass. The default choice is 'TEST', right
here wherever we are now. You can always change this later by
editing the Configuration.pm file.

END

use Storable;
my $DEFAULTS_FILE = "misc/default_config";
if (! -e $DEFAULTS_FILE) {
  #create DEFAULTS_FILE if it's not there
  store {
    'comma_root' => '/usr/local/comma',
    'mysql_user' => 'root',
    'mysql_pass' => '',
    'mysql_db'   => 'comma',
    'mysql_host' => 'localhost',
  }, $DEFAULTS_FILE; 
}
my $DEFAULTS = retrieve($DEFAULTS_FILE); 

sub prompt_and_save {
  my ($text, $var_name, %opts) = @_;
  my $empty_ok = $opts{empty_ok} || 0;
  my $default = $DEFAULTS->{$var_name};
  print "$text";
  print " [$default]" unless $empty_ok;
  print ": ";
  my $ret = <>; chop $ret;
  $ret = $empty_ok ? $ret : ($ret || $default);

  # save for the next run in case of failure
  $DEFAULTS->{$var_name} = $ret;
  store $DEFAULTS, $DEFAULTS_FILE;

  return $ret; 
}

my $comma_root = prompt_and_save ("XML::Comma comma_root", "comma_root");

### postgres install cheat sheat...
# su postgres
# $ createuser comma
# Shall the new user be allowed to create databases? (y/n) y
# Shall the new user be allowed to create more new users? (y/n) n
# CREATE USER
# 
# $ createdb -O comma comma
# CREATE DATABASE
# 
# $ psql -d comma
# comma=# grant all on database comma to `whoami`;
# comma=# grant all on database comma to root;
# comma=# grant all on database comma to apache, etc...;
# comma=# \q

print <<'END';

And we need to be able to talk to a database. We'll assume
for now that you're using mysql. (If that's not the case,
check the XML::Comma documentation for how to configure
database access in the Configuration.pm file.) We need
a local mysql user and password, and this user needs to
have permission to create new databases. The defaults
are 'root' and '', respectively. We also need the name 
of the database inside mysql that XML::Comma will use (and
to which all comma processes will be restricted). The 
default is 'comma'. If you are using postgres, just
accept the default values here, then edit the generated
lib/XML/Comma/Configuration.pm before running make.

END

my $host     = prompt_and_save ("mysql host", "mysql_host");
my $dbn      = prompt_and_save ("mysql database name", "mysql_db");
my $dbu      = prompt_and_save ("mysql user", "mysql_user");
my $dbp      = prompt_and_save ("mysql password (WILL ECHO!)",
                  "mysql_pass", empty_ok => 1);
my $dsn_xtra = prompt_and_save ("extra DSN parameters (optional)",
                  "dsn_xtra", empty_ok => 1);

print <<END;

Okay, thanks. For reference, we're using -->

XML::Comma root directory    $comma_root
mysql user                   $dbu
mysql password               $dbp
mysql database name          $dbn
mysql host                   $host
END

#create DSN from info collected
if($dsn_xtra) {
  $dsn_xtra .= ";" unless($dsn_xtra =~ /\;$/);
  $dsn_xtra .= "mysql_local_infile=1";
} else {
  $dsn_xtra =  "mysql_local_infile=1";
}
my $dsn = "DBI:mysql:$dbn:$host;$dsn_xtra";

print "extra DSN parameters         $dsn_xtra\n" if($dsn_xtra);
print "dsn                          $dsn\n";
print "\n";

#
# try to create database
#

#try to connect...
eval {
  require DBI;
  require DBD::mysql;
}; if($@) {
  die "you must have DBI and DBD::mysql installed to run comma-create-config.pl\n";
}

eval { DBI->connect($dsn, $dbu, $dbp, {RaiseError => 1}); };

#if there was an error connecting, try to create the db by hand
if($@) {
  print "database does not exist, trying to create it...\n";
  my $response = `mysqladmin --host="$host" --user="$dbu" --password="$dbp" create $dbn 2>&1`;
  if ( $response  and  $response !~ /database\s+exists/i ) {
    fail ( "could not create database: $response - is mysqladmin from mysql-client installed?" );
  }
  print "database appears to have been created successfully...\n";
}


#TODO: populate defs and macros with some standard stuff ?

my $CONFIG = <<END;
package XML::Comma::Configuration;
use base 'XML::Comma::Pkg::ModuleConfiguration'; 1;
__DATA__

##
#  system and defs directories
#
comma_root          =>     '$comma_root', 
log_file            =>     '$comma_root/log.comma', 
document_root       =>     '$comma_root/docs', 
sys_directory       =>     '$comma_root/sys', 
tmp_directory       =>     '/tmp', 

defs_directories    =>
    [
     '$comma_root/defs', 
     '$comma_root/macros', 
     '$comma_root/standard', 
     '$comma_root/test', 
    ],

#
##

defs_from_PARs    =>     1,
defs_extension    =>     '.def',
macro_extension   =>     '.macro',
include_extension =>     '.include',

#should we auto-validate a doc created with new( [ file | block ] => ... )?
validate_new      =>     1,

#for production environments that have access to Inline and cc,
#SimpleC is recommended for greater performance.
parser            =>     'PurePerl',
#parser            =>     'SimpleC',
hash_module       =>     'Digest::MD5',

mysql =>
  { sql_syntax  =>  'mysql',
    dbi_connect_info => 
    [ '$dsn', '$dbu', '$dbp',
      { RaiseError => 1,
        PrintError => 0,
        ShowErrorStatement => 1,
        AutoCommit => 1,
      },
    ],
  },
postgres =>
  { sql_syntax  =>  'Pg',
    dbi_connect_info => 
    [ 'DBI:Pg:dbname=$dbn', '', '',
      { RaiseError => 1,
        PrintError => 0,
        ShowErrorStatement => 1,
        AutoCommit => 1,
        pg_enable_utf8 => 1,
      },
    ],
  },
sqlite =>
  { sql_syntax  =>  'SQLite',
    dbi_connect_info =>
    [ 'DBI:SQLite:test.db', '', '',
      { RaiseError => 1,
        PrintError => 1,
        ShowErrorStatement => 1,
        AutoCommit => 1,
        HandleError => sub {
          my ( \$string, \$handle ) = \@_; 
          # print "handling error (\$handle)\\n";
          if ( \$string =~ m|schema has changed| ) {
            \$handle->execute();
            return 1;
          }
          return;
        },
      },
    ],
  },
### please note that postgres support is beta, and sqlite support is 
### broken. mysql is recommended for production environments.
system_db        => 'mysql',
#system_db        => 'postgres',
##system_db        => 'sqlite-DANGER-READ-NOTE-ABOVE',

END

open ( FILE, ">lib/XML/Comma/Configuration.pm" ) ||
  die "could not open file to write config into: $!\n"; 
print FILE $CONFIG; 
close FILE;
chmod 0755, "lib/XML/Comma/Configuration.pm";

#TODO: is there any reason why can't we just write out to blib instead
#      of writing to lib/ and then copying?
`cp "lib/XML/Comma/Configuration.pm" "blib/lib/XML/Comma/Configuration.pm"`;

sub fail {
  my $error = shift;
  print "-------- ERROR, CAN'T MAKE CONFIG FILE --------\n";
  die "$error\n";
}
