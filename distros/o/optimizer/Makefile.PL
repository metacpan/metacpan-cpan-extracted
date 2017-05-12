use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile
  (
   'NAME'		=> 'optimizer',
   'VERSION_FROM'	=> 'optimizer.pm',
   'PREREQ_PM'	=>
   {
    'DynaLoader'  => 0,
    'B::Generate' => '1.26'
   },
   ABSTRACT_FROM => 'optimizer.pm',
   AUTHOR        => 'Simon Cozens, Artur Bergman, Reini Urban',
   ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE'  =>
     {
      resources =>
      {
       license     => 'http://dev.perl.org/licenses/',
       repository  => 'http://github.com/rurban/optimizer',
      },
     }
    ) : ()),
  );

package MY;

sub depend { "README : optimizer.pm
	pod2text optimizer.pm > README

coverclean:
	\$(PERL) -S cover -delete

testcover : optimizer.c.gcov optimizer.xs.gcov cover_db/coverage.html

optimizer.c.gcov optimizer.xs.gcov : optimizer.xs
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -fprofile-arcs -ftest-coverage\" LDDLFLAGS=\"\$(LDDLFLAGS) -fprofile-arcs -ftest-coverage\"
	gcov optimizer.c optimizer.xs

cover_db/coverage.html : optimizer.xs optimizer.pm \$(TEST_FILES)
	PERL5OPT=-MDevel::Cover PERL_DL_NONLAZY=1 make test
	# -\$(PERL) -S gcov2perl optimizer.c.gcov optimizer.xs.gcov
	\$(PERL) -S cover

gprof :
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -pg\" LDDLFLAGS=\"\$(LDDLFLAGS) -pg\"
"; }

sub test {
  local $_ = shift->SUPER::test(@_);
  s/PERL_DL_NONLAZY=1 //g;
  return $_;
}
