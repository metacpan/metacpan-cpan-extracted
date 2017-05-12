use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'			=> 'Tk::FilterEntry',
	'VERSION_FROM'	=> 'FilterEntry.pm', # finds $VERSION
	'ABSTRACT'		=> "An entry with filter",
	'PREREQ_PM'		=> {
			'Tk'				=> 0
	},
	'PM'			=> {
			'FilterEntry.pm'	=> '$(INST_LIBDIR)/FilterEntry.pm'
	},
	'AUTHOR'		=> "Francois PERRAD (francois.perrad\@gadz.org)",
	'dist'			=> {
			'COMPRESS'			=> 'gzip',
			'SUFFIX'			=> '.gz',
	},
);
