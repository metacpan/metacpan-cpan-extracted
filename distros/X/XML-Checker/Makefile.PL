use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XML::Checker',
    'VERSION_FROM' => 'lib/XML/Checker.pm', # finds $VERSION
    'PREREQ_PM' => { 'XML::Parser' => '2.30',
		     'XML::Parser::PerlSAX' => '0.07',
		     'XML::DOM' => '1.29'}
);
