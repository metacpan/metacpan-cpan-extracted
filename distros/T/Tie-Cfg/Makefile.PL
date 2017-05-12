use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Check perl version

my $perlVersion="$]";
die "perl version is $perlVersion, should be >=5.006.000" if ($perlVersion lt "5.006.000");

# Write makefile now

WriteMakefile(
    'NAME'	=> 'Tie::Cfg',
    'VERSION_FROM' => 'Cfg.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'PREREQ_PM' => { 'LockFile::Simple' =>  '0.2.5' },
);


