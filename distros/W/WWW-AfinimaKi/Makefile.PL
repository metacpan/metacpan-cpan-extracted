use ExtUtils::MakeMaker;

use 5.8.0;

WriteMakefile(
	NAME            => 'WWW::AfinimaKi',
	VERSION_FROM    => 'lib/WWW/AfinimaKi.pm',
	AUTHOR			=> 'Matias Alejo Garcia ( matiu@cpan.org ) ',
	ABSTRACT		=> 'A AfinimaKi Recommendating Engine Client',
    PREREQ_PM 	   	=> {
            'Test::More' 	    => 0.88,
			'Carp'				=> undef,
            'RPC::XML'          => undef,
            'RPC::XML::Client'  => undef,
            'Encode'            => undef,
            'Cache::Memcached::Fast' => undef,
        },
    MIN_PERL_VERSION => '5.8.0',
);

