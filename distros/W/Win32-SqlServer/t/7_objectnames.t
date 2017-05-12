#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/t/7_objectnames.t 13    15-05-24 22:27 Sommar $
#
# This test suite tests that we interpret object names passed to sql_sp
# and sql_insert correctly.
#
# $History: 7_objectnames.t $
# 
# *****************  Version 13  *****************
# User: Sommar       Date: 15-05-24   Time: 22:27
# Updated in $/Perl/OlleDB/t
# Ripped out code specific for SQL 6.5.
# 
# *****************  Version 12  *****************
# User: Sommar       Date: 12-08-19   Time: 14:53
# Updated in $/Perl/OlleDB/t
# Corrected for restrictions on SQL 6.5.
# 
# *****************  Version 11  *****************
# User: Sommar       Date: 12-08-08   Time: 23:16
# Updated in $/Perl/OlleDB/t
# Original intent was to add tests for alias types with parameterised
# SQL, but a bug was revealed so that failed tests for checks of error
# messages were not registered. This lead to some restructuring and also
# some "dummy" tests to make it easier to compute the total number of
# tests. (The previous hard-coding masked the bug.)
# 
# *****************  Version 10  *****************
# User: Sommar       Date: 08-05-04   Time: 23:14
# Updated in $/Perl/OlleDB/t
# In correct no of tests for SQL 2008 and SQLNCLI.
#
# *****************  Version 9  *****************
# User: Sommar       Date: 08-05-04   Time: 21:40
# Updated in $/Perl/OlleDB/t
# Careful with that N, Eugene!
#
# *****************  Version 8  *****************
# User: Sommar       Date: 08-03-23   Time: 23:29
# Updated in $/Perl/OlleDB/t
# A little fix with the REVERT command, to avoid that SQLOLEDB adds
# "exec" in front.
#
# *****************  Version 7  *****************
# User: Sommar       Date: 08-03-09   Time: 22:48
# Updated in $/Perl/OlleDB/t
# Added tests for table-valued parameters and table types.
#
# *****************  Version 6  *****************
# User: Sommar       Date: 07-09-08   Time: 23:22
# Updated in $/Perl/OlleDB/t
# Corrected the test on which provider we use.
#
# *****************  Version 5  *****************
# User: Sommar       Date: 07-06-10   Time: 21:32
# Updated in $/Perl/OlleDB/t
# Don't use sp_addgroup to create a schema on SQL 2005 or higher, since
# there is CREATE SCHEMA - and in Katmai there is no sp_addgroup.
#
# *****************  Version 4  *****************
# User: Sommar       Date: 05-11-26   Time: 23:47
# Updated in $/Perl/OlleDB/t
# Renamed the module from MSSQL::OlleDB to Win32::SqlServer.
#
# *****************  Version 3  *****************
# User: Sommar       Date: 05-10-30   Time: 22:34
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 2  *****************
# User: Sommar       Date: 05-03-28   Time: 20:01
# Updated in $/Perl/OlleDB/t
#
# *****************  Version 1  *****************
# User: Sommar       Date: 05-03-28   Time: 19:03
# Created in $/Perl/OlleDB/t
#---------------------------------------------------------------------

use strict;
use Win32::SqlServer qw(:DEFAULT :consts);
use File::Basename qw(dirname);

require &dirname($0) . '\testsqllogin.pl';

use vars qw(@testres $verbose $no_of_tests);

sub blurb{
    push (@testres, "#------ Testing @_ ------\n");
    print "#------ Testing @_ ------\n" if $verbose;
}


$verbose = shift @ARGV;

$^W = 1;

$| = 1;

my $X = testsqllogin();
my ($sqlver) = split(/\./, $X->{SQL_version});
my ($sqlncli) = ($X->{Provider} >= PROVIDER_SQLNCLI);
my ($sqlncli10) = ($X->{Provider} >= PROVIDER_SQLNCLI10);

# Suppress informatiomal messages for our coming creation craze.
$X->{errInfo}{printText} = 1;

# Permit us to continue on errors.
$X->{ErrInfo}{MaxSeverity} = 17;

# The out data from the test procedures is a return value, so turn off that
# test.
$X->{ErrInfo}{CheckRetStat} = 0;

# But when we test for error messages, we want different settings.
sub setup_for_error_test {
   delete $X->{ErrInfo}{Messages};
   $X->{ErrInfo}{PrintMsg} = 17;
   $X->{ErrInfo}{PrintLines} = 17;
   $X->{ErrInfo}{PrintText} = 17;
   $X->{ErrInfo}{CarpLevel} = 17;
   $X->{ErrInfo}{SaveMessages} = 1;
}

sub reset_after_error_test {
    $X->{ErrInfo}{PrintMsg} = 1;
    $X->{ErrInfo}{PrintLines} = 11;
    $X->{ErrInfo}{PrintText} = 1;
    $X->{ErrInfo}{CarpLevel} = 10;
    $X->{ErrInfo}{SaveMessages} = 0;
}


# This becomes "räksmörgås" - but in Greek script.
my $shrimp = "\x{03A1}\x{03B5}\x{03BA}\x{03C3}\x{03BC}\x{03BF}\x{03B5}\x{03C1}\x{03BD}\x{03B3}\x{03C9}\x{03C2}";


# Database names we use. They are some absymal to avoid collisions with existing
# databases. Names with embedded dots does not work on 6.5, although in theory
# they should.
my @dbs = ('Olle$DB', '"Olle$DB test"', '"OlleDB.test"', '[Olle$DB.test]', 
           $shrimp);

# Schema names that we use. On 6.5, we only test the dbo schema, in SQL 6.5
# groups does not have schemas, and we don't want to create logins to create users.
# Also, users cannot have "funny" characters in them on 6.5.
my @schemas = ('dbo', 'guest', '"OlleDB$ test"', '"."', '"OlleDB.."""',
               '[Olle$DB.test]', '[".]', $shrimp);

# And procedure names.
my @procnames = ('plain_sp', '"space sp"', '"dot.sp"', '"dot.dot.sp"', 
                 '[bracket sp.]', '[bracket]]sp]', $shrimp);

# And add some really crazy names that SQLOLEDB cannot handle.
push(@procnames, '"""quote_sp"', '[]]"]]]') if $sqlncli;


# Drop existing databases. This is commented out normally as a safety
# precaution, so that we don't drop existing databases.
$X->sql("USE master");
#foreach my $db (@dbs) {
#   $X->sql("IF object_id(N'$db.dbo.sysobjects') IS NOT NULL DROP DATABASE $db");
#}


# Go on and create databases, schemas and procedures. Note that we don't drop
# existing databases. If the script fails, you may have drop to the databases
# manually.
my (%procmap, $n);
foreach my $db (@dbs) {
   $X->sql("USE master");
   $X->sql("CREATE DATABASE $db");
   $X->sql("USE $db");

   # Add as user to impersonate. We use guest on SQL 2000 and earlier,
   # else our own user.
   if ($sqlver >= 9) {
      $X->sql('CREATE USER olle WITHOUT LOGIN WITH DEFAULT_SCHEMA = guest');
   }
   else {
      $X->sql("EXEC sp_adduser guest");
   }

   # And create the schemas as groups (so logins are not required).
   foreach my $sch (@schemas) {
      unless ($sch =~ /^(dbo|guest)$/) {
         if ($sqlver >= 9) {
            $X->sql("CREATE SCHEMA $sch");
         }
         else {
            # No direct CREATE SCHEMA in previous version, but creating a
            # group will do.
            $X->sql("EXEC sp_addgroup $sch");
         }
      }

      if ($sqlver >= 9) {
         $X->sql("GRANT VIEW DEFINITION ON SCHEMA::$sch TO public");
      }   

      # And so the procedures and type. Each procedure and type has a 
      # unique signature with the parameter name, and we save this in %procmap.
      foreach my $proc (@procnames) {
         $n++;
         $X->sql ("CREATE PROCEDURE $sch.$proc \@a$n int AS RETURN \@a$n + $n");
         $X->sql ("GRANT EXECUTE ON $sch.$proc TO public");
         $procmap{$db}{$sch}{$proc} = $n;

         # We also create types. Exactly how depends on version etc.
         # and on the latter, types does not have a schema.
         if ($sqlver >= 10 and $sqlncli10) {
            # On SQL 2008 and SQLNCLI10 we do table types, so we can
            # test both type names and typeinfo.
            $X->sql("CREATE TYPE $sch.$proc AS TABLE (Olle$n int NOT NULL)");
            $X->sql(<<SQLEND);
            CREATE PROCEDURE $sch.Olletbl$n \@t $sch.$proc READONLY AS
                SELECT * FROM \@t
SQLEND
            $X->sql("GRANT EXECUTE ON TYPE::$sch.$proc TO public");
            $X->sql("GRANT EXECUTE ON $sch.Olletbl$n TO public");
         }
         elsif ($sqlver >= 9) {
            # For other versions we use a plain type.
            $X->sql("CREATE TYPE $sch.$proc FROM char($n)");
         }
         elsif ($sch eq 'dbo') {
            # On SQL 2000 and earlier, type does not have schema.
            # Furthermore, names are entered as is, that is quotedid are
            # not handled.
            my $type = $proc;
            if ($type =~ /^".+"$/) {
               $type =~ s/""/\"/g;
               $type = substr($type, 1, length($type) - 2);
            }
            elsif ($type =~ /^\[.+\]$/) {
               $type =~ s/\]\]/\]/g;
               $type = substr($type, 1, length($type) - 2);
            }

            # And on SQL 6.5, there can be no specials at all, so we skip
            # such type, and we will skip it below as well.
            $X->sql_sp("sp_addtype", [$type, "char($n)"]);
         }

         # On SQL 2005 and later, also create schema collections to test
         # handling of typeinfo if we have SQL Native client.
         if ($sqlver >= 9 and $sqlncli) {
            $X->sql(<<SQLEND);
CREATE XML SCHEMA COLLECTION $sch.$proc AS '
<schema xmlns="http://www.w3.org/2001/XMLSchema">
      <element name="Olle$n" type="string"/>
</schema>'
SQLEND
         $X->sql ("GRANT EXECUTE ON XML SCHEMA COLLECTION::$sch.$proc TO public");
         }
      }
   }
}

# Also create a temporary stored procedure and other objects starting
# with a hash mark
$X->sql("USE $dbs[0]");
$n = 4711;
$X->sql("CREATE PROCEDURE #temp_sp \@a$n int AS RETURN 10000 + $n");
if ($sqlver >= 9  and $sqlncli) {
  $X->sql(<<SQLEND);
CREATE XML SCHEMA COLLECTION #temp_sp AS
'<schema xmlns="http://www.w3.org/2001/XMLSchema">
      <element name="Olle$n" type="string"/>
</schema>'
SQLEND
}
if ($sqlver >= 10 and $sqlncli10) {
   # SQL Server does not accept table types starting with #, so we
   # cannot create a type. But we create a stored procedure to fake
   # success in the SP call test.
   $X->sql("CREATE PROCEDURE Olletbl$n \@x char(1) AS SELECT Olle$n = 100000");
}
elsif ($sqlver >= 9) {
   $X->sql("CREATE TYPE #temp_sp FROM char($n)");
}
else {
   $X->sql("EXEC sp_addtype '#temp_sp', 'char($n)'");
}

# First try all SP without schema qualification in the first database.
my $db = $dbs[0];
$X->sql("USE $db");
my $sch = 'dbo';
foreach my $proc (@procnames) {
   my $expect = $procmap{$db}{$sch}{$proc};
   do_test($db, $sch, $proc,                   $expect);
   do_test($db, $sch, ".$proc",                $expect);
   do_test($db, $sch, "..$proc",               $expect);
   do_test($db, $sch, "...$proc",              $expect);
   do_test($db, $sch, "$db. .$proc",           $expect, 'db');
   do_test($db, $sch, "....$proc",             'TOOMANY');
   do_test($db, $sch, ".$db.$sch.$proc",       $expect, 'db');
   do_test($db, $sch, ". $db . $sch . $proc",  $expect, 'db');
   do_test($db, $sch, ". $db . $sch . $proc",  $expect, 'db');  # Do it twice to test look-up.
   do_test($db, $sch, "...$sch.$proc",         'TOOMANY');
   do_test($db, $sch, "server.$db.$sch.$proc", 'SERVER');
   do_test($db, $sch, "a.b.$db.$sch.$proc",    'TOOMANY');
}
my $portioncombos = 12;

# Test bad quoting
do_test($db, $sch, '[plain_sp',               'UNTERM');
do_test(undef, undef, 'db.[sch]].plain_sp',   'UNTERM');
do_test(undef, undef, '"db.sch.plain_sp',     'UNTERM');
do_test(undef, undef, '[]]"]]',               'UNTERM');
do_test(undef, undef, 'db."sch"s.plain_sp',   'ILLQUOTE');
do_test(undef, undef, 'db. "sch" s.plain_sp', 'ILLQUOTE');
my $badquoting = 6;

# Redo for the guest schema. We must flush the proc cache here.
if ($sqlver >= 9) {
   $X->sql("EXECUTE AS USER = 'olle'");
}
else {
   $X->sql("SETUSER 'guest'");
}
$X->{'procs'} = {};
$X->{'tabletypes'} = {};
$X->{'usertypes'} = {};
$sch = 'guest';
foreach my $proc (@procnames) {
   # When running this test, there is a special case: types in SQL 2000
   # and earlier are always in dbo.
   my $expect = $procmap{$db}{$sch}{$proc};
   my $expect_dbo = $procmap{$db}{'dbo'}{$proc};
   do_test($db, $sch, $proc,         $expect, undef, 'dbo', $expect_dbo);
   do_test($db, $sch, "guest.$proc", $expect);
   do_test($db, $sch, "..$proc",     $expect, undef, 'dbo', $expect_dbo);
   do_test($db, $sch, ". ..$proc",   $expect, undef, 'dbo', $expect_dbo);
}
# The semi-colon is needed, because else SQLOLEDB adds "exec" before REVERT.
$X->sql(($sqlver >= 9 ? "; REVERT" : "SETUSER"));
my $testsasguest = 4;


# Now try all combinations of schema and procedure.
$X->{'procs'} = {};
$X->{'tabletypes'} = {};
$X->{'usertypes'} = {};
foreach $sch (@schemas) {
   foreach my $proc (@procnames) {
      my $expect = $procmap{$db}{$sch}{$proc};
      do_test($db, $sch, " $sch.$proc ", $expect);
      do_test($db, $sch, ".$sch.$proc",  $expect);
      do_test($db, $sch, "..$sch.$proc", $expect);
   }
}
my $allschproccombos = 3;

# And now all combinations of databases, schemas and procedeurs.
$X->sql("USE master");
foreach $db (@dbs) {
   foreach $sch (@schemas) {
      foreach my $proc (@procnames) {
         my $expect = $procmap{$db}{$sch}{$proc};
         do_test($db, $sch, "$db.$sch.$proc", $expect, 'db');
      }
   }
}
my $alldbcombos = 1;

# Test the temporary stored procedure.
$db = $dbs[0];
$X->sql("USE $db");
do_test($db, 'dbo', "#temp_sp", 4711);
my $temptest = 1;

# Finnaly test system stored procedures.
my $resset = 1;
$X->sql("USE $dbs[0]");
blurb("sp_help plain_sp");
my @result = sql_sp('sp_help', ['plain_sp']);
push(@testres,
     $result[$resset]{'Parameter_name'} eq 
        '@a' . $procmap{$dbs[0]}{'dbo'}{'plain_sp'});
foreach $db (@dbs) {
   blurb("$db..sp_help plain_sp");
   @result = sql_sp("$db..sp_help", ['plain_sp']);
   push(@testres,
        $result[$resset]{'Parameter_name'} eq 
          '@a' . $procmap{$db}{'dbo'}{'plain_sp'});
}


$X->sql("USE master");
foreach my $db (@dbs) {
   $X->sql("DROP DATABASE $db");
}

# Now computer the number of tests for each configuration.
my $tests_per_objref;
if ($sqlver >= 10 and $sqlncli10) {
   $tests_per_objref = 5;
}
elsif ($sqlver >= 9 and $sqlncli) {
   $tests_per_objref = 3;
}
else {
   $tests_per_objref = 2;
}

$no_of_tests = 
   $tests_per_objref * (
               $portioncombos * scalar(@procnames) +
               $badquoting +
               $testsasguest * scalar(@procnames) +
               $allschproccombos * scalar(@procnames) * scalar(@schemas) +
               $alldbcombos * scalar(@procnames) * scalar(@schemas) *
                              scalar(@dbs) +
               $temptest) + 
               scalar(@dbs) + 1;  # System procedures.


finally:



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

sub do_test {
    my($db, $sch, $objref, $mapvalue, $hasdbspec, 
       $ss2000_typeschema, $ss2000_expect) = @_;
    $ss2000_typeschema = $sch unless $ss2000_typeschema;
    $ss2000_expect     = $mapvalue unless $ss2000_expect;
    if ($mapvalue =~ /^\d+$/) {

       # First test call to stored procedure.
       my $retvalue;
       my $params;
       $$params{"a$mapvalue"} = 10000;
       my $expect = 10000 + $mapvalue;
       blurb("SP Call $objref");
       $X->sql_sp($objref, \$retvalue, $params);
       push(@testres, $retvalue == $expect);


       # XML schema collections.
       if ($sqlver >= 9 and $sqlncli) {
          blurb($objref . ' XML ');
          my $errorexpect;
          $expect = "<Olle$mapvalue>$mapvalue</Olle$mapvalue>";
          if ($objref =~ /^\./) {
             setup_for_error_test();
             $errorexpect = qr/Incorrect syntax near/;
          }
          my $sqlparams = ['xml', '<?xml version="1.0"?>' . $expect, $objref];
          $retvalue = $X->sql('SELECT convert(nvarchar(MAX), ?)', [$sqlparams],
                               SCALAR, SINGLEROW);
          if ($errorexpect) {
             my $errmsg = $X->{ErrInfo}{Messages}[0]{'text'};
             push(@testres, scalar($errmsg =~ $errorexpect));
          }
          else {
             push(@testres, $retvalue eq $expect);
          }
          reset_after_error_test();
       }

       # Test types. This is done different depending on SQL Server
       # version.
       if ($sqlver >= 10 and $sqlncli10) {
          # For "modern" platforms we test table types, for which
          # there are restrictions for which syntaxes that are legal.
          # Some of the test case will result in error.

          # First SP call with TVP. These tests always passes.
          $expect = "Olle$mapvalue";
          blurb("Table type $objref SP call");
          $retvalue = $X->sql_sp("$db.$sch.Olletbl$mapvalue", 
                                  [[]], COLINFO_NAMES, LIST);
          push(@testres,
               (ref $retvalue eq 'ARRAY' and $$retvalue[0][0] eq $expect));

          # The adhoc stuff is worse, here errors may occur:
          my ($errorexpect1, $errorexpect2);
          if ($hasdbspec) {
             $errorexpect1 = $errorexpect2 = 
                  qr/\Q'$objref'\E.*database portion/;
          }
          elsif ($objref =~ /^\./) {
             $errorexpect1 = $errorexpect2 = qr/Incorrect syntax near/;
          }
          elsif ($objref =~ /^\#/) {
             $errorexpect1 = qr/Unable to find.*\'\Q$objref\E\'/;
             $errorexpect2 = qr/Unknown data type '\Q$objref\E\'/;
          }
          if ($errorexpect1) {
             setup_for_error_test();
          }

          blurb("Table type $objref param sql");
          $retvalue = $X->sql('SELECT * FROM ?', [['table', [], $objref]],
                              COLINFO_NAMES, LIST);
          if ($errorexpect1) {
             my $errmsg = $X->{ErrInfo}{Messages}[0]{'text'};
             push(@testres, scalar($errmsg =~ $errorexpect1));
          }
          else {
             push(@testres, $$retvalue[0][0] eq $expect);
          }

          delete $X->{ErrInfo}{Messages};
          blurb("Table type $objref param sql, with type name");
          $retvalue = $X->sql('SELECT * FROM ?', [[$objref, []]],
                              COLINFO_NAMES, LIST);
          if ($errorexpect2) {
             my $errmsg = $X->{ErrInfo}{Messages}[0]{'text'};
             push(@testres, scalar($errmsg =~ $errorexpect2));
          }
          else {
             push(@testres, $$retvalue[0][0] eq $expect);
          }

          reset_after_error_test();
       }
       elsif ($sqlver >= 9 or $ss2000_typeschema eq 'dbo') {
          # With plain types we can test it all. No errors are expected.
          blurb("Type $objref");

          $expect = ($sqlver >= 9 ? $mapvalue : $ss2000_expect);
          $retvalue = $X->sql_one('SELECT datalength(?)', 
                                 [[$objref, ' ']], SCALAR);
          push(@testres, $retvalue eq $expect);
       }
       else {
          # On SQL 2000 and we don't accept any other schema than dbo.
          setup_for_error_test();

          blurb("Type $objref (error expected in SQL 2000)");
          $X->sql('SELECT ?', [[$objref, undef]]);       
          my $errmsg = $X->{ErrInfo}{Messages}[0]{'text'};
          push(@testres, 
                scalar ($errmsg =~ /has a schema different from/));

          reset_after_error_test();
       }
    }
    else {
       setup_for_error_test();

       my $expect;
       if ($mapvalue eq 'TOOMANY') {
          $expect = qr/'\Q$objref\E'.*includes more than four/;
       }
       elsif ($mapvalue eq 'SERVER') {
          $expect = qr/'\Q$objref\E'.*server (portion|component)/;
       }
       elsif ($mapvalue eq 'UNTERM') {
          $expect = qr/'\Q$objref\E'.*unterminated/;
       }
       elsif ($mapvalue eq 'ILLQUOTE') {
          $expect = qr/'\Q$objref\E'.*incorrectly quoted/;
       }
       else {
          die "Mapvalue has an unexpected value: '$mapvalue'.";
       }

       $X->sql_sp($objref);
       my $errmsg = $X->{ErrInfo}{Messages}[0]{'text'};
       blurb("SP call $objref (expected $expect, got '$errmsg')");
       push(@testres, scalar($errmsg =~ $expect));

       delete $X->{ErrInfo}{Messages};
       $X->sql('SELECT ?', [[$objref, undef]]);       
       $errmsg = $X->{ErrInfo}{Messages}[0]{'text'};
       blurb("Type $objref (expected $expect, got '$errmsg')");
       push(@testres, scalar($errmsg =~ $expect));

       if ($sqlver >= 9 and $sqlncli) {
          delete $X->{ErrInfo}{Messages};
          $X->sql('SELECT ?', [['xml', undef, $objref]]);
          $errmsg = $X->{ErrInfo}{Messages}[0]{'text'};
          blurb("XML $objref (expected $expect, got '$errmsg')");
          push(@testres, scalar($errmsg =~ $expect));
       }

       if ($sqlver >= 10 and $sqlncli10) {
          delete $X->{ErrInfo}{Messages};
          $X->sql('SELECT * FROM ?', [['table', [], $objref]],
                  COLINFO_NAMES, LIST);
          blurb("Table type $objref param sql (expected $expect, got '$errmsg')");
          push(@testres, scalar($errmsg =~ $expect));

          # This is a dummy "test" to have equally many tests for
          # errors and success. This makes it easier to compute the
          # total.
          blurb("Dummy test");
          push(@testres, 1);
       }

       reset_after_error_test();
    }
}

