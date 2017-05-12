#usage: "C:\Win32-API\api-test>perl builddll.pl [1]"
#1st argument, if exists and is true, means create debugging symbols (PDB file)
#the DLL that is bundled is created without debugging symbols to minimize delta
#between 2 dlls upon rebuild
#
#
#build API_test and rtc DLLs, 32 vs 64 is based on whatever cl.exe is found in PATH
#this .pl is basically a batch file of what the VS solution calls
#using this .pl is more likely to cause low delta DLLs since VC project
#files are messy and complicated to understand what the final CL/LINK flags
#are and the flags are likely to accidentally change in the project file
#the committed DLLs are made by running this script with VC 2003 for 32 and
#VC 2008 for 64

my $version = `cl 2>&1`;
#not arm/IA64 compatible
my $is_64 = $version =~ /^Microsoft.+ for x64$/m ? 1 : 0;

system 'mkdir Release';
my $cmd;
$cmd = 'cl /Od /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_USRDLL" /D "APITEST_EXPORTS" /D "_WINDLL" /D "_MBCS" /GF /FD /EHsc /RTC1 /MT /GS /Gy /Fo"Release/" /Fd"Release/vc70.pdb" /W3 /c /Wp64 /Zi /TP ".\rtc.cpp"';
print $cmd; system $cmd;
$cmd = 'link /OUT:"Release/rtc.dll" /INCREMENTAL:NO /NOLOGO /DLL /DEF:"rtc'.($is_64 ? '64' : '').'.def" '.( $ARGV[0] ? '/DEBUG /PDB:"Release/rtc.pdb"' : '').' /SUBSYSTEM:WINDOWS /OPT:REF /OPT:ICF /IMPLIB:"Release/rtc.lib" /MACHINE:'.($is_64 ? 'x64' : 'x86').' kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib ".\release\rtc.obj"';
print $cmd; system $cmd;
$cmd = 'cl /Od /Ob2 /Oi /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /D "_USRDLL" /D "API_TEST_EXPORTS" /GF /FD /EHsc /RTC1 /MD /GS /Gy /Fp".\Release/API_test.pch" /Fo".\Release/" /Fd".\Release/" /W3 /c /Zi /TP ".\API_test.cpp"';
print $cmd; system $cmd;
$cmd = 'link /OUT:".\Release/API_test.dll" /INCREMENTAL:NO /NOLOGO /DLL /NODEFAULTLIB /DEF:".\API_test.def" '.( $ARGV[0] ? '/DEBUG /PDB:".\Release/API_test.pdb"' : '').' /OPT:REF /OPT:ICF /ENTRY:"ApiDllMain" /IMPLIB:".\Release/API_test.lib" /MACHINE:'.($is_64 ? 'x64' : 'x86').' /merge:.rtc=.rdata /FILEALIGN:1024 .\Release\rtc.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib ".\Release\rtc.lib" ".\release\rtc.lib" ".\release\API_test.obj"';
print $cmd; system $cmd;

if($is_64) {
    system 'copy Release\API_Test.dll ..\API_Test64.dll && copy Release\rtc.dll ..\rtc64.dll';
} else {
    system 'copy Release\API_Test.dll .. && copy Release\rtc.dll ..';
}
