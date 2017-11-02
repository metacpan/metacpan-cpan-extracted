# $Id: /mirror/youri/soft/core/trunk/Makefile.PL 1284 2006-11-06T19:46:28.041137Z guillomovitch  $
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Youri::Package',
    VERSION_FROM => 'lib/Youri/Package.pm',
    AUTHOR       => 'Youri project <youri@zarb.org>',
    PREREQ_PM    => {
        'base'                           => 0,
        'constant'                       => 0,
        'feature'                        => 0,
        'overload'                       => 0,
        'strict'                         => 0,
        'version'                        => 0,
        'warnings'                       => 0,
        'Carp'                           => 0,
        'English'                        => 0,
        'Expect'                         => 0,
        'File::Basename'                 => 0,
        'File::Path'                     => 0,
        'File::Spec'                     => 0,
        'RPM'                            => 0,
        'RPM4'                           => 0,
        'RPM4::Header'                   => 0,
        'RPM4::Sign'                     => 0,
        'RPM::Constant'                  => 0,
        'RPM::Header'                    => 0,
        'RPM::Sign'                      => 0,
        'Scalar::Util'                   => 0,
        'UNIVERSAL::require'             => 0,
        'URPM'                           => 0,
    },
    TEST_REQUIRES  => {
        'File::Copy'                     => 0,
        'File::Temp'                     => 0,
        'File::Which'                    => 0,
        'Test::Exception'                => 0,
        'Test::Kwalitee'                 => 0,
        'Test::More'                     => 0,
        'Youri::Package::RPM::Generator' => 0,
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
