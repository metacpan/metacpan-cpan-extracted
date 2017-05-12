use ExtUtils::MakeMaker;
use strict;

my %args = (
            pkg_name  => 'pkgfind',
            name      => 'pkgfind',
            DESTDIR   => undef
            );

my %opts = (
            'NAME'          => "WWW-PkgFind",
            'AUTHOR'        => "Bryce Harrington <bryce\@bryceharrington.org>",
            'ABSTRACT_FROM' => "lib/WWW/PkgFind.pm",
            'VERSION'       => "1.3.1",
            'EXE_FILES'     => [ qw( 
                                     scripts/pkgfind 
                                     scripts/git-pkgfind
                                     ) ],
            'PREREQ_PM'     => {
                'LWP::Simple'     => 0,
                'WWW::RobotRules' => 0,
                'File::Spec'      => 0,
                'File::Path'      => 0,
                'Pod::Usage'      => 0,
                'Getopt::Long'    => 0,
            },
);

WriteMakefile( %opts )

# vi:set ai ts=4 sw=4 expandtab:
