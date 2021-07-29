#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/t/C_character.t 4     21-06-27 17:47 Sommar $
#
# Tests that varchar data is passed and received correctly with
# regards to the code page of the current database.
#
# $History: C_character.t $
# 
# *****************  Version 4  *****************
# User: Sommar       Date: 21-06-27   Time: 17:47
# Updated in $/Perl/OlleDB/t
# Removed tests for retriving sql_variant with varchar data, since
# MSOLEDBSQL 18.4 and later always converts data to the current code
# page.
# 
# *****************  Version 3  *****************
# User: Sommar       Date: 19-07-17   Time: 22:44
# Updated in $/Perl/OlleDB/t
# Suppress messages for CREATE DATABASE on SQL 2000.
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 19-07-16   Time: 22:31
# Updated in $/Perl/OlleDB/t
# Skip plain_result with SQLOLEDB, since we are not able to produce the
# correct result in this case.
# 
# *****************  Version 1  *****************
# User: Sommar       Date: 19-07-16   Time: 21:17
# Created in $/Perl/OlleDB/t
# New test for varchar data.
# 

#---------------------------------------------------------------------

use strict;
use Win32::SqlServer qw(:DEFAULT :consts);
use utf8;
use File::Basename qw(dirname);

require &dirname($0) . '\testsqllogin.pl';

$^W = 1;
$| = 1;

my $setup = testsqllogin(0);
my ($sqlver) = split(/\./, $setup->{SQL_version});
my $provider = $setup->{Provider};

# Test strings for insert. The first two are the same, 
# but the second does not get the UTF8 bit set inside Perl.
my $instr_latin1a = "räksmörgås";
my $instr_latin1b = "r\x{00E4}ksm\x{00F6}rg\x{00E5}s";
my $instr_greek = "αβγ";
my $instr_czech = "Dvořák";

# Test strings for retrieval.
my $outstr_latin1 = "ñandú";
my $outstr_greek  = "Σιγμα";
my $outstr_czech  = "Plzeň";

# These are the expected reults for the in-strings depending on the
# database. We get them sa binary to make sure we have it right.
my @expectforins = 
    (['0x72E46B736DF67267E573', '0x61DF3F', '0x44766F72E16B'],
     ['0x72616B736D6F72676173', '0xE1E2E3', '0x44766F72616B'],
     ['0x72E46B736DF672676173', '0x3FDF3F', '0x44766FF8E16B']);

# When we send in a TVP, nothing should be distorted.
my @expectfortvp = 
    (['0x72E46B736DF67267E573', '0xE1E2E3', '0x44766FF8E16B'],
     ['0x72E46B736DF67267E573', '0xE1E2E3', '0x44766FF8E16B'],
     ['0x72E46B736DF67267E573', '0xE1E2E3', '0x44766FF8E16B']);


# And these are the values we expect for the out strings. These
# we test against the actual strings.
my @expectforout = 
   (['ñandú', 'S??µa', 'Plzen'], 
    ['nandu', 'Σιγμα', 'Plzen'],
    ['nandú', '???µ?', 'Plzeň']);  


# Setup the collatons to work with. We use a UTF8 collation
# where available.
my @collations = qw(Latin1_General_CS_AS Greek_CS_AS Czech_CS_AS);
if ($sqlver >= 15) {
   $collations[2] = 'Czech_100_CS_AS_SC_UTF8';
   $expectforins[2] = ['0x72C3A46B736DC3B67267C3A573', '0xCEB1CEB2CEB3', 
                       '0x44766FC599C3A16B'];
   $expectfortvp[0][2] = '0x44766FC599C3A16B';
   $expectfortvp[1][2] = '0x44766FC599C3A16B';
   $expectfortvp[2][2] = '0x44766FC599C3A16B';
   $expectforout[2] = ['ñandú', 'Σιγμα', 'Plzeň'];  
}

# Suppress CREATE DATABASE messages on SQL 2000.
$setup->{ErrInfo}{PrintText} = 1 if $sqlver == 8;

# Create a database per collation.
foreach my $ix (0..$#collations) {
   $setup->sql("CREATE DATABASE Olle\$DB$ix COLLATE $collations[$ix]");
   $setup->sql("USE Olle\$DB$ix");

   # Tables and base data.
   $setup->sql(<<SQLEND);
   CREATE TABLE tbl1 (id       int         NOT NULL,
                      latin1a  varchar(20) NOT NULL,
                      latin1b  varchar(20) NOT NULL,
                      greek    varchar(20) NOT NULL,
                      czech    varchar(20) NOT NULL)

   INSERT tbl1 
      VALUES(20, N'$outstr_latin1', N'$outstr_latin1', N'$outstr_greek', 
             N'$outstr_czech')

   CREATE TABLE tbl2 (id     int         NOT NULL,
                      latin1 varchar(20) COLLATE $collations[0],
                      greek  varchar(20) COLLATE $collations[1],
                      czech  varchar(20) COLLATE $collations[2])

   INSERT tbl2 
      VALUES(20, N'$outstr_latin1', N'$outstr_greek', N'$outstr_czech')
SQLEND

   # Table type if possible.
   if ($sqlver >= 10 and $provider >= PROVIDER_SQLNCLI10) {
      my $tbltypes = <<SQLEND;
      CREATE TYPE tbltyp AS TABLE 
          (latin1   varchar(20) COLLATE $collations[0] NOT NULL,
           greek    varchar(20) COLLATE $collations[1] NOT NULL,
           czech    varchar(20) COLLATE $collations[2] NOT NULL)

      CREATE TYPE variant_tbltyp AS TABLE 
          (latin1a  sql_variant NOT NULL,
           latin1b  sql_variant NOT NULL,
           greek    sql_variant NOT NULL,
           czech    sql_variant NOT NULL)
      
SQLEND
      $setup->sql($tbltypes);
   }

   # Stored procedures.
   $setup->sql(<<'SQLEND');
   CREATE PROCEDURE plain_insert @latin1a varchar(20),
                                 @latin1b varchar(20),
                                 @greek   varchar(20),
                                 @czech   varchar(20) AS
      DELETE tbl1 WHERE id = 10
      INSERT tbl1 (id, latin1a, latin1b, greek, czech)
         VALUES(10, @latin1a, @latin1b, @greek, @czech)
SQLEND

   $setup->sql(<<'SQLEND');
   CREATE PROCEDURE variant_insert @latin1a sql_variant,
                                   @latin1b sql_variant,
                                   @greek   sql_variant,
                                   @czech   sql_variant AS
      DELETE tbl1 WHERE id = 10
      INSERT tbl1 (id, latin1a, latin1b, greek, czech)
         VALUES(10, convert(varchar(20), @latin1a), 
                    convert(varchar(20), @latin1b), 
                    convert(varchar(20), @greek), 
                    convert(varchar(20), @czech))
SQLEND

   if ($sqlver >= 10 and $provider >= PROVIDER_SQLNCLI10) {
      $setup->sql(<<'SQLEND');
      CREATE PROCEDURE variant_tvp_insert @tvp variant_tbltyp READONLY AS
         DELETE tbl1 WHERE id = 10
         INSERT tbl1 (id, latin1a, latin1b, greek, czech)
            SELECT 10, convert(varchar(20), latin1a), 
                       convert(varchar(20), latin1b), 
                       convert(varchar(20), greek), 
                       convert(varchar(20), czech)
            FROM   @tvp
SQLEND

      # Note that this one operates on tbl2 - with table types we
      # can match all collations.
      $setup->sql(<<'SQLEND');
      CREATE PROCEDURE tvp_insert @tvp tbltyp READONLY AS
         DELETE tbl2 WHERE id = 10
         INSERT tbl2 (id, latin1, greek, czech)
            SELECT 10, latin1, greek, czech
            FROM   @tvp
SQLEND
      
   }

   $setup->sql(<<'SQLEND');
   CREATE PROCEDURE plain_result AS
      SELECT  latin1a, greek, czech FROM tbl1 WHERE id = 20
      SELECT  latin1, greek, czech FROM tbl2 WHERE id = 20
SQLEND

   $setup->sql(<<'SQLEND');
   CREATE PROCEDURE plain_outparam @latin1 varchar(20) OUTPUT,
                                   @greek  varchar(20) OUTPUT,
                                   @czech  varchar(20) OUTPUT AS
      SELECT @latin1 = latin1a,
             @greek  = greek,
             @czech  = czech
      FROM   tbl1
      WHERE  id = 20
SQLEND

}

my @testres;

sub pushtestres {
   my ($result, $expect, $dbix, $table, $column, $action, $srcdb) = @_;

   if ($result eq $expect) {
      push(@testres, 'ok %d');
   }
   else {
      my $msg = "Column: $collations[$dbix].$table.$column; " .
                "action: $action; " .
                (defined $srcdb ? "Source db: $srcdb; " : '') . 
                "Result: $result; Expect: $expect;";
      push(@testres, "not ok %d # $msg");
   }
}

sub compare_in_strings {
   my($olle, $dbix, $action, $srcdb) = @_;

   # Run query to get the result.
   $olle->{BinaryAsStr} = 'x';
   my $result = $olle->sql(<<SQLEND, Win32::SqlServer::HASH, Win32::SqlServer::SINGLEROW);
      SELECT convert(varbinary, latin1a) AS latin1a,
             convert(varbinary, latin1b) AS latin1b,
             convert(varbinary, greek)   AS greek,
             convert(varbinary, czech)   AS czech
      FROM   tbl1
      WHERE  id = 10
SQLEND
 
   pushtestres($$result{'latin1a'}, $expectforins[$dbix][0],
               $dbix, 'tbl1', 'latin1a', $action, $srcdb);
   pushtestres($$result{'latin1b'}, $expectforins[$dbix][0],
               $dbix, 'tbl1', 'latin1a', $action, $srcdb);
   pushtestres($$result{'greek'}, $expectforins[$dbix][1],
               $dbix, 'tbl1', 'greek', $action, $srcdb);
   pushtestres($$result{'czech'}, $expectforins[$dbix][2],
               $dbix, 'tbl1', 'czech', $action, $srcdb);
}

sub compare_for_tvp {
   my($olle, $dbix, $action, $srcdb) = @_;

   # Run query to get the result.
   $olle->{BinaryAsStr} = 'x';
   my $result = $olle->sql(<<SQLEND, Win32::SqlServer::HASH, Win32::SqlServer::SINGLEROW);
      SELECT convert(varbinary, latin1) AS latin1,
             convert(varbinary, greek)  AS greek,
             convert(varbinary, czech)  AS czech
      FROM   tbl2
      WHERE  id = 10
SQLEND
 
   pushtestres($$result{'latin1'}, $expectfortvp[$dbix][0],
               $dbix, 'tbl2', 'latin1', $action, $srcdb);
   pushtestres($$result{'greek'}, $expectfortvp[$dbix][1],
               $dbix, 'tbl2', 'greek', $action, $srcdb);
   pushtestres($$result{'czech'}, $expectfortvp[$dbix][2],
               $dbix, 'tbl2', 'czech', $action, $srcdb);
}


sub compare_out_result {
   my($result, $dbix, $action, $srcdb) = @_;

   pushtestres($$result[0]{'latin1a'}, $expectforout[$dbix][0],
               $dbix, 'tbl1', 'latin1a', $action, $srcdb);
   pushtestres($$result[0]{'greek'}, $expectforout[$dbix][1],
               $dbix, 'tbl1', 'greek', $action, $srcdb);
   pushtestres($$result[0]{'czech'}, $expectforout[$dbix][2],
               $dbix, 'tbl1', 'czech', $action, $srcdb);

   if ($$result[1]) {
      pushtestres($$result[1]{'latin1'}, $outstr_latin1,
                  $dbix, 'tbl2', 'latin1', $action, $srcdb);
      pushtestres($$result[1]{'greek'}, $outstr_greek,
                  $dbix, 'tbl2', 'greek', $action, $srcdb);
      pushtestres($$result[1]{'czech'}, $outstr_czech,
                  $dbix, 'tbl2', 'czech', $action, $srcdb);
   }
}



sub compare_out_params {
   my($platin1, $pgreek, $pczech, $dbix, $action, $srcdb) = @_;

   pushtestres($platin1, $expectforout[$dbix][0],
               $dbix, 'tbl2', 'latin1', $action);
   pushtestres($pgreek, $expectforout[$dbix][1],
               $dbix, 'tbl2', 'greek', $action);
   pushtestres($pczech, $expectforout[$dbix][2],
               $dbix, 'tbl2', 'czech', $action);
}


# This is the procedure to all the tests. It is run twice, once 
# with normal connection and one with auto-connect.
sub run_all_tests {
   my ($autoconnect) = @_;

   # Setup our test connection.
   my $olle = testsqllogin(0, $autoconnect);

   # Loop over the test databases.
   foreach my $dbix (0..$#collations) {
      my $dbname = "Olle\$DB$dbix";
      if ($autoconnect) {
         $olle->setloginproperty('Database', $dbname);
      }
      else {
         $olle->sql("USE $dbname");
      }

      my @params = ($instr_latin1a, $instr_latin1b, 
                    $instr_greek, $instr_czech);
      $olle->sql_sp('plain_insert', \@params, Win32::SqlServer::NORESULT);
      compare_in_strings($olle, $dbix, 'SP plain_insert');

      my %params = ('@latin1a' => ['varchar(20)', $instr_latin1a],
                    '@latin1b' => ['varchar(20)', $instr_latin1b],
                    '@greek'   => ['varchar(20)', $instr_greek],
                    '@czech'   => ['varchar(20)', $instr_czech]);      
       $olle->sql(<<'SQLEND', \%params, Win32::SqlServer::NORESULT);
       DELETE tbl1 WHERE id = 10; 
       INSERT tbl1 (id, latin1a, latin1b, greek, czech)
           VALUES(10, @latin1a, @latin1b, @greek, @czech)
SQLEND
      compare_in_strings($olle, $dbix, 'SQL plain_insert');


      @params = ($instr_latin1a, $instr_latin1b, 
                 $instr_greek, $instr_czech);
      $olle->sql_sp('variant_insert', \@params, Win32::SqlServer::NORESULT);
      compare_in_strings($olle, $dbix, 'SP variant_insert');

      %params = ('@latin1a' => ['sql_variant', $instr_latin1a],
                 '@latin1b' => ['sql_variant', $instr_latin1b],
                 '@greek'   => ['sql_variant', $instr_greek],
                 '@czech'   => ['sql_variant', $instr_czech]);      
       $olle->sql(<<'SQLEND', \%params, Win32::SqlServer::NORESULT);
       DELETE tbl1 WHERE id = 10; 
       INSERT tbl1 (id, latin1a, latin1b, greek, czech)
           VALUES(10, convert(varchar(20), @latin1a), 
                      convert(varchar(20), @latin1b), 
                      convert(varchar(20), @greek), 
                      convert(varchar(20), @czech))
SQLEND
      compare_in_strings($olle, $dbix, 'SQL variant_insert');

      if ($sqlver >= 10 and $provider >= PROVIDER_SQLNCLI10) {
         my $row = {'latin1'  => $instr_latin1b,
                    'greek'   => $instr_greek,
                    'czech'   => $instr_czech};
         $olle->sql_sp('tvp_insert', [[$row]], Win32::SqlServer::NORESULT);
         compare_for_tvp($olle, $dbix, 'SP tvp_insert');

         $olle->sql(<<'SQLEND', {'@tvp' => ['tbltyp', [$row]]}, Win32::SqlServer::NORESULT);
         DELETE tbl2 WHERE id = 10
         INSERT tbl2 (id, latin1, greek, czech)
            SELECT 10, latin1, greek, czech
            FROM   @tvp
SQLEND
         compare_for_tvp($olle, $dbix, 'SQL tvp_insert');

         if ($autoconnect == 0) {
            # Need to skip these tests when autoconnect is on, 
            # this sql_variant in TVP for some reason do not work
            # with autoconnect on .
            $row = {'latin1a' => $instr_latin1a,
                    'latin1b' => $instr_latin1b,
                    'greek'   => $instr_greek,
                    'czech'   => $instr_czech};
            $olle->sql_sp('variant_tvp_insert', [[$row]], Win32::SqlServer::NORESULT);
            compare_in_strings($olle, $dbix, 'SP variant_tvp_insert');

            $olle->sql(<<'SQLEND', {'@tvp' => ['variant_tbltyp', [$row]]}, Win32::SqlServer::NORESULT);
            DELETE tbl1 WHERE id = 10
            INSERT tbl1 (id, latin1a, latin1b, greek, czech)
               SELECT 10, convert(varchar(20), latin1a), 
                          convert(varchar(20), latin1b), 
                          convert(varchar(20), greek), 
                          convert(varchar(20), czech)
               FROM   @tvp
SQLEND
            compare_in_strings($olle, $dbix, 'SQL variant_tvp_insert');
         }
      }

      my $result;
      unless ($olle->{Provider} == PROVIDER_SQLOLEDB) {
         $result = $olle->sql_sp('plain_result');
         compare_out_result($result, $dbix, 'plain_result', undef);
      }

      my ($platin1, $pgreek, $pczech);
      my $outparams = {'@latin1' => \$platin1, 
                       '@greek'  => \$pgreek, 
                       '@czech'  => \$pczech};
      $olle->sql_sp('plain_outparam', $outparams, Win32::SqlServer::NORESULT);
      compare_out_params($platin1, $pgreek, $pczech,
                         $dbix, 'plain_outparam', undef);

   }
}


run_all_tests(0);
run_all_tests(1);


# Print the results of the test.
binmode(STDOUT, ':utf8:');
my $no_of_tests = scalar(@testres);
print "1..$no_of_tests\n";

my $no = 1;
foreach my $line (@testres) {
   if ($line =~ /^(not )?ok/) {
      printf "$line\n", $no++;
   }
   else {
      print "$line\n";
   }
}

# Cleanup. Supress messages from ROLLBACK IMMEDIATE-
$setup->sql("USE tempdb");
$setup->{ErrInfo}{NeverPrint}{5060}++;
foreach my $ix (0..$#collations) {
    $setup->sql(<<SQLEND);
    ALTER DATABASE Olle\$DB$ix SET SINGLE_USER WITH ROLLBACK IMMEDIATE
    DROP DATABASE Olle\$DB$ix
SQLEND
}
