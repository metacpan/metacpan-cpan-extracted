use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	    => 'WDDX',
    VERSION_FROM    => 'WDDX.pm', # finds $VERSION
    PREREQ_PM	    => { 
        'Carp'         => 0,
        'MIME::Base64' => 0,
	'Time::Local'  => 0,
	'XML::Parser'  => 2,
    },
    clean	    => { 
	FILES => 'WDDX-*'
    },
);
