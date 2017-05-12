######################################################################
# Makefile.PL for YAML::Logic
# 2008, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/yaml-logic-perl',
        },
    }
};
WriteMakefile(
    'NAME'         => 'YAML::Logic',
    'VERSION_FROM' => 'Logic.pm', # finds $VERSION
    'PREREQ_PM'    => {
        YAML::Syck     => 0.97,
        Safe           => 2.11,
        Template       => 2.15,
        Log::Log4perl  => 1.00,
    }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Logic.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
