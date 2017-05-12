use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'WWW::Pipeline',
    VERSION_FROM => 'lib/WWW/Pipeline.pm',
    AUTHOR       => 'Stephen Howard <howars@alum.rpi.edu>',
    ABSTRACT     => 'Subclass of Application::Pipeline for creating web applications',
    PREREQ_PM    => {
        'Application::Pipeline' => 0.1,
        'CGI::Simple' => 0.071
    },
);

