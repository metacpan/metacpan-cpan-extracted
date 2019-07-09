use 5.008_001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

use Config;

my @DEFINES;
my %macro;

my $is_gcc_34 = 0;
print "Checking if this is gcc 3.4 on Windows trying to link against an import library... ";
if ($^O eq 'MSWin32' and not grep /^LD[A-Z]*=/, @ARGV) {
 my ($libperl, $gccversion) = map $_ || '', @Config{qw<libperl gccversion>};
 if ($gccversion =~ /^3\.4\.[0-9]+/ and $libperl =~ s/\.lib$//) {
  $is_gcc_34 = 1;
  my ($lddlflags, $ldflags) = @Config{qw<lddlflags ldflags>};
  $_ ||= '', s/-L(?:".*?"|\S+)//g for $lddlflags, $ldflags;
  $libperl = "-l$libperl";
  my $libdirs = join ' ',
                 map { s/(?<!\\)((?:\\\\)*")/\\$1/g; qq[-L"$_"] }
                  @Config{qw<bin sitebin>};
  $macro{LDDLFLAGS}    = "$lddlflags $libdirs $libperl";
  $macro{LDFLAGS}      = "$ldflags $libdirs $libperl";
  eval <<'  MY_SECTION';
   package MY;
   sub dynamic_lib {
    my $self = shift;
    my $inherited = $self->SUPER::dynamic_lib(@_);
    $inherited =~ s/"?\$\(PERL_ARCHIVE\)"?//g;
    return $inherited;
   }
  MY_SECTION
  die $@ if $@;
 }
}
print $is_gcc_34 ? "yes\n" : "no\n";

# Threads, Windows and 5.8.x don't seem to be best friends
if ($^O eq 'MSWin32' and "$]" < 5.009) {
 push @DEFINES, '-DXSH_MULTIPLICITY=0';
}

# Fork emulation got "fixed" in 5.10.1
if ($^O eq 'MSWin32' and "$]" < 5.010_001) {
 push @DEFINES, '-DXSH_FORKSAFE=0';
}

@DEFINES = (DEFINE => join ' ', @DEFINES) if @DEFINES;
%macro   = (macro  => { %macro })         if %macro; # Beware of the circle

my $dist = 'indirect';

(my $name = $dist) =~ s{-}{::}g;

(my $file = $dist) =~ s{-}{/}g;
$file = "lib/$file.pm";

my %PREREQ_PM = (
 'Carp'     => 0,
 'XSLoader' => 0,
);

my %BUILD_REQUIRES =(
 'Config'              => 0,
 'ExtUtils::MakeMaker' => 0,
 'File::Spec'          => 0,
 'IO::Handle'          => 0,
 'IO::Select'          => 0,
 'IPC::Open3'          => 0,
 'POSIX'               => 0,
 'Socket'              => 0,
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
  repository => "http://git.vpit.fr/?p=perl%2Fmodules%2F$dist.git",
 },
);

WriteMakefile(
 NAME             => $name,
 AUTHOR           => 'Vincent Pit <vpit@cpan.org>',
 LICENSE          => 'perl',
 VERSION_FROM     => $file,
 ABSTRACT_FROM    => $file,
 PL_FILES         => {},
 @DEFINES,
 BUILD_REQUIRES   => \%BUILD_REQUIRES,
 PREREQ_PM        => \%PREREQ_PM,
 MIN_PERL_VERSION => '5.008001',
 META_MERGE       => \%META,
 dist             => {
  PREOP    => "pod2text -u $file > \$(DISTVNAME)/README",
  COMPRESS => 'gzip -9f', SUFFIX => 'gz'
 },
 clean            => {
  FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt*"
 },
 %macro,
);
