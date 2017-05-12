use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'XML::XForms::Validate',
    VERSION_FROM      => 'lib/XML/XForms/Validate.pm',
    PREREQ_PM         => { XML::LibXML => 1.63, XML::Schema => 0.07 },
    ABSTRACT_FROM  => 'lib/XML/XForms/Validate.pm',
    AUTHOR         => 'Jörg Walter <info@syntax-k.de>',
);
