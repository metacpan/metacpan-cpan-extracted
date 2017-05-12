package Text::Repository;

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => __PACKAGE__,
    'VERSION_FROM' => 'Repository.pm', # finds $VERSION
);
