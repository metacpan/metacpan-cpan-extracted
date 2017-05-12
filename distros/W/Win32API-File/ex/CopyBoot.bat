@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!/usr/bin/perl -w
#line 14


use strict;

use Win32API::File 0.04 qw(
    createFile
    fileLastError
    ReadFile
    SetFilePointer
    WriteFile
    CloseHandle
    GetDriveType DRIVE_REMOVABLE DRIVE_FIXED
);

# Get the stripped-down name of this script for use in error messages:
my $Self= $0;
$Self =~ s#^.*[/\\]([^/\\]+)[.][^./\\]*$#$1#;

# Whether to simply overwrite entire boot sector of hard disk:
my $WriteEntire= 0;

exit main();


{
    # Here is a fun way to deal with packed data structures in Perl!
    package Sector0;

    use vars qw( $fmtSect0 @fldSect0 %fldSect0 );
    use vars qw( $fmtFatParams @fldFatParams %fldFatParams );

    BEGIN {
	# Format and field names for an MS-DOS master boot sector [MBR]:
	$fmtSect0= "a3 a8 a429 L S a64 S";
	@fldSect0= qw( pJump sOEM pBoot nSig nZero pPrtns nMarker );
	# Format and field names for part of a FAT partition boot sector [PBR]:
	# [Since pJump, sOEM, and nMarker are the same as for an MBR, we just
	#  extract the fields out of pBoot, even though a PBR doesn't have
	#  nSig, nZero, nor pPrtns.]
	@fldSect0{@fldSect0}= (0..$#fldSect0);
	$fmtFatParams= "S C S C S S C S S S L L a406";
	@fldFatParams=
	  qw( cSectBytes cClustSects cBootSects cFats cDirFiles nMediaType
	      cFatSects cTrackSects cCylHeads cHideSects cDiskSects pFatBoot );
	@fldFatParams{@fldFatParams}= (0..$#fldFatParams);
    }

    sub new
    {
	# Expect the class name and the boot sector data [512-byte string]:
	my( $Self, $pSect0 )= @_;

	# Allow C<$object->new($pSect0)>, not just C<Sector0->new($pSect0)>:
	$Self= ref($Self)   if  ref($Self);

	# Create the hash that will be tied to this package:
	my $tied= {};

	# Let TIEHASH allocate the hash that will hold our object's members:
	my $obj= tie %$tied, $Self;

	# Allow $tied->Meth(), not just $tied->{Mem} and tied(%$tied)->Meth():
	bless $tied, $Self;

	# Populate all of our members:
	$obj->_set_pSect0( $pSect0 );

	# Return the combined ref-to-tied-hash and object:
	return $tied;
    }

    sub TIEHASH
    {
	my( $Self )= @_;
	my $hash= {};
	return bless $hash, $Self;
    }

    # After we modify the pBoot member, we must call this:
    sub _set_pBoot
    {
	my( $obj )= @_;
	$obj->{fldFat} ||= [];	# Don't rely on autovivify.
	@{ $obj->{fldFat} }=  unpack $fmtFatParams, $obj->FETCH("pBoot");
    }

    # Don't store new pSect0 member directly.  Call this instead:
    sub _set_pSect0
    {
	my( $obj, $pSect0 )= @_;
	$obj->{pSect0}= $pSect0;

	$obj->{fldSect0} ||= [];
	@{ $obj->{fldSect0} }= unpack $fmtSect0, $pSect0;

	# The previous line modified the pBoot member:
	$obj->_set_pBoot;

	# All fields are in sync now:
	delete $obj->{bModified};

	#if(  0x55AA != $obj->FETCH("nMarker")  )
    }

    sub FETCH
    {
	my( $obj, $sKey )= @_;
	if(  $obj->{bModified}		# The packed data may be stale:
	and  "pSect0" eq $sKey  ||  "pBoot" eq $sKey  ) {
	    # If requesting packed data, rebuild it from fields first:
	    $obj->STORE(
	      "pBoot",  pack $fmtFatParams, @{ $obj->{fldFat} }  );
	    $obj->{pSect0}= pack $fmtSect0, @{ $obj->{fldSect0} };
	    delete $obj->{bModified};
	}
	if(  "pSect0" eq $sKey  ) {
	    return $obj->{$sKey};
	} elsif(  exists $fldSect0{$sKey}  ) {
	    return $obj->{fldSect0}->[ $fldSect0{$sKey} ];
	} elsif(  exists $fldFatParams{$sKey}  ) {
	    return $obj->{fldFat}->[ $fldFatParams{$sKey} ];
	} else {
	    require Carp;
	    Carp::croak( __PACKAGE__,"::FETCH:  Unknown field ($sKey)" );
	}
    }

    sub STORE
    {
	my( $obj, $sKey, $svNewValue )= @_;
	my $svOldValue;
	if(  "pSect0" eq $sKey  ) {
	    $svOldValue= $obj->{pSect0};
	    $obj->_set_pSect0( $svNewValue );
	    return $svOldValue;
	} elsif(  exists $fldSect0{$sKey}  ) {
	    for(  $obj->{fldSect0}->[ $fldSect0{$sKey} ]  ) {
		$svOldValue= $_;
		$_= $svNewValue;
	    }
	    if(  "pBoot" eq $sKey  ) {
		$obj->_set_pBoot();
	    }
	} elsif(  exists $fldFatParams{$sKey}  ) {
	    for(  $obj->{fldFat}->[ $fldFatParams{$sKey} ]  ) {
		$svOldValue= $_;
		$_= $svNewValue;
	    }
	} else {
	    require Carp;
	    Carp::croak( __PACKAGE__,"::FETCH:  Unknown field ($sKey)" );
	}
	$obj->{Modified}= 1
	  if  $svOldValue ne $svNewValue;
	return $svOldValue;	# This is probably ignored.
    }

    sub FIRSTKEY
    {
	my( $Self )= @_;
	return "pSect0";
    }

    sub NEXTKEY
    {
	my( $Self, $keyPrev )= @_;
	return $fldSect0[0]   if  "pSect0" eq $keyPrev;
	my $idx= $fldSect0{$keyPrev};
	if(  defined $idx  ) {
	    return $fldSect0[1+$idx] || $fldFatParams[0];
	}
	$idx= $fldFatParams{$keyPrev};
	return $fldFatParams[1+$idx] || undef;
    }

}


sub Usage
{
    die
     "Usage:  $Self A: BootFile\n"
    ,"      Copies sector 0 (with boot code) of the A: drive to BootFile.\n"
    ,"   or:  $Self [-e] BootFile A: [Backup]\n"
    ,"      Copies the boot code from BootFile to sector 0 of the A: drive.\n"
    ,"      -e  Overwrites the entire sector 0.  This is the default for\n"
    ,"          floppy disks.  For hard disks, the default is to restore\n"
    ,"          only the boot code [not the signature and partition table].\n"
    ,"      If Backup is given, then the original sector is backed up first.\n"
    ,"A: can also be a number where 0 is the first physical hard disk.\n"
    ;
}


sub BackupBootCode
{
    my( $drive, $file )= @_;
    $drive= "PhysicalDrive".$drive   if  $drive =~ /^\d+$/;
    my $hDrive= createFile( "//./$drive", "r" )
      or  die "Can't read device, $drive: ",fileLastError(),"\n";
    my( $sect0, $cnt );
    ReadFile( $hDrive, $sect0, 512, $cnt, [] )
      or  die "Can't read sector 0 of $drive: ",fileLastError(),"\n";
    die "Read $cnt bytes (not 512) of sector 0 of $drive: ",
      fileLastError(),"\n"
      if  512 != $cnt;
    CloseHandle( $hDrive )
      or  warn "Can't close device, $drive: ",fileLastError(),"\n";
    {
	my $fld= Sector0->new( $sect0 );
	if(  0x55AA != $fld->{nMarker}  ) {
	    warn "Invalid boot sector on $drive (end marker is ",
	      sprintf("0x%X",$fld->{nMarker})," not 0x55AA).\n";
	}
    }
    open( FILE, "> $file\0" )
      or  die "Can't write file, $file: $!\n";
    binmode( FILE )
      or  die "Can't set file output ($file) to binary mode: $!\n";
    print FILE $sect0
      or  die "Can't write sector 0 to file, $file: $!\n";
    close( FILE )
      or  die "Can't close file, $file: $!\n";
}

sub ConfirmContinue
{
    my( $drive )= @_;
    print "Replace ${drive}'s boot sector anyway? ";
    my $resp= <STDIN>;
    if(  $resp !~ /^\s*y/i  ) {
	die "Aborting changes.\n";
    }
}

sub RestoreBootCode
{
    my( $file, $drive )= @_;
    my $bFloppy= 0;
    if(  $drive =~ /^\d+$/  ) {
	$drive= "PhysicalDrive".$drive;
    } else {
	my $type= GetDriveType( $drive );
	if(  DRIVE_REMOVABLE == $type  ) {
	    $bFloppy= 1;
	} elsif(  DRIVE_FIXED != $type  ) {
	    warn "This probably won't work for $drive (type==$type).\n";
	}
    }
    my( $cursect, $newsect, $cnt );
    open( FILE, "< $file\0" )
      or  die "Can't read file, $file: $!\n";
    binmode( FILE )
      or  die "Can't set $file input to binary mode: $!\n";
    $cnt= read( FILE, $newsect, 513 )
      or  die "Can't read sector data from file, $file: $!\n";
    warn "More than 512 bytes in file, $file; ignoring extra.\n"
      if  512 < $cnt;
    die "Fewer than 512 bytes (only $cnt) in file, $file.\n"
      if  $cnt < 512;
    close( FILE )
      or  warn "Can't close file, $file: $!\n";
    my $fldNew= Sector0->new( $newsect );
    if(  0x55AA != $fldNew->{nMarker}  ) {
	warn "Invalid boot sector in file, $file (end marker is ",
	  sprintf("0x%X",$fldNew->{nMarker})," not 0x55AA).\n";
	ConfirmContinue( $drive );
    }
    my $hDrive= createFile( "//./$drive", "rwke" )
      or  die "Can't update device, $drive: ",fileLastError(),"\n";
    ReadFile( $hDrive, $cursect, 512, $cnt, [] )
      or  die "Can't read sector 0 of $drive: ",fileLastError(),"\n";
    die "Read $cnt bytes (not 512) of sector 0 of $drive: ",
      fileLastError(),"\n"
      if  512 != $cnt;
    my $fldCur= Sector0->new( $cursect );
    if(  0x55AA != $fldCur->{nMarker}  ) {
	warn "Invalid boot sector on $drive (end marker is ",
	  sprintf("0x%X",$fldCur->{nMarker})," not 0x55AA).\n";
    }
    if(  $bFloppy  ) {
	# For floppy, verify basic FAT params same then replace entire sector:
	my @dif= map { $fldCur->{$_} ne $fldNew->{$_} } @Sector0::fldFatParams;
	if(  @dif  ) {
	    warn "The following FAT parameters will be changed:\n";
	    for(  @dif  ) {
		warn "\t $_ from $fldCur->{$_} to $fldNew->{$_}\n";
	    }
	    ConfirmContinue( $drive );
	}
    } elsif(  ! $WriteEntire  ) {
	# For hard disk w/o -e, keep old nSig, nZero, pPrtns, and nMarker
	my @keep= qw( nSig nZero pPrtns nMarker );
	@{$fldNew}{@keep}= @{$fldCur}{@keep};
    } # For hard disk w/ -e, replace entire sector.
    $newsect= $fldCur->{pSect0};
    $cnt= SetFilePointer( $hDrive, 0, [], 0 )
      or  die "Can't seek back to front of device, $drive: ",
	    fileLastError(),"\n";
    die "Seeking to front of drive set wrong offset ($cnt).\n"
      if  0 != $cnt;
    WriteFile( $hDrive, $newsect, 512, $cnt, [] )
      or  die "Can't write sector 0 of $drive: ",fileLastError(),"\n";
    die "Write $cnt bytes (not 512) of sector 0 of $drive: ",
      fileLastError(),"\n"
      if  512 != $cnt;
    CloseHandle( $hDrive )
      or  die "Can't close device, $drive: ",fileLastError(),"\n";
}


sub main
{
    @ARGV= map { glob($_) } @ARGV;
    while(  @ARGV  &&  $ARGV[0] =~ /^-/  ) {
	my $opt= shift( @ARGV );
	$opt =~ s/^-//;
	if(  $opt =~ s/^e//i  ) {
	    $WriteEntire= 1;
	} else {
	    die "Unknown option, -$opt.\n";
	}
    }
    die "Current implementation doesn't support three-argument mode.\n"
      if  3 == @ARGV;
    Usage   if  2 != @ARGV;
    my( $src, $dest )= @ARGV;
    if(  $src =~ /^([a-z]:|\d+)$/i  ) {
	die "Can't copy boot code direclty between devices.\n"
	  if  $dest =~ /^([a-z]:|\d+)$/i;
	BackupBootCode( $src, $dest );
    } else {
	RestoreBootCode( $src, $dest );
    }
    return 0;
}

__END__
:endofperl
