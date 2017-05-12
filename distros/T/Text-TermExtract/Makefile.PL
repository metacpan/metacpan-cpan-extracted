######################################################################
# Makefile.PL for Text::TermExtract
# 2007, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Text::TermExtract',
    'VERSION_FROM' => 'TermExtract.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Lingua::StopWords     => 0.08,
        Text::Language::Guess => 0.02,
        Log::Log4perl         => 1.0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'TermExtract.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
