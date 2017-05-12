use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'			=> 'XML::Parser::YahooRESTGeocode',
    'VERSION_FROM'	=> 'YahooRESTGeocode.pm',
    'ABSTRACT_FROM'	=> 'YahooRESTGeocode.pod',
    'AUTHOR'		=> 'Andrew N. Hicox  <andrew@hicox.com>',
    'PREREQ_PM'		=> {
		'XML::Parser'	=> 2.31
    }
);
