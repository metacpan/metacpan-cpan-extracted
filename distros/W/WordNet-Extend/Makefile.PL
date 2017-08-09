use 5.018002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @word2vec = qw (word2vecSimilarity.py);


WriteMakefile(
    NAME              => 'WordNet::Extend',
    VERSION_FROM      => 'lib/WordNet/Extend.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1

    'INSTALLSITEBIN'=> '$(INST_BIN)',
    'LIB'=> '$(INST_LIB)',
    'INSTALLSITEARCH'=> '$(INST_ARCHLIB)',

    'EXE_FILES'=> [
	map ("$_", @word2vec),
	  ],
    
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WordNet/Extend.pm', # retrieve abstract from module
       AUTHOR         => 'Jonathan D Rusert <ruse0008@>') : ()),


    
);
