use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'            => 'XML::Filter::NSNormalise',
    'VERSION_FROM'    => 'lib/XML/Filter/NSNormalise.pm',
    'PREREQ_PM'       => {
                           Test::Simple          => 0.41,
			   XML::SAX              => 0.11,
			   XML::SAX::Writer      => 0.44,
			   XML::NamespaceSupport => 1.08,
                         },
    'EXE_FILES'       => [ qw(bin/xmlnsnorm) ],
    ($] >= 5.005 ?  (
      AUTHOR        => 'Grant McLean <grantm@cpan.org>',
      ABSTRACT_FROM => 'lib/XML/Filter/NSNormalise.pm',
    ) : ()),
);
