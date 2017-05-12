# $Id: /mirror/youri/soft/core/trunk/Makefile.PL 1284 2006-11-06T19:46:28.041137Z guillomovitch  $
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Youri::Package::RPM::Builder',
    VERSION_FROM => 'lib/Youri/Package/RPM/Builder.pm',
    AUTHOR       => 'Youri project <youri@zarb.org>',
    PREREQ_PM    => {
        'Youri::Package'     => 0.002,
        'Test::Exception'    => 0,
        'String::ShellQuote' => 0,
        'version'            => 0
    }
);

sub MY::postamble {
   return <<'EOF';
.PHONY: svntag
SVNPATH = svn+ssh://youri.zarb.org/home/projects/youri/svn/soft/Package-RPM-Builder

svntag:
	svn copy -m 'new release $(VERSION)'\
		$(SVNPATH)/trunk \
		$(SVNPATH)/tags/release-$(VERSION)

EOF
}
