#!/usr/bin/perl
#	Title:	touch.pl
#	Author:	T. R. Wyant
#	Date:	14-May-2004
#	Modified:
#	Remarks:
#		This Perl script is intended to be a demonstrator for
#		the Win32API::File::Time module, but in fact is useful
#		in its own right. The command interface is supposed to
#		be similar to the unix "touch" tool.

use strict;
use warnings;

use constant USAGE => <<eod;

Usage: perl touch.pl [options] FILE ...

Update the access and modification times of each FILE to the current time.

  -a                     change the access time
  -c                     do not create any files
  -creation              change the creation time
  -no-create             synonym for -c
  -date STRING           parse STRING with Date::Manip and use it instead of
                           the current time. Appears to have problems when
                           dealing with normal time during summer time, or
                           vice versa.
  -f                     ignored
  -m                     change the modification time
  -reference FILE        use this file's times instead of the current time
  -t STAMP               use [[CC]YY]MMDDhhmm[.ss] instead of the current time
  -time WORD             set the time given by WORD:
                           'access', 'atime', and 'use' are the same as -a
                           'modify' and' 'mtime' are the same as -m
                           you can specify this more than once
  -help                  display this help and exit
  -test                  display all times, but don't change any
  -verbose               display the names of files as they are modified
  -version               display version information and exit

Parsing is by Getopt::Long, so any unique abbreviation will work. Absent any
time specification, the current time is used. Absent any specification of what
to set, the access and modification times are set.
eod

use constant VERSION => <<eod;
Perl touch 0.01
Written by Tom Wyant.

Copyright (C) 2004 E. I. DuPont de Nemours and Company.
eod

use FileHandle;
use Getopt::Long;
use POSIX qw{strftime};
use Time::Local;
use Win32API::File::Time qw{GetFileTime SetFileTime};

use constant TIME_FMT => '%d-%b-%Y %H:%M:%S';

my %opt = (
    verbose => 0,
    );

GetOptions (\%opt, qw{
	a
	c|no-create
	creation
	date=s
	f
	help
	m
	reference=s
	t=s
	test
	time=s@
	verbose+
	version}) or die USAGE;

$opt{help} and do {
    print USAGE;
    exit;
    };

$opt{version} and do {
    print VERSION;
    exit;
    };

my %time_word = (
    atime => 'a',
    access => 'a',
    use => 'a',
    mtime => 'm',
    modify => 'm',
    ctime => 'creation',
    create => 'creation',
    );

$opt{time} ||= [];
foreach my $key (@{$opt{time}}) {
    $time_word{$key} or die <<eod;
touch: Invalid argument '$key' for -time
Valid arguments are:
  - 'atime', 'access', 'use'
  - 'mtime', 'modify'
  - 'ctime', 'create'
Try 'touch --help' for more information.
eod
    $opt{$time_word{$key}} = 1;
    }
$opt{a} = $opt{m} = 1 unless $opt{a} || $opt{m} || $opt{creation};


my ($atime, $mtime, $ctime);
$opt{date} and do {
    require Date::Manip;
    $atime = $mtime = $ctime = Date::Manip::UnixDate ($opt{date}, '%s');
    };
not $atime and $opt{t} and do {
    $opt{t} =~ m/^(\d{8,12})(\.(\d{2}))?$/ or die <<eod;
touch: invalid date format '$opt{t}'.
eod
    my @time;
    push @time, $3 || 0;
    my $mins = $1;
    $mins =~ s/(\d{2})(\d{2})(\d{2})(\d{2})$//;
    push @time, $4, $3, $2, $1 - 1, $mins || (localtime)[5];
    $atime = $mtime = $ctime = timelocal (@time);
    };
not $atime and $opt{reference} and do {
    ($atime, $mtime, $ctime) = GetFileTime ($opt{reference});
    };
not $atime and $atime = $mtime = $ctime = time ();

$opt{a} or $atime = undef;
$opt{m} or $mtime = undef;
$opt{creation} or $ctime = undef;

foreach my $fn (@ARGV) {
    -e $fn or do {
	next if $opt{c};
	FileHandle->new (">$fn") or die <<eod;
Error - Unable to create $fn
        $!
eod
	};
    $opt{test} and do {
	($atime, $mtime, $ctime) = GetFileTime ($fn);
	print <<eod;
Testing - $fn
    Accessed: @{[strftime TIME_FMT, localtime $atime]}
    Modified: @{[strftime TIME_FMT, localtime $mtime]}
     Created: @{[strftime TIME_FMT, localtime $ctime]}
eod
	next;
	};
    $opt{verbose} and print <<eod;
$fn
eod
    SetFileTime ($fn, $atime, $mtime, $ctime) or warn <<eod;
touch: $fn $^E
eod
    }

    
