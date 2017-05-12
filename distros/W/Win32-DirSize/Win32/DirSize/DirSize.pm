
	##################################################################
	##################################################################
	##
	## Win32::DirSize
	## version 1.13
	##
	## by Adam Rich <arich@cpan.org>
	##
	## 05/02/2005
	##
	##################################################################
	##################################################################

package Win32::DirSize;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

use constant DS_RESULT_OK			=> 0;
use constant DS_ERR_INVALID_DIR		=> 1;
use constant DS_ERR_OUT_OF_MEM		=> 2;
use constant DS_ERR_ACCESS_DENIED	=> 3;
use constant DS_ERR_OTHER			=> 4;

our %EXPORT_TAGS = ();
our @EXPORT_OK = qw(
	DS_ERR_ACCESS_DENIED
	DS_ERR_INVALID_DIR
	DS_ERR_OTHER
	DS_ERR_OUT_OF_MEM
	DS_RESULT_OK
	dir_size
	best_convert
	size_convert
	disk_space
);
our @EXPORT = qw(
	DS_ERR_ACCESS_DENIED
	DS_ERR_INVALID_DIR
	DS_ERR_OTHER
	DS_ERR_OUT_OF_MEM
	DS_RESULT_OK
	dir_size
	best_convert
	size_convert
	disk_space
);
our $VERSION = '1.13';

bootstrap Win32::DirSize $VERSION;

1;
__END__

=head1 NAME

Win32::DirSize - Calculate sizes of directories on Win32

=head1 SYNOPSIS

 use strict;  
 use Win32::DirSize;
 
 my $Result = dir_size(
   "C:\\TEMP",
   my $DirInfo, # this stores the directory information
 );
 
 if ($Result == DS_RESULT_OK) {
   print "Files Found = $DirInfo->{FileCount} \n";
   print "Dirs Found = $DirInfo->{DirCount} \n";
   print "Dir size = $DirInfo->{DirSize} bytes \n";
   print "Dir size on disk = $DirInfo->{DirSizeOnDisk} bytes \n";

   # If you don't want to display results in bytes,
   # let the module determine the best unit.
   
   my $Size = best_convert(
     my $SizeUnit, 
     $DirInfo->{HighSize}, 
     $DirInfo->{LowSize},
   );
   print "Dir size = $Size $SizeUnit \n";

   my $SizeOnDisk = best_convert(
     my $SizeOnDiskUnit, 
     $DirInfo->{HighSizeOnDisk}, 
     $DirInfo->{LowSizeOnDisk},
   );
   print "Dir size on disk = $SizeOnDisk $SizeOnDiskUnit \n";
 }

 # display any errors
 if (@{$DirInfo->{Errors}}) {
  foreach my $Error (@{$DirInfo->{Errors}}) {
    printf(
 	 "Error #%d at %s\n",
 	 $Error->{ErrCode},
 	 $Error->{Location},
    );
  }
 }

 my $Result = disk_space(
   "C:",
   my $DiskInfo, # this stores the disk information
 );

 if ($Result == DS_RESULT_OK) {
   print "Disk Size = $DiskInfo->{TotalBytes} bytes \n";
   print "Disk Free = $DiskInfo->{FreeBytes} bytes \n";
   print "Quota Free = $DiskInfo->{QuotaBytes} bytes \n";

   # Again, you can convert to human-readable size.
   my $DiskDize = best_convert(
     my $DiskSizeUnit, 
     $DiskInfo->{HighTotalBytes}, 
     $DiskInfo->{LowTotalBytes},
   );
   my $DiskFree = best_convert(
     my $DiskFreeUnit, 
     $DiskInfo->{HighFreeBytes}, 
     $DiskInfo->{LowFreeBytes},
   );
   my $QuotaFree = best_convert(
     my $QuotaFreeUnit, 
     $DiskInfo->{HighQuotaBytes}, 
     $DiskInfo->{LowQuotaBytes},
   );

   print "Disk Size = $DiskDize $DiskSizeUnit \n";
   print "Disk Free = $DiskFree $DiskFreeUnit \n";
   print "Quota Free = $QuotaFree $QuotaFreeUnit \n";
 }

=head1 DESCRIPTION

Win32::DirSize will calculate the total size used by any directory on your Win32 
file system.  It can also give you the total count of files or directories under 
that directory.  Informal benchmarks suggest this version of Win32::DirSize to 
be up to 50x faster than using File::Find. (See the dir_size() function)

Win32::DirSize can also provide the size of an entire disk, the amount of free 
space on that disk, and the amount of quota space available if quotas are 
enabled.  (See the disk_space() function)

Since drive and directory sizes on Win32 systems can easily reach the 
multi-terabyte range and beyond, and the result perl can store in a single 
32-bit integer is 3.999 GB, it's not possible to return an accurate result in 
a single variable.  So, the Win32 API and this module return the result in two 
separate values representing the least and most significant 32 bits.  This 
module also provides the result as a string value, suitable for printing and use 
with Math::BigInt.  Be aware that doing any math on the string value will 
convert it to a floating point value internally and you will lose precision.

Two convenience functions are provided to help convert the raw byte-sizes into 
more human-readable form: size_convert() and best_convert().  These functions 
take as input the two 32-bit integers making up the upper and lower 32 bits of 
the 64-bit size value and use floating point math to convert the value to 
another unit (some precision lost).

=head2 Function definitions

=over

=item dir_size(dirname, dirinfo [, permsdie [, othersdie]])

dir_size() will take the name of a directory, and a scalar variable, and attempt 
to determine the size, filecount, and directory count of the directory you 
specified.  It puts this information into the scalar variable you provided in 
the form of a hashref.  

The hashref will contain 9 keys: 

=over

=item DirSize

This is a string value representing the directory size in bytes.  This should be 
suitable for printing and use with Math::BigInt.  Be aware that doing any math 
on the string value will convert it to a floating point value internally and you 
will lose precision.

=item HighSize

This is an integer value containing the most significant 32 bits of the 
directory size.

=item LowSize

This is an integer value containing the least significant 32 bits of the 
directory size.

=item DirSizeOnDisk

This is a string value representing the actual amount of storage the directory 
takes up on disk, in bytes.  The cluster size of the file system is used to 
calculate this value, and compressed files and sparse files should be recorded 
accurately.  No attempt is made to handle hard links, reparse points, or named 
streams.

=item HighSizeOnDisk

This is an integer value containing the most significant 32 bits of the actual 
directory size on disk, as described above.

=item LowSizeOnDisk

This is an integer value containing the least significant 32 bits of the actual 
directory size on disk, as described above.

=item FileCount

This is an integer value containing the count of the files found beneath the 
directory you specified.

=item DirCount

This is an integer value containing the count of the subdirectories found 
beneath the directory you specified.

=item Errors

This is a reference to an array containing hashes, explained in more detail 
below.

=back

Sometimes, while recursing through a directory, dir_size() may encounter a 
directory or file that it can't access.  The most common reasons for this are 
that you lack sufficient permissions to open that directory, or that a file is 
locked in exclusive mode and cannot be analyzed (eg, a pagefile).  If you'd 
prefer dir_size() quit immediately when this happens, specify 1 for the 
"permsdie" parameter.  The default is to ignore the error and continue.  Other 
types of errors besides "access denied" are rare, but they can happen.  Specify 
1 for the "othersdie" parameter if you'd like to quit for other types of errors 
as well.  The default is to ignore them.

When it's finished, dir_size() will return an integer value indicating the 
status of the operation. If no errors were encountered, the result will be 
DS_RESULT_OK.  If you specified a 1 for "permsdie" and dir_size encountered a 
directory it had no rights to, the result will be DS_ERR_ACCESS_DENIED. And 
similarly, if you specified 1 for "othersdie" and a different type of 
file/directory error was encountered, the result will be DS_ERR_OTHER.  There 
are 2 other types of status you may see: DS_ERR_INVALID_DIR means the directory 
was an invalid format, and DS_ERR_OUT_OF_MEM means that a memory allocation 
failed.

Regardless of what values you specified for "permsdie" and "othersdie", any 
file/directory errors encountered during the operation are recorded in a list of 
hashes referenced in the "Errors" key of the dirinfo hashref.  Each hash will 
contain two keys: 'ErrCode' for the operating system's error code value, and 
'Location' for the name of the directory or file where the error was 
encountered.

=item disk_space(dirname, dirinfo)

disk_space() is used to calculate the total size and free space of a disk in 
bytes.  You should pass in the name of a drive and a scalar variable, and 
disk_space() will set that scalar variable to a hashref, similar to what 
dir_size() does.  If you pass in a full directory or UNC path, disk_space() will 
report statistics for the directory that path is located on.  disk_space() will 
return either DS_RESULT_OK or DS_ERR_OTHER.  

The hashref will contain 9 keys: 

=over

=item TotalBytes

This is a string value representing the total size of the disk, in bytes. This 
should be suitable for printing and use with Math::BigInt.  Be aware that doing 
any math on the string value will convert it to a floating point value 
internally and you will lose precision.

=item HighTotalBytes

This is an integer value containing the most significant 32 bits of the total 
disk size in bytes.

=item LowTotalBytes

This is an integer value containing the least significant 32 bits of the total 
disk size in bytes.

=item FreeBytes

This is a string value representing the free size of the disk, in bytes.  Note 
that if quotas are enabled, the user may not have access to the entire amount of 
this storage (see QuotaBytes below, instead).  This should be suitable for 
printing and use with Math::BigInt.  Be aware that doing any math on the string 
value will convert it to a floating point value internally and you will lose 
precision.

=item HighFreeBytes

This is an integer value containing the most significant 32 bits of the free 
disk size in bytes.

=item LowFreeBytes

This is an integer value containing the least significant 32 bits of the free 
disk size in bytes.

=item QuotaBytes

This is a string value representing the amount of free space in bytes that the 
user has access to, under the current quota setting.  If quotas are not enabled, 
this value will be identical to the 'FreeBytes' value.  This should be suitable 
for printing and use with Math::BigInt.  Be aware that doing any math on the 
string value will convert it to a floating point value internally and you will 
lose precision.

=item HighQuotaBytes

This is an integer value containing the most significant 32 bits of the 
available quota in bytes.

=item LowQuotaBytes

This is an integer value containing the least significant 32 bits of the 
available quota in bytes.

=back

The High/Low values returned by disk_space() can be used with best_convert() and 
size_convert() to convert them to a human-readable unit.

=item best_convert(unit, highsize, lowsize)

best_convert() is used to convert a size in bytes calculated by dir_size() or 
disk_space() into the best printable format automatically.  The variable you 
passed in for the "unit" parameter is set to the unit chosen.  The result is 
returned in a floating point format. (some precision lost)

=item size_convert(unit, highsize, lowsize)

size_convert() can be used to convert the directory size in bytes calculated by 
dir_size() or disk_space() into another unit.  The units to choose from include 
k, M, G, T, P, E for kibibytes, mebibytes, gibibytes, tebibytes, pebibytes, and 
exbibytes respectively.  If you provide an invalid unit, this function will 
return -1 to indicate an error.  

=back

=head2 

=head2 EXPORT

	Functions: dir_size() best_convert() size_convert() disk_space() 
	Constants: DS_ERR_ACCESS_DENIED DS_ERR_INVALID_DIR DS_ERR_OTHER 
		DS_ERR_OUT_OF_MEM DS_RESULT_OK

=head1 AUTHOR

Adam Rich (arich@cpan.org)

=cut
