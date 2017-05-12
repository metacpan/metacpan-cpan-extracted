use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WWW::Search::FirstGov',
    'VERSION_FROM'	=> 'FirstGov.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                             'WWW::Search' => 2.33,
                             'WWW::Search::Test' => 2.16,
                           }
);
