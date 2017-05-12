use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'p2',
    VERSION_FROM      => 'p2.pm',
    PREREQ_PM         => {},
    SIGN              => 1,
   ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE'  =>
     {
      resources =>
      {
       repository  => 'http://github.com/perl11/p2-pragma',
       license     => 'http://dev.perl.org/licenses/',
      },
     }
    ) : ()),
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'p2.pm',
       AUTHOR         => 'Reini Urban <rurban@cpan.org>') : ()),
);

package MY;

sub depend {
  "
README : \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README

release : README dist
	git commit -a -m\"release \$(VERSION)\"
	git tag \$(VERSION)
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	git push
	git push --tags
"
}
