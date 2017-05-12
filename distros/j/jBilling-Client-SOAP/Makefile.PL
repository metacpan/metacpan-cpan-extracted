use 5.010;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'jBilling::Client::SOAP',
    VERSION_FROM => 'lib/jBilling/Client/SOAP.pm',    # finds $VERSION
    PREREQ_PM    => {
        Class::Throwable => 0.11,
        Moose            => 2.1403,
        SOAP::Lite       => 1.11,
    },    # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/jBilling/Client/SOAP.pm',    # retrieve abstract from module
            AUTHOR => 'Aaron Guise <guisea@cpan.org'
          )
        : ()
    ),
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url => 'https://bitbucket.org/guisea/jbilling-client-soap.git',
                web => 'https://bitbucket.org/guisea/jbilling-client-soap',
				bugtracker => 'https://bitbucket.org/guisea/jbilling-client-soap/issues',
            },
        },
    },
);
