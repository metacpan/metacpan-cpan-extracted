use ExtUtils::MakeMaker;

WriteMakefile (
    NAME                => 'Time::Format',
    VERSION_FROM        => 'lib/Time/Format.pm', # finds $VERSION
    PREREQ_PM =>
    {
     'Test::Simple'     => '0.40',
     'Time::Local'      => '1.07',
    },
    PL_FILES            => {},

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Time/Format.pm', # retrieve abstract from module
       AUTHOR     => 'Eric Roode <roode@cpan.org>') : ()),
    (MM->can('signature_target')? (SIGN => 1) : ()),
);
