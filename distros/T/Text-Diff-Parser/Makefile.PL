use 5.00404;
use ExtUtils::MakeMaker;

eval "use ExtUtils::MakeMaker::Coverage;";




WriteMakefile(
    NAME              => 'Text::Diff::Parser',
    VERSION_FROM      => 'lib/Text/Diff/Parser.pm', # finds $VERSION
    LICENSE           => 'perl',
    PREREQ_PM         => {'Test::More'  =>  0, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Philip Gwyn <gwyn-at-cpan.org>',
       ABSTRACT       => 'Parse patches containing unified and standard diffs',
      ) : ()),
);
