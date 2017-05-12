use Win32::kernel32;

# ... or: use Win32::kernel32 qw( Sleep SetLastError );

print "Sleep: sleeping 2,5 second...";
Win32::Sleep(2500);
print "done\n\n";

print "GetTempPath: ", Win32::GetTempPath(), "\n\n";
print "GetBinaryType(C:\\windows\\notepad.exe): ",
    Win32::GetBinaryType("C:\\windows\\notepad.exe"),
    "\n\n";
print "GetVolumeInformation(): ", scalar(Win32::GetVolumeInformation()), "\n\n";
($label, $serial, $maxlen, $flags, $fstype) = Win32::GetVolumeInformation("c:\\");
print "GetVolumeInformation(C:\\).label: ",  $label,  "\n";
print "GetVolumeInformation(C:\\).serial: ", $serial, "\n";
print "GetVolumeInformation(C:\\).maxlen: ", $maxlen, "\n";
print "GetVolumeInformation(C:\\).flags: ",  $flags,  "\n";
print "GetVolumeInformation(C:\\).fstype: ", $fstype, "\n\n";
print "GetDiskFreeSpace(): ", join("/", Win32::GetDiskFreeSpace()), "\n\n";
print "VerLanguageName(1040): ", Win32::VerLanguageName(1040), "\n\n";
print "CopyFile(kernel32.pl, Copy of kernel32.pl): ",
    (Win32::CopyFile("kernel32.pl", "Copy of kernel32.pl"))
    ? "OK"
    : "Failed, file exists",
    "\n\n";
print "CopyFile(kernel32.pl, Copy of kernel32.pl, 0): ",
    (Win32::CopyFile("kernel32.pl", "Copy of kernel32.pl", 0)) ? "OK" : "Failed",
    "\n\n";
print "QueryDosDevice(): \n\t", join("\n\t", Win32::QueryDosDevice()), "\n\n";
print "GetCommandLine: \"", Win32::GetCommandLine(), "\"\n\n";
print "GetCurrencyFormat(3185928): \"", Win32::GetCurrencyFormat("3185928"), "\"\n\n";
print "GetDriveType(): ", Win32::GetDriveType(), "\n\n";

print "Press ENTER to view the kernel32.pm documentation: ";
$enter = <STDIN>;
`start kernel32.html`;
