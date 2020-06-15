use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Text::Starfish',
    'ABSTRACT'          => 'Perl-based Framework for '.
	                   'Text-Embedded Programming and Preprocessing',
    'VERSION_FROM'	=> 'Starfish.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (
      #ABSTRACT_FROM => 'Starfish.pm', # retrieve abstract from module
	AUTHOR     => 'Vlado Keselj http://web.cs.dal.ca/~vlado and '.
	              'contributing authors',
	LICENSE          => 'perlartistic',
       ) : ()),
    'dist'  => {'COMPRESS'=>'gzip', 'SUFFIX' => 'gz'},
    'clean' => {FILES => "tmp* Text *~"},
    EXE_FILES => [ 'starfish' ],
);

# parts of Makefile used only in the development directory
if (-f 'priv.make' ) {
    open(M, ">>Makefile") or die;
    open(I,"priv.make") or die;
    while (<I>) { print M }
    close(M); close(I);
}
