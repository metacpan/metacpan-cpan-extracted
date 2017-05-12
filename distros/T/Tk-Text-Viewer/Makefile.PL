use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#sub MY::clean
#{
#    package MY; # so that "SUPER" works right
#    my $inherited = shift->SUPER::clean(@_);
#    $inherited .= <<EOF;
#	-rm -rf misc/*.x~~ *.bak *.x~~
#EOF
#    $inherited; 804.027
#}
WriteMakefile(
    'NAME'        => 'Tk::Text::Viewer',
    'VERSION_FROM'    => 'Viewer.pm', # finds $VERSION
    'PREREQ_PM'        => {'Tk'             => 0}, 
    'EXE_FILES'    =>     => ['scripts/viewer.pl'],
    'clean' => {FILES => 'misc/*.bak misc/*.x~~ *.bak *.x~~'},
    'dist' => { PREOP=> 'chmod -R u=rwX,go=rX . ;' . 
		'sudo chown -R oded:users *;' . 
		'misc/prepare.pl > prepare.log.x~~' ,
		COMPRESS=>"gzip --best --force", 
		SUFFIX=>".gz", DIST_DEFAULT => 'all tardist'},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ('ABSTRACT' => 'Read only Tk Text Widget with search capability',
       AUTHOR     => 'Oded S. Resnik <razinf at cpan.org>') : ()),
);
