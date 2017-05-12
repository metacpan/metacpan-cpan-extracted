use 5.010;

use strict;
use warnings;
use ExtUtils::MakeMaker;

use Config;

if ($Config{d_cplusplus}) {
 print STDERR <<'FAILPLUSPLUS';
Configuration aborted: C++ compilers are not supported

    Your perl has been built with a C++ compiler, which is then handed to
    XS extensions as if it were a proper C compiler. This extension is
    written in C, and naturally only supports C compilers, so it cannot be
    built with your perl.

    Note that building perl with a C++ compiler is only supposed to be done
    by core developers in order to check that the perl headers can be
    included from C++ code. Its use in the wild is not supported by the
    perl5 porters. If your vendor has built its perl binary with a C++
    compiler, please consider reporting this issue to them.

    This text will be displayed 10 seconds, and then the configuration
    script will exit.
FAILPLUSPLUS
 sleep 10;
 exit 0;
}

my @DEFINES;

# Fork emulation got "fixed" in 5.10.1
if ($^O eq 'MSWin32' && "$]" < 5.010_001) {
 push @DEFINES, '-DXSH_FORKSAFE=0';
}

@DEFINES = (DEFINE => join ' ', @DEFINES) if @DEFINES;

my $dist = 're-engine-Plugin';

(my $name = $dist) =~ s{-}{::}g;

my %PREREQ_PM = (
 'XSLoader' => 0,
);

my %BUILD_REQUIRES = (
 'Config'              => 0,
 'ExtUtils::MakeMaker' => 0,
 'Test::More'          => 0,
 'lib'                 => 0,
 %PREREQ_PM,
);

my %META = (
 configure_requires => {
  'Config'              => 0,
  'ExtUtils::MakeMaker' => 0,
 },
 build_requires => {
  %BUILD_REQUIRES,
 },
 dynamic_config => 1,
 resources => {
  bugtracker => "http://rt.cpan.org/Dist/Display.html?Name=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/?p=perl%2Fmodules%2F$dist.git",
 },
);

my @AUTHORS = (
 "\x{C6}var Arnfj\x{F6}r\x{F0} Bjarmason <avar\@cpan.org>",
 'Vincent Pit <perl@profvince.com>',
);

my $AUTHOR = $ExtUtils::MakeMaker::VERSION < 6.58 ? $AUTHORS[0]
                                                  : \@AUTHORS;

WriteMakefile(
 NAME             => $name,
 AUTHOR           => $AUTHOR,
 LICENSE          => 'perl',
 ABSTRACT_FROM    => 'Plugin.pod',
 VERSION_FROM     => 'Plugin.pm',
 PL_FILES         => {},
 @DEFINES,
 PREREQ_PM        => \%PREREQ_PM,
 MIN_PERL_VERSION => '5.010',
 META_MERGE       => \%META,
 dist             => {
  PREOP    => 'pod2text -u Plugin.pod > $(DISTVNAME)/README',
  COMPRESS => 'gzip -9f', SUFFIX => 'gz'
 },
 clean            => {
  FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt"
 },
 test             => {
  TESTS => 't/*.t t/*/*.t t/*/*/*.t',
 },
);
