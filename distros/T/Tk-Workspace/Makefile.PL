use ExtUtils::MakeMaker;
# Refer to lib/Extutils/MakeMaker.pm for details of 
# how to influence the contents of the Makefile that
# is written.

WriteMakefile( 
	       NAME => 'Tk::XFontSelect',
	       VERSION_FROM => 'XFontSelect.pm',
	       );
	      
WriteMakefile( 
	       NAME => 'Tk::RemoteFileSelect',
	       VERSION_FROM => 'RemoteFileSelect.pm',
	       );
	      
WriteMakefile( NAME => 'Tk::Shell',
	       VERSION_FROM => 'Shell.pm',
	       );
WriteMakefile( NAME => 'Tk::SearchDialog',
	       VERSION_FROM => 'SearchDialog.pm',
	       );
WriteMakefile( NAME => 'Tk::WorkspaceText',
	       VERSION_FROM => 'WorkspaceText.pm',
	       );
WriteMakefile( NAME => 'Tk::Workspace',
	       EXE_FILES => [qw(mkws ws-upgrade)],
	       VERSION_FROM => 'Workspace.pm',
	       );
