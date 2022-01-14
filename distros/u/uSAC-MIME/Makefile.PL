use ExtUtils::MakeMaker;
WriteMakefile(
	NAME              => 'uSAC::MIME',
	VERSION_FROM      => 'lib/uSAC/MIME.pm', 
	PREREQ_PM         => {}, 
	ABSTRACT_FROM     => 'lib/uSAC/MIME.pod', 
	AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
	LICENSE           => 'mit',
	MIN_PERL_VERSION  => "5.24.0",
	META_MERGE        => {

		"meta-spec" => { version => 2 },

		resources => {

			repository => {
				type => 'git',
				url => 'https://github.com/drclaw1394/perl-usac-mime.git',
				web => 'https://github.com/drclaw1394/perl-usac-mime',
			},

		},

	},
);
