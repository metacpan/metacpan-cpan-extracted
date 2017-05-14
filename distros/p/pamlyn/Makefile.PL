use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'YN00',
#    VERSION_FROM      => 'lib/YN00.pm', # finds $VERSION
#    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
#    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
#      (ABSTRACT_FROM  => 'lib/YN00.pm', # retrieve abstract from module
#       AUTHOR         => 'Wen-Yu Chung <wychung@>') : ()),
    LIBS              => ['-lm'],
    OBJECT            => 'cal_kaks.o cal_kaks_wrap.o yn.o tools.o',
);
