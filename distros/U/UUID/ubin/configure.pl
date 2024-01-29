# run with -l switch

#
# check a bunch of stuff.
# write #define/#undef to file given in ARGV[0].
#

use strict;
use warnings;
use Config;
use Devel::CheckLib;

my ($out, $flagfile) = @ARGV;
my $conf  = [];
my $flags = [];

generate_conf($conf, $flags);
write_conf   ($conf, $out);

exit 0;

sub generate_conf {
    my ($defines, $flags) = @_;
    my $longest = 0;

    # dont use the uuidd.
    # it *should* be safe to though, if you really insist.
    #push @$defines, '#define USE_UUID 1';
    push @$defines, '#undef USE_UUIDD';

    # if lencheck is 1, \$longest is longest so far. sub is expected to
    #   update it if it has one longer and skip actual test.
    #
    # if lencheck is 0, \$longest contains global longest. sub is expected
    #   to use that when printing and to run the test.

    for my $check ( 1, 0 ) {
        try_headers($check, \$longest, $defines, qw(
            HAVE_INTTYPES_H      inttypes.h
            HAVE_NETINET_IN_H    netinet/in.h
            HAVE_NET_IF_DL_H     net/if_dl.h
            HAVE_NET_IF_H        net/if.h
            HAVE_STDLIB_H        stdlib.h
            HAVE_SYS_FILE_H      sys/file.h
            HAVE_SYS_IOCTL_H     sys/ioctl.h
            HAVE_SYS_RANDOM_H    sys/random.h
            HAVE_SYS_RESOURCE_H  sys/resource.h
            HAVE_SYS_SOCKET_H    sys/socket.h
            HAVE_SYS_SOCKIO_H    sys/sockio.h
            HAVE_SYS_SYSCALL_H   sys/syscall.h
            HAVE_SYS_TIME_H      sys/time.h
            HAVE_SYS_UN_H        sys/un.h
            HAVE_SYS_WAIT_H      sys/wait.h
            HAVE_UNISTD_H        unistd.h
            HAVE_WINDOWS_H       Windows.h
        ));

        try_getdtablesize  ($check, \$longest, $defines);
        try_getentropy     ($check, \$longest, $defines);
        try_getrandom      ($check, \$longest, $defines);
        try_getrlimit      ($check, \$longest, $defines);
        try_jrand48        ($check, \$longest, $defines);
        try_srandom        ($check, \$longest, $defines);
        try_sysconf        ($check, \$longest, $defines);

        try_sa_len         ($check, \$longest, $defines);

        # win32 native if on windows but not under some
        # sort of unix environ. i.e. native.
        try_win32_native   ($check, \$longest, $defines);
    }
#
# these havent been handled yet. do they need to be?
#
#   SIZEOF_INT
#   SIZEOF_LONG
#   SIZEOF_LONG_LONG
#   SIZEOF_SHORT
#
#   TLS
#
}

sub try_headers {
    my ($check, $long, $defs, %try) = @_;
    map {
        check_header($check, $long, $defs, $_, $try{$_})
    } sort keys %try;
}

sub check_header {
    my ($check, $long,  $defs, $def, $hdr) = @_;
    my $msg = join ' ', 'Checking', $hdr;
    my $len = length $msg;
    if ($check) {
        $$long = $len if $len > $$long;
        return;
    }
    my $more = $$long - $len;
    if ( check_lib(
        header => $hdr,
        #lib   => 'c',   # because not linking here.. duh!
        debug  => 0,
    )) {
        push @$defs, "#define $def 1";
        print $msg, ' ..', '.'x$more, ' found';
    }
    else {
        push @$defs, "#undef $def";
        print $msg, ' ..', '.'x$more, ' missing';
    }
}

sub try_getdtablesize {
    my ($check, $long, $defs) = @_;
    my $msg = join ' ', 'Checking getdtablesize()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    if ( check_lib(
        header   => [qw(unistd.h)],
        lib      => 'c', # always do at least this
        debug    => 0,
        function => q{
            int r;
            r = getdtablesize();
            return 0;
            (void)r;
        },
    )) {
        push @$defs, '#define HAVE_GETDTABLESIZE 1';
        print $msg, ' ..', '.'x$more, ' found';
    }
    else {
        push @$defs, '#undef HAVE_GETDTABLESIZE';
        print $msg, ' ..', '.'x$more, ' missing';
    }
}

sub try_getentropy {
    my ($check, $long, $defs) = @_;
    my $msg = join ' ', 'Checking getentropy()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    if ( check_lib(
        header   => [qw(unistd.h)],
        lib      => 'c', # always do at least this
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
}

sub try_getrandom {
    my ($check, $long, $defs) = @_;
    my $msg = join ' ', 'Checking getrandom()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    if ( check_lib(
        header   => [qw(sys/random.h)],
        lib      => 'c', # always do at least this
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
}

sub try_getrlimit {
    my ($check, $long, $defs) = @_;
    my $msg = join ' ', 'Checking getrlimit()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    if ( check_lib(
        header   => [qw(sys/resource.h)],
        lib      => 'c', # always do at least this
        debug    => 0,
        function => '
            struct rlimit rl;
            int r;
            r = getrlimit(RLIMIT_NOFILE, &rl);
            return 0;
            (void)r;
        ',
    )) {
        push @$defs, '#define HAVE_GETRLIMIT 1';
        print $msg, ' ..', '.'x$more, ' found';
    }
    else {
        push @$defs, '#undef HAVE_GETRLIMIT';
        print $msg, ' ..', '.'x$more, ' missing';
    }
}

sub try_jrand48 {
    my ($check, $long, $defs) = @_;
    my $msg = join ' ', 'Checking jrand48()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    if ( check_lib(
        header   => [qw(stdlib.h)],
        lib      => 'c', # always do at least this
        debug    => 0,
        function => q{
            unsigned short seed[3];
            long int r;
            r = jrand48(seed);
            return 0;
            (void)r;
        },
    )) {
        push @$defs, '#define HAVE_JRAND48 1';
        print $msg, ' ..', '.'x$more, ' found';
    }
    else {
        push @$defs, '#undef HAVE_JRAND48';
        print $msg, ' ..', '.'x$more, ' missing';
    }
}

sub try_srandom {
    my ($check, $long, $defs) = @_;
    my $msg = join ' ', 'Checking srandom()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    if ( check_lib(
        header   => [qw(stdlib.h)],
        lib      => 'c', # always do at least this
        debug    => 0,
        function => q{
            unsigned int s = 8675309;
            srandom(s);
            return 0;
        },
    )) {
        push @$defs, '#define HAVE_SRANDOM 1';
        print $msg, ' ..', '.'x$more, ' found';
    }
    else {
        push @$defs, '#undef HAVE_SRANDOM';
        print $msg, ' ..', '.'x$more, ' missing';
    }
}

sub try_sysconf {
    my ($check, $long, $defs) = @_;
    my $msg = join ' ', 'Checking sysconf()';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    if ( check_lib(
        header   => [qw(unistd.h)],
        lib      => 'c', # always do at least this
        debug    => 0,
        function => q{
            long r;
            r = sysconf(_SC_OPEN_MAX);
            return 0;
            (void)r;
        },
    )) {
        push @$defs, '#define HAVE_SYSCONF 1';
        print $msg, ' ..', '.'x$more, ' found';
    }
    else {
        push @$defs, '#undef HAVE_SYSCONF';
        print $msg, ' ..', '.'x$more, ' missing';
    }
}

sub try_sa_len {
    my ($check, $long, $defs) = @_;
    my $msg = join ' ', 'Checking sa_len member';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    if ( check_lib(
        header   => [qw(net/if.h stdio.h err.h)],
        lib      => 'c', # always do at least this
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
}

sub try_win32_native {
    my ($check, $long, $defs) = @_;
    my $msg = join ' ', 'Checking win32 native';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;

    my $iswin32   = $^O eq 'MSWin32'; # need Cygwin too?
    my $iswindows = grep {/define HAVE_WINDOWS_H/} @$defs;
    my $isnmake   = $Config{make} eq 'nmake';

    if (
        $iswin32 and $iswindows and $isnmake
    ) {
        push @$defs, '#define USE_WIN32_NATIVE 1';
        print $msg, ' ..', '.'x$more, ' found';
    }
    else {
        push @$defs, '#undef USE_WIN32_NATIVE';
        print $msg, ' ..', '.'x$more, ' missing';
    }
}

sub write_conf {
    my ($defines, $outfile) = @_;

    open my $fh, '>', $outfile
        or die 'open: ', $outfile, ": $!";

    print $fh '#ifndef EUMM_H';
    print $fh '#define EUMM_H';

    print $fh $_
        for @$defines;

    print $fh '#endif  /* EUMM_H */';
}
