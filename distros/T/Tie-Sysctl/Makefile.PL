use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Tie::Sysctl',
    'VERSION_FROM'	=> 'Sysctl.pm',
    'PREREQ_PM'		=> {},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (AUTHOR     => 'Raoul Zwart <rlzwart@cpan.org>') : ()),
);
