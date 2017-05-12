#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/t/4_conversion.t 13    12-08-19 14:54 Sommar $
#
# Tests that it's possible to set up a conversion based on the local
# OEM character set and the server charset. Mainly is this is test that
# we can access Win32::Registry properly.
#
# $History: 4_conversion.t $
# 
# *****************  Version 13  *****************
# User: Sommar       Date: 12-08-19   Time: 14:54
# Updated in $/Perl/OlleDB/t
# Skip tests with OUTPUT parameters on SQL 6.5.
# 
# *****************  Version 12  *****************
# User: Sommar       Date: 12-08-18   Time: 21:33
# Updated in $/Perl/OlleDB/t
# Use utility routine to get code page.
# 
# *****************  Version 11  *****************
# User: Sommar       Date: 12-08-08   Time: 23:12
# Updated in $/Perl/OlleDB/t
# Added tests for alias types in parameterised SQL.
# 
# *****************  Version 10  *****************
# User: Sommar       Date: 12-07-26   Time: 18:04
# Updated in $/Perl/OlleDB/t
# Added tests for OUTPUT parameters with sql().
# 
# *****************  Version 9  *****************
# User: Sommar       Date: 11-08-07   Time: 23:33
# Updated in $/Perl/OlleDB/t
# Check the code page for the server collation, and skip test if it is
# not CP1252.
# 
# *****************  Version 8  *****************
# User: Sommar       Date: 08-08-17   Time: 23:30
# Updated in $/Perl/OlleDB/t
# Must drop procedure before types can be dropped.
#
# *****************  Version 7  *****************
# User: Sommar       Date: 08-05-04   Time: 21:33
# Updated in $/Perl/OlleDB/t
# Data-type fix for SQL 6.5.
#
# *****************  Version 6  *****************
# User: Sommar       Date: 08-05-01   Time: 10:47
# Updated in $/Perl/OlleDB/t
# Run all tests without a default handle.
#
# *****************  Version 5  *****************
# User: Sommar       Date: 08-03-11   Time: 0:34
# Updated in $/Perl/OlleDB/t
# Added checks for CLR data types and table-valued parameters.
#
# *****************  Version 4  *****************
# User: Sommar       Date: 08-02-24   Time: 21:57
# Updated in $/Perl/OlleDB/t
# Use char(10) etc to avoid new warnings.
#
# *****************  Version 3  *****************
# User: Sommar       Date: 07-06-17   Time: 19:07
# Updated in $/Perl/OlleDB/t
# Some new tests and general adaption to the new implementation of
# $X->sql_set_conversion.
#
# *****************  Version 2  *****************
# User: Sommar       Date: 05-11-26   Time: 23:47
# Updated in $/Perl/OlleDB/t
# Renamed the module from MSSQL::OlleDB to Win32::SqlServer.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 05-02-06   Time: 22:51
# Created in $/Perl/OlleDB/t
#---------------------------------------------------------------------

use strict;
use Win32::SqlServer qw(:DEFAULT :consts);
use File::Basename qw(dirname);

require &dirname($0) . '\testsqllogin.pl';
require '..\helpers\assemblies.pl';


$^W = 1;
$| = 1;

my($shrimp, $shrimp_850, $shrimp_twoway, $shrimp_bogus, @data, $data, %data);

sub set_shrimp_850 {
   $shrimp_850    = 'r„ksm”rg†s';  # It's in CP850.
   $shrimp_twoway = 'räksmörgås';  # Latin-1 -> CP850 and back.
   $shrimp_bogus  = 'rõksm÷rgÕs';  # Converted to Latin-1 as if it was CP850 but it wasn't.
}

sub set_shrimp_437 {
   $shrimp_850    = 'r„ksm”rg†s';  # It's in CP437.
   $shrimp_twoway = 'rSksmörgss';  # Latin-1 -> Cp437 and back. Not round-trip.
   $shrimp_bogus  = 'rSksm÷rgss';  # Converted to Latin-1 as if it was CP437 but it wasn't.
}

# Get the OEM char-set.
my $client_cs = get_codepage_from_reg('OEMCP');
my $unknown_oem;

# These are the constants we use to test. It's all about shrimp sandwiches.
$shrimp       = 'räksmörgås';  # The way it should be in Latin-1.
if ($client_cs == 850) {
   set_shrimp_850;
}
elsif ($client_cs == 437) {
   set_shrimp_437;
}
else {
   # Some other OEM charset, with different distortions unknown to us. So
   # we will skip the test for the default OEM page.
   $unknown_oem = $client_cs;
}


my $X = testsqllogin(0);
my ($sqlver) = split(/\./, $X->{SQL_version});
my $provider = $X->{Provider};
my $clr_enabled;
if ($sqlver >= 9) {
   $clr_enabled = $X->sql_one(<<SQLEND, Win32::SqlServer::SCALAR);
   SELECT value
   FROM   sys.configurations
   WHERE  name = 'clr enabled'
SQLEND
}

# Investigate the code page for the server collation. The test only runs 
# if this is 1252, since we don't what distortions that happens with other
# charsets.
if (not is_latin1($X)) {
   print "1..0 # Skipped: Code page for server collation is not 1252.\n";
   exit;
}
   
print "1..37\n";


# First create a table to two procedures to read and write to a table.
$X->sql(<<SQLEND);
   CREATE TABLE #nisse (i       int      NOT NULL PRIMARY KEY,
                        shrimp  char(10) NOT NULL)
SQLEND

$X->sql(<<'SQLEND');
   CREATE PROCEDURE #nisse_ins_sp @i      int,
                                  @shrimp char(10) AS
      INSERT #nisse (i, shrimp) VALUES (@i, @shrimp)
SQLEND

$X->sql(<<'SQLEND');
   CREATE PROCEDURE #nisse_get_sp @i int,
                                  @shrimp char(10) OUTPUT AS

      SELECT @shrimp = shrimp FROM #nisse WHERE @i = i
SQLEND


# Now add first set of data with no conversion in effect.
$X->sql("INSERT #nisse (i, shrimp) VALUES (0, 'räksmörgås')");
$X->sql("INSERT #nisse (i, shrimp) VALUES (?, ?)", 
                [['int', 1], ['char(10)', 'räksmörgås']]);
$X->sql_insert("#nisse", {i => 2, 'shrimp' => 'räksmörgås'});
$X->sql_sp("#nisse_ins_sp", [3, 'räksmörgås']);

# Now set up default, bilateral conversion.
$X->sql_set_conversion();
print "ok 1\n";   # We wouldn't come back if it's not ok...

# Add a second set of data, now conversion is in effect.
$X->sql("INSERT #nisse (i, shrimp) VALUES (10, 'räksmörgås')");
$X->sql("INSERT #nisse (i, shrimp) VALUES (?, ?)", 
                 [['int', 11], ['char(10)', 'räksmörgås']]);
$X->sql_insert("#nisse", {i => 12, 'shrimp' => 'räksmörgås'});
$X->sql_sp("#nisse_ins_sp", [13, 'räksmörgås']);

# Now retrieve data and see what we get. The first should give the shrimp in CP850.
@data = $X->sql("SELECT shrimp FROM #nisse WHERE i BETWEEN 0 AND 3 ORDER BY i", 
                SCALAR);
unless ($unknown_oem) {
   if (compare(\@data, [$shrimp_850, $shrimp_850, $shrimp_850, $shrimp_850])) {
      print "ok 2\n";
   }
   else {
      print "not ok 2\n# " . join(' ', @data) . "\n";
   }
}
else {
   print "ok 2 # skip, no test data for OEM charset $unknown_oem\n";
}

# Same test, with output parameters.
if ($sqlver >= 7) {
   @data = (undef) x 4;
   my $params =  [['char(10)', \$data[0]], 
                  ['char(10)', \$data[1]], 
                  ['char(10)', \$data[2]], 
                  ['char(10)', \$data[3]]]; 
   $X->sql(<<SQLEND, $params);
 SELECT ? = shrimp FROM #nisse WHERE i = 0
 SELECT ? = shrimp FROM #nisse WHERE i = 1
 SELECT ? = shrimp FROM #nisse WHERE i = 2
 SELECT ? = shrimp FROM #nisse WHERE i = 3
SQLEND
   unless ($unknown_oem) {
      if (compare(\@data, [$shrimp_850, $shrimp_850, $shrimp_850, $shrimp_850])) {
         print "ok 3\n";
      }
      else {
         print "not ok 3\n# " . join(' ', @data) . "\n";
      }
   }
   else {
      print "ok 3 # skip, no test data for OEM charset $unknown_oem\n";
   }
}
else {
   print "ok 3 # skip, no OUTPUT parameters on SQL 6.5\n";
}


# This should give the real McCoy - it's been converted in both directions.
@data = $X->sql("SELECT shrimp FROM #nisse WHERE i BETWEEN 10 AND 13 ORDER BY i", 
                SCALAR);
unless ($unknown_oem) {
   if (compare(\@data,
               [$shrimp_twoway, $shrimp_twoway, $shrimp_twoway, $shrimp_twoway])) {
      print "ok 4\n";
   }
   else {
      print "not ok 4\n# " . join(' ', @data) . "\n";
   }
}
else {
   print "ok 4 # skip, no test data for OEM charset $unknown_oem\n";
}

# Same test, again with output params.
if ($sqlver >= 7) {
   @data = (undef) x 4;
   my $params =  [['char(10)', \$data[0]], 
                  ['char(10)', \$data[1]], 
                  ['char(10)', \$data[2]], 
                  ['char(10)', \$data[3]]]; 
   $X->sql(<<SQLEND, $params);
    SELECT ? = shrimp FROM #nisse WHERE i = 10
    SELECT ? = shrimp FROM #nisse WHERE i = 11
    SELECT ? = shrimp FROM #nisse WHERE i = 12
    SELECT ? = shrimp FROM #nisse WHERE i = 13
SQLEND
   unless ($unknown_oem) {
      if (compare(\@data,
                  [$shrimp_twoway, $shrimp_twoway, $shrimp_twoway, $shrimp_twoway])) {
         print "ok 5\n";
      }
      else {
         print "not ok 5\n# " . join(' ', @data) . "\n";
      }
   }
   else {
      print "ok 5 # skip, no test data for OEM charset $unknown_oem\n";
   }
}
else {
   print "ok 5 # skip, no OUTPUT parameters on SQL 6.5\n";
}


# Again, a CP850 shrimp is expected.
$X->sql_sp("#nisse_get_sp", [1, \$data]);
unless ($unknown_oem) {
   if ($data eq $shrimp_850) {
      print "ok 6\n";
   }
   else {
      print "not ok 6\n# $data\n";
   }
}
else {
   print "ok 6 # skip, no test data for OEM charset $unknown_oem\n";
}

# Again, in Latin-1.
$X->sql_sp("#nisse_get_sp", [11, \$data]);
unless ($unknown_oem) {
   if ($data eq $shrimp_twoway) {
      print "ok 7\n";
   }
   else {
      print "not ok 7\n# $data\n";
   }
}
else {
   print "ok 7 # skip, no test data for OEM charset $unknown_oem\n";
}


# Turn off conversion. This just can't fail. :-)
$X->sql_unset_conversion;

# Now we should get Latin-1.
@data = $X->sql("SELECT shrimp FROM #nisse WHERE i BETWEEN 0 AND 3", SCALAR);
if (compare(\@data, [$shrimp, $shrimp, $shrimp, $shrimp])) {
   print "ok 8\n";
}
else {
   print "not ok 8\n# " . join(' ', @data) . "\n";
}

# This is the bogus conversion, we converted Latin-1 to Latin-1.
@data = $X->sql("SELECT shrimp FROM #nisse WHERE i BETWEEN 10 AND 13", SCALAR);
unless ($unknown_oem) {
   if (compare(\@data,
                [$shrimp_bogus, $shrimp_bogus, $shrimp_bogus, $shrimp_bogus])) {
      print "ok 9\n";
   }
   else {
      print "not ok 9\n# " . join(' ', @data) . "\n";
   }
}
else {
   print "ok 9 # skip, no test data for OEM charset $unknown_oem\n";
}

# Again, a Latin-1 shrimp is expected.
$X->sql_sp("#nisse_get_sp", [1, \$data]);
if ($data eq $shrimp) {
   print "ok 10\n";
}
else {
   print "not ok 10\n# $data\n";
}

# Again, it's bogus.
$X->sql_sp("#nisse_get_sp", [11, \$data]);
unless ($unknown_oem) {
   if ($data eq $shrimp_bogus) {
      print "ok 11\n";
   }
   else {
      print "not ok 11\n# $data\n";
   }
}
else {
   print "ok 11 # skip, no test data for OEM charset $unknown_oem\n";
}

# From this point, we always use CP850 as the OEM charset.
$client_cs = 850;
set_shrimp_850;

# Now we will make a test that we convert hash keys correctly. We will also
# test asymmetric conversion and that $X->sql_one converts properly.
$X->sql_set_conversion("CP$client_cs", "iso_1", TO_CLIENT_ONLY);
{
   my %ref;
   $ref{$shrimp_850} = $shrimp_850;

   %data = $X->sql(q!SELECT "räksmörgås" = 'räksmörgås'!, HASH, SINGLEROW);
   if (compare(\%ref, \%data)) {
      print "ok 12\n";
   }
   else {
      print "not ok 12\n";
   }

   %data = $X->sql_one(q!SELECT "räksmörgås" = 'räksmörgås'!);
   if (compare(\%ref, \%data)) {
      print "ok 13\n";
   }
   else {
      print "not ok 13\n";
   }
}

# After this we have conversion both directions
$X->sql_set_conversion($client_cs, 1252, TO_SERVER_ONLY);
{
   my %ref;
   $ref{$shrimp_twoway} = $shrimp_twoway;

   %data = $X->sql("SELECT 'räksmörgås' = 'räksmörgås'", HASH, SINGLEROW);
   if (compare(\%ref, \%data)) {
      print "ok 14\n";
   }
   else {
      print "not ok 14\n";
   }

   %data = $X->sql_one("SELECT 'räksmörgås' = 'räksmörgås'");
   if (compare(\%ref, \%data)) {
      print "ok 15\n";
   }
   else {
      print "not ok 15\n";
   }
}

# After now only to server.
$X->sql_unset_conversion(TO_CLIENT_ONLY);
{
   my %ref;
   $ref{$shrimp_bogus} = $shrimp_bogus;

   %data = $X->sql(q!SELECT "räksmörgås" = 'räksmörgås'!, HASH, SINGLEROW);
   if (compare(\%ref, \%data)) {
      print "ok 16\n";
   }
   else {
      print "not ok 16\n";
      print '<' . (keys(%ref))[0] . '> <' . (keys(%data))[0] . ">\n";
   }

   %data = $X->sql_one(q!SELECT "räksmörgås" = 'räksmörgås'!);
   if (compare(\%ref, \%data)) {
      print "ok 17\n";
   }
   else {
      print "not ok 17\n";
   }
}

# And now in no direction at all.
$X->sql_unset_conversion(TO_SERVER_ONLY);
{
   my %ref;
   $ref{$shrimp} = $shrimp;

   %data = $X->sql(q!SELECT "räksmörgås" = 'räksmörgås'!, HASH, SINGLEROW);
   if (compare(\%ref, \%data)) {
      print "ok 18\n";
   }
   else {
      print "not ok 18\n";
   }

   %data = $X->sql_one(q!SELECT "räksmörgås" = 'räksmörgås'!);
   if (compare(\%ref, \%data)) {
      print "ok 19\n";
   }
   else {
      print "not ok 19\n";
   }
}

# Now we will test with object name that are subject to conversion. First
# some tables. This test requires CP850, as CP437 is not roundtrip.
$X->sql_unset_conversion;
$X->sql(<<SQLEND);
   CREATE TABLE #$shrimp (i       int         NOT NULL PRIMARY KEY,
                         $shrimp  varchar(10) NOT NULL)
SQLEND

$X->sql(<<SQLEND);
   CREATE PROCEDURE #${shrimp}_ins_sp \@i       int,
                                      \@$shrimp varchar(10) AS
      INSERT #$shrimp (i, $shrimp) VALUES (\@i, \@$shrimp)
SQLEND

$X->sql(<<SQLEND);
   CREATE PROCEDURE #${shrimp}_get_sp \@i int,
                                      \@$shrimp varchar(10) OUTPUT AS

      SELECT \@$shrimp = $shrimp FROM #$shrimp WHERE \@i = i
SQLEND

# Alias types.
if ($sqlver >= 9) {
   $X->sql(<<SQLEND);
   IF type_id(N'${shrimp}_string') IS NOT NULL DROP TYPE ${shrimp}_string
   CREATE TYPE ${shrimp}_string FROM varchar(10)
SQLEND
}
else {
   $X->{ErrInfo}{PrintText} = 11;
   $X->sql(<<'SQLEND', [['sysname', "${shrimp}_string"]]);
   DECLARE @name sysname
   SELECT @name = ?
   IF EXISTS (SELECT * FROM systypes WHERE name = @name)
      EXEC sp_droptype @name
   EXEC sp_addtype @name, 'varchar(10)'
SQLEND
   $X->{ErrInfo}{PrintText} = 0;
}

# UDTS on SQL 2005 and later.
if ($sqlver >= 9 and $provider >= PROVIDER_SQLNCLI and $clr_enabled) {
   create_the_udts($X, undef, "${shrimp}_point");
   $X->sql(<<SQLEND);
   CREATE PROCEDURE #UDT \@udt ${shrimp}_point AS SELECT \@udt.ToString()
SQLEND
}

# Table types for SQL 2008 and later.
if ($sqlver >= 10 and $provider >= PROVIDER_SQLNCLI10) {
   $X->sql(<<SQLEND);
   IF type_id(N'${shrimp}_type') IS NOT NULL DROP TYPE ${shrimp}_type
   IF type_id(N'${shrimp}_UDT') IS NOT NULL DROP TYPE ${shrimp}_UDT
SQLEND

   $X->sql(<<SQLEND);
   CREATE TYPE ${shrimp}_type AS TABLE (a       int         NOT NULL,
                                        $shrimp varchar(10) NOT NULL);
SQLEND

   $X->sql(<<SQLEND);
   CREATE PROCEDURE #test_shrimp_type \@t ${shrimp}_type READONLY AS
       INSERT #$shrimp(i, $shrimp) SELECT a, $shrimp FROM \@t
SQLEND

   if ($clr_enabled) {
      $X->sql("CREATE TYPE ${shrimp}_UDT AS TABLE (p ${shrimp}_point NOT NULL)");
      $X->sql(<<SQLEND);
   CREATE PROCEDURE #test_UDT_type \@t ${shrimp}_UDT READONLY AS
       SELECT p.ToString() FROM \@t
SQLEND
   }
}

# Insert some data
$X->sql("INSERT #$shrimp (i, $shrimp) VALUES (1, 'first row')");
if ($X->{SQL_version} =~ /^6\./) {
   $X->sql("INSERT #$shrimp (i, $shrimp) VALUES (?, ?)",
       [['int', 2], ['char(9)', 'secondrow']]);
}
else {
   $X->sql("INSERT #$shrimp (i, $shrimp) VALUES (\@i, \@$shrimp)",
       {i => ['int', 2], $shrimp => ['char(9)', 'secondrow']});
}
$X->sql_insert("#$shrimp", {i => 3, $shrimp => 'third row'});
$X->sql_sp("#${shrimp}_ins_sp", [4, 'fourthrow']);

# Turn on conversion.
$X->sql_set_conversion(850);

# We assume that things just crashes if test fails.
$X->sql("INSERT #$shrimp_850 (i, $shrimp_850) VALUES (5, 'fifth row')");
print "ok 20\n";
if ($X->{SQL_version} =~ /^6\./) {
   $X->sql("INSERT #$shrimp_850 (i, $shrimp_850) VALUES (?, ?)",
       [['int', 6], ["${shrimp_850}_string", 'sixth row']]);
}
else {
   $X->sql("INSERT #$shrimp_850 (i, $shrimp_850) VALUES (\@i, \@$shrimp_850)",
       {i => ['int', 6], $shrimp_850 => ["${shrimp_850}_string", 'sixth row']});
}
print "ok 21\n";
$X->sql_insert("#$shrimp_850", {i => 7, $shrimp_850 => 'row seven'});
print "ok 22\n";
$X->sql_sp("#${shrimp_850}_ins_sp", [8, 'eighthrow']);
print "ok 23\n";

# Check that data was inserted as expected.
@data = $X->sql("SELECT $shrimp_850 FROM #$shrimp_850 ORDER BY i", SCALAR);
if (compare(\@data, ['first row', 'secondrow', 'third row', 'fourthrow',
                     'fifth row', 'sixth row', 'row seven', 'eighthrow'])) {
   print "ok 24\n";
}
else {
   print "not ok 24\n# " . join(' ', @data) . "\n";
}

# Test handling of UDT names.
if ($sqlver >= 9 and $provider >= PROVIDER_SQLNCLI and $clr_enabled) {
   my $ret = $X->sql_sp('#UDT', ['0x0180000001800000098000000C'], SINGLEROW, SCALAR);
   if (compare($ret, '1:9:12')) {
      print "ok 25\n";
   }
   else {
      print "not 25\n# Got back $ret\n"
   }

   $ret = $X->sql('SELECT ?.ToString()',
              [['UDT', '0x0180000001800000098000000C', "${shrimp_850}_point"]],
              SINGLEROW, SCALAR);
   if (compare($ret, '1:9:12')) {
      print "ok 26\n";
   }
   else {
      print "not 26\n# Got back $ret\n"
   }

}
else {
   print "ok 25 # skip, no CLR\n";
   print "ok 26 # skip, no CLR\n";
}

# Test table-valued parameters.
# Empty the temp table.
$X->sql("TRUNCATE TABLE #$shrimp_850");
print "ok 27\n";
if ($sqlver >= 10 and $provider >= PROVIDER_SQLNCLI10) {
   $X->sql_sp('#test_shrimp_type', [[[1, $shrimp_850],
                                 [2, reverse($shrimp_850)]]]);
   print "ok 28\n";
   my $hashrows;
   $$hashrows[0]{a} = 3;
   $$hashrows[0]{$shrimp_850} = 'Third row';
   $$hashrows[1]{a} = 4;
   $$hashrows[1]{$shrimp_850} = 'Fourth row';
   $$hashrows[2]{a} = 5;
   $$hashrows[2]{$shrimp_850} = $shrimp_850;
   $X->sql_sp('#test_shrimp_type', [$hashrows]);
   print "ok 29\n";
   $X->sql("INSERT #$shrimp_850(i, $shrimp_850) SELECT a, $shrimp_850 FROM ?",
       [["table(${shrimp_850}_type)", [[6, $shrimp_850],
                                   [7, reverse($shrimp_850)]]
        ]]);
   print "ok 30\n";
   $$hashrows[0]{a} = 13;
   $$hashrows[1]{a} = 14;
   $$hashrows[2]{a} = 15;
   $X->sql("INSERT #$shrimp_850(i, $shrimp_850) SELECT a, $shrimp_850 FROM ?",
       [["table", $hashrows, "${shrimp_850}_type"]]);
   print "ok 31\n";

   # Let's have a look at what we have.
   $X->sql_unset_conversion;
   @data = $X->sql("SELECT i, $shrimp FROM #$shrimp ORDER BY i", LIST);
   my @expect = ([1, $shrimp], [2, reverse($shrimp)], [3, 'Third row'],
                 [4, 'Fourth row'], [5, $shrimp], [6, $shrimp],
                 [7, reverse($shrimp)], [13, 'Third row'], [14, 'Fourth row'],
                 [15, $shrimp]);
   if (compare(\@data, \@expect)) {
      print "ok 32\n";
   }
   else {
      print "not ok 32\n";
   }

   # And test with CLR column in the table type.
   $X->sql_set_conversion;
   if ($clr_enabled) {
      my $ret = $X->sql('SELECT p.ToString() FROM ?',
                 [["table(${shrimp_850}_UDT)", [['0x0180000001800000098000000C']]]],
                 SCALAR, SINGLEROW);
      if (compare($ret, '1:9:12')) {
         print "ok 33\n";
      }
      else {
         print "not 33\n# Got back $ret\n"
      }

      $ret = $X->sql_sp('#test_UDT_type', [[['0x0180000001800000098000000C']]],
                    SCALAR, SINGLEROW);
      if (compare($ret, '1:9:12')) {
         print "ok 34\n";
      }
      else {
         print "not 34\n# Got back $ret\n"
      }
   }
   else {
      print "ok 33 # skip, no CLR\n";
      print "ok 34 # skip, no CLR\n";
   }
}
else {
   print "ok 28 # skip, no TVPs\n";
   print "ok 29 # skip, no TVPs\n";
   print "ok 30 # skip, no TVPs\n";
   print "ok 31 # skip, no TVPs\n";
   print "ok 32 # skip, no TVPs\n";
   print "ok 33 # skip, no TVPs\n";
   print "ok 34 # skip, no TVPs\n";
}


# Test some more odd code-page variations.
$X->sql_unset_conversion;
$X->sql_set_conversion(1251, 1252, TO_CLIENT_ONLY);
# Latin-1 to Cyrillic. The shrimp gets straighened out.
@data = $X->sql("SELECT 'räksmörgås'", SCALAR);
if (compare(\@data, ['raksmorgas'])) {
   print "ok 35\n";
}
else {
   print "not ok 35\n# " . join(' ', @data) . "\n";
}

$X->sql_unset_conversion;
$X->sql_set_conversion(1251, 1252, TO_SERVER_ONLY);
# Cyrillic to Latin. The shrimp becomes a question.
@data = $X->sql("SELECT 'räksmörgås'", SCALAR);
if (compare(\@data, ['r?ksm?rg?s'])) {
   print "ok 36\n";
}
else {
   print "not ok 36\n# " . join(' ', @data) . "\n";
}

# Final test: check that a datetime hash is not thrashed when subject to
# conversion
$X->sql_set_conversion;
$X->{DatetimeOption} = DATETIME_HASH;
$data = $X->sql_one('SELECT dateadd(YEAR, 100, dateadd(minute, 20, ?))',
                [['datetime', '18140212 17:19:34']], SCALAR);
if (compare($data, {Year => 1914, Month => 2, Day => 12,
                    Hour => 17, Minute => 39, Second => 34, Fraction => 0})) {
   print "ok 37\n";
}
else {
   print "not ok 37\n";
}

# Cleanup
$X->sql_unset_conversion;
if ($sqlver >= 10) {
   $X->sql(<<SQLEND);
   IF object_id(N'#test_shrimp_type') IS NOT NULL
       DROP PROCEDURE #test_shrimp_type
   IF object_id(N'#test_UDT_type') IS NOT NULL
       DROP PROCEDURE #test_UDT_type
   IF type_id(N'${shrimp}_type') IS NOT NULL DROP TYPE ${shrimp}_type
   IF type_id(N'${shrimp}_UDT') IS NOT NULL DROP TYPE ${shrimp}_UDT
SQLEND
}
delete_the_udts($X) if $sqlver >= 9;

if ($sqlver >= 9) {
   $X->sql(<<SQLEND);
   IF type_id(N'${shrimp}_string') IS NOT NULL DROP TYPE ${shrimp}_string
SQLEND
}
else {
   $X->{ErrInfo}{PrintText} = 11;
   $X->sql(<<'SQLEND', [['sysname', "${shrimp}_string"]]);
   DECLARE @name sysname
   SELECT @name = ?
   IF EXISTS (SELECT * FROM systypes WHERE name = @name)
      EXEC sp_droptype @name
SQLEND
   $X->{ErrInfo}{PrintText} = 0;
}


exit;

sub compare {
   my ($x, $y) = @_;

   my ($refx, $refy, $ix, $key, $result);

   $refx = ref $x;
   $refy = ref $y;

   if (not $refx and not $refy) {
      if (defined $x and defined $y) {
         warn "<$x> ne <$y>" if $x ne $y;
         return ($x eq $y);
      }
      else {
         return (not defined $x and not defined $y);
      }
   }
   elsif ($refx ne $refy) {
      return 0;
   }
   elsif ($refx eq "ARRAY") {
      if ($#$x != $#$y) {
         return 0;
      }
      elsif ($#$x >= 0) {
         foreach $ix (0..$#$x) {
            $result = compare($$x[$ix], $$y[$ix]);
            last if not $result;
         }
         return $result;
      }
      else {
         return 1;
      }
   }
   elsif ($refx eq "HASH") {
      my $nokeys_x = scalar(keys %$x);
      my $nokeys_y = scalar(keys %$y);
      if ($nokeys_x != $nokeys_y) {
         return 0;
      }
      elsif ($nokeys_x > 0) {
         foreach $key (keys %$x) {
            if (not exists $$y{$key}) {
                return 0;
            }
            $result = compare($$x{$key}, $$y{$key});
            last if not $result;
         }
         return $result;
      }
      else {
         return 1;
      }
   }
   elsif ($refx eq "SCALAR") {
      return compare($$x, $$y);
   }
   else {
      return ($x eq $y);
   }
}

#--------------------------------- Copied from Sqllib.pm
sub get_codepage_from_reg {
    my($cp_value) = shift @_;
    # Reads the code page for OEM or ANSI. This is one specific key in
    # in the registry.

    my($REGKEY) = 'SYSTEM\CurrentControlSet\Control\Nls\CodePage';
    my($regref, $dummy, $result);

    # We need this module to read the registry, but as this is the only
    # place we need it in, we don't C<use> it.
    require 'Win32\Registry.pm';

    $dummy = $main::HKEY_LOCAL_MACHINE;  # Resolve "possible typo" with AS Perl.
    $main::HKEY_LOCAL_MACHINE->Open($REGKEY, $regref) or
         die "Could not open registry key: '$REGKEY'\n";

    # This is where stuff is getting really ugly, as I have found no code
    # that works both with the ActiveState Perl and the native port.
    if ($] < 5.004) {
       Win32::RegQueryValueEx($regref->{'handle'}, $cp_value, 0,
                              $dummy, $result) or
             die "Could not read '$REGKEY\\$cp_value' from registry\n";
    }
    else {
       $regref->QueryValueEx($cp_value, $dummy, $result);
    }
    $regref->Close or warn "Could not close registry key.\n";

    $result;
}
