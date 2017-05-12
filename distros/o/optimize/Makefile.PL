use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile
  (
   'NAME'		=> 'optimize',
   'VERSION_FROM'	=> 'lib/optimize.pm',
   'PREREQ_PM'	=>
   {
    'DynaLoader'  => 0,
    'Attribute::Handlers' => 0,
    'B::Generate' => '1.34',
    'B::Utils'    => 0,
    #'B::Hooks::EndOfScope' => '0.09',
    'optimizer'   => '0.06',
   },
   AUTHOR        => 'Artur Bergman, Reini Urban',
   ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE'  =>
     {
      resources =>
      {
       license     => 'http://dev.perl.org/licenses/',
       repository  => 'http://github.com/rurban/optimize',
      },
     }
    ) : ()),
  );

sub MY::depend { "
README : lib/optimize.pm 
	pod2text lib/optimize.pm > README

cover : cover_db/coverage.html

cover_db/coverage.html :
	PERL5OPT=-MDevel::Cover make test
	\$(PERL) -S cover
"; }

