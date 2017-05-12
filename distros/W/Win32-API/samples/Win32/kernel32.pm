# $Id$

package Win32::kernel32;
use Win32::API;

$VERSION = '0.50';

%APIs = (
    Beep => [[N, N], N],
    CopyFile       => [[P, P,  N], N],
    GetBinaryType  => [[P, P], N],
    GetCommandLine => [[], P],
    GetCompressedFileSize => [[P, P], N],
    GetCurrencyFormat => [[N,  N, P, P, P,  N], N],
    GetDiskFreeSpace  => [[P,  P, P, P, P], N],
    GetDriveType      => [[P], N],
    GetSystemTime     => [[P], V],
    GetTempPath => [[N, P], N],
    GetVolumeInformation      => [[P,  P, N,  P, P, P,  P, N], N],
    MultiByteToWideChar       => [[N,  N, P,  N, P, N], N],
    QueryDosDevice            => [[P,  P, N], N],
    QueryPerformanceCounter   => [[P], N],
    QueryPerformanceFrequency => [[P], N],
    SearchPath   => [[P,  P, P, N, P, P], N],
    SetLastError => [[N], V],
    Sleep        => [[N], V],
    VerLanguageName => [[N, P, N], N],
    WideCharToMultiByte => [[N, N, P, N, P, N, P, P], N],
);

%SUBs = (
    Beep => sub {
        my ($freq, $duration) = @_;
        return $Win32::kernel32::Beep->Call($freq, $duration);
    },
    CopyFile => sub {
        my ($old, $new, $flag) = @_;
        $flag = 1 unless defined($flag);
        return $Win32::kernel32::CopyFile->Call($old, $new, $flag);
    },
    GetBinaryType => sub {
        warn "The Win32::GetBinaryType API works only on Windows NT"
            unless Win32::IsWinNT();
        my ($appname) = @_;
        my $type = pack("L", 0);
        my $result = $Win32::kernel32::GetBinaryType->Call($appname, $type);
        return ($result) ? unpack("L", $type) : undef;
    },
    GetCompressedFileSize => sub {
        warn "The Win32::GetCompressedFileSize API works only on Windows NT"
            unless Win32::IsWinNT();
        my ($filename) = @_;
        my $hiword = pack("L", 0);
        my $loword = $Win32::kernel32::GetCompressedFileSize->Call($filename, $hiword);
        return $loword + $hiword * 4 * 1024**3;
    },
    GetCommandLine => sub {
        my $cmdline = $Win32::kernel32::GetCommandLine->Call();
        my $string = pack("a1024", $cmdline);
        $string =~ s/\0*$//;
        return $string;
    },
    GetCurrencyFormat => sub {
        my ($number, $locale) = @_;
        $locale = 2048 unless defined($locale);
        my $output = "\0" x 1024;
        my $result =
            $Win32::kernel32::GetCurrencyFormat->Call($locale, 0, $number, 0, $output,
            1024,);
        if ($result) {
            return substr($output, 0, $result - 1);
        }
        else {
            return undef;
        }
    },
    GetDiskFreeSpace => sub {
        my ($root) = @_;
        $root = 0 unless defined($root);
        my $SectorsPerCluster = pack("L", 0);
        my $BytesPerSector    = pack("L", 0);
        my $FreeClusters      = pack("L", 0);
        my $TotalClusters     = pack("L", 0);
        my $result =
            $Win32::kernel32::GetDiskFreeSpace->Call($root, $SectorsPerCluster,
            $BytesPerSector, $FreeClusters, $TotalClusters,);
        if ($result) {
            $SectorsPerCluster = unpack("L", $SectorsPerCluster);
            $BytesPerSector    = unpack("L", $BytesPerSector);
            $FreeClusters      = unpack("L", $FreeClusters);
            $TotalClusters     = unpack("L", $TotalClusters);
            return wantarray
                ? (
                $BytesPerSector * $SectorsPerCluster * $FreeClusters,
                $BytesPerSector * $SectorsPerCluster * $TotalClusters,
                )
                : $BytesPerSector * $SectorsPerCluster * $FreeClusters;
        }
        else {
            return undef;
        }
    },
    GetDriveType => sub {
        my ($root) = @_;
        $root = 0 unless defined($root);
        return $Win32::kernel32::GetDriveType->Call($root);
    },
    GetSystemTime => sub {
        my $SYSTEMTIME = pack("SSSSSSSS", 0, 0, 0, 0, 0, 0, 0, 0);
        $Win32::kernel32::GetSystemTime->Call($SYSTEMTIME);
        return wantarray ? unpack("SSSSSSSS", $SYSTEMTIME) : $SYSTEMTIME;
    },
    GetTempPath => sub {
        my $string = " " x 256;
        my $result = $Win32::kernel32::GetTempPath->Call(256, $string);
        return substr($string, 0, $result) if $result;
        return undef;
    },
    GetVolumeInformation => sub {
        my ($root) = @_;
        $root = 0 unless defined($root);
        my $name   = "\0" x 256;
        my $serial = pack("L", 0);
        my $maxlen = pack("L", 0);
        my $flags  = pack("L", 0);
        my $fstype = "\0" x 256;
        my $result =
            $Win32::kernel32::GetVolumeInformation->Call($root, $name, 256, $serial,
            $maxlen, $flags, $fstype, 256,);

        if ($result) {
            $name   =~ s/\0*$//;
            $fstype =~ s/\0*$//;
            return wantarray
                ? (
                $name,
                unpack("L", $serial),
                unpack("L", $maxlen),
                unpack("L", $flags), $fstype,
                )
                : $name;
        }
        else {
            return undef;
        }
    },
    MultiByteToWideChar => sub {
        my ($string, $codepage) = @_;
        $codepage = 0 unless defined($codepage);
        my $result =
            $Win32::kernel32::MultiByteToWideChar->Call($codepage, 0, $string,
            length($string), 0, 0,);
        return undef unless $result;
        my $ustring = " " x ($result * 2);
        $result =
            $Win32::kernel32::MultiByteToWideChar->Call($codepage, 0, $string,
            length($string), $ustring, $result,);
        return undef unless $result;
        return $ustring;
    },
    QueryDosDevice => sub {
        warn "The Win32::QueryDosDevice API works only on Windows NT"
            unless Win32::IsWinNT();
        my ($name) = @_;
        $name = 0 unless defined($name);
        my $path = "\0" x 1024;
        my $result = $Win32::kernel32::QueryDosDevice->Call($name, $path, 1024);
        if ($result) {
            return wantarray
                ? split(/\0/, $path)
                : join(";", split(/\0/, $path));
        }
        else {
            return undef;
        }
    },
    QueryPerformanceCounter => sub {
        my $count = pack("b64", 0);
        if ($Win32::kernel32::QueryPerformanceCounter->Call($count)) {
            my ($clo, $chi) = unpack("ll", $count);
            return $clo + $chi * 4 * 1024**3;
        }
        else {
            return undef;
        }
    },
    QueryPerformanceFrequency => sub {
        my $freq = pack("b64", 0);
        if ($Win32::kernel32::QueryPerformanceFrequency->Call($freq)) {
            my ($flo, $fhi) = unpack("ll", $freq);
            return $flo + $fhi * 4 * 1024**3;
        }
        else {
            return undef;
        }
    },
    SearchPath => sub {
        my ($name, $ext) = @_;
        $ext = 0 unless defined($ext);
        my $path = "\0" x 1024;
        my $pext = pack("L", 0);
        my $result =
            $Win32::kernel32::SearchPath->Call(0, $name, $extension, 1024, $path, $pext,);
        if ($result) {
            $path =~ s/\0*$//;
            return $path;
        }
        else {
            return undef;
        }
    },
    SetLastError => sub {
        $Win32::kernel32::SetLastError->Call($_[0]) if $_[0];
    },
    Sleep => sub {
        $Win32::kernel32::Sleep->Call($_[0]) if $_[0];
    },
    VerLanguageName => sub {
        my ($lang) = @_;
        if ($lang) {
            my $langdesc = "\0" x 256;
            my $result = $Win32::kernel32::VerLanguageName->Call($lang, $langdesc, 256);
            if ($result > 0 and $result < 256) {
                return substr($langdesc, 0, $result);
            }
            else {
                return 0;
            }
        }
    },
    WideCharToMultiByte => sub {
        my ($ustring, $codepage) = @_;
        $codepage = 0 unless defined($codepage);
        my $result =
            $Win32::kernel32::WideCharToMultiByte->Call($codepage, 0, $ustring, -1, 0, 0,
            0, 0,);
        return undef unless $result;
        my $string = " " x $result;
        $result =
            $Win32::kernel32::WideCharToMultiByte->Call($codepage, 0, $ustring, -1,
            $string, $result, 0, 0,);

        # $string =~ s/\0.*$//;
        return undef unless $result;
        return $string;
    },
);

sub import {
    my $self = shift;
    @apis = @_;
    @apis = keys %APIs unless @apis;
    foreach $api (@apis) {
        import_API($api);
    }
}

sub import_API {
    my ($function) = @_;
    my $params;
    if (exists($APIs{$function})) {
        $params = $APIs{$function};
    }
    else {
        $params = [[], V];
        warn "Unknown API: $function";
    }
    $$function = new Win32::API("kernel32", $function, @$params);
    warn "Win32::kernel32 failed to import API $function from KERNEL32.DLL"
        unless $$function;
    *{'Win32::' . $function} = $SUBs{$function};
}

1;
__END__

=head1 NAME

Win32::kernel32 - Experimental interface to some of the KERNEL32.DLL functions

=head1 SYNOPSIS

  use Win32::kernel32;

  # or

  use Win32::kernel32 qw( Sleep CopyFile GetVolumeInformation );


=head1 FUNCTIONS

=head4 Beep

Syntax:

    Win32::Beep ( [FREQUENCY, DURATION] )

Plays a simple tone on the speaker; C<FREQUENCY> is expressed
in hertz and ranges from 37 to 32767, C<DURATION> is expressed
in milliseconds.
Note that parameters are relevant only on Windows NT; on
Windows 95, parameters are ignored and the system plays the
default sound event (or a standard system beep on the speaker 
if you have no sound card).

Example:

    Win32::Beep(440, 1000);


=head4 CopyFile

Syntax:

    Win32::CopyFile ( SOURCE, TARGET, [SAFE] )

Copies the C<SOURCE> file to C<TARGET>. By default, it fails
if C<TARGET> already exists; to overwrite the already
existing file, the C<SAFE> flag must be set to 0.
Returns a true value if the operation was successfull,
a false one if it failed.

Example:

    if(Win32::CopyFile($from, $to)) {
        print "Copy OK.\n";
    } else {
        # overwrite the already existing file
        if(Win32::CopyFile($from, $to, 0)) {
            print "Copy OK, file replaced.\n";
        } else {
            print "Copy failed.\n";
        }
    }


=head4 GetBinaryType

Syntax:

    Win32::GetBinaryType ( FILENAME )

Returns the type ot the executable file C<FILENAME>.
Possible values are:

    0   A Win32 based application
    1   An MS-DOS based application
    2   A 16-bit Windows based application
    3   A PIF file that executes an MS-DOS based application
    4   A POSIX based application
    5   A 16-bit OS/2 based application

If the function fails, C<undef> is returned.

B<Note>: this function is available on Windows NT only.

Example:

    print "Notepad is a type ", Win32::GetBinaryType("c:\\winnt\\notepad.exe"), "\n";


=head4 GetCompressedFileSize

Syntax:

    Win32::GetCompressedFileSize ( FILENAME )

Returns the compressed size of the specified C<FILENAME>,
if the file is compressed; if it's not compressed, it
returns the normal file size (eg. same as C<-s>).

B<Note>: this function is available on Windows NT only.


Example:

    print Win32::GetCompressedFileSize("c:\\documents\\longlog.txt");


=head4 GetCommandLine

Syntax:

    Win32::GetCommandLine ( )

Returns the complete command line string, including the 
full path to the program name and its arguments.

Example:

    print Win32::GetCommandLine();


=head4 GetCurrencyFormat

Syntax:

    Win32::GetCurrencyFormat ( NUMBER, [LOCALE] )

Returns C<NUMBER> formatted to your locale's currency settings.
You can optionally supply a different C<LOCALE> for foreign currencies.

Example:

    print "You owe me ", Win32::GetCurrencyFormat(rand()*10000), "\n";

    # ten millions italian lires...
    $LotOfMoney = Win32::GetCurrencyFormat(10000000, 1040);

    # 1040 is "Italian (Standard)" (see also VerLanguageName)
    # and it returns: L. 10.000.000


=head4 GetDiskFreeSpace

Syntax:

    Win32::GetDiskFreeSpace ( [ROOT] )

Returns the amount of free disk space on the drive indicated by C<ROOT>;
if this is omitted, uses the current drive.
To specify a drive, you must provide the exact root directory
(eg. for drive C: it must be: "C:\").
In a scalar context, it returns the number of free bytes;
in a list context, it returns the number of free bytes and
the total number of bytes on the disk.

Example:

    $free = Win32::GetDiskFreeSpace("c:\\");
    ($free, $total) = Win32::GetDiskFreeSpace();


=head4 GetDriveType

Syntax:

    Win32::GetDriveType ( [ROOT] )

Returns the type ot the drive indicated by C<ROOT>.
If this is omitted, uses the current drive.
To specify a drive, you must provide the exact root directory
(eg. for drive C: it must be: "C:\").
Possible return values are:

    0   The drive type cannot be determined
    1   The root directory does not exist
    2   The disk can be removed from the drive
    3   The disk cannot be removed from the drive
    4   The drive is a remote (network) drive
    5   The drive is a CD-ROM drive
    6   The drive is a RAM disk

Example:

    print "C: is a type ", Win32::GetDriveType("c:\\"), "\n";


=head4 GetTempPath

Syntax:

    Win32::GetTempPath ( )

Returns the path of the directory designated for temporary
files, or C<undef> on errors.

Example:

    print "Please put your temp files in ", Win32::GetTempPath(), "\n";


=head4 GetVolumeInformation

Syntax:

    Win32::GetVolumeInformation ( [ROOT] )

Returns a 5-elements array with some information about the 
drive indicated by C<ROOT>.
If this is omitted, uses the current drive.
Typically used as follows:

    ($label, $serial, $maxlen, $flags, $fstype) = Win32::GetVolumeInformation();

Here are the meaning of the fields:

    label   the volume label
    serial  the volume serial number
    maxlen  the maximum filename length, in chars, supported by the volume
    flags   a set of flags associated with the file system
    fstype  the type of the file system (such as FAT or NTFS)

For more information about the C<flags> field, please refer
to the GetVolumeInformation() documentation in the Microsoft 
Win32 SDK Reference.

If called in a scalar context, the function returns only the
first element (the volume label).

Example:

    $volume = Win32::GetVolumeInformation();
    print "Working on $volume...";


=head4 MultiByteToWideChar

Syntax:

    Win32::MultiByteToWideChar ( STRING, [CODEPAGE] )

Converts a C<STRING> in Unicode format. The additional
C<CODEPAGE> parameter can have one of this values:

    0   ANSI codepage
    1   OEM codepage
    2   MAC codepage

Or the number of a codepage installed on your system (eg. 850 
for "MS-DOS Multilingual (Latin I)"). The default, if none
specified, is the ANSI codepage. Returns the converted string
or C<undef> on errors.

Example:

    $UnicodeString = Win32::MultiByteToWideChar($string);


=head4 QueryPerformanceCounter

Syntax:

    Win32::QueryPerformanceCounter ( )

Retrieves the current value of the high-resolution performance 
counter, if it exists. Returns zero if it doesn't.
To see how many times per second the counter is incremented,
use QueryPerformanceFrequency().

Example:

    $freq = Win32::QueryPerformanceFrequency();
    $count1 = Win32::QueryPerformanceCounter();
    # do something
    $count2 = Win32::QueryPerformanceCounter();
    print ($count2-$count1)/$freq , " seconds elapsed.\n";


=head4 QueryPerformanceFrequency

Syntax:

    Win32::QueryPerformanceFrequency ( )

Returns the frequency of the high-resolution performance 
counter, if it exists. Returns zero if it doesn't.
See also C<QueryPerformanceCounter>.


=head4 SearchPath

Syntax:

    Win32::SearchPath ( FILENAME )

Search for the specified C<FILENAME> in the path.
The following directories are searched:

    1. the directory from which the application loaded.
    2. the current directory
    3. the Windows system directory
    4. the Windows directory
    5. the directories in the PATH environment variable

Returns the full path to the found file or C<undef>
if the file was not found.

Example:

    print "Notepad exists" if -f Win32::SearchPath("notepad.exe");


=head4 SetLastError

Syntax:

    Win32::SetLastError ( VALUE )

Sets the Win32 last error to the specified C<VALUE>.

Example:

    # reset pending errors
    Win32::SetLastError(0);


=head4 Sleep

Syntax:

    Win32::Sleep ( MILLISECONDS )

Sleeps for the number of C<MILLISECONDS> specified.

Example:

    # sleep for 1/2 second
    Win32::Sleep(500);


=head4 VerLanguageName

Syntax:

    Win32::VerLanguageName ( LOCALE )

Returns a descriptive string for the language associated with the
specified C<LOCALE>.

Example:

    $ITA = Win32::VerLanguageName(1040);
    $JAP = Win32::VerLanguageName(1041);


=head4 WideCharToMultiByte

Syntax:

    Win32::WideCharToMultiByte ( STRING, [CODEPAGE] )

Converts an Unicode C<STRING> to a non-Unicode one. The additional
C<CODEPAGE> parameter can have one of this values:

    0   ANSI codepage
    1   OEM codepage
    2   MAC codepage

Or the number of a codepage installed on your system (eg. 850 
for "MS-DOS Multilingual (Latin I)"). The default, if none
specified, is the ANSI codepage. Returns the converted string
or C<undef> on errors.

Example:

    $string = Win32::WideCharToMultiByte($UnicodeString);



=head4 Yet to be documented

    GetSystemTime        => [[P], V],
    QueryDosDevice       => [[P, P, N], N],


=head1 AUTHOR

Aldo Calpini ( I<dada@perl.it> ).

=head1 MAINTAINER

Cosimo Streppone, <cosimo@cpan.org>

=cut

