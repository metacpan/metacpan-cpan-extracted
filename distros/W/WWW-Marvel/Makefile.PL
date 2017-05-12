

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::Marvel',
    VERSION_FROM => 'lib/WWW/Marvel.pm', # finds \$VERSION
    AUTHOR       => 'Simone Tampieri (simotrone@gmail.com)',
    ABSTRACT     => 'A Marvel Comics API',
    MIN_PERL_VERSION => "5.10.1",
    PREREQ_PM    => {
					 'Carp' => 0,
					 'Class::Accessor' => 0,
					 'Config::Tiny' => 0,
					 'Cwd' => 0,
					 'Digest::MD5' => 0,
					 'File::Basename' => 0,
					 'File::Spec::Functions' => 0,
					 'JSON' => 0,
					 'LWP::UserAgent' => 0,
					 'Module::Load' => 0,
					 'Test::Exception' => 0,
					 'Test::More' => 0,
					 'Test::Simple' => 0.44,
					 'URI' => 0,
                    },
);
