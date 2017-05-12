package YAML::DBH;
use strict;
use Exporter;
use DBI;
use DBD::mysql;
use Carp;
use YAML;
use vars qw(@EXPORT_OK %EXPORT_TAGS @ISA $VERSION @errstr);
@ISA = qw/Exporter/;
@EXPORT_OK = qw(yaml_dbh);
%EXPORT_TAGS = ( all => \@EXPORT_OK );
$VERSION = sprintf "%d.%02d", q$Revision: 1.8 $ =~ /(\d+)/g;



sub yaml_dbh {
   
   # 0) MAIN VARIABLES OF INTEREST

   # 0.a) the argument
   my $arg = $_[0] or croak('yaml_dbh() missing path to yaml file argument');

   # 0.b) the main arguments to open a connect via DBI are dbsource, username, and password
   my ( $dbsource, $username, $password );

   # 0.c) what we explore inside is the conf data hashref
   my $conf;




   # 1) RESOLVE THE CONF HASHREF ITSELF
   # figure out conf data, if conf was passed as a hashref or a path string

   # 1.a) if a ref, assume a conf ref was passed (hash or array, could be both?)
   if ( ref $arg ){
      $conf = $arg;
   }   
   # 1.b) otherwise assume the argument is a path string to a yaml file
   else {
      $conf = YAML::LoadFile($arg) 
         or croak("yaml_dbh(), cant YAML LoadFile: '$arg'"); 
   }




   # 2) SCAN THE CONF HASHREF FOR REQ CONNECT DATA   
   # 2.a) try mysql
   if( ! (($dbsource, $username, $password) = _findkeys_mysql($conf)) ){

      # 2.b) try sqlite
      ( $dbsource, $username, $password ) = _findkeys_sqlite($conf)

         # 2.c) or croak
         or croak("yaml_dbh() Cannot find proper params in arg '$arg' to connect via sqlite or mysql, errs: ".join(', ',@errstr));
   }



   # 3) OPEN DB HANDLE
   my $dbh = DBI->connect(
      $dbsource, 
      $username, 
      $password
   ) or die;

   return $dbh;
}


sub _findkeys_mysql {
   my $conf = shift;


   my $username = _findkey( $conf => qw(username uname user dbuser dbusername) )
      or push @errstr, "missing username";
      
   my $hostname = _findkey( $conf => qw(hostname host dbhost dbhostname) ) || 'localhost';

   my $password = _findkey( $conf => qw(password dbpass dbpassword passw dbpassw pass))
      or push @errstr, "missing password";
   
   my $database = _findkey( $conf => qw(database dbname databasename))
      or push @errstr, "missing database name";

   my $dbdriver = _findkey( $conf => qw(dbdriver driver db_driver) ) || 'mysql';

   (@errstr and scalar @errstr) and (warn("Errors: @errstr") and return);

   ### $database
   ### $hostname
   ### $username
   ### $password
   ### $dbdriver

   my $dbsource =  "DBI:$dbdriver:database=$database;host=$hostname";
   ### $dbsource

   return( $dbsource, $username, $password);
}

sub _findkeys_sqlite {
   my $conf = shift;

   my $abs_sqlite = _findkey( $conf => qw(abs_db abs_sqlite) )
      or ((push @errstr, "missing abs_sqlite") and return);

   my $dbdriver = _findkey( $conf => qw(dbdriver driver db_driver) ) || 'SQLite';

   my $dbsource = "dbi:$dbdriver:dbname=$abs_sqlite";
   ### $dbsource

   return ($dbsource,'','');
}



# pass it the conf hash ref, and a list of possible case insensitive key matches
sub _findkey {
   my $_hashref = shift;

   # convert the hashref
   my $c;
   map { $c->{lc($_)} = $_hashref->{$_} } keys %$_hashref;
   
   for my $_poss ( @_ ){
      my $poss = lc($_poss);
      if (exists $c->{$poss}){
         return $c->{$poss};
      }
   }
   return;

}

1;


__END__

=pod

=head1 NAME

YAML::DBH - instant database connection from config file on disk

=head1 SYNOPSIS

   use YAML::DBH 'yaml_dbh';
   
   my $dbh = yaml_dbh( '/home/myself/mysql_credentials.conf' );


=head2 EXAMPLE 2

   my $conf = YAML::LoadFile('./file.conf');
   
   my $dbh  = YAML::DBH::yml_dbh($conf);
   
=head2 EXAMPLE 3

   my $dbh  = YAML::DBH::yml_dbh({ 
      username => 'james', password => 'awefafw', database => 'oof',
      });

=head2 EXAMPLE 4

   my $dbh  = YAML::DBH::yml_dbh({
      abs_db => './t/sqlite.db',
   });

=head1 DESCRIPTION

Point and shoot method of getting a database handle with only a yaml 
configuration file as argument. 

This is meant for people learning perl who just want to get up and running.
It's the simplest customizable way of getting a database handle with very little code.

This is mostly for mysql- the default driver used. The conf file may also tell to 
use a sqlite db instead.

=head1 SUBS

Are not exported by default.

=head2 yaml_dbh()

Argument is abs path to yaml config file.
Returns database handle, this is a DBI connect object.

Optionally you may pass it a conf hashref as returned by YAML::LoadFile instead, to 
scan it for the parameters to open a mysql connect with, and return a database handle.


=head1 THE YAML CONFIG FILE

You basically need a text file with various parameters. We need the hostname, the username,
the password, and the name of your database to connect to. 
We allow the names of the parameters to be all kinds of silly things like 'user', 'username',
'uname','dbuser', 'DbUsEr' .. Case insensitive.
If your config file lacks hostname, we use 'localhost' by default.
You can also  specify 'driver', by default it is 'mysql'

In /etc/my.conf

   ---
   username: loomis
   host: localhost
   driver: mysql
   database: stuff
   password: stuffsee

Also acceptable:

   ---
   DBUSER: loomis
   DBHOST: tetranomicon
   DBNAME: margaux
   DBPASS: jimmy

Also acceptable:

   ---
   user; james
   pass: kumquat
   dbname: stuff

Also acceptable:

   ---
   username: jack
   password: aweg3hmva
   database: akira

Also acceptable to open a sqlite db:

   ---
   abs_sqlite: /path/to/sqlite.db

Or:

   --
   abs_db: /path/to/sqlite.db

=head1 CAVEATS

Tests will fail unless you have mysqld running, see README.

=head1 SEE ALSO

L<YAML>
L<DBI>
L<DBD::mysql>
L<DBD::SQLite>

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) 2009 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.
   
=cut


