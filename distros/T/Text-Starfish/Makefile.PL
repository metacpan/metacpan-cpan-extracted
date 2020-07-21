use ExtUtils::MakeMaker;

WriteMakefile(
 'NAME'     => 'Text::Starfish',
 'ABSTRACT' => 'Perl-based System for '.
	       'Preprocessing and Text-Embedded Programming',
 'VERSION_FROM' => 'Starfish.pm', # finds $VERSION
 'PREREQ_PM' => {}, # e.g., Module::Name => 1.1
 ($] >= 5.005 ? (   # Add these new keywords supported since 5.005
   #ABSTRACT_FROM => 'Starfish.pm', # cannot be used due to non-standard
		                  # line after =head1 NAME; I feel it is
		                  # important to mention command "starfish"
   AUTHOR => 'Vlado Keselj vlado@dnlp.ca and contributing authors',
   LICENSE          => 'artistic_1',
 ) : ()),
 'dist'  => {'COMPRESS'=>'gzip', 'SUFFIX' => 'gz'},
 'clean' => {FILES => "tmp* Text *~"},
 EXE_FILES => [ 'starfish' ],
);

# parts of Makefile used only in development, web publishing, and similar.
# The file 'priv.make' is not publicly released currently, but if there is
# interest it or parts of it can be released in the future.
if (-f 'priv.make' ) {
    open(M, ">>Makefile") or die;
    open(I,"priv.make") or die;
    while (<I>) { print M }
    close(M); close(I);
}
