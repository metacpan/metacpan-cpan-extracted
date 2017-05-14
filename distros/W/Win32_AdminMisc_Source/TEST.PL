        #   T e s t . p l
        #   -------------
        #   This is a test perl script designed to demonstrate some of the
        #   functions of Win32::AdminMisc.

    use Win32::AdminMisc;
    use Win32;

    if ($Win32::AdminMisc::Version < 971022){
        print "THIS VERSION OF WIN32::ADMINMISC IS TOO OLD TO WORK WITH THIS SCRIPT.\n";
        exit;
    }


    $Node = Win32::NodeName();
    $Domain = Win32::DomainName();
    $User = Win32::LoginName();

    $User = 'administrator';
    $Domain = '';


    if (%Data = Win32::AdminMisc::GetProcessorInfo()){
        print "Memory Information:\n";
        print "\tNumber of processors: $Data{ProcessorNum}\n";
        print "\tType of processor:    $Data{ProcessorType}\n";
        print "\tProcessor level:      $Data{ProcessorLevel}\n";
        print "\tProcessor revision:   $Data{ProcessorRevision}\n";
        print "\tPage size:            $Data{PageSize}\n";
    }

    undef %Data;
    if (%Data = Win32::AdminMisc::GetMemoryInfo()){
        print "\nMemory Information:\n";
        print "\tMemory available:     $Data{RAMAvail}\n";
        print "\tMemory total:         $Data{RAMTotal}\n";
        print "\tVirtual mem avail:    $Data{VirtAvail}\n";
        print "\tVirtual mem total:    $Data{VirtTotal}\n";
        print "\tPage mem available:   $Data{PageAvail}\n";
        print "\tPage mem total:       $Data{PageTotal}\n";
        print "\tCurrent memory load:  $Data{Load}\n";
    }

    undef %Data;

    if (%Data = Win32::AdminMisc::GetWinVersion()){
        print "\nWindows Information:\n";
        print "\tPlatform:             $Data{Platform}\n";
        print "\tVersion:              $Data{Major}.$Data{Minor}\n";
        print "\tBuild:                $Data{Build}\n";
        print "\tService Pack version: $Data{CSD}\n";
    }

    if (@Data = Win32::AdminMisc::GetIdInfo()){
        print "\nProcess Information:\n";
        print "\tThis Process ID:      $Data[0]\n";
        print "\tThis Thread ID:       $Data[1]\n";
        print "\tThis command line:    \"$Data[4]\"\n";
    }

    ####
    #   Get Drive information
    ####
    print "\nLocal Drive Information:\n";
    @Temp = Win32::AdminMisc::GetDrives(DRIVE_REMOVABLE);
    ProcessDrive( "Removeable", @Temp);
    @Temp = Win32::AdminMisc::GetDrives(DRIVE_FIXED);
    ProcessDrive("Fixed", @Temp);
    @Temp = Win32::AdminMisc::GetDrives(DRIVE_CDROM);
    ProcessDrive( "CDRom", @Temp);
    @Temp = Win32::AdminMisc::GetDrives(DRIVE_REMOTE);
    ProcessDrive("Net", @Temp);


    $~ = "DriveHeader";
    write;
    $~ = "Drive";
    foreach $Name (sort(keys(%Drive))){
        @Metric = ();
        @Metric = Win32::AdminMisc::GetDriveGeometry($Name);
        write;
    }

    @TotalDrives = Win32::AdminMisc::GetDrives();
    print "\nTotal number of connected drives: " . scalar @TotalDrives . " (not necessarily listed above)\n";

    print "\nLooking up attributes for $User in domain '$Domain'...\n";
    if (Win32::AdminMisc::UserGetMiscAttributes($Domain, $User, \%Hash)){

        $~ = "AttributeHeader";
        write;
        $~ = "Attribute";
        foreach $Attrib (sort keys(%Hash)){
            write;
        }
    }else{
        Error("UserGetMiscAttributes()");
    }


    print "\nDump of section keys in $ENV{'SYSTEMROOT'}\\win.ini file:\n";
    @Keys = Win32::AdminMisc::ReadINI("$ENV{'SYSTEMROOT'}\\win.ini", '', '');
    if (scalar @Keys){
        foreach (sort @Keys){
            print "\t[$_]\n";
        }
    }else{
        Error("ReadINI()");
    }




    print "\n\nR e p o r t :\n-------------\n";
    if (scalar @Error){
        print "The following errors have occured:\n\t";
        print join("\n\t", @Error) . "\n";
    }else{
        print "No errors have been detected.\n";
    }



#   ==========================================================

format AttributeHeader =
    Attribute                Value
    =======================  ==============================================
.

format Attribute =
    @<<<<<<<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    $Attrib,                 $Hash{$Attrib}
.


format DriveHeader =
                                              Sectors/  Bytes/   Total
  Drive  Type     Size          Available     Cluster   Sector   Clusters
  =====  =======  ============  ============  ========  =======  ========
.

format Drive =
  @<<<<  @<<<<<<  @>>>>>>>>>>>  @>>>>>>>>>>>  @<<<<<<<  @<<<<<<  @<<<<<<<
  $Name,  $Drive{$Name}->{Type}, $Drive{$Name}->{Size}, $Drive{$Name}->{Free}, $Metric[0], $Metric[1], $Metric[3]
.

sub Error{
    my($Function, $Comment) = @_;

    push(@Error, $Function);
    $Comment = Win32::FormatMessage(Win32::GetLastError()) unless $Comment;
    print "\tError with $Function:\n\t\"$Comment\"\n";
}

sub ProcessDrive{
    my($Type, @List) = @_;

    foreach (@List){
        $Drive{$_}->{Type} = $Type;
        ($Drive{$_}->{Size}, $Drive{$_}->{Free}) = Win32::AdminMisc::GetDriveSpace($_);
    }

}

sub Test{
    my($Comment, @Result) = @_;

    $iCount++;
    print "\n$iCount) $Comment:\n";
    if (scalar @Result){
        print "Results:\n\t" . join("\n\t", @Result) . "\n";
    }else{
        print "\tFail.\n";
    }
}

sub Error{

 return Win32::FormatMessage(Win32::GetLastError());
}
