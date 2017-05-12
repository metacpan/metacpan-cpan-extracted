use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'XML::Writer::String',
    'VERSION_FROM'	=> 'String.pm',
    'PREREQ_PM'		=> {XML::Writer => 0},
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'String.pm',
       AUTHOR     => 'S. Oliver <simon.oliver@umist.ac.uk>') : ()),
);
