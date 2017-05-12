use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

print "Writing Makefile for Perl version $].\n";

WriteMakefile (NAME => 'EC::About.pm');

WriteMakefile (NAME => 'EC::Attachments.pm',
	PREREQ_PM => {'MIME::Base64' => undef});

WriteMakefile (NAME => 'EC::ECConfig.pm');

WriteMakefile (NAME => 'EC::PasswordDialog.pm');

WriteMakefile (NAME => 'Tk::ECWarning.pm');

WriteMakefile (NAME => 'Tk::SimpleFileSelect.pm');

WriteMakefile (NAME => 'EC::Utilities.pm');

WriteMakefile (NAME => 'EC::ECIcon.pm');

if ($] =~ /5.004/) {
	WriteMakefile (
	'NAME'	=> 'ec',
	'VERSION_FROM'	=> 'ec',
	'EXE_FILES'	=> ['ec'],
	'PREREQ_PM'	=> { 'Tk' => '800.022' },
	    'AUTHOR'        => 'Robert Allan Kiesling <rkiesling@earthlink.net>',
	);
} else {
	WriteMakefile(
	    'NAME'	=> 'ec',
	    'VERSION_FROM' => 'ec', 
	    'EXE_FILES'  => ['ec'],
	    'PREREQ_PM'  => { 'Tk' => undef },
	    'AUTHOR'        => 'Robert Allan Kiesling <rkiesling@earthlink.net>',
	);
}


