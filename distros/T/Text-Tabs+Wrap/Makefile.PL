
use ExtUtils::MakeMaker;

WriteMakefile( 
	'NAME'		=> 'Text-Wrap',
	'DISTNAME'	  => 'Text-Tabs+Wrap',
	'VERSION_FROM' => 'lib.modern/Text/Wrap.pm',
	($] >= 5.005 ? 
		(
			ABSTRACT	=> 'Expand tabs and do simple line wrapping',
			AUTHOR		=> 'David Muir Sharnoff <muir@idiom.org>',
			META_MERGE	=> {
				resources  => {
					repository => 'http://github.com/muir/Text-Tabs-Wrap',
				}
			}
		) 
		: 
		()
	),
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'INSTALLDIRS'	=> 'perl',

	PM =>	($] > 5.010 ?
		{
			'lib.modern/Text/Tabs.pm'	=> '$(INST_LIBDIR)/Text/Tabs.pm',
			'lib.modern/Text/Wrap.pm'	=> '$(INST_LIBDIR)/Text/Wrap.pm',
		}
		:
		{
			'lib.old/Text/Tabs.pm'	=> '$(INST_LIBDIR)/Text/Tabs.pm',
			'lib.old/Text/Wrap.pm'	=> '$(INST_LIBDIR)/Text/Wrap.pm',
		})

	);

