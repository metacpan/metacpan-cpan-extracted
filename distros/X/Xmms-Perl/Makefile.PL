use 5.005;
use ExtUtils::MakeMaker;

use Term::ReadLine (); #for Term::ReadLine::Perl

WriteMakefile(
    'NAME'	=> 'Xmms-Perl',
    'VERSION_FROM' => 'lib/Xmms.pm',
    'PREREQ_PM'    => {	
	                 'Term::ReadLine::Perl' => 0,
		         'Term::ANSIColor'    => 0,
		         'MPEG::MP3Info'    => 0,
		      },
    'macro' => {
	  CVSROOT => 'modperl.com:/local/cvs_repository',
    },
);

sub MY::postamble { 
    return <<'EOF'; 

cvs_tag :
	cvs -d $(CVSROOT) tag v$(VERSION_SYM) . 
	@echo update lib/Xmms.pm VERSION now 
EOF
} 
