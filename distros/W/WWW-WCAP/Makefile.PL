use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME		=> 'WWW::WCAP',
	VERSION_FROM	=> 'lib/WWW/WCAP.pm', # finds $VERSION
	PREREQ_PM	=> {
				'Benchmark::Timer'	=> 0, # for test
				'LWP::UserAgent'	=> 0, # for comms
				'Date::Calc'		=> 0, # for parsing
			},
	($] >= 5.005 ?    ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM => 'lib/WWW/WCAP.pm', # retrieve abstract from module
		 AUTHOR     => 'Nathan Bailey <nate@cpan.org>') : ()),
	'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);


# Based on libwww-perl's Makefile.PL
package MY;

# What happens when we say 'make test'
sub test {
    q(
TEST_VERBOSE=0

test: all
	$(FULLPERL) t/TEST $(TEST_VERBOSE)

);
}
