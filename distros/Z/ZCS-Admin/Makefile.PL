use 5.8.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'ZCS::Admin',
    AUTHOR        => 'Phil Pearl <phil@zimbra.com>',
    VERSION_FROM  => 'lib/ZCS/Admin.pm',
    ABSTRACT_FROM => 'lib/ZCS/Admin.pm',
    PREREQ_PM     => {
        'Class::Std' => "0.011",
        'SOAP::WSDL' => "2.00.10",
        'Test::More' => 0,
    },
);

package MY;

sub postamble {

    return <<'MAKE_MODULES';

wsdl2perl: src/Makefile
	cd src && $(MAKE)

MAKE_MODULES

}
