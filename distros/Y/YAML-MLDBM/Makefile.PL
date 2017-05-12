use CPAN::MakeMaker;

$PREREQ_PM{YAML}       = '0.35';
$PREREQ_PM{MLDBM}      = '2.01';
$PREREQ_PM{Test::More} = 0;

$CLEAN_FILES = 'my_dbm_file*';

WriteMakefile;
