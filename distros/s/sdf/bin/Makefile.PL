
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'SDF::bin',

	EXE_FILES	=> [ qw(
fm2ps
mif2rtf
pod2sdf
poddiff
prn2ps
sdf
sdfapi
sdfbatch
sdfcli
sdfget
sdngen
			) ],
	);
