use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'YAML::LibYAML::API::XS',
    VERSION_FROM   => 'lib/YAML/LibYAML/API/XS.pm',
    PREREQ_PM      => { 'Test::More' => 0, 'Exporter' => '5.57' },
    ABSTRACT_FROM  => 'lib/YAML/LibYAML/API/XS.pm',
    AUTHOR         => 'You',
    LIBS           => ['-lyaml'],
    DEFINE         => '',
    INC            => '-I.',
    OBJECT         => '$(O_FILES)',
);
