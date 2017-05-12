use ExtUtils::MakeMaker;

WriteMakefile(
	NAME            => 'Tie::Array::Random',
	VERSION_FROM    => 'lib/Tie/Array/Random.pm',
	AUTHOR			=> 'Matias Alejo Garcia ( matiu@cpan.org ) ',
	ABSTRACT		=> 'A tied array that generate random',
    PREREQ_PM 	   	=> {
            'Test::More' 	    => '0.88',
			'Scalar::Util'      => undef,
            'Data::Random'      => undef,
	},
);

