use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'XML::Driver::HTML',
    'VERSION_FROM' => 'HTML.pm',
    'EXE_FILES'    => [ 'html2xhtml' ],
    'PREREQ_PM'    => {
    	'XML::Parser::PerlSAX' => 0.06,
    	'XML::Handler::YAWriter' => 0.20,
	'IO::File' => 1.06,
	'HTML::Parser' => 3.07,
	'HTML::TreeBuilder' => 2.96,
        'Digest::MD5' => 2.09
	}
);
