#---------------------------------------------------------------------
# $Header: /Perl/OlleDB/makefile.pl 26    16-07-11 22:25 Sommar $
#
# Makefile.pl for MSSQL::OlleDB. Note that you may need to specify where
# you ave the include files for OLE DB.
#
# $History: makefile.pl $
# 
# *****************  Version 26  *****************
# User: Sommar       Date: 16-07-11   Time: 22:25
# Updated in $/Perl/OlleDB
# Adapted to link-library refactoring in VS2015.
# 
# *****************  Version 25  *****************
# User: Sommar       Date: 15-05-24   Time: 21:07
# Updated in $/Perl/OlleDB
# Reduced littering when doing make install.
# 
# *****************  Version 24  *****************
# User: Sommar       Date: 12-09-23   Time: 22:53
# Updated in $/Perl/OlleDB
# No longer need /DELAYLOAD, but there is one more object file.
# 
# *****************  Version 23  *****************
# User: Sommar       Date: 12-07-19   Time: 0:20
# Updated in $/Perl/OlleDB
# Move to SQL Native Client 11.
# 
# *****************  Version 22  *****************
# User: Sommar       Date: 11-08-07   Time: 23:27
# Updated in $/Perl/OlleDB
# Oops! The entry dynamic_lib was incorrect after removal of /base
# option.
# 
# *****************  Version 21  *****************
# User: Sommar       Date: 10-11-17   Time: 14:47
# Updated in $/Perl/OlleDB
# Added /W3 to the compiler flags - need to investigate those warnings
# later.
#
# *****************  Version 20  *****************
# User: Sommar       Date: 10-10-29   Time: 16:20
# Updated in $/Perl/OlleDB
# Added GetProcessWorkingSetSize only to be able to test for memory
# leaks. Any use of this routine outside this scope is unsupported. The
# procedure could be removed without notice.
#
# *****************  Version 19  *****************
# User: Sommar       Date: 08-05-12   Time: 22:04
# Updated in $/Perl/OlleDB
# Exit 0 instead of die when things are bad.
#
# *****************  Version 18  *****************
# User: Sommar       Date: 08-05-04   Time: 18:36
# Updated in $/Perl/OlleDB
# Must use delayed inmport for SQLNCLI.DLL so that Win32::SqlServer can
# run on machines without it.
#
# *****************  Version 17  *****************
# User: Sommar       Date: 08-04-28   Time: 23:10
# Updated in $/Perl/OlleDB
# Need to cater for the 64-bit version of the link library for SQL Native
# Client.
#
# *****************  Version 16  *****************
# User: Sommar       Date: 08-03-23   Time: 19:30
# Updated in $/Perl/OlleDB
# Added common debug flag. Sometimes needed when testing...
#
# *****************  Version 15  *****************
# User: Sommar       Date: 08-01-05   Time: 0:24
# Updated in $/Perl/OlleDB
# New file tableparam.obj
#
# *****************  Version 14  *****************
# User: Sommar       Date: 07-12-24   Time: 21:38
# Updated in $/Perl/OlleDB
# The big explosion: split the single source file for XS into a whole
# bunch.
#
# *****************  Version 13  *****************
# User: Sommar       Date: 07-11-26   Time: 22:46
# Updated in $/Perl/OlleDB
# Added a libfile, since we now need to link against sqlnlic10.lib.
#
# *****************  Version 12  *****************
# User: Sommar       Date: 07-09-09   Time: 0:11
# Updated in $/Perl/OlleDB
# Get SQLNCLI from 100/SDK, so that we can suppor Katmai.
#
# *****************  Version 11  *****************
# User: Sommar       Date: 07-07-10   Time: 21:14
# Updated in $/Perl/OlleDB
# New machine, new location for WINZIP.
#
# *****************  Version 10  *****************
# User: Sommar       Date: 06-04-17   Time: 21:52
# Updated in $/Perl/OlleDB
# Now forcgin the C run-time to be staically linked.
#
# *****************  Version 9  *****************
# User: Sommar       Date: 05-11-26   Time: 23:47
# Updated in $/Perl/OlleDB
# Renamed the module to Win32::SqlServer and advanced to version 2.001.
#
# *****************  Version 8  *****************
# User: Sommar       Date: 05-11-20   Time: 19:31
# Updated in $/Perl/OlleDB
# Look for SQLNCLI.H on any disk. Use -P to Winzip for correct packaging.
#
# *****************  Version 7  *****************
# User: Sommar       Date: 05-11-19   Time: 21:26
# Updated in $/Perl/OlleDB
#
# *****************  Version 6  *****************
# User: Sommar       Date: 05-11-13   Time: 16:32
# Updated in $/Perl/OlleDB
# Use /O2 for optimization.
#
# *****************  Version 5  *****************
# User: Sommar       Date: 05-07-03   Time: 23:41
# Updated in $/Perl/OlleDB
# Now we use SQLNCLI.H, which means that we will have to move away from
# VC6.
#
# *****************  Version 4  *****************
# User: Sommar       Date: 04-08-23   Time: 22:49
# Updated in $/Perl/OlleDB
#
# *****************  Version 3  *****************
# User: Sommar       Date: 04-08-23   Time: 21:52
# Updated in $/Perl/OlleDB
#
# *****************  Version 2  *****************
# User: Sommar       Date: 04-04-27   Time: 22:32
# Updated in $/Perl/MSSQL/OlleDB
#
# *****************  Version 1  *****************
# User: Sommar       Date: 04-03-18   Time: 20:24
# Created in $/Perl/MSSQL/OlleDB
#---------------------------------------------------------------------


use strict;
use Config;
use ExtUtils::MakeMaker;

# Run CL to see if we are running some version of the Visual C++ compiler.
my $cl = `cl 2>&1`;
my $clversion = 0;
if ($cl =~ m!^Microsoft.*C/C\+\+\s+Optimizing\s+Compiler\s+Version\s+(\d+)!i) {
   $clversion = $1;
}

if ($clversion == 0) {
   warn "You don't appear to have Visual C++ installed. If you use another\n";
   warn "C++ compiler, I have no idea whether that will work or not. Be warned!\n";
}
elsif ($clversion < 13) {
   warn "You are using Visual C++ 6.0 or earlier. Unfortunately, OlleDB.xs\n";
   warn "performs an #include of SQLNCLI.H which does not compile with VC6.\n";
   warn  "No MAKEFILE generated.\n";
   exit 0
}

my $SQLDIR  = '\Program Files\Microsoft SQL Server\110\SDK';
my $sqlnclih = "$SQLDIR\\INCLUDE\\SQLNCLI.H";
foreach my $device ('C'..'Z') {
   if (-r "$device:$sqlnclih") {
      $SQLDIR = "$device:$SQLDIR";
      last;
   }
}
if ($SQLDIR !~ /^[C-Z]:/) {
    warn "Can't find '$sqlnclih' on any disk.\n";
    warn 'Check setting of $SQLDIR in makefile.pl' . "\n";
    warn "No MAKEFILE generated.\n";
    exit 0;
}

my $archlibdir = ($ENV{PROCESSOR_ARCHITECTURE} eq 'AMD64' ? 'x64' : $ENV{PROCESSOR_ARCHITECTURE});
my $libfile = qq!"$SQLDIR\\LIB\\$archlibdir\\sqlncli11.lib"!;

# Set specific flags we want for compilation.
my $ccflags = $Config{'ccflags'};
my $optimize = $Config{'optimize'};

# Force -MT over -MD, so that I don't have to include the MSVCRT in the
# binary distribitution.
$ccflags =~ s/-MD\b/-MT/;
$optimize =~ s/-MD\b/-MT/;

# With /O1, one test fails with AS1401 and x86. Yes, one single test! Why?
# Beats me.
$ccflags =~ s/-O1\b/-O2/;
$optimize =~ s/-O1\b/-O2/;

# Libraries loaded depending on the VS version
my $vslibs = '';
if ($clversion >= 19) {
   $vslibs = 'ucrt.lib libvcruntime.lib';
}
else {
   $vslibs = 'psapi.lib';
}

WriteMakefile(
    'INC'          => ($SQLDIR ? qq!-I"$SQLDIR\\INCLUDE"! : ""),
    'NAME'         => 'Win32::SqlServer',
    'CCFLAGS'      => $ccflags,
    'OPTIMIZE'     => $optimize,
    'OBJECT'       => 'SqlServer.obj handleattributes.obj convenience.obj ' .
                      'datatypemap.obj init.obj internaldata.obj ' .
                      'errcheck.obj connect.obj utils.obj datetime.obj ' .
                      'tableparam.obj senddata.obj getdata.obj filestream.obj ', 
    'LIBS'         => [":nosearch :nodefault $libfile $vslibs kernel32.lib user32.lib ole32.lib oleaut32.lib uuid.lib libcmt.lib"],
    'PM'           => {'SqlServer.pm' => '$(INST_LIB)/Win32/SqlServer.pm'},
    'VERSION_FROM' => 'SqlServer.pm',
    'XS'           => { 'SqlServer.xs' => 'SqlServer.cpp'},
    'dist'         => {ZIP => '"C:\Program Files\Winzip\wzzip"',
                       ZIPFLAGS => '-r -P'}
);

sub MY::xs_c {
    '
.xs.cpp:
   $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
';
}

