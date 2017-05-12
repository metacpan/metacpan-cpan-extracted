use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'DTS_UT',
    VERSION_FROM => 'lib/DTS_UT.pm',    # finds $VERSION
    PREREQ_PM    => {
        Class::Accessor                        => 0.31,
        CGI::Application                       => 4.06,
        CGI::Application::Plugin::Config::YAML => 0.01,
        Params::Validate                       => 0.89
    },                                  # e.g., Module::Name => 1.1
    dist => { SUFFIX => '.gz', COMPRESS => 'gzip --best' },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => 'lib/DTS_UT.pm',    # retrieve abstract from module
            AUTHOR => 'Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>'
          )
        : ()
    ),
);
