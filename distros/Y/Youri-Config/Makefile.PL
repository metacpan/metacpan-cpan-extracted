# $Id: Makefile.PL 1501 2007-03-05 21:43:04Z guillomovitch $
use ExtUtils::MakeMaker;
use version;

WriteMakefile(
    NAME         => 'Youri::Config',
    VERSION_FROM => 'lib/Youri/Config.pm',
    AUTHOR       => 'Youri project <youri@zarb.org>',
    PREREQ_PM    => {
        'YAML::AppConfig' => 0,
    }
);

sub MY::postamble {
   return <<'EOF';
.PHONY: svntag
SVNPATH = svn+ssh://youri.zarb.org/home/projects/youri/svn/soft/Config

svntag:
	svn copy -m 'new release $(VERSION)'\
		$(SVNPATH)/trunk \
		$(SVNPATH)/tags/release-$(VERSION)

EOF
}
