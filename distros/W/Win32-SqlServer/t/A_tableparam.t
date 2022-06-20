#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/t/A_tableparam.t 16    22-04-24 22:46 Sommar $
#
# This test script tests table parameters with sql_sp and sql in with
# all data types.
#
# $History: A_tableparam.t $
# 
# *****************  Version 16  *****************
# User: Sommar       Date: 22-04-24   Time: 22:46
# Updated in $/Perl/OlleDB/t
# Reworked the spatial tests, so we don't need a new identical data file
# for each new version of SQL Server.
# 
# *****************  Version 15  *****************
# User: Sommar       Date: 21-06-30   Time: 23:11
# Updated in $/Perl/OlleDB/t
# Adjustment for possible Perl bug with UTF-8 code page.
# 
# *****************  Version 14  *****************
# User: Sommar       Date: 21-04-25   Time: 22:01
# Updated in $/Perl/OlleDB/t
# For sql_variant tests permit either varchar or nvarchar data for plain
# strings, since it will always be nvarchar if DB code page and client
# code page are different.
# 
# *****************  Version 13  *****************
# User: Sommar       Date: 19-07-08   Time: 22:12
# Updated in $/Perl/OlleDB/t
# For older providers, UTF-8 data comes back as nvarchar.
# 
# *****************  Version 12  *****************
# User: Sommar       Date: 19-05-05   Time: 17:49
# Updated in $/Perl/OlleDB/t
# First wave of updating test cases for SQL 2019 and UTF-8.
# 
# *****************  Version 11  *****************
# User: Sommar       Date: 18-04-13   Time: 17:23
# Updated in $/Perl/OlleDB/t
# When checking whether the CLR is enabled, also take CLR strict security
# in consideration, and do not run CLR tests when strict security is in
# force.
# 
# *****************  Version 10  *****************
# User: Sommar       Date: 16-07-11   Time: 23:59
# Updated in $/Perl/OlleDB/t
# Avoid warnings about sprintf in Perl 5.24. Changed some tests slightly
# due to changes in SQL 2016.
# 
# *****************  Version 9  *****************
# User: Sommar       Date: 15-05-24   Time: 22:25
# Updated in $/Perl/OlleDB/t
# Change the condition for 64-bit. Had to change a test case with
# Fraction i a hash, because of unexpected float result.
# 
# *****************  Version 8  *****************
# User: Sommar       Date: 12-08-18   Time: 21:34
# Updated in $/Perl/OlleDB/t
# Fix XML test with Latin-1 so that it does not fail on servers with a
# different code page than 1252.
# 
# *****************  Version 7  *****************
# User: Sommar       Date: 12-07-19   Time: 0:18
# Updated in $/Perl/OlleDB/t
# Force collation to make sure that test works on servers with an SC
# collation (which does not support text & co). Changed functions for
# geometry test to one that are not subject to fuzziness.
#
# *****************  Version 6  *****************
# User: Sommar       Date: 11-08-07   Time: 23:34
# Updated in $/Perl/OlleDB/t
# Added test for empty strings with sql_variant. Different data files for
# the spatial data types depending on the SQL Server version.
#
# *****************  Version 5  *****************
# User: Sommar       Date: 09-08-16   Time: 13:58
# Updated in $/Perl/OlleDB/t
# Modified test för bit to handle empty string as input.
#
# *****************  Version 4  *****************
# User: Sommar       Date: 08-08-17   Time: 23:32
# Updated in $/Perl/OlleDB/t
# Need trick when dropping XML collection from table parameter because of
# deferred temp table drop in SQL 2008. We can now test NULL with UDTs.
#
# *****************  Version 3  *****************
# User: Sommar       Date: 08-04-30   Time: 22:48
# Updated in $/Perl/OlleDB/t
# $localoffset was not correctly computed for the datetimeoffset tests.
#
# *****************  Version 2  *****************
# User: Sommar       Date: 08-04-28   Time: 23:17
# Updated in $/Perl/OlleDB/t
# Use a precise function for the geography data type.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 08-04-07   Time: 22:48
# Created in $/Perl/OlleDB/t
#---------------------------------------------------------------------

use strict;
use IO::File;
use English;
use Config;

use vars qw($sqlver $x86 @tbltypes @tblcols @paramnames @paramtypes 
            $unnamedparambatch $namedparambatch $no_of_tests @testres %inparam
            %expectpar %expectcol %expectfile %test %filetest %comment);

use constant TESTFILE => "tableparam.log";

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
   @tbltypes = @tblcols = @paramnames = @paramtypes = %inparam =
   %expectpar = %expectcol = %expectfile = %test = %filetest = %comment = ();
   $unnamedparambatch = $namedparambatch = undef;
}

sub drop_test_objects {
    my ($type) = @_;
    sql("IF object_id('$type') IS NOT NULL DROP TABLE $type");
    sql("IF object_id('${type}_sp') IS NOT NULL DROP PROCEDURE ${type}_sp");
    my @droptype = sql(<<'SQLEND', {'@type' => ['nvarchar', $type]}, SCALAR);
    SELECT 'DROP TYPE ' + name
    FROM  sys.table_types
    WHERE name LIKE @type + '%'
SQLEND
    sql(join('; ', @droptype));
}

sub create_integer {
   drop_test_objects('integer');

   sql(<<SQLEND);
      CREATE TYPE integer_type1 AS TABLE (intcol      int      NULL,
                                          smallintcol smallint NULL,
                                          tinyintcol  tinyint  NULL)

      CREATE TYPE integer_type2 AS TABLE (floatcol float NULL,
                                          realcol  real  NULL,
                                          bitcol   bit   NULL)
SQLEND

   $namedparambatch = <<'SQLEND';
   SELECT intcol      = SUM(intcol),
          smallintcol = SUM(smallintcol),
          tinyintcol  = SUM(tinyintcol),
          floatcol    = SUM(floatcol),
          realcol     = SUM(realcol),
          bitcol      = SUM(bitcol),
          rowcnt      = SUM(rowcnt),
          intcolnull  = SUM(intcolnull),
          bitcolnull  = SUM(bitcolnull)
   FROM   (SELECT SUM(intcol), SUM(smallintcol), SUM(tinyintcol),
                  NULL, NULL, NULL, COUNT(*),
                  SUM(CASE WHEN intcol IS NULL THEN 1 ELSE 0 END), NULL
           FROM   @firsttable
           UNION  ALL
           SELECT @intpar, NULL, NULL, @floatpar, NULL, NULL, NULL, NULL, NULL
           UNION  ALL
           SELECT NULL, NULL, NULL, SUM(floatcol), SUM(realcol),
                  SUM(convert(int, bitcol)), COUNT(*), NULL,
                  SUM(CASE WHEN bitcol IS NULL THEN 1 ELSE 0 END)
           FROM   @secondtable) AS
        x(intcol, smallintcol, tinyintcol, floatcol, realcol, bitcol,
          rowcnt, intcolnull, bitcolnull)

SQLEND

   sql(<<SQLEND);
   CREATE PROCEDURE integer_sp
                    \@firsttable   integer_type1 READONLY,
                    \@intpar       int       OUTPUT,
                    \@floatpar     float,
                    \@secondtable  integer_type2 READONLY AS
   $namedparambatch;

   SELECT \@intpar  = -2 * \@intpar,
          \@floatpar = 2 * \@floatpar
SQLEND

   $unnamedparambatch = $namedparambatch;
   $unnamedparambatch =~ s/\@\w+/?/g;

   @tblcols    = qw(intcol smallintcol tinyintcol floatcol realcol bitcol
                    rowcnt intcolnull bitcolnull);
   @tbltypes   = qw(integer_type1 integer_type2);
   @paramnames = qw(firsttable intpar floatpar secondtable);
   @paramtypes = qw(table(integer_type1) int float table(integer_type2));
}

#........................

sub create_character {
   drop_test_objects('character');

   sql(<<SQLEND);
      CREATE TYPE character_type AS TABLE
             (charcol     char(20)       NULL,
              varcharcol  varchar(20)    NULL,
              varmaxcol   varchar(MAX)   NULL,
              ncharcol    nchar(20)      NULL,
              ident       int            IDENTITY,
              nvarcharcol nvarchar(20)   NULL,
              nvarmaxcol  nvarchar(MAX)  NULL)
SQLEND

   @tblcols = qw(charcol varcharcol varmaxcol 
                 ncharcol nvarcharcol nvarmaxcol );

   my $base = <<'SQLEND';
   ## = CAST((SELECT '~' + isnull(##, 'NULL') + '~'
              FROM tbl ORDER BY ident FOR XML PATH('')) AS nvarchar(MAX))
SQLEND

   my @arr;
   foreach my $col (@tblcols) {
      my $tmp = $base;
      $tmp =~ s/##/$col/g;
      push(@arr, $tmp);
   }
   $namedparambatch = 'WITH tbl AS (SELECT * FROM @chartable) SELECT ' .
                      join(',', @arr);
   $unnamedparambatch = 'WITH tbl AS (SELECT * FROM ?) SELECT ' .
                        join(',', @arr);

   sql(<<SQLEND);
   CREATE PROCEDURE character_sp \@chartable character_type READONLY AS
   $namedparambatch
SQLEND

   @tbltypes = qw(character_type);
   @paramnames = qw(chartable);
   @paramtypes = qw(table(character_type));
}

#............................

sub create_binary {
   drop_test_objects('binary');

   sql(<<SQLEND);
      CREATE TYPE binary_type1 AS TABLE (bincol      binary(20)    NULL,
                                         varbincol   varbinary(20) NULL,
                                         tstamp      timestamp     NOT NULL)

      CREATE TYPE binary_type2 AS TABLE (binmaxcol varbinary(MAX) NULL,
                                         rowvercol rowversion    NOT NULL)
SQLEND

   $namedparambatch = <<'SQLEND';
   SELECT bincol = convert(binary(20), 
                           reverse(convert(nchar(10), a.bincol))),
          varbincol = convert(varbinary(20), 
                              reverse(convert(nvarchar(20), a.varbincol))),
          binmaxcol = convert(varbinary(MAX), 
                              reverse(convert(nvarchar(MAX), b.binmaxcol))),
          a.tstamp, b.rowvercol
   FROM   @firsttable a
   CROSS  JOIN @secondtable b
SQLEND

   sql(<<SQLEND);
   CREATE PROCEDURE binary_sp \@firsttable  binary_type1 READONLY,
                              \@secondtable binary_type2 READONLY AS
   $namedparambatch
SQLEND

   $unnamedparambatch = $namedparambatch;
   $unnamedparambatch =~ s/\@\w+/?/g;
   
   @tblcols    = qw(bincol varbincol tstamp binmaxcol rowvercol);
   @tbltypes   = qw(binary_type1 binary_type2);
   @paramnames = qw(firsttable secondtable);
   @paramtypes = qw(table(binary_type1) table(binary_type2));
}

#...........................
sub create_oldlobs {
   drop_test_objects ('oldlobs');
   
   sql(<<SQLEND);
      CREATE TYPE oldlobs_type AS TABLE (textcol  text  NULL,
                                         ntextcol ntext NULL,
                                         imagecol image NULL)
SQLEND
   
   $namedparambatch = <<'SQLEND';
   SELECT substring(textcol, 1, 100) AS textcol,
          substring(ntextcol, 1, 100) AS ntextcol,
          substring(imagecol, 1, 100) AS imagecol
   FROM   @oldlobs_table
SQLEND
   
   sql(<<SQLEND);
   CREATE PROCEDURE oldlobs_sp \@oldlobs_table oldlobs_type READONLY AS
   $namedparambatch
SQLEND

   $unnamedparambatch = $namedparambatch;
   $unnamedparambatch =~ s/\@\w+/?/g;
   
   @tblcols    = qw(textcol ntextcol imagecol);
   @tbltypes   = qw(oldlobs_type);
   @paramnames = qw(oldlobs_table);
   @paramtypes = qw(table(oldlobs_type));
}

#...........................

sub create_decimal {
   drop_test_objects('decimal');

   sql(<<SQLEND);
      CREATE TYPE decimal_type1 AS TABLE
             (ident   integer IDENTITY,
              deccol1 decimal(24, 6)  NULL,
              deccol2 decimal(18, 0) NULL)

      CREATE TYPE decimal_type2 AS TABLE
             (numcol1 decimal(12,2) NULL,
              ident   integer IDENTITY,
              numcol2 decimal(6, 4) NULL,
              compcol1 AS coalesce(numcol1, 19) + coalesce(numcol2, 12),
              compcol2 AS coalesce(numcol1, 19) - coalesce(numcol2, 12))

      CREATE TYPE decimal_type3 AS TABLE (
             moneycol  money  NULL,
             compcol3  AS coalesce(moneycol, 19) + coalesce(dimecol, 12),
             dimecol   smallmoney NULL)
SQLEND

   $namedparambatch = <<'SQLEND';
   WITH the_union (firstcol, ident, deccol, compcol1, compcol2, compcol3,
                   lastcol) AS (
      SELECT @firstpar / 2, NULL, NULL, NULL, NULL, NULL, NULL
      UNION ALL
      SELECT NULL, SUM(ident),
             SUM(coalesce(deccol1, 19) + coalesce(deccol2, 12)),
             NULL, NULL, NULL, NULL
      FROM   @firsttable
      UNION  ALL
      SELECT NULL, SUM(ident), NULL, SUM(compcol1), SUM(compcol2), NULL, NULL
      FROM   @secondtable
      UNION ALL
      SELECT NULL, NULL, NULL, NULL, NULL, SUM(compcol3), NULL
      FROM   @thirdtable
      UNION ALL
      SELECT NULL, NULL, NULL, NULL, NULL, NULL, @lastpar / 4
   )
   SELECT firstcol = SUM(firstcol), ident = SUM(ident), deccol = SUM(deccol),
          compcol1 = SUM(compcol1), compcol2 = SUM(compcol2),
          compcol3 = SUM(compcol3), lastcol = SUM(lastcol)
   FROM   the_union
SQLEND

   sql(<<SQLEND);
   CREATE PROCEDURE decimal_sp
                    \@firstpar     money = 17,
                    \@firsttable   decimal_type1 READONLY,
                    \@secondtable  decimal_type2 READONLY,
                    \@thirdtable   decimal_type3 READONLY,
                    \@lastpar      smallmoney = 14 AS

   $namedparambatch
SQLEND

   $unnamedparambatch = $namedparambatch;
   $unnamedparambatch =~ s/\@\w+/?/g;

   @tblcols    = qw(firstcol ident deccol compcol1 compcol2 compcol3 lastcol);
   @tbltypes   = qw(decimal_type1 decimal_type2 decimal_type3);
   @paramnames = qw(firstpar firsttable secondtable thirdtable lastpar);
   @paramtypes = qw(money table(decimal_type1) table(decimal_type2)
                    table(decimal_type3) smallmoney);

}

#..............................

sub create_datetime {
   drop_test_objects('datetime');

   sql(<<SQLEND);
      CREATE TYPE datetime_type AS TABLE
          (datecol         date              NULL,
           timecol         time              NULL,
           datetimecol     datetime          NULL,
           datetime2col    datetime2(2)      NULL,
           ident           int               IDENTITY PRIMARY KEY,
           smallcol        smalldatetime     NULL,
           dtoffsetcol     datetimeoffset(0) NULL)
SQLEND

   $namedparambatch = <<'SQLEND';
   SELECT datecol = SUM(datediff(DAY, coalesce(a.datecol, '19000101'),
                                      coalesce(b.datecol, '19000101'))),
          timecol = SUM(datediff(MS, coalesce(a.timecol, '06:00'),
                                     coalesce(b.timecol, '06:00'))),
          datetimecol = SUM(datediff(MS, coalesce(a.datetimecol, '19000101'),
                                         coalesce(b.datetimecol, '19000101'))),
          datetime2col = SUM(datediff(MS, coalesce(a.datetime2col, '19000101'),
                                           coalesce(b.datetime2col, '19000101'))),
          smallcol = SUM(datediff(MINUTE, coalesce(a.smallcol, '19000101'),
                                          coalesce(b.smallcol, '19000101'))),
          dtoffsetcol = SUM(datediff(MINUTE,
                            coalesce(a.dtoffsetcol, '19000101 00:00 -08:00'),
                            coalesce(b.dtoffsetcol, '19000101 00:00 -08:00')))
   FROM  @firsttable a
   FULL  JOIN  @secondtable b ON a.ident = b.ident
SQLEND

   sql(<<SQLEND);
   CREATE PROCEDURE datetime_sp \@firsttable  datetime_type READONLY,
                                \@secondtable datetime_type READONLY AS
   $namedparambatch
SQLEND

   $unnamedparambatch = $namedparambatch;
   $unnamedparambatch =~ s/\@\w+/?/g;

   @tblcols    = qw(datecol timecol datetimecol datetime2col smallcol
                    dtoffsetcol);
   @tbltypes   = qw(datetime_type);
   @paramnames = qw(firsttable secondtable);
   @paramtypes = qw(table(datetime_type) table(datetime_type));
}
#.....................

sub create_guid {
   drop_test_objects('guid');

   sql(<<SQLEND);
      CREATE TYPE guid_type AS TABLE (guidcol uniqueidentifier NULL);
SQLEND

   $namedparambatch = <<'SQLEND';
   SELECT guidcol = convert(uniqueidentifier,
                      replace(convert(char(36), guidcol), 'F', '0'))
   FROM   @guidtable
SQLEND

   sql(<<SQLEND);
   CREATE PROCEDURE guid_sp \@guidtable guid_type READONLY AS

   $namedparambatch
SQLEND

   $unnamedparambatch = $namedparambatch;
   $unnamedparambatch =~ s/\@\w+/?/g;

   @tblcols    = qw(guidcol);
   @tbltypes   = qw(guid_type);
   @paramnames = qw(guidtable);
   @paramtypes = qw(table(guid_type));
}

#...........................
sub create_bigint {
   drop_test_objects('bigint');

   sql(<<SQLEND);
      CREATE TYPE bigint_type AS TABLE (bigintcol bigint NULL)
SQLEND

   $namedparambatch = <<'SQLEND';
   SELECT bigintcol = SUM(bigintcol) FROM @biginttable
SQLEND

   sql(<<SQLEND);
   CREATE PROCEDURE bigint_sp \@biginttable bigint_type READONLY AS
   $namedparambatch
SQLEND

   $unnamedparambatch = $namedparambatch;
   $unnamedparambatch =~ s/\@\w+/?/g;

   @tblcols    = qw(bigintcol);
   @tbltypes   = qw(bigint_type1);
   @paramnames = qw(biginttable);
   @paramtypes = qw(table(bigint_type));
}
#.................

sub create_sql_variant {
   drop_test_objects('sql_variant');

   sql(<<SQLEND);
      CREATE TYPE sql_variant_type AS TABLE
          (rowno  int          NOT NULL PRIMARY KEY,
           varcol sql_variant  NULL)
SQLEND

   $namedparambatch = <<'SQLEND';
   WITH CTE (rowno, varcol, basetype) AS (
       SELECT rowno, varcol,
              convert(nvarchar(127), sql_variant_property(varcol, 'Basetype'))
       FROM   @vartable
   )
   SELECT basetype = convert(nvarchar(MAX),
                        (SELECT coalesce(basetype, 'NULL') + ';' AS [text()]
                         FROM   CTE
                         ORDER  BY rowno
                         FOR XML PATH(''))),
          varcol   = convert(nvarchar(MAX),
                        (SELECT CASE WHEN basetype LIKE 'date%'
                                     THEN convert(nvarchar(40), varcol, 121)
                                     WHEN basetype = 'time'
                                     THEN convert(nvarchar(40), varcol, 114)
                                     WHEN varcol IS NOT NULL
                                     THEN convert(nvarchar(4000), varcol)
                                     ELSE 'NULL'
                                END + ';' AS [text()]
                         FROM   CTE
                         ORDER  BY rowno
                         FOR XML PATH('')))
SQLEND

   sql(<<SQLEND);
   CREATE PROCEDURE sql_variant_sp \@vartable sql_variant_type READONLY AS
   $namedparambatch
SQLEND

   $unnamedparambatch = $namedparambatch;
   $unnamedparambatch =~ s/\@\w+/?/g;

   @tblcols    = qw(basetype varcol);
   @tbltypes   = qw(sql_variant_type1);
   @paramnames = qw(vartable);
   @paramtypes = qw(table(sql_variant_type));
}

#....................

sub create_xml {

    drop_test_objects('xml');

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
    CREATE TYPE xml_type AS TABLE (xmlcol   xml             NULL,
                                   xmlsccol xml([Olles SC]) NULL)
SQLEND

    $namedparambatch = <<'SQLEND';
    SELECT xmlcol    = xmlcol.value(N'/*[1]', 'nvarchar(MAX)'),
           xmlsccol  = xmlsccol.value(N'/TÄST[1]', 'nvarchar(MAX)'),
           xmlnull   = CASE WHEN xmlcol   IS NULL THEN 1 ELSE 0 END,
           xmlscnull = CASE WHEN xmlsccol IS NULL THEN 1 ELSE 0 END
    FROM   @xmltable
SQLEND

    sql(<<SQLEND);
    CREATE PROCEDURE xml_sp \@xmltable xml_type READONLY AS
    $namedparambatch;
SQLEND

    $unnamedparambatch = $namedparambatch;
    $unnamedparambatch =~ s/\@\w+/?/g;

    @tblcols    = qw(xmlcol xmlsccol xmlnull xmlscnull);
    @tbltypes   = qw(xml_type);
    @paramnames = qw(xmltable);
    @paramtypes = qw(table(xml_type));
}

#................
sub create_clr_builtin {

    drop_test_objects('clr_builtin');

    sql(<<SQLEND);
    CREATE TYPE clr_builtin_type AS TABLE (
       hiercol      hierarchyid    NULL,
       geometrycol  geometry       NULL,
       geographycol geography      NULL)
SQLEND

    $namedparambatch = <<SQLEND;
    SELECT hiercol      = hiercol.GetDescendant(NULL, NULL),
           geometrycol  = geometrycol.STEndPoint(),
           geographycol = geographycol.STStartPoint()
    FROM   \@clr_builtin_table
SQLEND

    sql(<<SQLEND);
    CREATE PROCEDURE clr_builtin_sp \@clr_builtin_table clr_builtin_type READONLY AS
    $namedparambatch
SQLEND

    $unnamedparambatch = $namedparambatch;
    $unnamedparambatch =~ s/\@\w+/?/g;

    @tblcols    = qw(hiercol geometrycol geographycol);
    @tbltypes   = qw(clr_builtin_type);
    @paramnames = qw(clr_builtin_table);
    @paramtypes = qw(table(clr_builtin_type));
}


#.................

sub create_UDT {
    my($X) = @_;

    drop_test_objects('UDT');

   create_the_udts($X, 'OlleComplexInteger', 'OllePoint', 'OlleString',
                       'OlleStringMax');

    sql(<<SQLEND);
    CREATE TYPE UDT_type AS TABLE (cmplxcol  OlleComplexInteger NULL,
                                   pointcol  OllePoint          NULL,
                                   stringcol OlleString         NULL,
                                   maxcol    OlleStringMax      NULL,
                                   id        tinyint            NOT NULL PRIMARY KEY)
SQLEND

    $namedparambatch = <<'SQLEND';
    WITH CTE (cmplxcol, pointcol, stringcol, maxcol, id) AS (
        SELECT
           CASE WHEN cmplxcol  IS NOT NULL
                THEN convert(nvarchar(MAX), cmplxcol.ToString())
                ELSE 'NULL'
           END,
           CASE WHEN pointcol  IS NOT NULL
                THEN convert(nvarchar(MAX), pointcol.ToString())
                ELSE 'NULL'
           END,
           CASE WHEN stringcol IS NOT NULL
                THEN convert(nvarchar(MAX), stringcol.ToString())
                ELSE 'NULL'
           END,
           CASE WHEN maxcol    IS NOT NULL
                THEN convert(nvarchar(MAX), maxcol.ToString())
                ELSE 'NULL'
           END,
           id
        FROM @UDT_table
    )
    SELECT
       cmplxcol  = (SELECT cmplxcol + '/' AS [text()] FROM  CTE
                    ORDER BY id FOR XML PATH('')),
       pointcol  = (SELECT pointcol + '/' AS [text()] FROM  CTE
                    ORDER BY id FOR XML PATH('')),
       stringcol = (SELECT stringcol + '/' AS [text()] FROM  CTE
                    ORDER BY id FOR XML PATH('')),
       maxcol    = (SELECT maxcol + '/' AS [text()] FROM  CTE
                    ORDER BY id FOR XML PATH(''))
SQLEND

    sql(<<SQLEND);
    CREATE PROCEDURE UDT_sp \@UDT_table UDT_type READONLY AS
    $namedparambatch
SQLEND

    $unnamedparambatch = $namedparambatch;
    $unnamedparambatch =~ s/\@\w+/?/g;

    @tblcols    = qw(cmplxcol pointcol stringcol maxcol);
    @tbltypes   = qw(UDT_type);
    @paramnames = qw(UDT_table);
    @paramtypes = qw(table(UDT_type));
}

#................
sub create_funnynames {

    drop_test_objects('funnynames');

    sql(<<'SQLEND');
    CREATE TYPE funnynames_type AS TABLE ([spacy col]    int NULL,
                                          [dotty.col]    int NULL,
                                          [bracket]]col] int NOT NULL,
                                          [quoted""col]  int NULL)
SQLEND

    $namedparambatch = <<'SQLEND';
    SELECT [spacy col]    = SUM([spacy col]),
           [dotty.col]    = SUM([dotty.col]),
           [bracket]]col] = SUM([bracket]]col]),
           [quoted""col]  = SUM([quoted""col])
    FROM   @funnynames_table
SQLEND

    sql(<<SQLEND);
    CREATE PROCEDURE funnynames_sp \@funnynames_table funnynames_type READONLY AS
    $namedparambatch
SQLEND

    $unnamedparambatch = $namedparambatch;
    $unnamedparambatch =~ s/\@\w+/?/g;

    @tblcols    = ('spacy col', 'dotty.col', 'bracket]col', 'quoted""col');
    @tbltypes   = qw(funnynames_type);
    @paramnames = qw(funnynames_table);
    @paramtypes = qw(table(funnynames_type));
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
  my $ret = (split(/\s*\xc2?£\s*/, $line))[0];  # The \xC2 is needed wen OENCP = UTf-8. Perl bug?
  $ret =~ s/^\s*|\s*$//g;
  $ret .= $tz if defined $tz;
  return $ret;
}


sub open_testfile {
   open(TFILE, '>:utf8', TESTFILE);
   return \*TFILE;
}

sub get_testfile {
   open(TFILE, '<:utf8', TESTFILE);
   my $testfile = join('', <TFILE>);
   close TFILE;
   $testfile =~ s!\s*(\*/)?\ngo\s*$!\n!;
   return $testfile;
}

sub check_data {
   my ($result, $params, $paramsbyref) = @_;

   my ($ix, $col, $valref, %filevalues);

   my $testfile;

   foreach my $ix (0..$#tblcols) {
      my $col = $tblcols[$ix];
      next if not defined $col;

      my $resulttest = ($test{$col} =~ /%s.*%s/ ?
             sprintf($test{$col}, '$$result{$col}', '$expectcol{$col}') :
             sprintf($test{$col}, '$$result{$col}'));
      my $comment    = defined $comment{$col} ? $comment{$col} : "";

      push(@testres,
           eval($resulttest) ? "ok %d" :
           "not ok %d # result '$col': <$$result{$col}>, expected: <$expectcol{$col}>" .
           "   $comment $@");
   }

   if ($params) {
      foreach my $ix (0..$#paramnames) {
         my $par = $paramnames[$ix];
         next if not defined $par or $par =~ /table$/;

         my $valref;

         if (ref $params) {
            if (ref $params eq "ARRAY") {
               $valref = ($paramsbyref ? $$params[$ix] : \$$params[$ix]);
            }
            else {
               $valref = ($paramsbyref ? $$params{$par} : \$$params{$par});
            }
         }
         else {
            $valref = undef;
         }

         my $paramtest = ($test{$par} =~ /%s.*%s/ ?
            sprintf($test{$par}, '$$valref', '$expectpar{$par}') :
            sprintf($test{$par}, '$$valref'));
         my $comment = defined $comment{$par} ? $comment{$par} : "";

         push(@testres,
              eval($paramtest) ? "ok %d" :
              "not ok %d # param '$par': <$$valref>, expected: <$expectpar{$par}>  " .
              "    $comment $@");

      }
   }
}


sub do_tests {
    my ($X, $runlogfile, $typeclass, $testcase) = @_;

   $testcase = "<$typeclass" . (defined $testcase ? ", $testcase" : "") . ">";

   my ($result, @sp_params, %sp_params, @sp_paramrefs, %sp_paramrefs,
       @sql_params, %sql_params, @copy1, @copy2, $col);

   # Fill up parameter arrays. As the arrays are changed on each test,
   # fill up copies to refresh with as well.
   foreach my $ix (0..$#paramnames) {
       my $par = $paramnames[$ix];
       my $partype = $paramtypes[$ix];
       push(@sp_params, $inparam{$par});
       $sp_params{$par} = $inparam{$par};
       push(@copy1, $inparam{$par});
       push(@copy2, $inparam{$par});
       push(@sp_paramrefs, \$copy1[$#copy1]);
       $sp_paramrefs{$par} = \$copy2[$#copy2];
       push(@sql_params, [$partype, $inparam{$par}]);
       $sql_params{$par} = [$partype, $inparam{$par}];
   }

   # First test sql with parameters.
   blurb("paramsql $testcase unnamed params");
   $X->{LogHandle} = open_testfile();
   $result = sql($unnamedparambatch, \@sql_params, HASH, SINGLEROW);
   undef $X->{LogHandle};
   check_data($result, 0);

   if ($runlogfile) {
      blurb("Log file from param sql $testcase");
      my $logfile = get_testfile();
      $result = sql($logfile, HASH, SINGLEROW);
      check_data($result, 0);
   }

   blurb("paramsql $testcase named params");
   $result = sql($namedparambatch, \%sql_params, HASH, SINGLEROW);
   check_data($result, 0);

   blurb("sql_sp $testcase unnamed params, no refs");
   $X->{LogHandle} = open_testfile();
   $result = sql_sp("${typeclass}_sp", \@sp_params, HASH, SINGLEROW);
   undef $X->{LogHandle};
   check_data($result, \@sp_params, 0);

   if ($runlogfile) {
      blurb("Log file from sql_sp $testcase");
      my $logfile = get_testfile();
      $result = sql($logfile, HASH, SINGLEROW);
      check_data($result, 0);
   }

   blurb("sql_sp $testcase named params, no refs");
   $result = sql_sp("${typeclass}_sp", \%sp_params, HASH, SINGLEROW);
   undef $X->{LogHandle};
   check_data($result, \%sp_params, 0);

   blurb("sql_sp $testcase unnamed params, refs");
   $result = sql_sp("${typeclass}_sp", \@sp_paramrefs, HASH, SINGLEROW);
   undef $X->{LogHandle};
   check_data($result, \@sp_paramrefs, 1);

   blurb("sql_sp $testcase named params, refs");
   $result = sql_sp("${typeclass}_sp", \%sp_paramrefs, HASH, SINGLEROW);
   undef $X->{LogHandle};
   check_data($result, \%sp_paramrefs, 1);

   $no_of_tests += (6 + ($runlogfile ? 2 : 0)) * scalar(keys %expectcol) +
                   4 * (scalar(keys %expectpar));

}


binmode(STDOUT, ':utf8:');

$^W = 1;
$| = 1;

$no_of_tests = 0;

my $X = testsqllogin();

my $codepage = codepage($X);
my $collation = $X->sql_one("SELECT serverproperty('Collation')", SCALAR);
my $do_oldlobs = ($codepage != 65001 and $collation !~ /_SC$/);

$X->{'ErrInfo'}{RetStatOK}{4711}++;
$X->{'ErrInfo'}{NoWhine}++;
$X->{'ErrInfo'}{NeverPrint}{1708}++;  # Suppresses message for sql_variant table.

$sqlver = (split(/\./, $X->{SQL_version}))[0];
$x86 = not $Config{'use64bitint'};

if ($sqlver < 10 or $X->{Provider} < Win32::SqlServer::PROVIDER_SQLNCLI10) {
   print "1..0 # Skipped: No table parameters available with this server/provider.\n";
   exit;
}




# Make sure that we have standard settings, except for ANSI_WARNINGS
# that we want to be off, as we test overlong input.
$X->sql(<<SQLEND);
SET ANSI_DEFAULTS ON
SET CURSOR_CLOSE_ON_COMMIT OFF
SET IMPLICIT_TRANSACTIONS OFF
SET ANSI_WARNINGS OFF
SQLEND

#---------------------------- integer & float ----------------------------
{
# For integer and float, we do not only test the data types as such, but
# also try to test many aspectes of table parameters in general: NULL
# values, empty tables, left-out columns etc.

clear_test_data;
create_integer;

my(@firsttable, @secondtable);

@firsttable = ({intcol      => 1000000,
                smallintcol => 20000,
                tinyintcol  => 100},
               {intcol      => -100000,
                smallintcol => -1000,
                tinyintcol  => 10},
               {intcol      => 10000,
                smallintcol => 100,
                tinyintcol  => 1},
               {intcol      => -1000,
                smallintcol => -10,
                tinyintcol  => 20},
               {smallintcol => -1,
                tinyintcol  => 2});

@secondtable = ([123456789.456789, 0.456789, 1],
                [-0.456,           1,        ''],
                [2000,             2.2,      0]);

%inparam   = (firsttable   => \@firsttable,
              intpar      => 19,
              floatpar    => -89.0,
              secondtable => \@secondtable);
%expectcol = (intcol        => 909019,
              smallintcol   => 19089,
              tinyintcol    => 133,
              floatcol      => sprintf("%1.6f", 123458700.000789),
              realcol       => 3.656789,
              bitcol        => 1,
              rowcnt        => 8,
              intcolnull    => 1,
              bitcolnull    => 0);
%expectpar = (intpar        => -38,
              floatpar      => sprintf("%1.6f", -89.0));
%test      = (intcol        => '%s == %s',
              intpar        => '%s == %s',
              smallintcol   => '%s == %s',
              tinyintcol    => '%s == %s',
              floatcol      => 'sprintf("%%1.6f", %s) eq %s',
              floatpar      => 'sprintf("%%1.6f", %s) eq %s',
              realcol       => 'abs(%s - %s) < 10',
              bitcol        => '%s == %s',
              rowcnt        => '%s == %s',
              intcolnull    => '%s == %s',
              bitcolnull    => '%s == %s');
do_tests($X, 1, 'integer', 'regular');

@firsttable  = ({intcol      => undef,
                 smallintcol => undef,
                 tinyintcol  => undef});
@secondtable = ({floatcol => undef,
                 realcol  => undef,
                 bitcol   => undef});

%inparam   = (firsttable   => \@firsttable,
              intpar      => undef,
              floatpar    => undef,
              secondtable => \@secondtable);
%expectcol = (intcol        => undef,
              smallintcol   => undef,
              tinyintcol    => undef,
              floatcol      => undef,
              realcol       => undef,
              bitcol        => undef,
              rowcnt        => 2,
              intcolnull    => 1,
              bitcolnull    => 1);
%expectpar = (intpar        => undef,
              floatpar      => undef);
%test      = (intcol        => 'not defined %s',
              intpar        => 'not defined %s',
              smallintcol   => 'not defined %s',
              tinyintcol    => 'not defined %s',
              floatcol      => 'not defined %s',
              floatpar      => 'not defined %s',
              realcol       => 'not defined %s',
              bitcol        => 'not defined %s',
              rowcnt        => '%s == %s',
              intcolnull    => '%s == %s',
              bitcolnull    => '%s == %s');
do_tests($X, 1, 'integer', 'all null');


@secondtable = ({floatcol => 14,
                 realcol  => 18,
                 bitcol   => 1});

%inparam   = (firsttable  => [],
              intpar      => 19,
              floatpar    => -89,
              secondtable => \@secondtable);
%expectcol = (intcol        => 19,
              smallintcol   => undef,
              tinyintcol    => undef,
              floatcol      => '-75.000000',
              realcol       => 18,
              bitcol        => 1,
              rowcnt        => 1,
              intcolnull    => undef,
              bitcolnull    => 0);
%expectpar = (intpar        => -38,
              floatpar      => '-89.000000');
%test      = (intcol        => '%s == %s',
              intpar        => '%s == %s',
              smallintcol   => 'not defined %s',
              tinyintcol    => 'not defined %s',
              floatcol      => 'sprintf("%%1.6f", %s) eq %s',
              floatpar      => 'sprintf("%%1.6f", %s) eq %s',
              realcol       => 'abs(%s - %s) < 10',
              bitcol        => '%s == %s',
              rowcnt        => '%s == %s',
              intcolnull    => 'not defined %s',
              bitcolnull    => '%s == %s');
do_tests($X, 1, 'integer', 'first table empty');


@firsttable = ({intcol       => 14,
                smallintcol  => 18,
                tinyintcol   => 1});

%inparam   = (firsttable  => \@firsttable,
              intpar      => 19,
              floatpar    => -89);
%expectcol = (intcol        => 33,
              smallintcol   => 18,
              tinyintcol    => 1,
              floatcol      => '-89.000000',
              realcol       => undef,
              bitcol        => undef,
              rowcnt        => 1,
              intcolnull    => 0,
              bitcolnull    => undef);
%expectpar = (intpar        => -38,
              floatpar      => '-89.000000');
%test      = (intcol        => '%s == %s',
              intpar        => '%s == %s',
              smallintcol   => '%s == %s',
              tinyintcol    => '%s == %s',
              floatcol      => 'sprintf("%%1.6f", %s) eq %s',
              floatpar      => 'sprintf("%%1.6f", %s) eq %s',
              realcol       => 'not defined %s',
              bitcol        => 'not defined %s',
              rowcnt        => '%s == %s',
              intcolnull    => '%s == %s',
              bitcolnull    => 'not defined %s');
do_tests($X, 1, 'integer', 'second table missing');


%inparam   = (firsttable  => undef,
              intpar      => 19,
              floatpar    => undef,
              secondtbale => undef);
%expectcol = (intcol        => 19,
              smallintcol   => undef,
              tinyintcol    => undef,
              floatcol      => undef,
              realcol       => undef,
              bitcol        => undef,
              rowcnt        => 0,
              intcolnull    => undef,
              bitcolnull    => undef);
%expectpar = (intpar        => -38,
              floatpar      => undef);
%test      = (intcol        => '%s == %s',
              intpar        => '%s == %s',
              smallintcol   => 'not defined %s',
              tinyintcol    => 'not defined %s',
              floatcol      => 'not defined %s',
              floatpar      => 'not defined %s',
              realcol       => 'not defined %s',
              bitcol        => 'not defined %s',
              rowcnt        => '%s == %s',
              intcolnull    => 'not defined %s',
              bitcolnull    => 'not defined %s');
do_tests($X, 1, 'integer', 'both tables undef');



@firsttable = @secondtable = ();
foreach my $ix (1..10000) {
   push(@firsttable, [$ix, 1, ($ix % 100 == 0 ? 1 : 0)]);
   push(@secondtable, [$ix/10, -$ix/10]);
}

%inparam   = (firsttable   => \@firsttable,
              intpar      => 19,
              floatpar    => -89,
              secondtable => \@secondtable);
%expectcol = (intcol        => 10000*10001/2 + 19,
              smallintcol   => 10000,
              tinyintcol    => 100,
              floatcol      => sprintf("%1.6f", 10000*10001/2/10 - 89),
              realcol       => -10000*10001/2/10,
              bitcol        => undef,
              rowcnt        => 20000,
              intcolnull    => 0,
              bitcolnull    => 10000);
%expectpar = (intpar        => -38,
              floatpar      => sprintf("%1.6f", -89.0));
%test      = (intcol        => '%s == %s',
              intpar        => '%s == %s',
              smallintcol   => '%s == %s',
              tinyintcol    => '%s == %s',
              floatcol      => 'sprintf("%%1.6f", %s) eq %s',
              floatpar      => 'sprintf("%%1.6f", %s) eq %s',
              realcol       => 'abs(%s - %s) < 10',
              bitcol        => 'not defined %s',
              rowcnt        => '%s == %s',
              intcolnull    => '%s == %s',
              bitcolnull    => '%s == %s');
# Can't do log tables here - that takes forever!
do_tests($X, 0, 'integer', 'large tables');

drop_test_objects('integer');

}
#------------------------- CHARACTER --------------------------------
{
clear_test_data;
create_character;

my @chartable;

@chartable = (["12345678901234'67890", "abc\x{010D}\x{00F6}",
               'Bridgeblandning 2000' x 2000, 
               "\x{01E6}\x{10E5}\x{00F6}\x{FFFD}", undef,
               "abc\x{0157}",
               "21 pa\x{017A}dziernika 2004 " x 2000],
              {charcol       => 'avlat',
               varcharcol    => '12345678901234567890123',
               varmaxcol     => 'Kortare och kortare',
               ncharcol      => 'Gurkodling',
               nvarcharcol   => '12345678901234567890123',
               nvarmaxcol    => 'Znamenskoe Akaga ' x 1000});

%inparam   = (chartable    => \@chartable);
%expectcol = (charcol      => "~12345678901234'67890~~avlat" . ' ' x 15 . '~',
              varcharcol   => "~abc(\x{010D}|c)(\x{00F6}|o)~" .
                              "~12345678901234567890~",
              varmaxcol    => '~' . 'Bridgeblandning 2000' x 2000 . '~' .
                              '~Kortare och kortare~',
              ncharcol     => "~\x{01E6}\x{10E5}\x{00F6}\x{FFFD}" . ' ' x 16 .
                              "~~Gurkodling" . ' ' x 10 . '~',
              nvarcharcol  => "~abc\x{0157}~~12345678901234567890~",
              nvarmaxcol   => "~" . "21 pa\x{017A}dziernika 2004 " x 2000 . '~' .
                              "~" . 'Znamenskoe Akaga ' x 1000 . '~');
%expectpar = ();
%test      = (charcol      => '%s =~ /^%s$/',
              varcharcol   => '%s =~ /^%s$/',
              varmaxcol    => '%s =~ /^%s$/',
              ncharcol     => '%s =~ /^%s$/',
              nvarcharcol  => '%s =~ /^%s$/',
              nvarmaxcol   => '%s =~ /^%s$/');
do_tests($X, 1, 'character');


@chartable = (["",  "",  "", "", undef, "", ""],
              [" ",  " ",  " ", " ", undef, " ", " "],
              ["   ",  "   ",  "   ", "   ",undef, "   ", "   "]);

%inparam   = (chartable    => \@chartable);
%expectcol = (charcol      => "~" . ' ' x 20 . "~" .
                              "~" . ' ' x 20 . "~" .
                              "~" . ' ' x 20 . "~",
              varcharcol   => "~~~ ~~   ~",
              varmaxcol    => "~~~ ~~   ~",
              ncharcol     => "~" . ' ' x 20 . "~" .
                              "~" . ' ' x 20 . "~" .
                              "~" . ' ' x 20 . "~",
              nvarcharcol  => "~~~ ~~   ~",
              nvarmaxcol   => "~~~ ~~   ~");
%expectpar = ();
%test      = (charcol      => '%s =~ /^%s$/',
              varcharcol   => '%s =~ /^%s$/',
              varmaxcol    => '%s =~ /^%s$/',
              ncharcol     => '%s =~ /^%s$/',
              nvarcharcol  => '%s =~ /^%s$/',
              nvarmaxcol   => '%s =~ /^%s$/');
do_tests($X, 1, 'character', 'blanks');

@chartable = ({});

%inparam   = (chartable    => \@chartable);
%expectcol = (charcol      => "~NULL" . ' ' x 16 . '~',
              varcharcol   => "~NULL~",
              varmaxcol    => "~NULL~",
              ncharcol     => "~NULL" . ' ' x 16 . '~',
              nvarcharcol  => "~NULL~",
              nvarmaxcol   => "~NULL~");
%expectpar = ();
%test      = (charcol      => '%s =~ /^%s$/',
              varcharcol   => '%s =~ /^%s$/',
              varmaxcol    => '%s =~ /^%s$/',
              ncharcol     => '%s =~ /^%s$/',
              nvarcharcol  => '%s =~ /^%s$/',
              nvarmaxcol   => '%s =~ /^%s$/');
do_tests($X, 1, 'character', 'all null');

drop_test_objects('character');

}

#------------------------- BINARY ---------------------------------
{
clear_test_data;
create_binary;

my (@firsttable, @secondtable);

@firsttable  = ({bincol    => 'CEB1CEB2CEB3',
                 varbincol => 'CEB1CEB2CEB3'});
@secondtable = ({binmaxcol => 'CEB1CEB27E73' x 10000});

#$X->{BinaryAsStr} = 1;    Default.
%inparam   = (firsttable   => \@firsttable,
              secondtable  => \@secondtable);
%expectcol = (bincol       => '00' x 14 . 'CEB3CEB2CEB1',
              varbincol    => 'CEB3CEB2CEB1',
              tstamp       => '^[0-9A-F]{16}$',
              rowvercol    => '^[0-9A-F]{16}$',
              binmaxcol    => '7E73CEB2CEB1' x 10000);
%expectpar = ();
%test      = (bincol       => '%s eq %s',
              varbincol    => '%s eq %s',
              binmaxcol    => '%s eq %s',
              tstamp       => '%s =~ /%s/',
              rowvercol    => '%s =~ /%s/');
do_tests($X, 1, 'binary', 'BinaryAsStr = 1');

$X->{BinaryAsStr} = 0;
%inparam   = (firsttable   => \@firsttable,
              secondtable  => \@secondtable);
%expectcol = (bincol       => "\x00" x 8 . 'B3CEB2CEB1CE',
              varbincol    => 'B3CEB2CEB1CE',
              tstamp       => "^(.|\\n){8}\$",
              rowvercol    => "^(.|\\n){8}\$",
              binmaxcol    => '737EB2CEB1CE' x 10000);
%expectpar = ();
%test      = (bincol       => '%s eq %s',
              varbincol    => '%s eq %s',
              binmaxcol    => '%s eq %s',
              tstamp       => '%s =~ /%s/',
              rowvercol    => '%s =~ /%s/');
do_tests($X, 1, 'binary', 'BinaryAsStr = 0');

@firsttable  = (['', '']);
@secondtable = (['0x']);

$X->{BinaryAsStr} = 'x';
%inparam   = (firsttable   => \@firsttable,
              secondtable  => \@secondtable);
%expectcol = (bincol       => '0x' . "00" x 20,
              varbincol    => '0x',
              tstamp       => '^0x[0-9A-F]{16}$',
              rowvercol    => '^0x[0-9A-F]{16}$',
              binmaxcol    => '0x');
%expectpar = ();
%test      = (bincol       => '%s eq %s',
              varbincol    => '%s eq %s',
              binmaxcol    => '%s eq %s',
              tstamp       => '%s =~ /%s/',
              rowvercol    => '%s =~ /%s/');
do_tests($X, 1, 'binary', 'Empty, x');

@firsttable  = (['', '']);
@secondtable = (["\x00"]);

$X->{BinaryAsStr} = '0';
%inparam   = (firsttable   => \@firsttable,
              secondtable  => \@secondtable);
%expectcol = (bincol       => "\x00" x 20,
              varbincol    => '',
              tstamp       => "^(.|\\n){8}\$",
              rowvercol    => "^(.|\\n){8}\$",
              binmaxcol    => "\x00\x00");
%expectpar = ();
%test      = (bincol       => '%s eq %s',
              varbincol    => '%s eq %s',
              binmaxcol    => '%s eq %s',
              tstamp       => '%s =~ /%s/',
              rowvercol    => '%s =~ /%s/');
do_tests($X, 1, 'binary', 'Empty, 0');

@firsttable  = ([undef, undef]);
@secondtable = ([undef]);


$X->{BinaryAsStr} = '0';
%inparam   = (firsttable   => \@firsttable,
              secondtable  => \@secondtable);
%expectcol = (bincol       => undef,
              varbincol    => undef,
              tstamp       => "^(.|\\n){8}\$",
              rowvercol    => "^(.|\\n){8}\$",
              binmaxcol    => undef);
%expectpar = ();
%test      = (bincol       => 'not defined %s',
              varbincol    => 'not defined %s',
              binmaxcol    => 'not defined %s',
              tstamp       => '%s =~ /%s/',
              rowvercol    => '%s =~ /%s/');
do_tests($X, 1, 'binary', 'All NULL');


drop_test_objects('binary');

}
#------------------------- OLDLOBS -------------------------------
if ($do_oldlobs) {
clear_test_data;
create_oldlobs;

my (@firstable);

$X->{BinaryAsStr} = 1;
my @oldlobs_table = (['Motoranalfabet' x 3500, 
                      "21 pa\x{017A}dziernika 2004" x 2000, 
                      '4711ABCDCEB1CEB2CEB3' x 8000]);
%inparam = (oldlobs_table => \@oldlobs_table);
%expectcol = (textcol  => 'Motoranalfabet' x 7 . 'Mo',
              ntextcol => "21 pa\x{017A}dziernika 2004" x 5,
              imagecol => '4711ABCDCEB1CEB2CEB3' x 10);
%expectpar = ();
%test      = (textcol   => '%s eq %s',
              ntextcol  => '%s eq %s',
              imagecol  => '%s eq %s');
do_tests($X, 1, 'oldlobs', 'regular');

@oldlobs_table = (['', '', '']);
%inparam = (oldlobs_table => \@oldlobs_table);
%expectcol = (textcol  => '',
              ntextcol => '',
              imagecol => '');
%expectpar = ();
%test      = (textcol  => '%s eq %s',
              ntextcol => '%s eq %s',
              imagecol => '%s eq %s');
do_tests($X, 1, 'oldlobs', 'empty');

@oldlobs_table = ([undef, undef, undef]);
%inparam = (oldlobs_table => \@oldlobs_table);
%expectcol = (textcol  => undef,
              ntextcol => undef,
              imagecol => undef);
%expectpar = ();
%test      = (textcol  => 'not defined %s',
              ntextcol => 'not defined %s',
              imagecol => 'not defined %s');
do_tests($X, 1, 'oldlobs', 'undef');


}


#------------------------- DECIMAL --------------------------------
{

clear_test_data;
create_decimal;


my (@firsttable, @secondtable, @thirdtable);

@firsttable  = ([undef, 123456912345678.456789, 123456912345678.456789]);
@secondtable = ([14.56, undef, -7.2323],
                {numcol1 => 100, numcol2 => 10},
                {numcol1 => 0, numcol2 => 0.7777});
@thirdtable  = ({moneycol => 123456912345678.4567, dimecol => 123456.4566});

%inparam   = (firstpar    => 171,
              firsttable  => \@firsttable,
              secondtable => \@secondtable,
              thirdtable  => \@thirdtable,
              lastpar     => 171);
%expectcol = (firstcol    => 171 / 2,
              ident       => 7,
              deccol      => 2 * 123456912345678.456789,
              compcol1    => 117.3277 + 0.7777,
              compcol2    => 111.7923 - 0.7777,
              compcol3    => 123456912345678.4567 + 123456.4566,
              lastcol     => 171 / 4);
%expectpar = (firstpar    => 171,
              lastpar     => 171);
%test      = (firstcol    => 'abs(%s - %s) < 1E-6',
              ident       => '%s == %s',
              deccol      => 'abs(%s - %s) < 100',
              compcol1    => 'abs(%s - %s) < 1E-6',
              compcol2    => 'abs(%s - %s) < 1E-6',
              compcol3    => 'abs(%s - %s) < 100',
              lastcol     => 'abs(%s - %s) < 1E-6',
              firstpar    => '%s == %s',
              lastpar     => '%s == %s');
do_tests($X, 1, 'decimal', 'DecimalAsStr = 0');

$X->{DecimalAsStr} = 1;

@firsttable  = ({deccol1 => '123456912345678.456789',
                 deccol2 => '-123456912345678.456789'},
                [],
                [15, '9.1', '-10']);
@secondtable = (['1000000014.56', undef, '-7.2323'],
                {numcol1 => undef, numcol2 => 10},
                {numcol1 => 0, numcol2 => undef});
@thirdtable  = ({moneycol => '123456912345678.4567',
                 dimecol  => '-45678.4566'},
                ['1', undef, '100000'],
                [undef, undef]);

%inparam   = (firstpar    => 171,
              firsttable  => \@firsttable,
              secondtable => \@secondtable,
              thirdtable  => \@thirdtable,
              lastpar     => 171);
%expectcol = (firstcol    => '85.5',
              ident       => 12,
              deccol      => '30.556789',
              compcol1    => '1000000048.3277',
              compcol2    => '1000000018.7923',
              compcol3    => '123456912400032.0001',
              lastcol     => '42.75');
%expectpar = (firstpar    => 171,
              lastpar     => 171);
%test      = (firstcol    => '%s eq %s',
              ident       => '%s == %s',
              deccol      => '%s eq %s',
              compcol1    => '%s eq %s',
              compcol2    => '%s eq %s',
              compcol3    => '%s eq %s',
              lastcol     => '%s eq %s',
              firstpar    => '%s == %s',
              lastpar     => '%s == %s');
do_tests($X, 1, 'decimal', 'DecimalAsStr and null values');


drop_test_objects('decimal');
}
#------------------------- DATETIME --------------------------------
{
clear_test_data;
create_datetime;

my (@firsttable, @secondtable, $localoffset);

# Get local timezone.
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
  $localoffset = $offsetminutes;
}

@firsttable = ({datecol      => '19960813',
                timecol      => '04:36:24.997',
                datetimecol  => '1996-08-13 04:36:24.990',
                datetime2col => '1996-08-13 04:36:24.984',
                smallcol     => '1996-08-13T04:36',
                dtoffsetcol  => '1996-08-13 04:6 +02:00'},
               {datecol      => '   0001-8-1',
                timecol      => '23:50',
                datetimecol  => '1996-08-13Z',
                datetime2col => '1632-11-06 15:36',
                smallcol     => '1996-08-13T04:36',
                dtoffsetcol  => '1996-08-13 04:26:24 +2:0'});
@secondtable = ({datecol      => '19960830',
                 timecol      => '04:36:24.998',
                 datetimecol  => '1996-08-13 04:36:25',
                 datetime2col => '19960813 4:36 :24.993',
                 smallcol     => '1996-08-13T04:16',
                 dtoffsetcol  => '1996-08-13 4:15'},
                {datecol      => '   0001-8-2',
                 timecol      => '23:50:6',
                 datetimecol  => '1996-08-13 0:0:0.3',
                 datetime2col => '1632-11-06 15:37',
                 smallcol     => '1996-08-13T04:38',
                 dtoffsetcol  => '1996-08-13 04:37:25 -04:30'});

%inparam    = (firsttable   => \@firsttable,
               secondtable  => \@secondtable);
%expectcol  = (datecol      => 18,
               timecol      => 6001,
               datetimecol  => 310,
               datetime2col => 60010,
               smallcol     => -18,
               dtoffsetcol  => 120+9+390+11);
%expectpar  = ();
%test       = (datecol      => '%s == %s',
               timecol      => '%s == %s',
               datetimecol  => '%s == %s',
               datetime2col => '%s == %s',
               smallcol     => '%s == %s',
               dtoffsetcol  => '%s == %s');
do_tests($X, 0, 'datetime', 'ISO in');   # No logfile for datetime.

$X->{TZOffset} = 'local';
@firsttable = ({datecol      => ISO_to_regional('1996-08-13'),
                timecol      => ISO_to_regional('04:36:24'),
                datetimecol  => ISO_to_regional('1996-08-13 04:36:24'),
                datetime2col => ISO_to_regional('1996-08-12 04:36:24'),
                smallcol     => ISO_to_regional('1996-08-13 04:36'),
                dtoffsetcol  => ISO_to_regional('1996-08-13 04:06') . ' +02:00'},
               {datecol      => ISO_to_regional('0101-08-01'),
                timecol      => ISO_to_regional('23:50'),
                datetimecol  => ISO_to_regional('1996-08-13'),
                datetime2col => ISO_to_regional('1632-11-06 15:36'),
                smallcol     => ISO_to_regional('1996-08-13 04:36'),
                dtoffsetcol  => ISO_to_regional('1996-08-13 04:26:24') . ' -0:30'});
@secondtable = ({datecol      => ISO_to_regional('1996-08-30'),
                 timecol      => ISO_to_regional('04:40:24'),
                 datetimecol  => ISO_to_regional('1996-08-13 04:36:25'),
                 datetime2col => ISO_to_regional('1996-08-13 04:36:24'),
                 smallcol     => ISO_to_regional('1996-08-13 04:16'),
                 dtoffsetcol  => ISO_to_regional('1996-08-13 04:15')},
                {datecol      => ISO_to_regional('0101-08-02'),
                 timecol      => ISO_to_regional('23:50:06'),
                 datetimecol  => ISO_to_regional('1996-08-13 00:00:01'),
                 datetime2col => ISO_to_regional('1632-11-06 15:37'),
                 smallcol     => ISO_to_regional('1996-08-13 04:38'),
                 dtoffsetcol  => ISO_to_regional('1996-08-13 04:37:25')});

%inparam    = (firsttable   => \@firsttable,
               secondtable  => \@secondtable);
%expectcol  = (datecol      => 18,
               timecol      => 246000,
               datetimecol  => 2000,
               datetime2col => 86460000,
               smallcol     => -18,
               dtoffsetcol  => 120 - $localoffset + 9 + -30 - $localoffset +11);
%expectpar  = ();
%test       = (datecol      => '%s == %s',
               timecol      => '%s == %s',
               datetimecol  => '%s == %s',
               datetime2col => '%s == %s',
               smallcol     => '%s == %s',
               dtoffsetcol  => '%s == %s');
do_tests($X, 0, 'datetime', 'Regional in');


$X->{TZOffset} = '+03:00';
@firsttable  = ({datecol      => 3,
                 timecol      => 0.5,
                 datetimecol  => 2.25,
                 dtoffsetcol  => 2},
                {datetime2col => 3.25,
                 smallcol     => 3.25,
                 dtoffsetcol  => 3.25});
@secondtable = ({datetime2col => -2.25,
                 smallcol     => 2.25,
                 dtoffsetcol  => -2.25},
                {datecol      => -5,
                 timecol      => 0.75,
                 datetimecol  => -2.25});

%inparam    = (firsttable   => \@firsttable,
               secondtable  => \@secondtable);
%expectcol  = (datecol      => -8,
               timecol      => 6*3600000,
               datetimecol  => -96*3600000,
               datetime2col => -120*3600000,
               smallcol     => -24*60,
               dtoffsetcol  => -120*60 + 60 * 11);
%expectpar  = ();
%test       = (datecol      => '%s == %s',
               timecol      => '%s == %s',
               datetimecol  => '%s == %s',
               datetime2col => '%s == %s',
               smallcol     => '%s == %s',
               dtoffsetcol  => '%s == %s');
do_tests($X, 0, 'datetime', 'float in + null');


$X->{TZOffset} = '-03:30';
@firsttable = ({datecol      => {Year => 1996, Month => 8, Day => 13},
                timecol      => {Hour => 4, Minute => 36, => Second => 24,
                                 Fraction => 997},
                datetimecol  => {Year => 1996, Month => 8, Day => 13,
                                 Hour => 4, Minute => 36, => Second => 24,
                                 Fraction => 990},
                datetime2col => {Year => 1996, Month => 8, Day => 13,
                                 Hour => 4, Minute => 36, => Second => 24,
                                 Fraction => 984},
                smallcol     => {Year => 1996, Month => 8, Day => 13,
                                 Hour => 4, Minute => 36},
                dtoffsetcol  => {Year => 1996, Month => 8, Day => 13,
                                 Hour => 4, Minute => 6, TZHour => 2}},
               {datecol      => {Year => 1, Month => 8, Day => 1},
                timecol      => {Hour => 23, Minute => 50},
                datetimecol  => {Year => 1996, Month => 8, Day => 13},
                datetime2col => {Year => 1632, Month => 11, Day => 6,
                                 Hour => 4, Minute => 36, => Second => 0},
                smallcol     => {Year => 1996, Month => 8, Day => 13,
                                 Hour => 4, Minute => 36},
                dtoffsetcol  => {Year => 1996, Month => 8, Day => 13,
                                 Hour => 4, Minute => 24, Second => 24,
                                 TZHour => 2, TZMinute => 0}});
@secondtable = ({datecol      => {Year => 1996, Month => 8, Day => 30},
                 timecol      => {Hour => 4, Minute => 36, => Second => 24,
                                  Fraction => 998},
                 datetimecol  => {Year => 1996, Month => 8, Day => 13,
                                  Hour => 4, Minute => 36, => Second => 25,
                                  Fraction => 0},
                 datetime2col => {Year => 1996, Month => 8, Day => 13,
                                  Hour => 4, Minute => 36, => Second => 24,
                                  Fraction => 993},
                 smallcol     => {Year => 1996, Month => 8, Day => 13,
                                  Hour => 4, Minute => 16},
                 dtoffsetcol  => {Year => 1996, Month => 8, Day => 13,
                                  Hour => 4, Minute => 15}},
                {datecol      => {Year => 1, Month => 8, Day => 2},
                 timecol      => {Hour => 23, Minute => 50, Second => 6},
                 datetimecol  => {Year => 1996, Month => 8, Day => 13,
                                  Fraction => 30
 },
                 datetime2col => {Year => 1632, Month => 11, Day => 6,
                                  Hour => 15, Minute => 37},
                 smallcol     => {Year => 1996, Month => 8, Day => 13,
                                  Hour => 4, Minute => 38},
                 dtoffsetcol  => {Year => 1996, Month => 8, Day => 13,
                                  Hour => 4, Minute => 37, Second => 25,
                                  TZHour => -4, TZMinute => -30}});

%inparam    = (firsttable   => \@firsttable,
               secondtable  => \@secondtable);
%expectcol  = (datecol      => 18,
               timecol      => 6001,
               datetimecol  => 40,
               datetime2col => 11*3600000 + 60010,
               smallcol     => -18,
               dtoffsetcol  => 120+210+9+390+13);
%expectpar  = ();
%test       = (datecol      => '%s == %s',
               timecol      => '%s == %s',
               datetimecol  => '%s == %s',
               datetime2col => '%s == %s',
               smallcol     => '%s == %s',
               dtoffsetcol  => '%s == %s');
do_tests($X, 0, 'datetime', 'Hash in');

drop_test_objects('datetime');

}

#---------------------------- GUID -------------------------------
{
clear_test_data;
create_guid;

%inparam   = (guidtable   => [['FF0DCAF3-CFFC-4C9B-AE4B-C08B2000871C']]);
%expectcol = (guidcol     => '{000DCA03-C00C-4C9B-AE4B-C08B2000871C}');
%expectpar = ();
%test      = (guidcol     => '%s eq %s');
do_tests($X, 1, 'guid', 'unbraced');

%inparam   = (guidtable   => [['{FF0DCAF3-CFFC-4C9B-AE4B-C08B2000871C}']]);
%expectcol = (guidcol     => '{000DCA03-C00C-4C9B-AE4B-C08B2000871C}');
%expectpar = ();
%test      = (guidcol     => '%s eq %s');
do_tests($X, 1, 'guid', 'unbraced');

%inparam   = (guidtable   => [[undef]]);
%expectcol = (guidcol     => undef);
%expectpar = ();
%test      = (guidcol     => 'not defined %s');
do_tests($X, 1, 'guid', 'null');

drop_test_objects('guid');
}

#------------------------- BIGINT --------------------------------
{

clear_test_data;
create_bigint;

my @biginttable;

# Different tests for x86 and 64-bit.
if ($x86) {
   $X->{DecimalAsStr} = 0;
   %inparam   = (biginttable => [[123456912345678], [-12345678]]);
   %expectcol = (bigintcol   =>   123456900000000);
   %expectpar = ();
   %test      = (bigintcol   => 'abs(%s - %s) < 100');
   do_tests($X, 1, 'bigint', 'x86 DecimalAsStr = 0');

   $X->{DecimalAsStr} = 1; # Input is still numeric.
   %inparam   = (biginttable => [['123456912345678'], ['-12345678']]);
   %expectcol = (bigintcol   =>   '123456900000000');
   %expectpar = ();
   %test      = (bigintcol   => '%s eq %s');
   do_tests($X, 1, 'bigint', 'x86 DecimalAsStr = 1, str in');
}
else {
   %inparam   = (biginttable => [[123456912345678], [-12345678]]);
   %expectcol = (bigintcol   =>   123456900000000);
   %expectpar = ();
   %test      = (bigintcol   => '%s = %s');
   do_tests($X, 1, 'bigint', 'Regular 64-bit');

   # Test strings in, but they should still come back as numbers.
   %inparam   = (biginttable => [['123456912345678'], ['-12345678']]);
   %expectcol = (bigintcol   => 123456900000000);
   %expectpar = ();
   %test      = (bigintcol   => '%s == %s');
   do_tests($X, 1, 'bigint', '64-bit, str in');
}

# And test null values.
%inparam   = (biginttable => [[undef], [undef]]);
%expectcol = (bigintcol => undef);
%expectpar = ();
%test      = (bigintcol => 'not defined %s');
do_tests($X, 1, 'bigint', 'null values');

drop_test_objects('bigint');

}

#---------------------------- SQL_VARIANT ------------------------------
{

clear_test_data;
create_sql_variant;

my @vartable;

@vartable = ([1, {Year => 2008, Month => 3, Day => 22}],
             [2, {Year => 2008, Month => 3, Day => 22,
                  Hour => 18, Minute => 30, TZHour => 1}],
             [3, {Year => 2008, Month => 3, Day => 22,
                  Hour => 18, Minute => 30, Fraction => 31.1}],
             [4, {Hour => 0, Minute => 0, Fraction => 0.0001}],
             [5, 12345678],
             [6, 1e202],
             [7, "abc\x{010B}\x{FFFD}"],
             [8, "Lycksele"],
             [9, '']);

%inparam   = (vartable => \@vartable);
%expectcol = (basetype => "date;datetimeoffset;datetime2;time;int;" .
                          "float;nvarchar;n?varchar;n?varchar;",
              varcol   => "2008-03-22;2008-03-22 18:30:00.0000000 +01:00;" .
                          "2008-03-22 18:30:00.0311000;00:00:00.0000001;" .
                          "12345678;1e+202;abc\x{010B}\x{FFFD};Lycksele;;");
%expectpar = ();
%test      = (basetype => "%s =~ /%s/",
              varcol   => "%s eq %s");
do_tests($X, 0, 'sql_variant', 'all sorts');

@vartable = ([0, 123456789123456789]);
%inparam = (vartable => \@vartable);
%expectpar = ();
if ($x86) {
   %expectcol = (basetype => 'float;',
                 varcol   => '1.23457e+017;');
}
else {
   %expectcol = (basetype => 'bigint;',
                 varcol   => '123456789123456789;');
}
%test      = (basetype => "%s eq %s",
              varcol   => "%s eq %s");
do_tests($X, 0, 'sql_variant', 'bigint');


%inparam = (vartable => [[0]]);
%expectpar = ();
%expectcol = (basetype => 'NULL;',
              varcol   => 'NULL;');
%test      = (basetype => "%s eq %s",
              varcol   => "%s eq %s");
do_tests($X, 0, 'sql_variant', 'NULL');


drop_test_objects('sql_variant');

}

#------------------------------- XML -----------------------------------
# At this point we must turn on ANSI_WARNINGS, to get the XML stuff to
# work.
$X->sql("SET ANSI_WARNINGS ON");
{

clear_test_data;
create_xml;

my @xmltable;

@xmltable = ({xmlcol    => "<R\x{00C4}KSM\x{00D6}RG\x{00C5}S>" .
                           "21 pa\x{017A}dziernika 2004 " x 2000 .
                           "</R\x{00C4}KSM\x{00D6}RG\x{00C5}S>",
              xmlsccol  => ($codepage == 1252
                               ? '<?xml version="1.0" encoding="iso-8859-1"?>' . "\n" 
                               : '') .
                            "<TÄST>" .
                            "Vi är alltid bäst i räksmörgåstäster! " x 1500 .
                            "</TÄST>\n<TÄST>I alla fall nästan alltid!</TÄST>"});

%inparam      = (xmltable => \@xmltable);
%expectcol    = (xmlcol   => "21 pa\x{017A}dziernika 2004 " x 2000,
                 xmlsccol => "Vi är alltid bäst i räksmörgåstäster! " x 1500,
                 xmlnull  => 0,
                 xmlscnull=> 0);
%expectpar    = ();
%test         = (xmlcol    => '%s eq %s',
                 xmlsccol  => '%s eq %s',
                 xmlnull   => '%s == %s',
                 xmlscnull => '%s == %s');
do_tests($X, 1, 'xml', 'default, 8859');

@xmltable =  ([qq!<?xml version = "1.0"\tencoding =   "ucs-2"?>! .
               "<R\x{00C4}KSM\x{00D6}RG\x{00C5}S>" .
               "21 pa\x{017A}dziernika 2004 " .
               "</R\x{00C4}KSM\x{00D6}RG\x{00C5}S>  ",
                '<?xml  version="1.0" encoding="UTF-8" ?>' . "\n" .
                "<TÄST>" .
                "Vi är alltid bäst i räksmörgåstäster! " .
                "</TÄST>\n<TÄST>I alla fall nästan alltid!</TÄST>"]);
%inparam      = (xmltable => \@xmltable);
%expectcol    = (xmlcol   => "21 pa\x{017A}dziernika 2004 ",
                 xmlsccol => "Vi är alltid bäst i räksmörgåstäster! ",
                 xmlnull  => 0,
                 xmlscnull=> 0);
%expectpar    = ();
%test         = (xmlcol   => '%s eq %s',
                 xmlsccol => '%s eq %s',
                 xmlnull   => '%s == %s',
                 xmlscnull => '%s == %s');
do_tests($X, 1, 'xml', 'ucs-2, utf-8');

@xmltable  = (['', '   ']);
%inparam   = (xmltable => \@xmltable);
%expectcol = (xmlcol    => undef,
              xmlsccol  => undef,
              xmlnull   => 0,
              xmlscnull => 0);
%expectpar = ();
%test      = (xmlcol    => 'not defined %s',
              xmlsccol  => 'not defined %s',,
              xmlnull   => '%s == %s',
              xmlscnull => '%s == %s');
do_tests($X, 1, 'xml', 'empty strings');

@xmltable  = ([undef, undef]);
%inparam   = (xmltable => \@xmltable);
%expectcol = (xmlcol    => undef,
              xmlsccol  => undef,
              xmlnull   => 1,
              xmlscnull => 1);
%expectpar = ();
%test      = (xmlcol    => 'not defined %s',
              xmlsccol  => 'not defined %s',,
              xmlnull   => '%s == %s',
              xmlscnull => '%s == %s');
do_tests($X, 1, 'xml', 'NULL');

drop_test_objects('xml');
    sql(<<SQLEND);
    IF EXISTS (SELECT * FROM sys.xml_schema_collections WHERE name = 'Olles SC')
    BEGIN
       DECLARE \@i int = 20
       WHILE \@i > 0
       BEGIN
          IF EXISTS (SELECT *
                     FROM   sys.columns c
                     JOIN   sys.xml_schema_collections xcs ON
                            c.xml_collection_id = xcs.xml_collection_id
                     WHERE xcs.name = 'Olles SC')
          BEGIN
              WAITFOR DELAY '00:00:01'
              SELECT \@i -= 1
          END
          ELSE
          BEGIN
              DROP XML SCHEMA COLLECTION [Olles SC]
              SELECT \@i = 0
          END
       END
    END
SQLEND

}

#----------------------- Built-in CLR types ---------------------------------
{
clear_test_data;
create_clr_builtin;

my $spatialver = ($sqlver == 10 ? 10 : 11);
open(F, "../helpers/spatial.data.$spatialver") or 
      warn "Could not read file 'spatial data.$spatialver': $!\n";
my @file = <F>;
close F;
my ($geometry, $geometrycol, $geometrypar,
    $geography, $geographycol, $geographypar) = split(/\n/, join('', @file));

my @clr_table;

@clr_table = ({hiercol      => '0x5D5C1F',    # /1/10/23/
               geometrycol  => $geometry,
               geographycol => $geography});

$X->{BinaryAsStr} = 'x';
%inparam    = (clr_builtin_table => \@clr_table);
%expectcol  = (hiercol      => '0x5D5C1F58',
               geometrycol  => $geometrycol,
               geographycol => $geographycol);
%expectpar  = ();
%test       = (hiercol      => '%s eq %s',
               geometrycol  => '%s eq %s',
               geographycol => '%s eq %s');
do_tests($X, 1, 'clr_builtin', 'Bin0x');

@clr_table = ({hiercol      => undef,
               geometrycol  => undef,
               geographycol => undef});

$X->{BinaryAsStr} = 'x';
%inparam    = (clr_builtin_table => \@clr_table);
%expectcol  = (hiercol      => undef,
               geometrycol  => undef,
               geographycol => undef);
%expectpar  = ();
%test       = (hiercol      => 'not defined %s',
               geometrycol  => 'not defined %s',
               geographycol => 'not defined %s');
do_tests($X, 1, 'clr_builtin', 'null');

drop_test_objects('clr_builtin');
}

#------------------------------- UDT -----------------------------------
# We cannot do UDT tests, if the CLR is not enabled on the server.
my $clr_enabled = clr_enabled($X);

if ($clr_enabled) {

clear_test_data;
create_UDT($X);

my @udt_table;

$X->{BinaryAsStr} = 'x';
@udt_table = ({cmplxcol  => '0x800000058000000700',
               pointcol  => '0x0180000012800000088000000A',
               stringcol => '0x00050000004E69737365',
               maxcol    => '0x000D00000052C3A46B736DC3B67267C3A573',
               id        => 1},
              {cmplxcol  => '0x7FFFFFFF7FFFFFFF00',
               pointcol  => '0x01800000008000000080000064',
               stringcol => '0x0000000000',
               maxcol    => '0x0000000000',
               id        => 2},
              {cmplxcol  => '0x800000008000000000',
               pointcol  => '0x017FFFFF92800000227FFFFFC9',
               stringcol => '0x00A00F0000' . '4E69737365' x 800,
               maxcol    => '0x00C8320000' .
                            ('52C3A46B736DC3B67267C3A573' x 1000),
               id        => 3});

%inparam = (UDT_table => \@udt_table);
%expectcol = (cmplxcol   => '(5,7i)/(-1,-1i)/(0,0i)/',
              pointcol   => '18:8:10/0:0:100/-110:34:-55/',
              stringcol  => 'Nisse//' . 'Nisse' x 800 . '/',
              maxcol     => 'Räksmörgås//' . 'Räksmörgås' x 1000 . '/');
%expectpar = ();
%test      = (cmplxcol   => '%s eq %s',
              pointcol   => '%s eq %s',
              stringcol  => '%s eq %s',
              maxcol     => '%s eq %s');
do_tests($X, 1, 'UDT', 'Bin0x');

$X->{BinaryAsStr} = '0';
@udt_table = ({cmplxcol  => pack('H*', '800000058000000700'),
               pointcol  => pack('H*', '0180000012800000088000000A'),
               stringcol => pack('H*', '00050000004E69737365'),
               maxcol    => pack('H*', '000D00000052C3A46B736DC3B67267C3A573'),
               id        => 1},
              {cmplxcol  => pack('H*', '7FFFFFFF7FFFFFFF00'),
               pointcol  => pack('H*', '01800000008000000080000064'),
               stringcol => pack('H*', '0000000000'),
               maxcol    => pack('H*', '0000000000'),
               id        => 2},
              {cmplxcol  => pack('H*', '800000008000000000'),
               pointcol  => pack('H*', '017FFFFF92800000227FFFFFC9'),
               stringcol => pack('H*', '00A00F0000' . '4E69737365' x 800),
               maxcol    => pack('H*', '00C8320000' .
                            ('52C3A46B736DC3B67267C3A573' x 1000)),
               id        => 3});
%expectcol = (cmplxcol   => '(5,7i)/(-1,-1i)/(0,0i)/',
              pointcol   => '18:8:10/0:0:100/-110:34:-55/',
              stringcol  => 'Nisse//' . 'Nisse' x 800 . '/',
              maxcol     => 'Räksmörgås//' . 'Räksmörgås' x 1000 . '/');
%expectpar = ();
%test      = (cmplxcol   => '%s eq %s',
              pointcol   => '%s eq %s',
              stringcol  => '%s eq %s',
              maxcol     => '%s eq %s');
do_tests($X, 1, 'UDT', 'Binary as binary');


@udt_table = ({cmplxcol  => undef,
               pointcol  => undef,
               stringcol => undef,
               maxcol    => undef,
               id        => 1});
%expectcol = (cmplxcol   => 'NULL/',
              pointcol   => 'NULL/',
              stringcol  => 'NULL/',
              maxcol     => 'NULL/');
%expectpar = ();
%test      = (cmplxcol   => '%s eq %s',
              pointcol   => '%s eq %s',
              stringcol  => '%s eq %s',
              maxcol     => '%s eq %s');
do_tests($X, 1, 'UDT', 'NULL');


drop_test_objects('UDT');
delete_the_udts($X);
}


#-------------------------- Funny names -------------------------------

# The last test is the test with funny names in the column list.
{
# This test sums NULL, so warnings must be off.
$X->sql("SET ANSI_WARNINGS OFF");

clear_test_data;
create_funnynames;

my @funnytable = ([undef, 100, 1000, 10000],
                  [20, undef,  2000, 20000],
                  [30,   300,  3000, 30000],
                  [40,   400,  4000, undef]);

%inparam   = (funnynames_table => \@funnytable);
%expectcol = ('spacy col'   => 90,
              'dotty.col'   => 800,
              'bracket]col' => 10000,
              'quoted""col' => 60000);
%expectpar  = ();
%test      = ('spacy col'   => '%s == %s',
              'dotty.col'   => '%s == %s',
              'bracket]col' => '%s == %s',
              'quoted""col' => '%s == %s');
do_tests($X, 1, 'funnynames');

drop_test_objects('funnynames');

}


#-----------------------------------------------------------------------

finally:

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

