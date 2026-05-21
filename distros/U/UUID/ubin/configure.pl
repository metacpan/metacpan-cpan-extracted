#
# check a bunch of stuff.
# write #define/#undef to file given in ARGV[0].
# now also writes #include's too.
#

use strict;
use warnings;
use Config;
use File::Spec ();
use File::Temp ();
use Devel::CheckLib;

select STDERR; $|=1;
select STDOUT; $|=1;

my ($out, $flagfile) = @ARGV;
my $conf  = [];
my $flags = [];
my $WIN32 = 0;  # native

# set this once a working random found
my $RANDFOUND = 0;

# try to make all temp files here
my $TMPDIR = File::Temp->newdir('UUID-conf-XXXXXXXX', TMPDIR => 1, CLEANUP => 0);

generate_conf($conf, $flags);
write_conf   ($conf, $out);

#unlink($_) for <assertlib*.obj>;
my $tmpglob = File::Spec->catfile( $TMPDIR, 'assert*' );
unlink($_) for <"$tmpglob">;
rmdir $TMPDIR;

exit 0;

sub generate_conf {
    my ($defines, $flags) = @_;
    my $longest = 0;

    # if lencheck is 1, \$longest is longest so far. sub is expected to
    #   update it if it has one longer and skip actual test.
    #
    # if lencheck is 0, \$longest contains global longest. sub is expected
    #   to use that when printing and to run the test.

    for my $check ( 1, 0 ) {
        # win32 native if on windows but not under some
        # sort of unix environ. i.e. native.
        # sets $WIN32. do this first.
        my $platform = try_platform($check, \$longest, $defines);

        # NOTE: winsock2.h must precede Windows.h,
        #       at least for Cygwin.
        try_headers($check, \$longest, $defines, $platform, q(
            #
            # format:
            #   SYMBOL   FILE   [PLATFORM [PLATFORM [...]]]
            #
            # if FILE is found SYMBOL will be defined and
            # the header included in EUMM.h.
            #
            # if one or more PLATFORMs are listed, one must
            # match that returned from try_platform() or the
            # check is skipped.
            #
            # if no platforms are listed, the header is tried
            # on every platform.
            #
            # invalid platforms are ignored but, if it is the
            # only platform for a symbol, the file will not
            # be checked.
            #
            # valid platforms: alien, cygwin, native, unix.
            # (alien = Strawberry)
            #
            # comments and blank lines allowed.
            #
            HAVE_WINSOCK2_H          winsock2.h                       native      skip
            HAVE_WINDOWS_H           Windows.h           alien cygwin native      skip
            HAVE_IPHLPAPI_H          iphlpapi.h                       native      skip
            HAVE_BCRYPT_H            bcrypt.h            alien        native      skip
            #-------------------------------------------------------------------------
            HAVE_CTYPE_H             ctype.h             alien        native unix skip
            HAVE_DISPATCH_DISPATCH_H dispatch/dispatch.h                     unix skip
            HAVE_ERR_H               err.h                                   unix skip
            HAVE_ERRNO_H             errno.h             alien        native unix skip
            #-------------------------------------------------------------------------
            HAVE_FCNTL_H             fcntl.h             alien        native unix skip
            HAVE_INTTYPES_H          inttypes.h          alien        native unix skip
            HAVE_IO_H                io.h                alien        native      skip
            HAVE_MEMORYAPI_H         memoryapi.h         alien        native      skip
            #-------------------------------------------------------------------------
            HAVE_NETINET_IN_H        netinet/in.h                            unix skip
            HAVE_NET_IF_DL_H         net/if_dl.h                             unix skip
            HAVE_NET_IF_H            net/if.h                                unix skip
            HAVE_PROCESS_H           process.h           alien        native      skip
            #-------------------------------------------------------------------------
           #HAVE_PTHREAD_H           pthread.h           alien               unix skip
            HAVE_SEMAPHORE_H         semaphore.h               cygwin        unix skip
            HAVE_STDINT_H            stdint.h            alien        native unix skip
            HAVE_STDIO_H             stdio.h             alien        native unix skip
            #-------------------------------------------------------------------------
            HAVE_STDLIB_H            stdlib.h            alien        native unix skip
            HAVE_STRING_H            string.h            alien        native unix skip
            HAVE_SYS_FILE_H          sys/file.h          alien               unix skip
            HAVE_SYS_FUTEX_H         sys/futex.h                             unix skip
            #-------------------------------------------------------------------------
            HAVE_SYS_IOCTL_H         sys/ioctl.h                             unix skip
            HAVE_SYS_MMAN_H          sys/mman.h                cygwin        unix skip
            HAVE_SYS_RANDOM_H        sys/random.h              cygwin        unix skip
            HAVE_SYS_RESOURCE_H      sys/resource.h                          unix skip
            #-------------------------------------------------------------------------
            HAVE_SYS_SOCKET_H        sys/socket.h                            unix skip
            HAVE_SYS_SOCKIO_H        sys/sockio.h                            unix skip
            HAVE_SYS_STAT_H          sys/stat.h          alien        native unix skip
            HAVE_SYS_TIME_H          sys/time.h          alien               unix skip
            #-------------------------------------------------------------------------
            HAVE_SYS_TYPES_H         sys/types.h         alien        native unix skip
            HAVE_SYS_WAIT_H          sys/wait.h                              unix skip
            HAVE_TIME_H              time.h              alien        native unix skip
            HAVE_UNISTD_H            unistd.h            alien               unix skip
            #-------------------------------------------------------------------------
            HAVE_WINCRYPT_H          wincrypt.h          alien        native      skip
        ));

        try_arc4random      ($check, \$longest, $defines, $platform);
        try_BCryptGenRandom ($check, \$longest, $defines, $platform);
        try_CryptGenRandom  ($check, \$longest, $defines, $platform);
        try_getentropy      ($check, \$longest, $defines, $platform);
        try_getrandom       ($check, \$longest, $defines, $platform);
       #try_gettimeofday    ($check, \$longest, $defines, $platform);
        try_lstat           ($check, \$longest, $defines, $platform);
        try_sa_len          ($check, \$longest, $defines, $platform);
        try_srwlock         ($check, \$longest, $defines, $platform);
        try_symlink         ($check, \$longest, $defines, $platform);
       #try_threads         ($check, \$longest, $defines, $platform);
    }
}

sub try_headers {
    my ($check, $long, $defines, $platform, $block) = @_;
    my @lines = split /\n/, $block;
    for my $line ( @lines ) {
        chomp $line;
        $line =~ s/\s*\#.*$//;    # strip comments and tail space
        $line =~ s/^\s+//;        # strip lead space
        next if $line =~ /^\s*$/; # skip empty lines

        my ($symbol, $file, @more) = split /\s+/, $line;

        # platform match ?
        my $skip = 0;
        if (scalar @more) {
            $skip = 1;
            for (@more) { $skip=0 if $_ eq $platform }
        }

        check_header($check, $skip, $long, $defines, $symbol, $file);
    }
}

sub check_header {
    my ($check, $skip, $long, $defines, $symbol, $file) = @_;

    if ($skip) {
        return if $check;
        push @$defines, "#undef $symbol";
        return;
    }

    my $msg = join ' ', 'Checking for', $file;
    my $len = length $msg;
    if ($check) {
        $$long = $len if $len > $$long;
        return;
    }
    my $more = $$long - $len;
    print $msg, ' ..', '.'x$more, ' ';

    if ($skip) {
        print "skip\n";
        push @$defines, "#undef $symbol";
        return;
    }

    my ($conf, $fh) = gen_confh_fh($defines);
    print $fh join("\n", map {s/^\s+//; $_} split(/\n/, qq{
        #include <${file}>
    }));
    close $fh;

    my $win32permit = 1;
    $win32permit = 0 if !$WIN32 && $symbol =~ /WINSOCK/;
    $win32permit = 0 if !$WIN32 && $symbol =~ /IPHLPAPI/;

    if ( $win32permit && check_lib(
        header  => $conf,
        #lib    => 'c',   # because not linking here.. duh!
        ccflags => '-I.',
        debug   => 0,
    )) {
        push @$defines, "#define $symbol 1";
        push @$defines, "#include <${file}>";
        print "found\n";
    }
    else {
        push @$defines, "#undef $symbol";
        print "none\n";
    }
    unlink $conf;
}

sub gen_confh {
    my ($defs) = @_;
    my ($fh, $fname) = File::Temp::tempfile(
        'assertconfXXXXXXXX', SUFFIX => '.h', DIR => $TMPDIR, UNLINK => 0
    );
    print $fh "$_\n" for @$defs;
    close $fh;
    return $fname;
}

sub gen_confh_fh {
    my ($defs) = @_;
    my ($fh, $fname) = File::Temp::tempfile(
        'assertconfXXXXXXXX', SUFFIX => '.h', DIR => $TMPDIR, UNLINK => 0
    );
    print $fh "$_\n" for @$defs;
    return $fname, $fh;
}

sub try_arc4random {
    my ($check, $long, $defs, $platform) = @_;
    my $msg = 'Checking for arc4random()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    print $msg, ' ..', '.'x$more, ' ';
    if ($RANDFOUND or $platform eq 'native') {
        push @$defs, '#undef HAVE_ARC4RANDOM';
        print "skip\n";
        return;
    }
    my $conf = gen_confh($defs);
    if ( check_lib(
        header   => $conf,
        lib      => 'c', # always do at least this
        ccflags  => '-I.',
        debug    => 0,
        function => q{
            unsigned char p[4];
            int c = 4;
            arc4random_buf(&p, c);
            return 0;
        },
    )) {
        push @$defs, '#define HAVE_ARC4RANDOM 1';
        print "found\n";
        $RANDFOUND = 1;
    }
    else {
        push @$defs, '#undef HAVE_ARC4RANDOM';
        print "none\n";
    }
    unlink $conf;
}

sub try_BCryptGenRandom {
    my ($check, $long, $defs, $platform) = @_;
    my $msg = 'Checking for BCryptGenRandom()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    print $msg, ' ..', '.'x$more, ' ';
    if ($RANDFOUND or $platform eq 'unix') {
        push @$defs, '#undef HAVE_BCRYPTGENRANDOM';
        print "skip\n";
        return;
    }
    my $conf = gen_confh($defs);
    if ( check_lib(
        header   => $conf,
        lib      => 'bcrypt',
        ccflags  => '-I.',
        debug    => 0,
        function => q{
            unsigned char p[4];
            int r, c = 4;
            r = BCryptGenRandom(NULL, p, c, BCRYPT_USE_SYSTEM_PREFERRED_RNG);
            return 0;
            (void)r;
        },
    )) {
        push @$defs, '#define HAVE_BCRYPTGENRANDOM 1';
        print "found\n";
        $RANDFOUND = 1;
    }
    else {
        push @$defs, '#undef HAVE_BCRYPTGENRANDOM';
        print "none\n";
    }
    unlink $conf;
}

sub try_CryptGenRandom {
    my ($check, $long, $defs, $platform) = @_;
    my $msg = 'Checking for CryptGenRandom()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    print $msg, ' ..', '.'x$more, ' ';
    if ($RANDFOUND or $platform eq 'unix') {
        push @$defs, '#undef HAVE_CRYPTGENRANDOM';
        print "skip\n";
        return;
    }
    my $conf = gen_confh($defs);
    if ( check_lib(
        header   => $conf,
        lib      => 'crypto',
        ccflags  => '-I.',
        debug    => 0,
        function => q{
            unsigned char p[4];
            int r, c = 4;
            r = CryptGenRandom((HCRYPTPROV)NULL, c, p);
            return 0;
            (void)r;
        },
    )) {
        push @$defs, '#define HAVE_CRYPTGENRANDOM 1';
        print "found\n";
        $RANDFOUND = 1;
    }
    else {
        push @$defs, '#undef HAVE_CRYPTGENRANDOM';
        print "none\n";
    }
    unlink $conf;
}

sub try_getentropy {
    my ($check, $long, $defs, $platform) = @_;
    my $msg = 'Checking for getentropy()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    print $msg, ' ..', '.'x$more, ' ';
    if ($RANDFOUND or $platform eq 'native') {
        push @$defs, '#undef HAVE_GETENTROPY';
        print "skip\n";
        return;
    }
    my $conf = gen_confh($defs);
    if ( check_lib(
        header   => $conf,
        lib      => 'c', # always do at least this
        ccflags  => '-I.',
        debug    => 0,
        function => q{
            unsigned char p[4];
            int r, c = 4;
            r = getentropy(&p, c);
            return 0;
            (void)r;
        },
    )) {
        push @$defs, '#define HAVE_GETENTROPY 1';
        print "found\n";
        $RANDFOUND = 1;
    }
    else {
        push @$defs, '#undef HAVE_GETENTROPY';
        print "none\n";
    }
    unlink $conf;
}

sub try_getrandom {
    my ($check, $long, $defs, $platform) = @_;
    my $msg = 'Checking for getrandom()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    print $msg, ' ..', '.'x$more, ' ';
    if ($RANDFOUND or $platform eq 'native') {
        push @$defs, '#undef HAVE_GETRANDOM';
        print "skip\n";
        return;
    }
    my $conf = gen_confh($defs);
    if ( check_lib(
        header   => $conf,
        lib      => 'c', # always do at least this
        ccflags  => '-I.',
        debug    => 0,
        function => '
            unsigned char p[4];
            int r, c = 4;
            r = getrandom(c, &p, 0);
            return 0;
            (void)r;
        ',
    )) {
        push @$defs, '#define HAVE_GETRANDOM 1';
        print "found\n";
        $RANDFOUND = 1;
    }
    else {
        push @$defs, '#undef HAVE_GETRANDOM';
        print "none\n";
    }
    unlink $conf;
}

sub try_gettimeofday {
    my ($check, $long, $defs, $platform) = @_;
    my $msg = 'Checking for gettimeofday()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    print $msg, ' ..', '.'x$more, ' ';
    my $conf = gen_confh($defs);
    if ( check_lib(
        header   => $conf,
        lib      => 'c', # always do at least this
        ccflags  => '-I.',
        debug    => 0,
        function => '
            struct timeval tv;
            int r = gettimeofday(&tv, 0);
            return 0;
            (void)r;
        ',
    )) {
        push @$defs, '#define HAVE_GETTIMEOFDAY 1';
        print "found\n";
    }
    else {
        push @$defs, '#undef HAVE_GETTIMEOFDAY';
        print "none\n";
    }
    unlink $conf;
}

sub try_lstat {
    my ($check, $long, $defs, $platform) = @_;
    my $msg = 'Checking for lstat()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    print $msg, ' ..', '.'x$more, ' ';
    my $conf = gen_confh($defs);

    my $Werror = $WIN32 ? '-WX'  : '-Werror';
    my $lib    = $WIN32 ? 'ucrt' : 'c';

    if ( check_lib(
        header   => $conf,
        lib      => $lib, # always do at least this
        ccflags  => "-I. $Werror",
        debug    => 0,
        function => q{
            struct stat buf;
            int    rc, islink;
            rc     = lstat("foo", &buf);
            islink = ((buf.st_mode & S_IFMT) == S_IFLNK);
            return 0;
            (void)rc;
            (void)islink;
        },
    )) {
        push @$defs, '#define HAVE_LSTAT 1';
        print "found\n";
    }
    else {
        push @$defs, '#undef HAVE_LSTAT';
        print "none\n";
    }
    unlink $conf;
}

sub try_symlink {
    my ($check, $long, $defs, $platform) = @_;
    my $msg = 'Checking for symlink()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    print $msg, ' ..', '.'x$more, ' ';
    my $conf = gen_confh($defs);

    my $link = File::Spec->catfile( $TMPDIR, 'assertlibSYMLINK.h' );
    my $has_symlink = eval {
        symlink $conf, $link;
        return 1 if -l $link;
        return 0;
    };

    my $Werror = $WIN32 ? '-WX'  : '-Werror';
    my $lib    = $WIN32 ? 'ucrt' : 'c';

    if ( check_lib(
        header   => $conf,
        lib      => $lib, # always do at least this
        ccflags  => "-I. $Werror",
        debug    => 0,
        function => qq{
            struct stat buf;
            int    rc;
            rc = lstat("$link", &buf);
            if ((buf.st_mode & S_IFMT) == S_IFLNK)
                return 0;
            return 1;
            (void)rc;
        },
    )) {
        push @$defs, '#define HAVE_SYMLINK 1';
        print "found\n";
    }
    else {
        push @$defs, '#undef HAVE_SYMLINK';
        print "none\n";
    }
    unlink $conf, $link;
}

sub try_sa_len {
    my ($check, $long, $defs, $platform) = @_;
    my $msg = 'Checking for sa_len member';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    print $msg, ' ..', '.'x$more, ' ';
    if ($platform ne 'unix') {
        push @$defs, '#undef HAVE_SA_LEN';
        print "skip\n";
        return;
    }
    my $conf = gen_confh($defs);
    if ( check_lib(
        header   => $conf,
        lib      => 'c', # always do at least this
        ccflags  => '-I.',
        debug    => 0,
        function => q{
            struct ifreq ifr;
            unsigned char *r;
            r = (unsigned char*)&ifr.ifr_addr.sa_len;
            return 0;
            (void)r;
        },
    )) {
        push @$defs, '#define HAVE_SA_LEN 1';
        print "found\n";
    }
    else {
        push @$defs, '#undef HAVE_SA_LEN';
        print "none\n";
    }
    unlink $conf;
}

sub try_srwlock {
    my ($check, $long, $defs, $platform) = @_;
    my $msg = 'Checking for SRWLocks';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    print $msg, ' ..', '.'x$more, ' ';
    if ($platform ne 'alien' && $platform ne 'native') {
        push @$defs, '#undef HAVE_SRWLOCK';
        print "skip\n";
        return;
    }
    my ($conf, $fh) = gen_confh_fh($defs);
    print $fh join("\n", map {s/^\s+//; $_} split(/\n/, qq{
        typedef SRWLOCK uu_lock_t;
        typedef struct { uu_lock_t LOCK; } smem_t;
        static smem_t smem;
        #define UMTX_init   InitializeSRWLock(&smem.LOCK)
        #define UMTX_lock   AcquireSRWLockExclusive(&smem.LOCK)
        #define UMTX_unlock ReleaseSRWLockExclusive(&smem.LOCK)
    }));
    close $fh;
    if ( check_lib(
        header   => $conf,
        lib      => 'kernel32', # always do at least this
        ccflags  => '-I.',
        debug    => 0,
        function => q{
            UMTX_init;
            UMTX_lock;
            UMTX_unlock;
            return 0;
        },
    )) {
        push @$defs, '#define HAVE_SRWLOCK 1';
        print "found\n";
    }
    else {
        push @$defs, '#undef HAVE_SRWLOCK';
        print "none\n";
    }
    unlink $conf;
}

sub try_platform {
    my ($check, $long, $defs) = @_;
    my $msg = 'Checking platform';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long }
    my $more = $$long - $len;
    print $msg, ' ..', '.'x$more, ' '
        unless $check;

    my $rv;
    my $iscygwin  = $^O eq 'cygwin';
    my $iswin32   = $^O eq 'MSWin32';
    my $isnmake   = $Config{make} eq 'nmake';

    {
        if ( $iswin32 and $isnmake ) {
            $WIN32 = 1;
            $rv = 'native';
            last if $check;
            push @$defs, '#define USE_WIN32_NATIVE 1';
            push @$defs, '#undef USE_WIN32_ALIEN';
            push @$defs, '#undef USE_WIN32_CYGWIN';
        }
        elsif ( $iscygwin ) {
            $WIN32 = 0;
            $rv = 'cygwin';
            last if $check;
            push @$defs, '#undef USE_WIN32_NATIVE';
            push @$defs, '#undef USE_WIN32_ALIEN';
            push @$defs, '#define USE_WIN32_CYGWIN 1';
        }
        elsif ( $iswin32 ) {
            $rv = 'alien'; # strawberry
            last if $check;
            push @$defs, '#undef USE_WIN32_NATIVE';
            push @$defs, '#define USE_WIN32_ALIEN 1';
            push @$defs, '#undef USE_WIN32_CYGWIN';
        }
        else {
            $WIN32 = 0;
            $rv = 'unix';
            last if $check;
            push @$defs, '#undef USE_WIN32_NATIVE';
            push @$defs, '#undef USE_WIN32_ALIEN';
            push @$defs, '#undef USE_WIN32_CYGWIN';
        }
    }
    print $rv, "\n" unless $check;
    return $rv;
}

sub try_threads {
    my ($check, $long, $defs, $platform) = @_;
    my $msg = 'Checking for thread storage';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    # can we skip this if not -Duseithreads ?

    my ($conf1, $fh1) = gen_confh_fh($defs);
    print $fh1 q{
        int dec(void) {
          static __thread int foo = 3;
          return --foo;
        }
    };
    close $fh1;

    my ($conf2, $fh2) = gen_confh_fh($defs);
    print $fh2 q{
        int dec(void) {
          static __declspec(thread) int foo = 3;
          return --foo;
        }
    };
    close $fh2;

    my $Werror = $WIN32 ? '-WX'  : '-Werror';
    my $lib    = $WIN32 ? 'ucrt' : 'c';

    if ( check_lib(
        header   => $conf1,
        lib      => $lib, # always do at least this
        ccflags  => "-I. $Werror",
        debug    => 0,
        function => q{
            int rv;
            rv = dec();
            rv = dec();
            rv = dec();
            return rv;
        },
    )) {
        push @$defs, '#define TLS __thread';
        print $msg, ' ..', '.'x$more, ' __thread';
    }
    elsif ( check_lib(
        header   => $conf2,
        lib      => $lib, # always do at least this
        ccflags  => "-I. $Werror",
        debug    => 0,
        function => q{
            int rv;
            rv = dec();
            rv = dec();
            rv = dec();
            return rv;
        },
    )) {
        push @$defs, '#define TLS __declspec(thread)';
        print $msg, ' ..', '.'x$more, ' __declspec(thread)';
    }
    else {
        push @$defs, '#undef TLS';
        print $msg, ' ..', '.'x$more, ' none';
    }
    unlink $conf1, $conf2;
}

sub write_conf {
    my ($defines, $outfile) = @_;

    open my $fh, '>', $outfile
        or die 'open: ', $outfile, ": $!";

    print $fh "#ifndef ULIB__EUMM_H\n";
    print $fh "#define ULIB__EUMM_H\n";

    print $fh "$_\n"
        for @$defines;

    print $fh "#endif\n";
}
