use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'umlmgr',
    VERSION_FROM      => 'lib/Umlmgr.pm', # finds $VERSION
    PREREQ_PM         => {
        'Config::IniFiles'   => undef,
        'POSIX'              => undef,
        'Sys::Syslog'        => undef,
        'IPC::Open3'         => undef,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Umlmgr.pm', # retrieve abstract from module
       AUTHOR         => 'Olivier Thauvin <nanardon@localdomain>') : ()),
    EXE_FILES         => [ qw(bin/umlmgr bin/umltty) ],
);

package MY;

sub distdir {
    my $dist = shift->SUPER::distdir(@_);
    $dist =~ s/^(create_distdir :.*)/$1 ChangeLog manifest/m;
    $dist
}

sub dist_core {
    my $dist = shift->SUPER::dist_core(@_);
    $dist =~ s/^(\S.* :.*)/$1 ChangeLog manifest/mg;
    $dist
}

sub dist_basics {
    my $dist = shift->SUPER::dist_basics(@_);
    $dist =~ s/^manifest/oldmanifest/m;
    $dist .
"
manifest:
\tdarcs query manifest | sed 's:^./::' | sort > MANIFEST
\techo ChangeLog >> MANIFEST
";
}

sub postamble {
    return "
ChangeLog:
\tdarcs changes > ChangeLog

mymanifest : manifest
";
}

