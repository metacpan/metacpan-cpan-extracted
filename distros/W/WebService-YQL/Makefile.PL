

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WebService::YQL',
    VERSION_FROM => 'lib/WebService/YQL.pm', # finds \$VERSION
    AUTHOR       => 'Viorel Stirbu (cpan@stirbu.name)',
    ABSTRACT     => 'Simple interface for Yahoo Query Language',
    PREREQ_PM    => {
        'Test::Simple' => 0.44,
        'JSON::Any' => '0',
        'URI' => '0',
        'LWP::UserAgent' => '0',
        'List::MoreUtils' => '0', # only required for tests
    },
);
