use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use Config;

my $osiodefine;
if ($Config{osname} =~ /linux/) {
    $osiodefine = '-DLINUX_AF_UNIX';
} else {
    $osiodefine = '';
}

WriteMakefile(
    'NAME'		=> 'PerlIO::OnSearchIO',
    'DEFINE'            => $osiodefine,	      
    'VERSION_FROM'	=> 'OnSearchIO.pm', # finds $VERSION
);

