######################################################################
# Makefile.PL for Text::Language::Guess
# 2005, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Text::Language::Guess',
    'VERSION_FROM' => 'lib/Text/Language/Guess.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Log::Log4perl      => 1.0,
        Text::ExtractWords => 0,
        Lingua::StopWords  => 0,
        File::Spec         => 0,
        File::Basename     => 0,
    },
    'EXE_FILES' => ['eg/language-guess'],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Text/Language/Guess.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
