use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => "uni::perl",
	AUTHOR       => 'Mons Anderson <mons@cpan.org>',
	PREREQ_PM    => { perl => '5.10.0' },
	ABSTRACT_FROM=> "perl.pm.PL",
	VERSION_FROM => "perl.pm.PL",
	PL_FILES     => { "perl.pm.PL" => '$(INST_LIB)/uni/perl.pm' },
	clean        => { FILES => "perl.pm" },
	META_ADD     => {
		provides => {
			'uni::perl' => {
				file => 'lib/uni/perl.pm',
				version => '0.91',
			}
		},
		license => 'perl',
	}
);

