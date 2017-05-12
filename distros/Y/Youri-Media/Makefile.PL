# $Id: /mirror/youri/soft/core/trunk/Makefile.PL 1284 2006-11-06T19:46:28.041137Z guillomovitch  $
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Youri::Media',
    VERSION_FROM => 'lib/Youri/Media.pm',
    AUTHOR       => 'Youri project <youri@zarb.org>',
    PREREQ_PM  => {
        'Youri::Package'            => 0,
        'LWP::Simple'               => 0,
        'URPM'                      => 0,
        'Youri::Package::RPM::URPM' => 0,
        'version'                   => 0
    }
);

sub MY::postamble {
   return <<'EOF';
.PHONY: svntag
SVNPATH = svn+ssh://youri.zarb.org/home/projects/youri/svn/soft/Media

svntag:
	svn copy -m 'new release $(VERSION)'\
		$(SVNPATH)/trunk \
		$(SVNPATH)/tags/release-$(VERSION)

EOF
}
