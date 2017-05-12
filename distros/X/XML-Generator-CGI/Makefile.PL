use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::Generator::CGI',
    'VERSION_FROM'	=> 'CGI.pm', # finds $VERSION
    'PREREQ_PM'		=> { CGI => 0,
                             XML::SAX::Base => 0 }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'CGI.pm', # retrieve abstract from module
       AUTHOR     => 'Michael K. Neylon <mneylon-pm@masemware.com>') : ()),
);
