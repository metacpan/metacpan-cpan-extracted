use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Text::WrapI18N',
    'VERSION_FROM'	=> 'WrapI18N.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    	'Text::CharWidth'	=> '0.02',
    }
);
