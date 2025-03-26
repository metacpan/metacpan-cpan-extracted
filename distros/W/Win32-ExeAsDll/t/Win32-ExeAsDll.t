use strict;
use warnings;
use List::Util qw(first);
#use Devel::Peek;
#use Data::Dumper;
our $NO_ENDING;
BEGIN {
    sub INVALID_FILE_ATTRIBUTES {return -1;}
    sub FILE_ATTRIBUTE_DIRECTORY {return 0x10;}
    sub GetCurrentProcess {return -1;}
    unshift(@INC, '.');
    require "t/w32ead_test.pl";
    plan(33);
    use_ok('Win32::ExeAsDll', 'use; the .pm');
}

BEGIN {
  my $tmpfiledtor = sub {   unlink('o.txt');    unlink('err.txt');    };
  $SIG{__DIE__} = $tmpfiledtor;
  END {
    $tmpfiledtor->();
  }
}

ok(!getRC(), 'no cmd.exe in proc');

{
    #my $o=Win32::ExeAsDll->new();
    #$o->main('cmd /C ver', "\x5c\x5c0.0.0.0\x5cC\x5co.txt", "\x5c\x5c0.0.0.0\x5cC\x5cerr.txt");
    #local ($Data::Dumper::Useqq) = 1;
    #print Data::Dumper::Dumper(["\x5c\x5c0.0.0.0\x5cC\x5co.txt", "\x5c\x5c0.0.0.0\x5cC\x5cerr.txt"]);
    0;
}

fresh_perl_is(
    'use blib;use Win32::ExeAsDll;my $o=Win32::ExeAsDll->new();$o->main(\'cmd.exe /C echo 2222\');',
    '2222', '', 'test \'cmd.exe /C echo 2222\'');
fresh_perl_is(
    'use blib;use Win32::ExeAsDll;my $o=Win32::ExeAsDll->new(\'cmd.exe\');$o->main(\'cmd.exe /C echo 2222\');',
    '2222', '', 'test \'cmd.exe /C echo 2222\'');
fresh_perl_like(
    'use blib;use Win32::ExeAsDll;my $o=Win32::ExeAsDll->new();$o->main(\'cmd /C ver\');',
    'Microsoft Windows', '', 'test \'cmd /C ver\'');
fresh_perl_like(
    'use blib;use Win32::ExeAsDll;my $o=Win32::ExeAsDll->new(\'doesnt_exist_foo.exe\');if($o){$o->main(\'cmd /C ver\');}else{print($^E+0);}',
    # 126 == ERROR_MOD_NOT_FOUND
    '126', '', 'test file doesnt_exist_foo.exe doesn\'t exist');
fresh_perl_like(
    'use blib;use Win32::ExeAsDll;my $o=Win32::ExeAsDll->new();'
    .'$o->main(\'cmd.exe /C dir\', \'o.txt\', \'err.txt\');'
    .'print \'done o.txt err.txt\';',
    'done o.txt err.txt', '', 'test \'done o.txt err.txt\'');
{
    open(my $f, '<', 'o.txt') or die "OPENING o.txt: $!\n";
    my $string = do { local($/); <$f> };
    close($f);
    unlink('o.txt');
    like($string, 'Directory of', 'stdout capture .txt');
}
{
    open(my $f, '<', 'err.txt') or die "OPENING err.txt: $!\n";
    my $string = do { local($/); <$f> };
    close($f);
    unlink('err.txt');
    like($string, '', 'stderr capture .txt');
}

unlink('o.txt');
unlink('err.txt');

fresh_perl_like(
    'use blib;use Win32::ExeAsDll;my $o=Win32::ExeAsDll->new();'
    .'$o->main(\'cmd.exe /C dir\', "\x5c\x5c0.0.0.0\x5cC\x5co.txt", "\x5c\x5c0.0.0.0\x5cC\x5cerr.txt");'
    .'print \'done o.txt err.txt\';',
    '::main: CreateFileW GetLastError=1214', '', 'test bad UNC paths \\0.0.0.0\C\ o.txt err.txt');

fresh_perl_like(
    'use blib;use Win32::ExeAsDll;my $o=Win32::ExeAsDll->new();'
    .'$o->main(\'cmd.exe /C del 1>:NUL\', \'o.txt\', \'err.txt\');'
    .'print \'done real err.txt\';',
    'done real err.txt', '', 'test \'done real err.txt\'');
{
    open(my $f, '<', 'o.txt') or die "OPENING o.txt: $!\n";
    my $string = do { local($/); <$f> };
    close($f);
    unlink('o.txt');
    like($string, '', 'real stderr capture .txt fd 1');
}
{
    open(my $f, '<', 'err.txt') or die "OPENING err.txt: $!\n";
    my $string = do { local($/); <$f> };
    close($f);
    unlink('err.txt');
    like($string, 'The syntax of the command is incorrect', 'real stderr capture .txt fd 2');
}


{
    my $CopyFileW;
    sub CopyFileW {
        if(!$CopyFileW) {
            require Win32::API;
            require Encode;
            $CopyFileW = new Win32::API('kernel32', 'CopyFileW', 'PPL', 'N');
            die $^E if !$CopyFileW;
        }
        my ($wold, $wnew, $bFailIfExists) = (
            Encode::encode("UTF-16LE", $_[0]."\x00"),
            Encode::encode("UTF-16LE", $_[1]."\x00"),
            $_[2]
        );
        return $CopyFileW->Call($wold, $wnew, $bFailIfExists);
    }
}

{
    my $DeleteFileW;
    sub DeleteFileW {
        if(!$DeleteFileW) {
            require Win32::API;
            require Encode;
            $DeleteFileW = new Win32::API('kernel32', 'DeleteFileW', 'P', 'N');
            die $^E if !$DeleteFileW;
        }
        my $w = Encode::encode("UTF-16LE", $_[0]."\x00");
        return $DeleteFileW->Call($w);
    }
}

{
    my $GetCurrentDirectoryW;
    sub GetCurrentDirectoryW {
        if(!$GetCurrentDirectoryW) {
            require Win32::API;
            require Encode;
            $GetCurrentDirectoryW = new Win32::API('kernel32', 'GetCurrentDirectoryW', 'NP', 'N');
            die $^E if !$GetCurrentDirectoryW;
        }
        my $wstr = "\x00" x (256*2);
        my $wlen = length($wstr)/2;
        my $r;
        while(($r = $GetCurrentDirectoryW->Call($wlen, $wstr)) >= $wlen ) {
            $wstr = "\x00" x ($r*2);
            $wlen = length($wstr)/2;
        }
        if($r) {
          $wstr = substr($wstr,0,$r*2);
          $wstr = Encode::decode("UTF-16LE", $wstr);
        } else {
          $wstr = undef;
        }
    }
}

{
    my $o = Win32::ExeAsDll->new();
    my ($found, $dir, $out, $dh) = (0);
    $o->main('cmd.exe /C echo done Unicode STDOUT capture', "out\N{U+2708}.txt", "err\N{U+2708}.txt");
    opendir($dh, ".") || die "Can't open .: $!";
    while($dir = readdir $dh) {
        if($dir eq "OUT~1.TXT") {
            $found++;
            ok(FileExists("out\N{U+2708}.txt"), 'file "out\N{U+2708}.txt" exists');
            open(my $f, '<', "./OUT~1.TXT") or die "OPENING ./OUT~1.TXT: $!\n";
            $out = do { local($/); <$f> };
            close($f);
            unlink("./OUT~1.TXT");
            ok(!FileExists("out\N{U+2708}.txt"), 'file "out\N{U+2708}.txt" doesn\'t exists');
        }
        elsif($dir eq "ERR~1.TXT") {
            ok(FileExists("err\N{U+2708}.txt"), 'file "err\N{U+2708}.txt" exists');
            $found++;
            unlink("./ERR~1.TXT");
            ok(!FileExists("err\N{U+2708}.txt"), 'file "err\N{U+2708}.txt" doesn\'t exists');
        }
        last if $found >= 2;
    }
    closedir $dh;
    cmp_ok($found, '==', 2, "made 2 UTF16 Wide paths for 2 streams (STDERR and STDOUT)");
    like($out, 'done Unicode STDOUT capture', 'unicode path STDOUT capture contents');
    my $f = $o->GetExeFileName();
    like($f, 'cmd.exe', '$o->GetExeFileName()');
    my $cwd = GetCurrentDirectoryW();
    my $newfp = $cwd."\\cmd_tmp_uni_\N{U+2708}.exe";
    my $r = CopyFileW($f, $newfp, 0);
    my $es = $^E;
    my $en = $^E+0;
    diag("CopyFileW to emoji path e=".$en.' e='.$es) if !$r;
    cmp_ok($r, '==', 1 , 'CopyFileW to an emoji path had retval success');
    my $o2 = Win32::ExeAsDll->new($newfp);
    $f = $o2->GetExeFileName();
    like($f, "cmd_tmp_uni_\N{U+2708}.exe", 'GetExeFileName on cmd.exe with emojis path');
    ok($f eq $newfp, 'create emoji path is runtime GetExeFileName emoji path');

    unlink("./OUT~1.TXT");
    unlink("./ERR~1.TXT");
    $o2->main('"'.$newfp.'" /C echo done Unicode STDOUT capture', "out\N{U+2708}.txt", "err\N{U+2708}.txt");
    $f = undef;
    open($f, '<', "./OUT~1.TXT") or die "OPENING ./OUT~1.TXT: $!\n";
    $out = do {
      local($/);
      <$f> 
    };
    close($f);
    unlink("./OUT~1.TXT");
    unlink("./ERR~1.TXT");
    like($out, 'done Unicode STDOUT capture', 'unicode path STDOUT capture contents #2');

    $o2 = undef;
    $r = DeleteFileW($newfp);
    $es = $^E;
    $en = $^E+0;
    diag("DeleteFileW  e=".$en.' e='.$es) if !$r;
    ok($r, 'DeleteFileW on cmd.exe path with emoji chars');
}

my $PTR_SIZE = length(pack('P',undef));
my $PTR_LET = $PTR_SIZE == 4 ? 'L' : 'Q';

sub decodeGPMI {
    my @r = unpack( 'LL'.($PTR_LET x 8), $_[0]);
    my %r;
    $r{cb} = $r[0];
    $r{PageFaultCount} = $r[1];
    $r{PeakWorkingSetSize} = $r[2];
    $r{WorkingSetSize} = $r[3];
    $r{QuotaPeakPagedPoolUsage} = $r[4];
    $r{QuotaPagedPoolUsage} = $r[5];
    $r{QuotaPeakNonPagedPoolUsage} = $r[6];
    $r{QuotaNonPagedPoolUsage} = $r[7];
    $r{PagefileUsage} = $r[8];
    $r{PeakPagefileUsage} = $r[9];
    return \%r;
}

    # skip calling C funcs GetCurrentProcessId() / OpenProcess() / CloseHandle()
    # and hard code the CPP macro const "HANDLE GetCurrentProcess();" as -1
    # like SDK headers do but unrecommended by MSDN API docs

    #use the variant of the C struct that is the oldest, smallest and 
    #most compatible with old Windows versions, PROCESS_MEMORY_COUNTERS
sub makeGPMIBuf {
  my $BufSize = 4+4+(8*$PTR_SIZE);
  $_[1] = $BufSize;
  $_[0] = pack('L', $BufSize).('\0' x ($BufSize+$PTR_SIZE)); #secret 9xPTR for paranoia
}

sub do_call_exe_leak_test {
  my ($o, $BufSize, $MemStruct, $GPMIRet) = shift;
  foreach(0..150) {$o->main('cmd.exe /C echo off'); }
  makeGPMIBuf($MemStruct, $BufSize);
  # my $GetProcessMemoryInfo = shift;
  shift->Call(GetCurrentProcess(), $MemStruct, $BufSize);
  $GPMIRet = decodeGPMI($MemStruct);
  $GPMIRet = $GPMIRet->{WorkingSetSize};
  return $GPMIRet;
}

sub getRC {
    my ($out, $rc);
    Win32::ExeAsDll::DumpNtDllLdrTable(\$out);
    #print Dumper($out);
    $rc = first { $_->[1] =~ /cmd\.exe$/i ?  [$_->[2]] : undef } @$out;
    #die "cmd.exe not found in nt mod list" if !$rc1;
    $rc = $rc->[2] if $rc;
    return $rc;
}

sub do_dll_rcbump_test {
    my $ret = shift;
    my $o2 = Win32::ExeAsDll->new();
    my $ret2 = getRC();
    diag('cmd.exe #2 rc='.$ret2."\n");
    ok($ret2 > $ret, 'cmd.exe in proc 2 objs');
    return;
}

{
    my $has_a_fork;
    sub can_fork () {
        use Config;
        return $has_a_fork if defined $has_a_fork;
        my $native = $Config{d_fork} || $Config{d_pseudofork};
        my $win32 = ($^O eq 'MSWin32' || $^O eq 'NetWare');
        my $ithr = $Config{useithreads} and $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/;
        return ($has_a_fork = !!($native || ($win32 and $ithr)));
    }
}

{
    my $GetFileAttributesW;
    sub FileExists {
        if(!$GetFileAttributesW) {
            require Encode;
            require Win32::API;
            $GetFileAttributesW = new Win32::API('kernel32', 'GetFileAttributesW', 'P', 'N');
            die $^E if !$GetFileAttributesW;
        }
        my ($wpath, $dwAttrib);
        $wpath = Encode::encode("UTF-16LE", $_[0]."\x00");
        $dwAttrib = $GetFileAttributesW->Call($wpath);
        return !!($dwAttrib != INVALID_FILE_ATTRIBUTES
            && !($dwAttrib & FILE_ATTRIBUTE_DIRECTORY));
    }
}

{
    #diag("starting to test inside self-perl-proc");
    diag(" ");
    no strict 'subs';
    require Win32::API;
    my ($o, $ret, $ret2, $GetProcessMemoryInfo, $BufSize, $MemStruct,
                  $GPMIRet);
    my @WorkingSetSize;
    my $i = 0;
    $GetProcessMemoryInfo =
        new Win32::API('psapi.dll', 'GetProcessMemoryInfo', [N,P,N], I)
        || die "Can not link GetProcessMemoryInfo()\n";
    # establish baseline overhead for 1 call to Win32::ExeAsDll/cmd.exe
    ok(!getRC(), 'no cmd.exe in proc - 2');
    $o = Win32::ExeAsDll->new();
    $ret = getRC();
    diag('cmd.exe #1 rc='.$ret."\n");
    is($ret, 1, 'cmd.exe in proc 1 obj chk 1');
    {
        do_dll_rcbump_test($ret);
    }
    $ret = getRC();
    is($ret, 1, 'cmd.exe in proc 1 obj chk 2');
    $o->main('cmd.exe /C echo off');

    # establish baseline overhead for 1 call to Win32::API/GetProcessMemoryInfo()
    makeGPMIBuf($MemStruct, $BufSize);
    $ret = $GetProcessMemoryInfo->Call(GetCurrentProcess(), $MemStruct, $BufSize );
    ok($ret, 'GetProcessMemoryInfo() syscall no. 1 retval');
    $GPMIRet = decodeGPMI($MemStruct);
    $WorkingSetSize[$i] = $GPMIRet->{WorkingSetSize};

    # prove no mem leak, first 2 slots in the array are always/usually smaller
    # than slots 3-6, and 3-6 are the same value in my testing, so mem usage
    # won't flatline until iteration #3, but after that it stays stable
    $WorkingSetSize[$i++] = do_call_exe_leak_test($o, $GetProcessMemoryInfo);
    $WorkingSetSize[$i++] = do_call_exe_leak_test($o, $GetProcessMemoryInfo);
    $WorkingSetSize[$i++] = do_call_exe_leak_test($o, $GetProcessMemoryInfo);
    $WorkingSetSize[$i++] = do_call_exe_leak_test($o, $GetProcessMemoryInfo);
    $WorkingSetSize[$i++] = do_call_exe_leak_test($o, $GetProcessMemoryInfo);
    $WorkingSetSize[$i++] = do_call_exe_leak_test($o, $GetProcessMemoryInfo);
    $WorkingSetSize[$i++] = do_call_exe_leak_test($o, $GetProcessMemoryInfo);
    $WorkingSetSize[$i++] = do_call_exe_leak_test($o, $GetProcessMemoryInfo);

    cmp_ok($WorkingSetSize[$i-2], '<=', $WorkingSetSize[$i-3],
        'perl WorkingSetSize doesnt leak during loop 1');
    cmp_ok($WorkingSetSize[$i-3], '<=', $WorkingSetSize[$i-4],
        'perl WorkingSetSize doesnt leak during loop 2');
    #print Dumper(\@WorkingSetSize);
    diag("WorkingSetSize samples", @WorkingSetSize);
    # manual test of mortal stack/croak HEAP and Win32 HANDLE cleanup dtor
    if(0 && (*Win32::ExeAsDll::AV_HMODS_START_IDX{CODE} ? 1 : 0)) {
      my $dieobj = Win32::ExeAsDll->new();
      $dieobj->[Win32::ExeAsDll::AV_HMODS_START_IDX()-1] = undef;
      foreach(0..1500000) {
        eval{
          $dieobj->main('cmd.exe /C echo off','o.txt', 'err.txt');
        };
        print $@;
      }
    }

    if(can_fork()) {
        my $pid = fork();
        if(!$pid) {
            eval { $o->main('cmd.exe /C echo off'); };
            like($@,  'Can\'t call method "main" on unblessed reference',
                      'meth/sub CLONE_SKIP worked on psuedo-fork enabled build of perl');
        }
        else {
            $NO_ENDING = 1;
            waitpid($pid, 0);
            #done_testing();
        }
    }
    else {
        skip('no psuedo fork in this interp build, can\'t test meth/sub CLONE_SKIP',1);
    }
}


