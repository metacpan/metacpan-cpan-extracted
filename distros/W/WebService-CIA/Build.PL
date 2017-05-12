use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name  => 'WebService::CIA',
    license      => 'perl',
    script_files => ['webservice-cia-makedbm.pl'],
    requires     => {
        'MLDBM'          => '2.01',
        'Storable'       => '2.0',
        'DB_File'        => '1.8',
        'LWP::UserAgent' => '2.0',
        'Crypt::SSLeay'  => '0',
    },
    build_requires => {
        'Test::More'    => '0',
        'Module::Build' => '0',
    },
    create_makefile_pl => 'passthrough',
);

#print "Some tests require an internet connection\n";
#$build->notes('internet' => ($build->y_n("Run internet-based tests?", "y")?"yes":"no"));
$build->notes('internet' => "no");

$build->create_build_script;
