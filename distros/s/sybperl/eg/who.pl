#!/usr/local/bin/perl
#
#	@(#)who.pl	1.2	9/22/94
#

format STDOUT_TOP=
                    Sysprocesses Report

Spid Kpid     Engine Status Suid Hostname Program    Hostpid Cmd            Cpu  IO   Mem Bk Dbid Uid Gid
---------------------------------------------------------------------------------------------------------
.
format STDOUT=
@### @########## @# @<<<<<<< @## @<<<<<<< @<<<<<<<<<< @##### @<<<<<<<<<<<<< @### @### @### @# @# @### @###
$dat{spid}, $dat{kpid}, $dat{engine}, $dat{status}, $dat{suid}, $dat{hostname}, $dat{program_name}, $dat{hostprocess}, $dat{cmd}, $dat{cpu}, $dat{physical_io}, $dat{memusage}, $dat{blocked}, $dat{dbid}, $dat{uid}, $dat{gid}
.

require 'sybperl.pl';

$x = &dblogin();
&dbcmd($x, "select * from master..sysprocesses\n");
&dbsqlexec($x);
&dbresults($x);
while(%dat = &dbnextrow($x, 1))
{
#   foreach (keys(%dat))
#   {
#	print "$_: $dat{$_}\n";
#   }
#   print "-------------------\n";
    write;
}

