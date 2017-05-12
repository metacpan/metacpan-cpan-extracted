

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::Vimeo::Download',
    VERSION_FROM => 'lib/WWW/Vimeo/Download.pm', # finds \$VERSION
    AUTHOR       => 'Hernan Lopes',
    ABSTRACT     => 'interface to download vimeo videos',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Moose'=>0,
                     'XML::XPath'=>0,
                     'HTTP::Tiny'=>0,
#                    'HTTP::Request'=>0,
#                    'Perl6::Form'=>0,
                    },
);
