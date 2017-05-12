use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'XML::Generator::PerlData',
    'AUTHOR'        => 'Kip Hampton <khampton@totalcinema.com>',
    'VERSION_FROM'  => 'PerlData.pm',
    'ABSTRACT_FROM' => 'PerlData.pm',
    'LICENSE'       => 'perl',
    'META_MERGE'    => {
        resources => {
            license    => 'http://dev.perl.org/licenses',
            repository => 'https://github.com/ubu/xml-generator-perldata',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'XML-Generator-PerlData-*' },
    'PREREQ_PM' => {
        'XML::SAX::Base' => 1.02
    }
);
