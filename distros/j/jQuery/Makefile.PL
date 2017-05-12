use 5.010001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'jQuery',
    VERSION_FROM      => 'lib/jQuery.pm',
    PREREQ_PM         => {
	'XML::LibXML' => 0,
	'LWP::UserAgent' => 0,
	'HTML::Entities' => 0,
	'HTTP::Request::Common' => 0
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/jQuery.pm', # retrieve abstract from module
       AUTHOR         => 'Mamod A. Mehyar <mamod.mehyar@gmail.com>') : ()),
);
