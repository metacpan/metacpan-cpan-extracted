use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Zeal',
	VERSION_FROM      => 'lib/Zeal.pm',
	ABSTRACT_FROM     => 'lib/Zeal.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Archive::Tar           0
		   Class::Accessor::Fast  0
		   DBI                    0
		   DBD::SQLite            0
		   File::Slurp            0
		   File::Which            0
		   Mac::PropertyList::SAX 0
		   XML::Rules             0/,
	},
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'http://git.ieval.ro/?p=zeal.git',
		},
		recommends     => {
			qw/IO::Zlib                0
			   IO::Uncompress::Bunzip2 0/,
		},
	}
);
