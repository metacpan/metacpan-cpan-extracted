use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'			=> 'Time::Interval',
    'VERSION_FROM'	=> 'Interval.pm',
    'ABSTRACT_FROM'	=> 'Interval.pod',
    'AUTHOR'		=> 'Andrew N. HIcox <andrew@hicox.com>',
    'PREREQ_PM'		=> {
    	'Date::Parse'	=> '2.20'
    }
);
