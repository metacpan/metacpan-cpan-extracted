use 5.012004;
use ExtUtils::MakeMaker;
use lib 'inc';
use Devel::CheckLib;
check_lib_or_exit(lib => 'udt');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'UDT::Simple',
    VERSION_FROM      => 'lib/UDT/Simple.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/UDT/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'borislav nikolov <jack@sofialondonmoskva.com>') : ()),
    LIBS              => ['-ludt'], # e.g., '-lm'
    CC                => 'g++',
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    CCFLAGS           => '-Wno-deprecated-declarations',
    INC               => "-I. -I/usr/include -I/usr/local/include -I/usr/include/udt -I/usr/local/include/udt -I$ENV{UDT_INCLUDE}", # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    'XSOPT'             => '-C++',
    'TYPEMAPS'          => ['perlobject.map' ],
);
