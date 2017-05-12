use ExtUtils::MakeMaker;

WriteMakefile(
	NAME            => 'Tie::Hash::Random',
	VERSION_FROM    => 'lib/Tie/Hash/Random.pm',
	AUTHOR			=> 'Matias Alejo Garcia ( matiu@cpan.org ) ',
	ABSTRACT		=> 'A tied hash that generate random',
    PREREQ_PM 	   	=> {
            'Test::More' 	    => '0.88',
			'Scalar::Util'      => undef,
            'Data::Random'      => undef,
	},
);

