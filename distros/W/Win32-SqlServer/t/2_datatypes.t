#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/t/2_datatypes.t 35    16-07-15 21:34 Sommar $
#
# This test script tests using sql_sp and sql_insert in all possible
# ways and with testing use of all datatypes.
#
# $History: 2_datatypes.t $
# 
# *****************  Version 35  *****************
# User: Sommar       Date: 16-07-15   Time: 21:34
# Updated in $/Perl/OlleDB/t
# Adjusted some more tests for SQL 2016.
# 
# *****************  Version 34  *****************
# User: Sommar       Date: 16-07-12   Time: 0:00
# Updated in $/Perl/OlleDB/t
# Changes to avoid warnings about sprintf with Perl 5.24.
# 
# *****************  Version 33  *****************
# User: Sommar       Date: 15-05-24   Time: 22:28
# Updated in $/Perl/OlleDB/t
# Ripped out code specific for SQL 6.5. Changed condition for when to
# test 64-bit integers.
# 
# *****************  Version 32  *****************
# User: Sommar       Date: 12-08-18   Time: 21:33
# Updated in $/Perl/OlleDB/t
# Save all output files for better troubleshooting. Fix the XML test so
# that it does not fail on servers with different code pages.
# 
# *****************  Version 31  *****************
# User: Sommar       Date: 12-07-19   Time: 0:19
# Updated in $/Perl/OlleDB/t
# If server has an SC collation, run in our own database and not tempdb,
# since text & co does not work with SC. Use different functions for
# testing geometry to avoid fuzziness problems. Egads! There was a bug in
# check_data so that "not ok" was not printed in case of an error.
#
# *****************  Version 30  *****************
# User: Sommar       Date: 11-08-07   Time: 23:33
# Updated in $/Perl/OlleDB/t
# Added tests for empty strings with sql_variant. Suppot different data
# files for spatial data types depending on the SQL Server version.
#
# *****************  Version 29  *****************
# User: Sommar       Date: 09-08-16   Time: 13:58
# Updated in $/Perl/OlleDB/t
# Modified test för bit to handle empty string as input.
#
# *****************  Version 28  *****************
# User: Sommar       Date: 08-05-04   Time: 22:27
# Updated in $/Perl/OlleDB/t
# Incorrect skip of output parameters for the spatial data types.
#
# *****************  Version 27  *****************
# User: Sommar       Date: 08-04-28   Time: 23:17
# Updated in $/Perl/OlleDB/t
# Use precise functions for the geography type.
#
# *****************  Version 26  *****************
# User: Sommar       Date: 08-02-10   Time: 17:15
# Updated in $/Perl/OlleDB/t
# Added test for rowversion-
#
# *****************  Version 25  *****************
# User: Sommar       Date: 07-11-20   Time: 21:35
# Updated in $/Perl/OlleDB/t
# Added tests for the spatial data types.
#
# *****************  Version 24  *****************
# User: Sommar       Date: 07-11-12   Time: 23:03
# Updated in $/Perl/OlleDB/t
# Modified some tests for date/time and sql_variant, including tests when
# hash is complete.
#
# *****************  Version 23  *****************
# User: Sommar       Date: 07-11-11   Time: 20:17
# Updated in $/Perl/OlleDB/t
# Test some end of months.
#
# *****************  Version 22  *****************
# User: Sommar       Date: 07-11-10   Time: 23:50
# Updated in $/Perl/OlleDB/t
# Changed the year for one of the smalldatetime tests to test the upper
# limit.
#
# *****************  Version 21  *****************
# User: Sommar       Date: 07-11-10   Time: 20:11
# Updated in $/Perl/OlleDB/t
# Added tests for the new date/time data types.
#
# *****************  Version 20  *****************
# User: Sommar       Date: 07-09-16   Time: 22:43
# Updated in $/Perl/OlleDB/t
# Added tests for large UDTs and hierarchyid. Modified the tests for
# varcharmax somewhat.
#
# *****************  Version 19  *****************
# User: Sommar       Date: 07-09-09   Time: 0:10
# Updated in $/Perl/OlleDB/t
# Correct checks for the provider version.
#
# *****************  Version 18  *****************
# User: Sommar       Date: 07-06-18   Time: 0:10
# Updated in $/Perl/OlleDB/t
# Tests added/modified for bigint on x64.
#
# *****************  Version 17  *****************
# User: Sommar       Date: 05-11-26   Time: 23:47
# Updated in $/Perl/OlleDB/t
# Renamed the module from MSSQL::OlleDB to Win32::SqlServer.
#
# *****************  Version 16  *****************
# User: Sommar       Date: 05-11-06   Time: 20:49
# Updated in $/Perl/OlleDB/t
# Added test for datetime format YYYY-MM-DDZ.
#
# *****************  Version 15  *****************
# User: Sommar       Date: 05-10-23   Time: 23:12
# Updated in $/Perl/OlleDB/t
# Added more tests for XML.
#
# *****************  Version 14  *****************
# User: Sommar       Date: 05-08-07   Time: 0:16
# Updated in $/Perl/OlleDB/t
# Modified the Unicode test to also include Unicode in parameter names.
#
# *****************  Version 13  *****************
# User: Sommar       Date: 05-07-25   Time: 0:39
# Updated in $/Perl/OlleDB/t
# Added clean-up code to leave nothing around.
#
# *****************  Version 12  *****************
# User: Sommar       Date: 05-07-20   Time: 22:42
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 11  *****************
# User: Sommar       Date: 05-07-18   Time: 1:00
# Updated in $/Perl/OlleDB/t
# Tests for untyped XML as well.
#
# *****************  Version 10  *****************
# User: Sommar       Date: 05-07-17   Time: 23:11
# Updated in $/Perl/OlleDB/t
# Tests for UDT added.
#
# *****************  Version 9  *****************
# User: Sommar       Date: 05-06-25   Time: 23:01
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 8  *****************
# User: Sommar       Date: 05-02-06   Time: 20:45
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 7  *****************
# User: Sommar       Date: 05-01-30   Time: 21:56
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 6  *****************
# User: Sommar       Date: 05-01-24   Time: 23:09
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 5  *****************
# User: Sommar       Date: 05-01-24   Time: 0:41
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 4  *****************
# User: Sommar       Date: 05-01-19   Time: 23:07
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 3  *****************
# User: Sommar       Date: 05-01-10   Time: 23:02
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 2  *****************
# User: Sommar       Date: 05-01-10   Time: 20:55
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 1  *****************
# User: Sommar       Date: 05-01-06   Time: 22:59
# Created in $/Perl/OlleDB/t
#
# *****************  Version 3  *****************
# User: Sommar       Date: 00-07-24   Time: 22:10
# Updated in $/Perl/MSSQL/Sqllib/t
# Changed nullif argument for bincol due to bug(?) in SQL 2000 Beta 2.
#
# *****************  Version 2  *****************
# User: Sommar       Date: 00-05-08   Time: 22:23
# Updated in $/Perl/MSSQL/Sqllib/t
# Enhanced test for text and image to use really big stuff.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 99-01-30   Time: 16:36
# Created in $/Perl/MSSQL/sqllib/t
#---------------------------------------------------------------------

use strict;
use IO::File;
use English;
use Config;

use vars qw($sqlver $x86 @tblcols $no_of_tests @testres %tbl
            %expectpar %expectcol %expectfile %test %filetest %comment);


sub blurb{
    push(@testres, "#------ Testing @_ ------");
    print "#------ Testing @_ ------\n";
}

use Win32::SqlServer qw(:DEFAULT :consts);
use Filehandle;
use File::Basename qw(dirname);

require &dirname($0) . '\testsqllogin.pl';
require '..\helpers\assemblies.pl';

sub clear_test_data {
   @tblcols = %tbl = %expectpar = %expectcol = %expectfile =
   %test = %filetest = %comment = ();
}

sub drop_test_objects {
    my ($type) = @_;
    sql("IF object_id('$type') IS NOT NULL DROP TABLE $type");
    sql("IF object_id('${type}_sp') IS NOT NULL DROP PROCEDURE ${type}_sp");
}

sub create_integer {
   drop_test_objects('integer');

   sql(<<SQLEND);
      CREATE TABLE integer (intcol      int       NULL,
                           smallintcol  smallint  NULL,
                           tinyintcol   tinyint   NULL,
                           floatcol     float     NULL,
                           realcol      real      NULL,
                           bitcol       bit       NOT NULL)
SQLEND

   @tblcols = qw(intcol smallintcol tinyintcol floatcol realcol bitcol);

   sql(<<SQLEND);
      CREATE TRIGGER integer_tri ON integer FOR INSERT AS
      UPDATE integer
      SET    intcol      = intcol - 4711,
             smallintcol = smallintcol - 4711,
             tinyintcol  = tinyintcol - 47,
             floatcol    = floatcol - 4711,
             realcol     = realcol  - 4711,
             bitcol      = 1 - bitcol
SQLEND

   sql(<<'SQLEND');
   CREATE PROCEDURE integer_sp
                    @intcol       int           OUTPUT,
                    @smallintcol  smallint      OUTPUT,
                    @tinyintcol   tinyint       OUTPUT,
                    @floatcol     float         OUTPUT,
                    @realcol      real          OUTPUT,
                    @bitcol       bit           OUTPUT AS

   DELETE integer

   INSERT integer (intcol, smallintcol, tinyintcol, floatcol, realcol, bitcol)
      VALUES (@intcol, @smallintcol, @tinyintcol, @floatcol, @realcol,
              isnull(@bitcol, 0))

   SELECT @intcol       = -2 * @intcol,
          @smallintcol  = -2 * @smallintcol,
          @tinyintcol   =  2 * @tinyintcol,
          @floatcol     = -2 * @floatcol,
          @realcol      = -2 * @realcol,
          @bitcol       =  1 - @bitcol

   SELECT intcol, smallintcol, tinyintcol, floatcol, realcol, bitcol
   FROM   integer
SQLEND
}

sub create_character {
   drop_test_objects('character');

   sql(<<SQLEND);
      CREATE TABLE character(charcol      char(20)     NULL,
                             varcharcol   varchar(20)  NULL,
                             varcharcol2  varchar(20)  NOT NULL,
                             textcol      text         NULL);
SQLEND

   @tblcols = qw(charcol varcharcol varcharcol2 textcol);

   sql(<<SQLEND);
      CREATE TRIGGER character_tri ON character FOR INSERT AS
      UPDATE character
      SET    charcol     = reverse(charcol),
             varcharcol  = reverse(varcharcol),
             varcharcol2 = reverse(varcharcol2)
SQLEND

   sql(<<'SQLEND');
   CREATE PROCEDURE character_sp
                    @charcol     char(20)    OUTPUT,
                    @varcharcol  varchar(20) OUTPUT,
                    @varcharcol2 varchar(20) OUTPUT,
                    @textcol     text  AS

   DELETE character

   INSERT character(charcol, varcharcol, varcharcol2, textcol)
      VALUES (@charcol, @varcharcol, @varcharcol2, @textcol)

   SELECT @charcol     = upper(@charcol),
          @varcharcol  = upper(@varcharcol),
          @varcharcol2 = upper(@varcharcol2)

   SELECT charcol, varcharcol, varcharcol2, textcol
   FROM   character
SQLEND
}

sub create_binary {
   drop_test_objects('binary');

   sql(<<SQLEND);
      CREATE TABLE binary(bincol      binary(20)    NULL,
                          varbincol   varbinary(20) NULL,
                          tstamp      timestamp     NOT NULL,
                          imagecol    image         NULL);
SQLEND

   @tblcols = qw(bincol varbincol tstamp imagecol);

   sql(<<SQLEND);
      CREATE TRIGGER binary_tri ON binary FOR INSERT AS
      UPDATE binary
      SET    bincol     = convert(binary(20), reverse(bincol)),
             varbincol  = convert(varbinary(20), reverse(varbincol))
SQLEND

   sql(<<'SQLEND');
   CREATE PROCEDURE binary_sp
                    @bincol     binary(20)    OUTPUT,
                    @varbincol  varbinary(20) OUTPUT,
                    @tstamp     timestamp     OUTPUT,
                    @imagecol   image  AS

   DELETE binary

   INSERT binary(bincol, varbincol, imagecol)
      VALUES (@bincol, @varbincol, @imagecol)

   SELECT @bincol     = substring(@bincol, 1, 4) + @bincol,
          @varbincol  = @varbincol + @varbincol,
          @tstamp     = substring(@tstamp, 5, 4) + substring(@tstamp, 1, 4)

   SELECT bincol, varbincol, tstamp = @tstamp, imagecol
   FROM   binary
SQLEND
}

sub create_rowversion {
# To test that we handle the name rowversion correctly. The slask thing is
# only there to make the test scheme work in general.
   drop_test_objects('rowversion');

   sql(<<SQLEND);
      CREATE TABLE rowversion(slask     int        NOT NULL,
                              tstamp    rowversion NOT NULL);
SQLEND

   sql(<<SQLEND);
      CREATE TRIGGER rowversion_tri ON rowversion FOR INSERT AS
      UPDATE rowversion
      SET    slask = slask - 10
SQLEND


   @tblcols = qw(slask tstamp);

   sql(<<'SQLEND');
   CREATE PROCEDURE rowversion_sp @slask int OUTPUT,
                                  @tstamp  rowversion  OUTPUT AS

   DELETE rowversion

   INSERT rowversion(slask) VALUES(@slask)

   SELECT @slask = @slask + 10,
          @tstamp = substring(@tstamp, 5, 4) + substring(@tstamp, 1, 4)

   SELECT slask, tstamp = @tstamp FROM rowversion
SQLEND
}


sub create_decimal {
   drop_test_objects('decimal');

   sql(<<SQLEND);
      CREATE TABLE decimal(deccol       decimal(24,6) NULL,
                           numcol       numeric(12,2) NULL,
                           moneycol     money         NULL,
                           dimecol      smallmoney    NULL)
SQLEND

   @tblcols = qw(deccol numcol moneycol dimecol);

   sql(<<SQLEND);
      CREATE TRIGGER decimal_tri ON decimal FOR INSERT AS
      UPDATE decimal
      SET    deccol      = deccol   - 12345678,
             numcol      = numcol   - 12345678,
             moneycol    = moneycol - 12345678,
             dimecol     = dimecol  - 123456
SQLEND

   sql(<<'SQLEND');
   CREATE PROCEDURE decimal_sp
                    @deccol       decimal(24,6) OUTPUT,
                    @numcol       numeric(12,2) OUTPUT,
                    @moneycol     money         OUTPUT,
                    @dimecol      smallmoney    OUTPUT AS

   DELETE decimal

   INSERT decimal(deccol, numcol, moneycol, dimecol)
      VALUES (@deccol, @numcol, @moneycol, @dimecol)

   SELECT @deccol   = -2 * @deccol,
          @numcol   = -1 * @numcol / 2,
          @moneycol = -2 * @moneycol,
          @dimecol  = -1 * @dimecol / 2

   SELECT deccol, numcol, moneycol, dimecol
   FROM   decimal
SQLEND
}

sub create_datetime {
   drop_test_objects('datetime');

   sql(<<SQLEND);
      CREATE TABLE datetime(datetimecol   datetime      NULL,
                            smalldatecol  smalldatetime NULL)
SQLEND

   @tblcols = qw(datetimecol smalldatecol);

   sql(<<SQLEND);
      CREATE TRIGGER datetime_tri ON datetime FOR INSERT AS
      UPDATE datetime
      SET    datetimecol  = dateadd(DAY, 17, datetimecol),
             smalldatecol = dateadd(MONTH, 3, smalldatecol)
SQLEND

   sql(<<'SQLEND');
   CREATE PROCEDURE datetime_sp
                    @datetimecol  datetime      OUTPUT,
                    @smalldatecol smalldatetime OUTPUT AS

   DELETE datetime

   INSERT datetime(datetimecol, smalldatecol)
      VALUES (@datetimecol, @smalldatecol)

   SELECT @datetimecol   = dateadd(HOUR,    4, @datetimecol),
          @smalldatecol  = dateadd(MINUTE, 14, @smalldatecol)

   SELECT datetimecol, smalldatecol
   FROM   datetime
SQLEND
}

sub create_newdatetime {
   drop_test_objects('newdatetime');

   sql(<<SQLEND);
      CREATE TABLE newdatetime(datecol       date              NULL,
                               time0col      time(0)           NULL,
                               time7col      time(7)           NULL,
                               datetime2col  datetime2(3)      NULL,
                               dtoffset1col  datetimeoffset(1) NULL,
                               dtoffset7col  datetimeoffset(7) NULL)
SQLEND

   @tblcols = qw(datecol time0col time7col datetime2col
                 dtoffset1col dtoffset7col);

   sql(<<SQLEND);
      CREATE TRIGGER newdatetime_tri ON newdatetime FOR INSERT AS
      UPDATE newdatetime
      SET    datecol      = dateadd(DAY, 17, datecol),
             time0col     = dateadd(HOUR, 1, time0col),
             time7col     = dateadd(NS,  600, time7col),
             datetime2col = dateadd(MS, 1, datetime2col),
             dtoffset1col = dateadd(HOUR, 3, dtoffset1col),
             dtoffset7col = switchoffset(dtoffset7col, '-04:30')
SQLEND

   sql(<<'SQLEND');
   CREATE PROCEDURE newdatetime_sp
                    @datecol      date              OUTPUT,
                    @time0col     time(0)           OUTPUT,
                    @time7col     time(7)           OUTPUT,
                    @datetime2col datetime2(3)      OUTPUT,
                    @dtoffset1col datetimeoffset(1) OUTPUT,
                    @dtoffset7col datetimeoffset(7) OUTPUT AS

   DELETE newdatetime

   INSERT newdatetime(datecol, time0col, time7col, datetime2col,
                      dtoffset1col, dtoffset7col)
      VALUES (@datecol, @time0col, @time7col, @datetime2col,
              @dtoffset1col, @dtoffset7col)

   SELECT @datecol       = dateadd(YEAR, 5, @datecol),
          @time0col      = dateadd(MINUTE, 14, @time0col),
          @time7col      = dateadd(MCS, 230, @time7col),
          @datetime2col  = dateadd(DAY, 2, @datetime2col),
          @dtoffset1col  = dateadd(MINUTE, 30, @dtoffset1col),
          @dtoffset7col  = switchoffset(@dtoffset7col, '+08:00');

   SELECT datecol, time0col, time7col, datetime2col,
          dtoffset1col, dtoffset7col
   FROM   newdatetime
SQLEND
}

sub create_guid {
   drop_test_objects('guid');

   sql(<<SQLEND);
      CREATE TABLE guid(guidcol    uniqueidentifier NULL,
                        nullbitcol bit              NULL)
SQLEND

   @tblcols = qw(guidcol nullbitcol);

   sql(<<SQLEND);
      CREATE TRIGGER guid_tri ON guid FOR INSERT AS
      UPDATE guid
      SET    guidcol    = convert(uniqueidentifier,
                            replace(convert(char(36), guidcol), 'F', '0')),
             nullbitcol = 1 - nullbitcol
SQLEND

   sql(<<'SQLEND');
   CREATE PROCEDURE guid_sp
                    @guidcol     uniqueidentifier OUTPUT,
                    @nullbitcol  bit OUTPUT AS

   DELETE guid

   INSERT guid(guidcol, nullbitcol)
      VALUES (@guidcol, @nullbitcol)

   SELECT @guidcol    = convert(uniqueidentifier,
                            replace(convert(char(36), @guidcol), 'F', 'A')),
          @nullbitcol = 1 - @nullbitcol

   SELECT guidcol, nullbitcol
   FROM   guid
SQLEND
}

sub create_unicode {
   drop_test_objects('unicode');

   sql(<<SQLEND);
      CREATE TABLE unicode(ncharcol             nchar(20)     NULL,
                           \x{0144}varcharcol   nvarchar(20)  NULL,
                           nchärcöl2            nchar(20)     NOT NULL,
                           ntextcol             ntext         NULL);
SQLEND

   @tblcols = ("ncharcol", "\x{0144}varcharcol", "nchärcöl2", "ntextcol");

   sql(<<SQLEND);
      CREATE TRIGGER unicode_tri ON unicode FOR INSERT AS
      UPDATE unicode
      SET    ncharcol     = reverse(ncharcol),
             \x{0144}varcharcol  = reverse(\x{0144}varcharcol),
             nchärcöl2    = reverse(nchärcöl2)
SQLEND

   sql(<<SQLEND);
   CREATE PROCEDURE unicode_sp
                    \@ncharcol     nchar(20)    OUTPUT,
                    \@\x{0144}varcharcol  nvarchar(20) OUTPUT,
                    \@nchärcöl2    nchar(20)    OUTPUT,
                    \@ntextcol     ntext  AS

   DELETE unicode

   INSERT unicode(ncharcol, \x{0144}varcharcol, nchärcöl2, ntextcol)
      VALUES (\@ncharcol, \@\x{0144}varcharcol, \@nchärcöl2, \@ntextcol)

   SELECT \@ncharcol     = upper(\@ncharcol),
          \@\x{0144}varcharcol  = upper(\@\x{0144}varcharcol),
          \@nchärcöl2    = upper(\@nchärcöl2)

   SELECT ncharcol, \x{0144}varcharcol, nchärcöl2, ntextcol
   FROM   unicode
SQLEND
}

sub create_bigint {
   drop_test_objects('bigint');

   sql(<<SQLEND);
      CREATE TABLE bigint(bigintcol bigint NULL)
SQLEND

   @tblcols = qw(bigintcol);

   sql(<<SQLEND);
      CREATE TRIGGER bigint_tri ON bigint FOR INSERT AS
      UPDATE bigint
      SET    bigintcol = bigintcol   - 12345678
SQLEND

   sql(<<'SQLEND');
   CREATE PROCEDURE bigint_sp @bigintcol  bigint OUTPUT AS

   DELETE bigint

   INSERT bigint(bigintcol)
      VALUES (@bigintcol)

   SELECT @bigintcol = -2 * @bigintcol

   SELECT bigintcol
   FROM   bigint
SQLEND
}

sub create_sql_variant {
# sql_variant is a bit different from the rest...
   drop_test_objects('sql_variant');

   sql(<<SQLEND);
      CREATE TABLE sql_variant(varcol   sql_variant  NULL,
                               intype   sysname      NULL,
                               outtype  sysname      NOT NULL)
SQLEND

   @tblcols  = qw(varcol outtype intype);

   my $trigger = <<'SQLEND';
      CREATE TRIGGER sql_variant_tri ON sql_variant FOR INSERT AS
      DECLARE @var      sql_variant,
              @outtype  sysname
      UPDATE sql_variant
      SET    intype   = convert(sysname,
                                sql_variant_property(varcol, 'Basetype')),
             @outtype = outtype,
             @var     = varcol

      IF @outtype = 'bit'
         UPDATE sql_variant SET varcol = convert(bit, @var)
      ELSE IF @outtype = 'tinyint'
         UPDATE sql_variant SET varcol = convert(tinyint, @var) -
                                         convert(tinyint, 50)
      ELSE IF @outtype = 'smallint'
         UPDATE sql_variant SET varcol = convert(smallint, @var) -
                                         convert(smallint, 50)
      ELSE IF @outtype = 'int'
         UPDATE sql_variant SET varcol = convert(int, @var) -
                                         convert(int, 50)
      ELSE IF @outtype = 'bigint'
         UPDATE sql_variant SET varcol = convert(bigint, @var) -
                                         convert(bigint, 12345678)
      ELSE IF @outtype = 'real'
         UPDATE sql_variant SET varcol = convert(real, @var)  -
                                         convert(real, 50)
      ELSE IF @outtype = 'float'
         UPDATE sql_variant SET varcol = convert(float, @var) -
                                         convert(float, 50)
      ELSE IF @outtype = 'decimal'
         UPDATE sql_variant SET varcol = convert(decimal(24,6), @var) -
                                         convert(decimal(24,6), 12345678)
      ELSE IF @outtype = 'numeric'
         UPDATE sql_variant SET varcol = convert(numeric(12,2), @var) -
                                         convert(numeric(12,2), 12345678)
      ELSE IF @outtype = 'money'
         UPDATE sql_variant SET varcol = convert(money, @var) -
                                         convert(money, 12345678)
      ELSE IF @outtype = 'smallmoney'
         UPDATE sql_variant SET varcol = convert(smallmoney, @var) -
                                         convert(smallmoney, 12345)
      ELSE IF @outtype = 'datetime'
         UPDATE sql_variant SET varcol = dateadd(DAY, -50,
                                            convert(datetime, @var))
      ELSE IF @outtype = 'smalldatetime'
         UPDATE sql_variant SET varcol = dateadd(DAY, -50,
                                            convert(smalldatetime, @var))
      ELSE IF @outtype = 'char'
         UPDATE sql_variant SET varcol = reverse(convert(char(20), @var))
      ELSE IF @outtype = 'varchar'
         UPDATE sql_variant SET varcol = reverse(convert(varchar(20), @var))
      ELSE IF @outtype = 'nchar'
         UPDATE sql_variant SET varcol = reverse(convert(nchar(20), @var))
      ELSE IF @outtype = 'nvarchar'
         UPDATE sql_variant SET varcol = reverse(convert(nvarchar(20), @var))
      ELSE IF @outtype = 'binary'
         UPDATE sql_variant SET varcol = convert(binary(20), @var)
      ELSE IF @outtype = 'varbinary'
         UPDATE sql_variant SET varcol = convert(varbinary(20), @var)
      ELSE IF @outtype = 'uniqueidentifier'
         UPDATE sql_variant SET varcol = convert(uniqueidentifier, @var)
SQLEND

   if ($sqlver >= 10) {
      $trigger .= <<'SQLEND';
   ELSE IF @outtype = 'datetime2'
      UPDATE sql_variant SET varcol = dateadd(DAY, -50,
                                         convert(datetime2(4), @var))
   ELSE IF @outtype = 'date'
      UPDATE sql_variant SET varcol = dateadd(DAY, -50,  convert(date, @var))
   ELSE IF @outtype = 'time'
      UPDATE sql_variant SET varcol = dateadd(MCS, -50,  convert(time(5), @var))
   ELSE IF @outtype = 'datetimeoffset'
      UPDATE sql_variant SET varcol = dateadd(DAY, -50,
                                         convert(datetimeoffset(0), @var))
SQLEND
   }
   $trigger .= <<'SQLEND';
      ELSE
         UPDATE sql_variant SET varcol = NULL
SQLEND
   sql($trigger);

   my $proc = <<'SQLEND';
   CREATE PROCEDURE sql_variant_sp
                    @varcol       sql_variant     OUTPUT,
                    @outtype      sysname,
                    @intype       sysname  = NULL OUTPUT AS

   DELETE sql_variant

   INSERT sql_variant(varcol, outtype)
      VALUES (@varcol, @outtype)

   SELECT @intype = convert(sysname, sql_variant_property(@varcol, 'Basetype'))

   IF @outtype = 'bit'
      SELECT @varcol = convert(bit, @varcol)
   ELSE IF @outtype = 'tinyint'
      SELECT @varcol = convert(tinyint, 2) * convert(tinyint, @varcol)
   ELSE IF @outtype = 'smallint'
      SELECT @varcol = convert(smallint, -2) * convert(smallint, @varcol)
   ELSE IF @outtype = 'int'
      SELECT @varcol = convert(int, -2) * convert(int, @varcol)
   ELSE IF @outtype = 'bigint'
      SELECT @varcol = convert(bigint, -2) * convert(bigint, @varcol)
   ELSE IF @outtype = 'real'
      SELECT @varcol = convert(real, -2) * convert(real, @varcol)
   ELSE IF @outtype = 'float'
      SELECT @varcol = convert(float, -2) * convert(float, @varcol)
   ELSE IF @outtype = 'decimal'
      SELECT @varcol = convert(decimal(5,0), -2) * convert(decimal(24,6), @varcol)
   ELSE IF @outtype = 'numeric'
      SELECT @varcol = convert(numeric(5,0), -2) * convert(numeric(12,2), @varcol)
   ELSE IF @outtype = 'money'
      SELECT @varcol = convert(money, -2) * convert(money, @varcol)
   ELSE IF @outtype = 'smallmoney'
      SELECT @varcol = convert(smallmoney, -2) * convert(smallmoney, @varcol)
   ELSE IF @outtype = 'datetime'
      SELECT @varcol = dateadd(HOUR, 10, convert(datetime, @varcol))
   ELSE IF @outtype = 'smalldatetime'
      SELECT @varcol = dateadd(HOUR, 10, convert(smalldatetime, @varcol))
   ELSE IF @outtype = 'char'
      SELECT @varcol = upper(convert(char(20), @varcol))
   ELSE IF @outtype = 'varchar'
      SELECT @varcol = upper(convert(varchar(20), @varcol))
   ELSE IF @outtype = 'nchar'
      SELECT @varcol = upper(convert(nchar(20), @varcol))
   ELSE IF @outtype = 'nvarchar'
      SELECT @varcol = upper(convert(nvarchar(20), @varcol))
   ELSE IF @outtype = 'binary'
      SELECT @varcol = convert(binary(20), @varcol)
   ELSE IF @outtype = 'varbinary'
      SELECT @varcol = convert(varbinary(20), @varcol)
   ELSE IF @outtype = 'uniqueidentifier'
      SELECT @varcol = convert(uniqueidentifier, @varcol)
SQLEND

   if ($sqlver >= 10) {
      $proc .= <<'SQLEND';
   ELSE IF @outtype = 'datetime2'
      SELECT @varcol = dateadd(HOUR, 10, convert(datetime2(2), @varcol))
   ELSE IF @outtype = 'date'
      SELECT @varcol = dateadd(YEAR, 10, convert(date, @varcol))
   ELSE IF @outtype = 'time'
      SELECT @varcol = dateadd(HOUR, 10, convert(time(7), @varcol))
   ELSE IF @outtype = 'datetimeoffset'
      SELECT @varcol = dateadd(HOUR, 10, convert(datetimeoffset, @varcol))
SQLEND
   }

   $proc .= <<'SQLEND';
   ELSE
      SELECT @varcol = NULL

   SELECT varcol, intype, outtype = @outtype
   FROM   sql_variant
SQLEND
   sql($proc);
}

sub create_varcharmax {
   drop_test_objects('varcharmax');

   sql(<<SQLEND);
      CREATE TABLE varcharmax(varcharcol   varchar(MAX)   NULL,
                              nvarcharcol  nvarchar(MAX)  NOT NULL)
SQLEND

   @tblcols = qw(varcharcol nvarcharcol);

   sql(<<SQLEND);
      CREATE TRIGGER varcharmax_tri ON varcharmax FOR INSERT AS
      UPDATE varcharmax
      SET    varcharcol   = reverse(varcharcol),
             nvarcharcol  = reverse(nvarcharcol)
SQLEND

   sql(<<'SQLEND');
   CREATE PROCEDURE varcharmax_sp
                    @varcharcol  varchar(MAX)   OUTPUT,
                    @nvarcharcol nvarchar(MAX)  OUTPUT AS

   DELETE varcharmax

   INSERT varcharmax(varcharcol, nvarcharcol)
      VALUES (@varcharcol, @nvarcharcol)

   SELECT @varcharcol  = upper(@varcharcol) + 'UPPER',
          @nvarcharcol = upper(@nvarcharcol) + 'UPPER'

   SELECT varcharcol, nvarcharcol
   FROM   varcharmax
SQLEND
}

sub create_varbinmax {
   drop_test_objects('varbinmax');

   sql(<<SQLEND);
      CREATE TABLE varbinmax(varbincol  varbinary(MAX) NULL);
SQLEND

   @tblcols = qw(varbincol);

   sql(<<SQLEND);
      CREATE TRIGGER varbinmax_tri ON varbinmax FOR INSERT AS
      UPDATE varbinmax
      SET    varbincol  = convert(varbinary(MAX), reverse(varbincol))
SQLEND

   sql(<<'SQLEND');
   CREATE PROCEDURE varbinmax_sp
                    @varbincol   varbinary(MAX) OUTPUT AS

   DELETE varbinmax

   INSERT varbinmax(varbincol)
      VALUES (@varbincol)

   SELECT @varbincol = @varbincol + @varbincol

   SELECT varbincol
   FROM   varbinmax
SQLEND
}

sub create_UDT1 {
    my($X, $output) = @_;

    drop_test_objects('UDT1');

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

    create_the_udts($X, 'OlleComplexInteger', 'OllePoint', 'OlleString',
                        'OlleStringMax');

    sql(<<SQLEND);
       CREATE TABLE UDT1 (cmplxcol  OlleComplexInteger NULL,
                          pointcol  OllePoint          NULL,
                          stringcol OlleString         NULL,
                          xmlcol    xml(OlleSC)        NULL)
SQLEND

    @tblcols = qw(cmplxcol pointcol stringcol xmlcol);

    sql(<<SQLEND);
       CREATE TRIGGER UDT1_tri ON UDT1 FOR INSERT AS
       UPDATE UDT1
       SET    cmplxcol  = '(' + str(cmplxcol.Imaginary) + ',' +
                          str(cmplxcol.Real) + 'i)',
              pointcol  = ltrim(str(2*pointcol.X)) + ':' +
                          ltrim(str(2*pointcol.Y)) + ':' +
                          ltrim(str(2*pointcol.Z)),
              stringcol = reverse(stringcol.ToString())

       UPDATE UDT1
       SET    xmlcol.modify('replace value of (/root)[1]
                             with concat((/root)[1], " trigger text")')
       WHERE  xmlcol IS NOT NULL
SQLEND

   my $spcode = <<'SQLEND';
       CREATE PROCEDURE UDT1_sp @cmplxcol  OlleComplexInteger OUTPUT,
                                @pointcol  OllePoint          OUTPUT,
                                @stringcol OlleString         OUTPUT,
                                @xmlcol    xml(OlleSC)        OUTPUT AS

       DELETE UDT1

       INSERT UDT1 (cmplxcol, pointcol, stringcol, xmlcol)
          VALUES (@cmplxcol, @pointcol, @stringcol, @xmlcol)

       IF @cmplxcol IS NOT NULL
       BEGIN
          SET @cmplxcol.Real      = 2 * @cmplxcol.Real
          SET @cmplxcol.Imaginary = 2 * @cmplxcol.Imaginary
       END

       IF @pointcol IS NOT NULL
          SET @pointcol.Transpose()

       SELECT @stringcol = UPPER(@stringcol.ToString() + 'upper')

       IF @xmlcol IS NOT NULL
          SET @xmlcol.modify('replace value of (/root)[1]
                             with concat((/root)[1], " procedure text")')

       SELECT cmplxcol, pointcol, stringcol, xmlcol
       FROM   UDT1
SQLEND

    if (not $output) {
       $spcode =~ s/\bOUTPUT\b//g;
    }

    sql($spcode);
}

sub create_UDT2 {
    my($X, $output) = @_;

   drop_test_objects('UDT2');

   sql(<<SQLEND);
       CREATE TABLE UDT2 (cmplxcol  OlleComplexInteger NULL,
                          intcol    int                NULL,
                          stringcol OlleString         NULL)
SQLEND

    @tblcols = qw(cmplxcol intcol stringcol);

    sql(<<SQLEND);
       CREATE TRIGGER UDT2_tri ON UDT2 FOR INSERT AS
       UPDATE UDT2
       SET    cmplxcol  = '(' + str(cmplxcol.Imaginary) + ',' +
                          str(cmplxcol.Real) + 'i)',
              intcol    = 2*intcol,
              stringcol = reverse(stringcol.ToString())
SQLEND

   my $spcode = <<'SQLEND';
       CREATE PROCEDURE UDT2_sp @cmplxcol  OlleComplexInteger OUTPUT,
                                @intcol    int                OUTPUT,
                                @stringcol OlleString         OUTPUT AS

       DELETE UDT2

       INSERT UDT2 (cmplxcol, intcol, stringcol)
          VALUES (@cmplxcol, @intcol, @stringcol)

       IF @cmplxcol IS NOT NULL
       BEGIN
          SET @cmplxcol.Real      = 2 * @cmplxcol.Real
          SET @cmplxcol.Imaginary = 2 * @cmplxcol.Imaginary
       END

       SELECT @intcol    = @intcol + 91,
              @stringcol = UPPER(@stringcol.ToString())

       SELECT cmplxcol, intcol, stringcol
       FROM   UDT2
SQLEND

    if (not $output) {
       $spcode =~ s/\bOUTPUT\b//g;
    }

    sql($spcode);
}

sub create_UDT3 {
    my($X, $output) = @_;

    drop_test_objects('UDT3');

    sql(<<SQLEND);
       CREATE TABLE UDT3 (xmlcol    xml        NULL,
                          pointcol  OllePoint  NULL,
                          nollcol   float      NULL)
SQLEND

    @tblcols = qw(xmlcol pointcol nollcol);

    sql(<<SQLEND);
       CREATE TRIGGER UDT3_tri ON UDT3 FOR INSERT AS
       UPDATE UDT3
       SET    pointcol  = ltrim(str(2*pointcol.X)) + ':' +
                          ltrim(str(2*pointcol.Y)) + ':' +
                          ltrim(str(2*pointcol.Z)),
              nollcol   = nollcol + 19

       UPDATE UDT3
       SET    xmlcol.modify('replace value of (/TEST/text())[1]
                             with concat((/TEST/text())[1], " trigger text")')
       WHERE  xmlcol IS NOT NULL
SQLEND

   my $spcode = <<'SQLEND';
       CREATE PROCEDURE UDT3_sp @xmlcol    xml       OUTPUT,
                                @pointcol  OllePoint OUTPUT,
                                @nollcol   float     OUTPUT AS

       DELETE UDT3

       INSERT UDT3 (xmlcol, pointcol, nollcol)
          VALUES (@xmlcol, @pointcol, @nollcol)

       IF @xmlcol IS NOT NULL
          SET @xmlcol.modify('replace value of (/TEST/text())[1]
                             with concat((/TEST/text())[1], " procedure text")')

       IF @pointcol IS NOT NULL
          SET @pointcol.Transpose()

       SELECT @nollcol  = @nollcol - 9

       SELECT xmlcol, pointcol, nollcol
       FROM   UDT3
SQLEND

    if (not $output) {
       $spcode =~ s/\bOUTPUT\b//g;
    }

    sql($spcode);
}

sub create_hierarchy {
    my($X, $output) = @_;

    drop_test_objects('hierarchy');

    sql(<<SQLEND);
       CREATE TABLE hierarchy (hiercol hierarchyid   NULL)
SQLEND

    @tblcols = qw(hiercol );

    sql(<<SQLEND);
       CREATE TRIGGER hierarchy_tri ON hierarchy FOR INSERT AS
       UPDATE hierarchy
       SET    hiercol  = hiercol.GetDescendant(NULL, NULL)
SQLEND

   my $spcode = <<'SQLEND';
       CREATE PROCEDURE hierarchy_sp @hiercol hierarchyid OUTPUT AS

       DELETE hierarchy

       INSERT hierarchy (hiercol) VALUES (@hiercol)

       SELECT @hiercol = @hiercol.GetAncestor(1)

       SELECT hiercol FROM hierarchy
SQLEND

    if (not $output) {
       $spcode =~ s/\bOUTPUT\b//g;
    }

    sql($spcode);
}

sub create_UDTlarge {
    my($X, $output) = @_;

    drop_test_objects('UDTlarge');

    sql(<<SQLEND);
       CREATE TABLE UDTlarge (maxstringcol  OlleStringMax NULL)
SQLEND

    @tblcols = qw(maxstringcol);

    sql(<<SQLEND);
       CREATE TRIGGER UDTlarge_tri ON UDTlarge FOR INSERT AS
       UPDATE UDTlarge
       SET    maxstringcol = reverse(convert(nvarchar(MAX), maxstringcol))
SQLEND

   my $spcode = <<'SQLEND';
       CREATE PROCEDURE UDTlarge_sp @maxstringcol  OlleStringMax OUTPUT AS

       DELETE UDTlarge

       INSERT UDTlarge (maxstringcol)
          VALUES (@maxstringcol)

       SELECT @maxstringcol = upper(convert(nvarchar(MAX), @maxstringcol) +
                                    N'UPPER')

       SELECT maxstringcol
       FROM   UDTlarge
SQLEND

    if (not $output) {
       $spcode =~ s/\bOUTPUT\b//g;
    }

    sql($spcode);
}


sub create_spatial {
    my($X, $output) = @_;

    drop_test_objects('spatial');

    sql(<<SQLEND);
       CREATE TABLE spatial (geometrycol  geometry  NULL,
                             geographycol geography NULL)
SQLEND

    @tblcols = qw(geometrycol geographycol);

    sql(<<SQLEND);
       CREATE TRIGGER sptial_tri ON spatial FOR INSERT AS
       UPDATE spatial
       SET    geometrycol  = geometrycol.STEndPoint(),
              geographycol = geographycol.STStartPoint()
SQLEND

   my $spcode = <<'SQLEND';
       CREATE PROCEDURE spatial_sp @geometrycol  geometry OUTPUT,
                                   @geographycol geography OUTPUT AS

       DELETE spatial

       INSERT spatial (geometrycol, geographycol)
          VALUES (@geometrycol, @geographycol)

       SELECT @geometrycol = @geometrycol.STPointN(3),
              @geographycol = @geographycol.STPointN(2)

       SELECT geometrycol, geographycol
       FROM   spatial
SQLEND

    if (not $output) {
       $spcode =~ s/\bOUTPUT\b//g;
    }

    sql($spcode);
}



sub create_xmltest {
    my($X, $output) = @_;

    drop_test_objects('xmltest');

    sql(<<SQLEND);
    IF EXISTS (SELECT * FROM sys.xml_schema_collections WHERE name = 'Olles SC')
            DROP XML SCHEMA COLLECTION [Olles SC]
SQLEND

     sql(<<SQLEND);
CREATE XML SCHEMA COLLECTION [Olles SC] AS '
<schema xmlns="http://www.w3.org/2001/XMLSchema">
      <element name="TÄST" type="string"/>
</schema>
'
SQLEND


    sql(<<SQLEND);
       CREATE TABLE xmltest (xmlcol      xml             NULL,
                             xmlsccol    xml([Olles SC]) NULL,
                             nvarcol     nvarchar(MAX)   NULL,
                             nvarsccol   nvarchar(MAX)   NULL)
SQLEND

    @tblcols = qw(xmlcol xmlsccol nvarcol nvarsccol);

    sql(<<SQLEND);
       CREATE TRIGGER xmltest_tri ON xmltest FOR INSERT AS
       UPDATE xmltest
       SET    xmlcol    = (SELECT nvarcol FROM xmltest FOR XML AUTO),
              xmlsccol  = (SELECT 1 AS Tag, NULL as Parent,
                                  nvarsccol AS [TÄST!1]
                           FROM   xmltest
                           FOR    XML EXPLICIT),
              nvarcol   = nullif(convert(nvarchar(MAX), xmlcol), ''),
              nvarsccol = xmlsccol.value(N'/TÄST[1]', 'nvarchar(MAX)')
SQLEND

   my $spcode = <<'SQLEND';
       CREATE PROCEDURE xmltest_sp @xmlcol    xml             OUTPUT,
                                   @xmlsccol  xml([Olles SC]) OUTPUT,
                                   @nvarcol   nvarchar(MAX)   OUTPUT,
                                   @nvarsccol nvarchar(MAX)   OUTPUT AS

       DECLARE @tmp   nvarchar(MAX),
               @tmpsc nvarchar(MAX)

       DELETE xmltest

       INSERT xmltest (xmlcol, xmlsccol, nvarcol, nvarsccol)
          VALUES (@xmlcol, @xmlsccol, @nvarcol, @nvarsccol)

       SELECT @tmp = @nvarcol, @tmpsc = @nvarsccol

       SELECT @nvarcol = @xmlcol.value(N'/*[1]', 'nvarchar(MAX)'),
              @nvarsccol = nullif(convert(nvarchar(MAX), @xmlsccol), '')

       SELECT @xmlcol = (SELECT lower(@tmp) AS Lågland
                         FOR XML RAW, ELEMENTS),
              @xmlsccol = (SELECT 1 AS Tag, NULL as Parent,
                                  upper(@tmpsc) AS [TÄST!1]
                           FOR    XML EXPLICIT)

       SELECT xmlcol, xmlsccol, nvarcol, nvarsccol
       FROM   xmltest
SQLEND

    if (not $output) {
       $spcode =~ s/\bOUTPUT\b//g;
    }

    sql($spcode);
}



#------------------------------------------------------------------------

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


sub ISO_to_regional {
  # Help routine to convert ISO date to regional.
  my ($date) = @_;
  $date =~ s/(\s*[-+]\s*\d+\s*:\s*\d+\s*)$//;
  my $tz = $1;
  open DH, ">datehelperin.txt";
  print DH "$date\n";
  close DH;
  system("../helpers/datetesthelper");
  open DH, "datehelperout.txt";
  my $line = <DH>;
  close DH;
  my $ret = (split(/\s*£\s*/, $line))[0];
  $ret =~ s/^\s*|\s*$//g;
  $ret .= $tz if defined $tz;
  return $ret;
}


sub fixfilename {
   my($testcase) = @_;
   $testcase =~ s/\W//g;
   return "$testcase.log";
}

sub open_testfile {
   my ($filename) = @_;
   open(TFILE, '>:utf8', $filename);
   return \*TFILE;
}

sub get_testfile {
   my ($filename) = @_;
   open(TFILE, '<:utf8', $filename);
   my $testfile = join('', <TFILE>);
   close TFILE;
   $testfile =~ s!\s*(\*/)?\ngo\s*$!\n!;
   return $testfile;
}

sub check_data {
   my ($logfile, $result, $params, $paramsbyref) = @_;

   my ($ix, $col, $valref, %filevalues);

   my $testfile;

   if ($logfile) {
      $testfile = get_testfile($logfile);
      if (not $params) {
         $testfile =~ /\(([^\)]+)\)/;
         my $collist = $1;
         my @collist = split(/\s*,\s*/, $collist);
         unshift (@collist, undef);   # To make @collist 1-based.
         $testfile =~ s/\@P(\d+)\s*=/\@$collist[$1] =/g;
      }
   }

   foreach my $ix (0..$#tblcols) {
      my $col = $tblcols[$ix];
      next if not defined $col;

      my $valref;

      if (ref $params) {
         if (ref $params eq "ARRAY") {
            $valref = ($paramsbyref ? $$params[$ix] : \$$params[$ix]);
         }
         else {
            my $par = '@' . $col;
            $valref = ($paramsbyref ? $$params{$par} : \$$params{$par});
         }
      }
      else {
         $valref = undef;
      }

      # This is to avoid warning about "redudant" arguments in sprinf:
      my ($resulttest, $paramtest);
      if ($test{$col} =~ /%s.*%s/) {
          $resulttest = sprintf($test{$col}, '$$result{$col}', '$expectcol{$col}');
          $paramtest  = sprintf($test{$col}, '$$valref', '$expectpar{$col}');
      }
      else {
          $resulttest = sprintf($test{$col}, '$$result{$col}');
          $paramtest  = sprintf($test{$col}, '$$valref');
      }
      my $comment    = defined $comment{$col} ? $comment{$col} : "";

      push(@testres,
           eval($resulttest) ? "ok %d" :
           "not ok %d # result '$col': <$$result{$col}>, expected: <$expectcol{$col}>" .
           "   $comment $@");
      if ($params and exists $expectpar{$col}) {
         push(@testres,
              eval($paramtest) ? "ok %d" :
              "not ok %d # param '$col': <$$valref>, expected: <$expectpar{$col}>  " .
              "    $comment $@");
      }

      if ($logfile) {
         my $filevalue;
         if ($testfile =~ m/\@$col\s*=\s*([^,\n]+)[,\n]/) {
            $filevalue = $1;
         }
         my $filetest   = ($filetest{$col} or '%s eq %s');

         $filetest = sprintf($filetest, '$filevalue', '$expectfile{$col}');
         push(@testres,
              eval($filetest) ? "ok %d" :
              "not ok %d # file '$col': <$filevalue>, expected: <$expectfile{$col}>" .
              "   $@");
     }
   }
}


sub do_tests {
    my ($X, $runlogfile, $typeclass, $testcase) = @_;

   $testcase = "<$typeclass" . (defined $testcase ? ", $testcase" : "") . ">";

   my ($result, @params, %params, @paramrefs, %paramrefs,
       @copy1, @copy2, $col);

   # Fill up parameter arrays. As the arrays are changed on each test,
   # fill up copies to refresh with as well.
   foreach $col (@tblcols) {
       if (defined $tbl{$col}) {
          push(@params, $tbl{$col});
          $params{'@' . $col} = $tbl{$col};
          push(@copy1, $tbl{$col});
          push(@copy2, $tbl{$col});
       }
       else {
          push(@params, undef);
          $params{'@' . $col} = undef;
          push(@copy1, undef);
          push(@copy2, undef);
       }
       push(@paramrefs,\$copy1[$#copy1]);
       $paramrefs{'@' . $col}    = \$copy2[$#copy2];
   }

   # Run test for combination.
   blurb("sql_sp $testcase unnamed params, no refs");
   my $logfilename = fixfilename($testcase . '_sql_sp');
   $X->{LogHandle} = open_testfile($logfilename);
   $result = sql_sp("${typeclass}_sp", \@params, HASH, SINGLEROW);
   undef $X->{LogHandle};
   check_data(($runlogfile ? undef : $logfilename), $result, \@params, 0);

   if ($runlogfile) {
      blurb("Log file from sql_sp $testcase");
      my $logfile = get_testfile($logfilename);
      $result = sql($logfile, HASH, SINGLEROW);
      check_data(undef, $result, 0);
   }

   blurb("sql_sp $testcase named params, no refs");
   $result = sql_sp("${typeclass}_sp", \%params, HASH, SINGLEROW);
   undef $X->{LogHandle};
   check_data(undef, $result, \%params, 0);

   blurb("sql_sp $testcase unnamed params, refs");
   $result = sql_sp("${typeclass}_sp", \@paramrefs, HASH, SINGLEROW);
   undef $X->{LogHandle};
   check_data(undef, $result, \@paramrefs, 1);

   blurb("sql_sp $testcase named params, refs");
   $result = sql_sp("${typeclass}_sp", \%paramrefs, HASH, SINGLEROW);
   undef $X->{LogHandle};
   check_data(undef, $result, \%paramrefs, 1);

   # Also test sql_insert.
   blurb("sql_insert $testcase");
   sql("TRUNCATE TABLE ${typeclass}");
   $logfilename = fixfilename($testcase . '_sql_insert');
   $X->{LogHandle} = open_testfile($logfilename);
   sql_insert("${typeclass}", \%tbl);
   undef $X->{LogHandle};
   $result = sql("SELECT * FROM ${typeclass}", HASH, SINGLEROW);
   check_data(($runlogfile ? undef : $logfilename), $result, 0);

   if ($runlogfile and $sqlver >= 7) {
      sql("TRUNCATE TABLE ${typeclass}");
      blurb("Log file from sql_insert $testcase");
      sql(get_testfile($logfilename), NORESULT);
      $result = sql("SELECT * FROM ${typeclass}", HASH, SINGLEROW);
      check_data(undef, $result, 0);
   }

   $no_of_tests += 7 * scalar(keys %expectcol) +
                   4 * (scalar(keys %expectpar));

}



$^W = 1;
$| = 1;

$no_of_tests = 0;

my $X = testsqllogin();

$X->{'ErrInfo'}{RetStatOK}{4711}++;
$X->{'ErrInfo'}{NoWhine}++;
$X->{'ErrInfo'}{NeverPrint}{1708}++;  # Suppresses message for sql_variant table.

$sqlver = (split(/\./, $X->{SQL_version}))[0];
$x86 = not $Config{'use64bitint'};
my $havedb;
if ($sqlver >= 11) {
   my $collation = $X->sql_one("SELECT serverproperty('Collation')", SCALAR);
   if ($collation =~ /_SC$/) {
      $X->sql('CREATE DATABASE Olle$DB COLLATE Latin1_General_CS_AS');
      $X->sql('USE Olle$DB');
      $havedb = 1;
   }
}
my $is_latin1 = is_latin1($X);


# Make sure that we have standard settings, except for ANSI_WARNINGS
# that we want to be off, as we test overlong input.
$X->sql(<<SQLEND);
SET ANSI_DEFAULTS ON
SET CURSOR_CLOSE_ON_COMMIT OFF
SET IMPLICIT_TRANSACTIONS OFF
SET ANSI_WARNINGS OFF
SQLEND

clear_test_data;
create_integer;

%tbl       = (intcol        =>   47114711,
              smallintcol   =>   -4711,
              tinyintcol    =>   111,
              floatcol      =>   123456789.456789,
              realcol       =>   123456789.456789,
              bitcol        =>   1);
%expectcol = (intcol        =>   $tbl{intcol} - 4711,
              smallintcol   =>   $tbl{smallintcol} - 4711,
              tinyintcol    =>   $tbl{tinyintcol} - 47,
              floatcol      =>   sprintf("%1.6f", $tbl{floatcol} - 4711),
              realcol       =>   $tbl{realcol} - 4711,
              bitcol        =>   ($tbl{bitcol} ? 0 : 1));
%expectpar = (intcol        =>   -2 * $tbl{intcol},
              smallintcol   =>   -2 * $tbl{smallintcol},
              tinyintcol    =>   2 * $tbl{tinyintcol},
              floatcol      =>    sprintf("%1.6f", -2 * $tbl{floatcol}),
              realcol       =>   -2 * $tbl{realcol},
              bitcol        =>   ($tbl{bitcol} ? 0 : 1));
%test      = (intcol        =>   '%s == %s',
              smallintcol   =>   '%s == %s',
              tinyintcol    =>   '%s == %s',
              floatcol      =>   'sprintf("%%1.6f", %s) eq %s',
              realcol       =>   'abs(%s - %s) < 10',
              bitcol        =>   '%s == %s');
do_tests($X, 1, 'integer', 'regular');

# Redo the tests, now will as many null values we can have.
%tbl       = (intcol        =>   undef,
              smallintcol   =>   undef,
              tinyintcol    =>   "087",
              floatcol      =>   undef,
              realcol       =>   undef,
              bitcol        =>   '');
%expectcol = (intcol        =>   undef,,
              smallintcol   =>   undef,
              tinyintcol    =>   $tbl{tinyintcol} - 47,
              floatcol      =>   undef,
              realcol       =>   undef,
              bitcol        =>   ($tbl{bitcol} ? 0 : 1));
%expectpar = (intcol        =>   undef,
              smallintcol   =>   undef,
              tinyintcol    =>   2 * $tbl{tinyintcol},
              floatcol      =>   undef,
              realcol       =>   undef,
              bitcol        =>   ($tbl{bitcol} ? 0 : 1));
%test      = (intcol        =>   'not defined %s',
              smallintcol   =>   'not defined %s',
              tinyintcol    =>   '%s eq %s',
              floatcol      =>   'not defined %s',
              realcol       =>   'not defined %s',
              bitcol        =>   '%s == %s');
do_tests($X, 1, 'integer', 'null values');

drop_test_objects('integer');

#------------------------- CHARACTER --------------------------------
clear_test_data;
create_character;


%tbl       = (charcol      => "abc\x{00F6}",
              varcharcol   => "abc\x{010D}",
              varcharcol2  => "123456'8901234567890",
              textcol      => 'Hello Dolly! ' x 2000);
%expectcol = (charcol      => ' ' x 16 . "(\x{00F6}|o)" . 'cba',
              varcharcol   => "(\x{010D}|c)cba",
              varcharcol2  => "0987654321098'654321",
              textcol      => $tbl{textcol});
%expectpar = (charcol      => 'ABC' . "(\x{00D6}|O)" . ' ' x 16,
              varcharcol   => "ABC(\x{010C}|C)",
              varcharcol2  => $tbl{varcharcol2});
%test      = (charcol      => '%s =~ /^%s$/',
              varcharcol   => '%s =~ /^%s$/',
              varcharcol2  => '%s eq %s',
              textcol      => '%s eq %s');
do_tests($X, 1, 'character');

# Known issue: NUL character in SQL command terminates command and because 
# of this the log file cannot be run.
%tbl       = (charcol      => '',
              varcharcol   => '',
              varcharcol2  => "123456789\x00123456789022",
              textcol      => '');
%expectcol = (charcol      => ' ' x 20,
              varcharcol   => '',
              varcharcol2  => "0987654321\x00987654321",
              textcol      => '');
%expectpar = (charcol      => ' ' x 20,
              varcharcol   => '',
              varcharcol2  => substr($tbl{varcharcol2}, 0, 20));
%expectfile= (charcol      => "''",
              varcharcol   => "''",
              varcharcol2  => "'$tbl{varcharcol2}'",
              textcol      => "''");
%test      = (charcol      => '%s eq %s',
              varcharcol   => '%s eq %s',
              varcharcol2  => '%s eq %s',
              textcol      => '%s eq %s');
%filetest  = (charcol      => '%s eq %s',
              varcharcol   => '%s eq %s',
              varcharcol2  => '%s eq %s',
              textcol      => '%s eq %s');
do_tests($X, 0, 'character', 'empty string');

# Known issue SQL7 (only) strips trailing blanks from varchar parameter.
%tbl       = (charcol      => undef,
              varcharcol   => undef,
              varcharcol2  => '  ',
              textcol      => undef);
%expectcol = (charcol      => undef,
              varcharcol   => undef,
              varcharcol2  => '  ',
              textcol      => undef);
%expectpar = (charcol      => undef,
              varcharcol   => undef,
              varcharcol2  => ($sqlver != 7 ? '  ' : '  ?'));
%test      = (charcol      => 'not defined %s',
              varcharcol   => 'not defined %s',
              varcharcol2  => ($sqlver != 7 ? '%s eq %s' : '%s =~ /^%s$/'),
              textcol      => 'not defined %s');
undef %filetest;
do_tests($X, 1, 'character', 'null');

drop_test_objects('character');

#------------------------- BINARY ---------------------------------
clear_test_data;
create_binary;

#$X->{BinaryAsStr} = 1;    Default.
%tbl       = (bincol       => '4711ABCD',
              varbincol    => '4711ABCD',
              tstamp       => '0x00004711ABCD0009',
              imagecol     => '47119660AB002' x 10000);
%expectcol = (bincol       => '00' x 16 . 'CDAB1147',
              varbincol    => 'CDAB1147',
              tstamp       => '^[0-9A-F]{16}$',
              imagecol     => $tbl{'imagecol'});
%expectpar = (bincol       => '4711ABCD4711ABCD' . '00' x 12,
              varbincol    => '4711ABCD4711ABCD',
              tstamp       => 'ABCD000900004711');
%test      = (bincol       => '%s eq %s',
              varbincol    => '%s eq %s',
              tstamp       => '%s =~ /%s/',
              imagecol     => '%s eq %s');
do_tests($X, 1, 'binary', 'BinaryAsStr = 1');

$X->{BinaryAsStr} = 1;
%tbl       = (bincol       => '0x',
              varbincol    => '0x',
              tstamp       => '0x',
              imagecol     => '0x');
%expectcol = (bincol       => '00' x 20,
              varbincol    => '',
              tstamp       => '^[0-9A-F]{16}$',
              imagecol     => '');
%expectpar = (bincol       => '00' x 20,
              varbincol    => '',
              tstamp       => '^' . '00' x 8 . '$');
%test      = (bincol       => '%s eq %s',
              varbincol    => '%s eq %s',
              tstamp       => '%s =~ /%s/',
              imagecol     => '%s eq %s');
do_tests($X, 1, 'binary', 'BinaryAsStr = 1 empty');


$X->{BinaryAsStr} = 'x';
# Known issue: SQL 7 appears to give wrong value back on 0x0000 for varbinpar.
%tbl       = (bincol       => '4711ABCD',
              varbincol    => '0x0000',
              tstamp       => '00004711ABCD0009',
              imagecol     => '47119660AB002' x 100);
%expectcol = (bincol       => '0x' . '00' x 16 . 'CDAB1147',
              varbincol    => '0x0000',
              tstamp       => '^0x[0-9A-F]{16}$',
              imagecol     => '0x' . $tbl{'imagecol'});
%expectpar = (bincol       => '0x4711ABCD4711ABCD' . '00' x 12,
              varbincol    => ($sqlver != 7 ? '0x' . '00' x 4 : '0x00(000000)?'),
              tstamp       => '0xABCD000900004711');
%test      = (bincol       => '%s eq %s',
              varbincol    => ($sqlver != 7 ? '%s eq %s' : '%s =~ /^%s$/'),
              tstamp       => '%s =~ /%s/',
              imagecol     => '%s eq %s');
do_tests($X, 1, 'binary', 'BinaryAsStr = x');

$X->{BinaryAsStr} = 'x';
%tbl       = (bincol       => '',
              varbincol    => '',
              tstamp       => '0x',
              imagecol     => '');
%expectcol = (bincol       => '0x' . '00' x 20,
              varbincol    => '0x',
              tstamp       => '^0x[0-9A-F]{16}$',
              imagecol     => '0x');
%expectpar = (bincol       => '0x' . '00' x 20,
              varbincol    => '0x',
              tstamp       => '^0x' . '00' x 8 . '$');
%test      = (bincol       => '%s eq %s',
              varbincol    => '%s eq %s',
              tstamp       => '%s =~ /%s/',
              imagecol     => '%s eq %s');
do_tests($X, 1, 'binary', 'BinaryAsStr = x. empty');


$X->{BinaryAsStr} = 0;
%tbl       = (bincol       => '4711ABCD',
              varbincol    => 'Typewriter',
              tstamp       => "\x00\x00/!#¤§=",
              imagecol     => 'Hello Dolly! ' x 10000);
%expectcol = (bincol       => "\x00" x 12 . 'DCBA1174',
              varbincol    => 'retirwepyT',
              tstamp       => "^(.|\\n){8}\$",
              imagecol     => $tbl{'imagecol'});
%expectpar = (bincol       => '47114711ABCD' . "\x00" x 8,
              varbincol    => 'TypewriterTypewriter',
              tstamp       => "#¤§=\x00\x00/!");
%test      = (bincol       => '%s eq %s',
              varbincol    => '%s eq %s',
              tstamp       => '%s =~ /%s/',
              imagecol     => '%s eq %s');
do_tests($X, 1, 'binary', 'BinaryAsBinary');


%tbl       = (bincol       => '',
              varbincol    => '',
              tstamp       => '',
              imagecol     => '');
%expectcol = (bincol       => "\x00" x 20,
              varbincol    => '',
              tstamp       => "^(.|\\n){8}\$",
              imagecol     => '');
%expectpar = (bincol       => "\x00" x 20,
              varbincol    => '',
              tstamp       => '^' . "\x00" x 8 . '$');
%test      = (bincol       => '%s eq %s',
              varbincol    => '%s eq %s',
              tstamp       => '%s =~ /%s/',
              imagecol     => '%s eq %s');
do_tests($X, 1, 'binary', 'BinaryAsBinary, empty');

%tbl       = (bincol       => undef,
              varbincol    => undef,
              tstamp       => '00004711ABCD0009',
              imagecol     => undef);
%expectcol = (bincol       => undef,
              varbincol    => undef,
              tstamp       => "^(.|\\n){8}\$",
              imagecol     => undef);
%expectpar = (bincol       => undef,
              varbincol    => undef,
              tstamp       => '^47110000$');
%test      = (bincol       => 'not defined %s',
              varbincol    => 'not defined %s',
              tstamp       => '%s =~ /%s/',
              imagecol     => 'not defined %s');
do_tests($X, 1, 'binary', 'null');

drop_test_objects('binary');

#------------------------- DECIMAL --------------------------------
clear_test_data;
create_decimal;

#$X->{DecimalAsStr} = 0;   This should be default, so test this.
%tbl       = (deccol   => 123456912345678.456789,
              numcol   => 912345678.44,
              moneycol => 123456912345678.4567,
              dimecol  => 123456.4566);
%expectcol = (deccol   => $tbl{deccol}   - 12345678,
              numcol   => $tbl{numcol}   - 12345678,
              moneycol => $tbl{moneycol} - 12345678,
              dimecol  => $tbl{dimecol}  - 123456);
%expectpar = (deccol   => -2 * $tbl{deccol},
              numcol   => -$tbl{numcol} / 2,
              moneycol => -2 * $tbl{moneycol},
              dimecol  => -$tbl{dimecol} / 2);
%test      = (deccol   => 'abs(%s - %s) < 100',
              numcol   => 'abs(%s - %s) < 1E-6',
              moneycol => 'abs(%s - %s) < 100',
              dimecol  => 'abs(%s - %s) < 1E-6');
do_tests($X, 1, 'decimal', 'DecimalAsStr = 0');


$X->{DecimalAsStr} = 1; # Input is still numeric.
%tbl       = (deccol   => 123456912345678.456789,
              numcol   => 912345678.44,
              moneycol => 123456912345678.4567,
              dimecol  => 123456.4566);
%expectcol = (deccol   => $tbl{deccol}   - 12345678,
              numcol   => '900000000.44',
              moneycol => $tbl{moneycol} - 12345678,
              dimecol  => '0.4566');
%expectpar = (deccol   => -2 * $tbl{deccol},
              numcol   => '-456172839.22',
              moneycol => -2 * $tbl{moneycol},
              dimecol  => '-61728.2283');
%test      = (deccol   => 'abs(%s - %s) < 100',
              numcol   => '%s eq %s',
              moneycol => 'abs(%s - %s) < 100',
              dimecol  => '%s eq %s');
do_tests($X, 1, 'decimal', 'DecimalAsStr = 1, num in');


# Now we also send strings in.
%tbl       = (deccol   => '123456912345678.456789',
              numcol   => '912345678.44',
              moneycol => '123456912345678.4567',
              dimecol  => '123456.4566');
%expectcol = (deccol   => '123456900000000.456789',
              numcol   => '900000000.44',
              moneycol => '123456900000000.4567',
              dimecol  => '0.4566');
%expectpar = (deccol   => '-246913824691356.913578',
              numcol   => '-456172839.22',
              moneycol => '-246913824691356.9134',
              dimecol  => '-61728.2283');
%test      = (deccol   => '%s eq %s',
              numcol   => '%s eq %s',
              moneycol => '%s eq %s',
              dimecol  => '%s eq %s');
do_tests($X, 1, 'decimal', 'DecimalAsStr = 1, str in');

# And test null values.
%tbl       = (deccol   => undef,
              numcol   => undef,
              moneycol => undef,
              dimecol  => undef);
%expectcol = (deccol   => undef,
              numcol   => undef,
              moneycol => undef,
              dimecol  => undef);
%expectpar = (deccol   => undef,
              numcol   => undef,
              moneycol => undef,
              dimecol  => undef);
%test      = (deccol   => 'not defined %s',
              numcol   => 'not defined %s',
              moneycol => 'not defined %s',
              dimecol  => 'not defined %s');
do_tests($X, 1, 'decimal', 'null values');

drop_test_objects('decimal');

#------------------------- DATETIME --------------------------------
clear_test_data;
create_datetime;

# For datetime we must read the log file for most cases, since most date
# strings will only be exuectable with some dateformat settings - or
# even not at all.

#$X->{DateimeOption} = DATETIME_ISO    -- The default.
%tbl       = (datetimecol  => '1996-08-13 04:36:24.997',
              smalldatecol => '1996-08-13 04:36');
%expectcol = (datetimecol  => '1996-08-30 04:36:24.997',
              smalldatecol => '1996-11-13 04:36');
%expectpar = (datetimecol  => '1996-08-13 08:36:24.997',
              smalldatecol => '1996-08-13 04:50');
%expectfile= (datetimecol  => "'1996-08-13 04:36:24.997'",
              smalldatecol => "'1996-08-13 04:36'");
%test      = (datetimecol  => '%s eq %s',
              smalldatecol => '%s eq %s');
do_tests($X, 0, 'datetime', 'ISO in/out');

%tbl       = (datetimecol  => undef,
              smalldatecol => undef);
%expectcol = (datetimecol  => undef,
              smalldatecol => undef);
%expectpar = (datetimecol  => undef,
              smalldatecol => undef);
undef %expectfile;
%test      = (datetimecol  => 'not defined %s',
              smalldatecol => 'not defined %s');
do_tests($X, 1, 'datetime', 'ISO in/out, nulls');


%tbl       = (datetimecol  => '1996-08-13',
              smalldatecol => '1996-8-13');
%expectcol = (datetimecol  => '1996-08-30 00:00:00.000',
              smalldatecol => '1996-11-13 00:00');
%expectpar = (datetimecol  => '1996-08-13 04:00:00.000',
              smalldatecol => '1996-08-13 00:14');
%expectfile= (datetimecol  => "'1996-08-13'",
              smalldatecol => "'1996-8-13'");
%test      = (datetimecol  => '%s eq %s',
              smalldatecol => '%s eq %s');
do_tests($X, 0, 'datetime', 'ISO dates only');

%tbl       = (datetimecol  => '19960813 04:36:24.997',
              smalldatecol => '19960813 4:36');
%expectcol = (datetimecol  => '1996-08-30 04:36:24.997',
              smalldatecol => '1996-11-13 04:36');
%expectpar = (datetimecol  => '1996-08-13 08:36:24.997',
              smalldatecol => '1996-08-13 04:50');
undef %expectfile;   # The log file can be used, hooray!
%test      = (datetimecol  => '%s eq %s',
              smalldatecol => '%s eq %s');
do_tests($X, 1, 'datetime', 'YYYYMMDD in/ISO out');

%tbl       = (datetimecol  => '19960813',
              smalldatecol => '19960813');
%expectcol = (datetimecol  => '1996-08-30 00:00:00.000',
              smalldatecol => '1996-11-13 00:00');
%expectpar = (datetimecol  => '1996-08-13 04:00:00.000',
              smalldatecol => '1996-08-13 00:14');
undef %expectfile;
%test      = (datetimecol  => '%s eq %s',
              smalldatecol => '%s eq %s');
do_tests($X, 1, 'datetime', 'YYYMMDD only in/ISO out');

%tbl       = (datetimecol  => '1994-08-13Z',
              smalldatecol => '1994-08-13Z');
%expectcol = (datetimecol  => '1994-08-30 00:00:00.000',
              smalldatecol => '1994-11-13 00:00');
%expectpar = (datetimecol  => '1994-08-13 04:00:00.000',
              smalldatecol => '1994-08-13 00:14');
if ($sqlver >= 9) {
   undef %expectfile;
}
else {
   %expectfile= (datetimecol  => "'1994-08-13Z'",
                 smalldatecol => "'1994-08-13Z'");
}
%test      = (datetimecol  => '%s eq %s',
              smalldatecol => '%s eq %s');
do_tests($X, ($sqlver >= 9), 'datetime', 'YYYY-MM-DDZ');


%tbl       = (datetimecol  => '1996-08-13T04:36:24.997',
              smalldatecol => '1996-08-13T04:36');
%expectcol = (datetimecol  => '1996-08-30 04:36:24.997',
              smalldatecol => '1996-11-13 04:36');
%expectpar = (datetimecol  => '1996-08-13 08:36:24.997',
              smalldatecol => '1996-08-13 04:50');
%expectfile= (datetimecol  => "'1996-08-13T04:36:24.997'",
              smalldatecol => "'1996-08-13T04:36'");
%test      = (datetimecol  => '%s eq %s',
              smalldatecol => '%s eq %s');
do_tests($X, 0, 'datetime', 'XML in/ ISO out');

%tbl       = (datetimecol  => {Year => 1996, Month => 8, Day => 13,
                               Hour => 4, Minute => 36, Second => 24,
                               Fraction => 997},
              smalldatecol => {Year => 1996, Month => 8, Day => 13,
                               Hour => 4, Minute => 36});
%expectcol = (datetimecol  => '1996-08-30 04:36:24.997',
              smalldatecol => '1996-11-13 04:36');
%expectpar = (datetimecol  => '1996-08-13 08:36:24.997',
              smalldatecol => '1996-08-13 04:50');
%test      = (datetimecol  => '%s eq %s',
              smalldatecol => '%s eq %s');
%expectfile= (datetimecol  => "^'HASH\\(",
              smalldatecol => "^'HASH\\(");
%filetest  = (datetimecol  => '%s =~ /%s/',
              smalldatecol => '%s =~ /%s/');
do_tests($X, 0, 'datetime', 'Hash in, ISO out');

%tbl       = (datetimecol  => {Year => 1996, Month => 8, Day => 13},
              smalldatecol => {Year => 1996, Month => 8, Day => 13});
%expectcol = (datetimecol  => '1996-08-30 00:00:00.000',
              smalldatecol => '1996-11-13 00:00');
%expectpar = (datetimecol  => '1996-08-13 04:00:00.000',
              smalldatecol => '1996-08-13 00:14');
%test      = (datetimecol  => '%s eq %s',
              smalldatecol => '%s eq %s');
%expectfile= (datetimecol  => "^'HASH\\(",
              smalldatecol => "^'HASH\\(");
%filetest  = (datetimecol  => '%s =~ /%s/',
              smalldatecol => '%s =~ /%s/');
do_tests($X, 0, 'datetime', 'Hash in dates only');

%tbl       = (datetimecol  => 3.25,
              smalldatecol => 4);
%expectcol = (datetimecol  => '1900-01-19 06:00:00.000',
              smalldatecol => '1900-04-03 00:00');
%expectpar = (datetimecol  => '1900-01-02 10:00:00.000',
              smalldatecol => '1900-01-03 00:14');
%expectfile= %tbl;
%test      = (datetimecol  => '%s eq %s',
              smalldatecol => '%s eq %s');
do_tests($X, 0, 'datetime', 'Float in/ ISO out');

%tbl       = (datetimecol  => ISO_to_regional("1996-08-13 04:36:24"),
              smalldatecol => ISO_to_regional("1996-08-13 04:36"));
%expectcol = (datetimecol  => '1996-08-30 04:36:24.000',
              smalldatecol => '1996-11-13 04:36');
%expectpar = (datetimecol  => '1996-08-13 08:36:24.000',
              smalldatecol => '1996-08-13 04:50');
%expectfile= (datetimecol  => "'$tbl{datetimecol}'",
              smalldatecol => "'$tbl{smalldatecol}'");
%test      = (datetimecol  => '%s eq %s',
              smalldatecol => '%s eq %s');
do_tests($X, 0, 'datetime', 'Reg setting long in/ISO out');

$X->{DatetimeOption} = DATETIME_STRFMT;
%tbl       = (datetimecol  => '19960813 04:36:24 . 997',
              smalldatecol => '19960813 04:36');
%expectcol = (datetimecol  => '19960830 04:36:24.997',
              smalldatecol => '19961113 04:36(:00)?');
%expectpar = (datetimecol  => '19960813 08:36:24.997',
              smalldatecol => '19960813 04:50(:00)?');
undef %expectfile;
%test      = (datetimecol  => '%s eq %s',
              smalldatecol => '%s =~ /^%s$/');
do_tests($X, 1, 'datetime', 'ISO in/ STRFMT out default');

$X->{DateFormat} = "%d.%m.%y";
undef $X->{msecFormat};
%tbl       = (datetimecol  => '  19960831 04 :36:24.997',
              smalldatecol => '19960731 04:36  ');
%expectcol = (datetimecol  => '17.09.96',
              smalldatecol => '31.10.96');
%expectpar = (datetimecol  => '31.08.96',
              smalldatecol => '31.07.96');
undef %expectfile;
%test      = (datetimecol  => '%s eq %s',
              smalldatecol => '%s eq %s');
do_tests($X, 1, 'datetime', 'ISO in/ STRFMT out custom');

$X->{DatetimeOption} = DATETIME_FLOAT;
%tbl       = (datetimecol  => '19000102 06:00',
              smalldatecol => '19000104');
%expectcol = (datetimecol  => 20.25,
              smalldatecol => 95);
%expectpar = (datetimecol  => 3 + 10/24,
              smalldatecol => 5 + 14/(24*60));
undef %expectfile;
%test      = (datetimecol  => 'abs(%s - %s) < 1E-9',
              smalldatecol => 'abs(%s - %s) < 1E-9');
do_tests($X, 1, 'datetime', 'ISO in/ FLOAT out');

$X->{DatetimeOption} = DATETIME_HASH;
%tbl       = (datetimecol  => '19960229 04:36:24.997',
              smalldatecol => '20000229 04:36');
%expectcol = (datetimecol  => {Year => 1996, Month => 3, Day => 17,
                               Hour => 4, Minute => 36, Second => 24,
                               Fraction => 997},
              smalldatecol => {Year => 2000, Month => 5, Day => 29,
                               Hour => 4, Minute => 36, Second => 0,
                               Fraction => 0});
%expectpar = (datetimecol  => {Year => 1996, Month => 2, Day => 29,
                               Hour => 8, Minute => 36, Second => 24,
                               Fraction => 997},
              smalldatecol => {Year => 2000, Month => 2, Day => 29,
                               Hour => 4, Minute => 50, Second => 0,
                               Fraction => 0});
undef %expectfile;
%test      = (datetimecol  => 'datehash_compare(%s, %s)',
              smalldatecol => 'datehash_compare(%s, %s)');
do_tests($X, 1, 'datetime', 'ISO in/HASH out');

%tbl       = (datetimecol  => undef,
              smalldatecol => undef);
%expectcol = (datetimecol  => undef,
              smalldatecol => undef);
%expectpar = (datetimecol  => undef,
              smalldatecol => undef);
undef %expectfile;
%test      = (datetimecol  => 'not defined %s',
              smalldatecol => 'not defined %s');
do_tests($X, 1, 'datetime', 'NULL in/hash out');

$X->{DatetimeOption} = DATETIME_REGIONAL;
%tbl       = (datetimecol  => '19960813 04:36:24',
              smalldatecol => '19960813 04:36');
%expectcol = (datetimecol  => ISO_to_regional('1996-08-30 04:36:24'),
              smalldatecol => ISO_to_regional('1996-11-13 04:36'));
%expectpar = (datetimecol  => ISO_to_regional('1996-08-13 08:36:24'),
              smalldatecol => ISO_to_regional('1996-08-13 04:50'));
undef %expectfile;
%test      = (datetimecol  => '%s eq %s',
              smalldatecol => '%s eq %s');
do_tests($X, 1, 'datetime', 'ISO in/ REGIONAL out');

drop_test_objects('datetime');

#------------------------- GUID + NULLBIT-------------------------------
clear_test_data;
create_guid;

%tbl       = (guidcol     => 'FF0DCAF3-CFFC-4C9B-AE4B-C08B2000871C',
              nullbitcol  => 1);
%expectcol = (guidcol     => '{000DCA03-C00C-4C9B-AE4B-C08B2000871C}',
              nullbitcol  => 0);
%expectpar = (guidcol     => '{AA0DCAA3-CAAC-4C9B-AE4B-C08B2000871C}',
              nullbitcol  => 0);
%test      = (guidcol     => '%s eq %s',
              nullbitcol  => '%s eq %s');
do_tests($X, 1, 'guid', 'unbraced');

%tbl       = (guidcol     => '{FF0DCAF3-CFFC-4C9B-AE4B-C08B2000871C}',
              nullbitcol  => 0);
%expectcol = (guidcol     => '{000DCA03-C00C-4C9B-AE4B-C08B2000871C}',
              nullbitcol  => 1);
%expectpar = (guidcol     => '{AA0DCAA3-CAAC-4C9B-AE4B-C08B2000871C}',
              nullbitcol  => 1);
%test      = (guidcol     => '%s eq %s',
              nullbitcol  => '%s eq %s');
do_tests($X, 1, 'guid', 'braced');

%tbl       = (guidcol     => undef,
              nullbitcol  => undef);
%expectcol = (guidcol     => undef,
              nullbitcol  => undef);
%expectpar = (guidcol     => undef,
              nullbitcol  => undef);
%test      = (guidcol     => 'not defined %s',
              nullbitcol  => 'not defined %s');
do_tests($X, 1, 'guid', 'null values');

drop_test_objects('guid');

#------------------------- UNICODE --------------------------------
clear_test_data;
create_unicode;

my $nvarcharcol = "\x{0144}varcharcol";
my $ncharcol2 = 'nchärcöl2';
binmode(STDOUT, ':utf8:');

%tbl       = (ncharcol      => "\x{00E6}\x{00E5}\x{00F6}\x{FFFD}",
              $nvarcharcol  => "abc\x{0157}",
              $ncharcol2    => "123456'890123456789\x{010B}",
              ntextcol      => '21 pa\x{017A}dziernika 2004 ' x 2000);
%expectcol = (ncharcol      => ' ' x 16 . "\x{FFFD}\x{00F6}\x{00E5}\x{00E6}",
              $nvarcharcol  => "\x{0157}cba",
              $ncharcol2    => "\x{010B}987654321098'654321",
              ntextcol      => $tbl{ntextcol});
%expectpar = (ncharcol      => "\x{00C6}\x{00C5}\x{00D6}\x{FFFD}" . ' ' x 16,
              $nvarcharcol  => "ABC\x{0156}",
              $ncharcol2    => "123456'890123456789\x{010A}");
%test      = (ncharcol      => '%s eq %s',
              $nvarcharcol  => '%s eq %s',
              $ncharcol2    => '%s eq %s',
              ntextcol      => '%s eq %s');
do_tests($X, 1, 'unicode');

# Known issue: NULL terminates strings in literal SQL commands, so log
# file cannot be used. Unknown if this is an SQL Server bug.
%tbl       = (ncharcol      => '',
              $nvarcharcol  => '',
              $ncharcol2    => "\x001234567890'23456789022",
              ntextcol      => '');
%expectcol = (ncharcol      => ' ' x 20,
              $nvarcharcol  => '',
              $ncharcol2    => "98765432'0987654321\x00",
              ntextcol      => '');
%expectpar = (ncharcol      => ' ' x 20,
              $nvarcharcol  => '',
              $ncharcol2    => "\x001234567890'23456789");
%expectfile= (ncharcol      => "N''",
              $nvarcharcol  => "N''",
              $ncharcol2    => "N'\x001234567890''23456789022'",
              ntextcol      => "N''");
%test      = (ncharcol      => '%s eq %s',
              $nvarcharcol  => '%s eq %s',
              $ncharcol2    => '%s eq %s',
              ntextcol      => '%s eq %s');
do_tests($X, 0, 'unicode', 'empty string');

# Known issue SQL7 (only) strips trailing blanks from nvarchar parameter.
%tbl       = (ncharcol      => undef,
              $nvarcharcol  => undef,
              $ncharcol2    => '  ',
              ntextcol      => undef);
%expectcol = (ncharcol      => undef,
              $nvarcharcol  => undef,
              $ncharcol2    => ' ' x 20,
              ntextcol      => undef);
%expectpar = (ncharcol      => undef,
              $nvarcharcol  => undef,
              $ncharcol2    => ' ' x 20);
%test      = (ncharcol      => 'not defined %s',
              $nvarcharcol  => 'not defined %s',
              $ncharcol2    => '%s eq %s',
              ntextcol      => 'not defined %s');
do_tests($X, 1, 'unicode', 'null');

drop_test_objects('unicode');

#------------------------- BIGINT -------------------------------
# From here we're SQL 2000 and up only.
goto finally if $sqlver == 7;

#------------------------- BIGINT --------------------------------
clear_test_data;
create_bigint;

# Different tests for x86 and 64-bit.
if ($x86) {
   $X->{DecimalAsStr} = 0;
   %tbl       = (bigintcol   => 123456912345678);
   %expectcol = (bigintcol   => $tbl{bigintcol} - 12345678);
   %expectpar = (bigintcol   => -2 * $tbl{bigintcol});
   %test      = (bigintcol   => 'abs(%s - %s) < 100');
   do_tests($X, 1, 'bigint', 'x86 DecimalAsStr = 0');

   $X->{DecimalAsStr} = 1; # Input is still numeric.
   %tbl       = (bigintcol   => 123456912345678);
   %expectcol = (bigintcol   => $tbl{bigintcol} - 12345678);
   %expectpar = (bigintcol   => -2 * $tbl{bigintcol});
   %test      = (bigintcol   => 'abs(%s - %s) < 100');
   do_tests($X, 1, 'bigint', 'x86 DecimalAsStr = 1, num in');

   # Now we also send strings in.
   %tbl       = (bigintcol   => '123456912345678');
   %expectcol = (bigintcol   => '123456900000000');
   %expectpar = (bigintcol   => '-246913824691356');
   %test      = (bigintcol   => '%s eq %s');
   do_tests($X, 1, 'bigint', 'x86 DecimalAsStr = 1, str in');
}
else {
   %tbl       = (bigintcol   => 123456789012345678);
   %expectcol = (bigintcol   => $tbl{bigintcol} - 12345678);
   %expectpar = (bigintcol   => -2 * $tbl{bigintcol});
   %test      = (bigintcol   => '%s = %s');
   do_tests($X, 1, 'bigint', 'Regular 64-bit');

   # Test strings in, but they should still come back as numbers.
   %tbl       = (bigintcol   => '123456912345678');
   %expectcol = (bigintcol   => 123456900000000);
   %expectpar = (bigintcol   => -246913824691356);
   %test      = (bigintcol   => '%s == %s');
   do_tests($X, 1, 'bigint', '64-bit, str in');
}


# And test null values.
%tbl       = (bigintcol => undef);
%expectcol = (bigintcol => undef);
%expectpar = (bigintcol => undef);
%test      = (bigintcol => 'not defined %s');
do_tests($X, 1, 'bigint', 'null values');

drop_test_objects('bigint');

#------------------------- ROWVERSION ---------------------------------
clear_test_data;
create_rowversion;

$X->{BinaryAsStr} = 1;
%tbl       = (slask        => 4711,
              tstamp       => '0x00004711ABCD0009');
%expectcol = (slask        => 4701,
              tstamp       => '^[0-9A-F]{16}$');
%expectpar = (slask        => 4721,
              tstamp       => 'ABCD000900004711');
%test      = (slask        => '%s == %s',
              tstamp       => '%s =~ /%s/');
do_tests($X, 1, 'rowversion', 'BinaryAsStr = 1');

#---------------------------- SQL_VARIANT ------------------------------
clear_test_data;
create_sql_variant;

# Test send in outtype to tell how data is to be returned. intype is the
# base type for the expression for the inparameter.

# This is always the same, because we never run the log file. Parameter
# should always be an nvarchar constant.
%filetest  = (varcol  => '%s eq %s');

# Note here that the test for outtype is really a dummy type - this is not
# an output parameter. But this is how the framework works.
%tbl       = (varcol  => 112,
              intype  => undef,
              outtype => 'bit');
%expectcol = (varcol  => 1,
              intype  => 'int',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => 1,
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s == %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'bit');

%tbl       = (varcol  => 112,
              intype  => undef,
              outtype => 'tinyint');
%expectcol = (varcol  => 62,
              intype  => 'int',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => 224,
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s == %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'tinyint');

%tbl       = (varcol  => -10112,
              intype  => undef,
              outtype => 'smallint');
%expectcol = (varcol  => -10162,
              intype  => 'int',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => 20224,
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s == %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'int');

%tbl       = (varcol  => 1120000,
              intype  => undef,
              outtype => 'int');
%expectcol = (varcol  => 1119950,
              intype  => 'int',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => -2240000,
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%test      = (varcol  => '%s == %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
do_tests($X, 0, 'sql_variant', 'int');

if ($x86) {
   $X->{DecimalAsStr} = 0;
   %tbl       = (varcol  => 123456912345678,
                 intype  => undef,
                 outtype => 'bigint');
   %expectcol = (varcol  => 123456900000000,
                 intype  => 'float',
                 outtype => $tbl{'outtype'});
   %expectpar = (varcol  => -246913824691356,
                 intype  => $expectcol{'intype'},
                 outtype => $tbl{'outtype'});
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   %test      = (varcol  => 'abs(%s - %s) < 100',
                 intype  => '%s eq %s',
                 outtype => '%s eq %s');
   do_tests($X, 0, 'sql_variant', 'bigint x86');

   $X->{DecimalAsStr} = 1;
   %tbl       = (varcol  => '123456912345678',
                 intype  => undef,
                 outtype => 'bigint');
   %expectcol = (varcol  => '123456900000000',
                 intype  => 'varchar',
                 outtype => $tbl{'outtype'});
   %expectpar = (varcol  => '-246913824691356',
                 intype  => $expectcol{'intype'},
                 outtype => $tbl{'outtype'});
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   %test      = (varcol  => '%s eq %s',
                 intype  => '%s eq %s',
                 outtype => '%s eq %s');
   do_tests($X, 0, 'sql_variant', 'bigint x86 as str');
}
else {
   %tbl       = (varcol  => 123456912345678,
                 intype  => undef,
                 outtype => 'bigint');
   %expectcol = (varcol  => 123456900000000,
                 intype  => 'bigint',
                 outtype => $tbl{'outtype'});
   %expectpar = (varcol  => -246913824691356,
                 intype  => $expectcol{'intype'},
                 outtype => $tbl{'outtype'});
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   %test      = (varcol  => '%s == %s',
                 intype  => '%s eq %s',
                 outtype => '%s eq %s');
   do_tests($X, 0, 'sql_variant', 'bigint 64-bit');

   %tbl       = (varcol  => 0x7fff_ffff,
                 intype  => undef,
                 outtype => 'bigint');
   %expectcol = (varcol  => $tbl{'varcol'} - 12345678,
                 intype  => 'int',
                 outtype => $tbl{'outtype'});
   %expectpar = (varcol  => -2*$tbl{'varcol'},
                 intype  => $expectcol{'intype'},
                 outtype => $tbl{'outtype'});
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   %test      = (varcol  => '%s == %s',
                 intype  => '%s eq %s',
                 outtype => '%s eq %s');
   do_tests($X, 0, 'sql_variant', 'bigint 64-bit, maxint in');

   %tbl       = (varcol  => $tbl{'varcol'} + 1,
                 intype  => undef,
                 outtype => 'bigint');
   %expectcol = (varcol  => $tbl{'varcol'} - 12345678,
                 intype  => 'bigint',
                 outtype => $tbl{'outtype'});
   %expectpar = (varcol  => -2*$tbl{'varcol'},
                 intype  => $expectcol{'intype'},
                 outtype => $tbl{'outtype'});
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   %test      = (varcol  => '%s == %s',
                 intype  => '%s eq %s',
                 outtype => '%s eq %s');
   do_tests($X, 0, 'sql_variant', 'bigint 64-bit, maxint+1 in');

   %tbl       = (varcol  => -1 * $tbl{'varcol'},
                 intype  => undef,
                 outtype => 'bigint');
   %expectcol = (varcol  => $tbl{'varcol'} - 12345678,
                 intype  => 'int',
                 outtype => $tbl{'outtype'});
   %expectpar = (varcol  => -2*$tbl{'varcol'},
                 intype  => $expectcol{'intype'},
                 outtype => $tbl{'outtype'});
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   %test      = (varcol  => '%s == %s',
                 intype  => '%s eq %s',
                 outtype => '%s eq %s');
   do_tests($X, 0, 'sql_variant', 'bigint 64-bit, minint in');
}

%tbl       = (varcol  => 786.987,
              intype  => undef,
              outtype => 'real');
%expectcol = (varcol  => 736.987,
              intype  => 'float',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => -1573.974,
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => 'abs(%s - %s) < 0.01',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'real');

%tbl       = (varcol  => -786.987,
              intype  => undef,
              outtype => 'float');
%expectcol = (varcol  => -836.987,
              intype  => 'float',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => 1573.974,
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => 'abs(%s - %s) < 1E-7',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'float');

$X->{DecimalAsStr} = 0;
%tbl       = (varcol  => -912345678.12,
              intype  => undef,
              outtype => 'numeric');
%expectcol = (varcol  => -924691356.12,
              intype  => 'float',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => 1824691356.24,
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => 'abs(%s - %s) < 0.001',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'numeric, dec as num');

$X->{DecimalAsStr} = 1;
%tbl       = (varcol  => '123456912345678.123456',
              intype  => undef,
              outtype => 'decimal');
%expectcol = (varcol  => '123456900000000.123456',
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => '-246913824691356.246912',
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s eq %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'decimal as str');

$X->{DecimalAsStr} = 1;
%tbl       = (varcol  => '12345.3412',
              intype  => undef,
              outtype => 'smallmoney');
%expectcol = (varcol  => '0.3412',
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => '-24690.6824',
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s eq %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'smallmoney as str');

$X->{DecimalAsStr} = 0;
%tbl       = (varcol  => '123456912345678.123456',
              intype  => undef,
              outtype => 'decimal');
%expectcol = (varcol  => 123456900000000.123456,
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => -246913824691356.246912,
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => 'abs(%s - %s) < 0.01',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'money as dec');

# For all tests with date hashes, the type is different depending on
# the new date/time data types are available.
my $datetimeintype = 'datetime' .
                     (($sqlver >= 10 and
                      $X->{Provider} >= PROVIDER_SQLNCLI10) ? '2' : '');

$X->{DatetimeOption} = DATETIME_ISO;
%tbl       = (varcol  => {Year => 1996, Month => 10, Day => 21,
                          Hour => 14, Minute => 16, Second => 23},
              intype  => undef,
              outtype => 'datetime');
%expectcol = (varcol  => '1996-09-01 14:16:23.000',
              intype  => $datetimeintype,
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => '1996-10-22 00:16:23.000',
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s eq %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'datetime hash/iso');

%tbl       = (varcol  => {Year => 1996, Month => 10, Day => 21,
                          Hour => 14, Minute => 16, Second => 23},
              intype  => undef,
              outtype => 'smalldatetime');
%expectcol = (varcol  => '1996-09-01 14:16',
              intype  => $datetimeintype,
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => '1996-10-22 00:16',
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s eq %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'smalldatetime hash/iso');

$X->{DatetimeOption} = DATETIME_REGIONAL;
%tbl       = (varcol  => {Year => 1996, Month => 10, Day => 21,
                          Second => 23},
              intype  => undef,
              outtype => 'datetime');
%expectcol = (varcol  => ISO_to_regional('1996-09-01 00:00:23'),
              intype  => $datetimeintype,
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => ISO_to_regional('1996-10-21 10:00:23'),
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s eq %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'datetime hash/regional');

$X->{DatetimeOption} = DATETIME_HASH;
%tbl       = (varcol  => '19961021 14:16:23',
              intype  => undef,
              outtype => 'datetime');
%expectcol = (varcol  => {Year => 1996, Month => 9, Day => 1, Hour => 14,
                          Minute => 16, Second => 23, Fraction => 0},
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => {Year => 1996, Month => 10, Day => 22, Hour => 0,
                          Minute => 16, Second => 23, Fraction => 0},
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => 'datehash_compare(%s, %s)',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'datetime iso/hash');

%tbl       = (varcol  => '20790521 14:16',
              intype  => undef,
              outtype => 'smalldatetime');
%expectcol = (varcol  => {Year => 2079, Month => 4, Day => 1, Hour => 14,
                          Minute => 16, Second => 0, Fraction => 0},
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => {Year => 2079, Month => 5, Day => 22, Hour => 0,
                          Minute => 16, Second => 0, Fraction => 0},
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => 'datehash_compare(%s, %s)',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'smalldatetime iso/hash');

%tbl       = (varcol  => "abc",
              intype  => undef,
              outtype => 'char');
%expectcol = (varcol  => ' ' x 17 . "cba",
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => "ABC" . ' ' x 17,
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s eq %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'char');

%tbl       = (varcol  => "123456789\x00123456789nn",
              intype  => undef,
              outtype => 'varchar');
%expectcol = (varcol  => "n987654321\x00987654321",
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => "123456789\x00123456789N",
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s eq %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'varchar');

%tbl       = (varcol  => "",
              intype  => undef,
              outtype => 'varchar');
%expectcol = (varcol  => "",
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => "",
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s eq %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'varchar empty str');


%tbl       = (varcol  => "abc\x{010B}\x{FFFD}",
              intype  => undef,
              outtype => 'nchar');
%expectcol = (varcol  => ' ' x 15 . "\x{FFFD}\x{010B}cba",
              intype  => 'nvarchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => "ABC\x{010A}\x{FFFD}" . ' ' x 15,
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s eq %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'nchar');

%tbl       = (varcol  => "\x{010B}123456789\x{FFFD}",
              intype  => undef,
              outtype => 'nvarchar');
%expectcol = (varcol  => "\x{FFFD}987654321\x{010B}",
              intype  => 'nvarchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => "\x{010A}123456789\x{FFFD}",
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s eq %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'nvarchar');

$X->{BinaryAsStr} = 0;
%tbl       = (varcol  => "123456789\x{FFFD}",
              intype  => undef,
              outtype => 'binary');
%expectcol = (varcol  => "1\x002\x003\x004\x005\x006\x007\x008\x009\x00\xFD\xFF",
              intype  => 'nvarchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => "1\x002\x003\x004\x005\x006\x007\x008\x009\x00\xFD\xFF",
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s eq %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'binary as bin');

$X->{BinaryAsStr} = 1;
%tbl       = (varcol  => "abc",
              intype  => undef,
              outtype => 'varbinary');
%expectcol = (varcol  => "616263",
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => "616263",
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s eq %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'varbinary as str');

$X->{BinaryAsStr} = 'x';
%tbl       = (varcol  => "abc",
              intype  => undef,
              outtype => 'binary');
%expectcol = (varcol  => "0x616263" . '00' x 17,
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => "0x616263" . '00' x 17,
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s eq %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'binary as 0x');

%tbl       = (varcol  => "1B2EA68F-6E22-4471-B67E-2E4EFCC283CD",
              intype  => undef,
              outtype => 'uniqueidentifier');
%expectcol = (varcol  => "{1B2EA68F-6E22-4471-B67E-2E4EFCC283CD}",
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => "{1B2EA68F-6E22-4471-B67E-2E4EFCC283CD}",
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s eq %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'uniqueidentifier');

%tbl       = (varcol  => [9878],
              intype  => undef,
              outtype => 'NULL');
%expectcol = (varcol  => undef,
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => undef,
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => 'not defined %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'NULL out');

%tbl       = (varcol  => undef,
              intype  => undef,
              outtype => 'datetime');
%expectcol = (varcol  => undef,
              intype  => undef,
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => undef,
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "NULL",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => 'not defined %s',
              intype  => 'not defined %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'NULL in/out');

# New data types in SQL 2008 comes here.
if ($sqlver >= 10) {
   $X->{DatetimeOption} = DATETIME_ISO;
   %tbl       = (varcol  => {Year => 1996, Month => 10, Day => 21},
                 intype  => undef,
                 outtype => 'datetime2');
   %expectcol = (varcol  => '1996-09-01 00:00:00.0000',
                 intype  => ($X->{Provider} >= PROVIDER_SQLNCLI10 ?
                            'date' : 'datetime'),
                 outtype => $tbl{'outtype'});
   %expectpar = (varcol  => '1996-10-21 10:00:00.00',
                 intype  => $expectcol{'intype'},
                 outtype => $tbl{'outtype'});
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   %test      = (varcol  => '%s eq %s',
                 intype  => '%s eq %s',
                 outtype => '%s eq %s');
   do_tests($X, 0, 'sql_variant', 'date hash/ datetime2 iso');

   %tbl       = (varcol  => {Year => 1996, Month => 10, Day => 21,
                             Hour => 14, Minute => 16, Second => 23,
                             Fraction => 160.23, TZHour => 9},
                 intype  => undef,
                 outtype => 'datetimeoffset');
   if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
      %expectcol = (varcol  => '1996-09-01 14:16:23 +09:00',
                    intype  => 'datetimeoffset',
                    outtype => $tbl{'outtype'});
      %expectpar = (varcol  => '1996-10-22 00:16:23.1602300 +09:00',
                    intype  => $expectcol{'intype'},
                    outtype => $tbl{'outtype'});
   }
   else {
      %expectcol = (varcol  => '1996-09-01 14:16:23 +00:00',
                    intype  => 'datetime',
                    outtype => $tbl{'outtype'});
      %expectpar = (varcol  => '1996-10-22 00:16:23.1600000 +00:00',
                    intype  => $expectcol{'intype'},
                    outtype => $tbl{'outtype'});
   }
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   %test      = (varcol  => '%s eq %s',
                 intype  => '%s eq %s',
                 outtype => '%s eq %s');
   do_tests($X, 0, 'sql_variant', 'datetimeoffset hash/iso');

   $X->{DatetimeOption} = DATETIME_REGIONAL;
   %tbl       = (varcol  => {Hour => 14, Minute => 16, Second => 23},
                 intype  => undef,
                 outtype => 'datetime');
   if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
      %expectcol = (varcol  => ISO_to_regional('1899-11-12 14:16:23'),
                    intype  => 'time',
                    outtype => $tbl{'outtype'});
      %expectpar = (varcol  => ISO_to_regional('1900-01-02 00:16:23'),
                    intype  => $expectcol{'intype'},
                    outtype => $tbl{'outtype'});
      %test      = (varcol  => '%s eq %s',
                    intype  => '%s eq %s',
                    outtype => '%s eq %s');
   }
   else {
      $tbl{'outtype'} = 'varchar';
      %expectcol = (varcol  => '\(HSAH$',
                    intype  => 'varchar',
                    outtype => $tbl{'outtype'});
      %expectpar = (varcol  => '^HASH\(',
                    intype  => $expectcol{'intype'},
                    outtype => $tbl{'outtype'});
      %test      = (varcol  => '%s =~ %s',
                    intype  => '%s eq %s',
                    outtype => '%s eq %s');
   }
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   do_tests($X, 0, 'sql_variant', 'time hash/datetime regional');

   $X->{DatetimeOption} = DATETIME_HASH;
   %tbl       = (varcol  => '19961021',
                 intype  => undef,
                 outtype => 'date');
   if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
      %expectcol = (varcol  => {Year => 1996, Month => 9, Day => 1},
                    intype  => 'varchar',
                    outtype => $tbl{'outtype'});
      %expectpar = (varcol  => {Year => 2006, Month => 10, Day => 21},
                    intype  => $expectcol{'intype'},
                    outtype => $tbl{'outtype'});
   }
   else {
      %expectcol = (varcol  => '1996-09-01',
                    intype  => 'varchar',
                    outtype => $tbl{'outtype'});
      %expectpar = (varcol  => '2006-10-21',
                    intype  => $expectcol{'intype'},
                    outtype => $tbl{'outtype'});
   }
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
      %test      = (varcol  => 'datehash_compare(%s, %s)',
                    intype  => '%s eq %s',
                    outtype => '%s eq %s');
   }
   else {
      %test      = (varcol  => '%s eq %s',
                    intype  => '%s eq %s',
                    outtype => '%s eq %s');
   }
   do_tests($X, 0, 'sql_variant', 'date iso/hash');

   $X->{TZOffset} = '+08:00';
   %tbl       = (varcol  => '19961021 14:16',
                 intype  => undef,
                 outtype => 'datetimeoffset');
   if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
      %expectcol = (varcol  => {Year => 1996, Month => 9, Day => 1, Hour => 22,
                                Minute => 16, Second => 0, Fraction => 0},
                    intype  => 'varchar',
                    outtype => $tbl{'outtype'});
      %expectpar = (varcol  => {Year => 1996, Month => 10, Day => 22, Hour => 8,
                                Minute => 16, Second => 0, Fraction => 0},
                    intype  => $expectcol{'intype'},
                    outtype => $tbl{'outtype'});
   }
   else {
      %expectcol = (varcol  => '1996-09-01 14:16:00 +00:00',
                    intype  => 'varchar',
                    outtype => $tbl{'outtype'});
      %expectpar = (varcol  => '1996-10-22 00:16:00.0000000 +00:00',
                    intype  => $expectcol{'intype'},
                    outtype => $tbl{'outtype'});
   }
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
      %test      = (varcol  => 'datehash_compare(%s, %s)',
                    intype  => '%s eq %s',
                    outtype => '%s eq %s');
   }
   else {
      %test      = (varcol  => '%s eq %s',
                    intype  => '%s eq %s',
                    outtype => '%s eq %s');
   }
   do_tests($X, 0, 'sql_variant', 'datetimeoffset (tzoffset) iso/hash');
   undef $X->{TZOffset};

   $X->{DatetimeOption} = DATETIME_ISO;
   %tbl       = (varcol  => '14:16:20.7654321',
                 intype  => undef,
                 outtype => 'time');
   %expectcol = (varcol  => '14:16:20.76538',
                 intype  => 'varchar',
                 outtype => $tbl{'outtype'});
   %expectpar = (varcol  => '00:16:20.7654321',
                 intype  => $expectcol{'intype'},
                 outtype => $tbl{'outtype'});
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   %test      = (varcol  => '%s eq %s',
                 intype  => '%s eq %s',
                 outtype => '%s eq %s');
   do_tests($X, 0, 'sql_variant', 'time iso');
}
else {
   # For lower versions, test that hashes always interpreted as datetime.
   $X->{DatetimeOption} = DATETIME_ISO;
   %tbl       = (varcol  => {Year => 1996, Month => 10, Day => 21},
                 intype  => undef,
                 outtype => 'smalldatetime');
   %expectcol = (varcol  => '1996-09-01 00:00',
                 intype  => 'datetime',
                 outtype => $tbl{'outtype'});
   %expectpar = (varcol  => '1996-10-21 10:00',
                 intype  => $expectcol{'intype'},
                 outtype => $tbl{'outtype'});
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   %test      = (varcol  => '%s eq %s',
                 intype  => '%s eq %s',
                 outtype => '%s eq %s');
   do_tests($X, 0, 'sql_variant', 'date hash pre-SQL 2008');

   %tbl       = (varcol  => {Year => 1996, Month => 10, Day => 21,
                             Hour => 14, Minute => 16, Second => 23,
                             Fraction => 12.23, TZHour => 9},
                 intype  => undef,
                 outtype => 'smalldatetime');
   %expectcol = (varcol  => '1996-09-01 14:16',
                 intype  => 'datetime',
                 outtype => $tbl{'outtype'});
   %expectpar = (varcol  => '1996-10-22 00:16',
                 intype  => $expectcol{'intype'},
                 outtype => $tbl{'outtype'});
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   %test      = (varcol  => '%s eq %s',
                 intype  => '%s eq %s',
                 outtype => '%s eq %s');
   do_tests($X, 0, 'sql_variant', 'datetimeoffset hash pre-SQL 2008');

   $X->{DatetimeOption} = DATETIME_REGIONAL;
   %tbl       = (varcol  => {Year => 1999, Month => 12, Day => 30,
                             Hour => 14, Minute => 16, Second => 23},
                 intype  => undef,
                 outtype => 'datetime');
   %expectcol = (varcol  => ISO_to_regional('1999-11-10 14:16:23'),
                 intype  => 'datetime',
                 outtype => $tbl{'outtype'});
   %expectpar = (varcol  => ISO_to_regional('1999-12-31 00:16:23'),
                 intype  => $expectcol{'intype'},
                 outtype => $tbl{'outtype'});
   %expectfile= (varcol  => "N'$tbl{'varcol'}'",
                 intype  => 'NULL',
                 outtype => "N'$tbl{'outtype'}'");
   %test      = (varcol  => '%s eq %s',
                 intype  => '%s eq %s',
                 outtype => '%s eq %s');
   do_tests($X, 0, 'sql_variant', 'time hash pre-SQL 2008');
}

# Finally some tests with incomplete datetime hases.
%tbl       = (varcol  => {Year => 1999, Month => 12,
                          Hour => 14, Minute => 16, Second => 23},
              intype  => undef,
              outtype => 'varchar');
%expectcol = (varcol  => '\(HSAH$',
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => '^HASH\(',
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s =~ %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'Incomplete date-time hash1');

%tbl       = (varcol  => {Year => 1999, Day => 12,
                          Hour => 14, Minute => 16, Second => 23},
              intype  => undef,
              outtype => 'varchar');
%expectcol = (varcol  => '\(HSAH$',
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => '^HASH\(',
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s =~ %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'Incomplete date-time hash2');

%tbl       = (varcol  => {Month => 12, Day => 12},
              intype  => undef,
              outtype => 'varchar');
%expectcol = (varcol  => '\(HSAH$',
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => '^HASH\(',
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s =~ %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'Incomplete date-time hash3');

%tbl       = (varcol  => {Hour => 12, Second => 12},
              intype  => undef,
              outtype => 'varchar');
%expectcol = (varcol  => '\(HSAH$',
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => '^HASH\(',
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s =~ %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'Incomplete date-time hash4');

%tbl       = (varcol  => {Minute => 12, Second => 12},
              intype  => undef,
              outtype => 'varchar');
%expectcol = (varcol  => '\(HSAH$',
              intype  => 'varchar',
              outtype => $tbl{'outtype'});
%expectpar = (varcol  => '^HASH\(',
              intype  => $expectcol{'intype'},
              outtype => $tbl{'outtype'});
%expectfile= (varcol  => "N'$tbl{'varcol'}'",
              intype  => 'NULL',
              outtype => "N'$tbl{'outtype'}'");
%test      = (varcol  => '%s =~ %s',
              intype  => '%s eq %s',
              outtype => '%s eq %s');
do_tests($X, 0, 'sql_variant', 'Incomplete date-time hash5');


drop_test_objects('sql_variant');

#-------------------------- (N)VARCHAR MAX -----------------------------
# From here we're SQL 2005 and up only.
goto finally if $sqlver == 8;

clear_test_data;
create_varcharmax;

# When we run with SQLOLEDB, the (MAX) will be passed forth and back
# as (8000) or (4000).
%tbl       = (varcharcol   => 'Hello Dolly! ' x 2000,
              nvarcharcol  => "21 pa\x{017A}dziernika 2004 " x 2000);
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
   %expectcol = (varcharcol  => ' !ylloD olleH' x 2000,
                 nvarcharcol => " 4002 akinreizd\x{017A}ap 12" x 2000);
   %expectpar = (varcharcol  => 'HELLO DOLLY! ' x 2000 . 'UPPER',
                 nvarcharcol => "21 PA\x{0179}DZIERNIKA 2004 " x 2000 . 'UPPER');
   %test      = (varcharcol  => '%s eq %s',
                 nvarcharcol => '%s eq %s');
}
else {
   %expectcol = (varcharcol   => '('   . 'olleH' . ' !ylloD olleH' x 615 .
                                 ')|(' . ' !ylloD olleH' x 2000 . ')',
                 nvarcharcol  => '(' . "eizd\x{017A}ap 12" .
                                       " 4002 akinreizd\x{017A}ap 12" x 190 .
                                 ')|(' . " 4002 akinreizd\x{017A}ap 12" x 2000 . ')');
   %expectpar = (varcharcol   => 'HELLO DOLLY! ' x 615 . 'HELLO',
                 nvarcharcol  => "21 PA\x{0179}DZIERNIKA 2004 " x 190 .
                                 "21 PA\x{0179}DZIE");
   %test      = (varcharcol   => '%s =~ /^%s$/',
                 nvarcharcol  => '%s =~ /^%s$/');
}
do_tests($X, 1, 'varcharmax');


%tbl       = (varcharcol   => '',
              nvarcharcol  => '');
%expectcol = (varcharcol   => '',
              nvarcharcol  => '');
%expectpar = (varcharcol   => 'UPPER',
              nvarcharcol  => 'UPPER');
%test      = (varcharcol   => '%s eq %s',
              nvarcharcol  => '%s eq %s');
do_tests($X, 1, 'varcharmax', 'empty string');

%tbl       = (varcharcol   => undef,
              nvarcharcol  => '   ');
%expectcol = (varcharcol   => undef,
              nvarcharcol  => '   ');
%expectpar = (varcharcol   => undef,
              nvarcharcol  => '   ' . 'UPPER');
%test      = (varcharcol   => 'not defined %s',
              nvarcharcol  => '%s eq %s');
do_tests($X, 1, 'varcharmax', 'null');

drop_test_objects('varcharmax');

#-------------------------- (N)VARBINARY MAX -----------------------------

clear_test_data;
create_varbinmax;

# When we run with SQLOLEDB, the (MAX) will be passed forth and back
# as (8000) or (4000).
$X->{BinaryAsStr} = 1;
%tbl       = (varbincol    => '47119660AB0102' x 10000);
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
   %expectcol = (varbincol    => '0201AB60961147' x 10000);
   %expectpar = (varbincol    => '47119660AB0102' x 20000);
   %test      = (varbincol    => '%s eq %s');
}
else {
   %expectcol = (varbincol    => '(' . '01AB60961147' . '0201AB60961147' x 1142 .
                                 ')|(' . '0201AB60961147' x 10000 . ')');
   %expectpar = (varbincol    => '47119660AB0102' x 1142 . '47119660AB01');
   %test      = (varbincol    => '%s =~ /^%s$/');
}
do_tests($X, 1, 'varbinmax', 'as str');

%tbl       = (varbincol    => '0x');
%expectcol = (varbincol    => '');
%expectpar = (varbincol    => '');
%test      = (varbincol    => '%s eq %s');
do_tests($X, 1, 'varbinmax', 'empty string');

$X->{BinaryAsStr} = 'x';
%tbl       = (varbincol    => '0x' . '47119660AB0102' x 10000);
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
   %expectcol = (varbincol    => '0x' . '0201AB60961147' x 10000);
   %expectpar = (varbincol    => '0x' . '47119660AB0102' x 20000);
   %test      = (varbincol    => '%s eq %s');
}
else {
   %expectcol = (varbincol    => '0x' .
                                 '(' . '01AB60961147' . '0201AB60961147' x 1142 .
                                 ')|(' . '0201AB60961147' x 10000 . ')');
   %expectpar = (varbincol    => '0x' . '47119660AB0102' x 1142 . '47119660AB01');
   %test      = (varbincol    => '%s =~ /^%s$/');
}
do_tests($X, 1, 'varbinmax', '0x');

%tbl       = (varbincol    => '');
%expectcol = (varbincol    => '0x');
%expectpar = (varbincol    => '0x');
%test      = (varbincol    => '%s eq %s');
do_tests($X, 1, 'varbinmax', 'empty 0x');

$X->{BinaryAsStr} = 0;
%tbl       = (varbincol    => '47119660AB0102' x 10000);
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
   %expectcol = (varbincol    => '2010BA06691174' x 10000);
   %expectpar = (varbincol    => '47119660AB0102' x 20000);
   %test      = (varbincol    => '%s eq %s');
}
else {
   %expectcol = (varbincol    => '(' . '691174' . '2010BA06691174' x 571 .
                                 ')|(' . '2010BA06691174' x 10000 . ')');
   %expectpar = (varbincol    => '47119660AB0102' x 571 . '471196');
   %test      = (varbincol    => '%s =~ /^%s$/');
}
do_tests($X, 1, 'varbinmax', 'binary');

%tbl       = (varbincol    => '');
%expectcol = (varbincol    => '');
%expectpar = (varbincol    => '');
%test      = (varbincol    => '%s eq %s');
do_tests($X, 1, 'varbinmax', 'empty bin');


%tbl       = (varbincol    => undef);
%expectcol = (varbincol    => undef);
%expectpar = (varbincol    => undef);
%test      = (varbincol    => 'not defined %s');
do_tests($X, 1, 'varbinmax', 'null');

drop_test_objects('varbinmax');

#------------------------------- UDT -----------------------------------
# We cannot do UDT tests, if the CLR is not enabled on the server.
udt:
my $clr_enabled = sql_one(<<SQLEND, Win32::SqlServer::SCALAR);
SELECT value
FROM   sys.configurations
WHERE  name = 'clr enabled'
SQLEND
# At this point we must turn on ANSI_WARNINGS, to get the XML stuff to
# work.
$X->sql("SET ANSI_WARNINGS ON");

goto no_udt if not $clr_enabled;

clear_test_data;
create_UDT1($X, $X->{Provider} >= PROVIDER_SQLNCLI);

$X->{BinaryAsStr} = 'x';
%tbl       = (cmplxcol  => '0x800000058000000700',
              pointcol  => '0x01800000098000000480000005',
              stringcol => '0x00050000004E69737365',
              xmlcol    => '<root>input</root>');
%expectcol = (cmplxcol  => '0x800000078000000500',
              pointcol  => '0x0180000012800000088000000A',
              stringcol => '0x0005000000657373694E',
              xmlcol    => '<root>input trigger text</root>');
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
   %expectpar = (cmplxcol  => '0x8000000A8000000E00',
                 pointcol  => '0x01800000048000000580000009',
                 stringcol => '0x000A0000004E495353455550504552',
                 xmlcol    => '<root>input procedure text</root>');
}
else {
   %expectpar = ();
}
%test      = (cmplxcol  => '%s eq %s',
              pointcol  => '%s eq %s',
              stringcol => '%s eq %s',
              xmlcol    => '%s eq %s');
do_tests($X, 1, 'UDT1', 'Bin 0x');

$X->{BinaryAsStr} = 1;
%tbl       = (cmplxcol  => '0x800000058000000700',
              pointcol  => '0x01800000098000000480000005',
              stringcol => '00A00F0000' . '4E69737365' x 800,
              xmlcol    => '<root>input</root>');
%expectcol = (cmplxcol  => '800000078000000500',
              pointcol  => '0180000012800000088000000A',
              stringcol => '00A00F0000' . '657373694E' x 800,
              xmlcol    => '<root>input trigger text</root>');
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
   %expectpar = (cmplxcol  => '8000000A8000000E00',
                 pointcol  => '01800000048000000580000009',
                 stringcol => '00A00F0000' . '4E49535345' x 800,
                 xmlcol    => '<root>input procedure text</root>');
}
else {
   %expectpar = ();
}
%test      = (cmplxcol  => '%s eq %s',
              pointcol  => '%s eq %s',
              stringcol => '%s eq %s',
              xmlcol    => '%s eq %s');
do_tests($X, 1, 'UDT1', 'BinAsStr');

$X->{BinaryAsStr} = 0;
%tbl       = (cmplxcol  => pack('H*', '800000058000000700'),
              pointcol  => pack('H*', '01800000098000000480000005'),
              stringcol => pack('H*', '00050000004E69737365'),
              xmlcol    => '<root>input</root>');
%expectcol = (cmplxcol  => pack('H*', '800000078000000500'),
              pointcol  => pack('H*', '0180000012800000088000000A'),
              stringcol => pack('H*', '0005000000657373694E'),
              xmlcol    => '<root>input trigger text</root>');
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
   %expectpar = (cmplxcol  => pack('H*', '8000000A8000000E00'),
                 pointcol  => pack('H*', '01800000048000000580000009'),
                 stringcol => pack('H*', '000A0000004E495353455550504552'),
                 xmlcol    => '<root>input procedure text</root>');
}
else {
   %expectpar = ();
}
%test      = (cmplxcol  => '%s eq %s',
              pointcol  => '%s eq %s',
              stringcol => '%s eq %s',
              xmlcol    => '%s eq %s');
do_tests($X, 1, 'UDT1', 'BinaryAsBinary');


%tbl       = (cmplxcol  => undef,
              pointcol  => undef,
              stringcol => undef,
              xmlcol    => undef);
%expectcol = (cmplxcol  => undef,
              pointcol  => undef,
              stringcol => undef,
              xmlcol    => undef);
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
   %expectpar = (cmplxcol  => undef,
                 pointcol  => undef,
                 stringcol => undef,
                 xmlcol    => undef);
}
else {
   %expectpar = ();
}
%test      = (cmplxcol  => 'not defined %s',
              pointcol  => 'not defined %s',
              stringcol => 'not defined %s',
              xmlcol    => 'not defined %s');
do_tests($X, 1, 'UDT1', '0x, NULL');


clear_test_data;
create_UDT2($X, $X->{Provider} >= PROVIDER_SQLNCLI);

$X->{BinaryAsStr} = 'x';
%tbl       = (cmplxcol  => '0x800000058000000700',
              intcol    => 15,
              stringcol => '0x0000000000');
%expectcol = (cmplxcol  => '0x800000078000000500',
              intcol    => 30,
              stringcol => '0x0000000000');
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
   %expectpar = (cmplxcol  => '0x8000000A8000000E00',
                 intcol    => 106,
                 stringcol => '0x0000000000');
}
else {
   %expectpar = ();
}
%test      = (cmplxcol  => '%s eq %s',
              intcol    => '%s eq %s',
              stringcol => '%s eq %s',
              xmlcol    => '%s eq %s');
do_tests($X, 1, 'UDT2', 'Bin0x');

clear_test_data;
create_UDT3($X, $X->{Provider} >= PROVIDER_SQLNCLI);
$X->{BinaryAsStr} = 1;
%tbl       = (xmlcol    => '<TEST>Lantliv</TEST>',
              pointcol  => '0x01800000098000000480000005',
              nollcol   => 0);
%expectcol = (xmlcol    => '<TEST>Lantliv trigger text</TEST>',
              pointcol  => '0180000012800000088000000A',
              nollcol   => 19);
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
   %expectpar = (xmlcol    => '<TEST>Lantliv procedure text</TEST>',
                 pointcol  => '01800000048000000580000009',
                 nollcol   => -9);
}
else {
   %expectpar = ();
}
%test      = (xmlcol    => '%s eq %s',
              pointcol  => '%s eq %s',
              nollcol   => 'abs(%s - %s) < 1E-9');
do_tests($X, 1, 'UDT3', 'Bin');

# We now test large UDTs.
goto drop_udts if $sqlver < 10;

# Skip testing large UDTs with SQLOLEDB since they don't go together at all.
goto drop_udts if $X->{Provider} == PROVIDER_SQLOLEDB;

clear_test_data;
create_UDTlarge($X, $X->{Provider} >= PROVIDER_SQLNCLI10);

%tbl       = (maxstringcol => '0x000D00000052C3A46B736DC3B67267C3A573');
%expectcol = (maxstringcol =>  '000D00000073C3A56772C3B66D736BC3A452');
if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
  %expectpar = (maxstringcol => '001200000052C3844B534DC3965247C385535550504552');
}
else {
   %expectpar = ();
}
%test      = (maxstringcol  => '%s eq %s');
do_tests($X, 1, 'UDTlarge', 'Short');

%tbl       = (maxstringcol => '0x00C8320000' .
                              ('52C3A46B736DC3B67267C3A573' x 1000));
%expectcol = (maxstringcol =>  '00C8320000' .
                              ('73C3A56772C3B66D736BC3A452' x 1000));
if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
  %expectpar = (maxstringcol => '00CD320000' .
                               ('52C3844B534DC3965247C38553' x 1000) .
                               '5550504552');
}
else {
   %expectpar = ();
}
%test      = (maxstringcol  => '%s eq %s');
do_tests($X, 1, 'UDTlarge', 'Long strings');


%tbl       = (maxstringcol => undef);
%expectcol = (maxstringcol =>  undef);
if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
  %expectpar = (maxstringcol => undef);
}
else {
   %expectpar = ();
}
%test      = (maxstringcol  => 'not defined %s');
do_tests($X, 1, 'UDTlarge', 'NULL');


drop_udts:

drop_test_objects('UDT1');
drop_test_objects('UDT2');
drop_test_objects('UDT3');
drop_test_objects('UDTlarge');

    sql(<<SQLEND);
    IF EXISTS (SELECT * FROM sys.xml_schema_collections WHERE name = 'OlleSC')
            DROP XML SCHEMA COLLECTION OlleSC
SQLEND
delete_the_udts($X);

no_udt:

#------------------------------- XML -----------------------------------
binmode(STDOUT, ':utf8:');
binmode(STDERR, ':utf8:');

clear_test_data;
create_xmltest($X, $X->{Provider} >= PROVIDER_SQLNCLI);

%tbl       = (xmlcol    => "<R\x{00C4}KSM\x{00D6}RG\x{00C5}S>" .
                           "21 pa\x{017A}dziernika 2004 " x 2000 .
                           "</R\x{00C4}KSM\x{00D6}RG\x{00C5}S>",
              xmlsccol  => ($is_latin1 
                              ? '<?xml version="1.0" encoding="iso-8859-1"?>' . "\n"
                              : '') . 
                            "<TÄST>" .
                            "Vi är alltid bäst i räksmörgåstäster! " x 1500 .
                            "</TÄST>\n<TÄST>I alla fall nästan alltid!</TÄST>",
              nvarcol   => "21 PA\x{0179}DZIERNIKA 2004 " x 2000,
              nvarsccol => "The naïve rôles coöperate with their résumés "
                           x 1000);
%expectcol = (xmlcol    => '<xmltest nvarcol\s*=\s*"' .
                           "21 PA\x{0179}DZIERNIKA 2004 " x 2000 . '"\s*/\s*>',
              xmlsccol  => '<TÄST>' .
                           "The naïve rôles coöperate with their résumés "
                           x 1000 . '</TÄST>',
              nvarcol   => $tbl{'xmlcol'},
              nvarsccol => "Vi är alltid bäst i räksmörgåstäster! " x 1500);
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
   %expectpar = (xmlcol   => '<row><Lågland>' .
                             "21 pa\x{017A}dziernika 2004 " x 2000 .
                             '</Lågland></row>',
                 xmlsccol => '<TÄST>' .
                             "THE NAÏVE RÔLES COÖPERATE WITH THEIR RÉSUMÉS "
                             x 1000 . '</TÄST>',
                 nvarcol  => "21 pa\x{017A}dziernika 2004 " x 2000 ,
                 nvarsccol=> "<TÄST>" .
                             "Vi är alltid bäst i räksmörgåstäster! " x 1500 .
                             "</TÄST><TÄST>I alla fall nästan alltid!</TÄST>");
}
else {
   %expectpar = ();
}
%test      = (xmlcol    => '%s =~ %s',
              xmlsccol  => '%s eq %s',
              nvarcol   => '%s eq %s',
              nvarsccol => '%s eq %s');
do_tests($X, 1, 'xmltest');


%tbl       = (xmlcol    => qq!<?xml version = "1.0"\tencoding =   "ucs-2"?>! .
                           "<R\x{00C4}KSM\x{00D6}RG\x{00C5}S>" .
                           "21 pa\x{017A}dziernika 2004 " .
                           "</R\x{00C4}KSM\x{00D6}RG\x{00C5}S>  ",
              xmlsccol  => '<?xml  version="1.0" encoding="UTF-8" ?>' . "\n" .
                            "<TÄST>" .
                            "Vi är alltid bäst i räksmörgåstäster! " .
                            "</TÄST>\n<TÄST>I alla fall nästan alltid!</TÄST>",
              nvarcol   => "   ",
              nvarsccol => 'undef');
%expectcol = (xmlcol    => '<xmltest nvarcol\s*=\s*"   "\s*/\s*>',
              xmlsccol  => '<TÄST>undef</TÄST>',
              nvarcol   => "<R\x{00C4}KSM\x{00D6}RG\x{00C5}S>" .
                           "21 pa\x{017A}dziernika 2004 " .
                           "</R\x{00C4}KSM\x{00D6}RG\x{00C5}S>",
              nvarsccol => "Vi är alltid bäst i räksmörgåstäster! ");
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
   %expectpar = (xmlcol   => '<row><Lågland>( |\&\#x20;){3,3}</Lågland></row>',
                 xmlsccol => '<TÄST>UNDEF</TÄST>',
                 nvarcol  => "21 pa\x{017A}dziernika 2004 ",
                 nvarsccol=> "<TÄST>" .
                             "Vi är alltid bäst i räksmörgåstäster! ".
                             "</TÄST><TÄST>I alla fall nästan alltid!</TÄST>");
}
else {
   %expectpar = ();
}
%test      = (xmlcol    => '%s =~ %s',
              xmlsccol  => '%s eq %s',
              nvarcol   => '%s eq %s',
              nvarsccol => '%s eq %s');
do_tests($X, 1, 'xmltest', 'take two');


%tbl       = (xmlcol    => '',
              xmlsccol  => '   ',
              nvarcol   => undef,
              nvarsccol => undef);
%expectcol = (xmlcol    => '<xmltest\s*/\s*>',
              xmlsccol  => '<TÄST/>',
              nvarcol   => undef,
              nvarsccol => undef);
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
   %expectpar = (xmlcol   => '<row\s*/\s*>',
                 xmlsccol => '<TÄST/>',
                 nvarcol  => undef,
                 nvarsccol=> undef);
}
else {
   %expectpar = ();
}
%test      = (xmlcol    => '%s =~ %s',
              xmlsccol  => '%s eq %s',
              nvarcol   => 'not defined %s',
              nvarsccol => 'not defined %s');
do_tests($X, 1, 'xmltest', 'empty strings');


drop_test_objects('xmltest');
    sql(<<SQLEND);
    IF EXISTS (SELECT * FROM sys.xml_schema_collections WHERE name = 'Olles SC')
            DROP XML SCHEMA COLLECTION [Olles SC]
SQLEND

#-------------------------- NEW DATE/TIME DATA TYPES -------------------
# From here it's only SQL 2008 and later.
goto finally if $sqlver < 10;

clear_test_data;
create_newdatetime($X);

# Get local timezone.
my $localtz;
{ my $now = time;
  my @localtime = localtime($now);
  my @UTC = gmtime($now);
  my $UTC_minutes = $UTC[2] * 60 + $UTC[1];
  my $localminutes = $localtime[2] * 60 + $localtime[1];
  my $offsetminutes = $localminutes - $UTC_minutes;
  my $localday = $localtime[5]*10000 + $localtime[4]*100 + $localtime[3];
  my $UTCday = $UTC[5]*10000 + $UTC[4]*100 + $UTC[3];
  if ($localday < $UTCday) {
     $offsetminutes -= 24 * 60;
  }
  elsif ($localday > $UTCday) {
     $offsetminutes += 24 * 60;
  }
  my $hour   = int($offsetminutes / 60);
  my $minute = $offsetminutes % 60;
  if ($hour < 0 and $minute != 0) {
        $minute = 60 - $minute;
  }
  $localtz = sprintf("%+2.2d:%2.2d", $hour, $minute);
}

$X->{DatetimeOption} = DATETIME_ISO;
%tbl       = (datecol       => '1996-08-13 17:36:24.998',
              time0col      => '1996-08-13 04:36:24.998',
              time7col      => '1996-08-13 04:36:24.998',
              datetime2col  => '1996-08-13 04:36:24.998   ',
              dtoffset1col  => '1996-08-13 04:36:24. 998',
              dtoffset7col  => '1996-08-13T04:36:24.998');
%expectcol = (datecol       => '1996-08-30',
              time0col      => '05:36:24',
              time7col      => '04:36:24.9980006',
              datetime2col  => '1996-08-13 04:36:24.999',
              dtoffset1col  => '1996-08-13 07:36:24.9 +00:00',
              dtoffset7col  => '1996-08-13 00:06:24.9980000 -04:30');
%expectpar = (datecol       => '2001-08-13',
              time0col      => '04:50:24',
              time7col      => '04:36:24.9982300',
              datetime2col  => '1996-08-15 04:36:24.998',
              dtoffset1col  => '1996-08-13 05:06:24.9 +00:00',
              dtoffset7col  => '1996-08-13 12:36:24.9980000 +08:00');
if ($X->{Provider} < PROVIDER_SQLNCLI10) {
   # Due to rounding issues we get different results with legacy providers
   # in some cases.
   $expectcol{'time0col'} = '05:36:25';
   $expectpar{'time0col'} = '04:50:25';
   $expectcol{'dtoffset1col'} = '1996-08-13 07:36:25.0 +00:00';
   $expectpar{'dtoffset1col'} = '1996-08-13 05:06:25.0 +00:00';
}
# Need different test for file, because SQL Server rounds, but we truncate.
%expectfile = (datecol      => "'1996-08-13 17:36:24.998'",
              time0col      => "'1996-08-13 04:36:24.998'",
              time7col      => "'1996-08-13 04:36:24.998'",
              datetime2col  => "'1996-08-13 04:36:24.998   '",
              dtoffset1col  => "'1996-08-13 04:36:24. 998'",
              dtoffset7col  => "'1996-08-13T04:36:24.998'");
%test      = (datecol      => '%s eq %s',
              time0col     => '%s eq %s',
              time7col     => '%s eq %s',
              datetime2col => '%s eq %s',
              dtoffset1col => '%s eq %s',
              dtoffset7col => '%s eq %s');
do_tests($X, 0, 'newdatetime', 'ISO in/out extra');

$X->{DatetimeOption} = DATETIME_ISO;
%tbl       = (datecol       => '   19960813',
              time0col      => '04:36:24 + 02 :00   ',
              time7col      => '4:36:24.9999994 + 02: 00',
              datetime2col  => '1996-8-1 04:36:24.998',
              dtoffset1col  => '1996-08-13 04:36:24.6 -03:30  ',
              dtoffset7col  => '19960813 04:36:24.1234567+03:00');
%expectcol = (datecol       => '1996-08-30',
              time0col      => '05:36:24',
              time7col      => '04:36:25.0000000',
              datetime2col  => '1996-08-01 04:36:24.999',
              dtoffset1col  => '1996-08-13 07:36:24.6 -03:30',
              dtoffset7col  => '1996-08-12 21:06:24.1234567 -04:30');
%expectpar = (datecol       => '2001-08-13',
              time0col      => '04:50:24',
              time7col      => '04:36:25.0002294',
              datetime2col  => '1996-08-03 04:36:24.998',
              dtoffset1col  => '1996-08-13 05:06:24.6 -03:30',
              dtoffset7col  => '1996-08-13 09:36:24.1234567 +08:00');
# Because there is no rounding, we can run the log file. For these types,
# SQL server never misinterprets YYYY-MM-DD.
undef %expectfile;
%test      = (datecol      => '%s eq %s',
              time0col     => '%s eq %s',
              time7col     => '%s eq %s',
              datetime2col => '%s eq %s',
              dtoffset1col => '%s eq %s',
              dtoffset7col => '%s eq %s');
do_tests($X, 1, 'newdatetime', 'ISO in/out offset');

$X->{DatetimeOption} = DATETIME_ISO;
%tbl       = (datecol       => undef,
              time0col      => undef,
              time7col      => undef,
              datetime2col  => undef,
              dtoffset1col  => undef,
              dtoffset7col  => undef);
%expectcol = (datecol       => undef,
              time0col      => undef,
              time7col      => undef,
              datetime2col  => undef,
              dtoffset1col  => undef,
              dtoffset7col  => undef);
%expectpar = (datecol       => undef,
              time0col      => undef,
              time7col      => undef,
              datetime2col  => undef,
              dtoffset1col  => undef,
              dtoffset7col  => undef);
%test      = (datecol      => 'not defined %s',
              time0col     => 'not defined %s',
              time7col     => 'not defined %s',
              datetime2col => 'not defined %s',
              dtoffset1col => 'not defined %s',
              dtoffset7col => 'not defined %s');
do_tests($X, 1, 'newdatetime', 'ISO in/out all NULL');


# With an older provider get off here. We have done tests with ISO, which
# is the only that works anyway.
goto done_newdatetime if $X->{Provider} < PROVIDER_SQLNCLI10;

$X->{TZOffset} = 'local';
%tbl       = (datecol       => '    0004-02-26',
              time0col      => '23: 12   :   12  ',
              time7col      => '14:36',
              datetime2col  => '1996-8-1   4:6:4',
              dtoffset1col  => "04:36:24 $localtz",
              dtoffset7col  => '1996-08-13 04:36:24.1234567');
%expectcol = (datecol       => '0004-03-14',
              time0col      => '00:12:12',
              time7col      => '14:36:00.0000006',
              datetime2col  => '1996-08-01 04:06:04.001',
              dtoffset1col  => '1899-12-30 07:36:24.0',
              dtoffset7col  => '1996-08-13 04:36:24.1234567');
%expectpar = (datecol       => '0009-02-26',
              time0col      => '23:26:12',
              time7col      => '14:36:00.0002300',
              datetime2col  => '1996-08-03 04:06:04.000',
              dtoffset1col  => '1899-12-30 05:06:24.0',
              dtoffset7col  => '1996-08-13 04:36:24.1234567');
# Can't run the log file, since the TZOffset feature does not work with
# the log file.
%expectfile = (datecol      => "'$tbl{'datecol'}'",
              time0col      => "'$tbl{'time0col'}'",
              time7col      => "'$tbl{'time7col'}'",
              datetime2col  => "'$tbl{'datetime2col'}'",
              dtoffset1col  => "'$tbl{'dtoffset1col'}'",
              dtoffset7col  => "'$tbl{'dtoffset7col'}'");
%test      = (datecol      => '%s eq %s',
              time0col     => '%s eq %s',
              time7col     => '%s eq %s',
              datetime2col => '%s eq %s',
              dtoffset1col => '%s eq %s',
              dtoffset7col => '%s eq %s');
do_tests($X, 0, 'newdatetime', 'ISO in/out offset local');


$X->{TZOffset} = '-08:00';
$X->{DatetimeOption} = DATETIME_HASH;
%tbl       = (datecol       => '0004-02-26 12:00',
              time0col      => '0:0',
              time7col      => '00:00:00.0000001',
              datetime2col  => '   1896-12-01T06:00',
              dtoffset1col  => "1996-08-13 04:36:24  +  1:0",
              dtoffset7col  => '1996-08-13 04:36:24.1234567');
%expectcol = (datecol       => {Year => 4, Month => 3, Day => 14},
              time0col      => {Hour => 1, Minute=> 0, Second => 0,
                                Fraction => 0},
              time7col      => {Hour => 0, Minute=> 0, Second => 0,
                                Fraction => 0.0007},
              datetime2col  => {Year => 1896, Month => 12, Day => 1,
                                Hour => 6, Minute=> 0, Second => 0,
                                Fraction => 1},
              dtoffset1col  => {Year => 1996, Month => 8, Day => 12,
                                Hour => 22, Minute=> 36, Second => 24,
                                Fraction => 0},
              dtoffset7col  => {Year => 1996, Month => 8, Day => 13,
                                Hour => 4, Minute=> 36, Second => 24,
                                Fraction => 123.4567});
%expectpar = (datecol       => {Year => 9, Month => 2, Day => 26},
              time0col      => {Hour => 0, Minute=> 14, Second => 0,
                                Fraction => 0},
              time7col      => {Hour => 0, Minute=> 0, Second => 0,
                                Fraction => 0.2301},
              datetime2col  => {Year => 1896, Month => 12, Day => 3,
                                Hour => 6, Minute=> 0, Second => 0,
                                Fraction => 0},
              dtoffset1col  => {Year => 1996, Month => 8, Day => 12,
                                Hour => 20, Minute=> 6, Second => 24,
                                Fraction => 0},
              dtoffset7col  => {Year => 1996, Month => 8, Day => 13,
                                Hour => 4, Minute=> 36, Second => 24,
                                Fraction => 123.4567});
# Can't run the log file, since the TZOffset feature does not work with
# the log file.
%expectfile = (datecol      => "'$tbl{'datecol'}'",
              time0col      => "'$tbl{'time0col'}'",
              time7col      => "'$tbl{'time7col'}'",
              datetime2col  => "'$tbl{'datetime2col'}'",
              dtoffset1col  => "'$tbl{'dtoffset1col'}'",
              dtoffset7col  => "'$tbl{'dtoffset7col'}'");
%test      = (datecol      => 'datehash_compare(%s, %s)',
              time0col     => 'datehash_compare(%s, %s)',
              time7col     => 'datehash_compare(%s, %s)',
              datetime2col => 'datehash_compare(%s, %s)',
              dtoffset1col => 'datehash_compare(%s, %s)',
              dtoffset7col => 'datehash_compare(%s, %s)');
do_tests($X, 0, 'newdatetime', 'ISO in, hash out, offset explicit');


$X->{TZOffset} = '-02:45';
$X->{DatetimeOption} = DATETIME_HASH;
%tbl       = (datecol       => {Year => 2005, Month => 12, Day => 31},
              time0col      => {Hour => 0, Minute => 0},
              time7col      => {Hour => 23, Minute => 59, Second => 59,
                                Fraction => 999.9999},
              datetime2col  => {Year => 2005, Month => 12, Day => 31},
              dtoffset1col  => {Year => 1996, Month => 8, Day => 13,
                                Hour => 4, Minute => 36, Second => 24,
                                Fraction => 123, TZHour => 4, TZMinute => 30},
              dtoffset7col  => {Year => 1996, Month => 8, Day => 13,
                                Hour => 4, Minute => 36, Second => 24});
%expectcol = (datecol       => {Year => 2006, Month => 1, Day => 17},
              time0col      => {Hour => 1, Minute=> 0, Second => 0,
                                Fraction => 0},
              time7col      => {Hour => 0, Minute=> 0, Second => 0,
                                Fraction => 0.0005},
              datetime2col  => {Year => 2005, Month => 12, Day => 31,
                                Hour => 0, Minute=> 0, Second => 0,
                                Fraction => 1},
              dtoffset1col  => {Year => 1996, Month => 8, Day => 13,
                                Hour => 0, Minute=> 21, Second => 24,
                                Fraction => 100},
              dtoffset7col  => {Year => 1996, Month => 8, Day => 13,
                                Hour => 4, Minute=> 36, Second => 24,
                                Fraction => 0});
%expectpar = (datecol       => {Year => 2010, Month => 12, Day => 31},
              time0col      => {Hour => 0, Minute=> 14, Second => 0,
                                Fraction => 0},
              time7col      => {Hour => 0, Minute=> 0, Second => 0,
                                Fraction => 0.2299},
              datetime2col  => {Year => 2006, Month => 1, Day => 2,
                                Hour => 0, Minute=> 0, Second => 0,
                                Fraction => 0},
              dtoffset1col  => {Year => 1996, Month => 8, Day => 12,
                                Hour => 21, Minute=> 51, Second => 24,
                                Fraction => 100},
              dtoffset7col  => {Year => 1996, Month => 8, Day => 13,
                                Hour => 4, Minute=> 36, Second => 24,
                                Fraction => 0});
# For HASH the file test is really stupid.
%expectfile= (datecol      => "^'HASH\\(",
              time0col     => "^'HASH\\(",
              time7col     => "^'HASH\\(",
              datetime2col => "^'HASH\\(",
              dtoffset1col => "^'HASH\\(",
              dtoffset7col => "^'HASH\\(");
%filetest  = (datecol      => '%s =~ /%s/',
              time0col     => '%s =~ /%s/',
              time7col     => '%s =~ /%s/',
              datetime2col => '%s =~ /%s/',
              dtoffset1col => '%s =~ /%s/',
              dtoffset7col => '%s =~ /%s/');
%test      = (datecol      => 'datehash_compare(%s, %s)',
              time0col     => 'datehash_compare(%s, %s)',
              time7col     => 'datehash_compare(%s, %s)',
              datetime2col => 'datehash_compare(%s, %s)',
              dtoffset1col => 'datehash_compare(%s, %s)',
              dtoffset7col => 'datehash_compare(%s, %s)');
do_tests($X, 0, 'newdatetime', 'hash in/out, offset explicit');


$X->{TZOffset} = '+02:00';
$X->{DatetimeOption} = DATETIME_FLOAT;
%tbl       = (datecol       => {Year => 2005, Month => 12, Day => 31},
              time0col      => {Hour => 5, Minute => 0},
              time7col      => {Hour => 18, Minute => 0, Second => 0,
                                Fraction => 0},
              datetime2col  => {Year => 2005, Month => 12, Day => 31,
                                Hour => 12},
              dtoffset1col  => {Year => 1996, Month => 8, Day => 13,
                                Hour => 18, Minute => 0, Second => 0,
                                Fraction => 0, TZHour => -1},
              dtoffset7col  => {Year => 1996, Month => 8, Day => 13,
                                Hour => 18, Minute => 0, Second => 0});
%expectcol = (datecol       => 38734,
              time0col      => 0.25,
              time7col      => 0.75,
              datetime2col  => 38717.5 + 0.001/86400,
              dtoffset1col  => 35291,
              dtoffset7col  => 35290.75);
%expectpar = (datecol       => 40543,
              time0col      => (5 * 60 + 14)/(60*24),
              time7col      => 0.75,
              datetime2col  => 38719.5,
              dtoffset1col  => 35290 + 21.5/24,
              dtoffset7col  => 35290.75);
# For HASH the file test is really stupid.
%expectfile= (datecol      => "^'HASH\\(",
              time0col     => "^'HASH\\(",
              time7col     => "^'HASH\\(",
              datetime2col => "^'HASH\\(",
              dtoffset1col => "^'HASH\\(",
              dtoffset7col => "^'HASH\\(");
%filetest  = (datecol      => '%s =~ /%s/',
              time0col     => '%s =~ /%s/',
              time7col     => '%s =~ /%s/',
              datetime2col => '%s =~ /%s/',
              dtoffset1col => '%s =~ /%s/',
              dtoffset7col => '%s =~ /%s/');
%test      = (datecol      => 'abs(%s - %s) < 1E-9',
              time0col     => 'abs(%s - %s) < 1E-9',
              time7col     => 'abs(%s - %s) < 1E-9',
              datetime2col => 'abs(%s - %s) < 1E-9',
              dtoffset1col => 'abs(%s - %s) < 1E-9',
              dtoffset7col => 'abs(%s - %s) < 1E-9');
do_tests($X, 0, 'newdatetime', 'hash in/ float out, no offset');

$X->{TZOffset} = undef;
$X->{DatetimeOption} = DATETIME_FLOAT;
%tbl       = (datecol       => {Year => 2005, Month => 12, Day => 31,
                                Hour => 12, Minute => 14},
              time0col      => {Year => 2005, Month => 12, Day => 31,
                                Hour => 5, Minute => 0},
              time7col      => {Hour => 18, Minute => 0, Second => 0,
                                Fraction => 0},
              datetime2col  => {Year => 1895, Month => 12, Day => 31,
                                Hour => 6},
              dtoffset1col  => {Year => 1996, Month => 8, Day => 13,
                                Hour => 18, Minute => 0, Second => 0,
                                Fraction => 0, TZHour => -1},
              dtoffset7col  => {Year => 1996, Month => 8, Day => 13,
                                Hour => 18, Minute => 0, Second => 0,
                                TZHour => 8, TZMinute => 0});
%expectcol = (datecol       => 38734,
              time0col      => 0.25,
              time7col      => 0.75,
              datetime2col  => -1460.25 - 0.001/86400,
              dtoffset1col  => 35290 + 21/24,
              dtoffset7col  => 35290 + 5.5/24);
%expectpar = (datecol       => 40543,
              time0col      => (5 * 60 + 14)/(60*24),
              time7col      => 0.75,
              datetime2col  => -1458.25,
              dtoffset1col  => 35290 + 18.5/24,
              dtoffset7col  => 35290.75);
# For HASH the file test is really stupid.
%expectfile= (datecol      => "^'HASH\\(",
              time0col     => "^'HASH\\(",
              time7col     => "^'HASH\\(",
              datetime2col => "^'HASH\\(",
              dtoffset1col => "^'HASH\\(",
              dtoffset7col => "^'HASH\\(");
%filetest  = (datecol      => '%s =~ /%s/',
              time0col     => '%s =~ /%s/',
              time7col     => '%s =~ /%s/',
              datetime2col => '%s =~ /%s/',
              dtoffset1col => '%s =~ /%s/',
              dtoffset7col => '%s =~ /%s/');
%test      = (datecol      => 'abs(%s - %s) < 1E-9',
              time0col     => 'abs(%s - %s) < 1E-9',
              time7col     => 'abs(%s - %s) < 1E-9',
              datetime2col => 'abs(%s - %s) < 1E-9',
              dtoffset1col => 'abs(%s - %s) < 1E-9',
              dtoffset7col => 'abs(%s - %s) < 1E-9');
do_tests($X, 0, 'newdatetime', 'hash in/ float out, no offset');

$X->{DatetimeOption} = DATETIME_HASH;
%tbl       = (datecol       => 38717,
              time0col      => 0,
              time7col      => 12.75,
              datetime2col  => -364.75,
              dtoffset1col  => 38717.25,
              dtoffset7col  => 38717.25);
%expectcol = (datecol       => {Year => 2006, Month => 1, Day => 17},
              time0col      => {Hour => 1, Minute=> 0, Second => 0,
                                Fraction => 0},
              time7col      => {Hour => 18, Minute=> 0, Second => 0,
                                Fraction => 0.0006},
              datetime2col  => {Year => 1898, Month => 12, Day => 31,
                                Hour => 18, Minute=> 0, Second => 0,
                                Fraction => 1},
              dtoffset1col  => {Year => 2005, Month => 12, Day => 31,
                                Hour => 9, Minute => 0, Second => 0,
                                Fraction => 0, TZHour => 0, TZMinute => 0},
              dtoffset7col  => {Year => 2005, Month => 12, Day => 31,
                                Hour => 1, Minute=> 30, Second => 0,
                                Fraction => 0, TZHour => -4, TZMinute => -30});
%expectpar = (datecol       => {Year => 2010, Month => 12, Day => 31},
              time0col      => {Hour => 0, Minute=> 14, Second => 0,
                                Fraction => 0},
              time7col      => {Hour => 18, Minute=> 0, Second => 0,
                                Fraction => 0.23},
              datetime2col  => {Year => 1899, Month => 1, Day => 2,
                                Hour => 18, Minute=> 0, Second => 0,
                                Fraction => 0},
              dtoffset1col  => {Year => 2005, Month => 12, Day => 31,
                                Hour => 6, Minute=> 30, Second => 0,
                                Fraction => 0, TZHour => 0, TZMinute => 0},
              dtoffset7col  => {Year => 2005, Month => 12, Day => 31,
                                Hour => 14, Minute=> 0, Second => 0,
                                Fraction => 0, TZHour => 8, TZMinute => 0});
# We still cannot use the logfile, because floats does not convert to the
# new types.
%expectfile = (datecol      => "'$tbl{'datecol'}'",
              time0col      => "'$tbl{'time0col'}'",
              time7col      => "'$tbl{'time7col'}'",
              datetime2col  => "'$tbl{'datetime2col'}'",
              dtoffset1col  => "'$tbl{'dtoffset1col'}'",
              dtoffset7col  => "'$tbl{'dtoffset7col'}'");
%filetest  = (datecol      => "%s eq %s",
              time0col     => "%s eq %s",
              time7col     => "%s eq %s",
              datetime2col => "%s eq %s",
              dtoffset1col => "%s eq %s",
              dtoffset7col => "%s eq %s");
%test      = (datecol      => 'datehash_compare(%s, %s)',
              time0col     => 'datehash_compare(%s, %s)',
              time7col     => 'datehash_compare(%s, %s)',
              datetime2col => 'datehash_compare(%s, %s)',
              dtoffset1col => 'datehash_compare(%s, %s)',
              dtoffset7col => 'datehash_compare(%s, %s)');
do_tests($X, 0, 'newdatetime', 'float in, hash out');


$X->{DatetimeOption} = DATETIME_REGIONAL;
%tbl       = (datecol       => '   19960813',
              time0col      => '04:36:24 + 02 :00   ',
              time7col      => '4:36:24.9999994 + 02: 00',
              datetime2col  => '1996-8-1 04:36:24.998',
              dtoffset1col  => '1996-08-13 04:36:24.6 -03:30  ',
              dtoffset7col  => '19960813 04:36:24.1234567+03:00');
%expectcol = (datecol       => ISO_to_regional('1996-08-30'),
              time0col      => ISO_to_regional('05:36:24'),
              time7col      => ISO_to_regional('04:36:25'),
              datetime2col  => ISO_to_regional('1996-08-01 04:36:25'),
              dtoffset1col  => ISO_to_regional('1996-08-13 07:36:25 -03:30'),
              dtoffset7col  => ISO_to_regional('1996-08-12 21:06:24 -04:30'));
%expectpar = (datecol       => ISO_to_regional('2001-08-13'),
              time0col      => ISO_to_regional('04:50:24'),
              time7col      => ISO_to_regional('04:36:25'),
              datetime2col  => ISO_to_regional('1996-08-03 04:36:25'),
              dtoffset1col  => ISO_to_regional('1996-08-13 05:06:25 -03:30'),
              dtoffset7col  => ISO_to_regional('1996-08-13 09:36:24 +08:00'));
# We get an occasion to run the log file.
undef %expectfile;
undef %filetest;
%test      = (datecol      => '%s eq %s',
              time0col     => '%s eq %s',
              time7col     => '%s eq %s',
              datetime2col => '%s eq %s',
              dtoffset1col => '%s eq %s',
              dtoffset7col => '%s eq %s');
do_tests($X, 1, 'newdatetime', 'ISO in regional out');

$X->{DatetimeOption} = DATETIME_REGIONAL;
$X->{TZOffset} = '+05:30';
%tbl       = (datecol       => '19960813',
              time0col      => '14:36:24',
              time7col      => '14:36:24',
              datetime2col  => '1996-12-31 14:36:24.998',
              dtoffset1col  => '1996-08-13 14:36:24 -03 : 30',
              dtoffset7col  => '19960813 14:36:24 +03:00');
%expectcol = (datecol       => ISO_to_regional('1996-08-30'),
              time0col      => ISO_to_regional('15:36:24'),
              time7col      => ISO_to_regional('14:36:24'),
              datetime2col  => ISO_to_regional('1996-12-31 14:36:25'),
              dtoffset1col  => ISO_to_regional('1996-08-14 02:36:24'),
              dtoffset7col  => ISO_to_regional('1996-08-13 17:06:24'));
%expectpar = (datecol       => ISO_to_regional('2001-08-13'),
              time0col      => ISO_to_regional('14:50:24'),
              time7col      => ISO_to_regional('14:36:24'),
              datetime2col  => ISO_to_regional('1997-01-02 14:36:25'),
              dtoffset1col  => ISO_to_regional('1996-08-14 00:06:24'),
              dtoffset7col  => ISO_to_regional('1996-08-13 17:06:24'));
# We get an occasion to run the log file.
undef %expectfile;
undef %filetest;
%test      = (datecol      => '%s eq %s',
              time0col     => '%s eq %s',
              time7col     => '%s eq %s',
              datetime2col => '%s eq %s',
              dtoffset1col => '%s eq %s',
              dtoffset7col => '%s eq %s');
do_tests($X, 1, 'newdatetime', 'ISO in regional out, offset explicit');


$X->{DatetimeOption} = DATETIME_ISO;
$X->{TZOffset} = '+05:30';
%tbl       = (datecol       => ISO_to_regional('1996-08-13'),
              time0col      => ISO_to_regional('14:36:00'),
              time7col      => ISO_to_regional('00:36:24'),
              datetime2col  => ISO_to_regional('1996-12-31 14:36:24'),
              dtoffset1col  => ISO_to_regional('1996-08-13 14:36:24 -03 : 30'),
              dtoffset7col  => ISO_to_regional('1996-08-13 14:36:24 +03:00'));
%expectcol = (datecol       => '1996-08-30',
              time0col      => '15:36:00',
              time7col      => '00:36:24.0000006',
              datetime2col  => '1996-12-31 14:36:24.001',
              dtoffset1col  => '1996-08-14 02:36:24.0',
              dtoffset7col  => '1996-08-13 17:06:24.0000000');
%expectpar = (datecol       => '2001-08-13',
              time0col      => '14:50:00',
              time7col      => '00:36:24.0002300',
              datetime2col  => '1997-01-02 14:36:24.000',
              dtoffset1col  => '1996-08-14 00:06:24.0',
              dtoffset7col  => '1996-08-13 17:06:24.0000000');
# No log file with regional dates.
undef %expectfile;
%expectfile = (datecol      => "'$tbl{'datecol'}'",
              time0col      => "'$tbl{'time0col'}'",
              time7col      => "'$tbl{'time7col'}'",
              datetime2col  => "'$tbl{'datetime2col'}'",
              dtoffset1col  => "'$tbl{'dtoffset1col'}'",
              dtoffset7col  => "'$tbl{'dtoffset7col'}'");
%test      = (datecol      => '%s eq %s',
              time0col     => '%s eq %s',
              time7col     => '%s eq %s',
              datetime2col => '%s eq %s',
              dtoffset1col => '%s eq %s',
              dtoffset7col => '%s eq %s');
do_tests($X, 0, 'newdatetime', 'Regional in/ISO out, offset explicit');


$X->{DatetimeOption} = DATETIME_ISO;
$X->{TZOffset} = undef;
%tbl       = (datecol       => ISO_to_regional('2096-08-13'),
              time0col      => ISO_to_regional('12:00:00'),
              time7col      => ISO_to_regional('00:36:24'),
              datetime2col  => ISO_to_regional('1996-12-31 14:36:24'),
              dtoffset1col  => ISO_to_regional('1996-08-13 14:36:24 -3:0'),
              dtoffset7col  => ISO_to_regional('1996-08-13 14:36:24+03:00'));
%expectcol = (datecol       => '2096-08-30',
              time0col      => '13:00:00',
              time7col      => '00:36:24.0000006',
              datetime2col  => '1996-12-31 14:36:24.001',
              dtoffset1col  => '1996-08-13 17:36:24.0 -03:00',
              dtoffset7col  => '1996-08-13 07:06:24.0000000 -04:30');
%expectpar = (datecol       => '2101-08-13',
              time0col      => '12:14:00',
              time7col      => '00:36:24.0002300',
              datetime2col  => '1997-01-02 14:36:24.000',
              dtoffset1col  => '1996-08-13 15:06:24.0 -03:00',
              dtoffset7col  => '1996-08-13 19:36:24.0000000 +08:00');
# No log file with regional dates.
undef %expectfile;
%expectfile = (datecol      => "'$tbl{'datecol'}'",
              time0col      => "'$tbl{'time0col'}'",
              time7col      => "'$tbl{'time7col'}'",
              datetime2col  => "'$tbl{'datetime2col'}'",
              dtoffset1col  => "'$tbl{'dtoffset1col'}'",
              dtoffset7col  => "'$tbl{'dtoffset7col'}'");
%test      = (datecol      => '%s eq %s',
              time0col     => '%s eq %s',
              time7col     => '%s eq %s',
              datetime2col => '%s eq %s',
              dtoffset1col => '%s eq %s',
              dtoffset7col => '%s eq %s');
do_tests($X, 0, 'newdatetime', 'Regional in/ISO out, no TZoffset');

$X->{DatetimeOption} = DATETIME_STRFMT;
$X->{DateFormat} = '%Y%m%d %H:%M:%S';
$X->{MsecFormat} = '.%3.3d';
$X->{TZOffset} = undef;
%tbl       = (datecol       => '2096-08-13',
              time0col      => '12:00:00',
              time7col      => '00:36:24',
              datetime2col  => '1996-12-31 14:36:24',
              dtoffset1col  => '1996-08-13 14:36:24 -3:0',
              dtoffset7col  => '1996-08-13 14:36:24+03:00');
%expectcol = (datecol       => '20960830 00:00:00',
              time0col      => '19000101 13:00:00',
              time7col      => '19000101 00:36:24.000',
              datetime2col  => '19961231 14:36:24.001',
              dtoffset1col  => '19960813 17:36:24.000',
              dtoffset7col  => '19960813 07:06:24.000');
%expectpar = (datecol       => '21010813 00:00:00',
              time0col      => '19000101 12:14:00',
              time7col      => '19000101 00:36:24.000',
              datetime2col  => '19970102 14:36:24.000',
              dtoffset1col  => '19960813 15:06:24.000',
              dtoffset7col  => '19960813 19:36:24.000');
undef %expectfile;
%test      = (datecol      => '%s eq %s',
              time0col     => '%s eq %s',
              time7col     => '%s eq %s',
              datetime2col => '%s eq %s',
              dtoffset1col => '%s eq %s',
              dtoffset7col => '%s eq %s');
do_tests($X, 1, 'newdatetime', 'ISO in/STRFMT out, no TZoffset');


done_newdatetime:
drop_test_objects('newdatetime');

#----------------------- hierarchyid ----------------------------------
clear_test_data;
create_hierarchy($X, $X->{Provider} >= PROVIDER_SQLNCLI);

$X->{BinaryAsStr} = '1';
%tbl       = (hiercol      => '0x5D5C1F');    # /1/10/23/
%expectcol = (hiercol      => '5D5C1F58');
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
  %expectpar = (hiercol      => '5D50');
}
else {
   %expectpar = ();
}
%test      = (hiercol       => '%s eq %s');
do_tests($X, 1, 'hierarchy', 'BinAsStr');

%tbl       = (hiercol      => undef);
%expectcol = (hiercol      => undef);
if ($X->{Provider} >= PROVIDER_SQLNCLI) {
  %expectpar = (hiercol      => undef);
}
else {
   %expectpar = ();
}
%test      = (hiercol       => 'not defined %s');
do_tests($X, 1, 'hierarchy', 'NULL');
drop_test_objects('hierarchy');

#--------------------------- Spatial datatypes -------------------------
# Since these are large UDT we can test these with SQLOLEDB.
goto done_spatial if $X->{Provider} == PROVIDER_SQLOLEDB;

clear_test_data;
create_spatial($X, $X->{Provider} >= PROVIDER_SQLNCLI10);

{ open(F, "../helpers/spatial.data.$sqlver") or warn "Could not read file 'spatial data': $!\n";
  my @file = <F>;
  close F;
  my ($geometry, $geometrycol, $geometrypar,
      $geography, $geographycol, $geographypar) = split(/\n/, join('', @file));

  $X->{BinaryAsStr} = 'x';
  %tbl =       (geometrycol  => $geometry,
                geographycol => $geography);
  %expectcol = (geometrycol  => $geometrycol,
                geographycol => $geographycol);
  if ($X->{Provider} >= PROVIDER_SQLNCLI10) {
     %expectpar = (geometrycol  => $geometrypar,
                   geographycol => $geographypar);
  }
  %test      = (geometrycol  => '%s eq %s',
                geographycol => '%s eq %s');
  do_tests($X, 1, 'spatial');
}


drop_test_objects('spatial');
done_spatial: 1;
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
# Finally test parameterless SP.
finally:
{
   blurb("parameterless SP");
   sql ("CREATE PROCEDURE #pelle_sp AS SELECT 4711");
   my $result;
   $result = sql_sp('#pelle_sp', SCALAR, SINGLEROW);
   push(@testres, ($result == 4711 ? "ok %d" : "not ok %d"));
   $no_of_tests++;
}

if ($havedb) {
   $X->sql('USE tempdb');
   $X->sql('DROP DATABASE Olle$DB');
}

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

