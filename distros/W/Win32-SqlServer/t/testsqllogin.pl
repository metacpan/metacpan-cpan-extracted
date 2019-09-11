#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/t/testsqllogin.pl 14    19-07-15 23:05 Sommar $
#
# This file is C<required> by all test scripts. It defines a sub that
# connects to SQL Server, and changes current directory to the test
# directory, so that auxillary files are found, and all output files
# are written there.
#
# $History: testsqllogin.pl $
# 
# *****************  Version 14  *****************
# User: Sommar       Date: 19-07-15   Time: 23:05
# Updated in $/Perl/OlleDB/t
# Need a return in the codepage function.
# 
# *****************  Version 13  *****************
# User: Sommar       Date: 19-07-15   Time: 14:55
# Updated in $/Perl/OlleDB/t
# New parameter $autoconnect.
# 
# *****************  Version 12  *****************
# User: Sommar       Date: 19-07-09   Time: 21:04
# Updated in $/Perl/OlleDB/t
# Read codepage from the database, since codepages may not have a value
# at this point.
# 
# *****************  Version 11  *****************
# User: Sommar       Date: 19-07-08   Time: 22:11
# Updated in $/Perl/OlleDB/t
# Now retrieving code pages from Win32::SqlServer itself.
# 
# *****************  Version 10  *****************
# User: Sommar       Date: 19-05-05   Time: 17:48
# Updated in $/Perl/OlleDB/t
# Replaced is_latin1 with a function that returns the codepage.
# 
# *****************  Version 9  *****************
# User: Sommar       Date: 18-04-13   Time: 21:49
# Updated in $/Perl/OlleDB/t
# Correction to clr_enabled function.
# 
# *****************  Version 8  *****************
# User: Sommar       Date: 18-04-13   Time: 17:23
# Updated in $/Perl/OlleDB/t
# When checking whether the CLR is enabled, also take CLR strict security
# in consideration, and do not run CLR tests when strict security is in
# force.
# 
# *****************  Version 7  *****************
# User: Sommar       Date: 12-08-18   Time: 21:32
# Updated in $/Perl/OlleDB/t
# Added utilitity routine to retrieve codepage.
# 
# *****************  Version 6  *****************
# User: Sommar       Date: 08-05-01   Time: 10:48
# Updated in $/Perl/OlleDB/t
# Added parameter to permit test scripts to run without a default handle.
#
# *****************  Version 5  *****************
# User: Sommar       Date: 08-03-23   Time: 23:28
# Updated in $/Perl/OlleDB/t
# Handle empty provider value, so that it does not yield warnings about
# not being numeric.
#
# *****************  Version 4  *****************
# User: Sommar       Date: 07-07-07   Time: 16:43
# Updated in $/Perl/OlleDB/t
# Added support for specifying differnt providers.
#
# *****************  Version 3  *****************
# User: Sommar       Date: 05-07-16   Time: 17:30
# Updated in $/Perl/OlleDB/t
# We now have all the action in a special output directory.
#
# *****************  Version 2  *****************
# User: Sommar       Date: 05-06-27   Time: 21:40
# Updated in $/Perl/OlleDB/t
# Change directory to the test directory.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 05-01-02   Time: 20:54
# Created in $/Perl/OlleDB/t
#
#---------------------------------------------------------------------


sub testsqllogin
{
   my ($use_sql_init, $autoconnect) = @_;

   if (not defined $use_sql_init) {
      $use_sql_init = 1;
   }

   die '$use_sql_init must be 0 when $autoconnect = 1.'
      if $autoconnect and $use_sql_init;

   # Crack the envioronment vairable.
   my ($login) = $ENV{'OLLEDBTEST'};
   my ($server, $user, $pw, $dummy, $provider);
   ($server, $user, $pw, $dummy, $dummy, $dummy, $provider) =
        split(/;/, $login) if defined $login;
   undef $provider if defined $provider and $provider !~ /\S/;

   if ($use_sql_init) {
      return sql_init($server, $user, $pw, "tempdb", $provider);
   }
   else {
      my $X = new Win32::SqlServer;
      $X->{Provider} = $provider if defined $provider;
      $X->{AutoConnect} = 1 if $autoconnect;
      $X->setloginproperty('Server', $server);
      if ($user) {
         $X->setloginproperty('Username', $user);
         $X->setloginproperty('Password', $pw);
      }
      $X->setloginproperty('Database', 'tempdb');
      $X->connect() unless $autoconnect;
      return $X;
  }
}

sub codepage {
   my($X) = @_;

   # We don't just the codepages property, because it may not have
   # a value direct after connection.
   my ($codepage) = $X->sql_one(<<SQLEND, Win32::SqlServer::SCALAR);
    SELECT collationproperty(
                convert(nvarchar(1000), serverproperty('Collation')), 
           'CodePage')
SQLEND
   return $codepage;
}


sub clr_enabled {
   my($X) = @_;

   my ($sqlver) = split(/\./, $X->{SQL_version});

   return 0 if $sqlver <= 8;

   my $clr_enabled = $X->sql_one(<<SQLEND, Win32::SqlServer::SCALAR);
   SELECT CASE WHEN SUM(value)> 0 THEN 1 ELSE 0 END
   FROM   (SELECT convert(int, value_in_use) AS value
           FROM   sys.configurations
           WHERE  name = 'clr enabled'
           UNION ALL
           SELECT -convert(int, value_in_use)
           FROM   sys.configurations
           WHERE  name = 'clr strict security') AS u
SQLEND

   if ($clr_enabled and $sqlver >= 11 and $sqlver <=13) {
      my $tracestatus = $X->sql_one('DBCC TRACESTATUS(6545) WITH NO_INFOMSGS', Win32::SqlServer::HASH);
      if ($$tracestatus{'Status'}) {$clr_enabled = 0}
   }
   return $clr_enabled;
}


chdir dirname($0);
if (not -d 'output') {
   mkdir('output') or die "Cannot mkdir 'output': $!\n"
}
chdir 'output';

1;
