use ExtUtils::MakeMaker;
my %conf = (
	'NAME'         => 'Text::MediawikiFormat',
	'VERSION_FROM' => 'lib/Text/MediawikiFormat.pm',
	'PREREQ_PM'    => {
		'CGI'              => '0',
		'Scalar::Util'     => '1.14',
		'Test::More'       => '0.3',
		'Test::NoWarnings' => '0',
		'Test::Warn'       => '0',
		'URI'              => '0',
		'URI::Escape'      => '0',
		'version'          => '0.74',
		'HTML::Parser'     => '0',      # recommended only
		'HTML::Tagset'     => '0',      # recommented only

	},
	'INSTALLDIRS' => 'site',
	'LICENSE'     => 'perl',
	'EXE_FILES'   => [],
	'PL_FILES'    => {}
);

if ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ) {
	$conf{META_MERGE} = {
		'meta-spec' => { version => 2 },
		resources   => {
			repository => {
				type    => 'git',
				url     => 'http://github.com/szabgab/Text-MediawikiFormat.git',
				web     => 'http://github.com/szabgab/Text-MediawikiFormat',
				license => 'http://dev.perl.org/licenses/',
			},
			bugtracker => {
				web => 'http://github.com/szabgab/Text-MediawikiFormat/issues',
			},
		},
	};
}

WriteMakefile(%conf);

