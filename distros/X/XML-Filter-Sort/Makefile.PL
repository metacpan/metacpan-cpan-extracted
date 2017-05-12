use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'            => 'XML::Filter::Sort',
    'VERSION_FROM'    => 'lib/XML/Filter/Sort.pm',
    'PREREQ_PM'	      => { 
                           Test::Simple       => 0.41,
                           XML::SAX           => undef,
                           XML::SAX::Writer   => undef,
		         },
    'EXE_FILES'       => [ qw(bin/xmlsort) ],
    ($] >= 5.005 ? (
      'AUTHOR'        => 'Grant McLean <grantm@cpan.org>',
      'ABSTRACT_FROM' => 'lib/XML/Filter/Sort.pm',
    ) : () )

);
