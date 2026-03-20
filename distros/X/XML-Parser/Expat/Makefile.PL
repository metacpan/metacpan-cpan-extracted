use ExtUtils::MakeMaker;
use Config;

my $expat_libpath = $ENV{EXPATLIBPATH} || '';
my $expat_incpath = $ENV{EXPATINCPATH} || '';

my $libs = "-lexpat";
my @extras = ();

push(@extras, INC => "-I$expat_incpath") if $expat_incpath;

$libs = "-L$expat_libpath $libs" if $expat_libpath;

push(@extras,
    ABSTRACT => "Lowlevel access to James Clark's expat XML parser",
    AUTHOR   => 'Matt Sergeant (matt@sergeant.org)')
  if ($ExtUtils::MakeMaker::VERSION >= 5.4301);

WriteMakefile(
    NAME	=> 'XML::Parser::Expat',
    C         => ['Expat.c'],
    LIBS	=> $libs,
    XSPROTOARG => '-noprototypes',
    VERSION_FROM => 'Expat.pm',
    @extras
);
