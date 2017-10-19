use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Wx::Perl::IconDepot',
    VERSION_FROM      => 'lib/Wx/Perl/IconDepot.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::More'               => 0,
        'Wx'                       => 0,
        'Module::Load::Conditional' => 0
    }, 
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Wx/Perl/IconDepot.pm', # retrieve abstract from module
       AUTHOR         => 'Hans Jeuken <hansjeuken@xs4all.nl)>') : ()),
);
