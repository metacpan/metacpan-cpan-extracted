use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Tree::RedBlack',
    'PM'	=> {'RedBlack.pm'	=> '$(INST_LIBDIR)/RedBlack.pm',
		    'Node.pm'		=> '$(INST_LIBDIR)/RedBlack/Node.pm'},
    'VERSION_FROM' => 'RedBlack.pm', # finds $VERSION
    'dist'	=> {COMPRESS => 'gzip', SUFFIX => 'gz'},
);
