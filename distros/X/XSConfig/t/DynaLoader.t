#!/usr/bin/perl
eval "use DynaLoader;";
if($@) {
    warn $@;
    print <<'END';
1..1
not ok 1 - RT #125756 Old DynaLoader works
END
} else {
    print <<'END';
1..1
ok 1 - RT #125756 Old DynaLoader works
END
}

#C:\perl587\srcnew>perl -MDynaLoader -e"exit 0"
#DynaLoader object version 1.05 does not match $DynaLoader::VERSION  at C:/perl58
#7/srcnew/lib/XSLoader.pm line 16.
#Compilation failed in require at C:/perl587/srcnew/lib/Config.pm line 62.
#Compilation failed in require at C:/perl587/srcnew/lib/DynaLoader.pm line 25.
#BEGIN failed--compilation aborted at C:/perl587/srcnew/lib/DynaLoader.pm line 25
#.
#Compilation failed in require.
#BEGIN failed--compilation aborted.
