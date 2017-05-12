#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/t/3_retvalues.t 14    08-08-17 20:00 Sommar $
#
# This test suite tests return values from sql_sp. Most of the tests
# concerns UDFs.
#
# $History: 3_retvalues.t $
# 
# *****************  Version 14  *****************
# User: Sommar       Date: 08-08-17   Time: 20:00
# Updated in $/Perl/OlleDB/t
# Another geography revision.
#
# *****************  Version 13  *****************
# User: Sommar       Date: 08-05-04   Time: 22:35
# Updated in $/Perl/OlleDB/t
# Incorrect number of tests fixed.
#
# *****************  Version 12  *****************
# User: Sommar       Date: 08-05-04   Time: 22:01
# Updated in $/Perl/OlleDB/t
# Don't run the umpteen TZOffset tests with SQLOLEDB and SQLNCLI.
#
# *****************  Version 11  *****************
# User: Sommar       Date: 08-02-17   Time: 0:35
# Updated in $/Perl/OlleDB/t
# Restored funny names, now that SQL Native Client handles them properly
# again.
#
# *****************  Version 10  *****************
# User: Sommar       Date: 07-11-20   Time: 21:56
# Updated in $/Perl/OlleDB/t
# Added tests for spatial data types.
#
# *****************  Version 9  *****************
# User: Sommar       Date: 07-11-10   Time: 23:38
# Updated in $/Perl/OlleDB/t
# Added tests for the new date/time data types.
#
# *****************  Version 8  *****************
# User: Sommar       Date: 07-09-16   Time: 22:42
# Updated in $/Perl/OlleDB/t
# Added tests for large UDTs and hierarchyid. Temporary disabled funny
# names for SQL Native Client 10, since it can't cope with them.
#
# *****************  Version 7  *****************
# User: Sommar       Date: 07-09-08   Time: 23:18
# Updated in $/Perl/OlleDB/t
# Correct test on provider version.
#
# *****************  Version 6  *****************
# User: Sommar       Date: 05-11-26   Time: 23:47
# Updated in $/Perl/OlleDB/t
# Renamed the module from MSSQL::OlleDB to Win32::SqlServer.
#
# *****************  Version 5  *****************
# User: Sommar       Date: 05-10-29   Time: 22:14
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 4  *****************
# User: Sommar       Date: 05-10-25   Time: 22:57
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 3  *****************
# User: Sommar       Date: 05-07-25   Time: 0:40
# Updated in $/Perl/OlleDB/t
# Added tests fpt UDT and XML.
#
# *****************  Version 2  *****************
# User: Sommar       Date: 05-06-27   Time: 22:59
# Updated in $/Perl/OlleDB/t
# Added checks for the MAX datatypes.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 05-02-06   Time: 20:45
# Created in $/Perl/OlleDB/t
#---------------------------------------------------------------------

use strict;
use Win32::SqlServer qw(:DEFAULT :consts);
use File::Basename qw(dirname);

require &dirname($0) . '\testsqllogin.pl';
require '..\helpers\assemblies.pl';

use vars qw(@testres $verbose $retvalue $no_of_tests $clr_enabled);
use constant TESTUDF => 'olledb_testudf';

sub blurb{
    push (@testres, "#------ Testing @_ ------\n");
    print "#------ Testing @_ ------\n" if $verbose;
}

sub create_udf {
    my($X, $datatype, $param, $retvalue, $prelude) = @_;
    my $testudf = TESTUDF;
    delete $X->{procs}{$testudf};
    $prelude = '' if not defined $prelude;
    $X->sql("IF object_id('$testudf') IS NOT NULL DROP FUNCTION $testudf");
    $X->sql(<<SQLEND);
    CREATE FUNCTION $testudf ($param) RETURNS $datatype AS
    BEGIN
       $prelude
       RETURN $retvalue;
    END
SQLEND
}

sub datehash_compare {
  # Help routine to compare datehashes.
    my($val, $expect) = @_;

    foreach my $part (keys %$expect) {
       if (not defined $$val{$part} or $$expect{$part} != $$val{$part}) {
          warn "Expected $part=$$expect{$part}, got $$val{$part}.\n";
          return 0;
       }
    }

    foreach my $part (keys %$val) {
       if (not defined $$expect{$part}) {
          warn "Unexpected part '$part'\n";
          return 0;
       }
    }

    return 1;
}


$verbose = shift @ARGV;


$^W = 1;

$| = 1;

my $X = testsqllogin();
$X->sql("SET QUOTED_IDENTIFIER ON");
my ($sqlver) = split(/\./, $X->{SQL_version});

# Set up ErrInfo for test of return values.
$X->{errInfo}{RetStatOK}{4711}++;

$X->sql(<<'SQLEND');
IF object_id('check_ret_value') IS NOT NULL
   DROP PROCEDURE check_ret_value
IF object_id('multi_param_sp') IS NOT NULL
   DROP PROCEDURE multi_param_sp
SQLEND

$X->sql(<<'SQLEND');
CREATE PROCEDURE check_ret_value @ret int AS
   RETURN @ret
SQLEND

$X->sql(<<'SQLEND');
CREATE PROCEDURE multi_param_sp @p1 int = NULL,
                                  @p2 int = NULL OUTPUT,
                                  @p3 int = NULL,
                                  @p4 int = NULL OUTPUT,
                                  @p5 int = NULL OUTPUT AS
   SELECT @p2 = coalesce(@p1, 19) + 20
   SELECT @p4 = coalesce(@p3, 18) + 20
   SELECT @p5 = coalesce(@p5, 17) + 20
   RETURN
SQLEND

$retvalue = 233;
blurb('SP returns 0');
$X->sql_sp('check_ret_value', \$retvalue, [0]);
push(@testres, $retvalue == 0);

blurb('SP returns good non-zero');
$X->sql_sp('check_ret_value', \$retvalue, [4711]);
push(@testres, $retvalue == 4711);

blurb('SP returns bad non-zero');
eval(q!$X->sql_sp('check_ret_value', \$retvalue, [10])!);
push(@testres, ($@ =~ /returned status 10/i ? 1 : 0));

$no_of_tests = 3;

# Tests of omitting input parameters.
blurb("Input all parameters");
{ my ($p1, $p2, $p3, $p4, $p5) = (1, 2, 3, 4, 5);
  $X->sql_sp("multi_param_sp", [\$p1, \$p2, \$p3], {p4 => \$p4, p5 => \$p5});
  push(@testres, ($p2 == 21 and $p4 == 23 and $p5 == 25));
}

blurb("Only p1 and p2");
{ my ($p1, $p2) = (1, 2);
  $X->sql_sp("multi_param_sp", {p1 => \$p1, p2 => \$p2});
  push(@testres, $p2 == 21);
}

blurb("Only p3 and p4");
{ my ($p3, $p4) = (3, 4);
  $X->sql_sp("multi_param_sp", {p3 => \$p3, p4 => \$p4});
  push(@testres, $p4 == 23);
}

blurb("Only p1, p2 and p5");
{ my ($p1, $p2, $p5) = (1, undef, undef);
  $X->sql_sp("multi_param_sp", [\$p1, \$p2], {p5 => \$p5});
  push(@testres, ($p2 == 21 and $p5 == 37));
}

$no_of_tests += 4;

$X->sql(<<'SQLEND');
IF object_id('check_ret_value') IS NOT NULL
   DROP PROCEDURE check_ret_value
IF object_id('multi_param_sp') IS NOT NULL
   DROP PROCEDURE multi_param_sp
SQLEND

# For versions before SQL 2000, there is not much to test.
goto finally if ($sqlver < 8);

create_udf($X, 'bit', '', 1);
blurb('UDF bit');
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue == 1);

create_udf($X, 'tinyint', '@param tinyint', '@param + 1');
blurb('UDF tinyint');
$X->sql_sp(TESTUDF, \$retvalue, [123]);
push(@testres, $retvalue == 124);

create_udf($X, 'smallint', '@param smallint', '-3 * @param');
blurb('UDF smallint');
$X->sql_sp(TESTUDF, \$retvalue, [123]);
push(@testres, $retvalue == -369);

create_udf($X, 'int', '@param1 int, @param2 int', '@param1 + @param2');
blurb('UDF int');
$X->sql_sp(TESTUDF, \$retvalue, {param1 => 123, param2 => -500000});
push(@testres, $retvalue == (123 - 500000));

$X->{DecimalAsStr} = 0;
create_udf($X, 'bigint', '', '123456789123456');
blurb('UDF bigint');
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, abs($retvalue - 123456789123456) < 100);

$X->{DecimalAsStr} = 1;
$retvalue = 123;
blurb('UDF bigint, decimalasstr');
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq '123456789123456');

$X->{DecimalAsStr} = 0;
$retvalue = 123;
create_udf($X, 'decimal(24,6)', '@param decimal(8,6)', '@param + 123456789123456');
blurb('UDF decimal');
$X->sql_sp(TESTUDF, \$retvalue, ['0.123456']);
push(@testres, abs($retvalue - 123456789123456.123456) < 100);

$X->{DecimalAsStr} = 1;
$retvalue = 123;
blurb('UDF decimal, decimalasstr');
$X->sql_sp(TESTUDF, \$retvalue, ['0.123456']);
push(@testres, $retvalue eq '123456789123456.123456');

$retvalue = 123;
create_udf($X, 'float', '@param int', 'sqrt(@param)');
blurb('UDF float');
$X->sql_sp(TESTUDF, \$retvalue, [19]);
push(@testres, abs($retvalue - sqrt(19)) < 1E-15);

$X->{BinaryAsStr} = 0;
create_udf($X, 'binary(8)', '', '0x414243444546');
blurb('UDF binary as binary');
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq "ABCDEF\x00\x00");

$X->{BinaryAsStr} = 1;
blurb('UDF binary as string');
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq "4142434445460000");

$X->{BinaryAsStr} = 'x';
blurb('UDF binary as 0x');
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq "0x4142434445460000");

$retvalue = 123;
create_udf($X, 'uniqueidentifier', '', "'B8581AEF-059F-4B02-934D-C15F6C9638E7'");
blurb('UDF uniqueidentifier');
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq '{B8581AEF-059F-4B02-934D-C15F6C9638E7}');

create_udf($X, 'varchar(20)', "\@param varchar(20) = 'Kamel'", '@param');
blurb('UDF varchar');
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq 'Kamel');

blurb('UDF varchar, empty');
$X->sql_sp(TESTUDF, \$retvalue, ['']);
push(@testres, $retvalue eq '');

blurb('UDF varchar, NULL');
$X->sql_sp(TESTUDF, \$retvalue, [undef]);
push(@testres, not defined $retvalue);

create_udf($X, 'char(20)', "\@param varchar(20) = 'Kamel'", '@param');
blurb('UDF char');
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq 'Kamel' . ' ' x 15);

create_udf($X, 'nvarchar(20)', '', 'nchar(0x7623) + nchar(0x01AB) + nchar(0x2323)');
blurb('UDF nvarchar');
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq "\x{7623}\x{01AB}\x{2323}");

create_udf($X, 'nchar(20)', '', 'nchar(0x7623) + nchar(0x01AB) + nchar(0x2323)');
blurb('UDF nvarchar');
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq "\x{7623}\x{01AB}\x{2323}" . ' ' x 17);

$X->{DatetimeOption} = DATETIME_ISO;
create_udf($X, 'datetime', '', "'20050206 18:17:11.043'");
blurb('UDF datetime iso');
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq '2005-02-06 18:17:11.043');

$X->{DatetimeOption} = DATETIME_STRFMT;
blurb('UDF datetime strfmt');
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq '20050206 18:17:11.043');

$X->{DatetimeOption} = DATETIME_HASH;
blurb('UDF datetime iso');
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, datehash_compare($retvalue, {Year => 2005, Month => 2, Day => 6,
                                        Hour => 18, Minute => 17, Second => 11,
                                        Fraction => 43}));

create_udf($X, 'sql_variant', '@param int', 'convert(varchar, @param)');
blurb('UDF sql_variant/varchar');
undef $retvalue;
$X->sql_sp(TESTUDF, \$retvalue, [129]);
push(@testres, $retvalue eq '129');

$X->{DatetimeOption} = DATETIME_ISO;
create_udf($X, 'sql_variant', '@param int', 'convert(datetime, @param)');
blurb('UDF sql_variant/datetime');
$X->sql_sp(TESTUDF, \$retvalue, [12]);
push(@testres, $retvalue eq '1900-01-13 00:00:00.000');

$X->{BinaryAsStr} = 'x';
create_udf($X, 'sql_variant', '@param int', 'convert(varbinary(29), @param)');
blurb('UDF sql_variant/varbinary');
$X->sql_sp(TESTUDF, \$retvalue, [254]);
push(@testres, $retvalue eq '0x000000FE');

blurb('UDF sql_variant/NULL');
$X->sql_sp(TESTUDF, \$retvalue, [undef]);
push(@testres, not defined $retvalue);

$no_of_tests += 26;

if ($sqlver <= 8) {
   goto finally;
}

if ($X->{Provider} < PROVIDER_SQLNCLI) {
    goto finally;
}

blurb('UDF varchar(MAX)');
create_udf($X, 'varchar(MAX)', '@param varchar(MAX)', 'reverse(@param)');
$X->sql_sp(TESTUDF, \$retvalue, ['Palsternacksproducent' x 5000]);
push(@testres, $retvalue eq 'tnecudorpskcanretslaP' x 5000);

blurb('UDF nvarchar(MAX)');
create_udf($X, 'nvarchar(MAX)', '@param nvarchar(MAX)', 'upper(@param)');
$X->sql_sp(TESTUDF, \$retvalue, ["21 pa\x{017A}dziernika 2004 " x 5000]);
push(@testres, $retvalue eq "21 PA\x{0179}DZIERNIKA 2004 " x 5000);

$X->{BinaryAsStr} = 1;
blurb('UDF varbinary(MAX) as str');
create_udf($X, 'varbinary(MAX)', '@param varbinary(MAX)',
                'convert(varbinary(MAX), reverse(@param))');
$X->sql_sp(TESTUDF, \$retvalue, ['0x' . '47119660AB0102' x 5000]);
push(@testres, $retvalue eq '0201AB60961147' x 5000);

$X->{BinaryAsStr} = 'x';
blurb('UDF varbinary(MAX) 0x');
$X->sql_sp(TESTUDF, \$retvalue, ['47119660AB0102' x 5000]);
push(@testres, $retvalue eq '0x' . '0201AB60961147' x 5000);

$X->{BinaryAsStr} = 0;
blurb('UDF varbinary(MAX) as bin');
$X->sql_sp(TESTUDF, \$retvalue, ['47119660AB0102' x 5000]);
push(@testres, $retvalue eq '2010BA06691174' x 5000);

blurb('XML');
create_udf($X, 'xml', '@param xml', '@param',
           q!SET @param.modify('replace value of (/TEST/text())[1]
                                with concat((/TEST/text())[1], " extra text")')!);
$X->sql_sp(TESTUDF, \$retvalue, ['<TEST>regular text</TEST>']);
push(@testres, $retvalue eq '<TEST>regular text extra text</TEST>');

blurb('Long XML');
my $longoctober = "21 pa\x{017A}dziernika 2004 " x 2000;
create_udf($X, 'xml', '@param nvarchar(MAX)', '@xml',
           q!DECLARE @xml xml; SET @xml = (SELECT @param AS x FOR XML RAW)!);
$X->sql_sp(TESTUDF, \$retvalue, [$longoctober]);
push(@testres,
     ($retvalue =~ m!^<row\s+x\s*=\s*\"$longoctober\"\s*/\s*>$! ? 1 : 0));

blurb('XML(OlleSC)');
sql(<<SQLEND);
IF EXISTS (SELECT * FROM sys.xml_schema_collections WHERE name = 'OlleSC')
   DROP XML SCHEMA COLLECTION OlleSC
SQLEND
sql(<<SQLEND);
CREATE XML SCHEMA COLLECTION OlleSC AS '
<schema xmlns="http://www.w3.org/2001/XMLSchema">
      <element name="root" type="string"/>
</schema>
'
SQLEND
create_udf($X, 'xml(OlleSC)', '@param xml(OlleSC)', '@param',
           q!SET @param.modify('replace value of (/root)[1]
                                with concat((/root)[1], " added text")')!);
$X->sql_sp(TESTUDF, \$retvalue, ['<root>initial text</root>']);
push(@testres, $retvalue eq '<root>initial text added text</root>');

sql(<<SQLEND);
DROP FUNCTION olledb_testudf
IF EXISTS (SELECT * FROM sys.xml_schema_collections WHERE name = 'OlleSC')
   DROP XML SCHEMA COLLECTION OlleSC
SQLEND

$no_of_tests += 8;


$clr_enabled = sql_one(<<SQLEND, Win32::SqlServer::SCALAR);
SELECT value
FROM   sys.configurations
WHERE  name = 'clr enabled'
SQLEND

if ($clr_enabled) {
   create_the_udts($X, 'OlleComplexInteger', 'Olle.Point', 'OlleString',
                       'OlleStringMax');
   $X->{BinaryAsStr} = 'x';
   blurb('UDT1, bin0x');
   create_udf($X, '[Olle.Point]', '@p [Olle.Point]', '@p', 'SET @p.Transpose()');
   $X->sql_sp(TESTUDF, \$retvalue, ['0x01800000098000000480000005']);
   push(@testres, $retvalue eq      '0x01800000048000000580000009');

   $X->{BinaryAsStr} = 0;
   blurb('UDT3, binary as binary');
   create_udf($X, 'OlleString', '@s OlleString', 'upper(@s.ToString())');
   $X->sql_sp(TESTUDF, \$retvalue, [pack('H*', '0005000000657373694E')]);
   push(@testres, $retvalue eq pack('H*', '0005000000455353494E'));

   $no_of_tests += 2;
}

# From here it's only SQL 2008 and up.
goto finally if $sqlver < 10;

blurb('hierarchyid');
create_udf($X, 'hierarchyid', '@s hierarchyid', '@s.GetAncestor(1)');
$X->sql_sp(TESTUDF, \$retvalue, [pack('H*', '9D783FDC0C80')]);
push(@testres, $retvalue eq pack('H*', '9D783E'));

blurb('geometry');
create_udf($X, 'geometry', '@g geometry', '@g.STConvexHull()');
$X->sql_sp(TESTUDF, \$retvalue, [pack('H*', '000000000114000000000000F03F000000000000F03F00000000000000400000000000001040')]);
push(@testres, $retvalue eq pack('H*', '00000000011400000000000000400000000000001040000000000000F03F000000000000F03F'));

blurb('geography');
create_udf($X, 'geography', '@g geography', '@g.STPointN(1)');
# geography::STLineFromText('LINESTRING(47.656 -122.360, 47.656 -122.343)', 4326);
$X->sql_sp(TESTUDF, \$retvalue, [pack('H*', 'E610000001148716D9CEF7D34740D7A3703D0A975EC08716D9CEF7D34740CBA145B6F3955EC0')]);
push(@testres, $retvalue eq pack('H*', 'E6100000010C8716D9CEF7D34740D7A3703D0A975EC0'));


blurb('date');
$X->{DatetimeOption} = DATETIME_ISO;
create_udf($X, 'date', '', "'2007-10-11'");
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq '2007-10-11');

blurb('date, hash');
$X->{DatetimeOption} = DATETIME_HASH;
$X->sql_sp(TESTUDF, \$retvalue);
if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
   push(@testres, datehash_compare($retvalue,
                                   {Year => 2007, Month => 10,  Day => 11}));
}
else {
   push(@testres, $retvalue eq '2007-10-11');
}
undef $retvalue;

blurb('time');
$X->{DatetimeOption} = DATETIME_ISO;
create_udf($X, 'time(0)', '', "'12:23:59'");
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq '12:23:59');

blurb('time, hash');
$X->{DatetimeOption} = DATETIME_HASH;
$X->sql_sp(TESTUDF, \$retvalue);
if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
   push(@testres, datehash_compare($retvalue,
                                   {Hour => 12, Minute => 23, Second => 59,
                                   Fraction => 0}));
}
else {
   push(@testres, $retvalue eq '12:23:59');
}
undef $retvalue;

blurb('datetime2');
$X->{DatetimeOption} = DATETIME_ISO;
create_udf($X, 'datetime2(2)', '', "'1066-04-12 12:23:59.45'");
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq '1066-04-12 12:23:59.45');

blurb('datetime2, hash');
$X->{DatetimeOption} = DATETIME_HASH;
$X->sql_sp(TESTUDF, \$retvalue);
if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
   push(@testres, datehash_compare($retvalue,
                                   {Year => 1066, Month => 4, Day => 12,
                                   Hour => 12, Minute => 23, Second => 59,
                                   Fraction => 450}));
}
else {
   push(@testres, $retvalue eq '1066-04-12 12:23:59.45');
}
undef $retvalue;

blurb('datetimeoffset');
$X->{DatetimeOption} = DATETIME_ISO;
create_udf($X, 'datetimeoffset', '', "'1632-11-06 12:23:59.1239892 +01:00'");
$X->sql_sp(TESTUDF, \$retvalue);
push(@testres, $retvalue eq '1632-11-06 12:23:59.1239892 +01:00');

blurb('datetimeoffset, hash');
$X->{DatetimeOption} = DATETIME_HASH;
$X->sql_sp(TESTUDF, \$retvalue);
if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
   push(@testres, datehash_compare($retvalue,
                                   {Year => 1632, Month => 11, Day => 6,
                                   Hour => 12, Minute => 23, Second => 59,
                                   Fraction => 123.9892, TZHour => 1,
                                   TZMinute => 0}));
}
else {
   push(@testres, $retvalue eq '1632-11-06 12:23:59.1239892 +01:00');
}
undef $retvalue;

$no_of_tests += 11;


# Here follows many tests with datetimeoffset and tzoffset to make sure
# that we always apply the offset correctly.
if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
   $X->{DatetimeOption} = DATETIME_ISO;
   blurb('datetimeoffset, tzoffset1');
   $X->{TZOffset} = '-02:30';
   create_udf($X, 'datetimeoffset(0)', '', "'1632-11-06 12:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1632-11-06 08:53:00'));

   blurb('datetimeoffset, tzoffset2');
   $X->{TZOffset} = '+06:30';
   create_udf($X, 'datetimeoffset(0)', '', "'1632-11-06 12:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1632-11-06 17:53:00'));

   blurb('datetimeoffset, tzoffset3');
   $X->{TZOffset} = '+05:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1632-11-06 23:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1632-11-07 03:23:00'));

   blurb('datetimeoffset, tzoffset4');
   $X->{TZOffset} = '-05:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1632-11-06 01:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1632-11-05 19:23:00'));

   blurb('datetimeoffset, tzoffset5');
   $X->{TZOffset} = '-13:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1632-11-06 00:23:00 +12:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1632-11-04 23:23:00'));

   blurb('datetimeoffset, tzoffset6');
   $X->{TZOffset} = '+13:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1632-11-06 23:12:00 -12:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1632-11-08 00:12:00'));


   blurb('datetimeoffset, tzoffset7');
   $X->{TZOffset} = '-02:30';
   create_udf($X, 'datetimeoffset(0)', '', "'1958-11-06 12:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1958-11-06 08:53:00'));

   blurb('datetimeoffset, tzoffset8');
   $X->{TZOffset} = '+06:30';
   create_udf($X, 'datetimeoffset(0)', '', "'1958-11-06 12:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1958-11-06 17:53:00'));

   blurb('datetimeoffset, tzoffset9');
   $X->{TZOffset} = '+05:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1958-11-06 23:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1958-11-07 03:23:00'));

   blurb('datetimeoffset, tzoffset10');
   $X->{TZOffset} = '-05:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1958-11-06 01:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1958-11-05 19:23:00'));

   blurb('datetimeoffset, tzoffset11');
   $X->{TZOffset} = '-13:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1958-11-06 00:23:00 +12:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1958-11-04 23:23:00'));

   blurb('datetimeoffset, tzoffset12');
   $X->{TZOffset} = '+13:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1958-11-06 23:12:00 -12:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1958-11-08 00:12:00'));


   blurb('datetimeoffset, tzoffset13');
   $X->{TZOffset} = '-02:30';
   create_udf($X, 'datetimeoffset(0)', '', "'1899-12-30 12:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1899-12-30 08:53:00'));

   blurb('datetimeoffset, tzoffset14');
   $X->{TZOffset} = '+06:30';
   create_udf($X, 'datetimeoffset(0)', '', "'1899-12-30 12:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1899-12-30 17:53:00'));

   blurb('datetimeoffset, tzoffset15');
   $X->{TZOffset} = '+05:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1899-12-30 23:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1899-12-31 03:23:00'));

   blurb('datetimeoffset, tzoffset16');
   $X->{TZOffset} = '-05:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1899-12-30 01:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1899-12-29 19:23:00'));

   blurb('datetimeoffset, tzoffset17');
   $X->{TZOffset} = '-13:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1899-12-30 00:23:00 +12:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1899-12-28 23:23:00'));

   blurb('datetimeoffset, tzoffset18');
   $X->{TZOffset} = '+13:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1899-12-30 23:12:00 -12:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1900-01-01 00:12:00'));


   blurb('datetimeoffset, tzoffset19');
   $X->{TZOffset} = '-02:30';
   create_udf($X, 'datetimeoffset(0)', '', "'1899-12-29 12:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1899-12-29 08:53:00'));

   blurb('datetimeoffset, tzoffset20');
   $X->{TZOffset} = '+06:30';
   create_udf($X, 'datetimeoffset(0)', '', "'1899-12-29 12:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1899-12-29 17:53:00'));

   blurb('datetimeoffset, tzoffset21');
   $X->{TZOffset} = '+05:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1899-12-29 23:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1899-12-30 03:23:00'));

   blurb('datetimeoffset, tzoffset22');
   $X->{TZOffset} = '-05:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1899-12-29 01:23:00 +01:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1899-12-28 19:23:00'));

   blurb('datetimeoffset, tzoffset23');
   $X->{TZOffset} = '-13:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1899-12-29 00:23:00 +12:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1899-12-27 23:23:00'));

   blurb('datetimeoffset, tzoffset24');
   $X->{TZOffset} = '+13:00';
   create_udf($X, 'datetimeoffset(0)', '', "'1899-12-29 23:12:00 -12:00'");
   $X->sql_sp(TESTUDF, \$retvalue);
   push(@testres, ($retvalue eq '1899-12-31 00:12:00'));

   $no_of_tests += 24;
}

if ($clr_enabled) {
      blurb('UDTLarge, binary as binary');
      create_udf($X, 'OlleStringMax', '@s OlleStringMax',
                     'reverse(convert(nvarchar(MAX), @s))');
      $X->sql_sp(TESTUDF, \$retvalue,
                [pack('H*', '00C8320000' . ('52C3A46B736DC3B67267C3A573' x 1000))]);
      push(@testres, $retvalue eq pack('H*', '00C8320000' .
                                             ('73C3A56772C3B66D736BC3A452' x 1000)));
     $no_of_tests += 1;
}


finally:

if ($sqlver >= 8) {
   my $testudf = TESTUDF;
   $X->sql(<<SQLEND);
   IF EXISTS (SELECT * FROM sysobjects WHERE name = '$testudf')
      DROP FUNCTION $testudf
SQLEND
}

delete_the_udts($X) if $clr_enabled;

my $ix = 1;
my $blurb = "";
print "1..$no_of_tests\n";
foreach my $result (@testres) {
   if ($result =~ /^#--/) {
      print $result if $verbose;
      $blurb = $result;
   }
   elsif ($result == 1) {
      printf "ok %d\n", $ix++;
   }
   else {
      printf "not ok %d\n$blurb", $ix++;
   }
}

exit;
