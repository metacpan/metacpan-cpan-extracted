use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'		=> 'WWW::LEO',
	      'VERSION_FROM'	=> 'LEO.pm',
	      'PREREQ_PM'		=> {
					    LWP::UserAgent   => 0,
					    HTML::TokeParser => 0,
					    URI::Escape      => 0,
					   },
	      ($] >= 5.005 ? (AUTHOR => 'Joerg Ziefle <ziefle@cpan.org>') : ()),
);
