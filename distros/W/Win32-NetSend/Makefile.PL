use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Win32::NetSend',
    'VERSION_FROM'	=> 'NetSend.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Win32::API' => 0.01, },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (
		'ABSTRACT' => 'Sends message from NT to NT or Win9x running winpopup',
		#ABSTRACT_FROM	=> 'NetSend.pm', # retrieve abstract from module
		AUTHOR			=> 'Victor Sanchez (vsanchez@cpan.org)') : ()),
);

