# $Id: Makefile.PL 2415 2017-10-28 10:41:36Z guillomovitch $
use ExtUtils::MakeMaker;
use version;

WriteMakefile(
    NAME         => 'Youri::Config',
    VERSION_FROM => 'lib/Youri/Config.pm',
    AUTHOR       => 'Youri project <youri@zarb.org>',
    PREREQ_PM    => {
        'YAML::AppConfig' => 0,
        'Carp'            => 0,
        'File::Spec'      => 0,
        'Getopt::Long'    => 0,
        'Pod::Usage'      => 0,
        'strict'          => 0,
        'version'         => 0,
        'warnings'        => 0,
    },
    TEST_REQUIRES => {
        'File::Temp'      => 0,
        'Test::Exception' => 0,
        'Test::Kwalitee'  => 0,
        'Test::More'      => 0,
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
