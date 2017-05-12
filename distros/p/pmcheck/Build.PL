use 5.010;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup     => ['pmcheck-*'],
    build_requires     => { 'Test::Differences' => 0, },
    dist_author        => 'Andrew Pam <andrew.pam@strategicdata.com.au>',
    dist_version_from  => 'script/pmcheck',
    license            => 'perl',
    module_name        => 'pmcheck',
    recommends         => { 'Module::Used' => 0, 'Term::Activity' => 0, },
    requires           => { 'PPI::Document' => 0, 'perl' => '5.10.0', 'version' => 0, },
    script_files       => 'script',
);

$builder->create_build_script();
