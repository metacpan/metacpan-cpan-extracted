#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/SqlServer.pm 89    22-05-08 23:10 Sommar $
#
# Copyright (c) 2004-2022 Erland Sommarskog
#
#
# $History: SqlServer.pm $
# 
# *****************  Version 89  *****************
# User: Sommar       Date: 22-05-08   Time: 23:10
# Updated in $/Perl/OlleDB
# Stepping up to version 2.014 and added new OLE  DB provider MSOLEDBSQL.
# 
# *****************  Version 88  *****************
# User: Sommar       Date: 21-04-29   Time: 22:28
# Updated in $/Perl/OlleDB
# Version number 2.013.
# 
# *****************  Version 87  *****************
# User: Sommar       Date: 19-07-22   Time: 10:47
# Updated in $/Perl/OlleDB
# Only apply the fall back for varchar parameters to UTF-8 collations for
# output parameters.
# 
# *****************  Version 86  *****************
# User: Sommar       Date: 19-07-16   Time: 11:06
# Updated in $/Perl/OlleDB
# Changed the condition when we pass nvarchar to varchar in table
# variables.
# 
# *****************  Version 85  *****************
# User: Sommar       Date: 19-07-08   Time: 22:51
# Updated in $/Perl/OlleDB
# 1) PROVIDER_MSSQLOLEDB is now exported.
# 2) SQL_version is no longer read with a query, but the XS code get it
# from internaldata. The FETCH uses XS method to get it.
# 3) New attribute CurrentDB handled sa SQL_version, and codepages which
# is a hash with the database codepage. This is one read from the
# database like SQL_version used to be.
# 4) Various changes to handle UTF-8 support, not the least with
# downlevel providers.
# 
# *****************  Version 84  *****************
# User: Sommar       Date: 18-04-10   Time: 22:22
# Updated in $/Perl/OlleDB
# Win32::SqlServer 2.011
# 
# *****************  Version 83  *****************
# User: Sommar       Date: 18-04-09   Time: 22:51
# Updated in $/Perl/OlleDB
# Added support for the new MSOLEDBSQL provider.
# 
# *****************  Version 82  *****************
# User: Sommar       Date: 16-11-16   Time: 9:01
# Updated in $/Perl/OlleDB
# Parsing @@version failed when it included information about the CU and
# GDR. Instead use xp_msver when available, else use
# serverproperty('ProductVersion').
# 
# *****************  Version 81  *****************
# User: Sommar       Date: 16-07-11   Time: 22:24
# Updated in $/Perl/OlleDB
# Advanced version to 2.010.
# 
# *****************  Version 80  *****************
# User: Sommar       Date: 15-05-24   Time: 22:22
# Updated in $/Perl/OlleDB
# Perl 2.009
# 
# *****************  Version 79  *****************
# User: Sommar       Date: 12-09-23   Time: 22:52
# Updated in $/Perl/OlleDB
# Updated Copyright note.
# 
# *****************  Version 78  *****************
# User: Sommar       Date: 12-08-19   Time: 14:54
# Updated in $/Perl/OlleDB
# Need a special for sysname on SQL 6.5 where the id is below the
# usertype limit.
# 
# *****************  Version 77  *****************
# User: Sommar       Date: 12-08-12   Time: 20:34
# Updated in $/Perl/OlleDB
# Use SELECT @@version rather than xp_msver to get the SQL Server
# version, since there is no xp_msver on Azure. (And permission to
# execute it may have been revoked.)
# 
# *****************  Version 76  *****************
# User: Sommar       Date: 12-08-08   Time: 23:29
# Updated in $/Perl/OlleDB
# New feature: you can now use alias data types with parameterised sql in
# sql and sql_one. Reworked how the database name is handled in internal
# metadata queries: Rather than inlining it, pass the database name as a
# parameter to internal_sql so that sp_executesql is accessed as
# $db..sp_excecutesql. 
# 
# *****************  Version 75  *****************
# User: Sommar       Date: 12-07-26   Time: 18:07
# Updated in $/Perl/OlleDB
# We now support OUTPUT parameters for parameterised SQL.
# 
# *****************  Version 74  *****************
# User: Sommar       Date: 12-07-21   Time: 0:08
# Updated in $/Perl/OlleDB
# Add support for SQLNCLI11. Fixed warning from Perl 5.16.
#
# *****************  Version 73  *****************
# User: Sommar       Date: 11-08-07   Time: 23:29
# Updated in $/Perl/OlleDB
# Bumped version number.
#
# *****************  Version 72  *****************
# User: Sommar       Date: 10-10-29   Time: 20:50
# Updated in $/Perl/OlleDB
# New version!
#
# *****************  Version 71  *****************
# User: Sommar       Date: 10-10-29   Time: 16:18
# Updated in $/Perl/OlleDB
# Handles for CLONE were stored correctly, which resulted in a memory
# leak.
#
# *****************  Version 70  *****************
# User: Sommar       Date: 10-02-27   Time: 21:22
# Updated in $/Perl/OlleDB
# Peek at the first argument to sql_init to permit it be called as
# Win32::SqlServer.
#
# *****************  Version 69  *****************
# User: Sommar       Date: 09-08-16   Time: 14:00
# Updated in $/Perl/OlleDB
# When generating values for the log file, make sure that bit columns
# always have a value (we should handle empty string most of all).
#
# *****************  Version 68  *****************
# User: Sommar       Date: 09-08-14   Time: 23:06
# Updated in $/Perl/OlleDB
# Corrected logging of TVPs, so that there is a new INSERT for each 1000
# rows, as SQL Server does not permit more in the same VALUES clause.
#
# *****************  Version 67  *****************
# User: Sommar       Date: 09-06-21   Time: 17:11
# Updated in $/Perl/OlleDB
# New version number.
#
# *****************  Version 66  *****************
# User: Sommar       Date: 08-05-04   Time: 20:56
# Updated in $/Perl/OlleDB
# Fixed errors in SQL for retrieving parameter and column info from SQL
# 2000 and lower. Had broken the possibility to send longer statements
# and parameter lists than 4000 chars on SQL 2000 and SQL7.
#
# *****************  Version 65  *****************
# User: Sommar       Date2.13: 08-05-02   Time: 0:52
# Updated in $/Perl/OlleDB
# When testing that the code pages are correct, we need to pass a
# variable, a constant string won't do.
#
# *****************  Version 64  *****************
# User: Sommar       Date: 08-05-01   Time: 10:44
# Updated in $/Perl/OlleDB
# The character conversion stuff did not work when there was no default
# handle. All routines now check that there is a handle available.
#
# *****************  Version 63  *****************
# User: Sommar       Date: 08-04-30   Time: 22:36
# Updated in $/Perl/OlleDB
# Set verison number to 2.004.
#
# *****************  Version 62  *****************
# User: Sommar       Date: 08-03-23   Time: 23:42
# Updated in $/Perl/OlleDB
# Further changes when testing table-valued parameters. There was a bug,
# so that we used maxlen for binay values as strings at too low size.
#
# *****************  Version 61  *****************
# User: Sommar       Date: 08-03-16   Time: 21:10
# Updated in $/Perl/OlleDB
# Further corrections to the code to get the type id. Added more checks
# of the value for a table parameter.
#
# *****************  Version 60  *****************
# User: Sommar       Date: 08-03-09   Time: 20:24
# Updated in $/Perl/OlleDB
# Corrected handling of retrieving the type id. Handle the case the user
# does not have permission to the table type/UDT better. Improvements in
# error handling with table types.
#
# *****************  Version 59  *****************
# User: Sommar       Date: 08-02-24   Time: 23:50
# Updated in $/Perl/OlleDB
# Some improved error checks for table parameters.
#
# *****************  Version 58  *****************
# User: Sommar       Date: 08-02-24   Time: 22:00
# Updated in $/Perl/OlleDB
# nvarchar/varchar/varbinary without length now results in nvarchar(4000)
# etc to avoid cache bloats. Whereas char/nchar/binary without length
# yield warnings.
#
# *****************  Version 57  *****************
# User: Sommar       Date: 08-02-24   Time: 20:35
# Updated in $/Perl/OlleDB
# Seems like code-page conversion works with table parameters now. And
# UDTs and XML schema collections, which it did not in the past. General
# changes how conversion for hashes is done.
#
# *****************  Version 56  *****************
# User: Sommar       Date: 08-02-24   Time: 16:11
# Updated in $/Perl/OlleDB
# Added support for table parameters.
#
# *****************  Version 55  *****************
# User: Sommar       Date: 08-02-10   Time: 17:14
# Updated in $/Perl/OlleDB
# Added the rowversion to places where we handle timestamp.
#
# *****************  Version 54  *****************
# User: Sommar       Date: 07-12-01   Time: 23:40
# Updated in $/Perl/OlleDB
# Added support for OpenSqlFilestream. Clear some internal ErrInfo fields
# in olle_croak, so they are not set if we return from eval.
#
# *****************  Version 53  *****************
# User: Sommar       Date: 07-11-25   Time: 17:42
# Updated in $/Perl/OlleDB
# Added support for the spatial data types.
#
# *****************  Version 52  *****************
# User: Sommar       Date: 07-10-28   Time: 23:37
# Updated in $/Perl/OlleDB
# Corrections after test.
#
# *****************  Version 51  *****************
# User: Sommar       Date: 07-10-20   Time: 23:47
# Updated in $/Perl/OlleDB
# Added support for the new date/time data types.
#
# *****************  Version 50  *****************
# User: Sommar       Date: 07-10-06   Time: 22:20
# Updated in $/Perl/OlleDB
# New property: TZOffset.
#
# *****************  Version 49  *****************
# User: Sommar       Date: 07-09-16   Time: 22:38
# Updated in $/Perl/OlleDB
# Added suppor for large UDTs.
#
# *****************  Version 48  *****************
# User: Sommar       Date: 07-09-09   Time: 0:13
# Updated in $/Perl/OlleDB
# Added PROVIDER_SQLNCLI10 to the PROVIDER group.
#
# *****************  Version 47  *****************
# User: Sommar       Date: 07-07-10   Time: 21:59
# Updated in $/Perl/OlleDB
# Win32::SqlServer 2.003.
#
# *****************  Version 46  *****************
# User: Sommar       Date: 07-07-07   Time: 21:37
# Updated in $/Perl/OlleDB
# Added row style MULTISET_RC.
#
# *****************  Version 45  *****************
# User: Sommar       Date: 07-07-07   Time: 16:44
# Updated in $/Perl/OlleDB
# Added 5th parameter to sql_init: $provider.
#
# *****************  Version 44  *****************
# User: Sommar       Date: 07-06-25   Time: 0:31
# Updated in $/Perl/OlleDB
# Added handling of COLINFO styles.
#
# *****************  Version 43  *****************
# User: Sommar       Date: 07-06-17   Time: 19:06
# Updated in $/Perl/OlleDB
# Completely new implementation of sql_set_conversion.
#
# *****************  Version 42  *****************
# User: Sommar       Date: 06-04-17   Time: 21:48
# Updated in $/Perl/OlleDB
# Advancrd version to 2.002. No other changes.
#
# *****************  Version 41  *****************
# User: Sommar       Date: 05-11-26   Time: 23:47
# Updated in $/Perl/OlleDB
# Renamed the module to Win32::SqlServer and advanced to version 2.001.
#
# *****************  Version 40  *****************
# User: Sommar       Date: 05-11-13   Time: 16:33
# Updated in $/Perl/OlleDB
#
#---------------------------------------------------------------------


package Win32::SqlServer;

require 5.012;

use strict;
use Exporter;
use DynaLoader;
use Tie::Hash;
use Carp;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS
            $def_handle $SQLSEP
            %ALLSYSTEMTYPES
            %TYPESWITHLENGTH %TYPESWITHFIXLEN %PLAINCHARTYPES %QUOTEDTYPES
            %UNICODETYPES %LARGETYPES %CLRTYPES %BINARYTYPES %DECIMALTYPES
            %NEWDATETIMETYPES %MAXTYPES %TYPEINFOTYPES $VERSION);


$VERSION = '2.014';

@ISA = qw(Exporter DynaLoader Tie::StdHash);

# Kick life into the C++ code.
bootstrap Win32::SqlServer;

@EXPORT = qw(sql_init sql_string);
@EXPORT_OK = qw(sql_set_conversion sql_unset_conversion sql_one sql sql_sp
                sql_insert sql_has_errors sql_get_command_text
                sql_begin_trans sql_commit sql_rollback
                NORESULT SINGLEROW SINGLESET MULTISET MULTISET_RC KEYED
                SCALAR LIST HASH
                COLINFO_NONE COLINFO_POS COLINFO_NAMES COLINFO_FULL
                $SQLSEP
                TO_SERVER_ONLY TO_CLIENT_ONLY TO_SERVER_CLIENT
                RETURN_NEXTROW RETURN_NEXTQUERY RETURN_CANCEL RETURN_ERROR
                RETURN_ABORT
                PROVIDER_DEFAULT PROVIDER_SQLOLEDB PROVIDER_SQLNCLI
                PROVIDER_SQLNCLI10 PROVIDER_SQLNCLI11 PROVIDER_MSOLEDBSQL
                PROVIDER_MSOLEDBSQL19
                DATETIME_HASH DATETIME_ISO DATETIME_REGIONAL DATETIME_FLOAT
                DATETIME_STRFMT
                CMDSTATE_INIT CMDSTATE_ENTEREXEC CMDSTATE_NEXTRES
                CMDSTATE_NEXTROW CMDSTATE_GETPARAMS
                SQL_FILESTREAM_OPEN_FLAG_ASYNC
                SQL_FILESTREAM_OPEN_FLAG_NO_BUFFERING
                SQL_FILESTREAM_OPEN_FLAG_NO_WRITE_THROUGH
                SQL_FILESTREAM_OPEN_FLAG_SEQUENTIAL_SCAN
                SQL_FILESTREAM_OPEN_FLAG_RANDOM_ACCESS
                FILESTREAM_READ FILESTREAM_WRITE FILESTREAM_READWRITE);

%EXPORT_TAGS = (consts       => [qw($SQLSEP)],   # Filled in below.
                routines     => [qw(sql_set_conversion sql_unset_conversion
                                    sql_one sql sql_sp sql_insert
                                    sql_has_errors sql_get_command_text
                                    sql_string
                                    sql_begin_trans sql_commit sql_rollback)],
                resultstyles => [qw(NORESULT SINGLEROW SINGLESET MULTISET
                                    MULTISET_RC KEYED)],
                rowstyles    => [qw(SCALAR LIST HASH)],
                colinfostyles=> [qw(COLINFO_NONE COLINFO_POS COLINFO_NAMES
                                    COLINFO_FULL)],
                directions   => [qw(TO_SERVER_ONLY TO_CLIENT_ONLY TO_SERVER_CLIENT)],
                returns      => [qw(RETURN_NEXTROW RETURN_NEXTQUERY RETURN_CANCEL
                                    RETURN_ERROR RETURN_ABORT)],
                providers    => [qw(PROVIDER_DEFAULT PROVIDER_SQLOLEDB
                                    PROVIDER_SQLNCLI PROVIDER_SQLNCLI10
                                    PROVIDER_SQLNCLI11 PROVIDER_MSOLEDBSQL
                                    PROVIDER_MSOLEDBSQL19)],
                datetime     => [qw(DATETIME_HASH DATETIME_ISO DATETIME_REGIONAL
                                    DATETIME_FLOAT DATETIME_STRFMT)],
                cmdstates    => [qw(CMDSTATE_INIT CMDSTATE_ENTEREXEC CMDSTATE_NEXTRES
                                    CMDSTATE_NEXTROW CMDSTATE_GETPARAMS)],
                filestream   => [qw(SQL_FILESTREAM_OPEN_FLAG_ASYNC
                                    SQL_FILESTREAM_OPEN_FLAG_NO_BUFFERING
                                    SQL_FILESTREAM_OPEN_FLAG_NO_WRITE_THROUGH
                                    SQL_FILESTREAM_OPEN_FLAG_SEQUENTIAL_SCAN
                                    SQL_FILESTREAM_OPEN_FLAG_RANDOM_ACCESS
                                    FILESTREAM_READ FILESTREAM_WRITE
                                    FILESTREAM_READWRITE)]);

push(@{$EXPORT_TAGS{'consts'}}, @{$EXPORT_TAGS{'routines'}},
                                @{$EXPORT_TAGS{'resultstyles'}},
                                @{$EXPORT_TAGS{'rowstyles'}},
                                @{$EXPORT_TAGS{'colinfostyles'}},
                                @{$EXPORT_TAGS{'directions'}},
                                @{$EXPORT_TAGS{'returns'}},
                                @{$EXPORT_TAGS{'providers'}},
                                @{$EXPORT_TAGS{'datetime'}},
                                @{$EXPORT_TAGS{'cmdstates'}},
                                @{$EXPORT_TAGS{'filestream'}});

# Result-style constants.
use constant NORESULT    => 821;
use constant SINGLEROW   => 741;
use constant SINGLESET   => 643;
use constant MULTISET    => 139;
use constant MULTISET_RC => 564;
use constant KEYED       => 124;
use constant RESULTSTYLES => (NORESULT, SINGLEROW, SINGLESET, MULTISET,
                              MULTISET_RC, KEYED);

# Row-style constants.
use constant SCALAR    => 17;
use constant LIST      => 89;
use constant HASH      => 93;
use constant ROWSTYLES => (SCALAR, LIST, HASH);

# Column-info constants
use constant COLINFO_NONE  => 1233;
use constant COLINFO_NAMES => 7234;
use constant COLINFO_POS   => 6707;
use constant COLINFO_FULL  => 3591;
use constant COLINFOSTYLES => (COLINFO_NONE, COLINFO_NAMES, COLINFO_POS,
                               COLINFO_FULL);

# Separator when rows returned in one string, reconfigurarable.
$SQLSEP = "\022";

# Constants for conversion direction
use constant TO_SERVER_ONLY    => 8798;
use constant TO_CLIENT_ONLY    => 3456;
use constant TO_SERVER_CLIENT  => 2402;

# Constants for return values for callbacks
use constant RETURN_NEXTROW    =>  1;
use constant RETURN_NEXTQUERY  =>  2;
use constant RETURN_CANCEL     =>  3;
use constant RETURN_ERROR      =>  0;
use constant RETURN_ABORT      => -1;

# Constants for option Provider
use constant PROVIDER_DEFAULT      => 0;
use constant PROVIDER_SQLOLEDB     => 1;
use constant PROVIDER_SQLNCLI      => 2;
use constant PROVIDER_SQLNCLI10    => 3;
use constant PROVIDER_SQLNCLI11    => 4;
use constant PROVIDER_MSOLEDBSQL   => 5;
use constant PROVIDER_MSOLEDBSQL19 => 6;
use constant PROVIDER_OPTIONS    => (PROVIDER_DEFAULT, PROVIDER_SQLOLEDB,
                                     PROVIDER_SQLNCLI, PROVIDER_SQLNCLI10,
                                     PROVIDER_SQLNCLI11, PROVIDER_MSOLEDBSQL,
                                     PROVIDER_MSOLEDBSQL19);

# Constants for datetime options
use constant DATETIME_HASH     => 0;
use constant DATETIME_ISO      => 1;
use constant DATETIME_REGIONAL => 2;
use constant DATETIME_FLOAT    => 3;
use constant DATETIME_STRFMT   => 4;
use constant DATETIME_OPTIONS  => (DATETIME_HASH, DATETIME_ISO,
                                   DATETIME_REGIONAL, DATETIME_FLOAT,
                                   DATETIME_STRFMT);

# Constants for command state.
use constant CMDSTATE_INIT      => 0;
use constant CMDSTATE_ENTEREXEC => 1;
use constant CMDSTATE_NEXTRES   => 2;
use constant CMDSTATE_NEXTROW   => 3;
use constant CMDSTATE_GETPARAMS => 4;

# Filestream constants for access. (The others are defined in the XS.)
use constant FILESTREAM_READ      => 0;
use constant FILESTREAM_WRITE     => 1;
use constant FILESTREAM_READWRITE => 2;

use constant PACKAGENAME => 'Win32::SqlServer';

# Constant hashes for datatype combinations, for internal use only.
%ALLSYSTEMTYPES  = ('bigint' => 1, 'binary' => 1, 'bit' => 1, 
                    'char' => 1, 'date' => 1, 'datetime' => 1, 
                    'datetime2' => 1, 'datetimeoffset' => 1, 
                    'decimal' => 1, 'float' => 1, 'geography' => 1, 
                    'geometry' => 1, 'hierarchyid' => 1, 'image' => 1, 
                    'int' => 1, 'money' => 1, 'nchar' => 1, 
                    'ntext' => 1, 'numeric' => 1, 'nvarchar' => 1, 
                    'real' => 1, 'rowversion' => 1, 'smalldatetime' => 1, 
                    'smallint' => 1, 'smallmoney' => 1, 'sql_variant' => 1, 
                    'text' => 1, 'time' => 1, 'timestamp' => 1, 
                    'table' => 1, 'tinyint' => 1, 'UDT' => 1, 
                    'uniqueidentifier' => 1, 'varbinary' => 1, 
                    'varchar' => 1, 'xml' => 1);
%TYPESWITHLENGTH = ('char' => 1, 'nchar' => 1, 'varchar' => 1, 'nvarchar' => 1,
                    'binary' => 1, 'varbinary' => 1);
%TYPESWITHFIXLEN = ('char' => 1, 'nchar' => 1, 'binary' => 1);
%PLAINCHARTYPES  = ('char' => 1, 'varchar' => 1, 'text'=> 1);
%LARGETYPES      = ('text' => 1, 'ntext' => 1, 'image' => 1, 'xml' => 1);
%QUOTEDTYPES     = ('char' => 1, 'varchar' => 1, 'nchar' => 1, 'nvarchar' => 1,
                    'text' => 1, 'ntext' => 1, 'uniqueidentifier' => 1,
                    'datetime' => 1 , 'smalldatetime'=> 1, 'date' => 1,
                    'time' => 1, 'datetime2' => 1, 'datetimeoffset' => 1);
%UNICODETYPES     = ('nchar' => 1, 'nvarchar' => 1, 'ntext' => 1);
%CLRTYPES         = ('UDT' => 1, 'geometry' => 1, 'geography' => 1, 
                     'hierarchyid' => 1);
%BINARYTYPES      = ('binary' => 1, 'varbinary' => 1, 'timestamp' => 1,
                     'rowversion', => 1, 'image' => 1, %CLRTYPES);
%DECIMALTYPES     = ('decimal' => 1, 'numeric' => 1);
%NEWDATETIMETYPES = ('time' => 1, 'datetime2' => 1, 'datetimeoffset' => 1);
%MAXTYPES         = ('varchar' => 1, 'nvarchar' => 1, 'varbinary' => 1,
                     'UDT' => 1);
%TYPEINFOTYPES    = ('UDT' => 1, 'xml' => 1, 'table' => 1);

# Global hash to keep track of all object we create and destroy. This is
# needed when cloning for a new thread.
my %my_objects;

#----- -------------- Set up supported attributes. --------------------------
my %myattrs;

use constant XS_ATTRIBUTES =>   # Used by the XS code.
             qw(internaldata Provider PropsDebug AutoConnect RowsAtATime
                DecimalAsStr DatetimeOption TZOffset BinaryAsStr DateFormat
                MsecFormat CommandTimeout MsgHandler QueryNotification
                CurrentDB codepages);
use constant PERL_ATTRIBUTES => # Attributes used by the Perl code.
             qw(ErrInfo SQL_version to_server to_client NoExec procs tables
                tabletypes usertypes LogHandle UserData);
use constant ALL_ATTRIBUTES => (XS_ATTRIBUTES, PERL_ATTRIBUTES);

foreach my $attr (ALL_ATTRIBUTES) {
   $myattrs{$attr}++;
}

#------------------------  FETCH and STORE -------------------------------
# My own FETCH routine, chckes that retrieval is of a known attribute.
sub FETCH {
   my ($self, $key) = @_;
   if (not exists $myattrs{$key}) {
       # Compability with MSSQL::Sqllib: permit initial lowercase.
       $key =~ s/^./uc($&)/e;
       if (not exists $myattrs{$key}) {
           $self->olle_croak("Attempt to fetch a non-existing Win32::SqlServer property '$key'");
       }
   }

   # Some attributes come from internaldata.
   if ($key eq 'SQL_version') {
      return $self->get_sqlversion;
   }
   elsif ($key eq 'CurrentDB') {
      return $self->get_currentdb;
   }
   if ($key eq 'Provider') {
      return $self->get_provider_enum;
   }
   else {
      return $self->{$key};
   }
}

# My own STORE routine, barfs if attribute is non-existent.
sub STORE {
   my ($self, $key, $value) = @_;
   if (not exists $myattrs{$key}) {
       $key =~ s/^./uc($&)/e;
       if (not exists $myattrs{$key}) {
           $self->olle_croak("Attempt to set a non-existing Win32::SqlServer property '$key'");
       }
   }
   my $old_value = $self->{$key};
   if ($key eq 'MsgHandler') {
      if ($value) {
         if (not ref $value eq "CODE") {
            # It is not a ref to a sub, but it could be the name of that. There
            # is an XS routine to validate this. It croaks if things are bad.
            $self->validatecallback($value);
         }
      }
      else {
         $value = undef;
      }
   }
   elsif ($key eq "SQl_version" or $key eq "CurentDB") {
      $self->olle_croak("The object property '$key' is read-only.\n");
   }
   elsif ($key eq "internaldata" or $key eq "ErrInfo") {
      if ($old_value) {
         my $caller = (caller(1))[3];
         unless ($caller and $caller eq PACKAGENAME . '::DESTROY') {
            $self->olle_croak("You must not change the object property '$key'");
         }
      }
   }
   elsif ($key eq "Provider") {
      if (not grep($value == $_, PROVIDER_OPTIONS)) {
         $self->olle_croak("Illegal value '$value' for the Provider property");
      }
      my $ret = $self->set_provider_enum($value);
      if ($ret == -1) {
         croak("Cannot set the Provider while connected");
      }
   }
   elsif ($key eq "DatetimeOption") {
      if (not grep($value == $_, DATETIME_OPTIONS)) {
         $self->olle_croak("Illegal value '$value' for the DatetimeOption property");
      }
   }
   elsif ($key eq "TZOffset" and defined $value) {
      $value = lc($value);
      $value =~ s/\s//g;
      if ($value ne 'local' and $value !~ /[+-]\d\d:\d\d/) {
         $self->olle_croak("Incorrect value '$value' for the TZOffset property. The format must be '+/-hh:mm'.");
      }
   }
   elsif ($key eq "QueryNotification") {
      if (not ref $value eq "HASH") {
         $self->olle_croak("The value for the QueryNotification property must be a hash reference");
      }
   }

   $self->{$key} = $value;
}

sub DELETE {
   # Generally it is not permitted to delete keys from the hash, but 
   # to_client/to_server are exceptions as they are created and deleted
   # by sql_(un)set_conversion.
   my ($self, $key) = @_;
   if (not grep($_ eq $key, qw(to_server to_client))) {
      $self->olle_croak ("Attempt to delete the object property '$key'");
   }
   $self->{$key} = undef;
}

#------------------------ New and DESTROY -------------------------------

sub new {
   my ($self) = @_;

   my (%olle);

   # %olle is our tied hash.
   my $X = tie %olle, $self;

   # Initiate Win32::SqlServer properties.
   $olle{"internaldata"}      = setupinternaldata();
   $olle{"AutoConnect"}       = 0;
   $olle{"PropsDebug"}        = 0;
   $olle{"RowsAtATime"}       = 100;
   $olle{"DecimalAsStr"}      = 0;
   $olle{"DatetimeOption"}    = DATETIME_ISO;
   $olle{"BinaryAsStr"}       = '1';
   $olle{"DateFormat"}        = "%Y%m%d %H:%M:%S";
   $olle{"MsecFormat"}        =  ".%3.3d";
   $olle{"CommandTimeout"}    = 0;
   $olle{"QueryNotification"} = {};
   $olle{"MsgHandler"}        = \&sql_message_handler;

   # Initiate error handling.
   $olle{ErrInfo} = new_err_info();

   # Bless object.
   my $ret = bless \%olle, PACKAGENAME;

   # Save a reference to the object itself, keyed by the tied array.
   # This is for CLONE, see below.
   $my_objects{$ret} = $X;

   # And return the blessed object.
   return  $ret;
}

sub CLONE {
# Perl calls this routine when a new thread is created. If we would do
# nothing at all, internaldata would be the same for all thread, which
# would only cause misery. Particularly, the child threads would try to
# deallocate it, which crashes with "attempt to free from wrong pool".
# So we give all cloned objects a new fresh internaldata.
   foreach my $obj (values %my_objects) {
      $$obj{"internaldata"} = setupinternaldata()
   }
}

sub DESTROY {
   my ($self) = @_;

   delete $my_objects{$self};

   # We run the destruction in eval, as Perl sometimes produces an error
   # message "Can't call method "FETCH" on an undefined value" when the
   # destructor is called a second time.
   eval('xs_DESTROY($self)');

   unless ($@) {
      # We must clear internaldata, since Perl calls the destructor twice, but
      # on the second occasion, the XS code has already deallocated internaldata.
      # The XS code has problem with setting values in stored hashes, why we do
      # it. This assignment cannot be in eval, since the STORE method only
      # permits DESTROY to change internaldata.
      $$self{'internaldata'} = 0;
   }
}

#--------------------  sql_init  ----------------------------------------
sub sql_init {
# Logs into SQL Server and returns an object to use for further communication
# with the module. We permit the user to use both :: and -> on call.
    if (defined $_[0] and $_[0] eq PACKAGENAME) {shift @_};
    my ($server, $user, $pw, $db, $provider) = @_;

    my $X = new(PACKAGENAME);

    $X->{Provider} = $provider if defined $provider;

    # Set login properties if provided.
    $X->setloginproperty('Server', $server) if $server;

    if ($user) {
       $X->setloginproperty('Username', $user);
       $X->setloginproperty('Password', $pw) if $pw;
    }
    $X->setloginproperty('Database', $db) if $db;

    # Login into the server.
    if (not $X->connect()) {
       croak("Login into SQL Server failed");
    }

    # Get the code page for the current database.
    $X->get_db_codepage();

    # If the global default handle is undefined, give the recently created
    # connection.
    if (not defined $def_handle) {
       $def_handle = $X;
    }

    $X;
}

#------------------------- get_handle, internal ------------------------
# Decdes the first parameter to all methods, and dies there is no valid
# handle.
sub get_handle {
   my ($atundref) = @_;
   if (ref @$atundref[$[] eq PACKAGENAME) {
       return shift @$atundref;
   }
   elsif (defined $def_handle) {
       return $def_handle;
   }
   else {
      croak PACKAGENAME . ": No handle provided, and there is no default handle,";
   }
}

#-------------------------- sql_set_conversion --------------------------
sub sql_set_conversion
{
    my ($X) = get_handle(\@_);
    my($client_cs, $server_cs, $direction) = @_;

    # First validate the $direction parameter.
    if (! $direction) {
       $direction = TO_SERVER_CLIENT;
    }
    if (! grep($direction == $_,
              (TO_SERVER_ONLY, TO_CLIENT_ONLY, TO_SERVER_CLIENT))) {
       $X->olle_croak("Illegal direction value: $direction");
    }

    # Normalize parameters and get defaults. The client charset.
    if (not $client_cs or $client_cs =~ /^OEM/i) {
       # No value or OEM, use CP_OEM = 1
       $client_cs = 1
    }
    elsif ($client_cs =~ /^ANSI$/i) {
       # CP_ACP = 0
       $client_cs = 0;
    }
    $client_cs =~ s/^cp_?//i;             # Strip CP[_]

    # Now the server charset. If no charset given, query the server.
    if (not $server_cs) {
       if ($X->{SQL_version} =~ /^[467]\./) {
          # SQL Server 7.0 or earlier.
          $server_cs = $X->internal_sql(<<SQLEND, undef, SCALAR, SINGLEROW);
               SELECT chs.name
               FROM   master..syscharsets sor, master..syscharsets chs,
                      master..syscurconfigs cfg
               WHERE  cfg.config = 1123
                 AND  sor.id     = cfg.value
                 AND  chs.id     = sor.csid
SQLEND
       }
       else {
          # Modern stuff, SQL 2000 or later.
          $server_cs = $X->internal_sql(<<SQLEND, undef, SCALAR, SINGLEROW);
             SELECT collationproperty(
                    CAST(serverproperty ('collation') as nvarchar(255)),
                    'CodePage')
SQLEND
       }
    }
    if ($server_cs =~ /^iso_1$/i) {    # iso_1 is how SQL6&7 reports Latin-1.
       $server_cs = 1252;              # CP1252 is the Latin-1 code page.
    }
    $server_cs =~ s/^cp_?//i;

    # If client and server charset are the same, we should only remove any
    # current conversion, and then quit.
    if ($client_cs == $server_cs) {
       $X->sql_unset_conversion($direction);
       return;
    }

    # Test that the conversion works. That is, if the caller has specified
    # non-existing code-pages, this is where it all ends.
    my $test = 'räksmörgås';
    $X->codepage_convert($test, $client_cs, $server_cs);

    # Construct subs to perform the conversion. These subs are then called
    # in do_conversion.
    my $evaltext = <<'EVALEND';
    sub { my($X) = get_handle(\@_);
          foreach (@_) {
             next if ref or not $_;
             $X->codepage_convert($_, FROM_CP, TO_CP);
          }
        }
EVALEND

    # And save the conversion subs.
    if ($direction == TO_SERVER_ONLY or $direction == TO_SERVER_CLIENT) {
       my $sub = $evaltext;
       $sub =~ s/FROM_CP/$client_cs/;
       $sub =~ s/TO_CP/$server_cs/;
       my $evalstat = $X->{'to_server'} = eval($sub);
       if (not $evalstat) {
           $X->olle_croak("eval of client-to-server conversion failed: $@\n");
       }
    }

    if ($direction == TO_CLIENT_ONLY or $direction == TO_SERVER_CLIENT) {
       my $sub = $evaltext;
       $sub =~ s/FROM_CP/$server_cs/;
       $sub =~ s/TO_CP/$client_cs/;
       my $evalstat = $X->{'to_client'} = eval($sub);
       if (not $evalstat) {
           $X->olle_croak("eval of server-to-client conversion failed: $@");
       }
    }
}

#-------------------------- sql_unset_conversion -------------------------
sub sql_unset_conversion
{
    my ($X) = get_handle(\@_);
    my ($direction) = @_;

    # First validate the $direction parameter.
    if (! $direction) {
       $direction = TO_SERVER_CLIENT;
    }
    if (! grep($direction == $_,
              (TO_SERVER_ONLY, TO_CLIENT_ONLY, TO_SERVER_CLIENT))) {
       $X->olle_croak("Illegal direction value: $direction");
    }

    # Now remove as ordered.
    if ($direction == TO_SERVER_ONLY or $direction == TO_SERVER_CLIENT) {
       delete $X->{'to_server'};
    }
    if ($direction == TO_CLIENT_ONLY or $direction == TO_SERVER_CLIENT) {
       delete $X->{'to_client'};
    }
}

#-----------------------------  sql_one-------------------------------------
sub sql_one
{
    my ($X) = get_handle(\@_);
    my ($sql) = shift @_;

    # Get parameter array if any.
    my ($hashparams, $arrayparams);
    if (ref $_[0] eq "ARRAY") {
       $arrayparams = shift @_;
    }
    if (ref $_[0] eq "HASH") {
       $hashparams = shift @_;
    }

    # Get rowstyle.
    my ($rowstyle) = shift @_;


    # Make sure $rowstyle has a legal value.
    $rowstyle = $rowstyle || (wantarray ? HASH : SCALAR);
    if (not grep($rowstyle == $_, ROWSTYLES)) {
       croak PACKAGENAME . ": Illegal rowstyle value: $_[1]";
    }

    if (@_) {
       croak PACKAGENAME . ": extraneous parameters to sql_one: @_";
    }

    # Apply conversion.
    $X->do_conversion('to_server', $sql);

    # Set up the command - run initbatch and enter parameters if necessary.
    my @outputparams;
    my $ret = $X->setup_sqlcmd($sql, undef, $arrayparams, $hashparams, 
                               \@outputparams);
    if (not $ret) {
        $X->olle_croak("Single-row query '$sql' had parameter errors");
    }

    # Do logging.
    $X->do_logging;

    if ($X->{'NoExec'}) {
       $X->cancelbatch;
       return (wantarray ? () : undef);
    }

    my ($dataref, $saveref, $exec_ok);

    # Run the command.
    $exec_ok = $X->executebatch;

    # Get the only result set and the only row - or at least there should
    # be exactly one of each.
    my $sets = 0;
    my $rows = 0;
    if ($exec_ok) {
       # Only try this if query executed.
       while ($X->nextresultset()) {
          $sets++;

          while ($X->nextrow(($rowstyle == HASH) ? $dataref : undef,
                             ($rowstyle == HASH) ? undef : $dataref)) {
             $rows++;
             # If we have a second row, something is wrong.
             if ($rows > 1) {
                $X->olle_croak("Single-row query '$sql' returned more than one row");
             }
             $saveref = $dataref;
          }
       }
    }

    # Buf if execution failed, we are seeing the now.
    # If we don't have any result set, something is wrong.
    $X->olle_croak("Single-row query '$sql' returned no result set") if $sets == 0;

    # Same if we have no row at at all.
    $X->olle_croak("Single-row query '$sql' returned no row") if $rows == 0;

    # Apply server-to-client conversion
    $X->do_conversion('to_client', $saveref);

    # Any output parameters.
    $X->do_output_parameters(\@outputparams);

    if (wantarray) {
       return (($rowstyle == HASH) ? %$saveref : @$saveref);
    }
    else {
       return (($rowstyle == SCALAR) ? list_to_scalar($saveref) : $saveref);
    }
}

#-----------------------  sql  --------------------------------------
sub sql
{
    my ($X) = get_handle(\@_);

    my $sql = shift @_;

    # Get parameter array if any.
    my ($arrayparams, $hashparams);
    if (ref $_[0] eq "ARRAY") {
       $arrayparams = shift @_;
    }
    if (ref $_[0] eq "HASH") {
       $hashparams = shift @_;
    }

    # Style parameters. Get them from @_ and then check that values are
    # legal and supply defaults as needed.
    my($rowstyle, $resultstyle, $colinfostyle, $keys) = check_style_params(@_);

    # Apply conversion.
    $X->do_conversion('to_server', $sql);

    # Set up the SQL command - initbatch and enter parameters if necesary.
    my @outputparams;
    my $ret = $X->setup_sqlcmd($sql, undef, $arrayparams, $hashparams, 
                               \@outputparams);
    if (not $ret) {
       return (wantarray ? () : undef);
    }

    # Log the statement.
    $X->do_logging;

    my $exec_ok;
    unless ($X->{'NoExec'}) {
       # Run the command.
       $exec_ok = $X->executebatch;
    }
    else {
       $X->cancelbatch;
       $exec_ok = 0;
    }

    # And get the resultsets.
    my (@results, $resultsref);
    if (wantarray) {
        @results = $X->do_result_sets($exec_ok, $rowstyle, $resultstyle, 
                                      $colinfostyle, $keys);
    }
    else {
        $resultsref = $X->do_result_sets($exec_ok, $rowstyle, $resultstyle, 
                                         $colinfostyle, $keys);
    }

    # And output parameters.
    $X->do_output_parameters(\@outputparams);

    return (wantarray ? @results : $resultsref);
}

#-------------------------- sql_sp ------------------------------------
sub sql_sp {
    my ($X) = get_handle(\@_);

    # In this one we're not taking all parameters at once, but one by one,
    # as the parameter list is quite variable.
    my ($SP, $retvalueref, $unnamed, $named, $rowstyle,
        $resultstyle, $colinfostyle, $keys, $dummy);

    # The name of the SP, mandatory.
    $SP = shift @_;

    # Reference to scalar to receive the return value. Since there always is
    # return value, we always has a reference to a place to store it.
    if (ref $_[0] eq "SCALAR") {
       $retvalueref = shift @_;
    }
    else {
       $retvalueref = \$dummy;
    }

    # Reference to an array with named parameters.
    if (ref $_[0] eq "ARRAY") {
       $unnamed = shift @_;
    }

    # Reference to a hash with named parameters.
    if (ref $_[0] eq "HASH") {
       $named = shift @_;
    }

    # The usual row- and result-style parameters.
    ($rowstyle, $resultstyle, $colinfostyle, $keys) = check_style_params(@_);

    # Reference to hash that holds the parameter definitions.
    my ($paramdefs);

    # If we have the parameter profile for this SP, we can reuse it.
    if (exists $X->{procs}{$SP}) {
       $paramdefs = $X->{'procs'}{$SP}{'params'};
    }
    else {
       # No we don't. We must retrieve from the server.

       # Get the object id for the table and it's database
       my ($objid, $objdb, $normalspec) = $X->get_object_id($SP);
       if (not defined $objid) {
          my $msg = "Stored procedure '$SP' is not accessible";
          $X->olledb_message(-1, 1, 16, $msg);
          return (wantarray ? () : undef);
       }

       # Now, inquire about all the parameters their types. Always include
       # the return value. It's in the system metadata only for UDFs, so for
       # SPs, we have to roll our own. Different handling for different SQL
       # Server versions.
       # The second UNION bit is for the return value from SP:s.
       my $getcols;
       if ($X->{SQL_version} =~ /^[78]\./) {
          # The CASE for is_output because SQL 2000 says 0 for ret value from UDF.
          $getcols = <<'SQLEND';
              SELECT name = CASE colid WHEN 0 THEN NULL ELSE name END,
                     paramno = colid, type = type_name(xtype),
                     max_length = length, "precision" = coalesce(prec, 0),
                     scale = coalesce(scale, 0),
                     is_input  = CASE colid WHEN 0 THEN 0 ELSE 1 END,
                     is_output = CASE colid WHEN 0 THEN 1 ELSE isoutparam END,
                     is_retstatus = 0, typeinfo = NULL, is_table_type = 0,
                     needstypeinfo = 0
              FROM   dbo.syscolumns
              WHERE  id = @objid
              UNION
              SELECT NULL, 0, 'int', 4, 0, 0, 0, 1, 1, NULL, 0, 0
              WHERE  NOT EXISTS (SELECT *
                                 FROM   dbo.syscolumns
                                 WHERE  id = @objid
                                   AND  colid = 0)
              ORDER   BY paramno
SQLEND
       }
       else {
          # SQL Server 2005 or later. There is one small difference between
          # SQL 2005 and SQL 2008.
          my $tabletypecol = ($X->{SQL_version} =~ /^9\./ ?
                               '0' : 't.is_table_type');
          $getcols = <<SQLEND;
              SELECT name = CASE p.parameter_id WHEN 0 THEN NULL ELSE p.name END,
                     paramno = p.parameter_id,
                     type = CASE p.system_type_id
                               WHEN 240 THEN 'UDT'
                               ELSE type_name(p.system_type_id)
                          END,
                     p.max_length, p.precision, p.scale,
                     is_input = CASE p.parameter_id WHEN 0 THEN 0 ELSE 1 END,
                     p.is_output, is_retstatus = 0,
                     typeinfo =
                     CASE WHEN p.system_type_id IN (240, 243)
                          THEN CASE WHEN nullif(\@objdb, '') IS NOT NULL
                                    THEN \@objdb + '.'
                                    ELSE ''
                               END + quotename(s1.name) + '.' +
                               quotename(t.name)
                          WHEN p.system_type_id = 241
                          THEN CASE WHEN nullif(\@objdb, '') IS NOT NULL
                                    THEN \@objdb + '.'
                                    ELSE ''
                               END + quotename(s2.name) + '.' +
                               quotename(x.name)
                     END, is_table_type = coalesce($tabletypecol, 0),
                     needstypeinfo = CASE WHEN p.system_type_id IN (240, 243)
                                          THEN 1
                                          ELSE 0
                                     END
              FROM   sys.all_parameters p
              LEFT   JOIN (sys.types t
                          JOIN  sys.schemas s1 ON t.schema_id = s1.schema_id)
                  ON  p.user_type_id = t.user_type_id
                 AND  t.is_assembly_type | $tabletypecol = 1
              LEFT   JOIN (sys.xml_schema_collections x
                           JOIN  sys.schemas s2 ON x.schema_id = s2.schema_id)
                  ON  p.xml_collection_id = x.xml_collection_id
              WHERE  object_id = \@objid
              UNION
              SELECT NULL, 0, 'int', 4, 0, 0, 0, 1, 1, NULL, 0, 0
              WHERE  NOT EXISTS (SELECT *
                                 FROM   sys.all_parameters
                                 WHERE  object_id = \@objid
                                   AND  parameter_id = 0)
              ORDER   BY paramno
SQLEND
       }

       # Trim the SQL from extraneous spaces, to save network bandwidth.
       $getcols =~ s/\s{2,}/ /g;

       $paramdefs = $X->internal_sql($getcols, $objdb,
                                    {'@objid' => ['int',           $objid],
                                     '@objdb' => ['nvarchar(127)', $objdb]},
                                     HASH);

       # Remove irrelevant statement text.
       undef $X->{ErrInfo}{SP_call};

       # Store the profile in the handle.
       $X->{'procs'}{$SP}{'params'} = $paramdefs;
       $X->{'procs'}{$SP}{'normal'} = $normalspec;
    }

    # Check that the number of unnamed parameters does not exceed the
    # number of parameters the SP actually have.
    if ($unnamed and $#$unnamed > $#$paramdefs - 1) {
       my $no_of_passed = $#$unnamed + 1;
       my $no_of_real = $#$paramdefs;   # Since @paramdefs include return value.
       my $msg = ($no_of_passed > 1 ?
                 "There were $no_of_passed parameters " :
                 "There was a parameter ") .
                 "passed for procedure '$SP' that does ";
       if ($no_of_real == 0) {
          $msg .= "not take any parameters.";
       }
       elsif ($no_of_real == 1) {
          $msg .= "only take one parameter.";
       }
       else {
          $msg .= "only take $no_of_real parameters.";
       }
       $X->olledb_message(-1, 1, 16, $msg);
       return (wantarray ? () : undef);
    }

    # At this point we need one array for parameters, and one to receive
    # parameters.
    my($no_of_pars, @all_parameters, @output_params);

    # The return value is first in line.
    $no_of_pars = 0;
    push(@all_parameters, \$retvalueref);

    # Copy a reference for all unnamed parameters.
    foreach my $ix (0..$#$unnamed) {
       push(@all_parameters, \$$unnamed[$ix]);
    }
    $no_of_pars += scalar(@$unnamed);

    # And put named parameters on the slot they appear in the parameter
    # list.
    if ($named and %$named) {
       # Get a crossref from name to position.
       my (%crossref, $no_of_errs);
       foreach my $param (@$paramdefs) {
          $crossref{$$param{'name'}} = $$param{'paramno'}
              if defined $$param{'name'};
       }

       foreach my $key (keys %$named) {
          my $name = $key;

          # Add '@' if missing, but check for duplicates.
          if ($name !~ /^\@/) {
             if (exists($$named{'@' . $key})) {
                my $msg = "Warning: hash parameters for '$SP' includes the key " .
                          "'$name' as well as '\@$name'. The value for '$name' " .
                          "is discarded.";
                $X->olledb_message(-1, 1, 10, $msg);
                next;
             }
             $name = '@' . $name;
          }

          # Check that there is such a parameter
          if (not exists $crossref{$name}) {
             my $msg = "Procedure '$SP' does not have a parameter '$name'";
             $X->olledb_message(-1, 1, 10, $msg);
             $no_of_errs++;
             next;
          }

          my $parno = $crossref{$name};

          if (defined $all_parameters[$parno] and $^W) {
             my $msg = "Parameter '$name' in position $parno for '$SP' " .
                       "was specified both as unnamed and named. Named " .
                       "value discarded.";
             $X->olledb_message(-1, 1, 10, $msg);
             next;
          }

          $no_of_pars++;
          $all_parameters[$parno] = \$$named{$key};
       }

       if ($no_of_errs) {
          my $msg = "There were $no_of_errs unknown parameter(s). " .
                    "Cannot execute procedure '$SP'";
          $X->olledb_message(-1, 1, 16, $msg);
          return (wantarray ? () : undef);
       }
    }


    # Before we start building the command, get information about all
    # table types.
    foreach my $par_ix (0..$#all_parameters) {
       next if not defined($all_parameters[$par_ix]);
       next if not $$paramdefs[$par_ix]{'is_table_type'};
       $$paramdefs[$par_ix]{'tabledef'} =
             $X->get_table_type_info($$paramdefs[$par_ix]{'typeinfo'});
       if (not $$paramdefs[$par_ix]{'tabledef'}) {
            my $msg = "Unable to find information about table type " .
                      $$paramdefs[$par_ix]{'typeinfo'} .
                      ". This is somewhat unexpected.";
            $X->olledb_message(-1, 1, 16, $msg);
            $X->cancelbatch;
            return 0;
       }
    }


    # Compose the SQL statement and initiliaze the batch. We enter the
    # return value as a parameter, and start to build the log string.
    my $SP_conv = $X->{'procs'}{$SP}{'normal'};
    $X->do_conversion('to_server', $SP_conv);
    my $sqlstmt = "{? = call $SP_conv";
    if ($no_of_pars > 0) {
       $sqlstmt .= '(' .join(',', ('?') x $no_of_pars) . ')';
    }
    $sqlstmt .= '}';
    $X->initbatch($sqlstmt);
    $X->{ErrInfo}{SP_call} = "EXEC $SP_conv ";

    # Loop over all parameter references  to enter them.
    foreach my $par_ix (0..$#all_parameters) {
       next if not defined($all_parameters[$par_ix]);

       my($param, $is_ref, $value, $name, $maxlen, $precision, $scale, $type,
          $is_input, $is_output, $typeinfo, $istbltype, $needstypeinfo, $tabledef);

       # Get the actual parameter. What is in @all_parameter is a reference to
       # the parameter.
       $param = ${$all_parameters[$par_ix]};

       # And to confuse you even more - the parameter can itself be a reference
       # to the value. (And damn it! The value can also be a reference!)
       $is_ref = (ref $param) =~ /^(SCALAR|REF)$/;

       # Get attributes for the parameter.
       $name          = $$paramdefs[$par_ix]{'name'};
       $type          = $$paramdefs[$par_ix]{'type'};
       $is_output     = $$paramdefs[$par_ix]{'is_output'};
       $is_input      = $$paramdefs[$par_ix]{'is_input'};
       $maxlen        = $$paramdefs[$par_ix]{'max_length'};
       $precision     = $$paramdefs[$par_ix]{'precision'};
       $scale         = $$paramdefs[$par_ix]{'scale'};
       $typeinfo      = $$paramdefs[$par_ix]{'typeinfo'};
       $istbltype     = $$paramdefs[$par_ix]{'is_table_type'};
       $needstypeinfo = $$paramdefs[$par_ix]{'needstypeinfo'};
       $tabledef      = $$paramdefs[$par_ix]{'tabledef'};

       # Check that we have typeinfo for parameters where this is required.
       if ($needstypeinfo and not $typeinfo) {
          my $msg = "Parameter " . ($name ? "$name" : $par_ix) .
                    " is a '$type' parameter, but the type definition was " .
                    "not found. You may not have permission to access it.";
          $X->olledb_message(-1, 1, 16, $msg);
          $X->cancelbatch;
          return 0;
       }

       # Save reference where to receive the < of output parameters.
       if ($is_output) {
          if ($is_ref) {
             push(@output_params, $param);
          }
          else {
             push(@output_params, $all_parameters[$par_ix]);
             if ($^W and not $X->{ErrInfo}{NoWhine}) {
                my $msg = "Output parameter '$name' was not passed as reference";
                $X->olledb_message(-1, 1, 10, $msg);
             }
          }
       }

       # Get the value and perform conversions of name and value.
       $value = ($is_ref ? $$param : $param) if $is_input;
       $X->do_conversion('to_server', $value);
       $X->do_conversion('to_server', $name);
       $X->do_conversion('to_server', $typeinfo);

       # Set max length for some types where the query does not give the best
       # fit.
       if ($LARGETYPES{$type}) {
          $maxlen = -1;
       }
       elsif ($UNICODETYPES{$type} and $maxlen > 0) {
          $maxlen = $maxlen / 2;
       }

       # Precision and scale should be set only for some types
       undef $precision unless $DECIMALTYPES{$type};
       undef $scale unless $DECIMALTYPES{$type} or $NEWDATETIMETYPES{$type};

       # Add to the log string, execept for return values.
       if ($is_input) {
          $X->{ErrInfo}{SP_call} .= $name . ' = ' .
                                   $X->valuestring($type, $value, $name) . ', ';
       }

       # Now we can enter the parameter, but if it's a table variable there
       # is a special path. We cannot convert the typeinfo until now, because
       # we must pass the unconverted value to do_table_param.
       unless ($istbltype) {
          unless ($PLAINCHARTYPES{$type} and $is_output and
                  $X->{Provider} < PROVIDER_MSOLEDBSQL and
                  $X->{codepages}{$X->{CurrentDB}} == 65001) {
             $X->enterparameter($type, $maxlen, $name, $is_input, $is_output,
                                $value, $precision, $scale, $typeinfo);
          }
          else {
             # For UTF_8 databases, enter char/varchar as Unicode types when we
             # have a legacy provider.
             my $nlen = ($maxlen <= 4000 ? $maxlen : -1);
             $X->enterparameter("n$type", $nlen, $name, $is_input, $is_output,
                                $value, $precision, $scale, $typeinfo);
          }
       }
       else {
          my $ret = $X->do_table_parameter($name, $typeinfo, $tabledef, $value);
          if (not $ret) {
             $X->cancelbatch();
             return 0;
          }
       }
    }

    # Do logging.
    $X->{ErrInfo}{SP_call} =~ s/,\s*$//;
    $X->do_logging;

    # Some variables that we need to execute the function and retrieve the
    # result set.
    my($exec_ok, @results, $resultref);

    # Execute the procedure, unless NoExec is in effect.
    unless ($X->{'NoExec'}) {
       $exec_ok = $X->executebatch();
    }
    else {
       $X->cancelbatch;
       $exec_ok = 0;
    }

    # Retrieve the result sets.
    if (wantarray) {
       @results = $X->do_result_sets($exec_ok, $rowstyle, $resultstyle,
                                     $colinfostyle, $keys);
    }
    else {
       $resultref = $X->do_result_sets($exec_ok, $rowstyle, $resultstyle,
                                       $colinfostyle, $keys);
    }

    # Retrieve output parameters. They are not available if command was
    # cancelled or some such.
    if ($X->getcmdstate == CMDSTATE_GETPARAMS) {
       $X->do_output_parameters(\@output_params);

       # Check the return status if there was one. (The return value is
       # $$retvalueref now.)
       if ($$paramdefs[0]{'is_retstatus'}) {
          my ($retvalue) = $$retvalueref;
          if ($retvalue ne 0 and $X->{ErrInfo}{CheckRetStat} and
              not $X->{ErrInfo}{RetStatOK}{$retvalue}) {
              $X->olle_croak("Stored procedure $SP returned status $retvalue");
          }
       }
    }

    # Remove the faked call from ErrInfo
    delete $X->{ErrInfo}{SP_call};

    # Return the result sets.
    return (wantarray ? @results : $resultref);
}

#-------------------------  sql_insert  -------------------------------
sub sql_insert {
    my ($X) = get_handle(\@_);
    my($tblspec) = shift @_;
    my(%values) = %{shift @_};  # Take a copy, we'll be modifying.

    my($tbldef, $col);

    # If have a column profile saved, reuse it.
    if (exists $X->{'tables'}{$tblspec}) {
       $tbldef = $X->{'tables'}{$tblspec};
    }
    else {
       # We don't about this one. Get data about the table from the server.
       my ($objdb, $objid, @columns);

       # Get the object id for the table and it's database
       ($objid, $objdb) = $X->get_object_id($tblspec);
       if (not $objid) {
          my $msg = "Table '$tblspec' is not accessible";
          $X->olledb_message(-1, 1, 16, $msg);
          return;
       }

       # Now, inquire about all the columns in the table and their type.
       # Different handling for different SQL Server versions.
       my $getcols;
       if ($X->{SQL_version} =~ /^[78]\./) {
          $getcols = <<'SQLEND';
              SELECT name, type = type_name(xtype), length,
                     "precision" = prec, scale, typeinfo = NULL
              FROM   syscolumns
              WHERE  id = @objid
SQLEND
       }
       else {
          # SQL Server 2005 or later.
          $getcols = <<'SQLEND';
              SELECT c.name,
                     type = CASE c.system_type_id
                                 WHEN 240 THEN 'UDT' +
                                      CASE WHEN c.max_length = -1
                                           THEN '(MAX)'
                                           ELSE ''
                                      END
                                  ELSE type_name(c.system_type_id)
                             END,
                     length = c.max_length, c.precision, c.scale,
                     typeinfo =
                     CASE c.system_type_id
                          WHEN 240
                          THEN  coalesce(nullif(@objdb, ''),
                                         quotename(db_name())) + '.' +
                                quotename(s1.name) + '.' + quotename(t.name)
                          WHEN 241
                          THEN  coalesce(nullif(@objdb, ''),
                                         quotename(db_name())) + '.' +
                                quotename(s2.name) + '.' + quotename(x.name)
                     END
              FROM   sys.all_columns c
              LEFT   JOIN (sys.types t
                          JOIN  sys.schemas s1 ON t.schema_id = s1.schema_id)
                  ON  c.user_type_id = t.user_type_id
                 AND  t.is_assembly_type = 1
              LEFT   JOIN (sys.xml_schema_collections x
                           JOIN  sys.schemas s2 ON x.schema_id = s2.schema_id)
                  ON  c.xml_collection_id = x.xml_collection_id
              WHERE  c.object_id = @objid
SQLEND
       }

       # Trim the SQL from extraneous spaces, to save network bandwidth.
       $getcols =~ s/\s{2,}/ /g;

       $tbldef = $X->internal_sql($getcols, $objdb,
                                  {'@objid' => ['int', $objid],
                                   '@objdb' => ['nvarchar', $objdb]},
                                  HASH, KEYED, ['name']);

       # Clear SP_call
       undef $X->{ErrInfo}{SP_call};

       # Save it for future calls.
       $X->{'tables'}{$tblspec} = $tbldef;
    }

    # Build parameter and column array.
    my (@columns, @params);
    foreach my $col (sort keys %values) {
       if (exists $$tbldef{$col}) {
          my $type = $$tbldef{$col}{'type'};
          my $typeinfo = $$tbldef{$col}{'typeinfo'};

          # timestamp/rowversion columns, cannot be inserted into, so skip.
          next if $type =~ /^(timestamp|rowversion)$/;

          if ($DECIMALTYPES{$type}) {
             my $prec = $$tbldef{$col}{'precision'};
             my $scale = $$tbldef{$col}{'scale'};
             $type .= "($prec,$scale)";
          }
          elsif ($NEWDATETIMETYPES{$type}) {
             my $scale = $$tbldef{$col}{'scale'};
             $type .= "($scale)";
          }
          elsif ($TYPESWITHFIXLEN{$type}) {
             my $length = $$tbldef{$col}{'length'};
             if ($UNICODETYPES{$type}) {
                $length /= 2;
             }
             $type .= "($length)";
          }
          push(@params, [$type, $values{$col}, $typeinfo]);
       }
       else {
          # Missing column is an error condition, but let SQL say that.
          push (@params, ['int', undef]);
       }
       if (not defined $values{$col}) {
          $values{$col} = "NULL";
       }
       push(@columns, $col);
    }

    # Build SQL statement.
    my $sqlstmt = "INSERT $tblspec (" . join(', ', @columns) .
                  ")\n   VALUES (" .
                  join(', ', (('?') x scalar(@columns))) . ')';

    # Produce the SQL and run it.
    $X->sql($sqlstmt, \@params);
}

#----------------------- get_result_sets ------------------------------
sub get_result_sets {
   my ($X) = shift @_;
   my($rowstyle, $resultstyle, $colinfostyle, $keys) = check_style_params(@_);
   do_result_sets($X, 1, $rowstyle, $resultstyle, $colinfostyle, $keys);
}

#------------------------- sql_has_errors ----------------------------
sub sql_has_errors {
    my ($X) = get_handle(\@_);
    my ($keep) = @_;

    # Check that SaveMessages is on. Warn if not.
    if ($^W and not $X->{ErrInfo}{SaveMessages}) {
       carp "Since ErrInfo.SaveMessages is OFF, it's useless to call sql_has_errors";
    }

    if (not exists $X->{ErrInfo}{Messages}) {
       return 0;
    }

    my $has_error = 0;
    foreach my $msg (@{$X->{ErrInfo}{Messages}}) {
       next unless $msg->{'severity'} >= 11;
       $has_error = 1;
       last;
    }

    if (not $keep and not $has_error) {
       delete $X->{ErrInfo}{Messages};
    }

    return $has_error;
}

#---------------------- sql_get_command_text -------------------------
sub sql_get_command_text {
    my ($X) = get_handle(\@_);
    return ($X->{ErrInfo}{SP_call} ? $X->{ErrInfo}{SP_call} :
                                     $X->getcmdtext);
}

#-------------------------  sql_string  -------------------------------
sub sql_string {
    # Since the handle is optional here, we do not use get_handle.
    shift @_ if ref ($_[0]) eq PACKAGENAME;
    my($str) = @_;
    if (defined $str) {
       $str =~ s/'/'\'/g;
       "'$str'";
    }
    else {
       "NULL";
    }
}

#------------------------- transaction routines -----------------------
sub sql_begin_trans {
    my ($X) = get_handle(\@_);
    $X->sql("BEGIN TRANSACTION");
}

sub sql_commit {
    my ($X) = get_handle(\@_);
    $X->sql("COMMIT TRANSACTION");
}

sub sql_rollback {
    my ($X) = get_handle(\@_);
    $X->sql("ROLLBACK TRANSACTION");
}

#--------------------- sql_message_handler ----------------------------
sub sql_message_handler {
    my($X, $errno, $state, $severity, $text, $server,
       $procedure, $line, $sqlstate, $source, $n, $no_of_errs) = @_;

    my($ErrInfo, $print_msg, $print_text, $print_lines, $fh);

    # First get a reference to an ErrInfo hash.
    $ErrInfo = $X->{ErrInfo};

    # If this is the first message in a burst, clear the die and carp flags.
    $ErrInfo->{DieFlag}  = 0 if $n == 1;
    $ErrInfo->{CarpFlag} = 0 if $n == 1;

    # Determine where to write the messages.
    $fh = ($ErrInfo->{ErrFileHandle} or \*STDERR);

    # Save messages if requested.
    if ($ErrInfo->{SaveMessages}) {
       my %message;
       tie %message, 'Win32::SqlServer::ErrInfo::Messages';
       %message = (Errno    => $errno,
                   State    => $state,
                   Severity => $severity,
                   Text     => $text,
                   Proc     => $procedure,
                   Line     => $line,
                   Server   => $server,
                   SQLstate => $sqlstate,
                   Source   => $source);
       push(@{$ErrInfo->{Messages}}, \%message);
    }

    # If there is no sqlstate, just set it to empty string, so we don't
    # have to test for undef all the time.
    $sqlstate = '' if not defined $sqlstate;

    # Find out whether we should stop on this error unless die flag
    # already set.
    unless ($ErrInfo->{DieFlag}) {
       if ($severity > $ErrInfo->{MaxSeverity}) {
          $ErrInfo->{DieFlag} = 1 unless ($ErrInfo->{NeverStopOn}{$errno} or
                                          $ErrInfo->{NeverStopOn}{$sqlstate});
       }
       else {
          $ErrInfo->{DieFlag} = ($ErrInfo->{AlwaysStopOn}{$errno} or
                                 $ErrInfo->{AlwaysStopOn}{$sqlstate});
       }
    }

    # Then determine if to print and what.
    unless ($ErrInfo->{NeverPrint}{$errno} or $ErrInfo->{NeverPrint}{$sqlstate}) {
       # Not in neverPrint. If in alwaysPrint, print it all.

       if (not ($ErrInfo->{AlwaysPrint}{$errno} or
                $ErrInfo->{AlwaysPrint}{$sqlstate})) {
          # Nope. Check each part.
          $print_msg = $severity >= $ErrInfo->{PrintMsg};
          $print_text = $severity >= $ErrInfo->{PrintText};
          $print_lines = $severity >= $ErrInfo->{PrintLines};

          # Carp only if there is a message, and severity is above level-
          if ($severity >= $ErrInfo->{CarpLevel} and
              ($print_msg or $print_text or $print_lines)) {
             $ErrInfo->{CarpFlag}++
          }
       }
       else {
          $print_msg = $print_text = $print_lines = 1;
          $ErrInfo->{CarpFlag}++;
       }

       # Here goes printing for each part. First message info.
       if ($print_msg) {
          if (not $source) {
             print $fh "SQL Server message $errno, Severity $severity, ",
                       "State $state";
             print $fh ", Server $server" if $server;
             if ($procedure) {
                print $fh "\nProcedure $procedure, Line $line";
             }
             else {
                print $fh "\nLine $line" if $line;
             }
             print $fh "\n";
          }
          else {
             print $fh "Message "  . ($sqlstate ? $sqlstate : $errno) .
                       " from '$source', Severity: $severity\n";
             print $fh "Internal Win32::SqlServer call: $procedure\n" if $procedure;
          }
       }

       # The text.
       if ($print_text) {
          print $fh "$text\n" if $text;
       }

       # The lines. This is slightly more tricky. If SP_call is defined, use
       # that, else get the command text. Apply LinesWindow only in the latter
       # case.
       if ($print_lines) {
          my ($linetxt, $window);
          $linetxt = $X->sql_get_command_text();
          $window  = $ErrInfo->{LinesWindow};
          if ($linetxt) {
             my ($lineno);
             foreach my $row (split (/\n/, $linetxt)) {
                $lineno++;
                # Always print the line if there is no window or there was
                # no line number. Else print only if lineno is within window.
                if (not defined $window or not $line or
                    $lineno >= $line - $window and $lineno <= $line + $window) {
                   print $fh sprintf("%5d", $lineno), "> $row\n";
                }
             }
          }
       }
    }

    # Check for disconnect. The test on severity is hard-coded as that is
    # how SQL Server works.
    if ($severity >= 20 or $ErrInfo->{DisconnectOn}{$errno} or
       $$ErrInfo{DisconnectOn}{$sqlstate}) {
       $X->disconnect();
    }

    if ($n == $no_of_errs and $ErrInfo->{DieFlag}) {
         $X->olle_croak("Terminating on fatal error");
    }

    if ($n == $no_of_errs and $ErrInfo->{CarpFlag}) {
       carp "Message from " . (defined $source ? $source : 'SQL Server');
    }

    return 1;
}

#---------------------  internal_sql  --------------------------------------
# Very similar to the official sql, but does not check NoExec and 
# Loghandle. Nor does it do output parameters. On the other hand it has
# an extra mandatory parameter $targetdb which specifies the statement
# to run the statement in. 
# Used for internal calls to support sql_sp and sql_insert.
sub internal_sql
{
    my ($X) = get_handle(\@_);

    my $sql = shift @_;
    my $targetdb = shift @_;

    # Get parameter array if any.
    my ($arrayparams, $hashparams);
    if (ref $_[0] eq "ARRAY") {
       $arrayparams = shift @_;
    }
    if (ref $_[0] eq "HASH") {
       $hashparams = shift @_;
    }

    # Style parameters. Get them from @_ and then check that values are
    # legal and supply defaults as needed.
    my($rowstyle, $resultstyle, $colinfostyle, $keys) = check_style_params(@_);

    # Apply conversion.
    $X->do_conversion('to_server', $sql);

    # Set up the SQL command - initbatch and enter parameters if necesary.
    $X->setup_sqlcmd($sql, $targetdb, $arrayparams, $hashparams);

    my $exec_ok = $X->executebatch;

    # And get the resultsets.
    return $X->do_result_sets($exec_ok, $rowstyle, $resultstyle,
                              $colinfostyle, $keys);
}

#----------------------- olle_croak, internal -----------------------
sub olle_croak  {
    my ($X, $msg) = @_;
    delete $X->{ErrInfo}{DieFlag};
    delete $X->{ErrInfo}{CarpFlag};
    delete $X->{ErrInfo}{SP_call};
    $X->cancelbatch;
    croak($msg);
}

#---------------------- valuestring, internal----------------------------
sub valuestring {
    my ($X, $datatype, $value, $name) = @_;
    # Returns $value as literal suitable for SQL code.

    if ($datatype =~ /table( type)?/) {
    # For a table parameter we return the name of the parameter. Elsewhere
    # code is generated to declare and insert data into the table variable.
    # If no value is defined, we should pass default, NULL is not legal for
    # table parameters.
       if (not defined $value or ref $value eq 'ARRAY' and not @$value) {
          return 'DEFAULT';
       }
       else {
          return $name;
       }
    }
    elsif (not defined $value) {
       return "NULL";
    }
    elsif ($UNICODETYPES{$datatype} or $datatype eq 'sql_variant') {
       return 'N' . sql_string($value);
    }
    elsif ($BINARYTYPES{$datatype}) {
       my $ret;
       if ($X->{BinaryAsStr}) {
          $ret = $value;
          $ret = "0x$ret" unless $ret =~ /^0x/i;
       }
       else {
          $ret = "0x" . uc(unpack('H*', $value));
       }
       return $ret;
    }
    elsif ($QUOTEDTYPES{$datatype}) {
       return sql_string($value);
    }
    elsif ($datatype eq 'xml') {
       # For xml we need to check the encoding to find out whether we should
       # have an N or not.
       my $encoding;
       my $N = '';
       if ($value =~ /^\<\?xml\s+version\s*=\s*"1.0"\s+encoding\s*=\s*"([^\"]+)"/) {
          $encoding = lc($1);
       }
       if (not $encoding or $encoding =~ /^(utf-16|ucs)/) {
       # If no encoding found, it is UTF-8. If no listed encoding, it is
       # assumed to be 8-bit (or more exactly varchar.)
           $N = 'N';
       }
       elsif ($encoding eq 'utf-8') {
       # An explicit utf-8 declaration is devilish, because the string
       # we will print will not interpreted as UTF-8 by the T-SQL parser.
       # So to make it execute and pass the test suite - we simply remove
       # the part of the declartion! Then we pretend as if it was ucs-2.
          $value =~ s/(^\<\?xml\s+version\s*=\s*"1.0"\s+)encoding\s*=\s*"utf-8"/$1/i;
          $N = 'N';
       }
       return $N . sql_string($value);
    }
    elsif ($datatype eq 'bit') {
       return ($value ? 1 : 0);
    }
    else {
       return $value;
    }
}

#--------------------- new_err_info, internal----------------------------
sub new_err_info {
    # Initiates an err_info hash and returns a reference to it. We
    # set default to print everything but two messages (changed db
    # and language) and to stop on everything above severity 10.

    my(%ErrInfo);
    tie %ErrInfo, 'Win32::SqlServer::ErrInfo';

    # Initiate default error handling: stop on severity > 10, and print
    # both messages and lines.
    $ErrInfo{PrintMsg}       = 1;
    $ErrInfo{PrintText}      = 0;
    $ErrInfo{PrintLines}     = 11;
    $ErrInfo{NeverPrint}     = {'5701' => 1, '5703' => 1};
    $ErrInfo{AlwaysPrint}    = {'3606' => 1, '3607' => 1, '3622' => 1};
    $ErrInfo{MaxSeverity}    = 10;
    $ErrInfo{CheckRetStat}   = 1;
    $ErrInfo{SaveMessages}   = 0;
    $ErrInfo{CarpLevel}      = 10;
    $ErrInfo{DisconnectOn}   = {'2745'  => 1,  '4003' => 1,  '5702' => 1,
                                '17308' => 1, '17310' => 1, '17311' => 1,
                                '17571' => 1, '18002' => 1, '08001' => 1,
                                '08003' => 1, '08004' => 1, '08007' => 1,
                                '08S01' => 1};

    \%ErrInfo;
}

#-------------------- do_conversion, internal ----------------
sub do_conversion{
    my ($X) = shift @_;
    my ($direction) = shift @_;
    if (defined $X->{$direction}) {
       my $reftype = ref $_[0];

       if ($reftype eq "HASH") {
          # HASH needs particular care to handle the keys.
          my %tmp;
          foreach my $key (keys %{$_[0]}) {
             my $keycopy = $key;
             my $valuecopy = ${$_[0]}{$key};
             &{$X->{$direction}}($X, $keycopy, $valuecopy);
             $tmp{$keycopy} = $valuecopy;
          }
          $_[0] = \%tmp;
       }
       elsif ($reftype  eq "ARRAY") {
          if ($direction eq 'to_server') {
          # On direction to the server, we must work on a copy of the data,
          # so we don't change the caller's data. (Think table parameters.)
             my @tmp = @{$_[0]};
             $_[0] = \@tmp;
          }
          &{$X->{$direction}}($X, @{$_[0]});
       }
       elsif ($reftype eq "SCALAR") {
          if ($direction eq 'to_server') {
             my $tmp = ${$_[0]};
             $_[0] = \$tmp;
          }
          &{$X->{$direction}}($X, ${$_[0]});
       }
       else {
          &{$X->{$direction}}($X, @_);
       }
    }
}

#------------------------ do_logging, internal ----------------------
sub do_logging {
   my($X) = @_;

   if ($X->{LogHandle}) {
      my ($F) = $X->{LogHandle};
      my $sql = $X->sql_get_command_text();
      print $F "$sql\ngo\n";
   }
}

#--------------------- check_style_params, internal -------------------
sub check_style_params {
# Checks that row-, result- and colinfostyle parameters including keys
# array. Also checks for extraneous parameters.

    my ($rowstyle, $resultstyle, $colinfostyle, $keys);

    # Get the parameters.
    my $parno = 0;
    foreach my $par (@_) {
       $parno++;

       # Check for too many parameters. Keep in mind that $keys is always last.
       if ($parno > 4 or $keys) {
           croak PACKAGENAME . ": Extraneous parameter(s) specified";
       }

       # Just skip undef.
       next if not defined $par;

       # Check for the various styles. First weed out all cases where the
       # parameter is not numeric to avoid warnings about this.

       # An array reference only make sense if we have KEYED.
       if (ref $par eq 'ARRAY' and $resultstyle == KEYED) {
          $keys = $par;
       }
       # A code reference is a result style.
       elsif (ref $par eq 'CODE') {
          croak PACKAGENAME . ": Multiple result styles specified" if $resultstyle;
          $resultstyle = $par;
       }
       elsif (ref $par or $par =~ /\D/) {
          croak PACKAGENAME . ": Illegal style parameter '$par'";
       }
       # Here follows test for numeric styles.
       elsif (grep($_ == $par, ROWSTYLES)) {
          croak PACKAGENAME . ": Multiple row styles specified" if $rowstyle;
          $rowstyle = $par;
       }
       elsif (grep($_ == $par, RESULTSTYLES)) {
          croak PACKAGENAME . ": Multiple result styles specified" if $resultstyle;
          $resultstyle = $par;
       }
       elsif (grep($_ == $par, COLINFOSTYLES)) {
          croak PACKAGENAME . ": Multiple colinfo styles specified"
              if $colinfostyle;
          $colinfostyle = $par;
       }
       else {
          croak PACKAGENAME . ": Illegal style parameter $par";
       }
    }

    # Set defaults for those we did not get anything for.
    $rowstyle     = HASH         if not $rowstyle;
    $resultstyle  = SINGLESET    if not $resultstyle;
    $colinfostyle = COLINFO_NONE if not $colinfostyle;

    # Check that we have legal combinations. Some result styles cannot be
    # combined with column information.
    if ($colinfostyle != COLINFO_NONE and
        grep($_ == $resultstyle, (NORESULT, SINGLEROW, KEYED))) {
        croak PACKAGENAME . ": For result styles NORESULT, SINGLEROW and KEYED, you cannot request column information with \$colinfostyle";
    }

    # And full column info requires ARRAY or LIST.
    if ($colinfostyle == COLINFO_FULL and $rowstyle == SCALAR) {
        croak PACKAGENAME . ": Column style COLINFO_FULL cannot be combined with row style SCALAR"
    }

    # If result style is KEYED, check that we have a sensible keys.
    if ($resultstyle == KEYED) {
       croak PACKAGENAME . ": No keys given for result style KEYED"
             unless $keys;
       croak PACKAGENAME . ": \$keys is not a list reference"
             unless ref $keys eq "ARRAY";
       croak PACKAGENAME . ": Empty key array given for resultstyle KEYED"
             if @$keys == 0;
       if ($rowstyle != HASH) {
          croak PACKAGENAME . ": \@\$keys must be numeric for rowstyle LIST/SCALAR"
             if grep(/\D/, @$keys);
       }
    }

    # Return parameters.
    return($rowstyle, $resultstyle, $colinfostyle, $keys);
}

#------------------- setup_sqlcmd, internal --------------------------
sub setup_sqlcmd {
   my($X, $sql, $targetdb, $arrayparams, $hashparams, $outputparams) = @_;
   # Common routine for sql and sql_one. If both $arraypams and $hashparame 
   # are undef, just calls initbatch. Else runs through the parameters and
   # Generates a call to sp_executesql for $sql, the parameter list and
   # the parameters in %$params. $targetdb says which database the 
   # statement is to run in, currently only used by internal_sql.

   # Initial cleanup.
   delete $X->{ErrInfo}{SP_call};

   if (not ($arrayparams or $hashparams)) {
      # This is the simple one. Do it and leave.
      $X->initbatch($sql);
      return 1;
   }

   my (@paramnames);    # A parallel array to $arrayparams that holds the parameter names.
   my ($no_of_unnamed); # The number of elements initially in @$arrayparams.
   my ($paramdecls);    # Parameter declaration for the second param to sp_executesql.
   my (@parameters);    # Here we assemble input to enterparameter.
   my ($paramvalues);   # Parameter assignments for sp_executesql.
   my (@tabledefs);     # Table-type definition for table-parameters.

   # Give the all array parameters names on the form @P1 etc
   foreach my $ix (0..$#$arrayparams) {
      my $parno = $ix + 1;
      push(@paramnames, "\@P$parno");
   }

   # Repack hash parameters as array parameters, so we can handle them in
   # the same manner. Also check for name clashes with unnamed parameters.
   $no_of_unnamed = scalar(@$arrayparams);
   foreach my $parname (sort keys %$hashparams) {
      my $parname_as_given = $parname;

      # If the parameter does not have a leading @, add one, and check for
      # clashes.
      if ($parname !~ /^\@/) {
         if (exists $$hashparams{'@' . $parname}) {
            my $msg = "Warning: hash parameters for Win32::SqlServer::sql " .
                      "includes the key '$parname' as well as '\@$parname'. The " .
                      "value for the key '$parname' is discarded.";
            $X->olledb_message(-1, 1, 10, $msg);
            next;
         }
         $parname = '@' . $parname;
      }

      # If name is @P1 or simlar, check for clash with named parameter.
      if ($parname =~ /^\@P(\d+)$/) {
         my $parno = $1;
         if ($parno <= $no_of_unnamed and $^W) {
            my $msg =  "Warning: Value was provided for a named parameter " .
                       "'\@P$parno', but $no_of_unnamed unnamed values were " .
                       "also provided. The value for the named parameter is " .
                       "discarded.";
            $X->olledb_message(-1, 1, 10, $msg);
            next;
         }
      }

      push(@$arrayparams, $$hashparams{$parname_as_given});
      push(@paramnames, $parname);
   }

   # Now we can iterate over all parameters.
   foreach my $ix (0..$#$arrayparams) {
      my ($par, $parname, $value, $datatype, $isoutput, $typename,
          $typequal, $length, $precision, $scale, $typeinfo, $typestring);

      $par = $$arrayparams[$ix];
      $parname = $paramnames[$ix];
      if (ref $par eq 'ARRAY') {
         $datatype  = $$par[0];
         $value     = $$par[1];
         $typeinfo  = $$par[2];
      }
      else {
         $value = $par;
      }

      # If there is no datatype, supply a default, but give a warning unless
      # a NULL value is being passed.
      if (not defined $datatype) {
         if (defined $value and $^W) {
            my $msg = "Warning: no datatype provided for parameter '$parname', value '$value'.";
            $X->olledb_message(-1, 1, 10, $msg);
         }
         $datatype = 'varchar';
      }

      # Is this an output parameter?
      $isoutput = 0;
      if (ref $value eq 'SCALAR' or
          ref $value eq 'REF' and ref $$value eq 'HASH') {
         $isoutput = 1;
         push(@$outputparams, $value);
         $value = $$value;
      }

      # Time to tackle the data type. The first step is to separate any
      # part in parenthses from the rest. 
      if ($datatype =~ /(^.*)\s*\(([^\)]+)\)\s*$/) {
         $typename = $1;
         $typequal = $2;
      }
      else {
         $typename = $datatype;
      }
      
      # Normalise the typname to be lowercase (save for UDT).
      $typename = lc($typename);
      $typename = 'UDT' if $typename eq 'udt';

      # Trim leading/trailing spaces and any quoting.
      $typename =~ s/(^\s+|\s+$)//g;
      if ($typename =~ /^\[.+\]$/ or $typename =~ /^".+"$/) {
         $typename = substr($typename, 1, length($typename) - 2);
      }

      # If this is not a known type, see it this is user-defined type
      # and in such case replace with the definition. (And this case 
      # we should look at the full type string.) 
      if (not $ALLSYSTEMTYPES{$typename}) {
         # Note that if there is no match, $typename will be = $datatype. 
         # But it's undef if there is an error.
         ($typename, $typequal) = get_usertype_info($X, $datatype);
         if (not defined $typename) {
            return 0;
         }
      }

      # If there is a qualifier, analyse it further. If qualifier does
      # not fit with the type, consider the datatype specification to 
      # be the name, and enterparameter will hold the axe later on.
      if (defined $typequal) {
         if ($typequal =~ /^\s*\d+\s*$/) {
            # A single number. This is OK for strings, binary and
            # decimal types
            if ($TYPESWITHLENGTH{$typename}) {
               $length = $typequal;
            }
            elsif ($DECIMALTYPES{$typename}) {
               $precision = $typequal;
            }
            elsif ($NEWDATETIMETYPES{$typename}) {
               $scale = $typequal;
            }
            else {
               $typename = $datatype;
            }
         }
         elsif ($typequal =~ /^\s*MAX\s*$/i and $MAXTYPES{$typename}) {
            $length = -1;
         }
         elsif ($typequal =~ /^\s*(\d+)\s*,\s*(\d+)\s*$/ and
                $DECIMALTYPES{$typename}) {
             $precision = $1;
             $scale     = $2;
         }
         elsif ($TYPEINFOTYPES{$typename}) {
             if (defined $typeinfo and $typeinfo ne $typequal) {
                my $msg = "Conflicting type information ('$typequal' and " .
                          "'$typeinfo') provided for parameter '$parname' " .
                          "of datatype $typename.";
                $X->olledb_message(-1, 1, 16, $msg);
                return 0;
             }
             $typeinfo = $typequal;
         }
         else {
            $typename = $datatype;
         }
      }

      # Get length for variable length types.
      if (($TYPESWITHLENGTH{$typename} or $CLRTYPES{$typename})) {
         unless (defined $length) {
            my $maxlen = ($UNICODETYPES{$typename} ? 4000 : 8000);
            my $valuelen = 1;

            # Compute the length of the value.
            if (defined $value) {
               $valuelen = (length($value) or 1);

               # For binary as string, length passed is only half of value.
               if ($BINARYTYPES{$typename} and $X->{BinaryAsStr}) {
                  $valuelen -= 2 if $value =~ /^0x/ and $valuelen > 2;
                  $valuelen++ if $valuelen % 2;   # Make sure it's an even number.
                  $valuelen = $valuelen / 2;
               }
            }

            # For varchar etc, we can set the default length to be the
            # maxlen, to always use the same value to avoid cache bloat.
            if ($TYPESWITHFIXLEN{$typename}) {
               # For fixed-length types (char etc) we use the length of the
               # string, but warn the user that this is a bad habit.
               $length = $valuelen;
               if ($^W) {
                  my $msg = "Warning: length not specified for data type " .
                            "'$datatype'.";
                  $X->olledb_message(-1, 1, 10, $msg);
               }

               # Handle overlong strings.
               if ($length > $maxlen) {
                  if ($X->{SQL_version} =~ /^8\./) {
                     $length = $maxlen;
                  }
                  else {
                     # On SQL 2005 and later we can use MAX for some datatypes
                     $length = ($MAXTYPES{$typename} ? -1 : $maxlen);
                  }
               }
            }
            else {
               # For varchar etc, we can use the max length for the type,
               # and save the user from a warning.
               $length = $maxlen;

               # But on SQL 2005 and later, we should use the MAX types
               # where applicable.
               if (defined $value and $valuelen > $maxlen and
                   $MAXTYPES{$typename} and $X->{SQL_version} !~ /^8\./) {
                  $length = -1;
               }
            }
         }
      }
      elsif ($LARGETYPES{$typename}) {
         $length = -1;
      }
      else {
         $length = 0;
      }

      # Set precision/scale for decimal types and new date/time types
      # if not provided.
      if ($DECIMALTYPES{$typename}) {
         if (not defined $precision or not defined $scale) {
            if ($^W and defined $value) {
               my $msg = "Precision and/or scale missing for decimal parameter '$parname'.";
               $X->olledb_message(-1, 1, 10, $msg);
            }
            $precision = 18 if not defined $precision;
            $scale     = 0  if not defined $scale;
         }
      }
      elsif ($NEWDATETIMETYPES{$typename}) {
      # Things missing does not render a warning here, because the default
      # is max scale.
         $scale = 7 if not defined $scale;
      }

      # Check that typeinfo not provided when not applicable, and that is
      # specified for UDT
      if ($TYPEINFOTYPES{$typename}) {
         if ($typename ne 'xml' and not defined $typeinfo) {
            my $msg = "No actual user type specified for $typename parameter '$parname'.";
            $X->olledb_message(-1, 1, 16, $msg);
            $X->cancelbatch;
            return 0;
         }
      }
      elsif (defined $typeinfo) {
         my $msg = "The third element in the parameter array does not " .
                   "apply to the data type $datatype.";
         $X->olledb_message(-1, 1, 16, $msg);
         $X->cancelbatch;
         return 0;
      }

      # If the parameter is a table parameter, get the type information
      # from cache.
      if ($typename eq 'table') {
         my $tbldef = $X->get_table_type_info($typeinfo, 1);
         if (not $tbldef) {
            my $msg = "Unable to find information about table type '$typeinfo'.";
            $X->olledb_message(-1, 1, 16, $msg);
            $X->cancelbatch;
            return 0;
         }
         push(@tabledefs, $tbldef);
      }

      # Time to form the string to use for the type in the parameter
      # list to sp_executesql.
      if ($TYPESWITHLENGTH{$typename}) {
          $typestring = "$typename(" . 
                        ($length == -1 ? 'MAX' : $length) .")";
      }
      elsif ($DECIMALTYPES{$typename}) {
         $typestring = "$typename($precision, $scale)";
      }
      elsif ($NEWDATETIMETYPES{$typename}) {
         $typestring = "$typename($scale)";
      }
      elsif ($typename eq 'UDT') {
         $typestring = $typeinfo;
      }
      elsif ($typename eq 'table') {
         $typestring = "$typeinfo READONLY";
      }
      elsif ($typename eq 'xml' and $typeinfo) {
         $typestring = "$typename($typeinfo)";
      }
      else {
         $typestring = $typename;
      }


      # Do conversion of value and parameter name and data types. Typeinfo
      # for tables will be converted later.
      $X->do_conversion('to_server', $value);
      $X->do_conversion('to_server', $parname);
      $X->do_conversion('to_server', $typestring);
      $X->do_conversion('to_server', $typeinfo);

      # And save the parameter. There is a special case for UTF-8 data
      # databases and older providers. Here we specify (var)char as Unicode
      # types.
      unless ($PLAINCHARTYPES{$typename} and
              $X->{Provider} < PROVIDER_MSOLEDBSQL and
              $X->{codepages}{$X->{CurrentDB}} == 65001) {
         push(@parameters, [$typename, $length, $parname, 1, $isoutput, 
                            $value, $precision, $scale, $typeinfo]);
      }
      else {
         my $nlength = ($length <= 4000 ? $length : -1);
         push(@parameters, ["n$typename", $nlength, $parname, 1, $isoutput, 
                            $value, $precision, $scale, $typeinfo]);
      }

      # Add to the parameter declaration.
      $paramdecls .= (defined $paramdecls ? ", " : '') .
                     $parname . " " . $typestring .
                     ($isoutput ? " OUTPUT" : '');

      # Add to the parameter string for logging.
      $paramvalues .= (defined $paramvalues ? ", " : '') .
                       $parname . " = " .
                       $X->valuestring($typename, $value, $parname) .
                       ($isoutput ? " OUTPUT" : '');
   }

   # Determine the spec to use for sp_executesql; it could be in a 
   # different database.
   my $sp_executesql = 'sp_executesql';
   if (defined $targetdb and $targetdb =~ /\S/) {
      $sp_executesql = "$targetdb." . 
                    ($X->{SQL_version} =~ /^[78]\./ ? 'dbo' : 'sys') .
                    ".$sp_executesql";
   }

   # Replace ? with @P1 etc in the query string.
   $X->replaceparamholders($sql);

   # Build log string for error handling.
   $X->{errInfo}{SP_call} = "EXEC $sp_executesql N" . sql_string($sql) . ",\n" .
                            ' ' x 5 . 'N'. sql_string($paramdecls) . ",\n" .
                            ' ' x 5 . $paramvalues;

   # First build the sp_executesql command and init the batch, and enter
   # the first parameter.
   my $executesql = "{call $sp_executesql(?, ?, " .
                  join(', ', ('?') x scalar(@parameters)) . ')}';
   $X->initbatch($executesql);

   # Enter parameter for the statement. On SQL 2005, we can use
   # nvarchar(max), but not SQL 2000 we have to resort to ntext.
   my $stmtdtype = ($X->{SQL_version} =~ /^[8]\./ ? 'ntext' : 'nvarchar');
   $X->enterparameter($stmtdtype, -1, '@stmt', 1, 0, $sql);

   # Enter the parameter for parameter list.
   $X->enterparameter($stmtdtype, -1, '@parameters', 1, 0, $paramdecls);

   # Enter all the "real" parameters.
   foreach my $p (@parameters) {
      unless ($$p[0] eq 'table') {
         $X->enterparameter(@$p);
      }
      else {
         my $tabledef = shift(@tabledefs);
         my $ret = $X->do_table_parameter($$p[2], $$p[8], $tabledef, $$p[5]);
         if (not $ret) {
            $X->cancelbatch();
            return 0;
         }
      }
   }

   return 1;
}

#-------------------------- get_usertype_info --------------------------
# Gets information about a user-defined type a k a "alias type" from the
# cache or from the database if it's not in cache. The return value is a
# two-element array with typename and any qualifier.
sub get_usertype_info {
   my ($X, $usertype) = @_;

   if (not $X->{'usertypes'}{$usertype}) {

      # First crack the type name into pieces.
      my ($server, $typedb, $typeschema, $typename);
      my $ret = $X->parsename($usertype, 1, $server, 
                              $typedb, $typeschema, $typename);
      return undef if not $ret;

      # Cannot have a server name in the type specification.
      if ($server) {
         my $msg =  "Type name '$usertype' contains a server portion. " .
                    "This is illegal.";
         $X->olledb_message(-1, 1, 16, $msg);
         return undef;
      }

      # On SQL 2000, the schema cannot be anything else than dbo.
      if ($X->{SQL_version} =~ /^[678]\./ and 
          $typeschema and $typeschema ne 'dbo') {
         my $msg =  "Type name '$usertype' has a schema different from " .
                    "'dbo'. This is illegal on SQL 2000 and earlier.";
         $X->olledb_message(-1, 1, 16, $msg);
         return undef;
      }

      # Typeinfo we get back from SQL Server
      my ($systemtype, $maxlength, $prec, $scale);

      # Construct the type query, different for SQL 7/2000 on the one hand
      # and one for SQL 2005 and later.
      if ($X->{SQL_version} =~ /^[78]\./) {
         my $typequery = <<'SQLEND';
         SELECT st.name, ut.length, ut.prec, ut.scale
         FROM   dbo.systypes ut
         JOIN   dbo.systypes st ON ut.xtype = st.xtype
         WHERE  ut.name = parsename(@name, 1)
           AND  st.usertype <= 255
SQLEND

         ($systemtype, $maxlength, $prec, $scale) =
                   $X->internal_sql($typequery, $typedb, 
                                    {'@name'   => ['nvarchar', $typename]}, 
                                     SINGLEROW, LIST);
      }
      else {
         # On "modern" versions we use type_id which sorts out
         # schema priority for us.
         my $typeid = $X->internal_sql('SELECT type_id(?)', $typedb,
                                      [['nvarchar', "$typeschema.$typename"]],
                                      SCALAR, SINGLEROW);

         my $typequery = <<'SQLEND';
         SELECT CASE WHEN t.system_type_id = 240 THEN 'UDT'
                     WHEN t.system_type_id = 243 THEN 'table'
                     ELSE type_name(t.system_type_id)
                 END, t.max_length, t.precision, t.scale
         FROM   sys.types t
         JOIN   sys.schemas s ON t.schema_id = s.schema_id
         WHERE  t.user_type_id = @typeid
SQLEND

         ($systemtype, $maxlength, $prec, $scale) =
                   $X->internal_sql($typequery, $typedb, 
                                    {'@typeid' => ['int', $typeid]},
                                     SINGLEROW, LIST);
      } 

      # If we did not find any type, return the input.
      return ($usertype, undef) if not $systemtype;

      # Determine any qualifier (the part in parens);
      my $qualifier;
      if ($TYPESWITHLENGTH{$systemtype}) {
         if ($maxlength == -1) {
            $qualifier = "MAX";
         }
         elsif ($UNICODETYPES{$systemtype}) {
            $qualifier = $maxlength/2;
         }
         else {
            $qualifier .= $maxlength;
         }
      }
      elsif ($DECIMALTYPES{$systemtype}) {
         $qualifier = "$prec, $scale";
      }   
      elsif ($NEWDATETIMETYPES{$systemtype}) {
         $qualifier .= $scale;
      }
      elsif ($TYPEINFOTYPES{$systemtype}) {
         $qualifier = $usertype;
      } 
   
      # Save to the cache.
      $X->{'usertypes'}{$usertype} = [$systemtype, $qualifier];
   }

   # Return the two-element array.
   return @{$X->{'usertypes'}{$usertype}};
}

#------------------------- get_table_type_info---------------------------
# Gets information about a table type from the cache or from the database
# if it's not there.
sub get_table_type_info {
    my($X, $tabletype, $isparamsql) = @_;

    # First crack the type name into pieces.
    my ($server, $typedb, $typeschema, $typename);
    my $ret = $X->parsename($tabletype, 1, $server, 
                            $typedb, $typeschema, $typename);
    return undef if not $ret;

    # Cannot have a server name in the type specification.
    if ($server) {
       my $msg =  "Type name '$tabletype' contains a server portion. " .
                  "This is illegal.";
       $X->olledb_message(-1, 1, 16, $msg);
       return undef;
    }

    # Nor a database name for ad-hoc sql. (SQL Server does not
    # support it.)
    if ($isparamsql and $typedb) {
       my $msg =  "Type name '$tabletype' contains a database portion. " .
                  "This is illegal for ad-hoc batches.";
       $X->olledb_message(-1, 1, 16, $msg);
       return undef;
    }

    # Since sql_sp always passes database.schema.type, we cannot have
    # database without a schema. Assert this, because we rely on this below.
    if ($typedb and not $typeschema) {
       $X->olle_croak("Internal error: There is a typedb ('$typedb'), " .
                      "but no type schema?\n");
    }

    if (not defined $X->{tabletypes}{$tabletype}) {
       # First get the type id. We use type_id to look both the default 
       # schema and the dbo schema.
       my $typeid = $X->internal_sql('SELECT type_id(?)', $typedb,
                                    [['nvarchar', "$typeschema.$typename"]],
                                    SCALAR, SINGLEROW);

       my $getcols = <<'SQLEND';
       SELECT c.name,
              typename = CASE c.system_type_id
                              WHEN 240 THEN 'UDT'
                              ELSE type_name(c.system_type_id)
                          END,
              c.precision, c.scale, c.max_length,
              needsdefault = CASE WHEN c.is_identity = 1 THEN 1
                                  WHEN c.is_computed = 1 THEN 1
                                  WHEN type_name(c.system_type_id) IN
                                        ('timestamp', 'rowversion') THEN 1
                                  ELSE 0
                            END,
              typeinfo =
              CASE c.system_type_id
                   WHEN 240
                   THEN  coalesce(nullif(@typedb, ''),
                                  quotename(db_name())) + '.' +
                         quotename(s1.name) + '.' + quotename(t.name)
                   WHEN 241
                   THEN  coalesce(nullif(@typedb, ''),
                                  quotename(db_name())) + '.' +
                         quotename(s2.name) + '.' + quotename(x.name)
              END,
              codepage = collationproperty(c.collation_name, 'Codepage')
       FROM   sys.table_types tt
       JOIN   sys.schemas s0 ON tt.schema_id = s0.schema_id
       JOIN   sys.all_columns c ON tt.type_table_object_id = c.object_id
       LEFT   JOIN (sys.types t
                   JOIN  sys.schemas s1 ON t.schema_id = s1.schema_id)
           ON  c.user_type_id = t.user_type_id
          AND  t.is_assembly_type = 1
       LEFT   JOIN (sys.xml_schema_collections x
                    JOIN  sys.schemas s2 ON x.schema_id = s2.schema_id)
           ON  c.xml_collection_id = x.xml_collection_id
       WHERE  tt.user_type_id = @typeid
       ORDER BY c.column_id
SQLEND

       # Trim the SQL from extraneous spaces, to save network bandwidth.
       $getcols =~ s/\s{2,}/ /g;

       # Get the data, and save it the internal cache.
       my $tbldef = $X->internal_sql($getcols, $typedb,
                                    {'@typedb' => ['nvarchar', $typedb],
                                     '@typeid' => ['int', $typeid]},
                                    HASH);

       # Only save to the cache if we actually found something.
       if (@$tbldef) {
          $X->{'tabletypes'}{$tabletype} = $tbldef;
       }

       # Clear SP_call
       undef $X->{ErrInfo}{SP_call};
    }

    return $X->{tabletypes}{$tabletype};
}

#------------------------- do_table_parameter -------------------------
# Does all work needed to handle a table parameter: retrieves the type
# definition unless it's in the cache, defines the table, and inserts
# the rows in $value into the parameter.
sub do_table_parameter {
    my ($X, $paramname, $tabletype, $typedef, $value) = @_;

    my (@columns, $isempty);

    # If $value is undef or an empty array, we can pass DEFAULT for the
    # table and don't have to bother with loading the table definition.
    if (not defined $value) {
       $isempty = 1;
    }
    elsif (not ref $value eq 'ARRAY') {
       my $msg = "Illegal value '$value' passed for table parameter " .
                 "'$paramname'; The value must be an array reference.";
       $X->olledb_message(-1, 1, 16, $msg);
       return 0;
    }
    else {
       $isempty = scalar(@$value) == 0;
    }

    # If the table is empty, define the parameter and quit.
    if ($isempty) {
       return $X->enterparameter('table', 0, $paramname, 1, 0, undef, undef, undef,
                                 $tabletype);
    }

    # Enter the table parameter.
    my $ret = $X->enterparameter('table', scalar(@$typedef), $paramname, 1, 0,
                                 undef, undef, undef, $tabletype);
    return 0 if not $ret;

    # Define the table.
    foreach my $coldef (@$typedef) {
       my $colname      = $coldef->{'name'};
       my $coltype      = $coldef->{'typename'};
       my $maxlen       = $coldef->{'max_length'};
       my $precision    = $coldef->{'precision'};
       my $scale        = $coldef->{'scale'};
       my $needsdefault = $coldef->{'needsdefault'};
       my $typeinfo     = $coldef->{'typeinfo'};
       my $codepage     = $coldef->{'codepage'};

       # Set max length for some types where the query does not give the best
       # fit.
       if ($LARGETYPES{$coltype}) {
          $maxlen = -1;
       }
       elsif ($UNICODETYPES{$coltype} and $maxlen > 0) {
          $maxlen = $maxlen / 2;
       }

       # In many cases we want to send (var)char is n(var)chardata
       # to avoid unwanted character conversion which happens on 
       # two levels. 1) AutoTranslate is always on for TVPs, it seems
       # 2) Conversion to the DB collation. So only if column collation
       # and the DB collation is the ANSI code page, we can send things 
       # the regular way.
       if ($coltype =~ /^(var)?char$/ and 
           ($codepage != GetACP() or 
            $codepage != $X->{codepages}{$X->{CurrentDB}})) {
          $coltype = "n$coltype";
          if ($maxlen > 4000) {
             $coltype = 'nvarchar';
             $maxlen = -1;
          }
       }   


       # Precision and scale should be set only for some types
       undef $precision unless $DECIMALTYPES{$coltype};
       undef $scale unless $DECIMALTYPES{$coltype} or $NEWDATETIMETYPES{$coltype};

       $X->do_conversion('to_server', $colname);
       $X->do_conversion('to_server', $typeinfo);

       $X->definetablecolumn($paramname, $colname, $coltype, $maxlen,
                             $precision, $scale, $needsdefault, $typeinfo);

       # Save column name for logging.
       push(@columns, $colname) unless $needsdefault;
    }

    # Set up for logging.
    my $logstmt = "DECLARE $paramname $tabletype;\n";
    my $loginsert = "INSERT $paramname(" .
                    join(', ', map({s/\]/]]/g; "[$_]"} @columns)) .
                    ") VALUES\n";
    my @logrows;

    foreach my $r (@$value) {
        my (@columnvalues);

        # First check that the row has legal format.
        my $reftype = ref $r;
        unless ($reftype =~ /^(ARRAY|HASH)$/) {
           my $msg = "Illegal value '$r' for row in table parameter " .
                     "'$paramname'. This must be an array or hash reference.";
           $X->olledb_message(-1, 1, 16, $msg);
           $X->cancelbatch();
           return 0;
        }

        my $row = $r;
        $X->do_conversion('to_server', $row);
        $X->inserttableparam($paramname, $row);

        foreach my $ix (0..$#$typedef) {
           next if $$typedef[$ix]->{'needsdefault'};
           my $colname = $$typedef[$ix]->{'name'};
           my $coltype = $$typedef[$ix]->{'typename'};

           if ($reftype eq 'HASH') {
              push(@columnvalues, $X->valuestring($coltype, $$row{$colname}));
           }
           elsif ($reftype eq 'ARRAY') {
              push(@columnvalues, $X->valuestring($coltype, $$row[$ix]));
           }
        }

        push(@logrows, "(" . join(', ', @columnvalues) . ")");
    }

    # And finally add the log stuff to the SP_call thing. Since an
    # INSERT VALUES can only take 1000 values, we need to split this up.
    for my $i (0 .. int($#logrows / 1000)) {
       my $first_ix = $i * 1000;
       my $last_ix  = (($i + 1)*1000 < $#logrows) ? ($i * 1000 + 999) :
                      $#logrows;
       $logstmt .= $loginsert . join(",\n", @logrows[$first_ix .. $last_ix]);
    }
    $X->{ErrInfo}{SP_call} = $logstmt . "\n" . $X->{ErrInfo}{SP_call};
}


#---------------------- get_db_codepage -------------------------
# Retrieves the code page for the current database if needed. This 
# procedure is called from the C++ code, which is why we use the 
# mid-level interface directly.
sub get_db_codepage {
    my($self) = @_;

    my ($exec_ok, $currentdb, $codepage);

    $currentdb = $self->{CurrentDB};
    if (not defined $currentdb) {
       $self->olle_croak("Internal error: when entering get_db_codepage, CurrentDB is not defined.");
    }

    # If we already know the code page for this database, we can quit.
    return if exists $self->{codepages}{$currentdb};

    # Else, we run this query to get the codepage for the current database. 
    $self->initbatch(<<'SQLEND', 1);
        SELECT collationproperty(convert(nvarchar(128), 
                                     databasepropertyex(db_name(), 'Collation')), 
                                 'Codepage') AS Codepage
SQLEND
    $exec_ok = $self->executebatch();
    if (not $exec_ok) {
        $self->olle_croak("Failed to retrieve the code page.\n");
    }

    while ($self->nextresultset()) {
       my $hashref;
       if ($self->nextrow($hashref, undef)) {
           $codepage  = $$hashref{'Codepage'};
       }
       last if defined $codepage;
    }
    if (not defined $codepage) {
       $self->olle_croak("Could not retrieve the code page for the current database\n");
    }
    $self->cancelbatch();

    # Save the value.
    $self->{codepages}{$currentdb} = $codepage;
}


#------------------- get_object_id, internal ---------------------------
sub get_object_id {
   my($X, $objspec) = @_;
# Retrieves the object id for a database object.

    my(@objspec, $server, $objdb, $schema, $object, $objid, $normalspec);

    # Call C++ code to crack the object specification into parts.
    my $ret = $X->parsename($objspec, 1, $server, $objdb, $schema, $object);
    return (undef, undef) if not $ret;

    # We do currently not support names with server in it.
    if ($server) {
       my $msg = "Name '$objspec' includes a server portion. This is " .
                 "currently not supported.";
       $X->olledb_message(-1, 1, 16, $msg);
       return(undef, undef);
    }

    # Construct a normalised object specification. This is basically the
    # input, but spaces between the parts removed.
    $normalspec = ($objdb ? "$objdb." : '') .
                  (($schema or $objdb) ? "$schema." : '') .
                   $object;

    # A temporary object is per definition in tempdb.
    if ($object =~ /^#/ and $objdb eq '') {
       $objdb = "tempdb";
    }

    # Now we can reconstruct the object specification.
    $objspec = "$objdb.$schema.$object";

    # Get the object-id.
    $objid = $X->internal_sql("SELECT object_id(?)", undef,
                              [['nvarchar', $objspec]],
                              SCALAR, SINGLEROW);

    # If no luck, it might still be a system procedure.
    if (not defined $objid and $object =~ /^[\"\[]?sp_/) {
       $objdb = "master";
       $objspec = "master.$schema.$object";
       $objid = $X->internal_sql("SELECT object_id(?)", undef, 
                                 [['nvarchar', $objspec]],
                                 SCALAR, SINGLEROW);
    }

    # Clear SP_call from error info to avoid incorrect statement prints.
    undef $X->{ErrInfo}{SP_call};

    # Return id, database and normalised spec.
    ($objid, $objdb, $normalspec);
}

#---------------------- do_result_sets, internal ---------------------------------
sub do_result_sets {
    my($X, $exec_ok, $rowstyle, $resultstyle, $colinfostyle, $keys) = @_;

    my ($userstat, $is_callback, $isregular, $ismultiset, $wantcolinfo, $ix,
        $ressetno, $rowcount, $colinforef, $dataref, $resref, $keyed_res,
        $iscancelled, $caller);

    $is_callback = ref $resultstyle eq "CODE";
    $isregular   = grep ($_ == $resultstyle,
                         (MULTISET, MULTISET_RC, SINGLESET, SINGLEROW));
    $ismultiset = grep ($_ == $resultstyle, (MULTISET, MULTISET_RC));
    $wantcolinfo = $colinfostyle != COLINFO_NONE;
    $iscancelled = not $exec_ok;

    $ix = $ressetno = 0;
    $userstat = RETURN_NEXTROW;
    while (not $iscancelled and $X->isconnected() and
           $X->nextresultset($rowcount)) {
       $ressetno++;

       # He said NORESULT? Cancel the query, and proceed to next.
       if ($resultstyle == NORESULT) {
          $X->cancelresultset;
          next;
       }

       # Get column information if requested. We also need it for
       # MULTISET_RC to be able to discern an empty result from a pure
       # rowcount.
       if ($wantcolinfo or $resultstyle == MULTISET_RC) {
          $X->getcolumninfo(($rowstyle == HASH) ? $colinforef : undef,
                            ($rowstyle == HASH) ? undef : $colinforef);

          # Repack, if full colinfo is not requested.
          if (defined $colinforef) {
             # There are columns, thus we should clear the rowcount and
             # not add it to the output.
             undef $rowcount;

             # If colinfo style is NONE, just forget about it.
             if ($colinfostyle == COLINFO_NONE) {
                undef $colinforef;
             }
             # For NAMES and POS we need to repack.
             elsif ($colinfostyle == COLINFO_NAMES) {
                if ($rowstyle == HASH) {
                   foreach my $key (keys %$colinforef) {
                      $$colinforef{$key} = $$colinforef{$key}{Name};
                   }
                }
                else {
                   foreach my $colinfo (@$colinforef) {
                      $colinfo = $$colinfo{Name};
                   }
                }
             }
             elsif ($colinfostyle == COLINFO_POS) {
                if ($rowstyle == HASH) {
                   foreach my $key (keys %$colinforef) {
                      $$colinforef{$key} = $$colinforef{$key}{Colno};
                   }
                }
                else {
                   foreach my $colinfo (@$colinforef) {
                      $colinfo = $$colinfo{Colno};
                   }
                }
              }
              # For FULL ne need to do nothing here.
          }

          # For SINGLESET we should only return column information once.
          if ($resultstyle == SINGLESET) {
             $wantcolinfo = 0;
          }
       }

       # For the regular result styles create an empty array, if there is none at
       # the current index.
       if ($isregular) {
          @{$$resref[$ix]} = () unless defined $$resref[$ix];
       }
       elsif ($resultstyle == KEYED) {
          # For KEYED create result set, now we know we have a result set.
          $keyed_res = {} unless $keyed_res;
       }

       while (1) {
          my $morerows;

          if (defined $colinforef) {
          # If we have column information, do this first, unless we have a
          # callback.
             $dataref = $colinforef;
             undef $colinforef;
             $morerows = 1;
          }
          else {
             # Get a row with data.
             $morerows = $X->nextrow(($rowstyle == HASH) ? $dataref : undef,
                                     ($rowstyle == HASH) ? undef : $dataref);
          }

          # Are we past the last row?
          if (not $morerows) {
             # For MULTISET_RC save the row count, if the result set was
             # empty and we have a row count.
             if ($resultstyle == MULTISET_RC and defined $rowcount and
                 scalar(@{$$resref[$ix]}) == 0) {
                 $$resref[$ix] = $rowcount;
             }
             # The get out of this loop.
             last if not $morerows;
          }

          # Convert to client charset before anything else.
          $X->do_conversion('to_client', $dataref);

          # For SCALAR convert to joined string. (But for KEYED, this is deferred.)
          if ($rowstyle == SCALAR and $resultstyle != KEYED) {
             $dataref = list_to_scalar($dataref);
          }

          # Save the row if we have a regular resultstyle.
          if ($isregular) {
             push(@{$$resref[$ix]}, $dataref);
          }
          elsif ($resultstyle == KEYED) {
             # This is keyed access.
             store_keyed_result($X, $rowstyle, $keys, $dataref, $keyed_res);
          }
          elsif ($is_callback) {
             $userstat = &$resultstyle($dataref, $ressetno);

             if ($userstat == RETURN_NEXTQUERY) {
                # He wants next result set, so leave this one.
                $X->cancelresultset;
                last;
             }
             elsif ($userstat != RETURN_NEXTROW) {
             # Whatever, cancel the entire batch.
                $iscancelled = 1;
                $X->cancelbatch;
                if ($userstat == RETURN_ABORT) {
                   $X->olle_croak("User-supplied callback returned RETURN_ABORT");
                }
                elsif ($userstat != RETURN_CANCEL and $userstat != RETURN_ERROR) {
                   $X->olle_croak("User-supplied callback returned unknown return code");
                }
                last;
             }
          }
       }

       # If multiset requested advance index
       $ix++ if $ismultiset;
    }

    if ($is_callback) {
       return $userstat;
    }
    elsif (wantarray) {
       if ($resultstyle == KEYED) {
          if (defined $keyed_res) {
             return %$keyed_res;
          }
          else {
             return ();
          }
       }
       elsif (defined $resref) {
          if    ($ismultiset)  {return @$resref }
          elsif ($resultstyle == SINGLESET) {return @{$$resref[0]} }
          elsif ($resultstyle == SINGLEROW) {
              if    ($rowstyle == HASH)
                 { return (defined $$resref[0][0] ? %{$$resref[0][0]} : () )}
              elsif ($rowstyle == LIST)
                 { return (defined $$resref[0][0] ? @{$$resref[0][0]} : () )}
              elsif ($rowstyle == SCALAR) { return @{$$resref[0]} }
          }
          elsif ($resultstyle == KEYED) { return %$keyed_res; }
          else  { return ()}
       }
       else {
          return ();
       }
    }
    else {
       if    ($ismultiset)  {return $resref }
       elsif ($resultstyle == SINGLESET) {return $$resref[0] }
       elsif ($resultstyle == SINGLEROW) {return $$resref[0][0] }
       elsif ($resultstyle == KEYED)     {return $keyed_res }
       else  { return undef}
    }
}

#----------------------------- list_to_scalar ------------------------
# This routine takes a data array and returns a scalar from it. Care
# if being taken to avoid "unitialized value" warnings.
sub list_to_scalar {
   my ($arr) = @_;
   local($^W) = 0;
   if (@$arr == 0) {
      return undef;
   }
   elsif (@$arr == 1) {
      # If there is a single element return this as is and do not use
      # join below, as this would convert an undef to defined value.
      return $$arr[0];
   }
   else
   {
      return join($SQLSEP, @$arr);
   }
}


#------------------------------ store_keyed_result ---------------------
# This routine implements KEYED access. The key columns are removed from the
# list/hash that $dataref points to and added as keys to $keyed_res.
sub store_keyed_result {
   my ($X, $rowstyle, $keys, $dataref, $keyed_res) = @_;

   my ($keyvalue, $keyname, $keyno, $ref, $keystr);

   $ref = $keyed_res;
   $keystr = "";

   # Loop over the keys.
   foreach my $ix (0..$#$keys) {
      # First find the key value, different strategies with different row styles.
      if ($rowstyle == HASH) {
         # Get the key name.
         $keyname = $$keys[$ix];

         # If the key does not exist, we give up.
         unless (exists $$dataref{$keyname}) {
            $X->olle_croak(PACKAGENAME . ": No key '$keyname' in result set");
         }

         # Get the key value, and delete it from the data.
         $keyvalue = $$dataref{$keyname};
         delete $$dataref{$keyname};
      }
      else {
         # Now we have a key number.
         $keyno = $$keys[$ix];

         # It must be a valid index in the result set.
         unless ($keyno >= 1 and $keyno <= $#$dataref + 1) {
             $X->olle_croak(PACKAGENAME . ": Key number '$keyno' is not valid in result set");
         }

         # Get the key value, but don't touch @$dataref yet.
         $keyvalue = $$dataref[$keyno - 1];
      }

      # If this is not the last key, just create the node.
      if ($ix < $#$keys) {
         $ref = \%{$$ref{$keyvalue}};
      }

      # Add keys to debug string, for use in warning messages.
      $keystr .= "<$keyvalue>" if $^W;
   }

   # Now we can remove data from an array - had we done this above, the key numbers
   # wouldn't have matched.
   if ($rowstyle != HASH) {
      foreach my $ix (reverse sort @$keys) {
         splice(@$dataref, $ix - 1, 1);
      }

      # If we're talking scalar, convert at this point
      if ($rowstyle == SCALAR) {
         $dataref = list_to_scalar($dataref);
      }
   }


   # At this point $ref{$keyvalue} is where we want to store the rest of the data.
   # Just check that the spot is not already occupied.
   if ($^W) {
      carp "Key(s) $keystr is not unique" if exists $$ref{$keyvalue};
   }

   # And write into the result set.
   $$ref{$keyvalue} = $dataref;
}


#------------------------ do_output_parameters ----------------------
# Internal routine to retrieve the value of output parameters.
sub do_output_parameters {
   my($X, $outputparams) = @_;

   # Output parameters are not available if command was cancelled or 
   # some such.
   if ($X->getcmdstate == CMDSTATE_GETPARAMS) {
      my ($outputvalues);

      # Retrieve output parameters
      $X->getoutputparams(undef, $outputvalues);
      $X->do_conversion('to_client', $outputvalues);

      # And map values to the input parameters.
      foreach my $ix (0..$#$outputparams) {
         ${$$outputparams[$ix]} = $$outputvalues[$ix];
      }
   }
}


package Win32::SqlServer::ErrInfo;

use strict;
use Tie::Hash;
use Carp;

use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter Tie::StdHash);

use constant FIELDS => qw(ErrFileHandle DieFlag CarpFlag MaxSeverity
                          NeverStopOn AlwaysStopOn PrintMsg PrintText
                          PrintLines NeverPrint AlwaysPrint CarpLevel
                          CheckRetStat RetStatOK SaveMessages Messages
                          SP_call NoWhine LinesWindow DisconnectOn);

my %fields;

foreach my $f (FIELDS) {
   $fields{$f}++;
}


# My own FETCH routine, chckes that retrieval is of a known elements.
sub FETCH {
   my ($self, $key) = @_;
   if (not exists $fields{$key}) {
       $key =~ s/^./uc($&)/e;
       if (not exists $fields{$key}) {
           croak("Attempt to fetch undefined ErrInfo element '$key'");
       }
   }
   return $self->{$key};
}

# My own STORE routine, barfs if attribute is non-existent.
sub STORE {
   my ($self, $key, $value) = @_;
   if (not exists $fields{$key}) {
       $key =~ s/^./uc($&)/e;
       if (not exists $fields{$key}) {
           croak("Attempt to set undefined ErrInfo element '$key'");
       }
   }
   $self->{$key} = $value;
}

sub DELETE {
   my ($self, $key) = @_;
   if (not exists $fields{$key}) {
       $key =~ s/^./uc($&)/e;
   }
   delete $self->{$key};
}

sub EXISTS {
   my ($self, $key) = @_;
   if (not exists $fields{$key}) {
       $key =~ s/^./uc($&)/e;
   }
   return exists $self->{$key};
}


package Win32::SqlServer::ErrInfo::Messages;

use strict;
use Tie::Hash;
use Carp;

use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter Tie::StdHash);

use constant FIELDS => qw(Errno State Severity Proc Line Server
                          Text SQLstate Source);

my %mfields;

foreach my $f (FIELDS) {
   $mfields{$f}++;
}

# The same FETCH as before. Barf if does not exist, but permit initial
# lowercase.
sub FETCH {
   my ($self, $key) = @_;
   if (not exists $mfields{$key}) {
       $key =~ s/^./uc($&)/e;
       if (not exists $mfields{$key}) {
           croak("Attempt to fetch undefined Message element '$key'");
       }
   }
   return $self->{$key};
}

# My own STORE routine, barfs if attribute is non-existent and permits
# inital lowercase.
sub STORE {
   my ($self, $key, $value) = @_;
   if (not exists $mfields{$key}) {
       $key =~ s/^./uc($&)/e;
       if (not exists $mfields{$key}) {
           croak("Attempt to set undefined Message element '$key'");
       }
   }
   $self->{$key} = $value;
}

sub DELETE {
   my ($self, $key) = @_;
   if (not exists $mfields{$key}) {
       $key =~ s/^./uc($&)/e;
   }
   delete $self->{$key};
}

sub EXISTS {
   my ($self, $key) = @_;
   if (not exists $mfields{$key}) {
       $key =~ s/^./uc($&)/e;
   }
   return exists $self->{$key};
}



1;
