use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Tie::Concurrent',
    'VERSION_FROM' => 'Concurrent.pm', # finds $VERSION
    dist=>{COMPRESS=>'gzip -9f', EXT=>'gz'},
    LICENSE     => 'perl',
    PREREQ_PM   => {
        'GDBM_File' => '0', # or a minimum working version
        'MLDBM' => '0', # or a minimum working version
    }
);
