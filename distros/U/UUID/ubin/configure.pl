# run with -l switch

#
# check a bunch of stuff.
# write #define/#undef to file given in ARGV[0].
# now also writes #include's too.
#

use strict;
use warnings;
use Config;
use List::Util;
use File::Temp ();
use Devel::CheckLib;

my ($out, $flagfile) = @ARGV;
my $conf  = [];
my $flags = [];
my $WIN32 = 0;  # native

generate_conf($conf, $flags);
write_conf   ($conf, $out);

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
        try_win32_native ($check, \$longest, $defines);

        try_headers($check, \$longest, $defines, qw(
            -HAVE_WINDOWS_H       Windows.h
            HAVE_WINSOCK2_H      winsock2.h
            HAVE_IPHLPAPI_H      iphlpapi.h
            HAVE_CTYPE_H         ctype.h
            HAVE_ERR_H           err.h
            HAVE_ERRNO_H         errno.h
            -HAVE_FCNTL_H         fcntl.h
            HAVE_INTTYPES_H      inttypes.h
            HAVE_IO_H            io.h
            HAVE_NETINET_IN_H    netinet/in.h
            HAVE_NET_IF_DL_H     net/if_dl.h
            HAVE_NET_IF_H        net/if.h
            HAVE_PROCESS_H       process.h
            HAVE_STDINT_H        stdint.h
            HAVE_STDIO_H         stdio.h
            HAVE_STDLIB_H        stdlib.h
            HAVE_STRING_H        string.h
            HAVE_SYS_FILE_H      sys/file.h
            HAVE_SYS_IOCTL_H     sys/ioctl.h
            -HAVE_SYS_RANDOM_H    sys/random.h
            HAVE_SYS_RESOURCE_H  sys/resource.h
            HAVE_SYS_SOCKET_H    sys/socket.h
            HAVE_SYS_SOCKIO_H    sys/sockio.h
            HAVE_SYS_STAT_H      sys/stat.h
            -HAVE_SYS_TIME_H      sys/time.h
            HAVE_SYS_TYPES_H     sys/types.h
            HAVE_SYS_WAIT_H      sys/wait.h
            -HAVE_TIME_H          time.h
            HAVE_UNISTD_H        unistd.h
        ));

        #try_getentropy   ($check, \$longest, $defines);
        #try_getrandom    ($check, \$longest, $defines);
        try_lstat        ($check, \$longest, $defines);
        try_sa_len       ($check, \$longest, $defines);
        try_symlink      ($check, \$longest, $defines);
        #try_threads      ($check, \$longest, $defines);
    }
}

sub try_headers {
    my ($check, $long, $defs, @try) = @_;
    for ( List::Util::pairs(@try) ) {
        my ($key, $val) = @$_;
        next if $key =~ /^-/;
        check_header($check, $long, $defs, $key, $val);
    }
}

sub check_header {
    my ($check, $long, $defs, $def, $hdr) = @_;
    my $msg = join ' ', 'Checking', $hdr;
    my $len = length $msg;
    if ($check) {
        $$long = $len if $len > $$long;
        return;
    }
    my $more = $$long - $len;

    my ($conf, $fh) = gen_confh_fh($defs);
    print $fh join("\n", map {s/^\s+//; $_} split(/\n/, qq{
        #include <${hdr}>
    }));
    close $fh;

    my $win32permit = 1;
    $win32permit = 0 if !$WIN32 && $def =~ /WINSOCK/;
    $win32permit = 0 if !$WIN32 && $def =~ /IPHLPAPI/;

    if ( $win32permit && check_lib(
        header  => $conf,
        #lib    => 'c',   # because not linking here.. duh!
        ccflags => '-I.',
        debug   => 0,
    )) {
        push @$defs, "#define $def 1";
        push @$defs, "#include <${hdr}>";
        print $msg, ' ..', '.'x$more, ' found';
    }
    else {
        push @$defs, "#undef $def";
        print $msg, ' ..', '.'x$more, ' missing';
    }
    unlink $conf;
}

sub gen_confh {
    my ($defs) = @_;
    my ($fh, $fname) = File::Temp::tempfile(
        'assertconfXXXXXXXX', SUFFIX => '.h', UNLINK => 0
    );
    print $fh $_ for @$defs;
    close $fh;
    return $fname;
}

sub gen_confh_fh {
    my ($defs) = @_;
    my ($fh, $fname) = File::Temp::tempfile(
        'assertconfXXXXXXXX', SUFFIX => '.h', UNLINK => 0
    );
    print $fh $_ for @$defs;
    return $fname, $fh;
}

sub try_getentropy {
    my ($check, $long, $defs) = @_;
    my $msg = 'Checking getentropy()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
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
        print $msg, ' ..', '.'x$more, ' found';
    }
    else {
        push @$defs, '#undef HAVE_GETENTROPY';
        print $msg, ' ..', '.'x$more, ' missing';
    }
    unlink $conf;
}

sub try_getrandom {
    my ($check, $long, $defs) = @_;
    my $msg = 'Checking getrandom()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
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
        print $msg, ' ..', '.'x$more, ' found';
    }
    else {
        push @$defs, '#undef HAVE_GETRANDOM';
        print $msg, ' ..', '.'x$more, ' missing';
    }
    unlink $conf;
}

sub try_lstat {
    my ($check, $long, $defs) = @_;
    my $msg = 'Checking lstat()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
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
        print $msg, ' ..', '.'x$more, ' found';
    }
    else {
        push @$defs, '#undef HAVE_LSTAT';
        print $msg, ' ..', '.'x$more, ' missing';
    }
    unlink $conf;
}

sub try_symlink {
    my ($check, $long, $defs) = @_;
    my $msg = 'Checking symlink()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    my $conf = gen_confh($defs);

    my $has_symlink = eval {
        symlink $conf, 'assertlibSYMLINK.h';
        return 1 if -l 'assertlibSYMLINK.h';
        return 0;
    };

    my $Werror = $WIN32 ? '-WX'  : '-Werror';
    my $lib    = $WIN32 ? 'ucrt' : 'c';

    if ( check_lib(
        header   => $conf,
        lib      => $lib, # always do at least this
        ccflags  => "-I. $Werror",
        debug    => 0,
        function => q{
            struct stat buf;
            int    rc;
            rc = lstat("assertlibSYMLINK.h", &buf);
            if ((buf.st_mode & S_IFMT) == S_IFLNK)
                return 0;
            return 1;
            (void)rc;
        },
    )) {
        push @$defs, '#define HAVE_SYMLINK 1';
        print $msg, ' ..', '.'x$more, ' found';
    }
    else {
        push @$defs, '#undef HAVE_SYMLINK';
        print $msg, ' ..', '.'x$more, ' missing';
    }
    unlink $conf, 'assertlibSYMLINK.h';
}

sub try_sa_len {
    my ($check, $long, $defs) = @_;
    my $msg = 'Checking sa_len member';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
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
        print $msg, ' ..', '.'x$more, ' found';
    }
    else {
        push @$defs, '#undef HAVE_SA_LEN';
        print $msg, ' ..', '.'x$more, ' missing';
    }
    unlink $conf;
}

sub try_win32_native {
    my ($check, $long, $defs) = @_;
    my $msg = 'Checking win32 native';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;

    my $iswin32   = $^O eq 'MSWin32'; # need Cygwin too?
    my $isnmake   = $Config{make} eq 'nmake';

    if ( $iswin32 and $isnmake ) {
        push @$defs, '#define USE_WIN32_NATIVE 1';
        print $msg, ' ..', '.'x$more, ' found';
        $WIN32 = 1;
    }
    else {
        push @$defs, '#undef USE_WIN32_NATIVE';
        print $msg, ' ..', '.'x$more, ' missing';
        $WIN32 = 0;
    }
}

sub try_threads {
    my ($check, $long, $defs) = @_;
    my $msg = 'Checking thread storage';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    # can we skip this if not -Dusethreads ?

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

    print $fh '#ifndef UU_EUMM_H';
    print $fh '#define UU_EUMM_H';

    print $fh $_
        for @$defines;

    print $fh '#endif';
}
