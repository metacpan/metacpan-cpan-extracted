use ExtUtils::MakeMaker;
WriteMakefile(  ABSTRACT => "Select files remotely.",
               AUTHOR => "Robert Allan Kiesling <rkiesling\@earthlink.net>",
	       NAME => 'Tk::RemoteFileSelect',
	       VERSION_FROM => 'RemoteFileSelect.pm',
	       );

WriteMakefile (NAME => 'Tk::LoginDialog',
	       VERSION_FROM => 'LoginDialog.pm');
