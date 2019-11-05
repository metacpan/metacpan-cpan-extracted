package main;

use strict;
use warnings;

# local $^W = 0;

use File::Temp;
use Test::More 0.88;	# for done_testing.

use lib qw{ inc };

use My::Module::Test qw{ :all };
use Win32API::File::Time qw{ :all };	# Must be loaded after My::Module::Test

use constant REACT_OS	=> 'MSWin32' eq $^O && (
    $ENV{OS} =~m/ reactos /smxi ||
    defined $ENV{SystemRoot} && $ENV{SystemRoot} =~ m/ reactos /smxi ||
    defined $ENV{windir} && $ENV{windir} =~ m/ reactos /smxi ||
    defined $ENV{SystemDrive} && -e "$ENV{SystemDrive}/ReactOS"
);

my $me = $0;
my ( undef, undef, undef, undef, undef, undef, undef, undef,
    $patim, $pmtim, $pctim, undef, undef ) = stat $me
    or BAIL_OUT "Failed to stat $me: $!";
note spftime( "$me via stat()", $patim, $pmtim, $pctim );

# The set_up_trace and check_trace calls are an attempt to be able to do
# a meaningful test under some OS other than Windows. If maintenance
# ever goes to a Windows machine, these can be stripped out, since there
# will be no reason to run the tests under a non-Windows system.
set_up_trace;
my ( $atime, $mtime, $ctime ) = GetFileTime( $me );
check_trace [
    [
	"CreateFile",
	"t/file.t",
	128,
	1,
	[],
	3,
	33554432,
	0
    ],
    [
	"GetFileTime",
	"t/file.t",
	"\0\0\0\0\0\0\0\0",
	"\0\0\0\0\0\0\0\0",
	"\0\0\0\0\0\0\0\0"
    ],
    [
	"CloseHandle",
	"t/file.t"
    ],
    [
	"FileTimeToLocalFileTime",
	get_atime $me,
	get_atime $me,
    ],
    [
	"FileTimeToSystemTime",
	get_atime $me,
	"\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
    ],
    [
	"FileTimeToLocalFileTime",
	get_mtime $me,
	get_mtime $me,
    ],
    [
	"FileTimeToSystemTime",
	get_mtime $me,
	get_sys_atime $me,	# Because of GetFileTime internals
    ],
    [
	"FileTimeToLocalFileTime",
	get_ctime $me,
	get_ctime $me,
    ],
    [
	"FileTimeToSystemTime",
	get_ctime $me,
	get_sys_mtime $me,	# Because of GetFileTime internals
    ]
], 'GetFileTime KERNEL32 calls';
note spftime( "$me via GetFileTime()", $atime, $mtime, $ctime );

cmp_ok $mtime, '==', $pmtim, 'Got same modification time as stat()'
    or diag <<"EOD";
GetFileTime: @{[ scalar localtime $mtime ]}
       stat: @{[ scalar localtime $pmtim ]}
EOD

if ( REACT_OS ) {
    note 'Creation time not checked under ReactOS';
} elsif ( ! $pctim ) {
    note 'Creation time not checked because stat() returned 0';
} else {
    cmp_ok $ctime, '==', $pctim, 'Got same creation time as stat()'
	or diag <<"EOD";
GetFileTime: @{[ scalar localtime $ctime ]}
       stat: @{[ scalar localtime $pctim ]}
EOD
}

my $temp = File::Temp->new();
my $temp_name = $temp->filename();
my $now = time;
$now -= $now % 2;	# FAT's time resolution is 2 seconds.
CORE::utime $now, $now, $temp_name
    or BAIL_OUT "utime() on $temp_name failed: $!";

( undef, undef, undef, undef, undef, undef, undef, undef,
    $patim, $pmtim, $pctim ) = stat $temp_name;
note spftime( "$temp_name before SetFileTime()", $patim, $pmtim, $pctim );

my $want = $now + 10;
set_up_trace;
SetFileTime( $temp_name, $want, $want );
check_trace [
    [
	"SystemTimeToFileTime",
	sys_time $want,
	"\0\0\0\0\0\0\0\0"
    ],
    [
	"LocalFileTimeToFileTime",
	file_time $want,
	"\0\0\0\0\0\0\0\0"
    ],
    [
	"SystemTimeToFileTime",
	sys_time $want,
	"\0\0\0\0\0\0\0\0"
    ],
    [
	"LocalFileTimeToFileTime",
	file_time $want,
	"\0\0\0\0\0\0\0\0"
    ],
    [
	"CreateFile",
	$temp_name,
	256,
	3,
	[],
	3,
	33554560,
	0
    ],
    [
	"SetFileTime",
	$temp_name,
	"\0\0\0\0\0\0\0\0",
	file_time $want,
	file_time $want,
    ],
    [
	"CloseHandle",
	$temp_name,
    ]
], 'SetFileTime KERNEL32 calls';
( undef, undef, undef, undef, undef, undef, undef, undef,
    $patim, $pmtim, $pctim ) = stat $temp_name;
note spftime( "$temp_name after SetFileTime()", $patim, $pmtim, $pctim );

cmp_ok $want, '==', $pmtim, 'Set modification time with SetFileTime()'
    or diag <<"EOD";
SetFileTime: @{[ scalar localtime $want ]}
       stat: @{[ scalar localtime $pmtim ]}
EOD

$want += 10;
set_up_trace;
utime( $want, $want, $temp_name );
check_trace [
    [
	"SystemTimeToFileTime",
	sys_time $want,
	"\0\0\0\0\0\0\0\0"
    ],
    [
	"LocalFileTimeToFileTime",
	file_time $want,
	"\0\0\0\0\0\0\0\0"
    ],
    [
	"SystemTimeToFileTime",
	sys_time $want,
	"\0\0\0\0\0\0\0\0"
    ],
    [
	"LocalFileTimeToFileTime",
	file_time $want,
	"\0\0\0\0\0\0\0\0"
    ],
    [
	"CreateFile",
	$temp_name,
	256,
	3,
	[],
	3,
	33554560,
	0
    ],
    [
	"SetFileTime",
	$temp_name,
	"\0\0\0\0\0\0\0\0",
	file_time $want,
	file_time $want,
    ],
    [
	"CloseHandle",
	$temp_name,
    ]
], 'utime KERNEL32 calls';
( undef, undef, undef, undef, undef, undef, undef, undef,
    $patim, $pmtim, $pctim ) = stat $temp_name;
note spftime( "$temp_name after utime()", $patim, $pmtim, $pctim );

cmp_ok $want, '==', $pmtim, 'Set modification time with utime()'
    or diag <<"EOD";
utime: @{[ scalar localtime $want ]}
 stat: @{[ scalar localtime $pmtim ]}
EOD


done_testing;

sub spftime {
    my ( $fn, $sat, $smt, $sct ) = @_;
    ( $sat, $smt, $sct ) = map { scalar localtime $_ } $sat, $smt, $sct;
    return <<"EOD";
$fn;
Accessed: $sat
Modified: $smt
 Created: $sct
EOD
}

1;

# ex: set textwidth=72 :
