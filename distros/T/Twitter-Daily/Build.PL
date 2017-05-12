use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Twitter::Daily',
    license             => 'perl',
    dist_author         => q{Víctor A. Rodríguez (Bit-Man) <victor@bit-man.com.ar>},
    dist_version_from   => 'lib/Twitter/Daily.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Kwalitee' => 0, 'Test::Pod' => 0,
    },
    requires => {       
        'perl' => 5.006,
        'Date::Parse' => 0, 'Time::Local' => 0, 
        'Error'  => 0, 'Net::Twitter'  => 0,
        'File::MkTemp'  => 0, 'HTTP::Date'  => 0, 
    },
    script_files => 'bin/twitterDaily.pl' ,
    add_to_cleanup      => [ 'Twitter-Daily-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
