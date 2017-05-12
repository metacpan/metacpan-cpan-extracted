use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	    => 'VCS',
    'ABSTRACT_FROM' => 'lib/VCS.pm', # finds =head1 NAME line for PPD
    'VERSION_FROM'  => 'lib/VCS.pm', # finds $VERSION
    'PREREQ_PM'     => { 'URI' => 0 },
    META_MERGE => {
      "meta-spec" => { version => 2 },
      resources => {
	repository => {
	  type => 'git',
	  url => 'https://github.com/mohawk2/cpan-vcs.git',
	  web => 'https://github.com/mohawk2/cpan-vcs',
	},
      },
    },
);
