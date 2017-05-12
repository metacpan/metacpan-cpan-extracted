package sanity;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.03'; # VERSION
# ABSTRACT: The ONLY meta pragma you'll ever need!

# use feature has to be difficult...
our $VER_PACK;
BEGIN { $VER_PACK = sprintf(":%vd", $^V); }

# Eat our own dog food
use utf8;
use strict qw(subs vars);
no strict 'refs';
#use feature ($VER_PACK);
use warnings FATAL => 'all';
no warnings qw(uninitialized);
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

# Need this for some of the bit math
use bigint;            ### LAZY: I should probably be using Math::BigInt... ###
use sanity::BaseCalc;  ### FIXME: Temporary until Math::BaseCalc fix (RT #77198) ###

use List::MoreUtils qw(any all none uniq);

# Useful for importing modules, including stuff like Carp and its exports
use Import::Into v1.1.0;

my $base90 = [0..9, 'A'..'Z', 'a'..'z', split(//, '#$%&()*+.,-/:;<=>?@[]^_`{|}~')];  # no !, ', ", or \
my $base48900 = [
   @$base90,
   # see printuni.pl for details
   map { chr } (
        0xa2..0xac,  0xae..0x2e9, 0x2ec..0x2ff, 0x370..0x377, 0x37a..0x37e, 0x384..0x38a, 0x38c, 0x38e..0x3a1, 0x3a3..0x3e1,
      0x3f0..0x482, 0x48a..0x513, 0x531..0x556, 0x559..0x55f, 0x561..0x587, 0x589, 0x58a, 0x5be, 0x5c0,
      0x5c3, 0x5c6, 0x5d0..0x5ea, 0x5f0..0x5f4, 0x606..0x60f, 0x61b, 0x61e..0x64a, 0x660..0x66f,
      0x671..0x6d5, 0x6de, 0x6e5, 0x6e6, 0x6e9, 0x6ee..0x70d, 0x710, 0x712..0x72f, 0x74d..0x7b1,
      0x7c0..0x7ea, 0x7f4..0x7fa, 0x900..0x902, 0x904..0x93a, 0x93d, 0x941..0x948, 0x950, 0x955..0x977,
      0x979..0x97f, 0x981, 0x985..0x98c, 0x98f, 0x990, 0x993..0x9a8, 0x9aa..0x9b0, 0x9b2, 0x9b6..0x9b9,
      0x9bd, 0x9c1..0x9c4, 0x9ce, 0x9dc, 0x9dd, 0x9df..0x9e3, 0x9e6..0x9fb, 0xa01, 0xa02, 0xa05..0xa0a,
      0xa0f, 0xa10, 0xa13..0xa28, 0xa2a..0xa30, 0xa32, 0xa33, 0xa35, 0xa36, 0xa38, 0xa39, 0xa41, 0xa42, 0xa47, 0xa48,
      0xa4b, 0xa4c, 0xa51, 0xa59..0xa5c, 0xa5e, 0xa66..0xa75, 0xa81, 0xa82, 0xa85..0xa8d, 0xa8f..0xa91,
      0xa93..0xaa8, 0xaaa..0xab0, 0xab2, 0xab3, 0xab5..0xab9, 0xabd, 0xac1..0xac5, 0xac7, 0xac8, 0xad0,
      0xae0..0xae3, 0xae6..0xaef, 0xaf1, 0xb01, 0xb05..0xb0c, 0xb0f, 0xb10, 0xb13..0xb28, 0xb2a..0xb30,
      0xb32, 0xb33, 0xb35..0xb39, 0xb3d, 0xb3f, 0xb41..0xb44, 0xb56, 0xb5c, 0xb5d, 0xb5f..0xb63,
      0xb66..0xb77, 0xb82, 0xb83, 0xb85..0xb8a, 0xb8e..0xb90, 0xb92..0xb95, 0xb99, 0xb9a, 0xb9c, 0xb9e, 0xb9f,
      0xba3, 0xba4, 0xba8..0xbaa, 0xbae..0xbb9, 0xbc0, 0xbd0, 0xbe6..0xbfa, 0xc05..0xc0c, 0xc0e..0xc10,
      0xc12..0xc28, 0xc2a..0xc33, 0xc35..0xc39, 0xc3d..0xc40, 0xc46..0xc48, 0xc4a..0xc4c, 0xc58, 0xc59, 0xc60..0xc63,
      0xc66..0xc6f, 0xc78..0xc7f, 0xc85..0xc8c, 0xc8e..0xc90, 0xc92..0xca8, 0xcaa..0xcb3, 0xcb5..0xcb9, 0xcbd,
      0xcbf, 0xcc6, 0xccc, 0xcde, 0xce0..0xce3, 0xce6..0xcef, 0xcf1, 0xcf2, 0xd05..0xd0c,
      0xd0e..0xd10, 0xd12..0xd3a, 0xd3d, 0xd41..0xd44, 0xd4e, 0xd60..0xd63, 0xd66..0xd75, 0xd79..0xd7f,
      0xd85..0xd96, 0xd9a..0xdb1, 0xdb3..0xdbb, 0xdbd, 0xdc0..0xdc6, 0xdd2..0xdd4, 0xdd6, 0xdf4,
      0xe01..0xe37, 0xe3f..0xe47, 0xe4c..0xe5b, 0xe81, 0xe82, 0xe84, 0xe87, 0xe88, 0xe8a, 0xe8d,
      0xe94..0xe97, 0xe99..0xe9f, 0xea1..0xea3, 0xea5, 0xea7, 0xeaa, 0xeab, 0xead..0xeb7, 0xebb..0xebd,
      0xec0..0xec4, 0xec6, 0xecc, 0xecd, 0xed0..0xed9, 0xedc, 0xedd, 0xf00..0xf17, 0xf1a..0xf34, 0xf36,
      0xf38, 0xf3a..0xf3d, 0xf40..0xf47, 0xf49..0xf6c, 0xf73, 0xf75..0xf79, 0xf7e, 0xf81,
      0xf85, 0xf88..0xf97, 0xf99..0xfbc, 0xfbe..0xfc5, 0xfc7..0xfcc, 0xfce..0xfda, 0x10fb, 0x1100..0x115e,
      0x1161..0x1248, 0x124a..0x124d, 0x1250..0x1256, 0x1258, 0x125a..0x125d, 0x1260..0x1288, 0x128a..0x128d, 0x1290..0x12b0,
      0x12b2..0x12b5, 0x12b8..0x12be, 0x12c0, 0x12c2..0x12c5, 0x12c8..0x12d6, 0x12d8..0x1310, 0x1312..0x1315, 0x1318..0x135a,
      0x1360..0x137c, 0x1380..0x1399, 0x13a0..0x13f4, 0x1400..0x167f, 0x1681..0x169c, 0x16a0..0x16f0, 0x1735, 0x1736, 0x1780..0x17b3,
      0x17b7..0x17bd, 0x17c6, 0x17c9..0x17d1, 0x17d3..0x17dc, 0x17e0..0x17e9, 0x17f0..0x17f9, 0x1800..0x180d, 0x1810..0x1819,
      0x1820..0x1877, 0x1880..0x18a8, 0x18aa, 0x1950..0x196d, 0x1970..0x1974, 0x1980..0x19ab, 0x19c1..0x19c7, 0x19d0..0x19da,
      0x19de..0x19ff, 0x1d00..0x1dbf, 0x1e00..0x1f15, 0x1f18..0x1f1d, 0x1f20..0x1f45, 0x1f48..0x1f4d, 0x1f50..0x1f57, 0x1f59,
      0x1f5b, 0x1f5d, 0x1f5f..0x1f7d, 0x1f80..0x1fb4, 0x1fb6..0x1fc4, 0x1fc6..0x1fd3, 0x1fd6..0x1fdb, 0x1fdd..0x1fef,
      0x1ff2..0x1ff4, 0x1ff6..0x1ffe, 0x2010..0x2027, 0x2030..0x205e, 0x2070, 0x2071, 0x2074..0x208e, 0x2090..0x209c, 0x20a0..0x20b9,
      0x2100..0x2189, 0x2190..0x22bf, 0x2500..0x257f, 0x25a0..0x266f, 0x2701..0x27bf, 0x2800..0x28ff, 0x2c60..0x2c7f, 0x2d30..0x2d65,
      0x2d6f, 0x2d70, 0x2d80..0x2d96, 0x2da0..0x2da6, 0x2da8..0x2dae, 0x2db0..0x2db6, 0x2db8..0x2dbe, 0x2dc0..0x2dc6, 0x2dc8..0x2dce,
      0x2dd0..0x2dd6, 0x2dd8..0x2dde, 0x2e80..0x2e99, 0x2e9b..0x2ef3, 0x2ff0..0x2ffb, 0x3001..0x3029, 0x3030..0x303f, 0x3041..0x3096,
      0x309b..0x30ff, 0x3131..0x3163, 0x3165..0x318e, 0x3190..0x319f, 0x31c0..0x31e3, 0x31f0..0x321e, 0x3220..0x32fe, 0x3300..0x4db5,
      0x4e00..0x9fcb, 0xa000..0xa48c, 0xa490..0xa4c6, 0xa500..0xa62b, 0xa840..0xa877, 0xac00..0xd7a3, 0xf900..0xfa2d, 0xfa30..0xfa6d,
      0xfa70..0xfad9, 0xfb00..0xfb06, 0xfb13..0xfb17, 0xfb1d, 0xfb1f..0xfb36, 0xfb38..0xfb3c, 0xfb3e, 0xfb40, 0xfb41,
      0xfb43, 0xfb44, 0xfb46..0xfb4f, 0xfe10..0xfe19, 0xfe30..0xfe52, 0xfe54..0xfe66, 0xfe68..0xfe6b, 0xff01..0xff9f, 0xffa1..0xffbe,
      0xffc2..0xffc7, 0xffca..0xffcf, 0xffd2..0xffd7, 0xffda..0xffdc, 0xffe0..0xffe6, 0xffe8..0xffee,
   )
];
my $calc90    = sanity::BaseCalc->new(digits => $base90);
my $calc48900 = sanity::BaseCalc->new(digits => $base48900);

my @FLAGS = (
   # Perl.h HINTS (Bits 0-31)
   # (matches ordering of $^H)
   qw(
      integer
      strict/refs
      locale
      bytes
      XXX:ARRAY_BASE
      XXX:V_VMSISH1
      XXX:V_VMSISH2
      XXX:V_VMSISH3
      XXX:BLOCK_SCOPE
      strict/subs
      strict/vars
      feature/HINT/unicode
      XXX:overload/integer
      XXX:overload/float
      XXX:overload/binary
      XXX:overload/q
      XXX:overload/qr
      XXX:LOCALIZE_HH
      XXX:LEXICAL_IO_IN
      XXX:LEXICAL_IO_OUT
      re/taint
      re/eval
      filetest
      utf8
      NO:overloading
      XXX:RE_FLAGS
      XXX:FEATURE_BIT1
      XXX:FEATURE_BIT2
      XXX:FEATURE_BIT3
      XXX:HINT_0x20000000
      XXX:HINT_0x40000000
      XXX:HINT_0x80000000
   ),

   # warnings.pm (Bits 32-160)
   # (matches REVERSE ordering of $^{WARNING_BITS} << 32)
   qw(
      MULTI:warnings/all     MULTI:warnings/all/FATAL
      warnings/closure       MULTI:warnings/closure/FATAL
      warnings/deprecated    MULTI:warnings/deprecated/FATAL
      warnings/exiting       MULTI:warnings/exiting/FATAL
      warnings/glob          MULTI:warnings/glob/FATAL
      MULTI:warnings/io      MULTI:warnings/io/FATAL
      warnings/closed        MULTI:warnings/closed/FATAL
      warnings/exec          MULTI:warnings/exec/FATAL
      warnings/layer         MULTI:warnings/layer/FATAL
      warnings/newline       MULTI:warnings/newline/FATAL
      warnings/pipe          MULTI:warnings/pipe/FATAL
      warnings/unopened      MULTI:warnings/unopened/FATAL
      warnings/misc          MULTI:warnings/misc/FATAL
      warnings/numeric       MULTI:warnings/numeric/FATAL
      warnings/once          MULTI:warnings/once/FATAL
      warnings/overflow      MULTI:warnings/overflow/FATAL
      warnings/pack          MULTI:warnings/pack/FATAL
      warnings/portable      MULTI:warnings/portable/FATAL
      warnings/recursion     MULTI:warnings/recursion/FATAL
      warnings/redefine      MULTI:warnings/redefine/FATAL
      warnings/regexp        MULTI:warnings/regexp/FATAL
      MULTI:warnings/severe  MULTI:warnings/severe/FATAL
      warnings/debugging     MULTI:warnings/debugging/FATAL
      warnings/inplace       MULTI:warnings/inplace/FATAL
      warnings/internal      MULTI:warnings/internal/FATAL
      warnings/malloc        MULTI:warnings/malloc/FATAL
      warnings/signal        MULTI:warnings/signal/FATAL
      warnings/substr        MULTI:warnings/substr/FATAL
      MULTI:warnings/syntax  MULTI:warnings/syntax/FATAL
      warnings/ambiguous     MULTI:warnings/ambiguous/FATAL
      warnings/bareword      MULTI:warnings/bareword/FATAL
      warnings/digit         MULTI:warnings/digit/FATAL
      warnings/parenthesis   MULTI:warnings/parenthesis/FATAL
      warnings/precedence    MULTI:warnings/precedence/FATAL
      warnings/printf        MULTI:warnings/printf/FATAL
      warnings/prototype     MULTI:warnings/prototype/FATAL
      warnings/qw            MULTI:warnings/qw/FATAL
      warnings/reserved      MULTI:warnings/reserved/FATAL
      warnings/semicolon     MULTI:warnings/semicolon/FATAL
      warnings/taint         MULTI:warnings/taint/FATAL
      warnings/threads       MULTI:warnings/threads/FATAL
      warnings/uninitialized MULTI:warnings/uninitialized/FATAL
      warnings/unpack        MULTI:warnings/unpack/FATAL
      warnings/untie         MULTI:warnings/untie/FATAL
      MULTI:warnings/utf8    MULTI:warnings/utf8/FATAL
      warnings/void          MULTI:warnings/void/FATAL
      warnings/imprecision   MULTI:warnings/imprecision/FATAL
      warnings/illegalproto  MULTI:warnings/illegalproto/FATAL
      warnings/non_unicode   MULTI:warnings/non_unicode/FATAL
      warnings/nonchar       MULTI:warnings/nonchar/FATAL
      warnings/surrogate     MULTI:warnings/surrogate/FATAL
      MULTI:warnings/experimental           MULTI:warnings/experimental/FATAL
      warnings/experimental::lexical_subs   MULTI:warnings/experimental::lexical_subs/FATAL
      warnings/experimental::lexical_topic  MULTI:warnings/experimental::lexical_topic/FATAL
      warnings/experimental::regex_sets     MULTI:warnings/experimental::regex_sets/FATAL
      warnings/experimental::smartmatch     MULTI:warnings/experimental::smartmatch/FATAL
      warnings/experimental::autoderef      MULTI:warnings/experimental::autoderef/FATAL
      warnings/experimental::postderef      MULTI:warnings/experimental::postderef/FATAL
      warnings/experimental::signatures     MULTI:warnings/experimental::signatures/FATAL
      warnings/syscalls      MULTI:warnings/syscalls/FATAL
      XXX:warnings/60        XXX:warnings/60/FATAL
      XXX:warnings/61        XXX:warnings/61/FATAL
      XXX:warnings/62        XXX:warnings/62/FATAL
      XXX:warnings/63        XXX:warnings/63/FATAL
   ),

   # feature (Bits 161-176)
   qw(
      feature/^V
      feature/switch
      feature/say
      feature/state
      MULTI:feature/unicode
      feature/fc
      feature/evalbytes
      feature/array_base
      feature/current_sub
      feature/lexical_subs
      feature/unicode_eval
      feature/signatures
      feature/postderef
      feature/postderef_qq
      feature/current_sub
      XXX:feature/15
   ),

   ### TODO: Might need move this set to the bottom and add some extra bitmap bits after Perl 5.23

   # Perl versions (Bits 177-184)
   # (MAJOR-8)*16 + MINOR + 1 = 8-bit bitmap
   qw(
      BITMAP:perl/0
      BITMAP:perl/1
      BITMAP:perl/2
      BITMAP:perl/3
      BITMAP:perl/4
      BITMAP:perl/5
      BITMAP:perl/6
      BITMAP:perl/7
   ),

   # Autodie (Bits 185-200)
   # Will expand if requested, but I don't want to waste
   # all of that bit space right now.
   qw(
      MULTI:autodie/io
      autodie/dbm
      autodie/file
      autodie/filesys
      MULTI:autodie/ipc
      autodie/msg
      autodie/semaphore
      autodie/shm
      autodie/socket
      autodie/threads
      autodie/system
      XXX:autodie/11
      XXX:autodie/12
      XXX:autodie/13
      XXX:autodie/14
      XXX:autodie/15
   ),

   # Other CORE pragmas (Bits 201-216)
   qw(
      bigint
      bignum
      bigrat
      charnames
      charnames/short
      charnames/full
      encoding::warnings
      encoding::warnings/FATAL
      mro/dfs
      mro/c3
      open/crlf
      open/bytes
      open/utf8
      open/locale
      open/std
      XXX:CORE/15
   ),

   # Other pragmas (Bits 217-247 and beyond)
   qw(
      NO:autovivification/fetch
      NO:autovivification/exists
      NO:autovivification/delete
      NO:autovivification/store
      NO:autovivification/warn
      NO:autovivification/strict
      NO:indirect
      NO:indirect/global
      NO:indirect/fatal
      NO:multidimensional
      NO:bareword::filehandles
      namespace::clean
      namespace::autoclean
      namespace::sweep
      namespace::functions
      subs::auto
      utf8::all
      IO::File
      IO::Handle
      IO::All
      Carp
      BITMAP:criticism/0
      BITMAP:criticism/1
      BITMAP:criticism/2
      vendorlib
      true
      autolocale
      perl5i::0
      perl5i::1
      perl5i::2
      perl5i::3
      perl5i::latest
      Toolkit
   ),
   # new adds
   qw(
      Function::Parameters
      Function::Parameters/strict
      Switch::Plain
      Quote::Code
   ),
);
my %FLAGS;  # namespace abuse I know...
$FLAGS{$FLAGS[$_]} = $_ for (0 .. $#FLAGS);

my %ALIAS = (
   strict => [qw(strict/refs strict/subs strict/vars)],

   # See corpus/warnbits.pl for the bitwise math
   'warnings/all'                => '1902996923607946508077714625932660180412006400',  # 0x55555555555555555555555555555500
   'warnings/all/FATAL'          => '5708990770823839524233143877797980541236019200',  # 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00
   'warnings/io'                 => '1427247692705959881058285969473512868379885568',  # 0x00545500000000000000000000004000
   'warnings/io/FATAL'           => '4281743078117879643174857908420538605139656704',  # 0x00FCFF0000000000000000000000C000
   'warnings/severe'             =>                      '6441307882634196071481344',  # 0x00000000005405000000000000000000
   'warnings/severe/FATAL'       =>                     '19323923647902588214444032',  # 0x0000000000FC0F000000000000000000
   'warnings/syntax'             =>         '85071024421536332098205581043061227520',  # 0x00000000000000555515004000000000
   'warnings/syntax/FATAL'       =>        '170142481534374380428773091271241629696',  # 0x00000000000000FFFF3F008000000000
   'warnings/utf8'               =>       '7147258933335492648603770563127412785152',  # 0x00000000000000000000000115000000
   'warnings/utf8/FATAL'         =>      '21441776800006477945811311689382238355456',  # 0x0000000000000000000000033F000000
   'warnings/experimental'       =>  '475741971544825646998874771158206501072404480',  # 0x00000000000000000000000040551500
   'warnings/experimental/FATAL' => '1427225914634476940996624313474619503217213440',  # 0x000000000000000000000000C0FF3F00
   'warnings'                    => 'warnings/all',
   'warnings/FATAL'              => 'warnings/all/FATAL',

   # XXX: 5.18 has array_base and they "backported" it to older versions.
   # We don't use it, but that's not totally accurate of the feature_bundles.
   # It's a barely used $[ variable, anyway...

   'feature/unicode'         => [qw(MULTI:feature/unicode feature/HINT/unicode)],
   'feature/unicode_strings' => 'feature/unicode',
   'feature/5.9.5'           => 'feature/5.10',
   'feature/5.10'            => [map { "feature/$_" } qw(say state switch)],  # 5.18 has array_base, but not in 5.10's version
   'feature/5.11'            => [map { "feature/$_" } qw(5.10 unicode)],
   'feature/5.12'            => 'feature/5.11',
   'feature/5.13'            => 'feature/5.11',
   'feature/5.14'            => 'feature/5.11',
   'feature/5.15'            => [map { "feature/$_" } qw(current_sub evalbytes fc say state switch unicode_eval unicode_strings)],
   'feature/5.16'            => 'feature/5.15',
   'feature/5.17'            => 'feature/5.15',
   'feature/5.18'            => 'feature/5.15',
   'feature/5.19'            => 'feature/5.15',
   'feature/5.20'            => 'feature/5.15',
   'feature/5.21'            => 'feature/5.15',
   feature                   => 'feature/^V',

   'autodie/ipc'     => [qw(MULTI:autodie/ipc autodie/msg autodie/semaphore autodie/shm)],
   'autodie/io'      => [qw(MULTI:autodie/io  autodie/dbm autodie/file autodie/filesys autodie/ipc autodie/socket)],
   'autodie/default' => [qw(autodie/io autodie/threads)],
   'autodie/all'     => [qw(autodie/default autodie/system)],
   autodie           => 'autodie/default',

   mro => 'mro/dfs',
   'NO:autovivification' => [map { 'NO:autovivification/'.$_ } qw(fetch exists delete)],

   'criticism/gentle' => [map { 'BITMAP:criticism/'.$_ } qw(0 2)],
   'criticism/stern'  => 'BITMAP:criticism/2',
   'criticism/harsh'  => [map { 'BITMAP:criticism/'.$_ } qw(0 1)],
   'criticism/cruel'  => 'BITMAP:criticism/1',
   'criticism/brutal' => 'BITMAP:criticism/0',
   criticism          => 'criticism/gentle',

   # mimicry of other "meta pragma" modules
   'ex::caution'  => [qw(strict warnings)],
   'NO:crap'      => [qw(strict warnings)],
   'shit'         => [qw(strict warnings)],
   'latest'       => [qw(strict warnings feature)],
   'sane'         => [qw(strict warnings feature utf8)],
   'NO:nonsense'  => [qw(strict warnings true namespace::autoclean)],
   'Modern::Perl' => [qw(strict warnings mro/dfs feature IO::File IO::Handle)],
   'strictures'   => [qw(v5.8.4 strict warnings/all/FATAL NO:indirect/fatal NO:multidimensional NO:bareword::filehandles)],
   'uni::perl'    => [qw(
      v5.10 strict feature/5.10
   ), (
      map { "warnings/$_/FATAL" } qw(closed threads internal debugging pack substr malloc
      unopened portable prototype inplace io pipe unpack regexp deprecated exiting glob
      digit printf utf8 layer reserved parenthesis taint closure semicolon)
   ), qw(
      -warnings/exec/FATAL
      -warnings/newline/FATAL
      utf8
      open/utf8
      open/std
      mro/c3
      Carp
   )],
   'common::sense' => [qw(
      strict feature/5.10
   ), (
      map { "warnings/$_/FATAL" } qw(closed threads internal debugging pack malloc
      portable prototype inplace io pipe unpack deprecated glob digit printf
      layer reserved taint closure semicolon)
   ),
   qw(
      -warnings/exec/FATAL
      -warnings/newline/FATAL
      -warnings/unopened/FATAL
      utf8
   )],
   'sanity'   => [qw(
      v5.10.1 utf8 open/utf8 open/std mro/c3 strict/subs strict/vars feature/5.10
      warnings/all/FATAL -warnings/uninitialized/FATAL -warnings/experimental::smartmatch/FATAL
      NO:autovivification NO:autovivification/store NO:autovivification/strict
      NO:indirect/fatal NO:multidimensional
   )],
   'Acme::Very::Modern::Perl' => [qw(Modern::Perl -mro/dfs mro/c3 utf8 open/utf8 open/std common::sense perl5i::latest Toolkit Carp)],
);

# Implement experimental ALIASes in a similar manner as Leon's code itself
foreach my $main_pragma (qw[ array_base autoderef lexical_topic postderef regex_sets signatures smartmatch switch ]) {
    # additional pragmas to enable
    my @pragmas = ($main_pragma);
    push @pragmas, 'postderef_qq' if $main_pragma eq 'postderef';
    push @pragmas, 'smartmatch'   if $main_pragma eq 'switch';

    my @flags;
    foreach my $pragma (@pragmas) {
        push @flags, "-warnings/experimental::$pragma" if "warnings/experimental::$pragma" ~~ @FLAGS;
        push @flags, "feature/$pragma"                 if "feature/$pragma"                ~~ @FLAGS;
    }

    $ALIAS{"experimental/$main_pragma"} = \@flags;
}

# All FATAL warnings have both bits marked (at least in $^{WARNING_BITS}),
# so we'll mimic the same
foreach my $flag ( grep { qr(^warnings/) } @FLAGS ) {
   $ALIAS{"$flag/FATAL"} = [$flag, "MULTI:$flag/FATAL"];
}

# These modules are optional.  Everything else changes the nature
# of how Perl works, or would let you do something that would
# normally fatally error.
my @NON_INSTADIE = (qw(
   overloading
   autovivification
   indirect
   multidimensional
   bareword::filehandles
   criticism
));
# (autovivification probably shouldn't be here, since it actually
# prevents autoviv, but it's generally used as an author tool.)

my $author_load_warned;
sub import {
   my ($class, @args) = @_;

   # See if we need to encode a pragma hash
   my $print_hash  = find_and_remove(qr/^PRINT_PRAGMA_HASH$/, \@args);
   # ... or print flags
   my $print_flags = find_and_remove(qr/^PRINT_FLAGS$/, \@args);

   @args = ($class) unless (@args);
   unshift @args, $class if (all { /^-/ } @args);  # don't be all negative and such
   @args = filter_args(@args);

   if ($print_hash) {
      binmode STDOUT, ':utf8';
      print "use $class '".encode_pragmahash(\@args, '0')."';  # Overly long decimal version\n";
      print "use $class '".encode_pragmahash(\@args, '!')."';  # Safer ASCII version\n";
      print "use $class '".encode_pragmahash(\@args, '¡')."';  # Shorter UTF8 version\n";
      ### TODO: should try to resolve back to the closest alias ###
      exit;
   }
   if ($print_flags) {
      print join("\n", @args)."\n";
      exit;
   }

   # Look for every indicator that proves that the user is in the distro directory
   # and appears to be one of the coders
   my $author_mode = !!((caller)[1] =~ /^(?:x?t|b?lib)[\/\\]/ && (-d '.git' or -d '.svn'));
   $author_mode = 0 if (grep {
      $ENV{"PERL5_${_}_IS_RUNNING"} || $ENV{"PERL5_${_}_IS_RUNNING_IN_RECURSION"}
   } (qw/CPANM CPANP CPANPLUS CPAN/) );

   # Process order:
   #    v5.##.##
   #    utf8
   #    mro
   #    strict
   #    warnings
   #    feature
   #    ...anything else...
   #    namespace::clean
   #    namespace::functions (always last)
   # (If this needs to be changed, let me know and I can reorder it)

   # Perl version
   if ( my @perl_version = find_and_remove(qr/^BITMAP:perl\b/, \@args) ) {
      my $bitmap = args2bitmask(@perl_version) >> $FLAGS{'BITMAP:perl/0'};
      my $mj = ($bitmap >> 4) + 8;
      my $mn = $bitmap % 16 - 1;

      eval "use v5.$mj.$mn";
   }

   my @init = find_and_remove(qr/^(?:utf8|mro|strict|warnings|feature)\b/, \@args);
   my @end  = find_and_remove(qr/^namespace::(clean|functions)\b/, \@args);
   my @mod_list = uniq map { (/^(?:[A-Z]+\:(?!\:))?([\w\:]+)/)[0] } (@init, sort(@args), @end);
   unshift @args, @init;
   push    @args, @end;

   my @failed;
   foreach my $module (@mod_list) {
      my $success = load_pragma('import', find_and_remove(qr/^(?:[A-Z]+\:(?!\:))?$module\b/, \@args) );
      unless (defined $success) {
         require $module unless ($module ~~ @NON_INSTADIE);  # death by suicide (which prints the proper error msg)
         push @failed, $module;
      }
   }

   if (@failed and $author_mode and not $author_load_warned++) {
      my $failed = join ' ', @failed;
      warn <<EOE;
Detected current environment to be in "author mode" but couldn't load all
modules. Missing (author) modules were:

  $failed

You should install these modules via CPAN, but these modules are not
required by your users (unless you add them to your META file).
EOE
   }
}

# This is import with some subtractions and slight changes
sub unimport {
   my ($class, @args) = @_;

   @args = ($class) unless (@args);
   unshift @args, $class if (all { /^-/ } @args);  # don't be all negative and such
   @args = filter_args(@args);

   # Process order: IN REVERSE!
   my @end  = find_and_remove(qr/^(?:utf8|mro|strict|warnings|feature)\b/, \@args);
   my @init = find_and_remove(qr/^namespace::(clean|functions)\b/, \@args);
   my @mod_list = uniq map { (/^(?:[A-Z]+\:(?!\:))?([\w\:]+)/)[0] } (@init, sort(@args), @end);
   unshift @args, @init;
   push    @args, @end;

   foreach my $module (@mod_list) {
      my $success = load_pragma('unimport', find_and_remove(qr/^(?:[A-Z]+\:(?!\:))?$module\b/, \@args) );
      require $module unless (defined $success || $module !~~ @NON_INSTADIE);  # death by suicide (which prints the proper error msg)
   }
}

sub load_pragma {
   my $method = shift;
   $method = 'import' unless ($method =~ /^(?:un)?import$/);
   return 0 unless (@_);

   # import/unimport called us, so one step back
   my $target = scalar caller(1);

   my ($module, @options);
   foreach my $flag (@_) {
      ($module, my $param) = ($flag =~ qr!^([\w\:]+)(?:/(.+))?!);
      push @options, $param if ($param);
   }

   # handle NO:
   my ($modifier) = ($module =~ s/^([A-Z]+)\:(?!\:)//);
   $method  = 'un'.$method if ($modifier eq 'NO');
   $method =~ s/^unun//;

   # Use import::into / unimport:out_of
   $method .= '::'.($method =~ /^un/ ? 'out_of' : 'into');

   die "Cannot use XXX flag: XXX:$module" if ($modifier eq 'XXX');

   # Specific exceptions

   # (:param format for certain modules)
   @options = map { ":$_" } @options if ($module =~ /^(?:open|indirect|charnames|autodie|Function::Parameters)$/);
   # ^V = $^V (like feature)
   @options = map { $_ = ($_ eq '^V') ? $VER_PACK : $_ } @options;
   # remove feature/HINT/unicode
   @options = grep { !/^HINT\/unicode$/ } @options if ($module eq 'feature');
   # (adding cleanee to namespace::* modules)
   if ($module =~ /^namespace::/ and not $module eq 'namespace::functions') {
      @options = (-cleanee => $target);
      # (add 'meta' to namespace::clean's exceptions)
      push @options, (-except => 'meta') if ($module eq 'namespace::clean');
   }
   # (handling of FATAL in warnings)
   if ($module eq 'warnings') {
      # separate out FATAL and non-FATAL options
      my $options = [@options];
      my @fatal = map { s|/FATAL$||; $_ } find_and_remove(qr|/FATAL$|, $options);
      my @nonfatal = notin(\@fatal, $options);

      # To prevent "Unknown warnings category" errors for various versions of Perl,
      # we'll need to remove the ones that don't exist in the current version.

      # (also remove the combo flags while we're at it...)
      my @combos = grep { /^MULTI:warnings\/\w+$/ } @FLAGS;
         @combos = map  { s|MULTI:warnings/||; $_ } @combos;

      my @warn_categories = keys %warnings::Offsets;
      @fatal    = notin(\@combos, [ foundin(\@warn_categories, \@fatal)    ]);
      @nonfatal = notin(\@combos, [ foundin(\@warn_categories, \@nonfatal) ]);

      # if this is an import, first clean all warnings
      warnings->unimport::out_of($target);

      # warnings can handle both in one import, so let's do it that way
      @options = ();
      push(@options, FATAL    =>    @fatal) if    (@fatal);
      push(@options, NONFATAL => @nonfatal) if (@nonfatal);
   }
   if ($module eq 'strict') {
      # if this is an import, first clean all stricts
      strict->unimport::out_of($target);
   }
   # (BITMAPs)
   if ($modifier eq 'BITMAP') {
      my $bitmap = args2bitmask(map { s|^|BITMAP:$module/| } @options) >> $FLAGS{"BITMAP:$module/0"};
      if    ($module eq 'criticism') { @options = ( -severity => $bitmap ); }
      elsif ($module eq 'perl')      { die "Internal error (report as a bug): Perl versions should have already been extracted at this point!"; }
      else                           { die "Unsupported set of BITMAP flags: BITMAP:$module/*"; }
   }

   # open gets kinda strange with the eval/require
   my $evalmodule = $module;
   $evalmodule = "'open.pm'" if ($module eq 'open');

   # DO IT!
   if (eval "require $evalmodule; 1") {
      $module->$method($target, @options);
      return 1;
   }
   return undef;
}

sub find_and_remove {
   my ($re, $arr) = @_;
   return (wantarray ? () : undef) unless @$arr;
   $re = qr/$re/ unless (ref $re eq 'Regexp');

   my @flags;
   for (my $i = 0; $i < @$arr; $i++) {
      push @flags, splice(@$arr, $i--, 1) if ($arr->[$i] =~ $re);
   }

   return @flags;
}

# Find items in @B that are in @A
sub foundin (\@\@) {
   my ($A, $B) = @_;
   return grep { my $i = $_; any { $i eq $_ } @$A; } @$B;
}

# Find items in @B that are not in @A
sub notin (\@\@) {
   my ($A, $B) = @_;
   return grep { my $i = $_; none { $i eq $_ } @$A; } @$B;
}

sub filter_args {
   return bitmask2flags( args2bitmask(@_) );
}

sub args2bitmask {
   my @args = @_;

   my $bitmask = 0;
   while (my $flag = shift @args) {
      my $negate_bit = ($flag =~ s/^-//);
      my $bit = $FLAGS{$flag};
      my $def = $ALIAS{$flag};

      # Direct find on FLAGS
      if (defined $bit) {
         $bitmask = $negate_bit ?
            $bitmask & ~(1 << $bit) :
            $bitmask |   1 << $bit;
      }
      # Perl version
      elsif ($flag =~ /^(?|  # branch reset (look it up)
         v? 5\. (?<major>\d+) (?:\.(?<minor>\d+))? |
         \x05(?<major>.)(?<minor>.)?
      )$/x) {
         my ($mj, $mn) = ($+{major}, $+{minor});
         ($mj, $mn) = (ord($mj), ord($mn)) if $flag =~ /^\x05/;
         $mn ||= 0;  # bigint/BigInt has weird problems with undef

         my $bitmask8 = ($mj-8) * 16 + $mn + 1;
         die "Perl version flags for sanity must be at least 5.8.0" if ($bitmask8 <= 0);

         foreach my $bit8 (0..7) {
            push @args, 'BITMAP:perl/'.$bit8 if ($bitmask8 & 1 << $bit8);
         }
      }
      # Pragma hash
      elsif ($flag =~ /^[!¡]/) {
         die "Only one argument can be provided if you are using a pragma hash!" unless (@_ == 1);
         return decode_pragmahash($flag);
      }
      # A UTF-8 pragma hash
      elsif ($flag =~ /^\xC2\xA1/) {
         # This could happen if the user sent in a UTF-8 string without saying 'use utf8;' or
         # any identifying BOFs, etc., saying that the program is in UTF-8.  Of course, the
         # catch-22 is that they are expecting _sanity_ to enable utf8 for them, so we need to
         # convert the string manually.
         require Encode;
         push @args, Encode::decode('utf8', $flag);
      }
      # A real bitmask
      elsif ($flag =~ /^\d+$/) {
         $flag += 0;
         $bitmask = $negate_bit ?
            $bitmask & ~$flag :
            $bitmask |  $flag;
      }
      # An alias
      elsif (defined $def) {
         unshift @args, map { $negate_bit ? "-$_" : $_ } (ref $def ? @$def : $def);
      }
      else {
         die "Unsupported flag: $flag";
      }
   }

   return $bitmask;
}

sub bitmask2flags {
   my ($bitmask) = @_;

   my @flags;
   foreach my $bit (0..@FLAGS-1) {
      push @flags, $FLAGS[$bit] if ($bitmask & 1 << $bit);
   }

   return @flags;
}

my $CURRENT_HASH_VERSION = 0;

sub encode_pragmahash {
   my ($flags, $type) = @_;
   $type //= '¡';

   $flags = args2bitmask(@$flags) if (ref $flags eq 'ARRAY');
   return $flags if ($type eq '0');
   my $hash = ($type eq '!' ? $calc90 : $calc48900)->to_base($flags);
   return $type.$CURRENT_HASH_VERSION.$hash
}

### FIXME: Wait for Math::BaseCalc fix (RT #77198) ###
sub decode_pragmahash {
   my ($hash) = @_;
   ($hash, my $type) = (substr($hash, 1), substr($hash, 0, 1));
   die "Invalid hash type ($type) for pragma hash: $hash" unless ($type =~ /^[!¡]$/);
   die "Unsupported pragma hash version!" unless ($hash =~ s/^$CURRENT_HASH_VERSION//);

   return ($type eq '!' ? $calc90 : $calc48900)->from_base($hash);
}

# warnings void + bigint + 1; + perl sanity.pm = "Useless use of a constant (1) in void context"
42;

__END__

=pod

=encoding UTF-8

=head1 NAME

sanity - The ONLY meta pragma you'll ever need!

=head1 SYNOPSIS

   use sanity;
   use sanity 'strictures';
   use sanity 'Modern::Perl';

   use sanity qw(
      strictures -warnings/uninitialized/FATAL
      NO:autovivification NO:autovivification/store
      PRINT_PRAGMA_HASH
   );
   use sanity '!0*b^Npow{8T7_yZt<?cT6/?ZCO=Y0LV_Duoc';  # Safer ASCII version
   use sanity '¡0ǲ鵆㤧뱞⡫瘑빸ን둈댬嚝⠨舁聼䮋';  # Shorter UTF8 version

=head1 DESCRIPTION

Modern::Perl?  common::sense?  no nonsense?  use latest?

Everybody has their own opinion on what pragmas and modules are "required"
for every person to use.  These opinions turn into "personal pragmas", so that
people don't have to type several C<use> lines of header in front of every module
they write.

Personal opinions and pragmas don't really belong in the CPAN namespace.  (It's
CPAN, not Personal PAN.  If you want a Personal PAN, go call Pizza Hut.)  But
copying code on potentially hundreds of modules doesn't make sense, either.

That was my mentality when I had a personal opinion of my own.  Why repeat the same
problem like everybody else?

This "sanity" module attempts to level the playing field by making it a
B<customizable> personal pragma, allowing you to both reduce the code needed and
still implement all of the modules/pragmas you need.

As an illustration to what it's capable of, this pragma will emulate all of the
other personal pragmas, most of them 100% working exactly how they do it.

=head1 PARAMETERS

Sanity's parameters fall into three types: flags, aliases, and hashes.  (Oh my!)

=head2 Flags and Aliases

Flags are single pragma/module declarations, strict/warning flags, or other
items that need flags.  Aliases are merely one or more flags, grouped
together to better emulate the pragma/module's functionality.

Let's start off with an example:

   # These three statements do the same thing as...
   use Modern::Perl;
   use sanity 'Modern::Perl';
   use sanity qw(strict warnings mro/dfs feature IO::File IO::Handle);

   # ...these statements
   use strict;
   use warnings;
   use mro 'dfs';
   use feature ':all';
   use IO::File;
   use IO::Handle;

Basically, it does the same thing as the meta pragma L<Modern::Perl>, except
you actually don't need that module for it to work.  While there is some magic
to make sure, say, C<feature> gets loaded with various versions of Perl, it typically
just works using a standard C<import> call.  The C<strict> and C<warnings> flags
are combined aliases that enable all of the warnings that they would do via a standard
call.

=head3 Negating flags/aliases

You can turn off flags in the statement:

   use sanity qw(Modern::Perl -mro/dfs);

This does the same thing as above, except it doesn't import the C<mro> pragma.  You
can negate any flag, including combined aliases, as long as it makes sense.  In other
words, you need a positive included before you can negate something.

=head3 NO:* flags/aliases

Some pragmas work by using the C<B<unimport>> function, so that the English makes sense.
To keep that syntax, these pragmas are included with a C<NO:> prefix:

   use sanity 'NO:multidimensional';
   use sanity 'NO:indirect/FATAL';

This will run the C<unimport> function on these pragmas, even though sanity was called
via the C<import> function (via C<use>).

=head3 Perl versions

Sanity also supports Perl versions as a special kind of alias to specify minimum Perl
versions:

   # These are all the same:
   use v5.10.1;
   use sanity 'v5.10.1';
   use sanity v5.10.1;  # as a VSTRING
   use sanity 5.10.1;   # works too

   # Upgrade the Perl version of your favorite pragma
   use sanity qw(NO:nonsense v5.12);

Note that the version must be at least v5.8.  This should be fine for most people.  (If
I get a ticket requesting support for a Perl version older than one released in 2002, I
will hunt you down and break your keyboard in half.)

=head3 The Default

What does C<sanity> do without any parameters?  Why my personal preference, of course :)
It's listed in the C<meta pragma> section of the L<LIST OF FLAGS> below.  I detail the
reasons behind my choices L<here|sanity::sanity>.

=head2 Hashes

So, there's all of these flags, but unless you're using one of the combined aliases,
typing them all out is usually just as much (or more) code as the several lines of C<use>
statements.  Well, they are all flags so that it fits into a giant bitmap, and that
bitmap can be compressed into a large ASCII (or UTF-8) "number".

This number can be calculated using the flag C<PRINT_PRAGMA_HASH>:

   # This is merely the definition of uni::perl
   use sanity (qw(
      v5.10 strict feature/5.10
   ), (
      map { "warnings/$_/FATAL" } qw(closed threads internal debugging pack substr malloc
      unopened portable prototype inplace io pipe unpack regexp deprecated exiting glob
      digit printf utf8 layer reserved parenthesis taint closure semicolon)
   ), qw(
      -warnings/exec/FATAL
      -warnings/newline/FATAL
      utf8
      open/utf8
      open/std
      mro/c3
      Carp
   ), 'PRINT_PRAGMA_HASH');

   # Outputs:
   # use sanity '!04[D{9Fhfqc-7m738S4HK6B#D5=v{,T$(0)F5i';  # Safer ASCII version
   # use sanity '¡05༕ቑ釩腜쥸봱楇䐍퇥熠ᾯ緻褻真堩';  # Shorter UTF8 version

You can use that hash as the output illustrates without having to type out the entire big
set of commands or flags.

=head2 Other Meta Pragmas

Have your own set that is too long, and you don't like the ugliness of the hash?  Send me
your suggestion and I'll probably add it in.

=head1 CAVEATS

=head2 'NO:' ne '-'

A C<NO:> flag is NOT the same as negating a flag!  You also cannot remove the C<NO:>
from a flag, as it's part of the name of the flag, not a special modifier.

   # These two are NOT the same!
   use sanity 'NO:indirect';  # runs indirect->unimport()
   use sanity '-indirect';    # Dies, as there is no such flag/alias

   # This runs through the strictures alias and runs autovivification->unimport()
   use sanity qw(strictures NO:autovivification);

   # This runs through the strictures alias WITHOUT running indirect->unimport()
   use sanity qw(strictures -NO:indirect);

   use sanity '-indirect';    # This isn't what you want...
   no  sanity 'NO:indirect';  # ...you really meant to do this...
   use indirect;              # ...but this is better

=head2 Special clearing of strict/warnings

Since most people want exactly the strictness and warnings they specify, sanity will
clear these out first before running through the list.

   # This...
   use sanity qw(strict -strict/vars);

   # ...is the same as this...
   no strict;
   use strict qw(subs refs);

Also, some special magic is in place to ensure that newer warnings/features aren't
fatal to older Perls.  See L<https://rt.perl.org/rt3/Ticket/Display.html?id=112920>.

=head2 "Author" pragmas

Certain pragmas really only exist to make sure the code is designed right.  These
pragmas are deemed "optional" by C<sanity>.  In other words, if the user doesn't
have them, it will just silently ignore them and move on.  If C<sanity> thinks you're
an author/coder of the module itself (.git/svn/$ENV checks), it will give you a
warning that they are missing, but move on.

The following modules don't "instadie".  Modules that fall under this list don't
change the nature of how Perl works, or would let you do something that would
normally fatally error.

   overloading
   autovivification
   indirect
   multidimensional
   bareword::filehandles
   criticism

   # (autovivification probably shouldn't be here, since it actually
   # prevents autoviv, but it's generally used as an author tool.)

This feature was borrowed from L<strictures> and tweaked.

=head1 LIST OF FLAGS

=head2 Emulation of "meta pragmas"

   ex::caution:
      strict
      warnings
   NO:crap:  # Same as above
   shit:     # Same as above
   latest:
      strict
      warnings
      feature
   sane:
      strict
      warnings
      feature
      utf8
   NO:nonsense:
      strict
      warnings
      true
      namespace::autoclean
   Modern::Perl:
      strict
      warnings
      mro 'dfs'
      feature
      IO::File
      IO::Handle
   strictures: (without the 5.8.4 checks; that crap is old)
      v5.8.4 (forced, to make sure things work)
      strict
      warnings FATAL => 'all'
      no indirect 'fatal'
      no multidimensional
      no bareword::filehandles
   common::sense: (without the "memory usage" BS)
      utf8
      strict qw(subs vars)
      feature qw(say state switch)
      no warnings
      warnings FATAL => qw(closed threads internal debugging pack malloc portable prototype
                           inplace io pipe unpack deprecated glob digit printf
                           layer reserved taint closure semicolon)
      no warnings qw(exec newline unopened);
   uni::perl: (ditto)
      v5.10
      strict
      feature qw(say state switch)
      no warnings
      warnings qw(FATAL closed threads internal debugging pack substr malloc
                      unopened portable prototype inplace io pipe unpack regexp
                      deprecated exiting glob digit printf utf8 layer
                      reserved parenthesis taint closure semicolon)
      no warnings qw(exec newline)
      utf8
      open (:utf8 :std)
      mro 'c3'
      Carp
   sanity:
      v5.10.1
      utf8
      open (:utf8 :std)
      mro 'c3'
      strict qw(subs vars)
      no strict 'refs'
      warnings FATAL => 'all'
      no warnings qw(uninitialized experimental::smartmatch)
      feature '5.10'
      no autovivification qw(fetch exists delete store strict)
      no indirect 'fatal'
      no multidimensional
   perl5i::0 / 1 / 2 / latest:
      [the real module] (the pragma is too insane to try to duplicate here)
   Acme::Very::Modern::Perl:  (a joke, but it's still here all the same)
      strict
      warnings
      mro 'c3'
      feature
      IO::File
      IO::Handle
      utf8
      open (:utf8 :std)
      no warnings
      warnings FATAL => qw(closed threads internal debugging pack malloc portable prototype
                           inplace io pipe unpack deprecated glob digit printf
                           layer reserved taint closure semicolon)
      no warnings qw(exec newline unopened);
      perl5i::latest
      Toolkit
      Carp

=head2 Other flags/aliases

   strict/* => strict '[whatever]'        # supports all flags
   strict   => strict qw(refs subs vars)

   # other "hints"
   integer
   locale
   bytes
   re/taint
   re/eval
   filetest
   utf8
   NO:overloading

   warnings/*       => warnings NONFATAL => '[whatever]'  # supports all flags, multi or not
   warnings/*/FATAL => warnings    FATAL => '[whatever]'  # supports all flags; FATAL trumps NONFATAL
   warnings         => warnings NONFATAL => 'all'
   warnings/FATAL   => warnings    FATAL => 'all'

   feature/*        => feature '[whatever]'  # supports all flags
   feature/5.##     => # similar to feature enabling via 'use v5.##'; major version only
   feature/5.9.5    => # also exists, just like feature/5.10
   feature          => feature ':all'  # not exactly, but in spirit

   # Perl versions, described above
   v5.##.##

   # autodie
   autodie/* => autodie ':[whatever]'  # supports all _category_ flags, like all, io, shm, etc.
                                       # (Will expand if requested, but I don't want to waste
                                       # all of that bit space right now.)
   autodie   => autodie ':default'

   # other CORE pragmas
   bigint
   bignum
   bigrat
   charnames
   charnames/short
   charnames/full
   encoding::warnings
   encoding::warnings/FATAL
   mro/dfs                    # default for 'mro'
   mro/c3
   open/*

   # namespace cleaners
   namespace::clean       # included last; adds -except => 'meta'
   namespace::functions   # included last
   namespace::autoclean
   namespace::sweep

   # others
   NO:autovivification/*
   NO:autovivification => no autovivification qw(fetch exists delete)

   criticism/*
   criticism   => criticism 'gentle'

   experimental/*

   perl5i::0
   perl5i::1
   perl5i::2
   perl5i::3
   perl5i::latest

   NO:indirect
   NO:indirect/global
   NO:indirect/fatal
   NO:multidimensional
   NO:bareword::filehandles

   subs::auto
   utf8::all
   IO::File
   IO::Handle
   IO::All
   Carp
   vendorlib
   true
   autolocale
   Toolkit

   Function::Parameters
   Function::Parameters/strict
   Switch::Plain
   Quote::Code

Am I missing something?  Let me know.

=head1 TODO

Actually need to write sanity::sanity POD.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/sanity>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/sanity/>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and talk to this person for help: SineSwiper.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests via L<https://github.com/SineSwiper/sanity/issues>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 CONTRIBUTOR

=for stopwords Graham Knop

Graham Knop <haarg@haarg.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
