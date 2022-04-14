use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'constant::more',
	VERSION_FROM      => 'lib/constant/more.pm', 
	PREREQ_PM         => {}, 
	ABSTRACT_FROM     => 'lib/constant/more.pod',
	AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
	LICENSE           => 'mit',
	MIN_PERL_VERSION  => 'v5.24',
	META_ADD => {
		"meta-spec" => {
			version => 2
		},
		resources=> {
			repository =>{
				type => "git",
				url => "git://github.com/drclaw1394/perl-constant-more.git",
				web => "https://github.com/drclaw1394/perl-constant-more",
			}
		}
	}

);
