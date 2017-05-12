#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/t/1_resultsets.t 15    11-08-08 21:51 Sommar $
#
# $History: 1_resultsets.t $
# 
# *****************  Version 15  *****************
# User: Sommar       Date: 11-08-08   Time: 21:51
# Updated in $/Perl/OlleDB/t
# Cannot use brackets on SQL 6.5!
# 
# *****************  Version 14  *****************
# User: Sommar       Date: 11-08-07   Time: 23:32
# Updated in $/Perl/OlleDB/t
# Rewrote the test so that it uses queries which runs on Denali which
# does not support COMPUTE BY.
#
# *****************  Version 13  *****************
# User: Sommar       Date: 08-05-04   Time: 20:52
# Updated in $/Perl/OlleDB/t
# It was somewhat more sublime: cannot use the ambiguous column alias.
#
# *****************  Version 12  *****************
# User: Sommar       Date: 08-05-04   Time: 20:48
# Updated in $/Perl/OlleDB/t
# Needed ORDER BY in SQL statement for test of duplicate columns.
#
# *****************  Version 11  *****************
# User: Sommar       Date: 08-03-16   Time: 21:28
# Updated in $/Perl/OlleDB/t
# Added tests for empty command batches.
#
# *****************  Version 10  *****************
# User: Sommar       Date: 08-01-07   Time: 0:22
# Updated in $/Perl/OlleDB/t
# Added tests for handling of duplicate column names.
#
# *****************  Version 9  *****************
# User: Sommar       Date: 07-07-07   Time: 21:37
# Updated in $/Perl/OlleDB/t
# Added checks for MULTISET_RC and also more checks for batches with at
# most row counts only.
#
# *****************  Version 8  *****************
# User: Sommar       Date: 07-06-25   Time: 0:30
# Updated in $/Perl/OlleDB/t
# Added checks for colinfo styles.
#
# *****************  Version 7  *****************
# User: Sommar       Date: 05-11-26   Time: 23:47
# Updated in $/Perl/OlleDB/t
# Renamed the module from MSSQL::OlleDB to Win32::SqlServer.
#
# *****************  Version 6  *****************
# User: Sommar       Date: 05-08-06   Time: 23:23
# Updated in $/Perl/OlleDB/t
# Added test for sql_sp and callback.
#
# *****************  Version 5  *****************
# User: Sommar       Date: 05-02-27   Time: 21:54
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 4  *****************
# User: Sommar       Date: 05-02-06   Time: 20:45
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 3  *****************
# User: Sommar       Date: 05-01-02   Time: 20:56
# Updated in $/Perl/OlleDB/t
# Small adjustment to the require.
#
# *****************  Version 2  *****************
# User: Sommar       Date: 05-01-02   Time: 20:53
# Updated in $/Perl/OlleDB/t
# Now login is controlled from environment variable.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 05-01-02   Time: 20:27
# Created in $/Perl/OlleDB/t
#---------------------------------------------------------------------

use strict;
use Win32::SqlServer qw(:DEFAULT :consts);
use File::Basename qw(dirname);

require &dirname($0) . '\testsqllogin.pl';

use vars qw(@testres $verbose);

sub blurb{
    push (@testres, "#------ Testing @_ ------\n");
    print "#------ Testing @_ ------\n" if $verbose;
}

$verbose = shift @ARGV;

$^W = 1;

$| = 1;

my($X, $sql, $sql1, $sql_empty, $sql_error, $sql_null, $sql_key1,
   $sql_print, $sql_counts, $sql_nocount, $sql_key_many, $sql_dupnames,
   $no_of_tests);

$X = testsqllogin();

# Accept all errors, and be silent about them.
$X->{errInfo}{maxSeverity}= 25;
$X->{errInfo}{printLines} = 25;
$X->{errInfo}{printMsg}   = 25;
$X->{errInfo}{printText}  = 25;
$X->{errInfo}{carpLevel}  = 25;

$SQLSEP = '@!@';

# First set up tables and data.
sql(<<SQLEND);
CREATE TABLE #a(a char(1) NOT NULL, b char(1) NOT NULL, i int NOT NULL)
CREATE TABLE #b(x char(3) NULL)
CREATE TABLE #c(key1  char(5)     NOT NULL,
                key2  char(1)     NOT NULL,
                key3  int         NOT NULL,
                data1 smallint    NULL,
                data2 varchar(10) NULL,
                data3 char(1)     NOT NULL)

INSERT #a VALUES('A', 'A', 12)
INSERT #a VALUES('A', 'D', 24)
INSERT #a VALUES('A', 'H', 1)
INSERT #a VALUES('C', 'B', 12)

INSERT #c VALUES('apple', 'X', 1, NULL, NULL,      'T')
INSERT #c VALUES('apple', 'X', 2, -15,  NULL,      'T')
INSERT #c VALUES('apple', 'X', 3, NULL, NULL,      'T')
INSERT #c VALUES('apple', 'Y', 1, 18,   'Verdict', 'H')
INSERT #c VALUES('apple', 'Y', 6, 18,   'Maracas', 'I')
INSERT #c VALUES('peach', 'X', 1, 18,   'Lastkey', 'T')
INSERT #c VALUES('peach', 'X', 8, 4711, 'Monday',  'T')
INSERT #c VALUES('melon', 'Y', 1, 118,  'Lastkey', 'T')
SQLEND

# This is our test batch: three result sets whereof one empty. There are
# also two row counts
$sql = <<SQLEND;
SET NOCOUNT OFF

SELECT *
FROM   #a
ORDER  BY a, b

SELECT SUM(i) AS "sum" FROM #a GROUP BY a WITH ROLLUP
ORDER BY grouping(a), a


INSERT #b VALUES('xyz')
INSERT #b VALUES(NULL)

SELECT * FROM #b

DELETE #b

-- Note: if this SELECT comes directly after the first SELECT, SQLOLEDB
-- gets an AV. Not our fault. :-)
SELECT * FROM #a WHERE a = '?'

SELECT 4711
SQLEND

# Test code for single-row queries.
$sql1 = "SELECT * FROM #a WHERE i = 24";

# Test for SELECT of NULL.
$sql_null = "SELECT NULL";

# Test code for empty result sets
$sql_empty = <<SQLEND;
SELECT * FROM #a WHERE i = 456
SELECT * FROM #a WHERE a = 'z'
SQLEND

$sql_print = "PRINT 'Tjolahopp!'";

$sql_counts = <<SQLEND;
SET NOCOUNT OFF
INSERT #b VALUES ('ABC')
DELETE #b
SQLEND

$sql_nocount = <<SQLEND;
SET NOCOUNT ON
INSERT #b VALUES ('ABC')
DELETE #b
SET NOCOUNT OFF
SQLEND

# Test code with incorrect SQL which will not produce even a resultset,
$sql_error = 'SELECT FROM';

# Test code for keyed access.
$sql_key1     = "SELECT * FROM #a";
sql("CREATE PROCEDURE #sql_key_many AS SELECT * FROM #c");

# Test code for duplicate column names in result set.
$sql_dupnames = <<SQLEND;
SELECT a = 11, "Col 4A" = 12, "Col 3" = 13, "Col 3" = 14, a = 15, a = 16, 17
UNION
SELECT -11, -12, -13, -14, -15, -16, -17
ORDER BY 1 DESC
SQLEND

#==================================================================
#========================= MULTISET ===============================
#==================================================================
{
   my (@result, $result, @expect);
   #----------------------- HASH ---------------------------
   &blurb("HASH, MULTISET, COLINFO_NONE, wantarray");
   @expect = ([{a => 'A', b => 'A', i => 12},
               {a => 'A', b => 'D', i => 24},
               {a => 'A', b => 'H', i => 1},
               {a => 'C', b => 'B', i => 12}],
              [{sum => 37},
               {sum => 12},
               {sum => 49}],
              [], [],
              [{x => 'xyz'},
               {x => undef}], [],
              [],
              [{'Col 1' => 4711}]);
   @result = sql($sql, MULTISET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET, COLINFO_NONE, wantscalar");
   $result = sql($sql, HASH, MULTISET);
   push(@testres, compare(\@expect, $result));

   &blurb("HASH, MULTISET, COLINFO_POS, wantarray");
   @expect = ([{a => 1, b => 2, i => 3},
               {a => 'A', b => 'A', i => 12},
               {a => 'A', b => 'D', i => 24},
               {a => 'A', b => 'H', i => 1},
               {a => 'C', b => 'B', i => 12}],
              [{sum => 1},
               {sum => 37},
               {sum => 12},
               {sum => 49}],
              [], [],
              [{x => 1},
               {x => 'xyz'},
               {x => undef}],
              [],
              [{a => 1, b => 2, i => 3}],
              [{'Col 1' => 1},
               {'Col 1' => 4711}]);
   @result = sql($sql, HASH, MULTISET, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET, COLINFO_POS, wantscalar");
   $result = sql($sql, COLINFO_POS, HASH, MULTISET);
   push(@testres, compare(\@expect, $result));

   &blurb("HASH, MULTISET, COLINFO_NAMES, wantarray");
   @expect = ([{a => 'a', b => 'b', i => 'i'},
               {a => 'A', b => 'A', i => 12},
               {a => 'A', b => 'D', i => 24},
               {a => 'A', b => 'H', i => 1},
               {a => 'C', b => 'B', i => 12}],
              [{sum => 'sum'},
               {sum => 37},
               {sum => 12},
               {sum => 49}],
              [], [],
              [{x => 'x'},
               {x => 'xyz'},
               {x => undef}],
              [],
              [{a => 'a',  b=> 'b', i => 'i'}],
              [{'Col 1' => ''},
               {'Col 1' => 4711}]);
   @result = sql($sql, MULTISET, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET, COLINFO_NAMES, wantscalar");
   $result = sql($sql, COLINFO_NAMES, MULTISET, HASH);
   push(@testres, compare(\@expect, $result));


   &blurb("HASH, MULTISET, COLINFO_FULL, wantarray");
   my $abc = {a => {Name => 'a', Colno => 1, Type => 'char'},
              b => {Name => 'b', Colno => 2, Type => 'char'},
              i => {Name => 'i', Colno => 3, Type => 'int'}};
   my $suminfo = {sum => {Name => 'sum', Colno => 1, Type => 'int'}};
   @expect = ([$abc,
               {a => 'A', b => 'A', i => 12},
               {a => 'A', b => 'D', i => 24},
               {a => 'A', b => 'H', i => 1},
               {a => 'C', b => 'B', i => 12}],
              [$suminfo,
               {sum => 37},
               {sum => 12},
               {sum => 49}],
              [], [],
              [{x => {Name => 'x', Colno => 1, Type => 'char'}},
               {x => 'xyz'},
               {x => undef}],
              [],
              [$abc],
              [{'Col 1' => {Name => '', Colno => 1, Type => 'int'}},
               {'Col 1' => 4711}]);
   @result = sql($sql, HASH, MULTISET, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET, COLINFO_FULL, wantscalar");
   $result = sql($sql, COLINFO_FULL, HASH, MULTISET);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 8;

   #----------------------- LIST -----------------------------------

   &blurb("LIST, MULTISET, COLINFO_NONE, wantarray");
   @expect = ([['A', 'A', 12],
               ['A', 'D', 24],
               ['A', 'H', 1],
               ['C', 'B', 12]],
              [[37],
               [12],
               [49]],
              [], [],
              [['xyz'],
               [undef]],
              [],
              [],
              [[4711]]);
   @result = sql($sql, LIST, MULTISET);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET, COLINFO_NONE, wantscalar");
   $result = sql($sql, LIST, MULTISET);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET, COLINFO_POS, wantarray");
   @expect = ([[1, 2, 3],
               ['A', 'A', 12],
               ['A', 'D', 24],
               ['A', 'H', 1],
               ['C', 'B', 12]],
              [[1],
               [37],
               [12],
               [49]],
              [], [],
              [[1],
               ['xyz'],
               [undef]],
              [],
              [[1, 2, 3]],
              [[1],
               [4711]]);
   @result = sql($sql, LIST, MULTISET, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET, COLINFO_POS, wantscalar");
   $result = sql($sql, LIST, COLINFO_POS, MULTISET);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET, COLINFO_NAMES, wantarray");
   @expect = ([['a', 'b', 'i'],
               ['A', 'A', 12],
               ['A', 'D', 24],
               ['A', 'H', 1],
               ['C', 'B', 12]],
              [['sum'],
               [37],
               [12],
               [49]],
              [], [],
              [['x'],
               ['xyz'],
               [undef]],
              [],
              [['a', 'b', 'i']],
              [[''],
               [4711]]);
   @result = sql($sql, MULTISET, COLINFO_NAMES, LIST);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET, COLINFO_NAMES, wantscalar");
   $result = sql($sql, LIST, COLINFO_NAMES, MULTISET);
   push(@testres, compare(\@expect, $result));


   &blurb("LIST, MULTISET, COLINFO_FULL, wantarray");
   $abc = [{Name => 'a', Colno => 1, Type => 'char'},
           {Name => 'b', Colno => 2, Type => 'char'},
           {Name => 'i', Colno => 3, Type => 'int'}];
   $suminfo = [{Name => 'sum', Colno => 1, Type => 'int'}];
   @expect = ([$abc,
               ['A', 'A', 12],
               ['A', 'D', 24],
               ['A', 'H', 1],
               ['C', 'B', 12]],
              [$suminfo,
               [37],
               [12],
               [49]],
              [], [],
              [[{Name => 'x', Colno => 1, Type => 'char'}],
               ['xyz'],
               [undef]],
              [],
              [$abc],
              [[{Name => '', Colno => 1, Type => 'int'}],
               [4711]]);
   @result = sql($sql, MULTISET, COLINFO_FULL, LIST);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET, COLINFO_FULL, wantscalar");
   $result = sql($sql, COLINFO_FULL, LIST, MULTISET);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 8;
   #-------------------------- SCALAR -------------------------------

   &blurb("SCALAR, MULTISET, COLINFO_NONE, wantarray");
   @expect = (['A@!@A@!@12',
               'A@!@D@!@24',
               'A@!@H@!@1',
               'C@!@B@!@12'],
              ['37',
               '12',
               '49'],
              [], [],
              ['xyz',
               undef],
              [],
              [],
              ['4711']);
   @result = sql($sql, MULTISET, SCALAR, COLINFO_NONE);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET, COLINFO_NONE, wantscalar");
   $result = sql($sql, SCALAR, MULTISET);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET, COLINFO_POS, wantarray");
   @expect = (['1@!@2@!@3',
               'A@!@A@!@12',
               'A@!@D@!@24',
               'A@!@H@!@1',
               'C@!@B@!@12'],
              ['1',
               '37',
               '12',
               '49'],
              [], [],
              ['1',
               'xyz',
               undef],
              [],
              ['1@!@2@!@3',],
              ['1',
               '4711']);
   @result = sql($sql, MULTISET, SCALAR, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET, COLINFO_POS, wantscalar");
   $result = sql($sql, COLINFO_POS, SCALAR, MULTISET);
   push(@testres, compare(\@expect, $result));


   &blurb("SCALAR, MULTISET, COLINFO_NAMES, wantarray");
   @expect = (['a@!@b@!@i',
               'A@!@A@!@12',
               'A@!@D@!@24',
               'A@!@H@!@1',
               'C@!@B@!@12'],
              ['sum',
               '37',
               '12',
               '49'],
              [], [],
              ['x',
               'xyz',
               undef],
              [],
              ['a@!@b@!@i',],
              ['',
               '4711']);
   @result = sql($sql, MULTISET, SCALAR, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET, COLINFO_NAMES, wantscalar");
   $result = sql($sql, COLINFO_NAMES, SCALAR, MULTISET);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET, COLINFO_FULL");
   eval('sql($sql, COLINFO_FULL, SCALAR, MULTISET)');
   push(@testres, $@ =~ /COLINFO_FULL cannot be combined.*SCALAR at/ ? 1 : 0);

   $no_of_tests += 7;
}

#--------------------- MULTISET empty, empty ------------------------
{
   my (@result, $result, @expect);

   #------------------ COLINFO_NONE --------------------------

   @expect = ([], []);
   &blurb("HASH, MULTISET empty, wantarray");
   @result = sql($sql_empty, HASH, MULTISET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET empty, wantscalar");
   $result = sql($sql_empty, HASH, MULTISET);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET empty, wantarray");
   @result = sql($sql_empty, LIST, MULTISET);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET empty, wantscalar");
   $result = sql($sql_empty, LIST, MULTISET);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET empty, wantarray");
   @result = sql($sql_empty, SCALAR, MULTISET);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET empty, wantscalar");
   $result = sql($sql_empty, SCALAR, MULTISET);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;

   #---------------------- COLINFO_POS -----------------------
   &blurb("HASH, MULTISET, COLINFO_POS empty, wantarray");
   @expect = ([{a => 1, b => 2, i => 3}], [{a => 1, b => 2, i => 3}]);
   @result = sql($sql_empty, HASH, MULTISET, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET, COLINFO_POS empty, wantscalar");
   $result = sql($sql_empty, HASH, MULTISET, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET, COLINFO_POS empty, wantarray");
   @expect = ([[1, 2, 3]], [[1, 2, 3]]);
   @result = sql($sql_empty, LIST, MULTISET, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET, COLINFO_POS empty, wantscalar");
   $result = sql($sql_empty, LIST, MULTISET, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET, COLINFO_POS empty, wantarray");
   @expect = (['1@!@2@!@3'], ['1@!@2@!@3']);
   @result = sql($sql_empty, SCALAR, MULTISET, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET, COLINFO_POS empty, wantscalar");
   $result = sql($sql_empty, SCALAR, MULTISET, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;

   #---------------------- COLINFO_NAMES -----------------------
   &blurb("HASH, MULTISET, COLINFO_NAMES empty, wantarray");
   @expect = ([{a => 'a', b => 'b', i => 'i'}], [{a => 'a', b => 'b', i => 'i'}]);
   @result = sql($sql_empty, HASH, MULTISET, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET, COLINFO_NAMES empty, wantscalar");
   $result = sql($sql_empty, HASH, MULTISET, COLINFO_NAMES);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET, COLINFO_NAMES empty, wantarray");
   @expect = ([['a', 'b', 'i']], [['a', 'b', 'i']]);
   @result = sql($sql_empty, LIST, MULTISET, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET, COLINFO_NAMES empty, wantscalar");
   $result = sql($sql_empty, LIST, MULTISET, COLINFO_NAMES);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET, COLINFO_NAMES empty, wantarray");
   @expect = (['a@!@b@!@i'], ['a@!@b@!@i']);
   @result = sql($sql_empty, SCALAR, MULTISET, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET, COLINFO_NAMES empty, wantscalar");
   $result = sql($sql_empty, SCALAR, MULTISET, COLINFO_NAMES);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;

   #---------------------- COLINFO_FULL -----------------------
   &blurb("HASH, MULTISET, COLINFO_FULL empty, wantarray");
   @expect = ([{a => {Name => 'a', Colno => 1, Type => 'char'},
                b => {Name => 'b', Colno => 2, Type => 'char'},
                i => {Name => 'i', Colno => 3, Type => 'int'}}],
              [{a => {Name => 'a', Colno => 1, Type => 'char'},
                b => {Name => 'b', Colno => 2, Type => 'char'},
                i => {Name => 'i', Colno => 3, Type => 'int'}}]);
   @result = sql($sql_empty, HASH, MULTISET, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET, COLINFO_FULL empty, wantscalar");
   $result = sql($sql_empty, HASH, MULTISET, COLINFO_FULL);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET, COLINFO_FULL empty, wantarray");
   @expect = ([[{Name => 'a', Colno => 1, Type => 'char'},
                {Name => 'b', Colno => 2, Type => 'char'},
                {Name => 'i', Colno => 3, Type => 'int'}]],
              [[{Name => 'a', Colno => 1, Type => 'char'},
                {Name => 'b', Colno => 2, Type => 'char'},
                {Name => 'i', Colno => 3, Type => 'int'}]]);
   @result = sql($sql_empty, LIST, MULTISET, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET, COLINFO_FULL empty, wantscalar");
   $result = sql($sql_empty, LIST, MULTISET, COLINFO_FULL);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 4;
}

#--------------------- MULTISET error   ------------------------
{
   my (@result, $result, @expect);

   @expect = ([]);
   &blurb("HASH, MULTISET error, wantarray");
   @result = sql($sql_error, HASH, MULTISET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET error, wantscalar");
   $result = sql($sql_error, HASH, MULTISET, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET error, wantarray");
   @result = sql($sql_error, LIST, MULTISET, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET error, wantscalar");
   $result = sql($sql_error, LIST, MULTISET);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET error, wantarray");
   @result = sql($sql_error, SCALAR, MULTISET, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET error, wantscalar");
   $result = sql($sql_error, SCALAR, MULTISET);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;
}

#--------------------- MULTISET print   ------------------------
{
   my (@result, $result, @expect);

   @expect = ([]);
   &blurb("HASH, MULTISET print, wantarray");
   @result = sql($sql_print, HASH, MULTISET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET print, wantscalar");
   $result = sql($sql_print, HASH, MULTISET, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET print, wantarray");
   @result = sql($sql_print, LIST, MULTISET, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET print, wantscalar");
   $result = sql($sql_print, LIST, MULTISET);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET print, wantarray");
   @result = sql($sql_print, SCALAR, MULTISET, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET print, wantscalar");
   $result = sql($sql_print, SCALAR, MULTISET);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;
}

#--------------------- MULTISET counts   ------------------------
{
   my (@result, $result, @expect);

   @expect = ([], []);
   &blurb("HASH, MULTISET counts, wantarray");
   @result = sql($sql_counts, HASH, MULTISET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET counts, wantscalar");
   $result = sql($sql_counts, HASH, MULTISET, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET counts, wantarray");
   @result = sql($sql_counts, LIST, MULTISET, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET counts, wantscalar");
   $result = sql($sql_counts, LIST, MULTISET);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET counts, wantarray");
   @result = sql($sql_counts, SCALAR, MULTISET, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET counts, wantscalar");
   $result = sql($sql_counts, SCALAR, MULTISET);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;
}

#--------------------- MULTISET nocount   ------------------------
{
   my (@result, $result, @expect);

   @expect = ([]);
   &blurb("HASH, MULTISET nocount, wantarray");
   @result = sql($sql_nocount, HASH, MULTISET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET nocount, wantscalar");
   $result = sql($sql_nocount, HASH, MULTISET, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET nocount, wantarray");
   @result = sql($sql_nocount, LIST, MULTISET, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET nocount, wantscalar");
   $result = sql($sql_nocount, LIST, MULTISET);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET nocount, wantarray");
   @result = sql($sql_nocount, SCALAR, MULTISET, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET nocount, wantscalar");
   $result = sql($sql_nocount, SCALAR, MULTISET);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;
}

#--------------------- MULTISET noexec   ------------------------
{
   my (@result, $result, @expect);

   $X->{NoExec} = 1;
   @expect = ();
   &blurb("HASH, MULTISET NoExec, wantarray");
   @result = sql($sql, HASH, MULTISET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET NoExec, wantscalar");
   $result = sql($sql, HASH, MULTISET, COLINFO_POS);
   push(@testres, compare(undef, $result));

   &blurb("LIST, MULTISET NoExec, wantarray");
   @result = sql($sql, COLINFO_FULL, LIST, MULTISET);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET NoExec, wantscalar");
   $result = sql($sql, LIST, MULTISET);
   push(@testres, compare(undef, $result));

   &blurb("SCALAR, MULTISET NoExec, wantarray");
   @result = sql($sql, SCALAR, COLINFO_NAMES, MULTISET);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET NoExec, wantscalar");
   $result = sql($sql, SCALAR, MULTISET);
   push(@testres, compare(undef, $result));
   $X->{NoExec} = 0;

   $no_of_tests += 6;
}


#==================================================================
#========================= MULTISET_RC ============================
#==================================================================
{
   my (@result, $result, @expect);
   #----------------------- HASH ---------------------------
   &blurb("HASH, MULTISET_RC, COLINFO_NONE, wantarray");
   @expect = ([{a => 'A', b => 'A', i => 12},
               {a => 'A', b => 'D', i => 24},
               {a => 'A', b => 'H', i => 1},
               {a => 'C', b => 'B', i => 12}],
              [{sum => 37},
               {sum => 12},
               {sum => 49}],
              1, 1,
              [{x => 'xyz'},
               {x => undef}],
              2,
              [],
              [{'Col 1' => 4711}]);
   @result = sql($sql, MULTISET_RC);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET_RC, COLINFO_NONE, wantscalar");
   $result = sql($sql, HASH, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   &blurb("HASH, MULTISET_RC, COLINFO_POS, wantarray");
   @expect = ([{a => 1, b => 2, i => 3},
               {a => 'A', b => 'A', i => 12},
               {a => 'A', b => 'D', i => 24},
               {a => 'A', b => 'H', i => 1},
               {a => 'C', b => 'B', i => 12}],
              [{sum => 1},
               {sum => 37},
               {sum => 12},
               {sum => 49}],
              1, 1,
              [{x => 1},
               {x => 'xyz'},
               {x => undef}],
              2,
              [{a => 1, b => 2, i => 3}],
              [{'Col 1' => 1},
               {'Col 1' => 4711}]);
   @result = sql($sql, HASH, MULTISET_RC, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET_RC, COLINFO_POS, wantscalar");
   $result = sql($sql, COLINFO_POS, HASH, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   &blurb("HASH, MULTISET_RC, COLINFO_NAMES, wantarray");
   @expect = ([{a => 'a', b => 'b', i => 'i'},
               {a => 'A', b => 'A', i => 12},
               {a => 'A', b => 'D', i => 24},
               {a => 'A', b => 'H', i => 1},
               {a => 'C', b => 'B', i => 12}],
              [{sum => 'sum'},
               {sum => 37},
               {sum => 12},
               {sum => 49}],
              1, 1,
              [{x => 'x'},
               {x => 'xyz'},
               {x => undef}],
              2,
              [{a => 'a',  b=> 'b', i => 'i'}],
              [{'Col 1' => ''},
               {'Col 1' => 4711}]);
   @result = sql($sql, MULTISET_RC, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET_RC, COLINFO_NAMES, wantscalar");
   $result = sql($sql, COLINFO_NAMES, MULTISET_RC, HASH);
   push(@testres, compare(\@expect, $result));


   &blurb("HASH, MULTISET_RC, COLINFO_FULL, wantarray");
   my $abc = {a => {Name => 'a', Colno => 1, Type => 'char'},
              b => {Name => 'b', Colno => 2, Type => 'char'},
              i => {Name => 'i', Colno => 3, Type => 'int'}};
   my $suminfo = {sum => {Name => 'sum', Colno => 1, Type => 'int'}};
   @expect = ([$abc,
               {a => 'A', b => 'A', i => 12},
               {a => 'A', b => 'D', i => 24},
               {a => 'A', b => 'H', i => 1},
               {a => 'C', b => 'B', i => 12}],
              [$suminfo,
               {sum => 37},
               {sum => 12},
               {sum => 49}],
              1, 1,
              [{x => {Name => 'x', Colno => 1, Type => 'char'}},
               {x => 'xyz'},
               {x => undef}],
              2,
              [$abc],
              [{'Col 1' => {Name => '', Colno => 1, Type => 'int'}},
               {'Col 1' => 4711}]);
   @result = sql($sql, HASH, MULTISET_RC, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET_RC, COLINFO_FULL, wantscalar");
   $result = sql($sql, COLINFO_FULL, HASH, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 8;

   #----------------------- LIST -----------------------------------

   &blurb("LIST, MULTISET_RC, COLINFO_NONE, wantarray");
   @expect = ([['A', 'A', 12],
               ['A', 'D', 24],
               ['A', 'H', 1],
               ['C', 'B', 12]],
              [[37],
               [12],
               [49]],
              1, 1,
              [['xyz'],
               [undef]],
              2,
              [],
              [[4711]]);
   @result = sql($sql, LIST, MULTISET_RC);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET_RC, COLINFO_NONE, wantscalar");
   $result = sql($sql, LIST, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET_RC, COLINFO_POS, wantarray");
   @expect = ([[1, 2, 3],
               ['A', 'A', 12],
               ['A', 'D', 24],
               ['A', 'H', 1],
               ['C', 'B', 12]],
              [[1],
               [37],
               [12],
               [49]],
              1, 1,
              [[1],
               ['xyz'],
               [undef]],
              2,
              [[1, 2, 3]],
              [[1],
               [4711]]);
   @result = sql($sql, LIST, MULTISET_RC, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET_RC, COLINFO_POS, wantscalar");
   $result = sql($sql, LIST, COLINFO_POS, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET_RC, COLINFO_NAMES, wantarray");
   @expect = ([['a', 'b', 'i'],
               ['A', 'A', 12],
               ['A', 'D', 24],
               ['A', 'H', 1],
               ['C', 'B', 12]],
              [['sum'],
               [37],
               [12],
               [49]],
              1, 1,
              [['x'],
               ['xyz'],
               [undef]],
              2,
              [['a', 'b', 'i']],
              [[''],
               [4711]]);
   @result = sql($sql, MULTISET_RC, COLINFO_NAMES, LIST);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET_RC, COLINFO_NAMES, wantscalar");
   $result = sql($sql, LIST, COLINFO_NAMES, MULTISET_RC);
   push(@testres, compare(\@expect, $result));


   &blurb("LIST, MULTISET_RC, COLINFO_FULL, wantarray");
   $abc = [{Name => 'a', Colno => 1, Type => 'char'},
           {Name => 'b', Colno => 2, Type => 'char'},
           {Name => 'i', Colno => 3, Type => 'int'}];
   $suminfo = [{Name => 'sum', Colno => 1, Type => 'int'}];
   @expect = ([$abc,
               ['A', 'A', 12],
               ['A', 'D', 24],
               ['A', 'H', 1],
               ['C', 'B', 12]],
              [$suminfo,
               [37],
               [12],
               [49]],
              1, 1,
              [[{Name => 'x', Colno => 1, Type => 'char'}],
               ['xyz'],
               [undef]],
              2,
              [$abc],
              [[{Name => '', Colno => 1, Type => 'int'}],
               [4711]]);
   @result = sql($sql, MULTISET_RC, COLINFO_FULL, LIST);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET_RC, COLINFO_FULL, wantscalar");
   $result = sql($sql, COLINFO_FULL, LIST, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 8;
   #-------------------------- SCALAR -------------------------------

   &blurb("SCALAR, MULTISET_RC, COLINFO_NONE, wantarray");
   @expect = (['A@!@A@!@12',
               'A@!@D@!@24',
               'A@!@H@!@1',
               'C@!@B@!@12'],
              ['37',
               '12',
               '49'],
              1, 1,
              ['xyz',
               undef],
              2,
              [],
              ['4711']);
   @result = sql($sql, MULTISET_RC, SCALAR, COLINFO_NONE);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET_RC, COLINFO_NONE, wantscalar");
   $result = sql($sql, SCALAR, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET_RC, COLINFO_POS, wantarray");
   @expect = (['1@!@2@!@3',
               'A@!@A@!@12',
               'A@!@D@!@24',
               'A@!@H@!@1',
               'C@!@B@!@12'],
              ['1',
               '37',
               '12',
               '49'],
              1, 1,
              ['1',
               'xyz',
               undef],
              2,
              ['1@!@2@!@3',],
              ['1',
               '4711']);
   @result = sql($sql, MULTISET_RC, SCALAR, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET_RC, COLINFO_POS, wantscalar");
   $result = sql($sql, COLINFO_POS, SCALAR, MULTISET_RC);
   push(@testres, compare(\@expect, $result));


   &blurb("SCALAR, MULTISET_RC, COLINFO_NAMES, wantarray");
   @expect = (['a@!@b@!@i',
               'A@!@A@!@12',
               'A@!@D@!@24',
               'A@!@H@!@1',
               'C@!@B@!@12'],
              ['sum',
               '37',
               '12',
               '49'],
              1, 1,
              ['x',
               'xyz',
               undef],
              2,
              ['a@!@b@!@i',],
              ['',
               '4711']);
   @result = sql($sql, MULTISET_RC, SCALAR, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET_RC, COLINFO_NAMES, wantscalar");
   $result = sql($sql, COLINFO_NAMES, SCALAR, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET_RC, COLINFO_FULL");
   eval('sql($sql, COLINFO_FULL, SCALAR, MULTISET_RC)');
   push(@testres, $@ =~ /COLINFO_FULL cannot be combined.*SCALAR at/ ? 1 : 0);

   $no_of_tests += 7;

}

#--------------------- MULTISET_RC empty, empty ------------------------
{
   my (@result, $result, @expect);

   #------------------ COLINFO_NONE --------------------------

   @expect = ([], []);
   &blurb("HASH, MULTISET_RC empty, wantarray");
   @result = sql($sql_empty, HASH, MULTISET_RC);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET_RC empty, wantscalar");
   $result = sql($sql_empty, HASH, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET_RC empty, wantarray");
   @result = sql($sql_empty, LIST, MULTISET_RC);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET_RC empty, wantscalar");
   $result = sql($sql_empty, LIST, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET_RC empty, wantarray");
   @result = sql($sql_empty, SCALAR, MULTISET_RC);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET_RC empty, wantscalar");
   $result = sql($sql_empty, SCALAR, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;

   #---------------------- COLINFO_POS -----------------------
   &blurb("HASH, MULTISET_RC, COLINFO_POS empty, wantarray");
   @expect = ([{a => 1, b => 2, i => 3}], [{a => 1, b => 2, i => 3}]);
   @result = sql($sql_empty, HASH, MULTISET_RC, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET_RC, COLINFO_POS empty, wantscalar");
   $result = sql($sql_empty, HASH, MULTISET_RC, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET_RC, COLINFO_POS empty, wantarray");
   @expect = ([[1, 2, 3]], [[1, 2, 3]]);
   @result = sql($sql_empty, LIST, MULTISET_RC, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET_RC, COLINFO_POS empty, wantscalar");
   $result = sql($sql_empty, LIST, MULTISET_RC, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET_RC, COLINFO_POS empty, wantarray");
   @expect = (['1@!@2@!@3'], ['1@!@2@!@3']);
   @result = sql($sql_empty, SCALAR, MULTISET_RC, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET_RC, COLINFO_POS empty, wantscalar");
   $result = sql($sql_empty, SCALAR, MULTISET_RC, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;

   #---------------------- COLINFO_NAMES -----------------------
   &blurb("HASH, MULTISET_RC, COLINFO_NAMES empty, wantarray");
   @expect = ([{a => 'a', b => 'b', i => 'i'}], [{a => 'a', b => 'b', i => 'i'}]);
   @result = sql($sql_empty, HASH, MULTISET_RC, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET_RC, COLINFO_NAMES empty, wantscalar");
   $result = sql($sql_empty, HASH, MULTISET_RC, COLINFO_NAMES);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET_RC, COLINFO_NAMES empty, wantarray");
   @expect = ([['a', 'b', 'i']], [['a', 'b', 'i']]);
   @result = sql($sql_empty, LIST, MULTISET_RC, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET_RC, COLINFO_NAMES empty, wantscalar");
   $result = sql($sql_empty, LIST, MULTISET_RC, COLINFO_NAMES);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET_RC, COLINFO_NAMES empty, wantarray");
   @expect = (['a@!@b@!@i'], ['a@!@b@!@i']);
   @result = sql($sql_empty, SCALAR, MULTISET_RC, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET_RC, COLINFO_NAMES empty, wantscalar");
   $result = sql($sql_empty, SCALAR, MULTISET_RC, COLINFO_NAMES);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;


   #---------------------- COLINFO_FULL -----------------------
   &blurb("HASH, MULTISET_RC, COLINFO_FULL empty, wantarray");
   @expect = ([{a => {Name => 'a', Colno => 1, Type => 'char'},
                b => {Name => 'b', Colno => 2, Type => 'char'},
                i => {Name => 'i', Colno => 3, Type => 'int'}}],
              [{a => {Name => 'a', Colno => 1, Type => 'char'},
                b => {Name => 'b', Colno => 2, Type => 'char'},
                i => {Name => 'i', Colno => 3, Type => 'int'}}]);
   @result = sql($sql_empty, HASH, MULTISET_RC, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET_RC, COLINFO_FULL empty, wantscalar");
   $result = sql($sql_empty, HASH, MULTISET_RC, COLINFO_FULL);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET_RC, COLINFO_FULL empty, wantarray");
   @expect = ([[{Name => 'a', Colno => 1, Type => 'char'},
                {Name => 'b', Colno => 2, Type => 'char'},
                {Name => 'i', Colno => 3, Type => 'int'}]],
              [[{Name => 'a', Colno => 1, Type => 'char'},
                {Name => 'b', Colno => 2, Type => 'char'},
                {Name => 'i', Colno => 3, Type => 'int'}]]);
   @result = sql($sql_empty, LIST, MULTISET_RC, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET_RC, COLINFO_FULL empty, wantscalar");
   $result = sql($sql_empty, LIST, MULTISET_RC, COLINFO_FULL);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 4;
}

#--------------------- MULTISET_RC error   ------------------------
{
   my (@result, $result, @expect);

   @expect = (-1);
   &blurb("HASH, MULTISET_RC error, wantarray");
   @result = sql($sql_error, HASH, MULTISET_RC);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET_RC error, wantscalar");
   $result = sql($sql_error, HASH, MULTISET_RC, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET_RC error, wantarray");
   @result = sql($sql_error, LIST, MULTISET_RC, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET_RC error, wantscalar");
   $result = sql($sql_error, LIST, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET_RC error, wantarray");
   @result = sql($sql_error, SCALAR, MULTISET_RC, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET_RC error, wantscalar");
   $result = sql($sql_error, SCALAR, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;
}

#--------------------- MULTISET_RC print   ------------------------
{
   my (@result, $result, @expect);

   @expect = (-1);
   &blurb("HASH, MULTISET_RC print, wantarray");
   @result = sql($sql_print, HASH, MULTISET_RC);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET_RC print, wantscalar");
   $result = sql($sql_print, HASH, MULTISET_RC, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET_RC print, wantarray");
   @result = sql($sql_print, LIST, MULTISET_RC, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET_RC print, wantscalar");
   $result = sql($sql_print, LIST, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET_RC print, wantarray");
   @result = sql($sql_print, SCALAR, MULTISET_RC, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET_RC print, wantscalar");
   $result = sql($sql_print, SCALAR, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;
}

#--------------------- MULTISET_RC counts   ------------------------
{
   my (@result, $result, @expect);

   @expect = (1, 1);
   &blurb("HASH, MULTISET_RC counts, wantarray");
   @result = sql($sql_counts, HASH, MULTISET_RC);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET_RC counts, wantscalar");
   $result = sql($sql_counts, HASH, MULTISET_RC, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET_RC counts, wantarray");
   @result = sql($sql_counts, LIST, MULTISET_RC, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET_RC counts, wantscalar");
   $result = sql($sql_counts, LIST, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET_RC counts, wantarray");
   @result = sql($sql_counts, SCALAR, MULTISET_RC, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET_RC counts, wantscalar");
   $result = sql($sql_counts, SCALAR, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;
}

#--------------------- MULTISET_RC nocount   ------------------------
{
   my (@result, $result, @expect);

   @expect = (-1);
   &blurb("HASH, MULTISET_RC nocount, wantarray");
   @result = sql($sql_nocount, HASH, MULTISET_RC);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET_RC nocount, wantscalar");
   $result = sql($sql_nocount, HASH, MULTISET_RC, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, MULTISET_RC nocount, wantarray");
   @result = sql($sql_nocount, LIST, MULTISET_RC, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET_RC nocount, wantscalar");
   $result = sql($sql_nocount, LIST, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, MULTISET_RC nocount, wantarray");
   @result = sql($sql_nocount, SCALAR, MULTISET_RC, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET_RC nocount, wantscalar");
   $result = sql($sql_nocount, SCALAR, MULTISET_RC);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;
}

#--------------------- MULTISET_RC noexec   ------------------------
{
   my (@result, $result, @expect);

   $X->{NoExec} = 1;
   @expect = ();
   &blurb("HASH, MULTISET_RC NoExec, wantarray");
   @result = sql($sql, HASH, MULTISET_RC);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, MULTISET_RC NoExec, wantscalar");
   $result = sql($sql, HASH, MULTISET_RC, COLINFO_POS);
   push(@testres, compare(undef, $result));

   &blurb("LIST, MULTISET_RC NoExec, wantarray");
   @result = sql($sql, COLINFO_FULL, LIST, MULTISET_RC);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, MULTISET_RC NoExec, wantscalar");
   $result = sql($sql, LIST, MULTISET_RC);
   push(@testres, compare(undef, $result));

   &blurb("SCALAR, MULTISET_RC NoExec, wantarray");
   @result = sql($sql, SCALAR, COLINFO_NAMES, MULTISET_RC);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, MULTISET_RC NoExec, wantscalar");
   $result = sql($sql, SCALAR, MULTISET_RC);
   push(@testres, compare(undef, $result));
   $X->{NoExec} = 0;

   $no_of_tests += 6;
}


#==================================================================
#========================= SINGLESET ==============================
#==================================================================
{
   my (@result, $result, @expect);

   #----------------------- HASH ------------------------------
   &blurb("HASH, SINGLESET, COLINFO_NONE, wantarray");
   @expect = ({a => 'A', b => 'A', i => 12},
              {a => 'A', b => 'D', i => 24},
              {a => 'A', b => 'H', i => 1},
              {a => 'C', b => 'B', i => 12},
              {sum => 37},
              {sum => 12},
              {sum => 49},
              {'x' => 'xyz'},
              {'x' => undef},
              {'Col 1' => 4711});
   @result = sql($sql);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, SINGLESET, wantscalar");
   $result = sql($sql, COLINFO_NONE);
   push(@testres, compare(\@expect, $result));

   &blurb("HASH, SINGLESET, COLINFO_POS, wantarray");
   @expect = ({a => 1, b => 2, i => 3},
              {a => 'A', b => 'A', i => 12},
              {a => 'A', b => 'D', i => 24},
              {a => 'A', b => 'H', i => 1},
              {a => 'C', b => 'B', i => 12},
              {sum => 37},
              {sum => 12},
              {sum => 49},
              {'x' => 'xyz'},
              {'x' => undef},
              {'Col 1' => 4711});
   @result = sql($sql, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, SINGLESET, COLINFO_POS, wantscalar");
   $result = sql($sql, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   &blurb("HASH, SINGLESET, COLINFO_NAMES, wantarray");
   @expect = ({a => 'a', b => 'b', i => 'i'},
              {a => 'A', b => 'A', i => 12},
              {a => 'A', b => 'D', i => 24},
              {a => 'A', b => 'H', i => 1},
              {a => 'C', b => 'B', i => 12},
              {sum => 37},
              {sum => 12},
              {sum => 49},
              {'x' => 'xyz'},
              {'x' => undef},
              {'Col 1' => 4711});
   @result = sql($sql, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, SINGLESET, COLINFO_NAMES, wantscalar");
   $result = sql($sql, COLINFO_NAMES);
   push(@testres, compare(\@expect, $result));

   &blurb("HASH, SINGLESET, COLINFO_FULL, wantarray");
   @expect = ({a => {Name => 'a', Colno => 1, Type => 'char'},
               b => {Name => 'b', Colno => 2, Type => 'char'},
               i => {Name => 'i', Colno => 3, Type => 'int'}},
              {a => 'A', b => 'A', i => 12},
              {a => 'A', b => 'D', i => 24},
              {a => 'A', b => 'H', i => 1},
              {a => 'C', b => 'B', i => 12},
              {sum => 37},
              {sum => 12},
              {sum => 49},
              {'x' => 'xyz'},
              {'x' => undef},
              {'Col 1' => 4711});
   @result = sql($sql, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, SINGLESET, COLINFO_FULL, wantscalar");
   $result = sql($sql, COLINFO_FULL);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 8;

   #-------------------------- LIST -----------------------------
   &blurb("LIST, SINGLESET, COLINFO_NONE, wantarray");
   @expect = (['A', 'A', 12],
              ['A', 'D', 24],
              ['A', 'H', 1],
              ['C', 'B', 12],
              [37],
              [12],
              [49],
              ['xyz'],
              [undef],
              [4711]);
   @result = sql($sql, LIST, COLINFO_NONE);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLESET, wantscalar");
   $result = sql($sql, undef, LIST);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, SINGLESET, COLINFO_POS, wantarray");
   @expect = ([1, 2, 3],
              ['A', 'A', 12],
              ['A', 'D', 24],
              ['A', 'H', 1],
              ['C', 'B', 12],
              [37],
              [12],
              [49],
              ['xyz'],
              [undef],
              [4711]);
   @result = sql($sql, LIST, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLESET, wantscalar");
   $result = sql($sql, COLINFO_POS, undef, LIST);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, SINGLESET, COLINFO_NAMES, wantarray");
   @expect = (['a', 'b', 'i'],
              ['A', 'A', 12],
              ['A', 'D', 24],
              ['A', 'H', 1],
              ['C', 'B', 12],
              [37],
              [12],
              [49],
              ['xyz'],
              [undef],
              [4711]);
   @result = sql($sql, LIST, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLESET, wantscalar");
   $result = sql($sql, COLINFO_NAMES, undef, LIST);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, SINGLESET, COLINFO_FULL, wantarray");
   @expect = ([{Name => 'a', Colno => 1, Type => 'char'},
               {Name => 'b', Colno => 2, Type => 'char'},
               {Name => 'i', Colno => 3, Type => 'int'}],
              ['A', 'A', 12],
              ['A', 'D', 24],
              ['A', 'H', 1],
              ['C', 'B', 12],
              [37],
              [12],
              [49],
              ['xyz'],
              [undef],
              [4711]);
   @result = sql($sql, LIST, COLINFO_FULL);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLESET, wantscalar");
   $result = sql($sql, COLINFO_FULL, undef, LIST);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 8;

   #--------------------- SCALAR -------------------------------

   &blurb("SCALAR, SINGLESET, COLINFO_NONE, wantarray");
   @expect = ('A@!@A@!@12',
              'A@!@D@!@24',
              'A@!@H@!@1',
              'C@!@B@!@12',
              '37',
              '12',
              '49',
              'xyz',
              undef,
              '4711');
   @result = sql($sql, SCALAR);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLESET, COLINFO_NONE, wantscalar");
   $result = sql($sql, SCALAR);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, SINGLESET, COLINFO_POS, wantarray");
   @expect = ('1@!@2@!@3',
              'A@!@A@!@12',
              'A@!@D@!@24',
              'A@!@H@!@1',
              'C@!@B@!@12',
              '37',
              '12',
              '49',
              'xyz',
              undef,
              '4711');
   @result = sql($sql, COLINFO_POS, undef, SCALAR);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLESET, COLINFO_POS, wantscalar");
   $result = sql($sql, SCALAR, undef, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, SINGLESET, COLINFO_NAMES, wantarray");
   @expect = ('a@!@b@!@i',
              'A@!@A@!@12',
              'A@!@D@!@24',
              'A@!@H@!@1',
              'C@!@B@!@12',
              '37',
              '12',
              '49',
              'xyz',
              undef,
              '4711');
   @result = sql($sql, COLINFO_NAMES, undef, SCALAR);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLESET, COLINFO_NAMES, wantscalar");
   $result = sql($sql, SCALAR, undef, COLINFO_NAMES);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, SINGLESET, COLINFO_FULL");
   eval('sql($sql, SCALAR, COLINFO_FULL, SINGLESET)');
   push(@testres, $@ =~ /COLINFO_FULL cannot be combined.*SCALAR at/ ? 1 : 0);

   $no_of_tests += 7;
}

#--------------------- SINGLESET, empty ------------------------
{
   my (@result, $result, @expect);

   #--------------------- COLINFO_NONE -------------------------

   @expect = ();
   &blurb("HASH, SINGLESET empty, wantarray");
   @result = sql($sql_empty, HASH, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, SINGLESET empty, wantscalar");
   $result = sql($sql_empty, HASH, SINGLESET);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, SINGLESET empty, wantarray");
   @result = sql($sql_empty, LIST, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLESET empty, wantscalar");
   $result = sql($sql_empty, LIST, SINGLESET);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, SINGLESET empty, wantarray");
   @result = sql($sql_empty, SCALAR, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLESET empty, wantscalar");
   $result = sql($sql_empty, SCALAR, SINGLESET);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;


   #--------------------- COLINFO_POS -------------------------
   @expect = ({a => 1, b => 2, i => 3});
   &blurb("HASH, SINGLESET, COLINFO_POS empty, wantarray");
   @result = sql($sql_empty, HASH, COLINFO_POS, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, SINGLESET, COLINFO_POS empty, wantscalar");
   $result = sql($sql_empty, COLINFO_POS, HASH, SINGLESET);
   push(@testres, compare(\@expect, $result));

   @expect = ([1, 2, 3]);
   &blurb("LIST, SINGLESET, COLINFO_POS empty, wantarray");
   @result = sql($sql_empty, COLINFO_POS, LIST, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLESET, COLINFO_POS empty, wantscalar");
   $result = sql($sql_empty, LIST, COLINFO_POS, SINGLESET);
   push(@testres, compare(\@expect, $result));

   @expect = ('1@!@2@!@3');
   &blurb("SCALAR, SINGLESET, COLINFO_POS empty, wantarray");
   @result = sql($sql_empty, SCALAR, SINGLESET, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLESET, COLINFO_POS empty, wantscalar");
   $result = sql($sql_empty, SCALAR, SINGLESET, COLINFO_POS);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;

   #--------------------- COLINFO_NAMES -------------------------
   @expect = ({a => 'a', b => 'b', i => 'i'});
   &blurb("HASH, SINGLESET, COLINFO_NAMES empty, wantarray");
   @result = sql($sql_empty, HASH, COLINFO_NAMES, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, SINGLESET, COLINFO_NAMES empty, wantscalar");
   $result = sql($sql_empty, COLINFO_NAMES, HASH, SINGLESET);
   push(@testres, compare(\@expect, $result));

   @expect = (['a', 'b', 'i']);
   &blurb("LIST, SINGLESET, COLINFO_NAMES empty, wantarray");
   @result = sql($sql_empty, COLINFO_NAMES, LIST, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLESET, COLINFO_NAMES empty, wantscalar");
   $result = sql($sql_empty, LIST, COLINFO_NAMES, SINGLESET);
   push(@testres, compare(\@expect, $result));

   @expect = ('a@!@b@!@i');
   &blurb("SCALAR, SINGLESET, COLINFO_NAMES empty, wantarray");
   @result = sql($sql_empty, SCALAR, SINGLESET, COLINFO_NAMES);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLESET, COLINFO_NAMES empty, wantscalar");
   $result = sql($sql_empty, SCALAR, SINGLESET, COLINFO_NAMES);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;

   #--------------------- COLINFO_FULL -------------------------
   @expect = ({a => {Name => 'a', Colno => 1, Type => 'char'},
               b => {Name => 'b', Colno => 2, Type => 'char'},
               i => {Name => 'i', Colno => 3, Type => 'int'}});
   &blurb("HASH, SINGLESET, COLINFO_FULL empty, wantarray");
   @result = sql($sql_empty, HASH, COLINFO_FULL, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, SINGLESET, COLINFO_FULL empty, wantscalar");
   $result = sql($sql_empty, COLINFO_FULL, HASH, SINGLESET);
   push(@testres, compare(\@expect, $result));

   @expect = ([{Name => 'a', Colno => 1, Type => 'char'},
               {Name => 'b', Colno => 2, Type => 'char'},
               {Name => 'i', Colno => 3, Type => 'int'}]);
   &blurb("LIST, SINGLESET, COLINFO_FULL empty, wantarray");
   @result = sql($sql_empty, COLINFO_FULL, LIST, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLESET, COLINFO_FULL empty, wantscalar");
   $result = sql($sql_empty, LIST, COLINFO_FULL, SINGLESET);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 4;
}

#-------------------- SINGLESET, error ----------------------
{
   my (@result, $result, @expect);

   @expect = ();
   &blurb("HASH, SINGLESET error, wantarray");
   @result = sql($sql_error, HASH, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, SINGLESET error, wantscalar");
   $result = sql($sql_error, COLINFO_FULL);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, SINGLESET error, wantarray");
   @result = sql($sql_error, LIST, SINGLESET, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLESET error, wantscalar");
   $result = sql($sql_error, LIST, SINGLESET);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, SINGLESET error, wantarray");
   @result = sql($sql_error, SCALAR, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLESET error, wantscalar");
   $result = sql($sql_error, COLINFO_NAMES, SCALAR, SINGLESET);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;
}

#-------------------- SINGLESET, print ----------------------
{
   my (@result, $result, @expect);

   @expect = ();
   &blurb("HASH, SINGLESET print, wantarray");
   @result = sql($sql_print, HASH, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, SINGLESET print, wantscalar");
   $result = sql($sql_print, COLINFO_FULL);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, SINGLESET print, wantarray");
   @result = sql($sql_print, LIST, SINGLESET, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLESET print, wantscalar");
   $result = sql($sql_print, LIST, SINGLESET);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, SINGLESET print, wantarray");
   @result = sql($sql_print, SCALAR, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLESET print, wantscalar");
   $result = sql($sql_print, COLINFO_NAMES, SCALAR, SINGLESET);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;
}


#-------------------- SINGLESET, counts ----------------------
{
   my (@result, $result, @expect);

   @expect = ();
   &blurb("HASH, SINGLESET counts, wantarray");
   @result = sql($sql_counts, HASH, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, SINGLESET counts, wantscalar");
   $result = sql($sql_counts, COLINFO_FULL);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, SINGLESET counts, wantarray");
   @result = sql($sql_counts, LIST, SINGLESET, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLESET counts, wantscalar");
   $result = sql($sql_counts, LIST, SINGLESET);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, SINGLESET counts, wantarray");
   @result = sql($sql_counts, SCALAR, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLESET counts, wantscalar");
   $result = sql($sql_counts, COLINFO_NAMES, SCALAR, SINGLESET);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;
}

#-------------------- SINGLESET, nocount ----------------------
{
   my (@result, $result, @expect);

   @expect = ();
   &blurb("HASH, SINGLESET nocount, wantarray");
   @result = sql($sql_nocount, HASH, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, SINGLESET nocount, wantscalar");
   $result = sql($sql_nocount, COLINFO_FULL);
   push(@testres, compare(\@expect, $result));

   &blurb("LIST, SINGLESET nocount, wantarray");
   @result = sql($sql_nocount, LIST, SINGLESET, COLINFO_POS);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLESET nocount, wantscalar");
   $result = sql($sql_nocount, LIST, SINGLESET);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, SINGLESET nocount, wantarray");
   @result = sql($sql_nocount, SCALAR, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLESET nocount, wantscalar");
   $result = sql($sql_nocount, COLINFO_NAMES, SCALAR, SINGLESET);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 6;
}


#-------------------- SINGLESET, NoExec ----------------------
{
   my (@result, $result, @expect);

   $X->{NoExec} = 1;
   @expect = ();
   &blurb("HASH, SINGLESET NoExec, wantarray");
   @result = sql($sql, HASH, COLINFO_POS, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("HASH, SINGLESET NoExec, wantscalar");
   $result = sql($sql, HASH, SINGLESET);
   push(@testres, compare(undef, $result));

   &blurb("LIST, SINGLESET NoExec, wantarray");
   @result = sql($sql, LIST, COLINFO_NAMES, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLESET NoExec, wantscalar");
   $result = sql($sql, LIST, SINGLESET);
   push(@testres, compare(undef, $result));

   &blurb("SCALAR, SINGLESET NoExec, wantarray");
   @result = sql($sql, SCALAR, SINGLESET);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLESET NoExec, wantscalar");
   $result = sql($sql, SCALAR, SINGLESET);
   push(@testres, compare(undef, $result));
   $X->{NoExec} = 0;

   $no_of_tests += 6;
}

#==================================================================
#========================= SINGLEROW ==============================
#==================================================================
{
   my (@result, %result, $result, @expect, %expect, $expect);

   #--------------------------- COLINFO_NONE -------------------

   &blurb("HASH, SINGLEROW, wantarray");
   %expect = (a => 'A', b => 'D', i => 24);
   %result = sql($sql1, undef, SINGLEROW);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, SINGLEROW, wantscalar");
   $result = sql($sql1, SINGLEROW, undef);
   push(@testres, compare(\%expect, $result));

   &blurb("LIST, SINGLEROW, wantarray");
   @expect = ('A', 'D', 24);
   @result = sql($sql1, LIST, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLEROW, wantscalar");
   $result = sql($sql1, LIST, SINGLEROW);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, SINGLEROW, wantarray");
   @expect = ('A@!@D@!@24');
   @result = sql($sql1, SCALAR, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLEROW, wantscalar");
   $expect = 'A@!@D@!@24';
   $result = sql($sql1, SCALAR, SINGLEROW);
   push(@testres, compare($expect, $result));

   $no_of_tests += 6;

   #--------------------- Other COLINFO ----------------------------
   &blurb("HASH, SINGLEROW, COLINFO_POS");
   eval('sql($sql, COLINFO_POS, HASH, SINGLEROW)');
   push(@testres, $@ =~ /SINGLEROW.*cannot request.*\$colinfostyle at/ ? 1 : 0);

   &blurb("LIST, SINGLEROW, COLINFO_FULL");
   eval('sql($sql, COLINFO_FULL, LIST, SINGLEROW)');
   push(@testres, $@ =~ /SINGLEROW.*cannot request.*\$colinfostyle at/ ? 1 : 0);

   &blurb("SCALAR, SINGLEROW, COLINFO_NAMES");
   eval('sql($sql, COLINFO_NAMES, SCALAR, SINGLEROW)');
   push(@testres, $@ =~ /SINGLEROW.*cannot request.*\$colinfostyle at/ ? 1 : 0);

   $no_of_tests += 3;
}

#-------------------- SINGLEROW, SELECT NULL---------------------------
{
   my (@result, %result, $result, @expect, %expect, $expect);

   &blurb("HASH, SINGLEROW NULL, wantarray");
   %expect = ('Col 1' => undef);
   %result = sql($sql_null, undef, SINGLEROW);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, SINGLEROW NULL, wantscalar");
   $result = sql($sql_null, SINGLEROW, undef);
   push(@testres, compare(\%expect, $result));

   &blurb("LIST, SINGLEROW NULL, wantarray");
   @expect = (undef);
   @result = sql($sql_null, LIST, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLEROW NULL, wantscalar");
   $result = sql($sql_null, LIST, SINGLEROW);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, SINGLEROW NULL, wantarray");
   @expect = (undef);
   @result = sql($sql_null, SCALAR, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLEROW NULL, wantscalar");
   $expect = undef;
   $result = sql($sql_null, SCALAR, SINGLEROW);
   push(@testres, compare($expect, $result));

   $no_of_tests += 6;
}

#--------------- SINGLEROW, first result empty ----------------------------
{
   my (@result, %result, $result, @expect, %expect, $expect);

   &blurb("HASH, SINGLEROW first empty, wantarray");
   %expect = (a => 'A', b => 'D', i => 24);
   %result = sql("$sql_empty $sql1", undef, SINGLEROW);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, SINGLEROW first empty, wantscalar");
   $result = sql("$sql_empty $sql1", SINGLEROW, undef);
   push(@testres, compare(\%expect, $result));

   &blurb("LIST, SINGLEROW first empty, wantarray");
   @expect = ('A', 'D', 24);
   @result = sql("$sql_empty $sql1", LIST, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLEROW first empty, wantscalar");
   $result = sql("$sql_empty $sql1", LIST, SINGLEROW);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, SINGLEROW first empty, wantarray");
   @expect = ('A@!@D@!@24');
   @result = sql("$sql_empty $sql1", SCALAR, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLEROW first empty, wantscalar");
   $expect = 'A@!@D@!@24';
   $result = sql("$sql_empty $sql1", SCALAR, SINGLEROW);
   push(@testres, compare($expect, $result));

   $no_of_tests += 6;
}

#--------------------- SINGLEROW, empty ------------------------
{
   my (@result, %result, $result, @expect, %expect);
   @expect = %expect = ();

   &blurb("HASH, SINGLEROW empty, wantarray");
   %result = sql($sql_empty, HASH, SINGLEROW);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, SINGLEROW empty, wantscalar");
   $result = sql($sql_empty, HASH, SINGLEROW);
   push(@testres, compare(undef, $result));

   &blurb("LIST, SINGLEROW empty, wantarray");
   @result = sql($sql_empty, LIST, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLEROW empty, wantscalar");
   $result = sql($sql_empty, LIST, SINGLEROW);
   push(@testres, compare(undef, $result));

   &blurb("SCALAR, SINGLEROW empty, wantarray");
   @result = sql($sql_empty, SCALAR, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLEROW empty, wantscalar");
   $result = sql($sql_empty, SCALAR, SINGLEROW);
   push(@testres, compare(undef, $result));

   $no_of_tests += 6;
}

#--------------------- SINGLEROW, error -------------------
{
   my (@result, %result, $result, @expect, %expect);

   @expect = %expect = ();

   &blurb("HASH, SINGLEROW error, wantarray");
   %result = sql($sql_error, HASH, SINGLEROW);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, SINGLEROW error, wantscalar");
   $result = sql($sql_error, HASH, SINGLEROW);
   push(@testres, compare(undef, $result));

   &blurb("LIST, SINGLEROW error, wantarray");
   @result = sql($sql_error, LIST, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLEROW error, wantscalar");
   $result = sql($sql_error, LIST, SINGLEROW);
   push(@testres, compare(undef, $result));

   &blurb("SCALAR, SINGLEROW error, wantarray");
   @result = sql($sql_error, SCALAR, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLEROW error, wantscalar");
   $result = sql($sql_error, SCALAR, SINGLEROW);
   push(@testres, compare(undef, $result));

   $no_of_tests += 6;
}

#--------------------- SINGLEROW, print -------------------
{
   my (@result, %result, $result, @expect, %expect);

   @expect = %expect = ();

   &blurb("HASH, SINGLEROW print, wantarray");
   %result = sql($sql_print, HASH, SINGLEROW);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, SINGLEROW print, wantscalar");
   $result = sql($sql_print, HASH, SINGLEROW);
   push(@testres, compare(undef, $result));

   &blurb("LIST, SINGLEROW print, wantarray");
   @result = sql($sql_print, LIST, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLEROW print, wantscalar");
   $result = sql($sql_print, LIST, SINGLEROW);
   push(@testres, compare(undef, $result));

   &blurb("SCALAR, SINGLEROW print, wantarray");
   @result = sql($sql_print, SCALAR, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLEROW print, wantscalar");
   $result = sql($sql_print, SCALAR, SINGLEROW);
   push(@testres, compare(undef, $result));

   $no_of_tests += 6;
}

#--------------------- SINGLEROW, counts -------------------
{
   my (@result, %result, $result, @expect, %expect);

   @expect = %expect = ();

   &blurb("HASH, SINGLEROW counts, wantarray");
   %result = sql($sql_counts, HASH, SINGLEROW);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, SINGLEROW counts, wantscalar");
   $result = sql($sql_counts, HASH, SINGLEROW);
   push(@testres, compare(undef, $result));

   &blurb("LIST, SINGLEROW counts, wantarray");
   @result = sql($sql_counts, LIST, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLEROW counts, wantscalar");
   $result = sql($sql_counts, LIST, SINGLEROW);
   push(@testres, compare(undef, $result));

   &blurb("SCALAR, SINGLEROW counts, wantarray");
   @result = sql($sql_counts, SCALAR, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLEROW counts, wantscalar");
   $result = sql($sql_counts, SCALAR, SINGLEROW);
   push(@testres, compare(undef, $result));

   $no_of_tests += 6;
}

#--------------------- SINGLEROW, nocount -------------------
{
   my (@result, %result, $result, @expect, %expect);

   @expect = %expect = ();

   &blurb("HASH, SINGLEROW nocount, wantarray");
   %result = sql($sql_nocount, HASH, SINGLEROW);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, SINGLEROW nocount, wantscalar");
   $result = sql($sql_nocount, HASH, SINGLEROW);
   push(@testres, compare(undef, $result));

   &blurb("LIST, SINGLEROW nocount, wantarray");
   @result = sql($sql_nocount, LIST, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLEROW nocount, wantscalar");
   $result = sql($sql_nocount, LIST, SINGLEROW);
   push(@testres, compare(undef, $result));

   &blurb("SCALAR, SINGLEROW nocount, wantarray");
   @result = sql($sql_nocount, SCALAR, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLEROW nocount, wantscalar");
   $result = sql($sql_nocount, SCALAR, SINGLEROW);
   push(@testres, compare(undef, $result));

   $no_of_tests += 6;
}

#--------------------- SINGLEROW, NoExec -------------------
{
   my (@result, %result, $result, @expect, %expect);

   $X->{NoExec} = 1;
   @expect = %expect = ();
   &blurb("HASH, SINGLEROW NoExec, wantarray");
   %result = sql($sql, HASH, SINGLEROW);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, SINGLEROW NoExec, wantscalar");
   $result = sql($sql, HASH, SINGLEROW);
   push(@testres, compare(undef, $result));

   &blurb("LIST, SINGLEROW NoExec, wantarray");
   @result = sql($sql, LIST, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, SINGLEROW NoExec, wantscalar");
   $result = sql($sql, LIST, SINGLEROW);
   push(@testres, compare(undef, $result));

   &blurb("SCALAR, SINGLEROW NoExec, wantarray");
   @result = sql($sql, SCALAR, SINGLEROW);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, SINGLEROW NoExec, wantscalar");
   $result = sql($sql, SCALAR, SINGLEROW);
   push(@testres, compare(undef, $result));
   $X->{NoExec} = 0;

   $no_of_tests += 6;
}

#==================================================================
#========================== sql_one ===============================
#==================================================================
{
   my (@result, %result, $result, @expect, %expect, $expect);

   &blurb("HASH, sql_one, wantarray");
   %expect = (a => 'A', b => 'D', i => 24);
   %result = sql_one($sql1);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, sql_one, wantscalar");
   $result = sql_one($sql1, HASH);
   push(@testres, compare(\%expect, $result));

   &blurb("LIST, sql_one, wantarray");
   @expect = ('A', 'D', 24);
   @result = sql_one($sql1, LIST);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, sql_one, wantscalar");
   $result = sql_one($sql1, LIST);
   push(@testres, compare(\@expect, $result));

   &blurb("SCALAR, sql_one, wantscalar");
   $expect = 'A@!@D@!@24';
   $result = sql_one($sql1);
   push(@testres, compare($expect, $result));

   &blurb("SCALAR, sql_one, two ressets, one row");
   $result = sql_one("SELECT * FROM #b WHERE 1 = 0 $sql1");
   push(@testres, compare($expect, $result));

   &blurb("SCALAR, sql_one, one-NULL col, wantscalar");
   $expect = undef;
   $result = sql_one("SELECT NULL");
   push(@testres, compare($expect, $result));

   &blurb("SCALAR, sql_one, two-NULL cols, wantscalar");
   $expect = '@!@';
   $result = sql_one("SELECT NULL, NULL");
   push(@testres, compare($expect, $result));

   &blurb("sql_one, fail: no rows");
   eval("sql_one('SELECT * FROM #a WHERE i = 897')");
   push(@testres, ($@ =~ /returned no/ ? 1 : 0));

   &blurb("sql_one, fail: too many rows");
   eval("sql_one('SELECT * FROM #a')");
   push(@testres, ($@ =~ /more than one/ ? 1 : 0));

   &blurb("sql_one, fail: two ressets, two rows");
   eval("sql_one('SELECT 1 SELECT 2')");
   push(@testres, ($@ =~ /more than one/ ? 1 : 0));

   &blurb("sql_one, fail: syntax error => no rows");
   eval("sql_one('$sql_error')");
   push(@testres, ($@ =~ /returned no/ ? 1 : 0));

   &blurb("sql_one, fail: type error => no rwows.");
   eval("sql_one('SELECT * FROM #a WHERE i = ?', [['notype', 2]])");
   push(@testres, ($@ =~ /returned no/ ? 1 : 0));

   $no_of_tests += 13;
}

#-------------------- sql_one, NoExec ----------------------------
{
   my (@result, %result, $result, @expect, %expect, $expect);
   $X->{NoExec} = 1;
   @expect = %expect = ();
   $expect = undef;

   &blurb("HASH, sql_one NoExec, wantarray");
   %result = sql_one($sql1);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, sql_one NoExec, wantscalar");
   $result = sql_one($sql1, HASH);
   push(@testres, compare(undef, $result));

   &blurb("LIST, sql_one NoExec, wantarray");
   @result = sql_one($sql1, LIST);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, sql_one NoExec, wantscalar");
   $result = sql_one($sql1, LIST);
   push(@testres, compare(undef, $result));

   &blurb("SCALAR, sql_one NoExec, wantscalar");
   $result = sql_one($sql1);
   push(@testres, compare($expect, $result));

   &blurb("SCALAR, sql_one NoExec, two ressets, one row");
   $result = sql_one("SELECT * FROM #b WHERE 1 = 0 $sql1");
   push(@testres, compare($expect, $result));

   &blurb("sql_one NoExec, no rows");
   $result = sql_one('SELECT * FROM #a WHERE i = 897');
   push(@testres, compare($expect, $result));

   &blurb("sql_one NoExec, too many rows");
   $result = sql_one('SELECT * FROM #a');
   push(@testres, compare($expect, $result));

   &blurb("sql_one NoExec: two ressets, two rows");
   %result = sql_one('SELECT 1 SELECT 2');
   push(@testres, compare(\%expect, \%result));

   &blurb("sql_one NoExec, fail: syntax error => no rows");
   $result = sql_one('$sql_error');
   push(@testres, compare($expect, $result));

   &blurb("sql_one NoExec, type error => no rwows.");
   $result = sql_one('SELECT * FROM #a WHERE i = ?', [['notype', 2]]);
   push(@testres, compare($expect, $result));
   $X->{NoExec} = 0;

   $no_of_tests += 11;
}

#==================================================================
#========================= NORESULT ===============================
#==================================================================
{
   my (@result, %result, $result, @expect, %expect, $expect);

   &blurb("HASH, NORESULT, wantarray");
   @expect = %expect = ();
   $expect = undef;
   %result = sql($sql, HASH, NORESULT);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, NORESULT, wantscalar");
   $result = sql($sql, HASH, NORESULT);
   push(@testres, compare($expect, $result));

   &blurb("LIST, NORESULT, wantarray");
   @result = sql($sql, LIST, NORESULT);
   push(@testres, compare(\@expect, \@result));

   &blurb("LIST, NORESULT, wantscalar");
   $result = sql($sql, LIST, NORESULT);
   push(@testres, compare($expect, $result));

   &blurb("SCALAR, NORESULT, wantarray");
   @result = sql($sql, SCALAR, NORESULT);
   push(@testres, compare(\@expect, \@result));

   &blurb("SCALAR, NORESULT, wantscalar");
   $result = sql($sql, SCALAR, NORESULT);
   push(@testres, compare($expect, $result));

   $no_of_tests += 6;

   #--------------------- Other COLINFO ----------------------------
   &blurb("HASH, NORESULT, COLINFO_POS");
   eval('sql($sql, COLINFO_POS, HASH, NORESULT)');
   push(@testres, $@ =~ /NORESULT.*cannot request.*\$colinfostyle at/ ? 1 : 0);

   &blurb("LIST, NORESULT, COLINFO_FULL");
   eval('sql($sql, COLINFO_FULL, LIST, NORESULT)');
   push(@testres, $@ =~ /NORESULT.*cannot request.*\$colinfostyle at/ ? 1 : 0);

   &blurb("SCALAR, NORESULT, COLINFO_NAMES");
   eval('sql($sql, COLINFO_NAMES, SCALAR, NORESULT)');
   push(@testres, $@ =~ /NORESULT.*cannot request.*\$colinfostyle at/ ? 1 : 0);

   $no_of_tests += 3;
}

#==================================================================
#=========================== KEYED ================================
#==================================================================
#---------------------- KEYED, single key -------------------
{
   my (%result, $result, %expect);

   &blurb("HASH, KEYED, single key, wantarray");
   %expect = ('A' => {'a' => 'A', 'i' => 12},
              'D' => {'a' => 'A', 'i' => 24},
              'H' => {'a' => 'A', 'i' => 1},
              'B' => {'a' => 'C', 'i' => 12});
   %result = sql($sql_key1, KEYED, ['b']);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, KEYED, single key, wantref");
   $result = sql($sql_key1, HASH, KEYED, ['b']);
   push(@testres, compare(\%expect, $result));

   &blurb("LIST, KEYED, single key, wantarray");
   %expect = ('A' => ['A', 12],
              'D' => ['A', 24],
              'H' => ['A', 1],
              'B' => ['C', 12]);
   %result = sql($sql_key1, LIST, KEYED, [2]);
   push(@testres, compare(\%expect, \%result));

   &blurb("LIST, KEYED, single key, wantref");
   $result = sql($sql_key1, LIST, KEYED, [2]);
   push(@testres, compare(\%expect, $result));

   &blurb("SCALAR, KEYED, single key, wantarray");
   %expect = ('A' => 'A@!@12',
              'D' => 'A@!@24',
              'H' => 'A@!@1',
              'B' => 'C@!@12');
   %result = sql($sql_key1, SCALAR, KEYED, [2]);
   push(@testres, compare(\%expect, \%result));

   &blurb("SCALAR, KEYED, single key, wantref");
   $result = sql($sql_key1, SCALAR, KEYED, [2]);
   push(@testres, compare(\%expect, $result));

   $no_of_tests += 6;

   #--------------------- Other COLINFO ----------------------------
   &blurb("HASH, KEYED, COLINFO_POS");
   eval('sql($sql_key1, COLINFO_POS, HASH, KEYED)');
   push(@testres, $@ =~ /KEYED.*cannot request.*\$colinfostyle at/ ? 1 : 0);

   &blurb("LIST, KEYED, COLINFO_FULL");
   eval('sql($sql_key1, COLINFO_FULL, LIST, KEYED)');
   push(@testres, $@ =~ /KEYED.*cannot request.*\$colinfostyle at/ ? 1 : 0);

   &blurb("SCALAR, KEYED, COLINFO_NAMES");
   eval('sql($sql_key1, COLINFO_NAMES, SCALAR, KEYED)');
   push(@testres, $@ =~ /KEYED.*cannot request.*\$colinfostyle at/ ? 1 : 0);

   $no_of_tests += 3;
}

#---------------------- KEYED, multiple key -------------------
{
   my (%result, $result, %expect);

   &blurb("HASH, KEYED, multiple key, wantarray");
   %expect = ('apple' => {'X' => {'1' => {data1 => undef, data2 => undef,     data3 => 'T'},
                                  '2' => {data1 => -15,   data2 => undef,     data3 => 'T'},
                                  '3' => {data1 => undef, data2 => undef,     data3 => 'T'}
                                 },
                          'Y' => {'1' => {data1 => 18,    data2 => 'Verdict', data3 => 'H'},
                                  '6' => {data1 => 18,    data2 => 'Maracas', data3 => 'I'}
                                 }
                         },
              'peach' => {'X' => {'1' => {data1 => 18,    data2 => 'Lastkey', data3 => 'T'},
                                  '8' => {data1 => 4711,  data2 => 'Monday',  data3 => 'T'}
                                  }
                         },
              'melon' => {'Y' => {'1' => {data1 => 118,   data2 => 'Lastkey',  data3 => 'T'}
                                 }
                         }
             );
   %result = sql_sp('#sql_key_many', HASH, KEYED, ['key1', 'key2', 'key3']);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, KEYED, multiple key, wantref");
   $result = sql_sp('#sql_key_many', HASH, KEYED, ['key1', 'key2', 'key3']);
   push(@testres, compare(\%expect, $result));

   &blurb("LIST, KEYED, mulitple key, wantarray");
   %expect = ('apple' => {'X' => {'1' => [undef, undef,    'T'],
                                  '2' => [-15,   undef,    'T'],
                                  '3' => [undef, undef,    'T']
                                 },
                          'Y' => {'1' => [18,   'Verdict', 'H'],
                                  '6' => [18,   'Maracas', 'I']
                                 }
                         },
              'peach' => {'X' => {'1' => [18,   'Lastkey', 'T'],
                                  '8' => [4711, 'Monday',  'T']
                                  }
                         },
              'melon' => {'Y' => {'1' => [118,  'Lastkey', 'T']
                                 }
                         }
             );
   %result = sql_sp('#sql_key_many', LIST, KEYED, [1, 2, 3]);
   push(@testres, compare(\%expect, \%result));

   &blurb("LIST, KEYED, multiple key, wantref");
   $result = sql_sp('#sql_key_many', LIST, KEYED, [1, 2, 3]);
   push(@testres, compare(\%expect, $result));

   &blurb("SCALAR, KEYED, multiple key, wantarray");
   %expect = ('apple' => {'X' => {'1' => '@!@@!@T',
                                  '2' => '-15@!@@!@T',
                                  '3' => '@!@@!@T'
                                 },
                          'Y' => {'1' => '18@!@Verdict@!@H',
                                  '6' => '18@!@Maracas@!@I'
                                 }
                         },
              'peach' => {'X' => {'1' => '18@!@Lastkey@!@T',
                                  '8' => '4711@!@Monday@!@T'
                                  }
                         },
              'melon' => {'Y' => {'1' => '118@!@Lastkey@!@T'
                                 }
                         }
             );
   %result = sql_sp('#sql_key_many', SCALAR, KEYED, [1, 2, 3]);
   push(@testres, compare(\%expect, \%result));

   &blurb("SCALAR, KEYED, multiple key, wantref");
   $result = sql_sp('#sql_key_many', SCALAR, KEYED, [1, 2, 3]);
   push(@testres, compare(\%expect, $result));

   $no_of_tests += 6;
}

#-------------------- KEYED, empty ----------------------
{
   my (%result, $result, %expect);

   %expect = ();
   &blurb("HASH, KEYED empty, wantarray");
   %result = sql($sql_empty, HASH, KEYED, ['a']);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, KEYED empty, wantscalar");
   $result = sql($sql_empty, HASH, KEYED, ['a']);
   push(@testres, compare(\%expect, $result));

   &blurb("LIST, KEYED empty, wantarray");
   %result = sql($sql_empty, LIST, KEYED, [1]);
   push(@testres, compare(\%expect, \%result));

   &blurb("LIST, KEYED empty, wantscalar");
   $result = sql($sql_empty, LIST, KEYED, [1]);
   push(@testres, compare(\%expect, $result));

   &blurb("SCALAR, KEYED empty, wantarray");
   %result = sql($sql_empty, SCALAR, KEYED, [1]);
   push(@testres, compare(\%expect, \%result));

   &blurb("SCALAR, KEYED empty, wantscalar");
   $result = sql($sql_empty, SCALAR, KEYED, [1]);
   push(@testres, compare(\%expect, $result));

   $no_of_tests += 6;
}

#--------------------- KEYED, sql_error  -------------------
{
   my (%result, $result, %expect);

   %expect = ();
   &blurb("HASH, KEYED error, wantarray");
   %result = sql($sql_error, HASH, KEYED, ['a']);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, KEYED error, wantscalar");
   $result = sql($sql_error, HASH, KEYED, ['a']);
   push(@testres, compare(\%expect, $result));

   &blurb("LIST, KEYED error, wantarray");
   %result = sql($sql_error, LIST, KEYED, [1]);
   push(@testres, compare(\%expect, \%result));

   &blurb("LIST, KEYED error, wantscalar");
   $result = sql($sql_error, LIST, KEYED, [1]);
   push(@testres, compare(\%expect, $result));

   &blurb("SCALAR, KEYED error, wantarray");
   %result = sql($sql_error, SCALAR, KEYED, [1]);
   push(@testres, compare(\%expect, \%result));

   &blurb("SCALAR, KEYED error, wantscalar");
   $result = sql($sql_error, SCALAR, KEYED, [1]);
   push(@testres, compare(\%expect, $result));

   $no_of_tests += 6;
}

#--------------------- KEYED, print  -------------------
{
   my (%result, $result, %expect);

   %expect = ();
   &blurb("HASH, KEYED error, wantarray");
   %result = sql($sql_print, HASH, KEYED, ['a']);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, KEYED error, wantscalar");
   $result = sql($sql_print, HASH, KEYED, ['a']);
   push(@testres, compare(\%expect, $result));

   &blurb("LIST, KEYED error, wantarray");
   %result = sql($sql_print, LIST, KEYED, [1]);
   push(@testres, compare(\%expect, \%result));

   &blurb("LIST, KEYED error, wantscalar");
   $result = sql($sql_print, LIST, KEYED, [1]);
   push(@testres, compare(\%expect, $result));

   &blurb("SCALAR, KEYED error, wantarray");
   %result = sql($sql_print, SCALAR, KEYED, [1]);
   push(@testres, compare(\%expect, \%result));

   &blurb("SCALAR, KEYED error, wantscalar");
   $result = sql($sql_print, SCALAR, KEYED, [1]);
   push(@testres, compare(\%expect, $result));

   $no_of_tests += 6;
}

#--------------------- KEYED, counts  -------------------
{
   my (%result, $result, %expect);

   %expect = ();
   &blurb("HASH, KEYED error, wantarray");
   %result = sql($sql_counts, HASH, KEYED, ['a']);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, KEYED error, wantscalar");
   $result = sql($sql_counts, HASH, KEYED, ['a']);
   push(@testres, compare(\%expect, $result));

   &blurb("LIST, KEYED error, wantarray");
   %result = sql($sql_counts, LIST, KEYED, [1]);
   push(@testres, compare(\%expect, \%result));

   &blurb("LIST, KEYED error, wantscalar");
   $result = sql($sql_counts, LIST, KEYED, [1]);
   push(@testres, compare(\%expect, $result));

   &blurb("SCALAR, KEYED error, wantarray");
   %result = sql($sql_counts, SCALAR, KEYED, [1]);
   push(@testres, compare(\%expect, \%result));

   &blurb("SCALAR, KEYED error, wantscalar");
   $result = sql($sql_counts, SCALAR, KEYED, [1]);
   push(@testres, compare(\%expect, $result));

   $no_of_tests += 6;
}

#--------------------- KEYED, nocount  -------------------
{
   my (%result, $result, %expect);

   %expect = ();
   &blurb("HASH, KEYED error, wantarray");
   %result = sql($sql_nocount, HASH, KEYED, ['a']);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, KEYED error, wantscalar");
   $result = sql($sql_nocount, HASH, KEYED, ['a']);
   push(@testres, compare(\%expect, $result));

   &blurb("LIST, KEYED error, wantarray");
   %result = sql($sql_nocount, LIST, KEYED, [1]);
   push(@testres, compare(\%expect, \%result));

   &blurb("LIST, KEYED error, wantscalar");
   $result = sql($sql_nocount, LIST, KEYED, [1]);
   push(@testres, compare(\%expect, $result));

   &blurb("SCALAR, KEYED error, wantarray");
   %result = sql($sql_nocount, SCALAR, KEYED, [1]);
   push(@testres, compare(\%expect, \%result));

   &blurb("SCALAR, KEYED error, wantscalar");
   $result = sql($sql_nocount, SCALAR, KEYED, [1]);
   push(@testres, compare(\%expect, $result));

   $no_of_tests += 6;
}

#--------------------- KEYED, NoExec -------------------
{
   my (%result, $result, %expect);

   $X->{NoExec} = 1;
   %expect = ();
   &blurb("HASH, KEYED NoExec, wantarray");
   %result = sql($sql_key1, HASH, KEYED, ['a']);
   push(@testres, compare(\%expect, \%result));

   &blurb("HASH, KEYED NoExec, wantscalar");
   $result = sql($sql_key1, HASH, KEYED, COLINFO_NONE, ['a']);
   push(@testres, compare(undef, $result));

   &blurb("LIST, KEYED NoExec, wantarray");
   %result = sql($sql_key1, LIST, KEYED, [1]);
   push(@testres, compare(\%expect, \%result));

   &blurb("LIST, KEYED NoExec, wantscalar");
   $result = sql($sql_key1, LIST, KEYED, [1]);
   push(@testres, compare(undef, $result));

   &blurb("SCALAR, KEYED NoExec, wantarray");
   %result = sql($sql_key1, SCALAR, KEYED, [1]);
   push(@testres, compare(\%expect, \%result));

   &blurb("SCALAR, KEYED NoExec, wantscalar");
   $result = sql($sql_key1, SCALAR, KEYED, [1]);
   push(@testres, compare(undef, $result));
   $X->{NoExec} = 0;

   $no_of_tests += 6;
}

#------------------- KEYED, call errors -----------------
{
   &blurb("KEYED, no keys list");
   eval('sql("SELECT * FROM #a", HASH, KEYED)');
   push(@testres, $@ =~ /no keys/i ? 1 : 0);

   &blurb("KEYED, illegal type \$keys");
   eval('sql("SELECT * FROM #a", KEYED, undef, "a")');
   push(@testres, $@ =~ /Illegal style parameter/i ? 1 : 0);

   &blurb("KEYED, empty keys list");
   eval('sql("SELECT * FROM #a", HASH, KEYED, [])');
   push(@testres, $@ =~ /empty/i ? 1 : 0);

   &blurb("KEYED, undefined key name");
   eval('sql("SELECT * FROM #a", HASH, KEYED, ["bogus"])');
   push(@testres, $@ =~ /no key\b.*in result/i ? 1 : 0);

   &blurb("KEYED, key out of range");
   eval('sql("SELECT * FROM #a", LIST, KEYED, COLINFO_NONE, [47])');
   push(@testres, $@ =~ /number .*not valid/i ? 1 : 0);

   &blurb("KEYED, not unique");
   eval(<<'EVALEND');
       local $SIG{__WARN__} = sub {$X->cancelbatch; die $_[0]};
       sql("SELECT * FROM #a", LIST, KEYED, [1]);
EVALEND
   push(@testres, $@ =~ /not unique/i ? 1 : 0);

   $no_of_tests += 6;
}

#==================================================================
#========================= &callback ==============================
#==================================================================
{
   my (@expect);
   my ($ix, $ok, $cancel_ix, $error_ix);
   my ($retstat);

   sub callback {
      my ($row, $ressetno) = @_;
      if ($expect[$ix][0] != $ressetno or
          not compare($expect[$ix++][1], $row)) {
         warn "Not ok at index $ix, result set $ressetno.";
         $ok = 0;
         return RETURN_CANCEL;
      }
      if ($ix == $cancel_ix) {
         return RETURN_NEXTQUERY;
      }
      if ($ix == $error_ix) {
         return RETURN_ERROR;
      }
      RETURN_NEXTROW;
   }

   #------------------------- COLINFO_NONE ------------------------------
   &blurb("HASH, COLINFO_NON, &callback");
   @expect = ([1, {a => 'A', b => 'A', i => 12}],
              [1, {a => 'A', b => 'D', i => 24}],
              [1, {a => 'A', b => 'H', i => 1}],
              [1, {a => 'C', b => 'B', i => 12}],
              [2, {sum => 37}],
              [2, {sum => 12}],
              [2, {sum => 49}],
              [5, {'x' => 'xyz'}],
              [5, {'x' => undef}],
              [8, {'Col 1' => 4711}]);
   $ix = 0;
   $cancel_ix = 0;
   $error_ix = 0;
   $ok = 1;
   $retstat = sql($sql, \&callback);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_NEXTROW) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   &blurb("LIST, COLINFO_NONE, &callback");
   @expect = ([1, ['A', 'A', 12]],
              [1, ['A', 'D', 24]],
              [2, [37]],
              [2, [12]],
              [2, [49]],
              [5, ['xyz']],
              [5, [undef]],
              [8, [4711]]);
   $ix = 0;
   $cancel_ix = 2;
   $error_ix = 0;
   $ok = 1;
   $retstat = sql($sql, COLINFO_NONE, LIST, \&callback);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_NEXTROW) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   $ix = 0;
   $cancel_ix = 0;
   $error_ix = 3;
   $ok = 1;
   &blurb("SCALAR, COLINFO_NONE, &callback");
   @expect = ([1, 'A@!@A@!@12'],
              [1, 'A@!@D@!@24'],
              [1, 'A@!@H@!@1']);
   $retstat = sql($sql, \&callback, SCALAR);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_ERROR) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   $ix = 0;
   $cancel_ix = 0;
   $error_ix = 2;
   $ok = 1;
   blurb("sql_sp, callback");
   @expect = ([1, 'apple@!@X@!@1@!@@!@@!@T'],
              [1, 'apple@!@X@!@2@!@-15@!@@!@T']);
   $retstat = sql_sp('#sql_key_many', \&callback, SCALAR);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_ERROR) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   $no_of_tests += 4;

   #------------------------- COLINFO_POS ------------------------------
   &blurb("HASH, COLINFO_POS, &callback");
   @expect = ([1, {a => 1, b => 2, i => 3}],
              [1, {a => 'A', b => 'A', i => 12}],
              [1, {a => 'A', b => 'D', i => 24}],
              [1, {a => 'A', b => 'H', i => 1}],
              [1, {a => 'C', b => 'B', i => 12}],
              [2, {sum => 1}],
              [2, {sum => 37}],
              [2, {sum => 12}],
              [2, {sum => 49}],
              [5, {'x' => 1}],
              [5, {'x' => 'xyz'}],
              [5, {'x' => undef}],
              [7, {a => 1, b => 2, i => 3}],
              [8, {'Col 1' => 1}],
              [8, {'Col 1' => 4711}]);
   $ix = 0;
   $cancel_ix = 0;
   $error_ix = 0;
   $ok = 1;
   $retstat = sql($sql, COLINFO_POS, \&callback);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_NEXTROW) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   &blurb("LIST, COLINFO_POS, &callback");
   @expect = ([1, [1, 2, 3]],
              [1, ['A', 'A', 12]],
              [1, ['A', 'D', 24]],
              [2, [1]],
              [2, [37]],
              [2, [12]],
              [2, [49]],
              [5, [1]],
              [5, ['xyz']],
              [5, [undef]],
              [7, [1, 2, 3]],
              [8, [1]],
              [8, [4711]]);
   $ix = 0;
   $cancel_ix = 3;
   $error_ix = 0;
   $ok = 1;
   $retstat = sql($sql, LIST, \&callback, COLINFO_POS);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_NEXTROW) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   $ix = 0;
   $cancel_ix = 0;
   $error_ix = 4;
   $ok = 1;
   &blurb("SCALAR, COLINFO_POS, &callback");
   @expect = ([1, '1@!@2@!@3'],
              [1, 'A@!@A@!@12'],
              [1, 'A@!@D@!@24'],
              [1, 'A@!@H@!@1']);
   $retstat = sql($sql, \&callback, SCALAR, COLINFO_POS);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_ERROR) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   $ix = 0;
   $cancel_ix = 0;
   $error_ix = 3;
   $ok = 1;
   blurb("sql_sp, COLINFO_POS, callback");
   @expect = ([1, '1@!@2@!@3@!@4@!@5@!@6'],
              [1, 'apple@!@X@!@1@!@@!@@!@T'],
              [1, 'apple@!@X@!@2@!@-15@!@@!@T']);
   $retstat = sql_sp('#sql_key_many', \&callback, COLINFO_POS, SCALAR);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_ERROR) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   $no_of_tests += 4;

   #------------------------- COLINFO_NAMES ------------------------------
   &blurb("HASH, COLINFO_NAMES, &callback");
   @expect = ([1, {a => 'a', b => 'b', i => 'i'}],
              [1, {a => 'A', b => 'A', i => 12}],
              [1, {a => 'A', b => 'D', i => 24}],
              [1, {a => 'A', b => 'H', i => 1}],
              [1, {a => 'C', b => 'B', i => 12}],
              [2, {sum => 'sum'}],
              [2, {sum => 37}],
              [2, {sum => 12}],
              [2, {sum => 49}],
              [5, {'x' => 'x'}],
              [5, {'x' => 'xyz'}],
              [5, {'x' => undef}],
              [7, {a => 'a', b => 'b', i => 'i'}],
              [8, {'Col 1' => ''}],
              [8, {'Col 1' => 4711}]);
   $ix = 0;
   $cancel_ix = 0;
   $error_ix = 0;
   $ok = 1;
   $retstat = sql($sql, COLINFO_NAMES, \&callback);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_NEXTROW) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   &blurb("LIST, COLINFO_NAMES, &callback");
   @expect = ([1, ['a', 'b', 'i']],
              [1, ['A', 'A', 12]],
              [1, ['A', 'D', 24]],
              [2, ['sum']],
              [2, [37]],
              [2, [12]],
              [2, [49]],
              [5, ['x']],
              [5, ['xyz']],
              [5, [undef]],
              [7, ['a', 'b', 'i']],
              [8, ['']],
              [8, [4711]]);
   $ix = 0;
   $cancel_ix = 3;
   $error_ix = 0;
   $ok = 1;
   $retstat = sql($sql, LIST, \&callback, COLINFO_NAMES);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_NEXTROW) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   $ix = 0;
   $cancel_ix = 0;
   $error_ix = 7;
   $ok = 1;
   &blurb("SCALAR, COLINFO_NAMES, &callback");
   @expect = ([1, 'a@!@b@!@i'],
              [1, 'A@!@A@!@12'],
              [1, 'A@!@D@!@24'],
              [1, 'A@!@H@!@1'],
              [1, 'C@!@B@!@12'],
              [2, 'sum'],
              [2, '37']);
   $retstat = sql($sql, \&callback, SCALAR, COLINFO_NAMES);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_ERROR) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   $ix = 0;
   $cancel_ix = 0;
   $error_ix = 3;
   $ok = 1;
   blurb("sql_sp, COLINFO_NAMES, callback");
   @expect = ([1, 'key1@!@key2@!@key3@!@data1@!@data2@!@data3'],
              [1, 'apple@!@X@!@1@!@@!@@!@T'],
              [1, 'apple@!@X@!@2@!@-15@!@@!@T']);
   $retstat = sql_sp('#sql_key_many', \&callback, COLINFO_NAMES, SCALAR);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_ERROR) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   $no_of_tests += 4;

   #------------------------- COLINFO_FULL ------------------------------
   &blurb("HASH, COLINFO_FULL, &callback");
   @expect = ([1, {a => {Name => 'a', Colno => 1, Type => 'char'},
                   b => {Name => 'b', Colno => 2, Type => 'char'},
                   i => {Name => 'i', Colno => 3, Type => 'int'}}],
              [1, {a => 'A', b => 'A', i => 12}],
              [1, {a => 'A', b => 'D', i => 24}],
              [1, {a => 'A', b => 'H', i => 1}],
              [1, {a => 'C', b => 'B', i => 12}],
              [2, {sum => {Name => 'sum', Colno => 1, Type => 'int'}}],
              [2, {sum => 37}],
              [2, {sum => 12}],
              [2, {sum => 49}],
              [5, {x => {Name => 'x', Colno => 1, Type => 'char'}}],
              [5, {'x' => 'xyz'}],
              [5, {'x' => undef}],
              [7, {a => {Name => 'a', Colno => 1, Type => 'char'},
                   b => {Name => 'b', Colno => 2, Type => 'char'},
                   i => {Name => 'i', Colno => 3, Type => 'int'}}],
              [8, {'Col 1' => {Name => '', Colno => 1, Type => 'int'}}],
              [8, {'Col 1' => 4711}]);
   $ix = 0;
   $cancel_ix = 0;
   $error_ix = 0;
   $ok = 1;
   $retstat = sql($sql, COLINFO_FULL, \&callback);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_NEXTROW) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   &blurb("LIST, COLINFO_FULL, &callback");
   @expect = ([1, [{Name => 'a', Colno => 1, Type => 'char'},
                   {Name => 'b', Colno => 2, Type => 'char'},
                   {Name => 'i', Colno => 3, Type => 'int'}]],
              [1, ['A', 'A', 12]],
              [1, ['A', 'D', 24]],
              [2, [{Name => 'sum', Colno => 1, Type => 'int'}]],
              [2, [37]],
              [2, [12]],
              [2, [49]],
              [5, [{Name => 'x', Colno => 1, Type => 'char'}]],
              [5, ['xyz']],
              [5, [undef]],
              [7, [{Name => 'a', Colno => 1, Type => 'char'},
                    {Name => 'b', Colno => 2, Type => 'char'},
                    {Name => 'i', Colno => 3, Type => 'int'}]],
              [8, [{Name => '', Colno => 1, Type => 'int'}]],
              [8, [4711]]);
   $ix = 0;
   $cancel_ix = 3;
   $error_ix = 0;
   $ok = 1;
   $retstat = sql($sql, LIST, \&callback, COLINFO_FULL);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_NEXTROW) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   $ix = 0;
   $cancel_ix = 0;
   $error_ix = 7;
   $ok = 1;
   &blurb("SCALAR, COLINFO_FULL, &callback");
   eval('sql($sql, \&callback, SCALAR, COLINFO_FULL)');
   push(@testres, $@ =~ /COLINFO_FULL cannot be combined.*SCALAR at/ ? 1 : 0);

   $ix = 0;
   $cancel_ix = 0;
   $error_ix = 3;
   $ok = 1;
   blurb("sql_sp, COLINFO_FULL, callback");
   @expect = ([1, [{Name => 'key1', Colno => 1, Type => 'char'},
                   {Name => 'key2', Colno => 2, Type => 'char'},
                   {Name => 'key3', Colno => 3, Type => 'int'},
                   {Name => 'data1', Colno => 4, Type => 'smallint'},
                   {Name => 'data2', Colno => 5, Type => 'varchar'},
                   {Name => 'data3', Colno => 6, Type => 'char'}]],
              [1, ['apple', 'X', '1', undef, undef, 'T']],
              [1, ['apple', 'X', '2', '-15', undef, 'T']]);
   $retstat = sql_sp('#sql_key_many', LIST, \&callback, COLINFO_FULL);
   if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_ERROR) {
      push(@testres, 1);
   }
   else {
      push(@testres, 0);
   }

   $no_of_tests += 4;
}

#==================================================================
#==================== Name duplicates in result set ===============
#==================================================================
{
   &blurb("Duplicate column names in result set.");
   my (@warnings, $result, @expect);
   @expect = ({a        => 11,
               'Col 4A' => 12,
               'Col 3'  => 13,
               'Col 4B' => 14,
               'Col 5A' => 15,
               'Col 6A' => 16,
               'Col 7'  => 17},
               {a        => -11,
                'Col 4A' => -12,
                'Col 3'  => -13,
                'Col 4B' => -14,
                'Col 5A' => -15,
                'Col 6A' => -16,
                'Col 7'  => -17});
   eval(<<'EVALEND');
       local $SIG{__WARN__} = sub {push(@warnings, $_[0])};
       $result = sql($sql_dupnames, HASH, SINGLESET, COLINFO_NONE);
EVALEND
   push(@testres, $warnings[0] =~ /Column name 'Col 3' appears twice/i ? 1 : 0);
   push(@testres, $warnings[1] =~ /Column name 'Col 4A' appears twice/i ? 1 : 0);
   push(@testres, $warnings[2] =~ /Column name 'a' appears twice/i ? 1 : 0);
   push(@testres, $warnings[3] =~ /Column name 'a' appears twice/i ? 1 : 0);
   push(@testres, compare(\@expect, $result));

   &blurb("Duplicate column names in result set, COLINFO_POS.");
   @warnings = ();
   @expect = ({a        => 1,
               'Col 4A' => 2,
               'Col 3'  => 3,
               'Col 4B' => 4,
               'Col 5A' => 5,
               'Col 6A' => 6,
               'Col 7'  => 7},
              {a        => 11,
               'Col 4A' => 12,
               'Col 3'  => 13,
               'Col 4B' => 14,
               'Col 5A' => 15,
               'Col 6A' => 16,
               'Col 7'  => 17},
               {a        => -11,
                'Col 4A' => -12,
                'Col 3'  => -13,
                'Col 4B' => -14,
                'Col 5A' => -15,
                'Col 6A' => -16,
                'Col 7'  => -17});
   eval(<<'EVALEND');
       local $SIG{__WARN__} = sub {push(@warnings, $_[0])};
       $result = sql($sql_dupnames, HASH, SINGLESET, COLINFO_POS);
EVALEND
   push(@testres, $warnings[0] =~ /Column name 'Col 3' appears twice/i ? 1 : 0);
   push(@testres, $warnings[1] =~ /Column name 'Col 4A' appears twice/i ? 1 : 0);
   push(@testres, $warnings[2] =~ /Column name 'a' appears twice/i ? 1 : 0);
   push(@testres, $warnings[3] =~ /Column name 'a' appears twice/i ? 1 : 0);
   push(@testres, compare(\@expect, $result));

   &blurb("Duplicate column names in result set, LIST, names.");
   @warnings = ();
   @expect = (['a', 'Col 4A', 'Col 3', 'Col 3', 'a', 'a', ''],
              [11, 12, 13, 14, 15, 16, 17],
              [-11, -12, -13, -14, -15, -16, -17]);
   eval(<<'EVALEND');
       local $SIG{__WARN__} = sub {push(@warnings, $_[0])};
       $result = sql($sql_dupnames, LIST, SINGLESET, COLINFO_NAMES);
EVALEND
   push(@testres, $#warnings == -1 ? 1 : 0);
   push(@testres, compare(\@expect, $result));

   $no_of_tests += 2*5 + 2;

}

#==================================================================
#========================= Style errors ===========================
#==================================================================
{
   &blurb("Bogus row style 1");
   eval('sql("SELECT * FROM #a", 23, KEYED)');
   push(@testres, $@ =~ /Illegal style.* 23 at/i ? 1 : 0);

   &blurb("Bogus row style 2");
   eval('sql("SELECT * FROM #a", undef, 23)');
   push(@testres, $@ =~ /Illegal style.* 23 at/i ? 1 : 0);

   &blurb("Bogus row style 3");
   eval('sql("SELECT * FROM #a", SINGLESET, 23)');
   push(@testres, $@ =~ /Illegal style.* 23 at/i ? 1 : 0);

   &blurb("Bogus result style");
   eval('sql("SELECT * FROM #a", LIST, 23)');
   push(@testres, $@ =~ /Illegal style.* 23 at/i ? 1 : 0);

   &blurb("Bogus result style 2");
   eval('sql("SELECT * FROM #a", COLINFO_POS, LIST, 84)');
   push(@testres, $@ =~ /Illegal style.* 84 at/i ? 1 : 0);

   &blurb("Two row styles");
   eval('sql("SELECT * FROM #a", LIST, HASH)');
   push(@testres, $@ =~ /Multiple row styles .* at/i ? 1 : 0);

   &blurb("Two result styles");
   eval('sql("SELECT * FROM #a", SINGLESET, MULTISET)');
   push(@testres, $@ =~ /Multiple result styles .* at/i ? 1 : 0);

   &blurb("Two colinfo style styles");
   eval('sql("SELECT * FROM #a", COLINFO_NONE, COLINFO_NONE)');
   push(@testres, $@ =~ /Multiple colinfo styles .* at/i ? 1 : 0);

   &blurb("Parameters after keys");
   eval('sql("SELECT * FROM #a", KEYED, [1], COLINFO_NONE)');
   push(@testres, $@ =~ /Extraneous parameter.* at/i ? 1 : 0);

   &blurb("Too many parameters");
   eval('sql("SELECT * FROM #a", KEYED, COLINFO_NONE, undef, undef, LIST)');
   push(@testres, $@ =~ /Extraneous parameter.* at/i ? 1 : 0);

   $no_of_tests += 10;
}

#==================================================================
#====================== Empty command batches =====================
#==================================================================
{  my $result;

   &blurb("Command undef");
   $result = $X->sql;
   push(@testres, compare($result, []));

   &blurb("Command undef2");
   $result = $X->sql(undef);
   push(@testres, compare($result, []));

   &blurb("Command empty");
   $result = $X->sql('');
   push(@testres, compare($result, []));

   &blurb("Command blank");
   $result = $X->sql(' ');
   push(@testres, compare($result, []));

   $no_of_tests += 4;
}

print "1..$no_of_tests\n";

my $ix = 1;
my $blurb = "";
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
