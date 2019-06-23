use strict;
use warnings;
use utf8;
use feature qw/say/;

use Benchmark qw/cmpthese timethese/;

use Time::Strptime;
use Time::Strptime::Format;
use Time::Piece;
use DateTime::Format::Strptime;
use POSIX qw/tzset/;
use Time::Local qw/timelocal_nocheck/;
use Time::TZOffset qw/tzoffset tzoffset_as_seconds/;
use Time::Moment;
use POSIX::strptime;
use Test::More;

my $pattern = '%Y-%m-%d %H:%M:%S';
my $text    = '2014-01-01 01:23:45';

say "================ Perl5 info  ==============";
system $^X, '-V';
say "================ Module info ==============";
say "$_:\t",$_->VERSION for qw/DateTime DateTime::TimeZone DateTime::Locale DateTime::Format::Strptime Time::Local Time::TZOffset Time::Moment Time::Piece Time::Strptime/;
say "===========================================";

for my $time_zone (qw|GMT UTC Asia/Tokyo America/Whitehorse|) {
    local $ENV{TZ} = $time_zone;
    tzset();

    my $ts_parser = Time::Strptime::Format->new($pattern, { time_zone => $time_zone });
    my $dt_parser = DateTime::Format::Strptime->new(pattern => $pattern, time_zone => $time_zone);
    my $tp_parser = tzoffset(CORE::localtime) eq '+0000' ? Time::Piece->gmtime : Time::Piece->localtime;

    subtest "${time_zone}(@{[ tzoffset(CORE::localtime) ]})" => sub {
        my $dt = $dt_parser->parse_datetime($text);
        my $tp = $tp_parser->strptime($text, $pattern);
        my $tm = Time::Moment->from_string($text.tzoffset(CORE::localtime), lenient => 1);
        is_deeply(($ts_parser->parse($text))[0], timelocal_nocheck(POSIX::strptime($text, $pattern)));
        is_deeply([$ts_parser->parse($text)],    [$dt->epoch, $dt->offset]);
        is_deeply([$ts_parser->parse($text)],    [$tp->epoch, $tp->tzoffset->seconds]);
        is_deeply([$ts_parser->parse($text)],    [$tm->epoch, $tm->offset * 60]);
    };

    my $tzoffset = tzoffset(CORE::localtime);
    cmpthese timethese -10 => +{
        # 'dt(cached)' => sub { $dt_parser->parse_datetime($text) },
        'pt'         => sub { timelocal_nocheck(POSIX::strptime($text, $pattern)) },
        'ts(cached)' => sub { $ts_parser->parse($text) },
        'tp(cached)' => sub { $tp_parser->strptime($text, $pattern) },
        # 'dt'         => sub { DateTime::Format::Strptime->new(pattern => $pattern, time_zone => $time_zone)->parse_datetime($text) },
        # 'ts'         => sub { Time::Strptime::Format->new($pattern, { time_zone => $time_zone })->parse($text)                                                  },
        'tp'         => sub { Time::Piece->localtime->strptime($text, $pattern) },
        'tm'         => sub { Time::Moment->from_string($text.$tzoffset, lenient => 1) },
    };
}

done_testing;
__END__
================ Perl5 info  ==============
Summary of my perl5 (revision 5 version 28 subversion 0) configuration:
   
  Platform:
    osname=darwin
    osvers=16.7.0
    archname=darwin-2level
    uname='darwin karupanrurasmbp 16.7.0 darwin kernel version 16.7.0: fri apr 27 17:59:46 pdt 2018; root:xnu-3789.73.13~1release_x86_64 x86_64 '
    config_args='-Dprefix=/Users/karupanerura/.anyenv/envs/plenv/versions/5.28 -de -Dversiononly -A'eval:scriptdir=/Users/karupanerura/.anyenv/envs/plenv/versions/5.28/bin''
    hint=recommended
    useposix=true
    d_sigaction=define
    useithreads=undef
    usemultiplicity=undef
    use64bitint=define
    use64bitall=define
    uselongdouble=undef
    usemymalloc=n
    default_inc_excludes_dot=define
    bincompat5005=undef
  Compiler:
    cc='cc'
    ccflags ='-fno-common -DPERL_DARWIN -mmacosx-version-min=10.12 -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include -DPERL_USE_SAFE_PUTENV'
    optimize='-O3'
    cppflags='-fno-common -DPERL_DARWIN -mmacosx-version-min=10.12 -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include'
    ccversion=''
    gccversion='4.2.1 Compatible Apple LLVM 8.1.0 (clang-802.0.42)'
    gccosandvers=''
    intsize=4
    longsize=8
    ptrsize=8
    doublesize=8
    byteorder=12345678
    doublekind=3
    d_longlong=define
    longlongsize=8
    d_longdbl=define
    longdblsize=16
    longdblkind=3
    ivtype='long'
    ivsize=8
    nvtype='double'
    nvsize=8
    Off_t='off_t'
    lseeksize=8
    alignbytes=8
    prototype=define
  Linker and Libraries:
    ld='cc'
    ldflags =' -mmacosx-version-min=10.12 -fstack-protector-strong -L/usr/local/lib'
    libpth=/usr/local/lib /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/../lib/clang/8.1.0/lib /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib /usr/lib
    libs=-lpthread -lgdbm -ldbm -ldl -lm -lutil -lc
    perllibs=-lpthread -ldl -lm -lutil -lc
    libc=
    so=dylib
    useshrplib=false
    libperl=libperl.a
    gnulibc_version=''
  Dynamic Linking:
    dlsrc=dl_dlopen.xs
    dlext=bundle
    d_dlsymun=undef
    ccdlflags=' '
    cccdlflags=' '
    lddlflags=' -mmacosx-version-min=10.12 -bundle -undefined dynamic_lookup -L/usr/local/lib -fstack-protector-strong'


Characteristics of this binary (from libperl): 
  Compile-time options:
    HAS_TIMES
    PERLIO_LAYERS
    PERL_COPY_ON_WRITE
    PERL_DONT_CREATE_GVSV
    PERL_MALLOC_WRAP
    PERL_OP_PARENT
    PERL_PRESERVE_IVUV
    PERL_USE_SAFE_PUTENV
    USE_64_BIT_ALL
    USE_64_BIT_INT
    USE_LARGE_FILES
    USE_LOCALE
    USE_LOCALE_COLLATE
    USE_LOCALE_CTYPE
    USE_LOCALE_NUMERIC
    USE_LOCALE_TIME
    USE_PERLIO
    USE_PERL_ATOF
  Locally applied patches:
    Devel::PatchPerl 1.48
  Built under darwin
  Compiled at Jul  4 2018 00:57:42
  %ENV:
    PERL_CPANM_OPT="--mirror file:///Users/karupanerura/.minicpan --prompt --cascade-search --mirror http://ftp.ring.gr.jp/pub/lang/perl/CPAN/ --mirror http://cpan.metacpan.org/"
  @INC:
    /Users/karupanerura/.anyenv/envs/plenv/versions/5.28/lib/perl5/site_perl/5.28.0/darwin-2level
    /Users/karupanerura/.anyenv/envs/plenv/versions/5.28/lib/perl5/site_perl/5.28.0
    /Users/karupanerura/.anyenv/envs/plenv/versions/5.28/lib/perl5/5.28.0/darwin-2level
    /Users/karupanerura/.anyenv/envs/plenv/versions/5.28/lib/perl5/5.28.0
================ Module info ==============
DateTime:	1.49
DateTime::TimeZone:	2.19
DateTime::Locale:	1.22
DateTime::Format::Strptime:	1.75
Time::Local:	1.28
Time::TZOffset:	0.04
Time::Moment:	0.44
Time::Piece:	1.3204
Time::Strptime:	1.03
===========================================
# Subtest: GMT(+0000)
    ok 1
    ok 2
    ok 3
    ok 4
    1..4
ok 1 - GMT(+0000)
Benchmark: running pt, tm, tp, tp(cached), ts(cached) for at least 10 CPU seconds...
        pt: 11 wallclock secs (10.41 usr +  0.01 sys = 10.42 CPU) @ 297345.59/s (n=3098341)
        tm: 10 wallclock secs (10.17 usr +  0.01 sys = 10.18 CPU) @ 2481673.28/s (n=25263434)
        tp: 10 wallclock secs (10.52 usr +  0.01 sys = 10.53 CPU) @ 56390.98/s (n=593797)
tp(cached): 11 wallclock secs (10.53 usr +  0.01 sys = 10.54 CPU) @ 80838.24/s (n=852035)
ts(cached): 11 wallclock secs (10.60 usr +  0.01 sys = 10.61 CPU) @ 267686.15/s (n=2840150)
                Rate         tp tp(cached) ts(cached)         pt         tm
tp           56391/s         --       -30%       -79%       -81%       -98%
tp(cached)   80838/s        43%         --       -70%       -73%       -97%
ts(cached)  267686/s       375%       231%         --       -10%       -89%
pt          297346/s       427%       268%        11%         --       -88%
tm         2481673/s      4301%      2970%       827%       735%         --
# Subtest: UTC(+0000)
    ok 1
    ok 2
    ok 3
    ok 4
    1..4
ok 2 - UTC(+0000)
Benchmark: running pt, tm, tp, tp(cached), ts(cached) for at least 10 CPU seconds...
        pt: 11 wallclock secs (10.57 usr +  0.01 sys = 10.58 CPU) @ 303926.37/s (n=3215541)
        tm: 11 wallclock secs (10.64 usr +  0.00 sys = 10.64 CPU) @ 2444909.12/s (n=26013833)
        tp: 11 wallclock secs (10.47 usr +  0.02 sys = 10.49 CPU) @ 55906.86/s (n=586463)
tp(cached): 12 wallclock secs (11.68 usr +  0.07 sys = 11.75 CPU) @ 73205.11/s (n=860160)
ts(cached): 11 wallclock secs (10.60 usr +  0.09 sys = 10.69 CPU) @ 234198.13/s (n=2503578)
                Rate         tp tp(cached) ts(cached)         pt         tm
tp           55907/s         --       -24%       -76%       -82%       -98%
tp(cached)   73205/s        31%         --       -69%       -76%       -97%
ts(cached)  234198/s       319%       220%         --       -23%       -90%
pt          303926/s       444%       315%        30%         --       -88%
tm         2444909/s      4273%      3240%       944%       704%         --
# Subtest: Asia/Tokyo(+0900)
    ok 1
    ok 2
    ok 3
    ok 4
    1..4
ok 3 - Asia/Tokyo(+0900)
Benchmark: running pt, tm, tp, tp(cached), ts(cached) for at least 10 CPU seconds...
        pt: 10 wallclock secs (10.29 usr +  0.05 sys = 10.34 CPU) @ 147048.07/s (n=1520477)
        tm: 10 wallclock secs (10.00 usr +  0.03 sys = 10.03 CPU) @ 2344311.67/s (n=23513446)
        tp: 10 wallclock secs (10.15 usr +  0.02 sys = 10.17 CPU) @ 44565.39/s (n=453230)
tp(cached): 11 wallclock secs (10.41 usr +  0.06 sys = 10.47 CPU) @ 50136.29/s (n=524927)
ts(cached): 10 wallclock secs (10.73 usr +  0.07 sys = 10.80 CPU) @ 114871.48/s (n=1240612)
                Rate         tp tp(cached) ts(cached)         pt         tm
tp           44565/s         --       -11%       -61%       -70%       -98%
tp(cached)   50136/s        13%         --       -56%       -66%       -98%
ts(cached)  114871/s       158%       129%         --       -22%       -95%
pt          147048/s       230%       193%        28%         --       -94%
tm         2344312/s      5160%      4576%      1941%      1494%         --
# Subtest: America/Whitehorse(-0700)
    ok 1
    ok 2
    ok 3
    not ok 4
    1..4
not ok 4 - America/Whitehorse(-0700)
Benchmark: running pt, tm, tp, tp(cached), ts(cached) for at least 10 CPU seconds...
        pt: 10 wallclock secs (10.17 usr +  0.05 sys = 10.22 CPU) @ 147409.78/s (n=1506528)
        tm: 10 wallclock secs (10.37 usr +  0.04 sys = 10.41 CPU) @ 2294469.55/s (n=23885428)
        tp: 11 wallclock secs ( 9.97 usr +  0.05 sys = 10.02 CPU) @ 42148.30/s (n=422326)
tp(cached): 12 wallclock secs (11.04 usr +  0.08 sys = 11.12 CPU) @ 48750.72/s (n=542108)
ts(cached): 11 wallclock secs ( 9.95 usr +  0.07 sys = 10.02 CPU) @ 100110.68/s (n=1003109)
                Rate         tp tp(cached) ts(cached)         pt         tm
tp           42148/s         --       -14%       -58%       -71%       -98%
tp(cached)   48751/s        16%         --       -51%       -67%       -98%
ts(cached)  100111/s       138%       105%         --       -32%       -96%
pt          147410/s       250%       202%        47%         --       -94%
tm         2294470/s      5344%      4607%      2192%      1457%         --
1..4
