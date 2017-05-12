use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name  => 'WebService::Etsy',
    license      => 'perl',
    script_files => ['generate_methods.pl'],
    requires     => {
        'LWP::UserAgent' => '2.0',
        'JSON'           => '2.0',
    },
    build_requires => {
        'Test::More'    => '0',
    },
    create_makefile_pl => 'passthrough',
);

#print "Some tests require an internet connection\n";
#$build->notes('internet' => ($build->y_n("Run internet-based tests?", "y")?"yes":"no"));
#$build->notes('internet' => "no");

$build->create_build_script;
