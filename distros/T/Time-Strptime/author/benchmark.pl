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
use Time::Local qw/timelocal/;
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
        is_deeply(($ts_parser->parse($text))[0], timelocal(POSIX::strptime($text, $pattern)));
        is_deeply([$ts_parser->parse($text)],    [$dt->epoch, $dt->offset]);
        is_deeply([$ts_parser->parse($text)],    [$tp->epoch, $tp->tzoffset->seconds]);
        is_deeply([$ts_parser->parse($text)],    [$tm->epoch, $tm->offset * 60]);
    };

    my $tzoffset = tzoffset(CORE::localtime);
    cmpthese timethese -10 => +{
        'dt(cached)' => sub { $dt_parser->parse_datetime($text) },
        'pt'         => sub { timelocal(POSIX::strptime($text, $pattern)) },
        'ts(cached)' => sub { $ts_parser->parse($text) },
        'tp(cached)' => sub { $tp_parser->strptime($text, $pattern) },
        'dt'         => sub { DateTime::Format::Strptime->new(pattern => $pattern, time_zone => $time_zone)->parse_datetime($text) },
        'ts'         => sub { Time::Strptime::Format->new($pattern, { time_zone => $time_zone })->parse($text)                                                  },
        'tp'         => sub { Time::Piece->localtime->strptime($text, $pattern) },
        'tm'         => sub { Time::Moment->from_string($text.$tzoffset, lenient => 1) },
    };
}

done_testing;
__END__
================ Perl5 info  ==============
Summary of my perl5 (revision 5 version 22 subversion 1) configuration:
   
  Platform:
    osname=darwin, osvers=14.5.0, archname=darwin-2level
    uname='darwin karupanerura-mbp.local 14.5.0 darwin kernel version 14.5.0: tue sep 1 21:23:09 pdt 2015; root:xnu-2782.50.1~1release_x86_64 x86_64 '
    config_args='-Dprefix=/Users/karupanerura/.anyenv/envs/plenv/versions/5.22 -de -Dusedevel -A'eval:scriptdir=/Users/karupanerura/.anyenv/envs/plenv/versions/5.22/bin''
    hint=recommended, useposix=true, d_sigaction=define
    useithreads=undef, usemultiplicity=undef
    use64bitint=define, use64bitall=define, uselongdouble=undef
    usemymalloc=n, bincompat5005=undef
  Compiler:
    cc='cc', ccflags ='-fno-common -DPERL_DARWIN -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include',
    optimize='-O3',
    cppflags='-fno-common -DPERL_DARWIN -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include'
    ccversion='', gccversion='4.2.1 Compatible Apple LLVM 7.0.2 (clang-700.1.81)', gccosandvers=''
    intsize=4, longsize=8, ptrsize=8, doublesize=8, byteorder=12345678, doublekind=3
    d_longlong=define, longlongsize=8, d_longdbl=define, longdblsize=16, longdblkind=3
    ivtype='long', ivsize=8, nvtype='double', nvsize=8, Off_t='off_t', lseeksize=8
    alignbytes=8, prototype=define
  Linker and Libraries:
    ld='env MACOSX_DEPLOYMENT_TARGET=10.3 cc', ldflags =' -fstack-protector-strong -L/usr/local/lib'
    libpth=/usr/local/lib /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/../lib/clang/7.0.2/lib /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib /usr/lib
    libs=-lpthread -lgdbm -ldbm -ldl -lm -lutil -lc
    perllibs=-lpthread -ldl -lm -lutil -lc
    libc=, so=dylib, useshrplib=false, libperl=libperl.a
    gnulibc_version=''
  Dynamic Linking:
    dlsrc=dl_dlopen.xs, dlext=bundle, d_dlsymun=undef, ccdlflags=' '
    cccdlflags=' ', lddlflags=' -bundle -undefined dynamic_lookup -L/usr/local/lib -fstack-protector-strong'


Characteristics of this binary (from libperl): 
  Compile-time options: HAS_TIMES PERLIO_LAYERS PERL_DONT_CREATE_GVSV
                        PERL_HASH_FUNC_ONE_AT_A_TIME_HARD PERL_MALLOC_WRAP
                        PERL_NEW_COPY_ON_WRITE PERL_PRESERVE_IVUV
                        PERL_USE_DEVEL USE_64_BIT_ALL USE_64_BIT_INT
                        USE_LARGE_FILES USE_LOCALE USE_LOCALE_COLLATE
                        USE_LOCALE_CTYPE USE_LOCALE_NUMERIC USE_LOCALE_TIME
                        USE_PERLIO USE_PERL_ATOF
  Locally applied patches:
	Devel::PatchPerl 1.38
  Built under darwin
  Compiled at Dec 14 2015 13:05:08
  @INC:
    /Users/karupanerura/.anyenv/envs/plenv/versions/5.22/lib/perl5/site_perl/5.22.1/darwin-2level
    /Users/karupanerura/.anyenv/envs/plenv/versions/5.22/lib/perl5/site_perl/5.22.1
    /Users/karupanerura/.anyenv/envs/plenv/versions/5.22/lib/perl5/5.22.1/darwin-2level
    /Users/karupanerura/.anyenv/envs/plenv/versions/5.22/lib/perl5/5.22.1
    .
================ Module info ==============
DateTime:	1.21
DateTime::TimeZone:	1.94
DateTime::Locale:	1.02
DateTime::Format::Strptime:	1.62
Time::Local:	1.2300
Time::TZOffset:	0.04
Time::Moment:	0.37
Time::Piece:	1.29
Time::Strptime:	0.03
===========================================
    # Subtest: GMT(+0000)
    ok 1
    ok 2
    ok 3
    ok 4
    1..4
ok 1 - GMT(+0000)
Benchmark: running dt, dt(cached), pt, tm, tp, tp(cached), ts, ts(cached) for at least 10 CPU seconds...
        dt: 11 wallclock secs (10.53 usr +  0.00 sys = 10.53 CPU) @ 2350.24/s (n=24748)
dt(cached): 10 wallclock secs (10.42 usr +  0.01 sys = 10.43 CPU) @ 8005.27/s (n=83495)
        pt: 11 wallclock secs (10.43 usr +  0.01 sys = 10.44 CPU) @ 200603.64/s (n=2094302)
        tm: 11 wallclock secs (10.00 usr +  0.01 sys = 10.01 CPU) @ 1921666.53/s (n=19235882)
        tp: 11 wallclock secs (10.30 usr +  0.00 sys = 10.30 CPU) @ 112851.26/s (n=1162368)
tp(cached): 10 wallclock secs (10.72 usr +  0.01 sys = 10.73 CPU) @ 283407.74/s (n=3040965)
        ts:  9 wallclock secs (10.53 usr +  0.01 sys = 10.54 CPU) @ 3886.05/s (n=40959)
ts(cached): 11 wallclock secs (10.52 usr +  0.01 sys = 10.53 CPU) @ 173625.07/s (n=1828272)
                Rate     dt     ts dt(cached)    tp ts(cached)   pt tp(cached)    tm
dt            2350/s     --   -40%       -71%  -98%       -99% -99%       -99% -100%
ts            3886/s    65%     --       -51%  -97%       -98% -98%       -99% -100%
dt(cached)    8005/s   241%   106%         --  -93%       -95% -96%       -97% -100%
tp          112851/s  4702%  2804%      1310%    --       -35% -44%       -60%  -94%
ts(cached)  173625/s  7288%  4368%      2069%   54%         -- -13%       -39%  -91%
pt          200604/s  8435%  5062%      2406%   78%        16%   --       -29%  -90%
tp(cached)  283408/s 11959%  7193%      3440%  151%        63%  41%         --  -85%
tm         1921667/s 81665% 49350%     23905% 1603%      1007% 858%       578%    --
    # Subtest: UTC(+0000)
    ok 1
    ok 2
    ok 3
    ok 4
    1..4
ok 2 - UTC(+0000)
Benchmark: running dt, dt(cached), pt, tm, tp, tp(cached), ts, ts(cached) for at least 10 CPU seconds...
        dt: 11 wallclock secs (10.57 usr +  0.00 sys = 10.57 CPU) @ 2333.40/s (n=24664)
dt(cached): 10 wallclock secs (10.51 usr +  0.00 sys = 10.51 CPU) @ 7991.44/s (n=83990)
        pt: 11 wallclock secs (10.62 usr +  0.01 sys = 10.63 CPU) @ 198514.11/s (n=2110205)
        tm: 11 wallclock secs (10.31 usr +  0.01 sys = 10.32 CPU) @ 1942108.82/s (n=20042563)
        tp:  9 wallclock secs (10.51 usr +  0.00 sys = 10.51 CPU) @ 112625.69/s (n=1183696)
tp(cached): 11 wallclock secs (10.30 usr +  0.01 sys = 10.31 CPU) @ 286277.30/s (n=2951519)
        ts: 10 wallclock secs (10.59 usr +  0.01 sys = 10.60 CPU) @ 3864.06/s (n=40959)
ts(cached): 11 wallclock secs (10.08 usr +  0.00 sys = 10.08 CPU) @ 172403.08/s (n=1737823)
                Rate     dt     ts dt(cached)    tp ts(cached)   pt tp(cached)    tm
dt            2333/s     --   -40%       -71%  -98%       -99% -99%       -99% -100%
ts            3864/s    66%     --       -52%  -97%       -98% -98%       -99% -100%
dt(cached)    7991/s   242%   107%         --  -93%       -95% -96%       -97% -100%
tp          112626/s  4727%  2815%      1309%    --       -35% -43%       -61%  -94%
ts(cached)  172403/s  7289%  4362%      2057%   53%         -- -13%       -40%  -91%
pt          198514/s  8408%  5037%      2384%   76%        15%   --       -31%  -90%
tp(cached)  286277/s 12169%  7309%      3482%  154%        66%  44%         --  -85%
tm         1942109/s 83131% 50161%     24202% 1624%      1026% 878%       578%    --
    # Subtest: Asia/Tokyo(+0900)
    ok 1
    ok 2
    ok 3
    ok 4
    1..4
ok 3 - Asia/Tokyo(+0900)
Benchmark: running dt, dt(cached), pt, tm, tp, tp(cached), ts, ts(cached) for at least 10 CPU seconds...
        dt: 11 wallclock secs (10.53 usr +  0.00 sys = 10.53 CPU) @ 2175.02/s (n=22903)
dt(cached): 11 wallclock secs (10.63 usr +  0.01 sys = 10.64 CPU) @ 6889.94/s (n=73309)
        pt: 10 wallclock secs (10.35 usr +  0.01 sys = 10.36 CPU) @ 116392.95/s (n=1205831)
        tm: 10 wallclock secs (10.51 usr +  0.01 sys = 10.52 CPU) @ 1921173.29/s (n=20210743)
        tp: 10 wallclock secs (10.01 usr +  0.00 sys = 10.01 CPU) @ 126741.16/s (n=1268679)
tp(cached): 11 wallclock secs (10.33 usr +  0.00 sys = 10.33 CPU) @ 286425.65/s (n=2958777)
        ts: 10 wallclock secs (10.54 usr +  0.01 sys = 10.55 CPU) @ 3412.23/s (n=35999)
ts(cached): 11 wallclock secs (10.77 usr +  0.02 sys = 10.79 CPU) @ 85325.02/s (n=920657)
                Rate     dt     ts dt(cached) ts(cached)    pt    tp tp(cached)    tm
dt            2175/s     --   -36%       -68%       -97%  -98%  -98%       -99% -100%
ts            3412/s    57%     --       -50%       -96%  -97%  -97%       -99% -100%
dt(cached)    6890/s   217%   102%         --       -92%  -94%  -95%       -98% -100%
ts(cached)   85325/s  3823%  2401%      1138%         --  -27%  -33%       -70%  -96%
pt          116393/s  5251%  3311%      1589%        36%    --   -8%       -59%  -94%
tp          126741/s  5727%  3614%      1740%        49%    9%    --       -56%  -93%
tp(cached)  286426/s 13069%  8294%      4057%       236%  146%  126%         --  -85%
tm         1921173/s 88229% 56203%     27784%      2152% 1551% 1416%       571%    --
    # Subtest: America/Whitehorse(-0800)
    ok 1
    ok 2
    ok 3
    ok 4
    1..4
ok 4 - America/Whitehorse(-0800)
Benchmark: running dt, dt(cached), pt, tm, tp, tp(cached), ts, ts(cached) for at least 10 CPU seconds...
        dt: 10 wallclock secs (10.46 usr +  0.00 sys = 10.46 CPU) @ 2182.03/s (n=22824)
dt(cached): 10 wallclock secs (10.59 usr +  0.01 sys = 10.60 CPU) @ 6979.34/s (n=73981)
        pt: 11 wallclock secs (10.54 usr +  0.01 sys = 10.55 CPU) @ 100008.72/s (n=1055092)
        tm: 11 wallclock secs (10.44 usr +  0.00 sys = 10.44 CPU) @ 1938606.13/s (n=20239048)
        tp: 11 wallclock secs (10.49 usr +  0.00 sys = 10.49 CPU) @ 111452.72/s (n=1169139)
tp(cached): 11 wallclock secs (10.62 usr +  0.01 sys = 10.63 CPU) @ 280872.44/s (n=2985674)
        ts: 10 wallclock secs (10.41 usr +  0.01 sys = 10.42 CPU) @ 3424.28/s (n=35681)
ts(cached): 11 wallclock secs (10.58 usr +  0.00 sys = 10.58 CPU) @ 90333.55/s (n=955729)
                Rate     dt     ts dt(cached) ts(cached)    pt    tp tp(cached)    tm
dt            2182/s     --   -36%       -69%       -98%  -98%  -98%       -99% -100%
ts            3424/s    57%     --       -51%       -96%  -97%  -97%       -99% -100%
dt(cached)    6979/s   220%   104%         --       -92%  -93%  -94%       -98% -100%
ts(cached)   90334/s  4040%  2538%      1194%         --  -10%  -19%       -68%  -95%
pt          100009/s  4483%  2821%      1333%        11%    --  -10%       -64%  -95%
tp          111453/s  5008%  3155%      1497%        23%   11%    --       -60%  -94%
tp(cached)  280872/s 12772%  8102%      3924%       211%  181%  152%         --  -86%
tm         1938606/s 88744% 56514%     27676%      2046% 1838% 1639%       590%    --
1..4
