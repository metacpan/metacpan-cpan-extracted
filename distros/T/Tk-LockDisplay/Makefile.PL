use ExtUtils::MakeMaker;

# Get version from LockDisplay.pm for WriteMakefile.

my $pm = 'LockDisplay.pm';
open(V, $pm) or die "Cannot open $pm:  $!";
while (defined($_ = <V>)) {
    last if /^\S+/;
}
close(V) or die $!;
my($v) = /['"]([^'"]+)/;
die "Version $v is invalid." unless $v;

WriteMakefile(
    NAME      => 'Tk::LockDisplay',
    DISTNAME  => 'Tk-LockDisplay',
    EXE_FILES => ['tklock'],
    VERSION   => "$v",
    dist      => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ($] >= 5.005 ?
	(ABSTRACT => 'Screen saver/lock widget with opt. animation',
	 AUTHOR   => 'Stephen O. Lidie (sol0@Lehigh.EDU)') : ()),
);
