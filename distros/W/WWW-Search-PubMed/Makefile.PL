# use ExtUtils::MakeMaker;
use inc::Module::Install;

license				'perl';

WriteMakefile(
				NAME			=> 'WWW::Search::PubMed',
				ABSTRACT		=> 'Search the NCBI PubMed abstract database.',
				VERSION_FROM	=> 'lib/WWW/Search/PubMed.pm',
				AUTHOR			=> 'Gregory Todd Williams <gwilliams@cpan.org>',
				PREREQ_PM		=> {
									'WWW::Search'		=> 0,
									'LWP::UserAgent'	=> 0,
									'XML::DOM'			=> 0
								},
			);
