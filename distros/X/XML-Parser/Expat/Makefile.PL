use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use lib '../inc';
use Devel::CheckLib;

my $expat_libpath = $ENV{EXPATLIBPATH} || '';
my $expat_incpath = $ENV{EXPATINCPATH} || '';

my $libs = "-lexpat";
my @extras = ();
my @defines = ();

push(@extras, INC => "-I$expat_incpath") if $expat_incpath;

$libs = "-L$expat_libpath $libs" if $expat_libpath;

push(@extras,
    ABSTRACT => "Lowlevel access to James Clark's expat XML parser",
    AUTHOR   => 'Matt Sergeant (matt@sergeant.org)')
  if ($ExtUtils::MakeMaker::VERSION >= 5.4301);

# Feature-detect AllocTracker API (added in libexpat 2.7.2, removed in 2.7.5)
if (check_lib(
    lib      => [qw(expat)],
    header   => ['expat.h'],
    function => 'XML_SetAllocTrackerMaximumAmplification(NULL, 1.0); return 0;',
    ccflags  => '-Werror=implicit-function-declaration',
    ($expat_incpath ? (incpath => $expat_incpath) : ()),
    ($expat_libpath ? (libpath => $expat_libpath) : ()),
)) {
    push @defines, '-DHAVE_XML_SETALLOCTRACKER';
}

push(@extras, DEFINE => join(' ', @defines)) if @defines;

WriteMakefile(
    NAME	=> 'XML::Parser::Expat',
    C         => ['Expat.c'],
    LIBS	=> $libs,
    XSPROTOARG => '-noprototypes',
    VERSION_FROM => 'Expat.pm',
    @extras
);
