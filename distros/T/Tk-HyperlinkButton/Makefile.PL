use 5.016000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::HyperlinkButton',
    VERSION_FROM      => 'lib/Tk/HyperlinkButton.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
		# e.g., Module::Name => 1.1
		'Tk' => '804',
		'Browser::Open' => '0.04',
		'ExtUtils::MakeMaker' => '6.98',
	},
    ABSTRACT_FROM     => 'lib/Tk/HyperlinkButton.pm', # retrieve abstract from module
    AUTHOR            => 'Alexander Becker <asb@cpan.org>',
    
	#Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    LICENSE           => 'perl',
	MIN_PERL_VERSION  => 5.16.3, # unicode support
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/asb-capfan/Tk-HyperlinkButton',
        },
    },
);
