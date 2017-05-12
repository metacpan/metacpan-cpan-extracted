use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tree::Family',
    AUTHOR              => 'Brian Duggan <bduggan@matatu.org>',
    VERSION_FROM        => 'lib/Tree/Family.pm',
    ABSTRACT_FROM       => 'lib/Tree/Family.pm',
    EXCLUDE_EXT         => [qw/swp/],
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'Data::Faker'           => 0,
        'List::Util'            => 0,
        'Sub::Installer'        => 0,
        'Clone'                 => 0,
        'Algorithm::Permute'    => 0,
        'List::MoreUtils'       => 0,
        'Text::GenderFromName'  => 0,
        'Lingua::EN::NameParse' => 0,
        'File::Temp'            => 0,
        'YAML::XS'              => 0,
      },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tree-Family-*' },
);
