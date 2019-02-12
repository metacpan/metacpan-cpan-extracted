use 5.10.0;
use strict;
BEGIN { unshift @INC, 'lib' }
use XS::Install;

write_makefile(
    NAME             => "XS::Install",
    TEST_REQUIRES    => {'Test::Deep' => 0},
    MIN_PERL_VERSION => '5.10.0',
    PREREQ_PM        => {
        'Exporter'            => '5.58',
        'ExtUtils::MakeMaker' => '7.12',
        'ExtUtils::ParseXS'   => '3.24',
    },
    BIN_SHARE        => {
    	PARSE_XS => 'XS::Install::ParseXS',
    	INCLUDE  => {
            'xsheader.h' => '',
    		'ppport.h'   => '',
    	},
    	TYPEMAPS => {typemap => ''},
        XSOPT    => '-hiertype',
    },
);
