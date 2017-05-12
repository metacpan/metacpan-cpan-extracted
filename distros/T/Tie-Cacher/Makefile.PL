use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tie::Cacher',
    'VERSION_FROM'	=> 'Cacher.pm', # finds $VERSION
    'PREREQ_PM'		=> {Test::More => 0.11},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Ton Hospel <Tie::Cacher@ton.iguana.be>') : ()),
);
