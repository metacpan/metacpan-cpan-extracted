use VMS::IndexedFile;

print "\nHere are the first 20 userids in your SYSUAF file\n";
print "   Alphabetically                    in UIC order\n";
print "   --------------                    ------------\n";

tie(%sysuaf1,VMS::IndexedFile,"sysuaf",0)
  or tie(%sysuaf1,VMS::IndexedFile,'sys$system:sysuaf.dat',0)
  or die "Can't open SYSUAF file: $!\n";

tie(%sysuaf2,VMS::IndexedFile,"sysuaf",1)
  or tie(%sysuaf2,VMS::IndexedFile,'sys$system:sysuaf.dat',1)
  or die "Can't open SYSUAF file: $!\n";

for($i = 0; $i < 20; $i++) {
  ($userid1,$uid1,$gid1) = unpack("x4a12x20SS",$sysuaf1{''});
  ($userid2,$uid2,$gid2) = unpack("x4a12x20SS",$sysuaf2{''});
  printf ("   [%04.4o,%04.4o] %s          [%04.4o,%04.4o] %s\n",
    $gid1,$uid1,$userid1,$gid2,$uid2,$userid2);
}

print "\n";

untie(%sysuaf1);
untie(%sysuaf2);
