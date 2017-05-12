
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'Test::MultiFork',
	'DISTNAME' => 'Test-MultiFork',
	'VERSION_FROM' => 'MultiFork.pm',
	($] >= 5.005 ?
	    ('ABSTRACT' => 'Test wrapper for multi-process systems',
	     'AUTHOR'	=> 'David Muir Sharnoff <muir@idiom.com>') : ()),
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'},
	'PREREQ_PM' => {
		'IO::Event' => 0.504,
		'Filter::Util::Call' => 0,
		'Event' => 0,
		'IO::Handle' => 0,
		'Time::HiRes' => 0,
		'Storable' => 0,
	 },

);

package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: MultiFork.pod
\tpod2text MultiFork.pod >README

END_OF_POSTAMBLE
}

