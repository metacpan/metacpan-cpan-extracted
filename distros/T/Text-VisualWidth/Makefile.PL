use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Text::VisualWidth',
    VERSION_FROM      => 'lib/Text/VisualWidth.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.006 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/VisualWidth.pm', # retrieve abstract from module
       AUTHOR         => 'Takaaki Mizuno <cpan@takaaki.info>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
