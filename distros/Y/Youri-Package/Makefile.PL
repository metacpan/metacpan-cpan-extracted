# $Id: /mirror/youri/soft/core/trunk/Makefile.PL 1284 2006-11-06T19:46:28.041137Z guillomovitch  $
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Youri::Package',
    VERSION_FROM => 'lib/Youri/Package.pm',
    AUTHOR       => 'Youri project <youri@zarb.org>',
    PREREQ_PM  => {
        'Test::Exception'                => 0,
        'File::Which'                    => 0,
        'Youri::Package::RPM::Generator' => 0,
        'Expect'                         => 0,
        'URPM'                           => 0,
        'UNIVERSAL::require'             => 0,
        'version'                        => 0,
    }
);

sub MY::postamble {
   return <<'EOF';
.PHONY: svntag
SVNPATH = svn+ssh://youri.zarb.org/home/projects/youri/svn/soft/Package

svntag:
	svn copy -m 'new release $(VERSION)'\
		$(SVNPATH)/trunk \
		$(SVNPATH)/tags/release-$(VERSION)

EOF
}
