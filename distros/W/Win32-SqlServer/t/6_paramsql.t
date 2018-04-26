#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/t/6_paramsql.t 22    18-04-13 17:23 Sommar $
#
# This test suite concerns sql with parameterised SQL statements.
#
# $History: 6_paramsql.t $
# 
# *****************  Version 22  *****************
# User: Sommar       Date: 18-04-13   Time: 17:23
# Updated in $/Perl/OlleDB/t
# When checking whether the CLR is enabled, also take CLR strict security
# in consideration, and do not run CLR tests when strict security is in
# force.
# 
# *****************  Version 21  *****************
# User: Sommar       Date: 15-05-24   Time: 22:27
# Updated in $/Perl/OlleDB/t
# Ripped out code specific for SQL 6.5.
# 
# *****************  Version 20  *****************
# User: Sommar       Date: 12-08-08   Time: 23:13
# Updated in $/Perl/OlleDB/t
# Tests for new feature: You can now use user-defined types with
# parameters in the sql() method.
# 
# *****************  Version 19  *****************
# User: Sommar       Date: 12-07-26   Time: 18:06
# Updated in $/Perl/OlleDB/t
# Added tests for OUTPUT parameters and rearranged the entire script.
# 
# *****************  Version 18  *****************
# User: Sommar       Date: 08-08-17   Time: 23:31
# Updated in $/Perl/OlleDB/t
# Coordinates have been swapped in geometry.
#
# *****************  Version 17  *****************
# User: Sommar       Date: 08-05-04   Time: 22:41
# Updated in $/Perl/OlleDB/t
# We get different dates back depending the provider.
#
# *****************  Version 16  *****************
# User: Sommar       Date: 08-05-04   Time: 22:08
# Updated in $/Perl/OlleDB/t
# Don't test the spatial data types with SQLNCLI (because it doesn't
# work.)
#
# *****************  Version 15  *****************
# User: Sommar       Date: 08-05-04   Time: 21:19
# Updated in $/Perl/OlleDB/t
# We can't test rowversion on SQL 7 and earlier!
#
# *****************  Version 14  *****************
# User: Sommar       Date: 08-02-17   Time: 0:35
# Updated in $/Perl/OlleDB/t
# Restored funny names, now that SQL Native Client handles them properly
# again.
#
# *****************  Version 13  *****************
# User: Sommar       Date: 08-02-10   Time: 17:16
# Updated in $/Perl/OlleDB/t
# Added test for rowversion and timestamp.
#
# *****************  Version 12  *****************
# User: Sommar       Date: 07-12-01   Time: 23:48
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 11  *****************
# User: Sommar       Date: 07-11-20   Time: 22:08
# Updated in $/Perl/OlleDB/t
# Added tests for spatial.
#
# *****************  Version 10  *****************
# User: Sommar       Date: 07-11-11   Time: 18:57
# Updated in $/Perl/OlleDB/t
# Added tests for the new date/time data types.
#
# *****************  Version 9  *****************
# User: Sommar       Date: 07-09-16   Time: 22:42
# Updated in $/Perl/OlleDB/t
# Added tests for large UDTs and hierarchyid. Temporary disabled funny
# names for SQL Native Client 10, since it can't cope with them.
#
# *****************  Version 8  *****************
# User: Sommar       Date: 07-06-10   Time: 21:50
# Updated in $/Perl/OlleDB/t
# Corrected for a new error message on Katmai in one case.
#
# *****************  Version 7  *****************
# User: Sommar       Date: 05-11-26   Time: 23:47
# Updated in $/Perl/OlleDB/t
# Renamed the module from MSSQL::OlleDB to Win32::SqlServer.
#
# *****************  Version 6  *****************
# User: Sommar       Date: 05-10-29   Time: 23:18
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 5  *****************
# User: Sommar       Date: 05-08-07   Time: 22:41
# Updated in $/Perl/OlleDB/t
# Test case-insensitivty.
#
# *****************  Version 4  *****************
# User: Sommar       Date: 05-07-25   Time: 0:41
# Updated in $/Perl/OlleDB/t
# Added tests for XML and UDT.
#
# *****************  Version 3  *****************
# User: Sommar       Date: 05-06-26   Time: 22:36
# Updated in $/Perl/OlleDB/t
# Now checks 6.5. Added test for (too) long binary and string values.
#
# *****************  Version 2  *****************
# User: Sommar       Date: 05-03-20   Time: 21:48
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 1  *****************
# User: Sommar       Date: 05-03-20   Time: 21:23
# Created in $/Perl/OlleDB/t
#---------------------------------------------------------------------

use strict;
use Win32::SqlServer qw(:DEFAULT :consts);
use File::Basename qw(dirname);

require &dirname($0) . '\testsqllogin.pl';
require '..\helpers\assemblies.pl';

use vars qw(@testres $verbose $no_of_tests $clr_enabled);

sub blurb{
    push (@testres, "#------ Testing @_ ------\n");
    print "#------ Testing @_ ------\n" if $verbose;
}

sub datehash_compare {
  # Help routine to compare datehashes.
    my($val, $expect) = @_;

    foreach my $part (keys %$expect) {
       return 0 if not defined $$val{$part} or $$expect{$part} != $$val{$part};
    }
    return 1;
}

$verbose = shift @ARGV;


$^W = 1;

$| = 1;

my $X = testsqllogin();
#open (F, '>paramsql.sql');
#$X->{LogHandle} = \*F;

my ($sqlver) = split(/\./, $X->{SQL_version});

# Create alias types. First set up a stored procedure for the task.
if ($sqlver >= 9) {
   my $create_type_sub = <<'SQLEND';
   CREATE PROCEDURE #create_type @name   sysname,
                                 @def    varchar(255) = NULL,
                                 @schema sysname = 'dbo' AS
   DECLARE @sql nvarchar(MAX)
   IF EXISTS (SELECT * 
              FROM   sys.types t
              JOIN   sys.schemas s ON t.schema_id = s.schema_id
              WHERE  s.name = @schema
                AND  t.name = @name)
   BEGIN
      SELECT @sql = 'DROP TYPE ' + quotename(@schema) + '.' + 
                                   quotename(@name)
      EXEC(@sql)
   END
   IF @def IS NOT NULL
   BEGIN                                    
      SELECT @sql = 'CREATE TYPE ' + quotename(@schema) + '.' + 
                                     quotename(@name) + 
                    'FROM ' + @def
      EXEC(@sql)
      SELECT @sql = 'GRANT VIEW DEFINITION ON TYPE::' +
                     + quotename(@schema) + '.' + quotename(@name) +  
                     ' TO public'
      EXEC(@sql)
   END 
SQLEND
   $X->sql($create_type_sub);
}
else {
   my $create_type_sub = <<'SQLEND';
   CREATE PROCEDURE #create_type @name   sysname,
                                 @def    varchar(255) = NULL AS
   IF EXISTS (SELECT * 
              FROM   systypes t
              WHERE  t.name = @name)
   BEGIN
      EXEC sp_droptype @name
   END
   IF @def IS NOT NULL
   BEGIN                                    
      EXEC sp_addtype @name, @def
   END 
SQLEND
   $X->sql($create_type_sub);
}

$X->{errInfo}{printText}  = 11 if $sqlver < 9;
sql_sp('#create_type', ['int_type', 'int']);
sql_sp('#create_type', ['char_type', 'char(10)']);
sql_sp('#create_type', ['unicode_type', 'nvarchar(12)']);
sql_sp('#create_type', ['maxtype', 'varbinary(MAX)']) 
    if $sqlver >= 9;
sql_sp('#create_type', ['decimal_type', 'decimal(7, 0)', 'guest']) 
    if $sqlver >= 9;
sql_sp('#create_type', ['decimal_type', 'numeric(7, 2)']);
sql_sp('#create_type', ['dateoff_type', 'datetimeoffset(0)']) 
    if $sqlver >= 10;
sql_sp('#create_type', ['datetime2_type', ' datetime2(4)'])
    if $sqlver >= 10;
$X->{errInfo}{printText}  = 0;

if ($sqlver >= 9 and $X->{Provider} >= PROVIDER_SQLNCLI) {
   $clr_enabled = clr_enabled($X);

   create_the_udts($X, 'OlleComplexInteger', 'OllePoint', 'Olle-String',
                   'OlleString MAX') if $clr_enabled;
}

if ($sqlver >= 9 and $X->{Provider} >= PROVIDER_SQLNCLI) {
   # Create schema for the XML with schema collection stuff
   sql(<<SQLEND);
IF EXISTS (SELECT * FROM sys.xml_schema_collections WHERE name = 'OlleSC')
   DROP XML SCHEMA COLLECTION OlleSC
CREATE XML SCHEMA COLLECTION OlleSC AS '
<schema xmlns="http://www.w3.org/2001/XMLSchema">
      <element name="Olle" type="string"/>
</schema>
'
SQLEND
}



# Accept all errors, print errors, but suppress warnings (because
# we generate quite a few on purpose).
$X->{errInfo}{maxSeverity}  = 25;
$X->{errInfo}{printLines}   = 11;
$X->{errInfo}{printMsg}     = 11;
$X->{errInfo}{printText}    = 11;
$X->{errInfo}{carpLevel}    = 25;
$X->{ErrInfo}{SaveMessages} = 1;

# ---------------------------  General tests -------------------------
blurb("many parameters");
if (1) {
   my $sqlstring = 'SELECT a0 = 0';
   my @params;
   my $expect = [{'a0' => 0}];
   foreach my $i (1..1123) {
      $sqlstring .= ", a$i = ?";
      $$expect[0]{"a$i"} = -$i;
      push(@params, ['int', -$i]);
   }
   my $result = $X->sql($sqlstring, \@params);
   push (@testres, compare($expect, $result));
}

blurb("many parameters OUTPUT");
if (1) {
   my $sqlstring = 'SELECT @R0 = 0';
   my %params;
   my @values;
   my $expect;
   foreach my $i (0..1123) {
      $sqlstring .= ", \@R$i = 7*\@R$i" unless $i == 0;
      push(@$expect, 7 * $i);
      push(@values, $i);
      $params{"R$i"} = ['int', \$values[$i]];
   }
   $X->sql($sqlstring, \%params);
   push (@testres, compare($expect, \@values));
}

blurb("NULL value for OUTPUT parameter");
if (1) {
   my $out1 = 'This is not NULL!';
   $X->sql('SELECT @d = NULL', { d => ['varchar(40)', \$out1]});
   push(@testres, compare(undef, $out1));
}


blurb("mix of named and positional parameters");
if (1) {
   my $expect = {'a' => 12, 'b' => 233, 'c' => 288};
   my $result = $X->sql_one('SELECT a = ?, b = @x + @y, c = ? + @x',
                           [['int', 12], ['int', 98]],
                            {'@x' => ['int', 190],
                             y    => ['int', 43]}, HASH);
   push (@testres, compare($expect, $result));
}


blurb("mix of named and positional OUTPUT parameters");
if (1) {
   my $expect = [12, 233, 288];
   my ($out1, $out2, $out3);
   $X->sql('SELECT @a = ?, ? = @x + @y, @c = ? + @x',
            [['int', 12], ['int', \$out2], ['int', 98]],
             {c   => ['int', \$out3],
             '@x' => ['int', 190],
             '@a' => ['int', \$out1], 
              y   => ['int', 43]});
   push (@testres, compare($expect, [$out1, $out2, $out3]));
}

blurb("Not expanding '?' in /* */");
if (1) {
   my $expect = [{'a' => 12, 'c' => 19}];
   my $result = $X->sql('SELECT a = ?, /* b = ?, */ c = ?', 
                        [['int', 12], ['int', 19]]);
   push (@testres, compare($expect, $result));
}

blurb("Not expanding '?' after --");
if (1) {
   my $expect = [{'a' => 12, 'c' => 19}];
   my $result = $X->sql(<<SQLEND,  [['int', 12], ['int', 19]]);
   SELECT a = ?, -- b = ?,
          c = ?
SQLEND
   push (@testres, compare($expect, $result));
}

blurb("-- in /*");
if (1) {
   my $expect = [{'a' => 12, 'Col 2' => 14, 'c' => 19}];
   my $result = $X->sql(<<SQLEND,  [['int', 12], ['int', 14], ['int', 19]]);
   SELECT a = ?, /*
       -- b = */ ?,
       c = ?
SQLEND
   push (@testres, compare($expect, $result));
}

blurb("Nested /*");
if (1) {
   my $expect = [{'a' => 12, 'Col 2' => 19}];
   my $result = $X->sql(<<SQLEND,  [['int', 12], ['int', 19]]);
SELECT a = ?, /* b = ?, /*
       c = ?, */ d = */ ?
SQLEND
   push (@testres, compare($expect, $result));
}

blurb("Not expanding '?' literal");
if (1) {
   my $expect = {'a' => 12, 'b' => '?', 'c' => 19};
   my $result = $X->sql_one("SELECT a = ?, b = '?', c = ?", 
                            [['int', 12], ['int', 19]], HASH);
   push (@testres, compare($expect, $result));
}

blurb("Ignoring '/*' in literal");
if (1) {
   my $expect = [{'a' => 12, 'b' => '/*', 'c' => 19}];
   my $result = $X->sql(<<SQLEND,  [['int', 12], ['int', 19]]);
   SELECT a = ?, b = '/*', c = ?
SQLEND
   push (@testres, compare($expect, $result));
}

blurb("Not expanding '?' in quoted identifiers");
if (1) {
   my $expect = [{'a?' => 12, '?' => 456, 'c' => 19}];
   my $result = $X->sql(<<SQLEND,  [['int', 12], ['int', 456], ['int', 19]]);
   SELECT "a?" = ?, [?] = ?, c = ?
SQLEND
   push (@testres, compare($expect, $result));
}

blurb("doubling of quotes");
if (1) {
   my $expect = {'a' => 12, 'b"?' => "?'?987", 'c' => 19};
   my $result = $X->sql_one(<<SQLEND,  [['int', 12], ['int', 987], ['int', 19]], HASH);
   SELECT a = ?, "b""?" = '?''?' + ltrim(str(?)), c = ?
SQLEND
   push (@testres, compare($expect, $result));
}

blurb("doubling of brackets");
if (1) {
   my $expect = [{'a' => 12, 'b]?' => "?[?987", 'c' => 19}];
   my $result = $X->sql(<<SQLEND,  [['int', 12], ['int', 987], ['int', 19]]);
   SELECT a = ?, [b]]?] = '?[?' + ltrim(str(?)), c = ?
SQLEND
   push (@testres, compare($expect, $result));
}


blurb("expansion of ???");
if (1) {
   my $expect = [{'a' => 12, 'c' => 19}];
   my $result = $X->sql("SELECT a = ???,  c = ?",
                     {'@P1@P2@P3' => ['int', 12], '@P4' => ['int', 19]});
   push (@testres, compare($expect, $result));
}

blurb("Expansion of ??? at end of string");
if (1) {
   my $expect = {'a' => 12, 'c' => 19};
   my $result = $X->sql_one("SELECT a = ?,  c = ???",
                            {'@P1' => ['int', 12], '@P2@P3@P4' => ['int', 19]}, 
                             HASH);
   push (@testres, compare($expect, $result));
}

blurb("Expanding of '???' only");
if (1) {
   my $expect;
   if ($sqlver >= 10) {
      $expect = qr/Must declare the scalar variable ['"]\@P1\@P2(\@P3)?["']/;
   }
   else {
      $expect = qr/Incorrect syntax near ['"]\@P1\@P2(\@P3)?["']/;
   }
   delete $X->{ErrInfo}{Messages};
   $X->{errInfo}{printLines}   = 25;
   $X->{errInfo}{printMsg}     = 25;
   $X->{errInfo}{printText}    = 25;
   $X->sql("???", {'@P1@P2@P3' => ['int', 12]});
   push(@testres, ($X->{ErrInfo}{Messages}[0]{'text'} =~ $expect ? 1 : 0));
   $X->{errInfo}{printLines}   = 11;
   $X->{errInfo}{printMsg}     = 11;
   $X->{errInfo}{printText}    = 11;
}

blurb("General test with alias type");
if (1) {
   my $expect = 78;
   my $result = $X->sql_one('SELECT ? / 10', [['int_type', 780]], SCALAR);
   push(@testres, compare($expect, $result));
}

blurb("General test with alias type from different database");
if (1) {
   sql("USE master");
   my $expect = 78;
   my $result = $X->sql_one('SELECT ? / 10', 
                            [['tempdb..int_type', 780]], SCALAR);
   push(@testres, compare($expect, $result));
   sql("USE tempdb");
}


blurb("General test with alias type OUTPUT");
if (1) {
   my $expect = 78;
   my $out;
   $X->sql('SELECT @r2 = @r1 / 10', 
           {r1 => ['int_type', 780], 
            r2 => ['int_type', \$out]});
   push(@testres, compare($expect, $out));
}


#------------------------- date/time data types ---------------------

blurb ("datetime HASH in and out");
if (1) {
   $X->{DatetimeOption} = DATETIME_HASH;
   my $expect = [{'d' => {Year => 1945, Month => 5, Day => 9,
                  Hour => 12, Minute => 14, Second => 0, Fraction => 0}}];
   my $result = $X->sql(
      'SELECT d = dateadd(YEAR, 27, dateadd(MONTH, -6, dateadd(DAY, -2, ?)))',
      [['Smalldatetime', {Year => 1918, Month => 11, Day => 11,
                          Hour => 12, Minute => 14}]]);
   push(@testres, compare($expect, $result));
}

blurb ("datetime HASH in and output param");
if (1) {
   $X->{DatetimeOption} = DATETIME_HASH;
   my $expect = {Year => 1945, Month => 5, Day => 9,
                 Hour => 12, Minute => 14, Second => 0, Fraction => 0};
   my $d = {Year => 1918, Month => 11, Day => 11, Hour => 12, Minute => 14};
   my $result = $X->sql(<<'SQLEND',  {'@P1' => ['Smalldatetime', \$d]}, LIST);
      SELECT @P1 = dateadd(YEAR, 27, dateadd(MONTH, -6, dateadd(DAY, -2, @P1)))
      SELECT convert(char(16), @P1, 121)
SQLEND
   push(@testres, compare($expect, $d));
   blurb("Result reference with output param");
   push(@testres, compare([['1945-05-09 12:14']], $result));
}    

blurb ("datetime HASH in and output param with ISO");
if (1) {
   $X->{DatetimeOption} = DATETIME_ISO;
   my $expect = '1945-05-09 12:14';
   my $d = {Year => 1918, Month => 11, Day => 11, Hour => 12, Minute => 14};
   $X->sql(<<'SQLEND',  {'@P1' => ['Smalldatetime', \$d]});
      SELECT @P1 = dateadd(YEAR, 27, dateadd(MONTH, -6, dateadd(DAY, -2, @P1)))
SQLEND
   push(@testres, compare($expect, $d));
}    


blurb ("datetime HASH in and separate output param");
if (1) {
   $X->{DatetimeOption} = DATETIME_HASH;
   my $expect = {Year => 1945, Month => 5, Day => 9,
                 Hour => 12, Minute => 14, Second => 0, Fraction => 0};
   my $d_in = {Year => 1918, Month => 11, Day => 11, Hour => 12, Minute => 14};
   my $d_out;
   my $result = $X->sql(
      'SELECT ? = dateadd(YEAR, 27, dateadd(MONTH, -6, dateadd(DAY, -2, ?)))',
     [['Smalldatetime', \$d_out], ['smalldatetime', $d_in]]);
   push(@testres, compare($expect, $d_out));
   blurb("Empty result set with output param");
   push(@testres, compare([], $result));
}

blurb("date");
if ($sqlver >= 10) {
   $X->{DatetimeOption} = DATETIME_ISO;
   my $sqltext = 'SELECT dateadd(DAY, 1, ?)';
   my $expect = ['1998-12-11'];
   my $result = $X->sql_one($sqltext, [['date', '1998-12-10']], LIST);
   push(@testres, compare($expect, $result));
}
else { 
   push(@testres, 'skip, new date/time types not supported on this platform.');
}   


blurb("date OUTPUT");
if ($sqlver >= 10) {
   $X->{DatetimeOption} = DATETIME_ISO;
   my $expect = '1998-12-11';
   my $out;
   $X->sql("SELECT ? = convert(date, '19981211')", [['date', \$out]]);
   push(@testres, compare($expect, $out));
}
else { 
   push(@testres, 'skip, new date/time types not supported on this platform.');
}   


blurb("time");
if ($sqlver >= 10) {
   my $sqltext = 
      'SELECT dateadd(HOUR, 1, ?), dateadd(MINUTE, 1, ?), dateadd(MS, 8, ?)';
   my $expect = ['14:12:21', '17:23:23.1234567', '00:12:12.123'];
   my  $result = $X->sql_one($sqltext, [['time(0)', '13:12:21'],
                                        ['time',    '17:22:23.1234567'],
                                        ['time(3)', '00:12:12.115']], LIST);
   push(@testres, compare($expect, $result));
}
else { 
   push(@testres, 'skip, new date/time types not supported on this platform.');
}   

blurb("time OUTPUT");
if ($sqlver >= 10) {
   my $sqltext = <<'SQLEND';
      SELECT @a = dateadd(HOUR, 1, @a), 
             @b = dateadd(MINUTE, 1, @b), 
             @c = dateadd(MS, 8, @c)
SQLEND
   my $expect = ['14:12:21', '17:23:23.1234567', '00:12:12.123'];

   my $a = '13:12:21';
   my $b = '17:22:23.1234567';
   my $c = '00:12:12.115';
   $X->sql($sqltext, {a => ['time(0)', \$a],
                      b => ['time',    \$b],
                      c => ['time(3)', \$c]});
   push(@testres, compare($expect, [$a, $b, $c]));
}
else { 
   push(@testres, 'skip, new date/time types not supported on this platform.');
}   


blurb("datetime2");
if ($sqlver >= 10) {
   my $date = ($X->{Provider} >= PROVIDER_SQLNCLI10 ? '1899-12-30' : '1900-01-01');
   my $sqltext = 'SELECT dateadd(HOUR, 1, ?), dateadd(MINUTE, 1, ?), dateadd(MS, 8, ?)';
   my $expect = ["$date 14:12:21", "$date 17:23:23.1234567",
                 "$date 00:12:12.1230000"];
   my $result = $X->sql_one($sqltext, [['datetime2(0)', '13:12:21'],
                                       ['datetime2',    '17:22:23.1234567'],
                                       ['datetime2(7)', '00:12:12.115']], LIST);
   push(@testres, compare($expect, $result));
}
else { 
   push(@testres, 'skip, new date/time types not supported on this platform.');
}   

blurb("datetime2 OUTPUT");
if ($sqlver >= 10) {
   my $date = ($X->{Provider} >= PROVIDER_SQLNCLI10 ? '1899-12-30' : '1900-01-01');
   my $sqltext = <<'SQLEND';
      SELECT @a = dateadd(HOUR, 1, @a), 
             @b = dateadd(MINUTE, 1, @b), 
             @c = dateadd(MS, 8, @c)
SQLEND
   my $expect = ["$date 14:12:21", "$date 17:23:23.1234567",
                 "$date 00:12:12.1230000"];
   my $a = '13:12:21';
   my $b = '17:22:23.1234567';
   my $c = '00:12:12.115';
   $X->sql($sqltext, {'@a' => ['DateTime2(0)', \$a],
                      '@b' => ['datetime2',    \$b],
                      '@c' => ['datetime2 (7) ', \$c]});
   push(@testres, compare($expect, [$a, $b, $c]));
}
else { 
   push(@testres, 'skip, new date/time types not supported on this platform.');
}   

blurb("datetime2 with user-defined type");
if ($sqlver >= 10) {
   my $date = ($X->{Provider} >= PROVIDER_SQLNCLI10 ? '1899-12-30' : '1900-01-01');
   my $sqltext = 'SELECT dateadd(MINUTE, 1, ?)';
   my $expect = "$date 17:23:23.1234";
   my $result = $X->sql_one($sqltext, [['datetime2_type', '17:22:23.1234067']], 
                            SCALAR);
   push(@testres, compare($expect, $result));
}
else { 
   push(@testres, 'skip, new date/time types not supported on this platform.');
}   


blurb("datetimeoffset");
if ($sqlver >= 10) {
   my $sqltext = "SELECT switchoffset(?, '+08:00'), dateadd(YEAR, 1, ?)";
   my $expect = ['2005-09-30 20:12:21.00 +08:00', '1454-08-11 17:23:23.0000000 +00:00'];
   my $result = $X->sql_one($sqltext, 
                            [['datetimeoffset(2)', '2005-09-30 14:12:21 +02:00'],
                             ['datetimeoffset',    '1453-08-11 17:23:23']],
                            LIST);
   push(@testres, compare($expect, $result));
}
else { 
   push(@testres, 'skip, new date/time types not supported on this platform.');
}   

blurb("datetimeoffset OUTPUT");
if ($sqlver >= 10) {
   my $sqltext = 
        "SELECT ? = switchoffset(?, '+08:00'), ? = dateadd(YEAR, 1, ?)";
   my $expect = ['2005-09-30 20:12:21.0 +08:00', 
                 '1454-08-11 17:23:23.0000000 +00:00'];
   my ($out1, $out2);
   $X->sql($sqltext, [['datetimeoffset(1)', \$out1],
                      ['datetimeoffset(2)', '2005-09-30 14:12:21 +02:00'],
                      ['DATETIMEOFFSET',    \$out2],
                      ['datetimeoffset',    '1453-08-11 17:23:23']]);
   push(@testres, compare($expect, [$out1, $out2]));
}
else { 
   push(@testres, 'skip, new date/time types not supported on this platform.');
}   

blurb("datetimeoffset with alias type");
if ($sqlver >= 10) {
   my $sqltext = 
        "SELECT ? = switchoffset(?, '+08:00'), ? = dateadd(YEAR, 1, ?)";
   my $expect = ['2005-09-30 20:12:21 +08:00', 
                 '1454-08-11 17:23:23 +00:00'];
   my ($out1, $out2);
   $X->sql($sqltext, [['dateoff_type', \$out1],
                      ['dateoff_type', '2005-09-30 14:12:21 +02:00'],
                      ['dbo.dateoff_type',  \$out2],
                      ['[dbo].[dateoff_type]',    '1453-08-11 17:23:23']]);
   push(@testres, compare($expect, [$out1, $out2]));
}
else { 
   push(@testres, 'skip, new date/time types not supported on this platform.');
}   


#---------------------------------- Decimal ----------------------------
blurb ("decimal with variations");
if (1) {
   $X->{DecimalAsStr} = 1;
   my $expect = [{'d1' => '246246246246',
                  'd2' => '3578',
                  'd3' => '246246246246.246246',
                  'n1' => '94.22',
                  'n2' => '94.22'}];
   my $result = $X->sql('SELECT d1 = 2*?, d2 = 2*?, d3 = 2*?, n1 = 2*?, n2 = 2*?',
                     [['decimal',          '123123123123.123123'],
                      ['decimal(10)',      '1789.44'],
                      ['decimal(18,6)',    '123123123123.123123'],
                      ['NUMERIC(8, 2) ',   '47.11'],
                      ['numeric( 8 , 2 )', '47.11']]);
   push(@testres, compare($expect, $result));
}

blurb ("decimal with variations, alias types");
if ($sqlver >= 9) {
   $X->{DecimalAsStr} = 1;
   my $expect = [{'d1' => '24690',
                  'd2' => '37037.01',
                  'd3' => '49382.68'}];
   my $result = $X->sql('SELECT d1 = 2*?, d2 = 3*?, d3 = 4*?',
                     [['guest.decimal_type',  '12345.67'],
                      ['decimal_type',        '12345.67'],
                      ['dbo.decimal_type',    '12345.67']]);
   push(@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, schema for types not supported on SQL 2000 and earlier.');
}

blurb ("decimal with variations, alias types as guest");
if ($sqlver >= 9) {
   $X->{DecimalAsStr} = 1;
   my $expect = [{'d1' => '24690',
                  'd2' => '37035',
                  'd3' => '49382.68'}];
   # We need a new connection for this test, or else the cache will
   # outsmart us.
   my $guest = testsqllogin();
   if ($sqlver >= 9) {
      $guest->sql("EXECUTE AS USER = 'guest'");
   }
   else {
      $guest->sql("SETUSER 'guest'");
   }
   my $result = $guest->sql('SELECT d1 = 2*?, d2 = 3*?, d3 = 4*?',
                           [['guest.decimal_type',  '12345.67'],
                            ['decimal_type',        '12345.67'],
                            ['dbo.decimal_type',    '12345.67']]);
   push(@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, schema for types not supported on SQL 2000 and earlier.');
}


blurb ("named decimal with variations");
if (1) {
   $X->{DecimalAsStr} = 1;
   my $expect = [{'d1' => '246246246246',
                  'd2' => '3578',
                  'd3' => '246246246246.246246',
                  'n1' => '94.22',
                  'n2' => '94.22'}];
   my $params = {d1 => ['decimal',            '123123123123.123123'],
                 d2 => ['"decimal" (10)',     '1789.44'],
                 d3 => ['decimal(18,6)',      '123123123123.123123'],
                 n1 => ['[numeric] (8, 2) ',   '47.11'],
                 n2 => ['[numEric]( 8 , 2 )', '47.11']};
   my $result = $X->sql(<<'SQLEND', $params);
        SELECT d1 = @d1 + @d1, d2 = 2*@d2, d3 = 2*@d3, 
                n1 = @n2 + @n1, n2 = @n2 + @n2
SQLEND
   push(@testres, compare($expect, $result));
}

blurb ("decimal with variations OUTPUT");
if (1) {
   $X->{DecimalAsStr} = 1;
   my $expect = ['246246246246', '3578', '246246246246.246246',
              '94.22', '94.22'];
   my $d1 = '123123123123.123123';
   my $d2 = '1789.44';
   my $d3 = '123123123123.123123';
   my $n1 = '47.11';
   my $n2 = '47.11';
   my $params = {d1 => ['decimal',            \$d1],
                 d2 => [' "decimal" (10)',    \$d2],
                 d3 => [' [decimal] (18,6)',  \$d3],
                 n1 => ['numeric(8, 2) ',     \$n1],
                 n2 => ['numeric( 8 , 2 )',   \$n2]};
   my @result = $X->sql(<<'SQLEND',  $params, SCALAR);
      SELECT @d1 = 2*@d1, @d2 = 2*@d2, @d3 = 2*@d3,  
             @n1 = 2*@n1, @n2 = 2*@n2
      SELECT @d1
      SELECT @d2
      SELECT @d3
      SELECT @n1
      SELECT @n2
SQLEND
   push(@testres, compare($expect, [$d1, $d2, $d3, $n1, $n2]));
   blurb("Result array with output param");
   push(@testres, compare($expect, \@result));
}

#---------------------------------- Binary -------------------------
blurb("binary as binary");
if (1) {
   $X->{BinaryAsStr} = 0;
   my $expect = [{'a' => "ABCDEFABCDEF", 'b' => "ABCDEF\0\0ABCDEF", 'c' => "ABCABC"}];
   my $result = $X->sql('SELECT a = ? + ?, b = ? + ?, c = ? + ?',
                       [['binary', 'ABCDEF'],
                        ['binary', 'ABCDEF'],
                        ['binary(8)', 'ABCDEF'],
                        ['varbinary( 8)', 'ABCDEF'],
                        ['binary( 3 )', 'ABCDEF'],
                        ['binary(3 )', 'ABCDEF']]);
   push (@testres, compare($expect, $result));
}

blurb("binary as binary OUTPUT");
if (1) {
   $X->{BinaryAsStr} = 0;
   my $expect = ["ABCDEF", "A", "ABCDEF\0\0ABCDEF\0\0", "ABCABC"];
   my $input = 'ABCDEF';
   my ($out1, $out2, $out3);
   my $params = [['binary',        \$out1],
                 ['binary',        $input],
                 ['binary',        $input],
                 ['binary(16)',    \$out2],
                 ['binary(8)',     $input],
                 ['varbinary(8 )', $input],
                 ['varbinary',     \$out3],
                 ['binary(3)',     $input],                                               ['binary( 3 )', 'ABCDEF'],
                 ['binary(3 )',    $input]];
   my $result = $X->sql_one(<<'SQLEND', $params, LIST);
      SELECT 12, 'Alfons'
      SELECT ? = ? + ?, ? = ? + ?, ? = ? + ? 
SQLEND
   push (@testres, compare($expect, [$input, $out1, $out2, $out3]));
   blurb("Result set from sql_one with output parameter");
   push (@testres, compare([12, 'Alfons'], $result));
}

blurb("named binary as binary");
if (1) {
   $X->{BinaryAsStr} = 0;
   my $expect = [{'a' => "ABCDEFABCDEF", 'b' => "ABCDEF\0\0ABCDEF\0\0", 'c' => "ABCABC"}];
   my $result = $X->sql(
                'SELECT a = @b1 + @b1, b = @b2 + @b2, c = @b3 + @b3',
                {'@b1' => ['binary', 'ABCDEF'],
                 '@b2' => ['binary(8)', 'ABCDEF'],
                 '@b3' => ['binary( 3 )', 'ABCDEF']});
   push (@testres, compare($expect, $result));
}

blurb("Too long binary as binary");
if (1) {
   $X->{BinaryAsStr} = 0;
   my $expect ;
   if ($sqlver <= 8) {
      $expect = {'a' => '691174' . '2010BA06691174' x 571,
                 'b' => '47119660AB0102' x 571 . '471196'};
   }
   else {
      $expect = {'a' => '2010BA06691174' x 7453,
                 'b' => '47119660AB0102' x 571 . '471196'};
   }
   my $result = $X->sql_one(
                'SELECT a = convert(image, reverse(?)), b = ? + ?',
                 [['varbinary', '47119660AB0102' x 7453],
                  ['binary',    '47119660AB0102' x 5453],
                  ['BINARY',    '47119660AB0102' x 5453]], HASH);
   push (@testres, compare($expect, $result));
}

blurb("Too long binary as binary OUTPUT");
if (1) {
   my $expect;
   $X->{BinaryAsStr} = 0;
   if ($sqlver <= 8) {
      $expect = ['691174' . '2010BA06691174' x 571,
                 '47119660AB0102' x 571 . '471196'];
   }
   elsif ($X->{Provider} == PROVIDER_SQLOLEDB) {
      $expect = ['2010BA06691174' x 571 . '2010BA',
                 '47119660AB0102' x 571 . '471196'];
   }
   else {
      $expect = ['2010BA06691174' x 7453,
                 '47119660AB0102' x 571 . '471196'];
   }
   my($a, $b);
   my $type_a = ($sqlver >= 9 ? 'varbinary(MAX)' : 'varbinary(8000)');
   $b = '1' x 8000;
   $X->sql('SELECT @a = convert(image, reverse(@p1)), @b = @p2 + @p3',
           {a =>  [$type_a,     \$a],
            b =>  ['binary',    \$b],
            p1 => ['varbinary', '47119660AB0102' x 7453],
            p2 => ['binary',    '47119660AB0102' x 5453],
            p3 => ['BINARY',    '47119660AB0102' x 5453]});
   push (@testres, compare($expect, [$a, $b]));
}

blurb("varbinary(MAX) as binary");
if ($sqlver >= 9) {
   $X->{BinaryAsStr} = 0;
   my $expect = {'a' => '2010BA06691174' x 7453,
                 'b' => '47119660AB0102' x 10906};
   my $result = $X->sql_one(
             'SELECT a = convert(varbinary(MAX), reverse(@b1)), b = @b2 + @b2',
             {'@b1' => ['varbinary( MaX )',  '47119660AB0102' x 7453],
              '@b2' => ['varbinary( Max)', '47119660AB0102' x 5453]},
              HASH);
   push (@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, MAX types not supported on SQL 2000 and earlier.');
}

blurb("varbinary(MAX) as binary OUTPUT");
if ($sqlver >= 9) {
   $X->{BinaryAsStr} = 0;
   my $expect = ['2010BA06691174' x 7453, '47119660AB0102' x 10906];
   if ($X->{Provider} == PROVIDER_SQLOLEDB) {
      $$expect[0] = substr($$expect[0], 0, 8000);
      $$expect[1] = substr($$expect[1], 0, 8000);
   }
   my($a, $b);
   $X->sql('SELECT ? = convert(varbinary(MAX), reverse(@b1)), ? = @b2 + @b2',
           [['Varbinary(MAX)', \$a], ['VARBINARY(MAX)', \$b]],
           {'@b1' => ['"maxtype"',  '47119660AB0102' x 7453],
            '@b2' => ['[maxtype]', '47119660AB0102' x 5453]});
   push (@testres, compare($expect, [$a, $b]));
}
else {
   push(@testres, 'skip, MAX types not supported on SQL 2000 and earlier.');
}

blurb("Testing binary as string");
if (1) {
   $X->{BinaryAsStr} = 1;
   my $expect = [{'a' => "ABCDEFABCDEF", 'b' => "ABCDEF0000ABCDEF",
                  'c' => "ABCDABCD"}];
   my $result = $X->sql('SELECT a = ? + ?, b = ? + ?, c = ? + ?',
                       [['varbinary', 'ABCDEF'],
                        ['binary', 'ABCDEF'],
                        ['binary(5)', 'ABCDEF'],
                        ['varbinary( 5)', 'ABCDEF'],
                        ['binary( 2 )', 'ABCDEF'],
                        ['binary(2 )', 'ABCDEF']]);
   push (@testres, compare($expect, $result));
}

blurb("binary as string OUPTUT");
if (1) {
   $X->{BinaryAsStr} = 1;
   my $expect = ["ABCDEF", "ABCDEFABCDEF", "ABCDEF0000ABCDEF", "ABCDABCD"];
   my $input = 'ABCDEF';
   my ($out1, $out2, $out3);
   my $params = [['varbinary',      \$out1],
                 ['varbinary',      'ABCDEF'],
                 ['binary',         'ABCDEF'],
                 ['varbinary(10)',  \$out2],
                 ['binary(5)',      'ABCDEF'],
                 ['varbinary(5)',   'ABCDEF'],
                 ['binary(4)',      \$out3],
                 ['binary( 2 )',    'ABCDEF'],
                 ['binary(2 )',     'ABCDEF']];
   my %result = $X->sql_one(<<'SQLEND', $params, HASH);
      SELECT ? = ? + ?, ? = ? + ?, ? = ? + ?
      SELECT 12 AS a, 'Kalle kanin' AS kk
SQLEND
   push (@testres, compare($expect, [$input, $out1, $out2, $out3]));
   blurb('sql_one with OUTPUT param and HASH return');
   push (@testres, compare({ a => 12, kk => 'Kalle kanin'}, \%result));
}

blurb("too long binary as str");
if (1) {
   my $expect;
   $X->{BinaryAsStr} = 1;
   if ($sqlver <= 8) {
      $expect = {'a' => '01AB60961147' . '0201AB60961147' x 1142,
                 'b' => '47119660AB0102' x 1142 . '47119660AB01'};
   }
   else {
      $expect = {'a' => '0201AB60961147' x 7453,
                 'b' => '47119660AB0102' x 1142 . '47119660AB01'};
   }
   my $result = $X->sql_one(
                 'SELECT a = convert(image, reverse(?)), b = ? + ?',
                 [['varbinary', '47119660AB0102' x 7453],
                  ['binary',    '47119660AB0102' x 5453],
                  ['binary',    '47119660AB0102' x 5453]], HASH);
   push (@testres, compare($expect, $result));
}

blurb("too long binary as str OUPTUT");
if (1) {
    $X->{BinaryAsStr} = 1;
    my $expect;
    if ($sqlver <= 8  or $X->{Provider} == PROVIDER_SQLOLEDB) {
       $expect = ['01AB60961147' . '0201AB60961147' x 1142,
                  '47119660AB0102' x 1142 . '47119660AB01'];
    }
    else {
       $expect = ['0201AB60961147' x 7453,
                  '47119660AB0102' x 1142 . '47119660AB01'];
    }
    my $a = '47119660AB0102' x 7453;
    my $b = '47119660AB0102' x 5453; 
    $X->sql('SELECT @a = convert(image, reverse(@a)), @b = @b + @b',
           {a => ['varbinary', \$a],
            b => ['binary',    \$b]});
    push (@testres, compare($expect,  [$a, $b]));
}

blurb("binary as 0x");
if (1) {
   $X->{BinaryAsStr} = 'x';
   my $expect = [{'a' => "0xABCDEFABCDEF", 'b' => "0xABCDEF0000ABCDEF",
                  'c' => "0xABCDABCD"}];
   my $result = $X->sql('SELECT a = ? + ?, b = ? + ?, c = ? + ?',
                       [['binary', '0xABCDEF'],
                        ['varbinary', '0xABCDEF'],
                        ['binary(5)', '0xABCDEF'],
                        ['varbinary( 5)', '0xABCDEF'],
                        ['binary( 2 )', '0xABCDEF'],
                        ['binary(2 )', '0xABCDEF']]);
   push (@testres, compare($expect, $result));
}

blurb("binary as 0x OUTPUT");
if ($sqlver >= 7) {
   $X->{BinaryAsStr} = 'x';
   my $expect = ["0xABCDEF", "0xABCDEFABCDEF", "0xABCDEFABCD"];
   my ($out1, $out2, $out3);
   $out1 = $out2 = $out3 = '0xABCDEF';
   $X->sql('SELECT @a = @a + @a, @b = @b + @b, @c = @d + @d',
           {a => ['binary',         \$out1],
            b => ['varbinary',      \$out2],
            c => ['varbinary( 5 )', \$out3],
            d => ['varbinary',      '0xABCDEF']});
   push (@testres, compare($expect, [$out1, $out2, $out3]));
}


blurb("too long binary as 0x");
$X->{BinaryAsStr} = 'x';
if (1) {
   my $expect;
   if ($sqlver <= 8) {
      $expect = {'a' => '0x' . '01AB60961147' . '0201AB60961147' x 1142,
                 'b' => '0x' . '47119660AB0102' x 1142 . '47119660AB01'};
   }
   else {
      $expect = {'a' => '0x' . '0201AB60961147' x 7453,
                 'b' => '0x' . '47119660AB0102' x 1142 . '47119660AB01'};
   }
   my $result = $X->sql_one(
                 'SELECT a = convert(image, reverse(?)), b = ? + ?',
                 [['varbinary', '0x' . '47119660AB0102' x 7453],
                  ['binary',    '0x' . '47119660AB0102' x 5453],
                  ['binary',    '0x' . '47119660AB0102' x 5453]],
                 HASH);
   push (@testres, compare($expect, $result));
}

blurb("too long binary as 0x OUTPUT");
if (1) {
    $X->{BinaryAsStr} = 'x';
    my $expect;
    if ($sqlver <= 8) {
       $expect = ['0x' . '01AB60961147' . '0201AB60961147' x 1142,
                  '0x' . '47119660AB0102' x 1142 . '47119660AB01'];
    }
    elsif ($X->{Provider} == PROVIDER_SQLOLEDB) {
       $expect = ['0x' . '0201AB60961147' x 1142 . '0201AB609611' ,
                  '0x' . '47119660AB0102' x 1142 . '47119660AB01'];
    }
    else {
       $expect = ['0x' . '0201AB60961147' x 7453,
                  '0x' . '47119660AB0102' x 1142 . '47119660AB01'];
    }
    my($p1, $p3);
    $p1 = '0x' . 'FF' x 10000;
    $X->sql('SELECT ? = convert(image, reverse(?)), ? = ? + ?',
             [['varbinary', \$p1],
              ['varbinary', '0x' . '47119660AB0102' x 7453],
              ['varbinary', \$p3],
              ['binary',    '0x' . '47119660AB0102' x 5453],
              ['binary',    '0x' . '47119660AB0102' x 5453]]);
    push (@testres, compare($expect, [$p1, $p3]));
}

blurb("varbinary(MAX) as str");
if ($sqlver >= 9) {
   $X->{BinaryAsStr} = 1;
   my $expect = {'a' => '0201AB60961147' x 7453,
                 'b' => '47119660AB0102' x 10906};
   my $result = $X->sql_one(
            'SELECT a = convert(varbinary(MAX), reverse(@b1)), b = @b2 + @b2',
            {'@b1' => ['varbinary( MAX )',  '47119660AB0102' x 7453],
             '@b2' => ['varbinary(Max )', '47119660AB0102' x 5453]},
              HASH);
   push (@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, MAX types not supported on SQL 2000 and earlier.');
}

blurb("varbinary(MAX) as str OUTPUT");
if ($sqlver >= 9) {
   $X->{BinaryAsStr} = 1;
   my $expect = ['0201AB60961147' x 7453, '47119660AB0102' x 10906];
   if ($X->{Provider} == PROVIDER_SQLOLEDB) {
      $$expect[0] = substr($$expect[0], 0, 16000);
      $$expect[1] = substr($$expect[1], 0, 16000);
   }
   my ($a, $b);
   $X->sql('SELECT @a = convert(varbinary(MAX), reverse(@b1)), @b = @b2 + @b2',
           {'@a'  => ['varbinary(MAX)',   \$a],
            '@b'  => ['varbinary(MAX)',   \$b],  
            '@b1' => [' varbinary ( MAX ) ', '47119660AB0102' x 7453],
            '@b2' => ['varbinary(Max )',  '47119660AB0102' x 5453]});
   push (@testres, compare($expect, [$a, $b]));
}
else {
   push(@testres, 'skip, MAX types not supported on SQL 2000 and earlier.');
}


#---------------------------- timestamp / rowversion -----------------
blurb("timestamp and rowversion");
if (1) {
   $X->{BinaryAsStr} = 1;
   my $expect = [{'a' => "ABCDEF8800000000", 'b' => "1234567800000000"}];
   my $params = {'@b1' => ['timestamp', 'ABCDEF88'],
                 '@b2' => ['rowversion', '123456780']};
   if ($sqlver <= 7) {
      $$params{'@b2'}[0] = 'timestamp';
   }
   my $result = $X->sql('SELECT a = @b1, b = @b2', $params);
   push (@testres, compare($expect, $result));
}

blurb("timestamp and rowversion, 0x");
if (1) {
   $X->{BinaryAsStr} = 'x';
   my $params = {'@b1' => ['timestamp', 'ABCDEF88'],
                 '@b2' => ['rowversion', '123456780']};
   if ($sqlver <= 7) {
      $$params{'@b2'}[0] = 'timestamp';
   }
   my $expect = [{'a' => "0xABCDEF8800000000", 'b' => "0x1234567800000000"}];
   my $result = $X->sql('SELECT a = @b1, b = @b2', $params);
   push (@testres, compare($expect, $result));
}

blurb("timestamp and rowversion, OUTPUT");
if (1) {
   $X->{BinaryAsStr} = 'x';
   my ($out1, $out2);
   my $params = {'@b1' => ['timestamp',  \$out1],
                 '@b2' => ['rowversion', \$out2]};
   if ($sqlver <= 7) {
      $$params{'@b2'}[0] = 'timestamp';
   }
   my $result = $X->sql_one('SELECT @@DBTS SELECT @b1 = @@DBTS, @b2 = @@DBTS', 
                            $params, SCALAR); 
   push (@testres, compare([$result, $result], [$out1, $out2]));
}


#----------------------------- char/varchar --------------------------
blurb("char/varchar");
if (1) {
   my $expect = {'a' => "x'zx''z ", 'b' => "0xABCDEF  0xABCDEF",
                 'c' => "0xAB0xAB"};
   my $result = $X->sql_one('SELECT a = ? + ?, b = ? + ?, c = ? + ?',
                           [['char', "x'z"],
                            ['varchar', "x''z "],
                            ['char(10)', '0xABCDEF'],
                            ['varchar( 10)', '0xABCDEF'],
                            ['char( 4 )', '0xABCDEF'],
                            ['char(4 )', '0xABCDEF']], HASH);
   push (@testres, compare($expect, $result));
}

blurb("named char/varchar");
if (1) {
   my $expect = {'a' => "x''z 0xABCDEF", 'b' => "0xABCDEF  x''z ",
                 'c' => "0xABCDEF0xABCDEF  "};
   my $result = $X->sql_one(
                'SELECT a = @v1 + @v3, b = @v2 + @v1, c = @v3 + @v2',
                 {v1    => ['varchar',  "x''z "],
                  v2    => ['char(10)', '0xABCDEF'],
                  '@v3' => ['varchar( 10)', '0xABCDEF']}, HASH);
   push (@testres, compare($expect, $result));
}

blurb("char/varchar OUTPUT");
if (1) {
   my $expect = ["x'zx''z ", "0xABCDEF  0xABCDEF", "0xAB0xAB  "];
   my ($a, $b, $c);
   $c = '1234567890';
   $X->sql('SELECT @a = @P1 + @P2, @b = @P3 + @P4, @c = @P5 + @P6',
           {'@P1' => ['char',         "x'z"],
            '@P2' => ['varchar',      "x''z "],
            '@P3' => ['char_type',    '0xABCDEF'],
            '@P4' => ['varchar( 10)', '0xABCDEF'],
            '@P5' => ['char( 4 )',    '0xABCDEF'],
            '@P6' => ['char(4 )',     '0xABCDEF'],
            '@a'  => ['varchar',      \$a],
            '@b'  => ['varchar',      \$b],
            '@c'  => ['char',         \$c]});
   push (@testres, compare($expect, [$a, $b, $c]));
}

blurb("too long varchar");
if (1) {
   my $expect;
   if ($sqlver <= 8) {
      $expect = {'a' => 'HELLO DOLLY! ' x 615 . 'HELLO'};
   }
   else {
      $expect = {'a' => 'HELLO DOLLY! ' x 1854};
   }
   my $result = $X->sql_one('SELECT a = upper(?)',
                            [['varchar',  'Hello Dolly! ' x 1854]], HASH);
   push (@testres, compare($expect, $result));
}

blurb("too long varchar OUTPUT");
if (1) {
   my $expect;
   if ($sqlver <= 8 or $X->{Provider} == PROVIDER_SQLOLEDB) {
      $expect = 'HELLO DOLLY! ' x 615 . 'HELLO';
   }
   else {
      $expect = 'HELLO DOLLY! ' x 1854;
   }
   my $a = 'Hello Dolly! ' x 1854;
   $X->sql('SELECT @a = upper(@a)', {a=> ['varchar',  \$a]});
   push (@testres, compare($expect, $a));
}

blurb("too long char");
if (1) {
   my $expect = {'a' => 'HELLO DOLLY! ' x 615 . 'HELLO'};
   my $result = $X->sql_one('SELECT a = upper(?)',
                 [['char',  'Hello Dolly! ' x 1854]], HASH);
   push (@testres, compare($expect, $result));
}

blurb("too long char OUTPUT");
if (1) {
   my $expect = 'HELLO DOLLY! ' x 615 . 'HELLO';
   my $a = 'Hello Dolly! ' x 1854;
   $X->sql('SELECT @a = upper(@a)', {a => ['char', \$a]});
   push (@testres, compare($expect, $a));
}


blurb("varchar(MAX)");
if ($sqlver >= 9) {
   my $expect = {'a' => 'HELLO DOLLY! ' x 1854,
                 'b' => "21 PA\x{0179}DZIERNIKA 2004 " x 1711};
   my $result = $X->sql_one('SELECT a = upper(?), b = upper(?)',
                  [['varchar(MAX)',  'Hello Dolly! ' x 1854],
                  ['nvarchar(max)', "21 pa\x{017A}dziernika 2004 " x 1711]],
                 HASH);
   push (@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, MAX types not supported on SQL 2000 and earlier.');
}

blurb("varchar(MAX) OUTPUT");
if ($sqlver >= 9) {
   my $expect = ['HELLO DOLLY! ' x 1854,
                 "21 PA\x{0179}DZIERNIKA 2004 " x 1711];
   if ($X->{Provider} == PROVIDER_SQLOLEDB) {
      $$expect[0] = substr($$expect[0], 0, 8000);
      $$expect[1] = substr($$expect[1], 0, 4000);
   }
   my $a = 'Hello Dolly! ' x 1854;
   my $b = "21 pa\x{017A}dziernika 2004 " x 1711;
   $X->sql('SELECT @a = upper(@a), @b = upper(@b)',
          { a => ['varchar(MAX)',  \$a],
            b => ['nvarchar(max)', \$b]});
   push (@testres, compare($expect, [$a, $b]));
}
else {
   push(@testres, 'skip, MAX types not supported on SQL 2000 and earlier.');
}


#----------------------------- nchar/nvarchar ----------------------
blurb("nchar/nvarchar");
if (1) {
   my $expect = [{'a' => "x'z\x{ABCD}E''F", 'b' => "\x{ABCD}EF  0xAB",
                 'c' => "0xAB0xAB"}];
   my $result = $X->sql('SELECT a = ? + ?, b = ? + ?, c = ? + ?',
                       [['nchar', "x'z"],
                        ['nchar', "\x{ABCD}E''F"],
                        ['nchar(5)', "\x{ABCD}EF"],
                        ['nvarchar( 5)', '0xAB'],
                        ['nchar( 4 )', '0xABCDEF'],
                        ['nchar(4 )', '0xABCDEF']]);
   push (@testres, compare($expect, $result));
}

blurb("nchar/nvarchar OUTPUT");
if (1) {
   my $expect = ["x'z\x{ABCD}E''F", "\x{ABCD}EF  0xAB ", "0"];
   my ($out1, $out2, $out3);
   $X->sql('SELECT ? = ? + ?, ? = ? + ?, ? = ? + ?',
           [['nvarchar',     \$out1],
            ['nchar',        "x'z"],
            ['nchar',        "\x{ABCD}E''F"],
            ['nchar(10)',    \$out2],
            ['nchar(5)',     "\x{ABCD}EF"],
            ['nvarchar( 5)', '0xAB'],
            ['nchar',        \$out3],
            ['nchar( 4 )',   '0xABCDEF'],
            ['nchar(4 )',    '0xABCDEF']]);
   push (@testres, compare($expect, [$out1, $out2, $out3]));
}

blurb("nchar/nvarchar alias_type");
if (1) {
   my $expect = "1234567890ABXYZABCDEFUTS";
   my ($out1);
   $X->sql('SELECT @a = @b + @c',
           {a => ['nvarchar(24)',   \$out1],
            b => ['unicode_type',   '1234567890ABC'],
            c => ['[unicode_type]', 'XYZABCDEFUTS7']});
   push (@testres, compare($expect, $out1));
}

blurb("too long nvarchar");
if (1) {
   my $expect;
   if ($sqlver <= 8) {
      $expect = {'b' => "21 PA\x{0179}DZIERNIKA 2004 " x 190 .
                        "21 PA\x{0179}DZIE"};
   }
   else {
      $expect = {'b' => "21 PA\x{0179}DZIERNIKA 2004 " x 250};
   }
   my $result = $X->sql_one('SELECT b = upper(?)',
                [['nvarchar', "21 pa\x{017A}dziernika 2004 " x 250]],
                 HASH);
   push (@testres, compare($expect, $result));
}

blurb("too long nvarchar, OUTPUT");
if (1) {
   my $expect;
   if ($sqlver <= 8 or $X->{Provider} == PROVIDER_SQLOLEDB) {
      $expect = "21 PA\x{0179}DZIERNIKA 2004 " x 190 . "21 PA\x{0179}DZIE";
   }
   else {
      $expect = "21 PA\x{0179}DZIERNIKA 2004 " x 250;
   }
   my $b = "21 pa\x{017A}dziernika 2004 " x 250;
   $X->sql('SELECT @b = upper(@b)', {'@b' => ['nvarchar', \$b]});
   push (@testres, compare($expect, $b));
}

blurb("too long nchar");
if (1) {
   my $expect = {'b' => "21 PA\x{0179}DZIERNIKA 2004 " x 190 .
                        "21 PA\x{0179}DZIE"};
   my $result = $X->sql_one('SELECT b = upper(?)',
                 [['nchar', "21 pa\x{017A}dziernika 2004 " x 250]],
                 HASH);
   push (@testres, compare($expect, $result));
}

blurb("too long nchar OUPTUT");
if (1) {
   my $expect = "21 PA\x{0179}DZIERNIKA 2004 " x 190 . "21 PA\x{0179}DZIE";
   my $b = "21 pa\x{017A}dziernika 2004 " x 250;
   $X->sql('SELECT @b = upper(@b)', {b =>  ['nchar', \$b]});
   push (@testres, compare($expect, $b));
}

blurb("sysname");
if (1) {
   my $expect = 256;
   my $result = sql_one('SELECT datalength(?)', 
                        [['sysname', 'x' x 255]], SCALAR);
   push(@testres, compare($expect, $result));
}

#----------------------------------- XML -------------------------
blurb("XML without schema OUTPUT");
if ($sqlver >= 9 and $X->{Provider} >= PROVIDER_SQLNCLI) {
   my $expect = '<Robyn>My wife and my dead wife</Robyn>';
   my $sqltext = <<'SQLEND';
   SET @a.modify(N'replace value of (/Robyn/text())[1]
                  with concat((/Robyn/text())[1], " and my dead wife")');
SQLEND
   my $a = '<Robyn>My wife</Robyn>';
   $X->sql($sqltext, {'@a' => ['xml', \$a]});
   push (@testres, compare($expect, $a));
}
else {
   push(@testres, 'skip, XML data type not supported on this platform.');
}

blurb("XML without schema");
if ($sqlver >= 9) {
   my $expect = '<Robyn>My wife and my dead wife</Robyn>';
   my $sqltext = <<'SQLEND';
   SET @a.modify(N'replace value of (/Robyn/text())[1]
                  with concat((/Robyn/text())[1], " and my dead wife")');
   SELECT a = @a
SQLEND
   my $result = $X->sql_one($sqltext, 
                            {'@a' => ['xml', '<Robyn>My wife</Robyn>']},
                            SCALAR);
   push (@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, XML data type not supported on this platform.');
}

blurb("XML with charset decl utf-16 OUTPUT");
if ($sqlver >= 9 and $X->{Provider} >= PROVIDER_SQLNCLI) {
   my $xml = '<?xml version="1.0" encoding="utf-16"?>' . "\n" .
             '<MMV>' . "27 pa\x{017A}dziernika 2005 " x 2000 . '</MMV>';
   my $expect = '<MMV>' . "27 pa\x{017A}dziernika 2005 " x 2001 . '</MMV>';
   my $sqltext = <<SQLEND;
   SET \@a.modify(N'replace value of (/MMV/text())[1]
                   with concat((/MMV/text())[1], "27 pa\x{017A}dziernika 2005 ")');
SQLEND
   $X->sql($sqltext, {'@a' => ['xml', \$xml]});
   push (@testres, compare($expect, $xml));
}
else {
   push(@testres, 'skip, XML data type not supported on this platform.');
}

blurb("XML with charset decl utf-16");
if ($sqlver >= 9) {
   my $xml = '<?xml version="1.0" encoding="utf-16"?>' . "\n" .
             '<MMV>' . "27 pa\x{017A}dziernika 2005 " x 2000 . '</MMV>';
   my $expect = '<MMV>' . "27 pa\x{017A}dziernika 2005 " x 2001 . '</MMV>';
   my $sqltext = <<SQLEND;
   SET \@a.modify(N'replace value of (/MMV/text())[1]
                   with concat((/MMV/text())[1], "27 pa\x{017A}dziernika 2005 ")');
   SELECT a = \@a
SQLEND
   my $result = $X->sql_one($sqltext, {'@a' => ['xml', $xml]}, SCALAR);
   push (@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, XML data type not supported on this platform.');
}

blurb("XML with charset decl utf-8 OUTPUT");
if ($sqlver >= 9 and $X->{Provider} >= PROVIDER_SQLNCLI) {
   my $xml = '<?xml version="1.0" encoding="utf-8"?>' . "\n" .
             '<MMV>' . "27 pa\x{017A}dziernika 2005 " x 2000 . '</MMV>';
   my $expect = '<MMV>' . "27 pa\x{017A}dziernika 2005 " x 2001 . '</MMV>';
   my $sqltext = <<SQLEND;
   SET ?.modify(N'replace value of (/MMV/text())[1]
                 with concat((/MMV/text())[1], "27 pa\x{017A}dziernika 2005 ")');
SQLEND
   $X->sql($sqltext, [['xml', \$xml]]);
   push (@testres, compare($expect, $xml));
}
else {
   push(@testres, 'skip, XML data type not supported on this platform.');
}

blurb("XML with charset decl utf-8");
if ($sqlver >= 9) {
   my $xml = '<?xml version="1.0" encoding="utf-8"?>' . "\n" .
             '<MMV>' . "27 pa\x{017A}dziernika 2005 " x 2000 . '</MMV>';
   my $expect = '<MMV>' . "27 pa\x{017A}dziernika 2005 " x 2001 . '</MMV>';
   my $sqltext = <<SQLEND;
   SET \@a.modify(N'replace value of (/MMV/text())[1]
                    with concat((/MMV/text())[1], "27 pa\x{017A}dziernika 2005 ")');
   SELECT a = \@a
SQLEND
   my $result = $X->sql($sqltext, {'@a' => ['xml', $xml]}, SCALAR, SINGLEROW);
   push (@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, XML data type not supported on this platform.');
}

blurb("XML with charset decl iso-8859-1 OUTPUT");
if ($sqlver >= 9 and $X->{Provider} >= PROVIDER_SQLNCLI) {
   my $xml = '<?xml version="1.0" encoding="iso-8859-1"?>' . "\n" .
             '<ñandú>' . "Räksmörgås" . '</ñandú>';
   my $expect = '<ñandú>' . "RäksmörgåsRäksmörgås". '</ñandú>';
   my $sqltext = <<'SQLEND';
   SET @a.modify(N'replace value of (/ñandú/text())[1]
                  with concat((/ñandú/text())[1], "Räksmörgås")');
SQLEND
   $X->sql($sqltext, {'@a' => ['xml', \$xml]});
   push (@testres, compare($expect, $xml));
}
else {
   push(@testres, 'skip, XML data type not supported on this platform.');
}


blurb("XML with charset decl iso-8859-1");
if ($sqlver >= 9) {
   my $xml = '<?xml version="1.0" encoding="iso-8859-1"?>' . "\n" .
             '<ñandú>' . "Räksmörgås" . '</ñandú>';
   my $expect = '<ñandú>' . "RäksmörgåsRäksmörgås". '</ñandú>';
   my $sqltext = <<'SQLEND';
   SET @a.modify(N'replace value of (/ñandú/text())[1]
                  with concat((/ñandú/text())[1], "Räksmörgås")');
   SELECT a = @a
SQLEND
   my $result = $X->sql_one($sqltext, {'@a' => ['xml', $xml]}, SCALAR);
   push (@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, XML data type not supported on this platform.');
}

blurb("Testing XML with schema OUTPUT");
if ($sqlver >= 9 and $X->{Provider} >= PROVIDER_SQLNCLI) {
   my $xml = '<Olle>Mors lilla Olle</Olle>';
   my $expect = '<Olle>Mors lilla Olle i skogen gick</Olle>';
   my $sqltext = <<'SQLEND';
   SET @a.modify(N'replace value of (/Olle)[1]
                  with concat((/Olle)[1], " i skogen gick")');
SQLEND
   $X->sql($sqltext, {'@a' => ['xml(OlleSC)', \$xml]});
   push (@testres, compare($expect, $xml));
}
else {
   push(@testres, 'skip, schemabound XML not supported on this platform.');
}


blurb("Testing XML with schema in parens");
if ($sqlver >= 9 and $X->{Provider} >= PROVIDER_SQLNCLI) {
   my $expect = '<Olle>Mors lilla Olle i skogen gick</Olle>';
   my $sqltext = <<'SQLEND';
   SET @a.modify(N'replace value of (/Olle)[1]
                  with concat((/Olle)[1], " i skogen gick")');
   SELECT a = @a
SQLEND
   my $result = $X->sql_one($sqltext,
                         {'@a' => ['xml(OlleSC)', '<Olle>Mors lilla Olle</Olle>']},
                         SCALAR);
   push (@testres, compare($expect, $result));
}
else { 
   push(@testres, 'skip, schemabound XML not supported on this platform.');
}   

blurb("Testing XML with schema in parens with spaces");
if ($sqlver >= 9 and $X->{Provider} >= PROVIDER_SQLNCLI) {
   my $expect = '<Olle>Rosor på kinden solsken i blick</Olle>';
   my $sqltext = <<'SQLEND';
   SET @a.modify(N'replace value of (/Olle)[1]
                  with concat((/Olle)[1], " solsken i blick")');
   SELECT a = @a
SQLEND
   my $result = $X->sql_one($sqltext,
                         {'@a' => ['XML( dbo.OlleSC )', '<Olle>Rosor på kinden</Olle>']},
                         SCALAR);
   push (@testres, compare($expect, $result));
}
else { 
   push(@testres, 'skip, schemabound XML not supported on this platform.');
}   

blurb("XML with schema as third param from other DB OUTPUT");
if ($sqlver >= 9 and $X->{Provider} >= PROVIDER_SQLNCLI) {
   $X->sql("USE master");
   my $xml = '<Olle>Bara jag slapp</Olle>';
   my $expect = '<Olle>Bara jag slapp att så ensam här gå</Olle>';
   my $sqltext = <<'SQLEND';
   SET @a.modify(N'replace value of (/Olle)[1]
                  with concat((/Olle)[1], " att så ensam här gå")');
SQLEND
   $X->sql($sqltext, {'@a' => ['xml', \$xml, 'tempdb..OlleSC']});
   push (@testres, compare($expect, $xml));
   $X->sql("USE tempdb");
}
else {
   push(@testres, 'skip, schemabound XML not supported on this platform.');
}

blurb("XML with schema as third param from other DB");
if ($sqlver >= 9 and $X->{Provider} >= PROVIDER_SQLNCLI) {
   $X->sql("USE master");
   my $expect = '<Olle>Bara jag slapp att så ensam här gå</Olle>';
   my $sqltext = <<'SQLEND';
   SET @a.modify(N'replace value of (/Olle)[1]
                  with concat((/Olle)[1], " att så ensam här gå")');
   SELECT a = @a
SQLEND
   my $result = $X->sql_one($sqltext,
               {'@a' => ['xml', '<Olle>Bara jag slapp</Olle>',
                        'tempdb..OlleSC']},
                SCALAR);
   push (@testres, compare($expect, $result));
   $X->sql("USE tempdb");
}
else { 
   push(@testres, 'skip, schemabound XML not supported on this platform.');
}   

blurb("XML with schema in both places");
if ($sqlver >= 9 and $X->{Provider} >= PROVIDER_SQLNCLI) {
   my $expect = '<Olle>Mors lilla Olle med solsken i blick</Olle>';
   my $sqltext = <<'SQLEND';
   SET @a.modify(N'replace value of (/Olle)[1]
                  with concat((/Olle)[1], " med solsken i blick")');
   SELECT a = @a
SQLEND
   my $result = $X->sql_one($sqltext,
                {'@a' => ['xml(OlleSC)', '<Olle>Mors lilla Olle</Olle>', 
                          'OlleSC']},
                 SCALAR);
   push (@testres, compare($expect, $result));
}
else { 
   push(@testres, 'skip, schemabound XML not supported on this platform.');
}   


#----------------------------- CLR UDTs --------------------------------
blurb("UDT with BinAsStr");
if ($clr_enabled) {
   $X->{BinaryAsStr} = 1;
   my $expect = {p => '01800000048000000580000009',
                 s => '0005000000455353494E'};
   my $sqltext = <<'SQLEND';
   SET @p.Transpose()
   SET @s = upper(@s.ToString())
   SELECT p = @p, s = @s
SQLEND
   my $result = $X->sql_one($sqltext,
               {'@p' => ['UDT(OllePoint)', '0x01800000098000000480000005'],
                '@s' => ['udt', '0x0005000000657373694E', "[Olle-String]"]},
               HASH);
   push (@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, CLR not supported/enabled on this platform');
}

blurb("UDT with BinAsStr OUTPUT");
if ($clr_enabled) {
   $X->{BinaryAsStr} = 1;
   my $expect = ['01800000048000000580000009', '0005000000455353494E'];
   my $sqltext = <<'SQLEND';
   SET @p.Transpose()
   SET @s = upper(@s.ToString())
SQLEND
   my $p = '0x01800000098000000480000005';
   my $s = '0x0005000000657373694E';
   $X->sql($sqltext, {'@p' => ['OllePoint', \$p],
                      '@s' => ['[Olle-String]', \$s]});
   push (@testres, compare($expect, [$p, $s]));
}
else {
   push(@testres, 'skip, CLR not supported/enabled on this platform');
}


blurb("UDT with BinAsOx");
if ($clr_enabled) {
   $X->{BinaryAsStr} = 'x';
   my $expect = {p => '0x01800000048000000580000009',
              s => '0x0005000000455353494E'};
   my $sqltext = <<'SQLEND';
   SET @p.Transpose()
   SET @s = upper(@s.ToString())
   SELECT p = @p, s = @s
SQLEND
   my $result = $X->sql_one($sqltext,
               {'@p' => ['UDT(OllePoint)', '0x01800000098000000480000005', 'OllePoint'],
                '@s' => ["udt(dbo.[Olle-String] )", '0x0005000000657373694E']},
               HASH);
   push (@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, CLR not supported/enabled on this platform');
}

blurb("UDT with BinAsBin");
if ($clr_enabled) {
   $X->{BinaryAsStr} = 0;
   my $expect = {p => pack('H*', '01800000048000000580000009'),
                 s => pack('H*', '0005000000455353494E')};
   my $sqltext = <<'SQLEND';
   SET @p.Transpose()
   SET @s = upper(@s.ToString())
   SELECT p = @p, s = @s
SQLEND
   my $result = $X->sql_one($sqltext,
                {'@p' => ['dbo.OllePoint',
                          pack('H*', '01800000098000000480000005')],
                '@s' => ['UDT',
                          pack('H*', '0005000000657373694E'), "  [Olle-String]  "]},
               HASH);
   push (@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, CLR not supported/enabled on this platform');
}

blurb("UDT with BinAsBin OUTPUT");
if ($clr_enabled) {
   $X->{BinaryAsStr} = 0;
   my $expect = [pack('H*', '01800000048000000580000009'),
                 pack('H*', '0005000000455353494E')];
   my $sqltext = <<'SQLEND';
   SET @p.Transpose()
   SET @s = upper(@s.ToString())
SQLEND
   my $p = pack('H*', '01800000098000000480000005');
   my $s = pack('H*', '0005000000657373694E');
   $X->sql($sqltext, {'@p' => ['UDT(dbo.OllePoint)', \$p],
                      '@s' => ['UDT', \$s, "[Olle-String]  "]});
   push (@testres, compare($expect, [$p, $s]));
}
else {
   push(@testres, 'skip, CLR not supported/enabled on this platform');
}
 
blurb("UDT with BinAsStr, from other db");
if ($clr_enabled) {
   $X->{BinaryAsStr} = 1;
   $X->sql("USE master");
   my $expect = {p => '01800000048000000580000009',
                 s => '0005000000455353494E'};
   my $sqltext = <<'SQLEND';
   SET @p.Transpose()
   SET @s = upper(@s.ToString())
   SELECT p = @p, s = @s
SQLEND
   my $result = $X->sql_one($sqltext,
               {'@p' => ['UDT(tempdb.dbo.OllePoint)', '0x01800000098000000480000005'],
                '@s' => ['UDT', '0x0005000000657373694E', "tempdb..[Olle-String]"]},
               HASH);
   push (@testres, compare($expect, $result));
   $X->sql("USE tempdb");
}
else {
   push(@testres, 'skip, CLR not supported/enabled on this platform');
}

blurb("Large UDT");
if ($sqlver >= 10 and $clr_enabled and $X->{Provider} >= PROVIDER_SQLNCLI) {
   $X->{BinaryAsStr} = 1;
   my $sqltext = 'SELECT datalength(?)';
   my $result = $X->sql_one($sqltext,
                [['UDT',
                  '00C8320000' . ('73C3A56772C3B66D736BC3A452' x 1000),
                  '[OlleString MAX]']],
                SCALAR);
   push(@testres, compare(13005, $result));
}
else {
   push(@testres, 'skip, large UDTs not supported/enabled on this platform');
}

blurb("Large UDT OUTPUT");
if ($sqlver >= 10 and $clr_enabled and $X->{Provider} >= PROVIDER_SQLNCLI10) {
   $X->{BinaryAsStr} = 1;
   my $s = '00C8320000' .   ('73C3A56772C3B66D736BC3A452' x 1000);
   my $expect = '00C8320000' . ('53C3854752C3964D534BC38452' x 1000);
   $X->sql('SET @s = upper(@s.ToString())', 
           {s=> ['[OlleString MAX]', \$s]});
   push(@testres, compare($expect, $s));
}
else {
   push(@testres, 'skip, OUTPUT params of large UDTs not supported/enabled on this platform');
}

blurb("Large UDT (but short)");
if ($sqlver >= 10 and $clr_enabled and $X->{Provider} >= PROVIDER_SQLNCLI) {
   $X->{BinaryAsStr} = 1;
   my $sqltext = 'SELECT datalength(?)';
   my $result = $X->sql($sqltext,
                         [['UDT(MAX)',
                          '000D00000073C3A56772C3B66D736BC3A452',
                          '[OlleString MAX]']],
                         SCALAR, SINGLEROW);
   push(@testres, compare(18, $result));
}
else {
   push(@testres, 'skip, large UDTs not supported/enabled on this platform');
}

blurb("Large UDT (but short) OUTPUT");
if ($sqlver >= 10 and $clr_enabled and $X->{Provider} >= PROVIDER_SQLNCLI10) {
   $X->{BinaryAsStr} = 1;
   my $s = '000D00000073C3A56772C3B66D736BC3A452';
   my $expect = '00C8320000' . ('53C3854752C3964D534BC38452' x 1000);
   $X->sql('SET @s = replicate(upper(@s.ToString()), 1000)', 
           { '@s' => ['UDT(MAX)', \$s, '[OlleString MAX]']});
   push(@testres, compare($expect, $s));
}
else {
   push(@testres, 'skip, OUTPUT params of large UDTs not supported/enabled on this platform');
}

blurb("hierarchyid");
if ($sqlver >= 10) {
   $X->{BinaryAsStr} = 1;
   my $sqltext = 'SELECT cast(@a as varchar(50)), cast(@b as varchar(50));';
   my $expect = ['/7/1/23/980/', '/1/7/980/'];
   my $result = $X->sql_one($sqltext, 
                            {'@a' => ['hierarchyid', '0x9D783FDC0C80'],
                             '@b' => ['UDT', '0x5CFDC0C8', 'hierarchyid']},
                            LIST);
   push(@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, hierarchyid not supported on SQL 2005 and earlier');
}

blurb("hierarchyid OUTPUT");
if ($sqlver >= 10  and $X->{Provider} >= PROVIDER_SQLNCLI10) {
   $X->{BinaryAsStr} = 1;
   my $sqltext = <<'SQLEND';
   SET @a = hierarchyid::Parse('/7/1/23/980/')
   SET @b = hierarchyid::Parse('/1/7/980/')
SQLEND
   my $expect = ['9D783FDC0C80', '5CFDC0C8'];
   my($a, $b);
   $X->sql($sqltext, {'@a' => ['HIERARCHYID', \$a],
                      '@b' => ['[hierarchyid]', \$b]});
   push(@testres, compare($expect, [$a, $b]));
}
else {
   push(@testres, 'skip, OUTPUT hierarchyid not supported on this platform');
}

blurb("spatial, take 1");
if ($sqlver >= 10 and $X->{Provider} >= PROVIDER_SQLNCLI10) {
   my $sqltext = 'SELECT @geom.STAsText(), @geog.STAsText();';
   my $expect = ['POINT (98 12)', 'POINT (18.36 59.656)'];
   my $result = $X->sql_one($sqltext, 
                   {'@geom' => ['geometry', '0x0A000000010C00000000008058400000000000002840'],
                    '@geog' => ['geography', '0xE6100000010C8716D9CEF7D34D405C8FC2F5285C3240']},
                   LIST);
   push(@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, spatial data types not supported on this platform');
}

blurb("spatial2");
if ($sqlver >= 10 and $X->{Provider} >= PROVIDER_SQLNCLI10) {
   my $sqltext = 'SELECT @geom.STAsText(), @geog.STAsText();';
   my $expect = ['POINT (98 12)', 'POINT (18.36 59.656)'];
   my $result = $X->sql_one($sqltext, 
                     {'@geom' => ['UDT', '0x0A000000010C00000000008058400000000000002840', 'geometry'],
                      '@geog' => ['UDT', '0xE6100000010C8716D9CEF7D34D405C8FC2F5285C3240', 'geography']},
                      LIST);
   push(@testres, compare($expect, $result));
}
else {
   push(@testres, 'skip, spatial data types not supported on this platform');
}

blurb("spatial OUTPUT 1");
if ($sqlver >= 10 and $X->{Provider} >= PROVIDER_SQLNCLI10) {
   my $sqltext = <<'SQLEND';
   SELECT @geom = convert(geometry, 'POINT (98 12)'),
          @geog = convert(geography, 'POINT (18.36 59.656)')
SQLEND
   my($out1, $out2);
   my $expect = ['00000000010C00000000008058400000000000002840', 
                 'E6100000010C8716D9CEF7D34D405C8FC2F5285C3240'];
   $X->sql($sqltext, {'@geom' => ['GEOMETRY',  \$out1],
                      '@geog' => ['[Geography]', \$out2]});
   push(@testres, compare($expect, [$out1, $out2]));
}
else {
   push(@testres, 'skip, OUTPUT of spatial data types not supported on this platform');
}
 
blurb("spatial2 OUTPUT");
if ($sqlver >= 10 and $X->{Provider} >= PROVIDER_SQLNCLI10) {
   my $sqltext = <<'SQLEND';
   SELECT @geom = convert(geometry, 'POINT (98 12)'),
          @geog = convert(geography, 'POINT (18.36 59.656)')
SQLEND
   my($out1, $out2);
   my $expect = ['00000000010C00000000008058400000000000002840', 
              'E6100000010C8716D9CEF7D34D405C8FC2F5285C3240'];
   my($out3, $out4);
   $X->sql($sqltext, {'@geom' => ['UDT', \$out3, 'geometry'],
                      '@geog' => ['UDT', \$out4, 'geography']});
   push(@testres, compare($expect, [$out3, $out4]));
}
else {
   push(@testres, 'skip, OUTPUT of spatial data types not supported on this platform');
}

#-------------------------------- TVP ------------------------------
blurb("TVP with output parameter");
if ($sqlver >= 10 and $X->{Provider} >= PROVIDER_SQLNCLI10) {
   my $expect = 3;
   $X->sql(<<SQLEND);
      IF EXISTS (SELECT * FROM sys.table_types WHERE name = 'OlleTVP')
         DROP TYPE OlleTVP
      CREATE TYPE OlleTVP AS TABLE (a int NOT NULL);
SQLEND
   my $c;
   $X->sql('SELECT @c = COUNT(*) FROM @t', 
           {'@c' => ['int', \$c],
            '@t' => ['OlleTVP', [[12], [89], [23]]]});
   push(@testres, compare($expect, 3));
   $no_of_tests += 3;
}
else {
   push(@testres, 'skip, TVPs not supported on this platform');
}


#---------------------------------- End game! -----------------------------
delete_the_udts($X) if $clr_enabled;

if ($sqlver >= 9 and $X->{Provider} >= PROVIDER_SQLNCLI) {
   # Drop XML Schema if we created one.
   sql(<<SQLEND);
IF EXISTS (SELECT * FROM sys.xml_schema_collections WHERE name = 'OlleSC')
   DROP XML SCHEMA COLLECTION OlleSC
SQLEND
}

sql_sp('#create_type', ['int_type']);
sql_sp('#create_type', ['char_type']);
sql_sp('#create_type', ['unicode_type']);
sql_sp('#create_type', ['maxtype']);
sql_sp('#create_type', ['decimal_type', undef, 'guest']) if $sqlver >= 9;
sql_sp('#create_type', ['decimal_type']);
sql_sp('#create_type', ['dateoff_type']); 
sql_sp('#create_type', ['datetime2_type']);
sql_sp('#create_type', ['OlleTVP']);


my $ix = 1;
my $blurb = "";
my $no_of_tests = scalar(@testres) / 2;
print "1..$no_of_tests\n";
foreach my $result (@testres) {
   if ($result =~ /^#--/) {
      print $result if $verbose;
      $blurb = $result;
   }
   elsif ($result =~ /^skip/) {
      printf "ok %d # $result\n", $ix++;
   }
   elsif ($result == 1) {
      printf "ok %d\n", $ix++;
   }
   else {
      printf "not ok %d\n$blurb", $ix++;
   }
}

exit;

#------------------------- compare ------------------------
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
         my $ret = (not defined $x and not defined $y);
         warn "undef ne <$y>" if not $ret and not defined $x;
         warn "<$x> ne undef" if not $ret and not defined $y;
         return $ret;
      }
   }
   elsif ($refx ne $refy) {
      warn "<$x> ne <$y>";
      return 0;
   }
   elsif ($refx eq "ARRAY") {
      if ($#$x != $#$y) {
         warn "Different array lengths: $#$x and $#$y";
         return 0;
      }
      elsif ($#$x >= 0) {
         foreach $ix (0..$#$x) {
            $result = compare($$x[$ix], $$y[$ix]);
            warn "Diff at index $ix" if not $result;
            last if not $result;
         }
         return $result;
      }
      else {
         return 1;
      }
   }
   elsif ($refx eq "HASH") {
      # Filter some colinfo properties that are not relevant for this test.
      my @keysx = keys %$x;
      my @keysy = grep($_ !~ /^(Maybenull|Maxlength|Scale|Precision|Readonly)$/,
                       keys %$y);

      my $nokeys_x = scalar(@keysx);
      my $nokeys_y = scalar(@keysy);
      if ($nokeys_x != $nokeys_y) {
         warn "$nokeys_x keys != $nokeys_y keys";
         return 0;
      }
      elsif ($nokeys_x > 0) {
         foreach $key (@keysx) {
            if (not exists $$y{$key}) {
                warn "Key <$key> only on left side";
                return 0;
            }
            $result = compare($$x{$key}, $$y{$key});
            warn "Diff at key '$key'" if not $result;
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
      warn "<$x> ne <$y>" if $x ne $y;
      return ($x eq $y);
   }
}
