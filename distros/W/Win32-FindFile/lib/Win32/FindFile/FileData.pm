package Win32::FileFind::FileData;
use strict;

=pod

=head1 NAME

Win32::FileFind::FileData - A info about file

=head1 DESCRIPTION

    This module is internal and contains all data returned by Win32 function FindFirstFile

=head1 SYNOPSYS

    for my $file ( FindFile( './*' )){
	next unless $file->is_entry # skip over '.', '..'
	next if $file->is_hidden; # skip over hidden files
	next if $file->is_system; # etc
	next if $file->is_directory;

	next if $file->ftCreationTime   > time -10; # skip over files created recently
	next if $file->ftLastWriteTime  > time -10; # or $file->mtime
	next if $file->ftLastAccessTime > time -10; # or $file->atime

	my $mtime = $file->mtime->as_double + 1;

	next if $file->FileSize == 0; # 

	print $file, "\n"; # $file->cFileName
	
	print $file->dosName, "\n";

	my $s = $file->dwFileAttributes; # Get all attribytes
    }

=head1 Attributes

=over 4

=item $relName = $fd->relName( $dirname, $path_delimiter )

=item $bool = $fd->is_temporary

    This is a convinience function what test what dwFileAttributes has FILE_FILE_ATTRIBUTE_TEMPORARY bit set.

=item $bool = $fd->is_entry

    boolean function that is false for filename equal '.' and '..', otherwise return true.

=item $bool = $fd->is_ro

    boolean value that file has readonly or hidden attribute

=item $bool = $fd->is_archive

    file has archive bit set

=item $bool = is_compressed
=item $bool = is_device
=item $bool = is_directory same as is_dir 
=item $bool = is_dir
=item $bool = is_file
=item $bool = is_encrypted
=item $bool = is_hidden
=item $bool = is_normal
=item $bool = is_not_indexed
=item $bool = is_not_content_indexed
=item $bool = is_offline
=item $bool = is_readonly
=item $bool = is_reparse_point
=item $bool = is_sparse
=item $bool = is_system


=back

    All these properties name by its corresponding attribute

=head1 PROPERTIES

=over 4

=item $dword = $fd->dwFileAttributes

    return all FileAttributes in one unsinged integer

=item $name   = $fd->cFileName or fileName or name

    return utf8 name of file ( not set utf8 flag MAY CHANGE)

=item $dosName = $fd->dosName

    return old 8.3 name if file name is long

=item $filesize = FileSize 

    File size

=item $time = $fd->ftCreationTime, ftLastWriteTime, ftLastAccessTime

    File's timestamps

=item nFileSizeHigh, nFileSizeLow, dwReserved0,  dwReserved1

    File Raw data

=back
