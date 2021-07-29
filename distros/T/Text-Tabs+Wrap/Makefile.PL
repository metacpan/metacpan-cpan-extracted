use 5.006; use strict; use warnings;

use ExtUtils::MakeMaker;

my $u = 'github.com/ap/Text-Tabs';

WriteMakefile( 
	'NAME'		=> 'Text::Wrap',
	'DISTNAME'	  => 'Text-Tabs+Wrap',
	'VERSION_FROM' => 'lib.modern/Text/Wrap.pm',
			ABSTRACT	=> 'Expand tabs and do simple line wrapping',
			AUTHOR		=> 'David Muir Sharnoff <muir@idiom.org>',
	( eval { ExtUtils::MakeMaker->VERSION(6.48) } ?
		(
			MIN_PERL_VERSION => '5.006',
			META_MERGE	=> {
				dynamic_config => 0,
				resources  => {
					repository => { type => 'git', url => "git://$u.git", web => "https://$u" },
					bugtracker => { web => "https://$u/issues" },
				},
				'meta-spec' => { version => 2 },
			}
		) 
		: 
		()
	),
	INSTALLDIRS => ( "$]" >= 5.011 ? 'site' : 'perl' ),

	MAN3PODS =>
		{
			'lib.modern/Text/Tabs.pm'	=> '$(INST_MAN3DIR)/Text::Tabs.$(MAN3EXT)',
			'lib.modern/Text/Wrap.pm'	=> '$(INST_MAN3DIR)/Text::Wrap.$(MAN3EXT)',
		},
	PM =>
		{
			'lib.modern/Text/Tabs.pm'	=> '$(INST_LIBDIR)/Tabs.pm',
			'lib.modern/Text/Wrap.pm'	=> '$(INST_LIBDIR)/Wrap.pm',
		}
	);

sub MY::postamble { -f 'META.yml' ? return : <<'' }
create_distdir : MANIFEST
distdir        : MANIFEST
MANIFEST :
	( echo MANIFEST ; git ls-files ) | sort -f > MANIFEST

