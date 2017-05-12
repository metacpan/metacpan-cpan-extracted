

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'VK::App',
    VERSION_FROM => 'lib/VK/App.pm', # finds \$VERSION
    AUTHOR       => 'Misha Genaev (mag@cpan.org)',
    LICENSE      => 'perl_5',
    ABSTRACT     => 'Creation client applications for vk.com',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'LWP' => 5.834,
                     'LWP::Protocol::https' => '0',
                     'JSON' => 2.53,
                    },
    META_MERGE   => {
          requires  => { perl => '5.008008' },
          resources => {
            homepage    => 'http://genaev.com/',
            license     => 'http://dev.perl.org/licenses/',
                       },
                    },
);

