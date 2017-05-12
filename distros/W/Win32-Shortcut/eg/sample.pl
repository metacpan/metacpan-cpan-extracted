# TEST.PL for the Win32::Shortcut Package
# Version 0.03
# by Aldo Calpini <dada@perl.it>

use Win32::Shortcut;
use Cwd;

print "\nWin32::Shortcut ", Win32::Shortcut::Version, " TEST\n\n";

print "1. Creating a shortcut to Notepad...";

$L=new Win32::Shortcut();

if($L) {
    print "\n";

    # [dada] some technical info 
    # print "   L.ilink=".$L->{'ilink'}."\n";
    # print "   L.ifile=".$L->{'ifile'}."\n";

    my $windows = $ENV{'SYSTEMROOT'} || $ENV{'WINDIR'};
    $L->Path("$windows\\Notepad.exe");
    my $temp = $ENV{'TEMP'}; $temp =~ s!/!\\!g;
    $L->WorkingDirectory($temp);
    $L->ShowCmd(3);

    printf("%20s = %s\n","Path",            $L->Path);
    printf("%20s = %s\n","WorkingDirectory",$L->WorkingDirectory);
    printf("%20s = %s\n","ShowCmd",         $L->ShowCmd);
    print "   Saving \"test1.lnk\"...";

    $result=$L->Save("test1.lnk");
    print "OK\n" if $result;
    print "*** ERROR ***\n" if not $result;

    $L->Close(); 

} else {
    print "*** ERROR ***\n";
}

print "\n2. Reloading the shortcut...";
$L = new Win32::Shortcut("test1.lnk");
if($L) {
    print "\n";
    printf("%20s = %s\n","Path",             $L->Path);
    printf("%20s = %s\n","WorkingDirectory", $L->WorkingDirectory);
    printf("%20s = %s\n","ShowCmd",          $L->ShowCmd);
    printf("%20s = %s\n","Description",      $L->Description);
    printf("%20s = %s\n","Hotkey",           $L->Hotkey);
    printf("%20s = %s\n","IconLocation",     $L->IconLocation);
    printf("%20s = %s\n","IconNumber",       $L->IconNumber);
    
    print "\n   Changing shortcut data...\n";

    $L->Set($windows."\\Write.exe",
            "",
            $windows,
            "This is a description",
            1,
            hex('0x0337'),
            "",
            0);

    print "   Saving to \"test2.lnk\"...";

    $result=$L->Save("test2.lnk");

    if($result) {
        print "OK\n";
    } else {
        print "** ERROR **\n";
    }

    print "\n   Reloading \"test2.lnk\"...\n";
    $L->Load("test2.lnk");
    printf("%20s = %s\n","Path",             $L->Path);
    printf("%20s = %s\n","WorkingDirectory", $L->WorkingDirectory);
    printf("%20s = %s\n","ShowCmd",          $L->ShowCmd);
    printf("%20s = %s\n","Description",      $L->Description);
    printf("%20s = %s\n","Hotkey",           $L->Hotkey);
    printf("%20s = %s\n","IconLocation",     $L->IconLocation);
    printf("%20s = %s\n","IconNumber",       $L->IconNumber);
    $L->Close();
    undef $L;
}
  
print "\n3. Resolving a shortcut...\n";
print "   Creating a dummy file \"dummy.txt\"...";

if(open(DUMMY,">dummy.txt")) {
    print DUMMY "doh\n";
    close(DUMMY);
    print "OK\n";
    print "   Creating the shortcut...";
    $L = new Win32::Shortcut();
    if($L) {
        print "OK\n";
	require Win32 unless defined &Win32::GetCwd;
        $pathto = Win32::GetCwd();
        $L->Path("$pathto\\dummy.txt");
        $L->WorkingDirectory($pathto);
        printf("%20s = %s\n", "WorkingDirectory", $L->WorkingDirectory);
        printf("%20s = %s\n", "Path", $L->Path);
        print "   Saving to \"test3.lnk\"...";
        $result = $L->Save("test3.lnk");
        if($result) {
            print "OK\n";
            print "\n   Renaming \"dummy.txt\" to \"dummy2.txt\"...";
            if(rename("dummy.txt", "dummy2.txt")) {
                print "OK\n";
                print "   Attempting resolve...";
                $L->Resolve() or print "Resolve failed\n";
                if(-f $L->{'Path'}) {
                    print "OK\n";
                    print "   Successfully resolved to \"$L->{'Path'}\"!\n";
                    print "   Saving \"test3.lnk\"...";
                    $result = $L->Save();
                    print "OK\n" if $result;
                    print "*** ERROR ***\n" if not $result;
                } else {
                    print "FAILED\n";
                }
            } else {
                print "** ERROR **\n";
            }
        } else {
            print "** ERROR **\n";
        }
        $L->Close(); 
    } else {
        print "** ERROR **\n";
    }
} else {
    print "** ERROR **\n";
}

END { unlink qw[dummy.txt dummy2.txt test1.lnk test2.lnk test3.lnk]; }
